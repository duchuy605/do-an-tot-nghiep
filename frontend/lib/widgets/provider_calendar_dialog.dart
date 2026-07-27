import 'package:flutter/material.dart';

class ProviderCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  /// Danh sách ca làm hiện có của nhân viên, mỗi phần tử: {date:'YYYY-MM-DD', start:'HH:mm', end:'HH:mm'}
  final List<Map<String, dynamic>> providerShifts;
  /// Giờ bắt đầu dự kiến của khách
  final TimeOfDay plannedStartTime;
  /// Số giờ làm dự kiến
  final double plannedDurationHours;

  const ProviderCalendarDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.providerShifts,
    required this.plannedStartTime,
    required this.plannedDurationHours,
  });

  @override
  State<ProviderCalendarDialog> createState() => _ProviderCalendarDialogState();
}

class _ProviderCalendarDialogState extends State<ProviderCalendarDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static const orangeColor = Color(0xFFFF8225);

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Chuyển chuỗi 'HH:mm' thành số phút kể từ 00:00
  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// Kiểm tra xem ngày [d] có ca làm của nhân viên TRÙNG khung giờ khách sắp đặt không.
  /// Trả về true nếu có conflict → hiện vòng đỏ.
  bool _hasConflict(DateTime d) {
    final key = _dateKey(d);
    // Lấy các ca trong ngày đó
    final shiftsOnDay = widget.providerShifts.where((s) => s['date'] == key).toList();
    if (shiftsOnDay.isEmpty) return false;

    // Khung giờ khách muốn đặt
    final customerStart = widget.plannedStartTime.hour * 60 + widget.plannedStartTime.minute;
    final customerEnd = customerStart + (widget.plannedDurationHours * 60).round();

    // Kiểm tra overlap với từng ca của nhân viên
    for (final shift in shiftsOnDay) {
      final shiftStart = _timeToMinutes(shift['start'] ?? '00:00');
      final shiftEnd = _timeToMinutes(shift['end'] ?? '00:00');
      // Hai khoảng [A,B] và [C,D] overlap nếu A < D && C < B
      if (customerStart < shiftEnd && shiftStart < customerEnd) {
        return true;
      }
    }
    return false;
  }

  bool _isSelected(DateTime d) =>
      d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isDisabled(DateTime d) =>
      d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime?> _buildCalendarDays() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // weekday: 1=Mon, 7=Sun => ta muốn CN=0
    int startWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final List<DateTime?> days = [];
    for (int i = 0; i < startWeekday; i++) days.add(null);
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }
    return days;
  }

  /// Có ít nhất 1 ngày bị conflict trong tháng hiện tại không?
  bool get _hasAnyConflict {
    for (final day in _buildCalendarDays()) {
      if (day != null && _hasConflict(day)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final monthNames = ['', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
    final dayHeaders = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    // Format giờ đặt để hiển thị trong chú thích
    final plannedH = widget.plannedStartTime.hour.toString().padLeft(2, '0');
    final plannedM = widget.plannedStartTime.minute.toString().padLeft(2, '0');
    final durationInt = widget.plannedDurationHours.truncate();
    final durationMin = ((widget.plannedDurationHours - durationInt) * 60).round();
    final durationLabel = durationMin > 0 ? '${durationInt}h${durationMin}p' : '${durationInt}h';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF6EAE3), // Màu nền nhẹ nhàng
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - tháng và nút điều hướng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${monthNames[_currentMonth.month]} ${_currentMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            // Chú thích
            if (_hasAnyConflict)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Trùng giờ ($plannedH:$plannedM, $durationLabel)',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Tiêu đề ngày trong tuần
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayHeaders.map((h) => SizedBox(
                width: 36,
                child: Center(child: Text(h, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: h == 'CN' ? Colors.red.shade600 : Colors.grey.shade700,
                ))),
              )).toList(),
            ),
            const SizedBox(height: 4),
            // Lưới ngày
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                days.length % 7 == 0 ? days.length : days.length + (7 - days.length % 7),
                (i) {
                  if (i >= days.length || days[i] == null) return const SizedBox();
                  final day = days[i]!;
                  final disabled = _isDisabled(day);
                  final selected = _isSelected(day);
                  final today = _isToday(day);
                  // Chỉ đánh dấu đỏ khi THỰC SỰ trùng khung giờ
                  final conflict = !disabled && _hasConflict(day);

                  return GestureDetector(
                    onTap: disabled ? null : () {
                      setState(() => _selectedDate = day);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? orangeColor : null,
                        border: Border.all(
                          color: conflict
                              ? Colors.red
                              : (today && !selected ? orangeColor : Colors.transparent),
                          width: conflict ? 2 : (today && !selected ? 1.5 : 0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected || conflict ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? Colors.white
                                : disabled
                                    ? Colors.grey.shade400
                                    : conflict
                                        ? Colors.red
                                        : Colors.blueGrey.shade100, // Màu nhạt theo mockup
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
