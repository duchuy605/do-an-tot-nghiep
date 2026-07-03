import 'package:flutter/material.dart';
import '../../viewmodels/provider/my_jobs_viewmodel.dart';

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
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
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
    final confirm = await showDialog<String?>(
      context: context,
      builder: (context) {
        final lyDoController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Từ Chối / Hủy Nhận Ca', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn muốn từ chối ca làm này? Ca làm sẽ được đưa trở lại bảng chung để nhân viên khác nhận.'),
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
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
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

    if (confirm == null) return;

    final response = await _viewModel.rejectJob(caLamId, lyDoHuy: confirm);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy nhận việc thành công.'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể từ chối ca làm này.')),
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
    DateTime selectedDate = DateTime.tryParse(job['NgayLamViec'] ?? '') ?? DateTime.now();
    TimeOfDay startTime = _parseTimeOfDay(job['GioBatDau'] ?? '08:00:00');
    TimeOfDay endTime = _parseTimeOfDay(job['GioKetThuc'] ?? '10:00:00');
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đổi Ca Làm Việc', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Ngày làm mới'),
                subtitle: Text(_formatDate(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.isBefore(DateTime.now()) ? DateTime.now() : selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Giờ bắt đầu'),
                subtitle: Text(startTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime);
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Giờ kết thúc'),
                subtitle: Text(endTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: endTime);
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do đổi ca',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final startMinutes = startTime.hour * 60 + startTime.minute;
                final endMinutes = endTime.hour * 60 + endTime.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Đổi Ca', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8225))),
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
      gioKetThuc: _formatTime(endTime),
      lyDo: reasonController.text.trim(),
    );
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi ca làm việc thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadMyJobs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể đổi ca làm việc.')),
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
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
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
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nhận Tất Cả', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
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

  // Hiển thị card tổng hợp cho đơn đặt lịch định kỳ
  Widget _buildRecurringJobCard(List<dynamic> jobs, Color orangeColor, Color darkColor) {
    final firstJob = jobs.first;
    final String services = firstJob['DichVu'] ?? '';
    final String address = firstJob['DiaChiLamViec'] ?? '';
    final String customerName = firstJob['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final String customerPhone = firstJob['KhachHang']?['SoDienThoai'] ?? '';
    final int totalShifts = jobs.length;
    final int completedShifts = jobs.where((j) => j['TrangThaiDonHang'] == 2).length;
    final int pendingConfirmShifts = jobs.where((j) => j['TrangThaiDonHang'] == 0).length;
    final bool allPending = pendingConfirmShifts == totalShifts;

    // Tính tổng lương thực nhận
    double totalEarnings = 0;
    for (final job in jobs) {
      final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
      totalEarnings += money * 0.8;
    }
    final String earningsStr = '${totalEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showRecurringDetailSheet(jobs, orangeColor, darkColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: orangeColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tên dịch vụ + Badge định kỳ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      services,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: orangeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: orangeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Định kỳ - $totalShifts ca',
                      style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Địa chỉ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Thông tin khách hàng
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Khách: $customerName ($customerPhone)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tiến độ hoàn thành
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$completedShifts/$totalShifts ca hoàn thành',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Lương + nút hành động
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng lương (80%):', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  // Nếu tất cả ca đều chờ xác nhận → hiện nút Nhận tất cả + Từ chối
                  if (allPending)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleRejectAllJobs(jobs),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('TỪ CHỐI', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleAcceptAllJobs(jobs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('NHẬN TẤT CẢ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  // Nếu có ca đang chờ xác nhận nhưng không phải tất cả → hiện thông tin
                  if (!allPending && pendingConfirmShifts > 0)
                    Text(
                      '$pendingConfirmShifts ca chờ xác nhận',
                      style: TextStyle(fontSize: 12, color: orangeColor, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hiển thị bottom sheet chi tiết các ca trong đơn định kỳ
  void _showRecurringDetailSheet(List<dynamic> jobs, Color orangeColor, Color darkColor) {
    final int maDatLich = jobs.first['MaDatLich'] ?? 0;
    final int totalShifts = jobs.length;
    final int completedShifts = jobs.where((j) => j['TrangThaiDonHang'] == 2).length;

    // Sắp xếp theo ngày làm việc
    final sortedJobs = List<dynamic>.from(jobs)
      ..sort((a, b) => (a['NgayLamViec'] ?? '').compareTo(b['NgayLamViec'] ?? ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Tiêu đề
              Row(
                children: [
                  Icon(Icons.repeat_rounded, color: orangeColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chi Tiết Đơn Định Kỳ - Đơn #$maDatLich',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Badge tiến độ
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📋 $completedShifts/$totalShifts ca hoàn thành',
                    style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Danh sách từng ca làm
              ...sortedJobs.map((job) {
                final int caLamId = job['MaCaLam'] ?? 0;
                final int status = job['TrangThaiDonHang'] ?? 1;
                final String date = job['NgayLamViec'] ?? '';
                final String start = job['GioBatDau']?.substring(0, 5) ?? '';
                final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
                final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
                final double providerEarnings = money * 0.8;
                final String earningsStr = '${providerEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

                // Xác định màu và text trạng thái
                Color statusColor;
                String statusText;
                switch (status) {
                  case 0:
                    statusColor = Colors.orange;
                    statusText = 'Chờ xác nhận';
                    break;
                  case 2:
                    statusColor = Colors.green;
                    statusText = 'Hoàn thành';
                    break;
                  case 3:
                    statusColor = Colors.red;
                    statusText = 'Đã hủy';
                    break;
                  default:
                    statusColor = Colors.blue;
                    statusText = 'Đã nhận';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ngày + trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Giờ làm + lương
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text('$start - $end', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                        ],
                      ),
                      // Nút hành động theo trạng thái
                      if (status == 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () { Navigator.pop(context); _handleCancelJob(caLamId); },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Từ Chối', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () { Navigator.pop(context); _handleAcceptJob(caLamId); },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                      if (status == 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () { Navigator.pop(context); _handleCancelJob(caLamId); },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Từ Chối', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () { Navigator.pop(context); _handleCompleteJob(caLamId); },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(dynamic job, Color orangeColor, Color darkColor) {
    final int id = job['MaCaLam'] ?? 0;
    final int status = job['TrangThaiDonHang'] ?? 1; // 0: Cho xac nhan, 1: Da nhan, 2: Hoan thanh, 3: Huy
    final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
    final double providerEarnings = money * 0.8;
    final String earningsStr = '${providerEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

    final String date = job['NgayLamViec'] ?? '';
    final String start = job['GioBatDau']?.substring(0, 5) ?? '';
    final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
    final String services = job['DichVu'] ?? '';
    final String address = job['DiaChiLamViec'] ?? '';
    final String customerName = job['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final String customerPhone = job['KhachHang']?['SoDienThoai'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showJobDetailSheet(context, job, orangeColor, darkColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade50),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Service & Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      services,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: orangeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status == 2 ? Colors.green : (status == 3 ? Colors.red : (status == 0 ? Colors.orange : Colors.blue))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 0 ? 'Chờ xác nhận' : (status == 2 ? 'Đã hoàn thành' : (status == 3 ? 'Đã hủy' : 'Đã nhận việc')),
                      style: TextStyle(
                        color: status == 2 ? Colors.green : (status == 3 ? Colors.red : Colors.blue),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Time & Date
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày làm: $date ($start - $end)',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Customer Info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Khách: $customerName ($customerPhone)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Action section & Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lương thực nhận (80%):', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  // Trạng thái 0: Chờ xác nhận → hiện nút Nhận việc + Từ chối
                  if (status == 0)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleCancelJob(id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Từ Chối'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleAcceptJob(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  // Trạng thái 1: Đã nhận → hiện nút Từ chối + Hoàn thành
                  if (status == 1)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleCancelJob(id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Từ Chối'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleCompleteJob(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetailSheet(BuildContext context, dynamic job, Color orangeColor, Color darkColor) {
    final int id = job['MaCaLam'] ?? 0;
    final int status = job['TrangThaiDonHang'] ?? 1;
    final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
    final double providerEarnings = money * 0.8;
    final double systemFee = money * 0.2;
    final String moneyStr = '${money.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
    final String earningsStr = '${providerEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
    final String feeStr = '${systemFee.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

    final String date = job['NgayLamViec'] ?? '';
    final String start = job['GioBatDau']?.substring(0, 5) ?? '';
    final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
    final String services = job['DichVu'] ?? '';
    final String address = job['DiaChiLamViec'] ?? '';
    final String note = job['MoTaCongViec'] ?? '';
    final String customerName = job['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final String customerPhone = job['KhachHang']?['SoDienThoai'] ?? '';
    final String customerEmail = job['KhachHang']?['Email'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Title
              Row(
                children: [
                  Icon(Icons.assignment_rounded, color: orangeColor, size: 24),
                  const SizedBox(width: 8),
                  Text('Chi Tiết Ca Làm ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkColor)),
                ],
              ),
              const SizedBox(height: 6),
              // Status badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: (status == 2 ? Colors.green : (status == 3 ? Colors.red : (status == 0 ? Colors.orange : Colors.blue))).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 0 ? '🟠 Chờ xác nhận' : (status == 2 ? '✅ Đã hoàn thành' : (status == 3 ? '❌ Đã hủy' : '🔵 Đã nhận việc')),
                    style: TextStyle(
                      color: status == 2 ? Colors.green : (status == 3 ? Colors.red : Colors.blue),
                      fontWeight: FontWeight.bold, fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Service
              _detailRow(Icons.cleaning_services_rounded, 'Dịch vụ', services, orangeColor),
              const SizedBox(height: 12),
              // Date & Time
              _detailRow(Icons.calendar_today_rounded, 'Ngày làm', date, orangeColor),
              const SizedBox(height: 12),
              _detailRow(Icons.access_time_rounded, 'Giờ làm', '$start → $end', orangeColor),
              const SizedBox(height: 12),
              // Address
              _detailRow(Icons.location_on_rounded, 'Địa chỉ', address, orangeColor),
              const SizedBox(height: 12),
              // Note
              if (note.isNotEmpty) ...[
                _detailRow(Icons.notes_rounded, 'Ghi chú', note, orangeColor),
                const SizedBox(height: 12),
              ],

              const Divider(),
              const SizedBox(height: 12),

              // Customer info
              const Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _detailRow(Icons.person_rounded, 'Họ tên', customerName, Colors.blue),
              const SizedBox(height: 8),
              _detailRow(Icons.phone_rounded, 'SĐT', customerPhone, Colors.blue),
              const SizedBox(height: 8),
              if (customerEmail.isNotEmpty) ...[
                _detailRow(Icons.email_rounded, 'Email', customerEmail, Colors.blue),
                const SizedBox(height: 8),
              ],

              const Divider(),
              const SizedBox(height: 12),

              // Earnings
              const Text('Chi tiết thu nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _earningsRow('Tổng tiền ca làm', moneyStr, darkColor),
              const SizedBox(height: 6),
              _earningsRow('Phí hệ thống (20%)', '- $feeStr', Colors.red),
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 6),
              _earningsRow('Lương thực nhận', earningsStr, Colors.green, bold: true, fontSize: 17),
              const SizedBox(height: 20),

              // Yêu cầu đổi lịch đang chờ xử lý
              if (status == 0 || status == 1) ...[
                Builder(builder: (_) {
                  final List pendingRequests = (job['LichSuDoiLichs'] as List?) ?? [];
                  final hasPending = pendingRequests.isNotEmpty;

                  if (hasPending) {
                    final req = pendingRequests.first;
                    final requesterName = req['NguoiYeuCau']?['HoTenNguoiDung'] ?? 'Người dùng';
                    final requesterRole = req['NguoiYeuCau']?['VaiTro'] ?? 0;
                    final requestId = req['MaLichSu'] ?? 0;
                    final ngayMoiRaw = req['NgayMoi'] ?? '';
                    final gioBatDauMoiRaw = req['GioBatDauMoi'] ?? '';
                    final gioKetThucMoiRaw = req['GioKetThucMoi'] ?? '';
                    final ngayMoi = ngayMoiRaw.length >= 10 ? ngayMoiRaw.substring(0, 10) : ngayMoiRaw;
                    final gioBatDauMoi = gioBatDauMoiRaw.length >= 16 ? gioBatDauMoiRaw.substring(11, 16) : gioBatDauMoiRaw;
                    final gioKetThucMoi = gioKetThucMoiRaw.length >= 16 ? gioKetThucMoiRaw.substring(11, 16) : gioKetThucMoiRaw;
                    // requesterRole == 1 => khách hàng gửi => nhân viên xử lý (hiện nút)
                    // requesterRole == 2 => nhân viên gửi => đang chờ khách hàng phản hồi
                    final isResponder = requesterRole == 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, color: orangeColor, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Yêu cầu đổi ca (đang chờ)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _detailRow(Icons.person_outline, 'Người gửi', requesterName, Colors.blueGrey),
                          const SizedBox(height: 6),
                          _detailRow(Icons.calendar_today_outlined, 'Ngày mới', ngayMoi, Colors.blueGrey),
                          const SizedBox(height: 6),
                          _detailRow(Icons.schedule_outlined, 'Giờ mới', '$gioBatDauMoi - $gioKetThucMoi', Colors.blueGrey),
                          if (isResponder) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _handleRespondReschedule(requestId, false);
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('Từ Chối'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _handleRespondReschedule(requestId, true);
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Đồng Ý'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⏳ Đang chờ bên kia phản hồi...',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  // Không có yêu cầu đang chờ → hiện nút Đổi ca bình thường
                  return OutlinedButton.icon(
                    onPressed: () { Navigator.pop(context); _handleRescheduleJob(job); },
                    icon: const Icon(Icons.event_repeat_rounded, size: 18),
                    label: const Text('Đổi Ca Làm Việc'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orangeColor,
                      side: BorderSide(color: orangeColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              // Actions
              // Trạng thái 0: Chờ xác nhận → hiện nút Nhận việc + Từ chối
              if (status == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(context); _handleCancelJob(id); },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Từ Chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); _handleAcceptJob(id); },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('NHẬN VIỆC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Trạng thái 1: Đã nhận → hiện nút Từ chối + Hoàn thành
              if (status == 1) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(context); _handleCancelJob(id); },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Từ Chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); _handleCompleteJob(id); },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('HOÀN THÀNH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _earningsRow(String label, String value, Color valueColor, {bool bold = false, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: valueColor)),
      ],
    );
  }

  Widget _buildTabContent(List filteredList, Color orangeColor, Color darkColor) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        if (item['type'] == 'recurring') {
          return _buildRecurringJobCard(item['jobs'], orangeColor, darkColor);
        }
        return _buildJobCard(item['job'], orangeColor, darkColor);
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
          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _viewModel.loadMyJobs,
                color: orangeColor,
                child: _buildTabContent(activeJobs, orangeColor, darkColor),
              ),
              RefreshIndicator(
                onRefresh: _viewModel.loadMyJobs,
                color: orangeColor,
                child: _buildTabContent(historyJobs, orangeColor, darkColor),
              ),
            ],
          );
        },
      ),
    );
  }
}
