import 'package:flutter/material.dart';
import '../../viewmodels/customer/booking_detail_viewmodel.dart';
import 'payment_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final int maDatLich;

  const BookingDetailScreen({super.key, required this.maDatLich});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingDetailViewModel _viewModel = BookingDetailViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadBookingDetails(widget.maDatLich);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    final booking = _viewModel.booking;
    final isPaid = booking != null && booking.trangThai == 2;
    final confirmMessage = isPaid
        ? 'Bạn có chắc muốn hủy đơn này? Số tiền đã thanh toán sẽ được hoàn vào ví của bạn.'
        : 'Bạn có chắc chắn muốn hủy đơn đặt lịch này không?';
    final lyDoController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác Nhận Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(confirmMessage),
            const SizedBox(height: 16),
            TextField(
              controller: lyDoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy đơn *',
                hintText: 'Nhập lý do hủy đơn...',
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
              if (lyDoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy đơn'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Hủy Đơn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.cancelBooking(widget.maDatLich, lyDoHuy: lyDoController.text.trim());
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hủy đơn đặt lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _viewModel.loadBookingDetails(widget.maDatLich);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể hủy đơn hàng này.')),
      );
    }
  }

  void _showReviewDialog(int caLamId) {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đánh Giá Ca Làm Việc', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng chọn số sao đánh giá:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starCount = index + 1;
                  return IconButton(
                    icon: Icon(
                      starCount <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedStars = starCount;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final response = await _viewModel.createReview(
                  caLamId,
                  selectedStars,
                  commentController.text.trim(),
                );
                if (!mounted) return;
                if (response['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đánh giá thành công!'), backgroundColor: Colors.green),
                  );
                  _viewModel.loadBookingDetails(widget.maDatLich);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message'] ?? 'Lỗi gửi đánh giá.')),
                  );
                }
              },
              child: const Text('Gửi Đánh Giá', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8225))),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog(int caLamId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gửi Khiếu Nại', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề khiếu nại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Chi tiết sự cố xảy ra',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context);
              final response = await _viewModel.createComplaint(
                caLamId,
                titleController.text.trim(),
                descController.text.trim(),
              );
              if (!mounted) return;
              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi khiếu nại lên hệ thống quản trị!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['message'] ?? 'Lỗi gửi khiếu nại.')),
                );
              }
            },
            child: const Text('Gửi Khiếu Nại', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getShiftStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chờ thanh toán';
      case 1:
        return 'Chờ nhận việc';
      case 2:
        return 'Đã hoàn thành';
      case 3:
        return 'Đã hủy';
      default:
        return 'Đang xử lý';
    }
  }

  Color _getShiftStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.booking == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: orangeColor)),
          );
        }

        if (_viewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi Tiết Đơn Hàng'), backgroundColor: orangeColor),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_viewModel.errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadBookingDetails(widget.maDatLich),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final booking = _viewModel.booking!;
        final priceStr = '${booking.giaGoi.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text('Đơn Đặt Lịch #${booking.maDatLich}', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: darkColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (booking.trangThai == 2)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: _handleCancel,
                  tooltip: 'Hủy đơn',
                ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary billing card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng Thanh Toán:',
                                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  priceStr,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            // Working address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.diaChiLamViec,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkColor, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Time Slot
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Khung giờ: ${booking.gioBatDau.substring(0, 5)} - ${booking.gioKetThuc.substring(0, 5)}',
                                  style: const TextStyle(fontSize: 14, color: darkColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Duration
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  booking.loaiDatLich == 1
                                      ? 'Một lần: ${booking.ngayBatDau}'
                                      : 'Định kỳ: Từ ${booking.ngayBatDau} đến ${booking.ngayKetThuc}',
                                  style: const TextStyle(fontSize: 14, color: darkColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (booking.thuTrongTuan != null && booking.thuTrongTuan!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.repeat_rounded, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Các ngày làm việc: Thứ ${booking.thuTrongTuan}',
                                    style: const TextStyle(fontSize: 14, color: orangeColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            if (booking.moTaCongViec != null && booking.moTaCongViec!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 6),
                              const Text('Ghi chú của khách hàng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkColor)),
                              const SizedBox(height: 4),
                              Text(booking.moTaCongViec!, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detail Shifts
                    const Text(
                      'Danh Sách Ca Làm Chi Tiết',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: booking.caLamViecs?.length ?? 0,
                      itemBuilder: (context, index) {
                        final shift = booking.caLamViecs![index];
                        final shiftPrice = '${shift.tongTien.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ca ngày: ${shift.ngayLamViec}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkColor),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getShiftStatusColor(shift.trangThaiDonHang).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getShiftStatusText(shift.trangThaiDonHang),
                                        style: TextStyle(
                                          color: _getShiftStatusColor(shift.trangThaiDonHang),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Dịch vụ: ${shift.dichVu}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('Chi phí ca: $shiftPrice', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
                                if (shift.nhanVien != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor: orangeColor,
                                          radius: 16,
                                          child: Icon(Icons.person, size: 18, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shift.nhanVien!.hoTenNguoiDung,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkColor),
                                              ),
                                              Text(
                                                'SĐT: ${shift.nhanVien!.soDienThoai}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Feedback Actions
                                if (shift.trangThaiDonHang == 2) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.star_rounded, size: 14),
                                        label: const Text('Đánh giá'),
                                        onPressed: () => _showReviewDialog(shift.maCaLam),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.amber.shade800,
                                          side: BorderSide(color: Colors.amber.shade600),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.warning_rounded, size: 14),
                                        label: const Text('Khiếu nại'),
                                        onPressed: () => _showComplaintDialog(shift.maCaLam),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Bottom checkout bar
              if (booking.trangThai == 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Đơn hàng chưa thanh toán', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: orangeColor)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(maDatLich: booking.maDatLich),
                              ),
                            ).then((_) {
                              _viewModel.loadBookingDetails(widget.maDatLich);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('THANH TOÁN NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_viewModel.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: orangeColor)),
                ),
            ],
          ),
        );
      },
    );
  }
}
