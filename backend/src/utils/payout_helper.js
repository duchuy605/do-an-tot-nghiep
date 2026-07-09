const { Op } = require('sequelize');
const { CaLamViec, KhieuNai, ViTien, LichSuViTien } = require('../models');
const sequelize = require('../config/database');

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
        // Nếu có khiếu nại, giữ đủ 72 tiếng
        if (finishDate > seventyTwoHoursAgo) return false;
        
        // Và khiếu nại phải được giải quyết xong mới được nhận tiền
        const allResolved = shift.KhieuNais.every(k => k.TrangThaiXuLy === 2);
        if (!allResolved) return false;
      } else {
        // Nếu không có khiếu nại, giữ đủ 24 tiếng
        if (finishDate > twentyFourHoursAgo) return false;
      }

      return true;
    });

    if (validShifts.length === 0) return;

    tx = await sequelize.transaction();

    let totalPayout = 0;
    for (const shift of validShifts) {
      const amount = shift.TongTienTre !== null ? parseFloat(shift.TongTienTre) : parseFloat(shift.TienNhanVienNhan);
      totalPayout += amount;

      // Đánh dấu đã thanh toán
      await shift.update({ DaThanhToan: true, TongTienTre: amount }, { transaction: tx });
    }

    if (totalPayout > 0) {
      // 1. Cộng vào ví nhân viên
      const newProvBalance = parseFloat(providerWallet.SoDu) + totalPayout;
      await providerWallet.update({ SoDu: newProvBalance }, { transaction: tx });

      // 2. Trừ ví tạm giữ hệ thống
      const newSysBalance = parseFloat(systemWallet.SoDu) - totalPayout;
      await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

      // 3. Ghi lịch sử ví
      await LichSuViTien.create({
        MaViNguon: systemWallet.MaViTien,
        MaViDich: providerWallet.MaViTien,
        MaCaLam: null,
        LoaiGiaoDich: 4, // 4: Trả lương nhân viên
        SoTien: totalPayout,
        SoDuSau: newProvBalance,
        NgayTao: new Date(),
        NoiDungGiaoDich: `Giải ngân tự động cho ${validShifts.length} ca làm việc đủ điều kiện (24h/72h).`
      }, { transaction: tx });

      console.log(`[ON-DEMAND PAYOUT] Released ${totalPayout} to provider #${providerId} for ${validShifts.length} shifts.`);
    }

    await tx.commit();
  } catch (err) {
    if (tx) await tx.rollback();
    console.error('[ON-DEMAND PAYOUT ERROR]:', err.message);
  }
}

module.exports = { checkAndExecutePayoutsForProvider };
