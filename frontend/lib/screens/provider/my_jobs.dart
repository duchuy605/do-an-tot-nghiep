import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/provider_calendar_dialog.dart';
import '../../widgets/custom_time_picker.dart';
import '../../viewmodels/provider/my_jobs_viewmodel.dart';
import '../../widgets/top_banner_notification.dart';
import '../../widgets/weekly_calendar_widget.dart';
import '../../widgets/provider_job_components.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => MyJobsScreenState();
}

class MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  final MyJobsViewModel _viewModel = MyJobsViewModel();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.loadMyJobs();
  }

  void reloadData() {
    _viewModel.loadMyJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleStartJob(int caLamId) async {
    final response = await _viewModel.startJob(caLamId);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bắt đầu công việc thành công! Vui lòng hoàn thành tốt công việc của mình.')),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Có lỗi xảy ra')),
      );
    }
  }

  Future<void> _handleCompleteJob(int caLamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Báo Cáo Hoàn Thành', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn xác nhận đã hoàn thành ca làm dọn dẹp sạch sẽ và bàn giao lại cho khách? Hệ thống sẽ cộng lương cho bạn ngay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn Thành', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.completeJob(caLamId);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chúc mừng! Báo cáo hoàn thành ca làm và giải ngân lương thành công.'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể báo cáo hoàn thành.')),
      );
    }
  }

  // Nhận việc cho ca chờ xác nhận (trạng thái 0)
  Future<void> _handleAcceptJob(int caLamId) async {
    final response = await _viewModel.acceptJob(caLamId);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nhận việc thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể nhận việc.')),
      );
    }
  }

  Future<void> _handleCancelJob(int caLamId) async {
    final job = _viewModel.myJobs.firstWhere((j) => j['MaCaLam'] == caLamId, orElse: () => null);
    final isAccepted = job != null && job['TrangThaiDonHang'] == 1;

    final confirm = await showDialog<String?>(
      context: context,
      builder: (context) {
        final lyDoController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isAccepted ? 'Hủy Nhận Ca Làm Việc' : 'Từ Chối / Hủy Nhận Ca', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAccepted 
                  ? 'Bạn muốn hủy ca làm đã nhận này? Việc hủy chỉ được chấp nhận trước giờ bắt đầu ít nhất 30 phút.' 
                  : 'Bạn muốn từ chối ca làm này? Ca làm sẽ được đưa trở lại bảng chung để nhân viên khác nhận.'),
              const SizedBox(height: 16),
              TextField(
                controller: lyDoController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isAccepted ? 'Lý do hủy lịch *' : 'Lý do từ chối *',
                  hintText: isAccepted ? 'Nhập lý do hủy lịch...' : 'Nhập lý do từ chối...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Đóng', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                if (lyDoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAccepted ? 'Vui lòng nhập lý do hủy' : 'Vui lòng nhập lý do từ chối'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, lyDoController.text.trim());
              },
              child: Text(isAccepted ? 'Hủy Lịch' : 'Từ Chối', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == null) return;

    final response = isAccepted 
        ? await _viewModel.cancelJob(caLamId, lyDoHuy: confirm)
        : await _viewModel.rejectJob(caLamId, lyDoHuy: confirm);
        
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAccepted ? 'Đã hủy nhận lịch thành công!' : 'Đã từ chối ca làm việc thành công.'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể thực hiện yêu cầu hủy/từ chối.')),
      );
    }
  }

  // Nhận tất cả ca làm chờ xác nhận trong đơn định kỳ
  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _handleRescheduleJob(dynamic job) async {
    DateTime oldDate = DateTime.tryParse(job['NgayLamViec'] ?? '') ?? DateTime.now();
    TimeOfDay oldStartTime = _parseTimeOfDay(job['GioBatDau'] ?? '08:00:00');
    TimeOfDay oldEndTime = _parseTimeOfDay(job['GioKetThuc'] ?? '10:00:00');
    
    DateTime selectedDate = oldDate;
    TimeOfDay startTime = oldStartTime;
    TimeOfDay endTime = oldEndTime;
    final reasonController = TextEditingController();

    int durationMins = (oldEndTime.hour - oldStartTime.hour) * 60 + (oldEndTime.minute - oldStartTime.minute);
    bool hasConflict = false;

    void checkConflict() {
      hasConflict = false;
      int newStartMins = startTime.hour * 60 + startTime.minute;
      int newEndMins = newStartMins + durationMins;
      String newDateStr = _formatDate(selectedDate);

      for (var s in _viewModel.myJobs) {
        if (s['MaCaLam'] == job['MaCaLam']) continue; // Bỏ qua ca hiện tại
        int status = s['TrangThaiDonHang'] ?? 0;
        if (status == 0 || status == 1 || status == 2) { 
           String otherDateStr = s['NgayLamViec'] ?? '';
           if (otherDateStr.startsWith(newDateStr)) {
              TimeOfDay otherStart = _parseTimeOfDay(s['GioBatDau'] ?? '08:00:00');
              TimeOfDay otherEnd = _parseTimeOfDay(s['GioKetThuc'] ?? '10:00:00');
              int otherStartMins = otherStart.hour * 60 + otherStart.minute;
              int otherEndMins = otherEnd.hour * 60 + otherEnd.minute;
              
              if (newStartMins < otherEndMins && otherStartMins < newEndMins) {
                hasConflict = true;
                break;
              }
           }
        }
      }
    }

    checkConflict();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đổi Lịch Làm Việc', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lịch cũ
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Lịch cũ: ${_formatDate(oldDate)} lúc ${oldStartTime.format(context)} - ${oldEndTime.format(context)}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Ngày làm mới'),
                subtitle: Text(_formatDate(selectedDate)),
                onTap: () async {
                  final picked = await showDialog<DateTime>(
                    context: context,
                    builder: (context) => ProviderCalendarDialog(
                      initialDate: selectedDate.isBefore(DateTime.now()) ? DateTime.now() : selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                      providerShifts: _viewModel.myJobs
                          .where((s) => s['MaCaLam'] != job['MaCaLam'] && (s['TrangThaiDonHang'] == 0 || s['TrangThaiDonHang'] == 1 || s['TrangThaiDonHang'] == 2))
                          .map((s) => {
                                'date': (s['NgayLamViec'] ?? '').toString().split('T')[0].split(' ')[0],
                                'start': s['GioBatDau'] ?? '00:00',
                                'end': s['GioKetThuc'] ?? '00:00'
                              })
                          .toList(),
                      plannedStartTime: startTime,
                      plannedDurationHours: durationMins / 60.0,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                      checkConflict();
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Giờ bắt đầu'),
                subtitle: Text(startTime.format(context)),
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return CustomTimePicker(
                        initialTime: startTime,
                        onTimeSelected: (TimeOfDay picked) {
                          setDialogState(() {
                            startTime = picked;
                            checkConflict();
                          });
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              if (hasConflict)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thời gian này bị trùng với một ca làm việc khác của bạn!',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (selectedDate == oldDate && startTime == oldStartTime)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Expanded(child: Text('Vui lòng chọn thời gian khác với lịch cũ để đổi lịch.', style: TextStyle(color: Colors.blue, fontSize: 12))),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Giờ kết thúc sẽ được tự động tính dựa trên tổng số giờ của các dịch vụ trong ca.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do đổi lịch',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng', style: TextStyle(color: Color(0xFFFF8225))),
            ),
            TextButton(
              onPressed: (hasConflict || (selectedDate == oldDate && startTime == oldStartTime)) ? null : () {
                Navigator.pop(context, true);
              },
              child: Text('Đổi Lịch', style: TextStyle(fontWeight: FontWeight.bold, color: (hasConflict || (selectedDate == oldDate && startTime == oldStartTime)) ? Colors.grey : const Color(0xFFFF8225))),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final response = await _viewModel.rescheduleShift(
      job['MaCaLam'] ?? 0,
      ngayLamViec: _formatDate(selectedDate),
      gioBatDau: _formatTime(startTime),
      lyDo: reasonController.text.trim(),
    );
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi lịch làm việc thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể đổi lịch làm việc.')),
      );
    }
  }

  Future<void> _handleRespondReschedule(int requestId, bool dongY) async {
    final actionText = dongY ? 'đồng ý' : 'từ chối';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác Nhận ${dongY ? "Đồng Ý" : "Từ Chối"}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn $actionText yêu cầu đổi lịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              dongY ? 'Đồng Ý' : 'Từ Chối',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: dongY ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.respondRescheduleRequest(requestId, dongY);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã $actionText yêu cầu đổi lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể xử lý yêu cầu.')),
      );
    }
  }

  Future<void> _handleAcceptAllJobs(List<dynamic> jobs) async {
    final pendingJobs = jobs.where((j) => j['TrangThaiDonHang'] == 0).toList();
    if (pendingJobs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhận Tất Cả Ca', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn xác nhận nhận tất cả ${pendingJobs.length} ca làm trong đơn định kỳ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nhận việc', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int successCount = 0;
    for (final job in pendingJobs) {
      final response = await _viewModel.acceptJob(job['MaCaLam']);
      if (response['success'] == true) successCount++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã nhận $successCount/${pendingJobs.length} ca thành công!'),
        backgroundColor: Colors.green,
      ),
    );
    _viewModel.loadMyJobs();
  }

  // Từ chối tất cả ca làm chờ xác nhận trong đơn định kỳ
  Future<void> _handleRejectAllJobs(List<dynamic> jobs) async {
    final pendingJobs = jobs.where((j) => j['TrangThaiDonHang'] == 0).toList();
    if (pendingJobs.isEmpty) return;

    final lyDo = await showDialog<String?>(
      context: context,
      builder: (context) {
        final lyDoController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Từ Chối Tất Cả Ca', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn muốn từ chối tất cả ${pendingJobs.length} ca làm trong đơn định kỳ này?'),
              const SizedBox(height: 16),
              TextField(
                controller: lyDoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối *',
                  hintText: 'Nhập lý do từ chối...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Đóng', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                if (lyDoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do từ chối'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, lyDoController.text.trim());
              },
              child: const Text('Từ Chối', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (lyDo == null) return;

    int successCount = 0;
    for (final job in pendingJobs) {
      final response = await _viewModel.rejectJob(job['MaCaLam'], lyDoHuy: lyDo);
      if (response['success'] == true) successCount++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã từ chối $successCount/${pendingJobs.length} ca thành công.'),
        backgroundColor: Colors.green,
      ),
    );
    _viewModel.loadMyJobs();
  }
  JobActionCallbacks _getCallbacks() {
    return JobActionCallbacks(
      onRejectAllJobs: _handleRejectAllJobs,
      onAcceptAllJobs: _handleAcceptAllJobs,
      onRescheduleJob: _handleRescheduleJob,
      onAcceptJob: _handleAcceptJob,
      onCancelJob: _handleCancelJob,
      onStartJob: _handleStartJob,
      onCompleteJob: _handleCompleteJob,
      onRespondReschedule: _handleRespondReschedule,
    );
  }

  Widget _buildTabContent(List<dynamic> filteredList, Color orangeColor, Color darkColor, {bool isHistory = false}) {
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Bạn không có ca làm việc nào ở mục này.',
              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Nhóm các ca làm định kỳ theo MaDatLich
    final List<Map<String, dynamic>> displayItems = [];
    final Map<int, List<dynamic>> recurringGroups = {};
    for (final job in filteredList) {
      final loaiDatLich = job['DonDatLich']?['LoaiDatLich'];
      final maDatLich = job['MaDatLich'];
      if (loaiDatLich == 2 && maDatLich != null) {
        recurringGroups.putIfAbsent(maDatLich, () => []).add(job);
      } else {
        displayItems.add({'type': 'single', 'job': job});
      }
    }
    for (final entry in recurringGroups.entries) {
      displayItems.add({'type': 'recurring', 'maDatLich': entry.key, 'jobs': entry.value});
    }

    displayItems.sort((a, b) {
      final dateA = a['type'] == 'recurring' ? (a['jobs'].isNotEmpty ? a['jobs'].first['NgayLamViec'] : '') : (a['job']['NgayLamViec'] ?? '');
      final timeA = a['type'] == 'recurring' ? (a['jobs'].isNotEmpty ? a['jobs'].first['GioBatDau'] : '') : (a['job']['GioBatDau'] ?? '');
      final dateB = b['type'] == 'recurring' ? (b['jobs'].isNotEmpty ? b['jobs'].first['NgayLamViec'] : '') : (b['job']['NgayLamViec'] ?? '');
      final timeB = b['type'] == 'recurring' ? (b['jobs'].isNotEmpty ? b['jobs'].first['GioBatDau'] : '') : (b['job']['GioBatDau'] ?? '');

      if (isHistory) {
        int dateCmp = (dateB ?? '').compareTo(dateA ?? '');
        if (dateCmp != 0) return dateCmp;
        return (timeB ?? '').compareTo(timeA ?? '');
      } else {
        int dateCmp = (dateA ?? '').compareTo(dateB ?? '');
        if (dateCmp != 0) return dateCmp;
        return (timeA ?? '').compareTo(timeB ?? '');
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        if (item['type'] == 'recurring') {
          return ProviderRecurringJobCard(jobs: item['jobs'], orangeColor: orangeColor, darkColor: darkColor, callbacks: _getCallbacks());
        }
        return ProviderJobCard(job: item['job'], orangeColor: orangeColor, darkColor: darkColor, callbacks: _getCallbacks());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Công Việc Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: orangeColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: orangeColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Việc đã nhận'),
            Tab(text: 'Lịch sử dọn'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }

          // Trạng thái 0 (chờ xác nhận) và 1 (đã nhận) thuộc tab việc đang làm
      final activeJobs = <dynamic>[];
final historyJobs = <dynamic>[];

for (final job in _viewModel.myJobs) {
  final isRecurring = job['DonDatLich']?['LoaiDatLich'] == 2;

  if (isRecurring) {
    // Đơn định kỳ xét theo trạng thái của DonDatLich
    if (job['DonDatLich']?['TrangThai'] == 3) {
      historyJobs.add(job);
    } else {
      activeJobs.add(job);
    }
  } else {
    // Đơn thường xét theo trạng thái ca làm
    if (job['TrangThaiDonHang'] == 0 ||
        job['TrangThaiDonHang'] == 1) {
      activeJobs.add(job);
    } else {
      historyJobs.add(job);
    }
  }
}

activeJobs.sort((a, b) {
  final dateA = a['NgayLamViec'] ?? '';
  final dateB = b['NgayLamViec'] ?? '';
  int dateCmp = dateA.compareTo(dateB);
  if (dateCmp != 0) return dateCmp;
  return (a['GioBatDau'] ?? '').compareTo(b['GioBatDau'] ?? '');
});

historyJobs.sort((a, b) {
  final dateA = a['NgayLamViec'] ?? '';
  final dateB = b['NgayLamViec'] ?? '';
  int dateCmp = dateB.compareTo(dateA);
  if (dateCmp != 0) return dateCmp;
  return (b['GioBatDau'] ?? '').compareTo(a['GioBatDau'] ?? '');
});
          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _viewModel.loadMyJobs,
                color: orangeColor,
                child: WeeklyCalendarWidget(
                  activeJobs: activeJobs,
                  orangeColor: orangeColor,
                  darkColor: darkColor,
                  onTapJob: (job, isRecurring) {
                    if (isRecurring) {
                      final maDatLich = job['MaDatLich'];
                      final relatedJobs = activeJobs.where((j) => j['MaDatLich'] == maDatLich).toList();
                      showRecurringDetailSheet(context, relatedJobs.isNotEmpty ? relatedJobs : [job], orangeColor, darkColor, _getCallbacks());
                    } else {
                      showJobDetailSheet(context, job, orangeColor, darkColor, _getCallbacks());
                    }
                  },
                ),
              ),
              RefreshIndicator(
                onRefresh: _viewModel.loadMyJobs,
                color: orangeColor,
                child: _buildTabContent(historyJobs, orangeColor, darkColor, isHistory: true),
              ),
            ],
          );
        },
      ),
    );
  }
}
