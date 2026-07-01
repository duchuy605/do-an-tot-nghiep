import 'package:flutter/material.dart';
import '../../viewmodels/provider/job_board_viewmodel.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => JobBoardScreenState();
}

class JobBoardScreenState extends State<JobBoardScreen> {
  final JobBoardViewModel _viewModel = JobBoardViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadAvailableJobs();
  }

  void reloadData() {
    _viewModel.loadAvailableJobs();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Format số tiền có dấu phẩy
  String _formatMoney(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  // Xử lý nhận 1 ca làm việc đơn lẻ
  Future<void> _handleAcceptJob(int caLamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác Nhận Nhận Việc', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn chắc chắn muốn nhận ca làm việc này không? Hãy sắp xếp thời gian đến đúng giờ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nhận Ca', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8225))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.acceptJob(caLamId);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhận ca làm việc thành công! Vui lòng kiểm tra ở mục Việc của tôi.'), backgroundColor: Colors.green),
      );
      _viewModel.loadAvailableJobs();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nhận Việc Thất Bại', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(response['message'] ?? 'Hồ sơ chưa được duyệt hoặc trạng thái hoạt động đang tắt.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        ),
      );
    }
  }

  // Xử lý nhận tất cả ca làm việc định kỳ
  Future<void> _handleAcceptRecurringJobs(List<dynamic> jobs) async {
    final int totalShifts = jobs.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhận Việc Định Kỳ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn sẽ nhận tất cả $totalShifts ca làm việc trong đơn đặt lịch định kỳ này. Bạn chắc chắn chứ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nhận Tất Cả', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8225))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int successCount = 0;
    int failCount = 0;

    for (final job in jobs) {
      final int caLamId = job['MaCaLam'] ?? 0;
      if (caLamId == 0) continue;
      final response = await _viewModel.acceptJob(caLamId);
      if (response['success'] == true) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;

    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nhận thành công $successCount ca làm việc! Vui lòng kiểm tra ở mục Việc của tôi.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nhận được $successCount/$totalShifts ca. $failCount ca thất bại.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _viewModel.loadAvailableJobs();
  }

  // Hiển thị bottom sheet chi tiết các ca làm việc định kỳ
  void _showRecurringShiftsDetail(List<dynamic> jobs) {
    const orangeColor = Color(0xFFFF8225);
    final firstJob = jobs.first;
    final String services = firstJob['DichVu'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Thanh kéo
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Tiêu đề
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat_rounded, color: orangeColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$services - ${jobs.length} ca',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Danh sách các ca
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: jobs.length,
                    separatorBuilder: (context, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final shift = jobs[index];
                      final String date = shift['NgayLamViec'] ?? '';
                      final String start = shift['GioBatDau']?.substring(0, 5) ?? '';
                      final String end = shift['GioKetThuc']?.substring(0, 5) ?? '';
                      final double money = double.tryParse(shift['TongTien']?.toString() ?? '0') ?? 0;
                      final double earnings = money * 0.8;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: orangeColor.withValues(alpha: 0.1),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: orangeColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'Ngày $date',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$start - $end',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        trailing: Text(
                          _formatMoney(earnings),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Card cho ca làm việc đơn lẻ (giữ nguyên giao diện cũ)
  Widget _buildSingleJobCard(dynamic job, Color orangeColor) {
    final int id = job['MaCaLam'] ?? 0;
    final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
    final double providerEarnings = money * 0.8;
    final String earningsStr = _formatMoney(providerEarnings);

    final String date = job['NgayLamViec'] ?? '';
    final String start = job['GioBatDau']?.substring(0, 5) ?? '';
    final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
    final String services = job['DichVu'] ?? '';
    final String address = job['DiaChiLamViec'] ?? '';
    final String customerName = job['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';

    return Container(
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
            // Tên dịch vụ & Thu nhập
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    services,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF8225)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  earningsStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
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

            // Ngày giờ
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

            // Khách hàng
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Khách hàng: $customerName',
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Nút nhận việc
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thu nhập (80%):',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => _handleAcceptJob(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                  ),
                  child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card cho đơn đặt lịch định kỳ (gom nhóm nhiều ca)
  Widget _buildRecurringJobCard(List<dynamic> jobs, Color orangeColor) {
    final firstJob = jobs.first;
    final String services = firstJob['DichVu'] ?? '';
    final String address = firstJob['DiaChiLamViec'] ?? '';
    final String customerName = firstJob['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final int totalShifts =
      firstJob['DonDatLich']?['SoBuoi'] ?? jobs.length;

    // Tính tổng thu nhập từ tất cả các ca
    double totalEarnings = 0;
    for (final job in jobs) {
      final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
      totalEarnings += money * 0.8;
    }
    final String earningsStr = _formatMoney(totalEarnings);

    return GestureDetector(
      onTap: () => _showRecurringShiftsDetail(jobs),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên dịch vụ & Badge định kỳ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      services,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF8225)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: orangeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded, size: 14, color: orangeColor),
                        const SizedBox(width: 4),
                        Text(
                          'Định kỳ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: orangeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Số ca làm việc
              Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Đặt định kỳ - $totalShifts ca',
                    style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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

              // Khách hàng
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Khách hàng: $customerName',
                    style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Tổng thu nhập & nút nhận tất cả
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng thu nhập (80%):',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        earningsStr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _handleAcceptRecurringJobs(jobs),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    child: const Text('NHẬN TẤT CẢ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),

              // Gợi ý nhấn xem chi tiết
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nhấn để xem chi tiết từng ca',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
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
        title: const Text('Bảng Việc Có Sẵn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _viewModel.loadAvailableJobs,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }

          if (_viewModel.availableJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có ca làm việc nào đang chờ nhận.',
                    style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // Gom nhóm theo MaDatLich cho đặt lịch định kỳ
          final List<Map<String, dynamic>> displayItems = [];
          final Map<int, List<dynamic>> recurringGroups = {};

          for (final job in _viewModel.availableJobs) {
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

          return RefreshIndicator(
            onRefresh: _viewModel.loadAvailableJobs,
            color: orangeColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];
                if (item['type'] == 'recurring') {
                  // Card gom nhóm định kỳ
                  return _buildRecurringJobCard(item['jobs'] as List<dynamic>, orangeColor);
                } else {
                  // Card đơn lẻ
                  return _buildSingleJobCard(item['job'], orangeColor);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
