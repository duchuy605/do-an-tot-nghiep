// Tính toán thời gian và giá cả bằng vanilla JS (không cần thư viện bên ngoài)

function timeToMinutes(timeStr) {
  if (!timeStr) return 0;
  const parts = timeStr.split(':');
  const hours = parseInt(parts[0], 10) || 0;
  const minutes = parseInt(parts[1], 10) || 0;
  return hours * 60 + minutes;
}

function getDurationInHours(startTimeStr, endTimeStr) {
  const start = timeToMinutes(startTimeStr);
  let end = timeToMinutes(endTimeStr);
  if (end < start) {
    // Over midnight
    end += 24 * 60;
  }
  return (end - start) / 60;
}

function checkTimeInSlot(timeStr, slotStartStr, slotEndStr) {
  const time = timeToMinutes(timeStr);
  const start = timeToMinutes(slotStartStr);
  const end = timeToMinutes(slotEndStr);
  
  if (end < start) {
    // Slot spans over midnight
    return time >= start || time <= end;
  }
  return time >= start && time <= end;
}

function getDayOfWeekVN(dateStr) {
  const date = new Date(dateStr);
  const day = date.getDay(); // 0 = Sunday, 1 = Monday, ...
  if (day === 0) return 'CN';
  return (day + 1).toString(); // '2', '3', '4', '5', '6', '7'
}

module.exports = {
  getDurationInHours,
  timeToMinutes,
  checkTimeInSlot,
  getDayOfWeekVN
};
