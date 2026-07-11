const cron = require('node-cron');
const { Op } = require('sequelize');
const { CaLamViec, NguoiDung } = require('../models');
const oCamManager = require('../sockets/o_cam_manager');

function startShiftMonitorCron() {
  // Chạy mỗi phút 1 lần
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      
      // Lấy tất cả ca làm việc trong ngày hôm nay, trạng thái Đã nhận (1)
      const today = now.toISOString().split('T')[0]; // YYYY-MM-DD
      
      const shifts = await CaLamViec.findAll({
        where: {
          NgayLamViec: today,
          TrangThaiDonHang: 1, // Đã nhận
        }
      });

      for (const shift of shifts) {
        // Dùng local time để so sánh vì server/db có thể lưu giờ local
        // Sử dụng mốc thời gian của Node.js:
        const startTimeStr = `${shift.NgayLamViec}T${shift.GioBatDau}+07:00`;
        const startTime = new Date(startTimeStr);
        const diffMs = startTime - now;
        const diffMinutes = Math.floor(diffMs / (1000 * 60));

        // 1. Nhắc nhở Nhân viên trước 15 phút
        if (diffMinutes === 15) {
          oCamManager.guiThongBaoNguoiDung(shift.MaNhanVien, {
            tieuDe: 'Sắp bắt đầu ca làm việc',
            noiDung: `Bạn có ca làm việc sẽ bắt đầu sau 15 phút nữa (lúc ${shift.GioBatDau.substring(0,5)}). Hãy chuẩn bị và nhớ nhấn "Bắt đầu" nhé!`,
            data: shift
          });
        }

        // 2. Nhắc nhở Admin nếu nhân viên trễ 15 phút chưa bấm "Bắt đầu"
        if (diffMinutes === -15 && !shift.ThoiGianBatDauThucTe) {
          const provider = await NguoiDung.findByPk(shift.MaNhanVien);
          const providerName = provider ? provider.HoTenNguoiDung : 'Không rõ';
          
          oCamManager.guiThongBaoAdmin({
            tieuDe: 'Nhân viên có thể đi trễ',
            noiDung: `Nhân viên ${providerName} vẫn chưa bấm "Bắt đầu" cho ca làm việc #${shift.MaCaLam} (Giờ bắt đầu: ${shift.GioBatDau.substring(0,5)}). Đã trễ 15 phút!`,
            data: shift
          });
        }
      }

    } catch (error) {
      console.error('Lỗi khi chạy cron giám sát ca làm:', error);
    }
  });
}

module.exports = { startShiftMonitorCron };
