import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer/booking_detail_viewmodel.dart';
import '../../services/api_service.dart';
import '../../models/booking_model.dart';
import '../../widgets/provider_calendar_dialog.dart';
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

  bool _isWithin24Hours(String ngayLamViec, String gioKetThuc) {
    try {
      final dateStr = ngayLamViec.contains('T') ? ngayLamViec.split('T')[0] : ngayLamViec.split(' ')[0];
      final timeStr = gioKetThuc.length == 5 ? '$gioKetThuc:00' : gioKetThuc;
      final endDateTime = DateTime.parse('$dateStr $timeStr');
      final now = DateTime.now();
      return now.difference(endDateTime).inHours <= 24;
    } catch (e) {
      return true;
    }
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
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
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
              child: const Text('Hủy', style: TextStyle(color: Colors.black)),
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
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
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

  List<Map<String, dynamic>> _getMappedShifts(List<CaLamViecModel> allOtherShifts) {
    List<Map<String, dynamic>> mappedShifts = [];
    for (var s in allOtherShifts) {
      int status = s.trangThaiDonHang;
      if (status == 0 || status == 1 || status == 3) {
        String dateStr = s.ngayLamViec;
        if (dateStr.contains('T')) dateStr = dateStr.split('T')[0];
        
        mappedShifts.add({
          'date': dateStr,
          'start': s.gioBatDau.substring(0, 5),
          'end': s.gioKetThuc.substring(0, 5),
        });
      }
    }
    return mappedShifts;
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
          content: Text('Đã gửi yêu cầu đổi lịch'),
          backgroundColor: Colors.green,
        ),
      );
      _viewModel.loadBookingDetails(widget.maDatLich);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể xử lý yêu cầu.')),
      );
    }
  }
  Future<void> _showRescheduleDialog(dynamic shift) async {
    DateTime oldDate = DateTime.tryParse(shift.ngayLamViec) ?? DateTime.now();
    TimeOfDay oldStartTime = _parseTimeOfDay(shift.gioBatDau);
    TimeOfDay oldEndTime = _parseTimeOfDay(shift.gioKetThuc);
    
    DateTime selectedDate = oldDate;
    TimeOfDay startTime = oldStartTime;
    final reasonController = TextEditingController();

    int durationMins = (oldEndTime.hour - oldStartTime.hour) * 60 + (oldEndTime.minute - oldStartTime.minute);
    bool hasConflict = false;
    List<CaLamViecModel> allOtherShifts = [];
    bool isFetching = true;

    void _checkConflict() {
      if (isFetching) return;
      hasConflict = false;
      int newStartMins = startTime.hour * 60 + startTime.minute;
      int newEndMins = newStartMins + durationMins;
      String newDateStr = _formatDate(selectedDate);

      for (var s in allOtherShifts) {
        int status = s.trangThaiDonHang;
        if (status == 0 || status == 1 || status == 3) {
          String otherDateStr = s.ngayLamViec;
          if (otherDateStr.startsWith(newDateStr)) {
             TimeOfDay otherStart = _parseTimeOfDay(s.gioBatDau);
             TimeOfDay otherEnd = _parseTimeOfDay(s.gioKetThuc);
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

    ApiService.getBookings().then((res) {
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        for (var b in list) {
          final bModel = BookingModel.fromJson(b);
          for (var s in bModel.caLamViecs ?? []) {
            if (s.maCaLam != shift.maCaLam) {
               allOtherShifts.add(s);
            }
          }
        }
      }
      isFetching = false;
      _checkConflict();
    });

    final confirmed = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Gắn callback vào _checkConflict để nó có thể trigger UI update
          void updateConflict() {
            setDialogState(() {
              _checkConflict();
            });
          }

          // Cập nhật lại logic gọi fetch
          if (isFetching) {
            ApiService.getBookings().then((res) {
              if (res['success'] == true && res['data'] != null) {
                final List list = res['data'];
                allOtherShifts.clear();
                for (var b in list) {
                  final bModel = BookingModel.fromJson(b);
                  for (var s in bModel.caLamViecs ?? []) {
                    if (s.maCaLam != shift.maCaLam) {
                       allOtherShifts.add(s);
                    }
                  }
                }
              }
              isFetching = false;
              updateConflict();
            });
          }

          return AlertDialog(
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
              // Khung chọn lịch mới
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Ngày làm mới'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: isFetching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                      onTap: isFetching ? null : () async {
                        final picked = await showDialog<DateTime>(
                          context: context,
                          builder: (context) => ProviderCalendarDialog(
                            initialDate: selectedDate.isBefore(DateTime.now()) ? DateTime.now() : selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 180)),
                            providerShifts: _getMappedShifts(allOtherShifts),
                            plannedStartTime: startTime,
                            plannedDurationHours: durationMins / 60.0,
                          ),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          updateConflict();
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Giờ bắt đầu'),
                      subtitle: Text(startTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: startTime);
                        if (picked != null) {
                          startTime = picked;
                          updateConflict();
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (hasConflict)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Expanded(child: Text('Lịch này trùng với một ca làm việc khác của bạn.', style: TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
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
              child: const Text('Hủy đổi lịch', style: TextStyle(color: Color(0xFFFF8225))),
            ),
            TextButton(
              onPressed: hasConflict ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Ủy quyền hệ thống'),
                    content: const Text('Nếu nhân viên từ chối đổi lịch thì bạn có đồng ý ủy quyền cho hệ thống chọn nhân viên khác không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Từ chối', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8225)),
                        child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm != null) {
                  if (!context.mounted) return;
                  Navigator.pop(context, {'confirmed': true, 'uyQuyen': confirm});
                }
              },
              child: Text('Đổi Lịch', style: TextStyle(fontWeight: FontWeight.bold, color: hasConflict ? Colors.grey : const Color(0xFFFF8225))),
            ),
          ],
        );
      },
    ),
    );
    if (confirmed == null || confirmed['confirmed'] != true) return;

    bool isUyQuyen = confirmed['uyQuyen'] == true;

    final response = await _viewModel.rescheduleShift(
      shift.maCaLam,
      ngayLamViec: _formatDate(selectedDate),
      gioBatDau: _formatTime(startTime),
      lyDo: reasonController.text.trim(),
    );
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi lịch làm việc thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadBookingDetails(widget.maDatLich);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể đổi lịch làm việc.')),
      );
    }
  }

  Future<void> _handleChangeProvider(int caLamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi Nhân Viên', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đổi nhân viên cho ca làm việc này? Nhân viên hiện tại sẽ bị gỡ và ca sẽ được chuyển về bảng tin để nhân viên khác nhận.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng Ý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await _viewModel.changeProvider(caLamId);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi nhân viên thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadBookingDetails(widget.maDatLich);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Không thể đổi nhân viên.')),
      );
    }
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
        final priceStr = '${NumberFormat('#,###', 'vi_VN').format(booking.giaGoi.toInt())} đ';

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
                        final shiftPrice = '${NumberFormat('#,###', 'vi_VN').format(shift.tongTien.toInt())} đ';

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
                                
                                // Yêu cầu đổi lịch đang chờ xử lý
                                if (shift.trangThaiDonHang == 0 || shift.trangThaiDonHang == 1) ...[
                                  const SizedBox(height: 12),
                                  if (shift.lichSuDoiLichs.isNotEmpty) ...[
                                    // Có yêu cầu đổi lịch đang chờ
                                    Builder(builder: (_) {
                                      final req = shift.lichSuDoiLichs.first;
                                      final requesterName = req.nguoiYeuCau?.hoTenNguoiDung ?? 'Người dùng';
                                      final requesterRole = req.nguoiYeuCau?.vaiTro ?? 0;
                                      final ngayMoiRaw = req.ngayMoi ?? '';
                                      final gioBatDauMoiRaw = req.gioBatDauMoi ?? '';
                                      final gioKetThucMoiRaw = req.gioKetThucMoi ?? '';
                                      final ngayMoi = ngayMoiRaw.length >= 10 ? ngayMoiRaw.substring(0, 10) : ngayMoiRaw;
                                      final gioBatDauMoi = gioBatDauMoiRaw.length >= 16 ? gioBatDauMoiRaw.substring(11, 16) : gioBatDauMoiRaw;
                                      final gioKetThucMoi = gioKetThucMoiRaw.length >= 16 ? gioKetThucMoiRaw.substring(11, 16) : gioKetThucMoiRaw;
                                      // requesterRole == 2 => nhân viên gửi yêu cầu => khách hàng xử lý (hiện nút)
                                      // requesterRole == 1 => khách hàng tự gửi => đang chờ nhân viên phản hồi
                                      final isResponder = requesterRole == 2;

                                      return Container(
                                        padding: const EdgeInsets.all(12),
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
                                                Icon(Icons.swap_horiz_rounded, color: orangeColor, size: 18),
                                                const SizedBox(width: 6),
                                                const Expanded(
                                                  child: Text(
                                                    'Yêu cầu đổi lịch (đang chờ)',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text('👤 Người gửi: $requesterName', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                            const SizedBox(height: 4),
                                            Text('📅 Ngày mới: $ngayMoi', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                            const SizedBox(height: 4),
                                            Text('⏰ Giờ mới: $gioBatDauMoi - $gioKetThucMoi', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                            if (isResponder) ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () => _handleRespondReschedule(req.maLichSu, false),
                                                      icon: const Icon(Icons.close_rounded, size: 14),
                                                      label: const Text('Từ Chối'),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: Colors.red,
                                                        side: const BorderSide(color: Colors.red),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _handleRespondReschedule(req.maLichSu, true),
                                                      icon: const Icon(Icons.check_rounded, size: 14),
                                                      label: const Text('Đồng Ý'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  ' Đang chờ bên kia phản hồi...',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ] else ...[
                                    // Không có yêu cầu đang chờ → hiện nút Đổi lịch bình thường
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (shift.nhanVien != null) ...[
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.person_remove_rounded, size: 14),
                                              label: const Text('Đổi nhân viên'),
                                              onPressed: () => _handleChangeProvider(shift.maCaLam),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.event_repeat_rounded, size: 14),
                                            label: const Text('Đổi Lịch'),
                                            onPressed: () => _showRescheduleDialog(shift),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: orangeColor,
                                              side: const BorderSide(color: orangeColor),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],

                                // Feedback Actions
                                if (shift.trangThaiDonHang == 2 && _isWithin24Hours(shift.ngayLamViec, shift.gioKetThuc) && (!shift.daDanhGia || !shift.daKhieuNai)) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!shift.daDanhGia)
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
                                      if (!shift.daDanhGia && !shift.daKhieuNai)
                                        const SizedBox(width: 8),
                                      if (!shift.daKhieuNai)
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
