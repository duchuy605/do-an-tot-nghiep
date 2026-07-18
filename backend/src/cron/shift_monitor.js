const cron = require('node-cron');
const { Op } = require('sequelize');
const { CaLamViec, NguoiDung } = require('../models');
const oCamManager = require('../sockets/o_cam_manager');
let isRunning = false;
let cronScheduled = false;

const notified15m = new Set();
const notifiedLate = new Set();
let lastDateString = '';

function getReminderWindowState(startTime, now) {
  const diffMs = startTime.getTime() - now.getTime();
  const diffSeconds = Math.floor(diffMs / 1000);
  const reminderWindowStart = 0;
  const reminderWindowEnd = 15 * 60;

  return {
    diffSeconds,
    shouldSendReminder: diffSeconds >= reminderWindowStart && diffSeconds <= reminderWindowEnd
  };
}

function startShiftMonitorCron() {
  if (cronScheduled) {
    return;
  }
  cronScheduled = true;
 

  // Chạy mỗi phút 1 lần
  cron.schedule('* * * * *', async () => {
    if (isRunning) {
      return;
    }

    isRunning = true;
    const runStart = Date.now();
    try {
      const tzOffset = 7 * 60 * 60 * 1000;
      const nowVN = new Date(Date.now() + tzOffset);
      const today = nowVN.toISOString().split('T')[0];

      // Reset cache when date changes
      if (today !== lastDateString) {
        notified15m.clear();
        notifiedLate.clear();
        lastDateString = today;
      }

      const now = new Date();
      
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
        const { diffSeconds, shouldSendReminder } = getReminderWindowState(startTime, now);

        const lateWindowStart = -16 * 60;
        const lateWindowEnd = -14 * 60;

        // Nhắc nhở Nhân viên trước 15 phút (chỉ gửi 1 lần)
        if (shouldSendReminder && !notified15m.has(shift.MaCaLam)) {
          oCamManager.guiThongBaoNguoiDung(shift.MaNhanVien, {
            tieuDe: 'Sắp bắt đầu ca làm việc',
            noiDung: `Bạn có ca làm việc sẽ bắt đầu sau 15 phút nữa (lúc ${shift.GioBatDau.substring(0,5)}). Hãy chuẩn bị và nhớ nhấn "Bắt đầu" nhé!`,
            data: shift
          });

          notified15m.add(shift.MaCaLam);
        }

        // 2. Nhắc nhở Admin nếu nhân viên trễ 15 phút chưa bấm "Bắt đầu"
        if (diffSeconds >= lateWindowStart && diffSeconds <= lateWindowEnd && !shift.ThoiGianBatDauThucTe && !notifiedLate.has(shift.MaCaLam)) {
          const provider = await NguoiDung.findByPk(shift.MaNhanVien);
          const providerName = provider ? provider.HoTenNguoiDung : 'Không rõ';
          
          oCamManager.guiThongBaoAdmin({
            tieuDe: 'Nhân viên có thể đi trễ',
            noiDung: `Nhân viên ${providerName} vẫn chưa bấm "Bắt đầu" cho ca làm việc #${shift.MaCaLam} (Giờ bắt đầu: ${shift.GioBatDau.substring(0,5)}). Đã trễ 15 phút!`,
            data: shift
          });

          notifiedLate.add(shift.MaCaLam);
        }
      }

      const runDuration = Date.now() - runStart;
    } catch (error) {
      console.error('Lỗi khi chạy cron giám sát ca làm:', error);
    } finally {
      isRunning = false;
    }
  });
}

module.exports = { startShiftMonitorCron, getReminderWindowState };

