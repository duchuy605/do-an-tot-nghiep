import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer/customer_bookings_viewmodel.dart';
import '../../models/booking_model.dart';
import 'booking_detail.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => CustomerBookingsScreenState();
}

class CustomerBookingsScreenState extends State<CustomerBookingsScreen> with SingleTickerProviderStateMixin {
  final CustomerBookingsViewModel _viewModel = CustomerBookingsViewModel();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel.loadBookings();
  }

  void reloadData() {
    _viewModel.loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  String _getBookingStatusText(int status) {
    switch (status) {
      case 0:
        return 'Đã hủy';
      case 2:
        return 'Đang hoạt động';
      case 3:
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Color _getBookingStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatPrice(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount.toInt())} đ';
  }

  // Kiểm tra đơn có ca hoàn thành nào chưa đánh giá không
  bool _hasUnreviewedShifts(BookingModel booking) {
    if (booking.caLamViecs == null) return false;
    return booking.caLamViecs!.any((ca) => ca.trangThaiDonHang == 2 && !ca.daDanhGia);
  }

  // Kiểm tra đơn có ca hoàn thành nào chưa khiếu nại không
  bool _hasUnComplainedShifts(BookingModel booking) {
    if (booking.caLamViecs == null) return false;
    return booking.caLamViecs!.any((ca) => ca.trangThaiDonHang == 2 && !ca.daKhieuNai);
  }

  Widget _buildBookingCard(BookingModel booking, Color orangeColor, Color darkColor, {bool showActions = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(maDatLich: booking.maDatLich),
                ),
              ).then((_) => _viewModel.loadBookings());
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Order ID & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đơn hàng #${booking.maDatLich}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E24)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getBookingStatusColor(booking.trangThai).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getBookingStatusText(booking.trangThai),
                          style: TextStyle(
                            color: _getBookingStatusColor(booking.trangThai),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Working address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.diaChiLamViec,
                          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date and Time Slots
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Bắt đầu: ${booking.ngayBatDau}',
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        booking.gioBatDau.substring(0, 5),
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Total Payment & Sessions count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Số buổi: ${booking.soBuoi}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _formatPrice(booking.giaGoi),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF8225)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action buttons for completed bookings
          if (showActions) ...[
            if (_hasUnreviewedShifts(booking) || _hasUnComplainedShifts(booking))
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    if (_hasUnreviewedShifts(booking))
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReviewDialog(booking),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade700,
                            side: BorderSide(color: Colors.amber.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (_hasUnreviewedShifts(booking) && _hasUnComplainedShifts(booking))
                      const SizedBox(width: 10),
                    if (_hasUnComplainedShifts(booking))
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showComplaintDialog(booking),
                          icon: const Icon(Icons.report_problem_rounded, size: 18),
                          label: const Text('Khiếu nại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ==================== ĐÁNH GIÁ DIALOG ====================
  void _showReviewDialog(BookingModel booking) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    // Lấy ca hoàn thành đầu tiên chưa đánh giá
    final completedShift = booking.caLamViecs?.firstWhere(
      (ca) => ca.trangThaiDonHang == 2 && !ca.daDanhGia,
      orElse: () => booking.caLamViecs!.first,
    );

    if (completedShift == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đánh Giá Dịch Vụ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đơn hàng #${booking.maDatLich}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingLabel(selectedRating),
                    style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // Comment field
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhận xét thêm về dịch vụ...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        setSheetState(() => isSubmitting = true);
                        try {
                          final response = await _viewModel.createReview(
                            completedShift.maCaLam,
                            selectedRating,
                            commentController.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đánh giá thành công! Cảm ơn bạn.'), backgroundColor: Colors.green),
                            );
                            _viewModel.loadBookings();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'] ?? 'Đánh giá thất bại.'), backgroundColor: Colors.red),
                            );
                          }
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lỗi kết nối máy chủ.'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8225),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('GỬI ĐÁNH GIÁ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'Rất tệ';
      case 2: return 'Tệ';
      case 3: return 'Bình thường';
      case 4: return 'Tốt';
      case 5: return 'Tuyệt vời';
      default: return '';
    }
  }

  // ==================== KHIẾU NẠI DIALOG ====================
  void _showComplaintDialog(BookingModel booking) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isSubmitting = false;

    final completedShift = booking.caLamViecs?.firstWhere(
      (ca) => ca.trangThaiDonHang == 2,
      orElse: () => booking.caLamViecs!.first,
    );

    if (completedShift == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.report_problem_rounded, color: Colors.red.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Khiếu Nại Dịch Vụ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đơn hàng #${booking.maDatLich}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Tiêu đề khiếu nại',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Content field
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung.'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        setSheetState(() => isSubmitting = true);
                        try {
                          final response = await _viewModel.createComplaint(
                            completedShift.maCaLam,
                            titleController.text.trim(),
                            contentController.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Khiếu nại đã được gửi! Chúng tôi sẽ xử lý sớm.'), backgroundColor: Colors.green),
                            );
                            _viewModel.loadBookings();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'] ?? 'Gửi khiếu nại thất bại.'), backgroundColor: Colors.red),
                            );
                          }
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lỗi kết nối máy chủ.'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('GỬI KHIẾU NẠI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabContent(List<BookingModel> filteredList, Color orangeColor, Color darkColor, {bool showActions = false}) {
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showActions ? Icons.check_circle_outline_rounded : Icons.assignment_late_outlined,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              showActions ? 'Chưa có đơn hoàn thành' : 'Không có đơn hàng nào ở mục này',
              style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(filteredList[index], orangeColor, darkColor, showActions: showActions);
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
        title: const Text('Lịch Sử Hoạt Động', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Tab(text: 'Hoạt động'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }

          final activeBookings = _viewModel.bookings.where((b) => b.trangThai == 2).toList();
          final completedBookings = _viewModel.bookings.where((b) => b.trangThai == 3).toList();
          final canceledBookings = _viewModel.bookings.where((b) => b.trangThai == 0).toList();

          activeBookings.sort((a, b) {
            int dateCmp = a.ngayBatDau.compareTo(b.ngayBatDau);
            if (dateCmp != 0) return dateCmp;
            return a.gioBatDau.compareTo(b.gioBatDau);
          });

          completedBookings.sort((a, b) {
            int dateCmp = b.ngayBatDau.compareTo(a.ngayBatDau);
            if (dateCmp != 0) return dateCmp;
            return b.gioBatDau.compareTo(a.gioBatDau);
          });

          canceledBookings.sort((a, b) {
            int dateCmp = b.ngayBatDau.compareTo(a.ngayBatDau);
            if (dateCmp != 0) return dateCmp;
            return b.gioBatDau.compareTo(a.gioBatDau);
          });

          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _viewModel.loadBookings,
                color: orangeColor,
                child: _buildTabContent(activeBookings, orangeColor, darkColor),
              ),
              RefreshIndicator(
                onRefresh: _viewModel.loadBookings,
                color: orangeColor,
                child: _buildTabContent(completedBookings, orangeColor, darkColor, showActions: true),
              ),
              RefreshIndicator(
                onRefresh: _viewModel.loadBookings,
                color: orangeColor,
                child: _buildTabContent(canceledBookings, orangeColor, darkColor),
              ),
            ],
          );
        },
      ),
    );
  }
}
