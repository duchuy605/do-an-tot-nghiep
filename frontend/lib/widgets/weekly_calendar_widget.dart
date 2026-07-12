import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyCalendarWidget extends StatefulWidget {
  final List<dynamic> activeJobs;
  final Color orangeColor;
  final Color darkColor;
  final Function(dynamic job, bool isRecurring) onTapJob;

  const WeeklyCalendarWidget({
    super.key,
    required this.activeJobs,
    required this.orangeColor,
    required this.darkColor,
    required this.onTapJob,
  });

  @override
  State<WeeklyCalendarWidget> createState() => _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends State<WeeklyCalendarWidget> {
  DateTime _currentWeekStart = _getStartOfWeek(DateTime.now());

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final endOfWeek = _currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    
    final jobsThisWeek = widget.activeJobs.where((job) {
      final dateStr = job['NgayLamViec'];
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.isAfter(_currentWeekStart.subtract(const Duration(days: 1))) && date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    const double hourHeight = 60.0;
    const double colWidth = 100.0;
    const double timeColWidth = 50.0;
    const int startHour = 6;
    const int endHour = 22;
    const int totalHours = endHour - startHour;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                  });
                },
              ),
              Text(
                '${DateFormat('dd/MM').format(_currentWeekStart)} - ${DateFormat('dd/MM').format(endOfWeek)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: timeColWidth + (7 * colWidth),
                height: (totalHours + 1) * hourHeight,
                child: Stack(
                  children: [
                    // Lưới nền
                    for (int i = 0; i <= totalHours; i++)
                      Positioned(
                        top: hourHeight + (i * hourHeight),
                        left: timeColWidth,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: i % 2 == 0 ? Colors.grey.shade200 : Colors.transparent, // Chỉ kẻ sọc ngang mỗi 2 giờ
                        ),
                      ),
                    
                    // Cột giờ
                    for (int i = 0; i <= totalHours; i += 2)
                      Positioned(
                        top: hourHeight + (i * hourHeight) - 8,
                        left: 0,
                        width: timeColWidth,
                        child: Text(
                          '${startHour + i}:00',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    
                    // Cột ngày và vạch phân cách
                    for (int i = 0; i < 7; i++) ...[
                      Positioned(
                        top: 0,
                        left: timeColWidth + (i * colWidth),
                        width: colWidth,
                        height: hourHeight,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                DateFormat('dd/MM').format(_currentWeekStart.add(Duration(days: i))),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: hourHeight,
                        bottom: 0,
                        left: timeColWidth + (i * colWidth),
                        child: Container(width: 1, color: Colors.grey.shade200),
                      ),
                    ],

                    // Render ca làm việc
                    for (final job in jobsThisWeek)
                      Builder(builder: (context) {
                        final dateStr = job['NgayLamViec'];
                        final date = DateTime.tryParse(dateStr ?? '');
                        if (date == null) return const SizedBox.shrink();
                        final dayIndex = date.difference(_currentWeekStart).inDays;
                        
                        final startStr = job['GioBatDau'] ?? '08:00:00';
                        final endStr = job['GioKetThuc'] ?? '10:00:00';
                        final startParts = startStr.split(':');
                        final endParts = endStr.split(':');
                        final startH = int.tryParse(startParts[0]) ?? 8;
                        final startM = int.tryParse(startParts[1]) ?? 0;
                        final endH = int.tryParse(endParts[0]) ?? 10;
                        final endM = int.tryParse(endParts[1]) ?? 0;
                        
                        final startOffset = (startH - startHour) * hourHeight + (startM / 60) * hourHeight;
                        final durationHours = (endH - startH) + (endM - startM) / 60;
                        final height = durationHours * hourHeight;

                        final isRecurring = job['DonDatLich']?['LoaiDatLich'] == 2;
                        final status = job['TrangThaiDonHang'] ?? 0;
                        final boxColor = status == 0 ? Colors.orange.shade300 : widget.orangeColor;

                        return Positioned(
                          top: hourHeight + startOffset,
                          left: timeColWidth + (dayIndex * colWidth) + 2,
                          width: colWidth - 4,
                          height: height - 2,
                          child: InkWell(
                            onTap: () => widget.onTapJob(job, isRecurring),
                            child: Container(
                              decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - ${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Expanded(
                                    child: Text(
                                      job['DichVu'] ?? '',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.2),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
