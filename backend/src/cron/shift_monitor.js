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

      console.log(`[Cron] Giám sát ca làm - Thời gian VN: ${today} ${nowVN.toISOString().split('T')[1].substring(0, 8)} | Tìm thấy ${shifts.length} ca cần theo dõi.`);

      for (const shift of shifts) {
        // Dùng giờ VN để tính thời gian bắt đầu ca
        let dateStr = shift.NgayLamViec;
        if (dateStr instanceof Date) {
          const d = dateStr;
          const year = d.getFullYear();
          const month = String(d.getMonth() + 1).padStart(2, '0');
          const day = String(d.getDate()).padStart(2, '0');
          dateStr = `${year}-${month}-${day}`;
        } else {
          dateStr = String(dateStr).split('T')[0];
        }

        const startTimeStr = `${dateStr}T${shift.GioBatDau}+07:00`;
        const startTime = new Date(startTimeStr);
        const { diffSeconds, shouldSendReminder } = getReminderWindowState(startTime, now);

        const lateWindowStart = -16 * 60;
        const lateWindowEnd = -14 * 60;

        // Nhắc nhở Nhân viên trước 15 phút (chỉ gửi 1 lần)
        if (shouldSendReminder && !notified15m.has(shift.MaCaLam)) {
          console.log(`[Cron] Gửi nhắc nhở 15 phút cho nhân viên #${shift.MaNhanVien} của ca làm #${shift.MaCaLam} (Bắt đầu: ${shift.GioBatDau})`);
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
          
          console.log(`[Cron] Gửi cảnh báo trễ 15 phút cho Admin. Nhân viên ${providerName} chưa bấm Bắt đầu ca #${shift.MaCaLam}`);
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
      console.error('[Cron Error] Lỗi khi chạy cron giám sát ca làm:', error);
    } finally {
      isRunning = false;
    }
  });
}

module.exports = { startShiftMonitorCron, getReminderWindowState };

