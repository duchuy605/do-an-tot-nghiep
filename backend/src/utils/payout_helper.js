const { Op } = require('sequelize');
const { CaLamViec, KhieuNai, DanhGia, ViTien, LichSuViTien } = require('../models');
const sequelize = require('../config/database');

/**
 * Logic giải ngân (payout) cho nhân viên (provider):
 * Hệ thống sẽ tự động kiểm tra các ca làm việc đã hoàn thành nhưng chưa được thanh toán tiền cho nhân viên.
 * 
 * Quy tắc giải ngân:
 * 1. Nếu KHÔNG CÓ khiếu nại liên quan đến ca làm việc: Số tiền sẽ được giữ trong ví tạm giữ của hệ thống trong 24 giờ kể từ khi hoàn thành ca làm việc. Sau 24h, tiền được tự động giải ngân (chuyển) vào ví của nhân viên.
 * 2. Nếu CÓ khiếu nại: Số tiền sẽ bị giữ lại tối đa 72 giờ và chỉ được giải ngân khi TẤT CẢ các khiếu nại liên quan đến ca làm việc đó đã được xử lý xong (TrangThaiXuLy = 2).
 * 
 * Giao dịch chuyển tiền được thực hiện dưới dạng Transaction trong cơ sở dữ liệu để đảm bảo tính nhất quán (trừ tiền hệ thống, cộng tiền nhân viên và ghi lịch sử giao dịch thành công đồng thời).
 */
function parseDbDate(dateStr) {
  if (!dateStr) return null;
  if (dateStr instanceof Date) return dateStr;
  const str = String(dateStr);
  if (str.includes('+') || str.endsWith('Z')) return new Date(str);
  return new Date(str.replace(' ', 'T') + '+07:00');
}

function getPrimaryComplaintIdForShift(shift) {
  if (!shift || !Array.isArray(shift.KhieuNais) || shift.KhieuNais.length === 0) {
    return null;
  }

  const sortedComplaints = [...shift.KhieuNais].sort((a, b) => (b.MaKhieuNai || 0) - (a.MaKhieuNai || 0));
  return sortedComplaints[0]?.MaKhieuNai || null;
}

