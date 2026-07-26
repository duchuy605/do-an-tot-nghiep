const { Op } = require('sequelize');
const { CaLamViec, KhieuNai, ViTien, LichSuViTien } = require('../models');
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
async function checkAndExecutePayoutsForProvider(providerId) {
  let tx;
  try {
    const providerWallet = await ViTien.findOne({ where: { MaNguoiDung: providerId } });
    if (!providerWallet) return;

    const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
    if (!systemWallet) return;

    // Lấy các ca làm việc hoàn thành, chưa thanh toán của nhân viên này
    const pendingShifts = await CaLamViec.findAll({
      where: {
        MaNhanVien: providerId,
        TrangThaiDonHang: 2, // Hoàn thành
        DaThanhToan: false
      },
      include: [{
        model: KhieuNai,
        as: 'KhieuNais',
        required: false
      }]
    });

    if (pendingShifts.length === 0) return;

    const seventyTwoHoursAgo = new Date(Date.now() - 72 * 60 * 60 * 1000);
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const validShifts = pendingShifts.filter(shift => {
      const hasComplaints = shift.KhieuNais && shift.KhieuNais.length > 0;
      
      // Số tiền giải ngân: nếu TongTienTre null/0, dùng TienNhanVienNhan
      const amount = shift.TongTienTre !== null ? parseFloat(shift.TongTienTre) : parseFloat(shift.TienNhanVienNhan);
      if (!(amount > 0)) return false;

      // Xác định thời gian hoàn tất ca
      let finishDate;
      if (shift.NgayHoanThanh) {
        finishDate = new Date(shift.NgayHoanThanh);
      } else if (shift.NgayCapNhat) {
        finishDate = new Date(shift.NgayCapNhat);
      } else {
        finishDate = new Date(shift.NgayLamViec + 'T' + shift.GioKetThuc);
      }

      if (hasComplaints) {
        // Nếu có khiếu nại, khiếu nại phải được giải quyết xong mới được nhận tiền
        const allResolved = shift.KhieuNais.every(k => k.TrangThaiXuLy === 2);
        if (!allResolved) return false;
        // Ghi chú: Nếu Admin đã giải quyết, lập tức cho phép nhận tiền (bỏ chặn 72h)
      } else {
        // Nếu không có khiếu nại, giữ đủ 24 tiếng
        if (finishDate > twentyFourHoursAgo) return false;
      }

      return true;
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

      // Ghi lịch sử ví từng ca
      await LichSuViTien.create({
        MaViNguon: systemWallet.MaViTien,
        MaViDich: providerWallet.MaViTien,
        MaCaLam: shift.MaCaLam,
        LoaiGiaoDich: 4, // 4: Trả lương nhân viên
        SoTien: amount,
        SoDuSau: currentProvBalance,
        NgayTao: new Date(),
        NoiDungGiaoDich: `Giải ngân ca làm việc #${shift.MaCaLam}.`
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

module.exports = { checkAndExecutePayoutsForProvider };
