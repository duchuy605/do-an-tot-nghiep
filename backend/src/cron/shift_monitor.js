const cron = require('node-cron');
const { Op } = require('sequelize');
const { CaLamViec, NguoiDung } = require('../models');
const oCamManager = require('../sockets/o_cam_manager');
let isRunning = false;

function startShiftMonitorCron() {
  // Chạy mỗi phút 1 lần
  cron.schedule('* * * * *', async () => {
    if (isRunning) {
    
      return;
    }

    isRunning = true;
    const runStart = Date.now();
    try {
      const now = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Ho_Chi_Minh' }));
      
      // Lấy tất cả ca làm việc trong ngày hôm nay theo giờ VN
      const today = now.toISOString().split('T')[0];
      
      const shifts = await CaLamViec.findAll({
        where: {
          NgayLamViec: today,
          TrangThaiDonHang: { [Op.in]: [0, 1] }, // Chờ xác nhận hoặc đã nhận
          MaNhanVien: { [Op.ne]: null }
        }
      });

      for (const shift of shifts) {
        // Dùng giờ VN để tính thời gian bắt đầu ca
        const startTimeStr = `${shift.NgayLamViec}T${shift.GioBatDau}+07:00`;
        const startTime = new Date(startTimeStr);
        const diffMs = startTime - now;
        const diffSeconds = Math.floor(diffMs / 1000);


        const reminderWindowStart = 14 * 60;
        const reminderWindowEnd = 16 * 60;
        const lateWindowStart = -16 * 60;
        const lateWindowEnd = -14 * 60;

        // 1. Nhắc nhở Nhân viên trước 15 phút
        if (diffSeconds >= reminderWindowStart && diffSeconds <= reminderWindowEnd) {
          console.log('[thong bao] Sending 15-minute reminder to provider', shift.MaNhanVien, 'for shift', shift.MaCaLam, 'diffSeconds', diffSeconds);
          oCamManager.guiThongBaoNguoiDung(shift.MaNhanVien, {
            tieuDe: 'Sắp bắt đầu ca làm việc',
            noiDung: `Bạn có ca làm việc sẽ bắt đầu sau 15 phút nữa (lúc ${shift.GioBatDau.substring(0,5)}). Hãy chuẩn bị và nhớ nhấn "Bắt đầu" nhé!`,
            data: shift
          });
        } ;

        // 2. Nhắc nhở Admin nếu nhân viên trễ 15 phút chưa bấm "Bắt đầu"
        if (diffSeconds >= lateWindowStart && diffSeconds <= lateWindowEnd && !shift.ThoiGianBatDauThucTe) {
          const provider = await NguoiDung.findByPk(shift.MaNhanVien);
          const providerName = provider ? provider.HoTenNguoiDung : 'Không rõ';
          
          oCamManager.guiThongBaoAdmin({
            tieuDe: 'Nhân viên có thể đi trễ',
            noiDung: `Nhân viên ${providerName} vẫn chưa bấm "Bắt đầu" cho ca làm việc #${shift.MaCaLam} (Giờ bắt đầu: ${shift.GioBatDau.substring(0,5)}). Đã trễ 15 phút!`,
            data: shift
          });
        } ;
      }

      const runDuration = Date.now() - runStart;
    } catch (error) {
      console.error('Lỗi khi chạy cron giám sát ca làm:', error);
    } finally {
      isRunning = false;
    }
  });
}

module.exports = { startShiftMonitorCron };