async function checkAndExecutePayoutsForProvider(providerId) {
  let tx;
  try {
    let providerWallet = await ViTien.findOne({ where: { MaNguoiDung: providerId } });
    if (!providerWallet) {
      providerWallet = await ViTien.create({
        MaNguoiDung: providerId,
        SoDu: 0,
        LoaiVi: 2,
        TrangThai: true
      });
    }

    let systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
    if (!systemWallet) {
      const fallbackWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
      if (fallbackWallet) {
        systemWallet = fallbackWallet;
      } else {
        const adminUser = await sequelize.models.NguoiDung.findOne({ where: { VaiTro: 3 } });
        if (adminUser) {
          let adminWallet = await ViTien.findOne({ where: { MaNguoiDung: adminUser.MaNguoiDung } });
          if (!adminWallet) {
            adminWallet = await ViTien.create({
              MaNguoiDung: adminUser.MaNguoiDung,
              SoDu: 0,
              LoaiVi: 3,
              TrangThai: true
            });
          }
          systemWallet = adminWallet;
        } else {
          systemWallet = await ViTien.create({
            MaNguoiDung: providerId,
            SoDu: 0,
            LoaiVi: 3,
            TrangThai: true
          });
        }
      }
    }

    // Lấy các ca làm việc hoàn thành, chưa thanh toán của nhân viên này
    const pendingShifts = await CaLamViec.findAll({
      where: {
        MaNhanVien: providerId,
        TrangThaiDonHang: 2, // Hoàn thành
        DaThanhToan: false
      },
      include: [
        {
          model: KhieuNai,
          as: 'KhieuNais',
          required: false
        },
        {
          model: DanhGia,
          as: 'DanhGia',
          required: false
        }
      ]
    });

    if (pendingShifts.length === 0) return;

    const now = new Date();

    const validShifts = pendingShifts.filter(shift => {
      const complaintId = getPrimaryComplaintIdForShift(shift);
      const hasComplaints = !!complaintId;
      const hasReview = !!shift.DanhGia;
      
      // Số tiền giải ngân: nếu TongTienTre null/0, dùng TienNhanVienNhan
      const amount = shift.TongTienTre !== null ? parseFloat(shift.TongTienTre) : parseFloat(shift.TienNhanVienNhan);
      if (!(amount > 0)) return false;

      // Xác định thời gian hoàn tất ca
      let finishDate;
      if (shift.NgayHoanThanh) {
        finishDate = parseDbDate(shift.NgayHoanThanh);
      } else if (shift.NgayCapNhat) {
        finishDate = parseDbDate(shift.NgayCapNhat);
      } else {
        finishDate = new Date(shift.NgayLamViec + 'T' + shift.GioKetThuc + '+07:00');
      }

      if (hasComplaints) {
        // Nếu có khiếu nại, phải được giải quyết xong mới được nhận tiền.
        const allResolved = (shift.KhieuNais || []).every(k => k.TrangThaiXuLy === 2);
        if (!allResolved) return false;
      }

      let releaseDate = finishDate;
      if (hasReview) {
        // Nếu khách hàng đã đánh giá, tiền sẽ bị giữ lâu hơn để chờ xử lý/đánh giá cuối cùng.
        const reviewDate = parseDbDate(shift.DanhGia?.NgayDanhGia || shift.NgayHoanThanh || shift.NgayCapNhat || finishDate);
        const resolvedComplaint = (shift.KhieuNais || []).find(k => k.TrangThaiXuLy === 2);
        const decisionDate = resolvedComplaint?.NgayXuLy ? parseDbDate(resolvedComplaint.NgayXuLy) : reviewDate;
        releaseDate = decisionDate || reviewDate || finishDate;
        releaseDate = new Date(releaseDate.getTime() + 72 * 60 * 60 * 1000);
      } else {
        releaseDate = new Date(finishDate.getTime() + 24 * 60 * 60 * 1000);
      }

      return now >= releaseDate;
    });

    if (validShifts.length === 0) return;

    tx = await sequelize.transaction();

    let currentProvBalance = parseFloat(providerWallet.SoDu);
    let currentSysBalance = parseFloat(systemWallet.SoDu);
    let processedShifts = 0;

    for (const shift of validShifts) {
      // Kiểm tra lại Database một lần nữa bằng CSDL để chống Double Spending (Race Condition)
      const checkShift = await CaLamViec.findOne({ where: { MaCaLam: shift.MaCaLam, DaThanhToan: false }, transaction: tx });
      if (!checkShift) continue;

      const amount = checkShift.TongTienTre !== null ? parseFloat(checkShift.TongTienTre) : parseFloat(checkShift.TienNhanVienNhan);
      if (!(amount > 0)) continue;

      // Đánh dấu đã thanh toán
      await checkShift.update({ DaThanhToan: true, TongTienTre: amount }, { transaction: tx });

      // Cập nhật số dư trong bộ nhớ
      currentProvBalance += amount;
      currentSysBalance -= amount;

      const complaintId = getPrimaryComplaintIdForShift(shift);

      // Ghi lịch sử ví từng ca
      await LichSuViTien.create({
        MaViNguon: systemWallet.MaViTien,
        MaViDich: providerWallet.MaViTien,
        MaCaLam: shift.MaCaLam,
        MaKhieuNai: complaintId,
        LoaiGiaoDich: 4, // 4: Trả lương nhân viên
        SoTien: amount,
        SoDuSau: currentProvBalance,
        NgayTao: new Date(),
        NoiDungGiaoDich: `Giải ngân ca làm việc #${shift.MaCaLam}${complaintId ? ` liên quan khiếu nại #${complaintId}` : ''}.`
      }, { transaction: tx });

      processedShifts++;
    }

    if (processedShifts > 0) {
      // 1. Cập nhật ví nhân viên
      await providerWallet.update({ SoDu: currentProvBalance }, { transaction: tx });

      // 2. Cập nhật ví tạm giữ hệ thống
      await systemWallet.update({ SoDu: currentSysBalance }, { transaction: tx });

      console.log(`[GIẢI NGÂN THEO YÊU CẦU] Đã giải ngân cho nhân viên #${providerId} ứng với ${processedShifts} ca làm việc.`);
    }

    await tx.commit();
  } catch (err) {
    if (tx) await tx.rollback();
    console.error('[LỖI GIẢI NGÂN THEO YÊU CẦU]:', err.message);
  }
}

module.exports = { checkAndExecutePayoutsForProvider, getPrimaryComplaintIdForShift };
