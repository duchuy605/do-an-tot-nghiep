import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer/booking_checkout_viewmodel.dart';
import '../../models/service_model.dart';
import 'customer_wallet.dart';

/// Màn hình thanh toán trước khi tạo đơn đặt lịch.
/// Nhận dữ liệu booking từ BookingForm, hiện tóm tắt, 
/// xác nhận thanh toán → gọi API createBooking (atomic).
class BookingCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final ServiceModel mainService;
  final List<ServiceModel> additionalServices; // dịch vụ bổ sung đã chọn
  final double durationHours;
  final int bookingType; // 1: Một lần, 2: Định kỳ

  const BookingCheckoutScreen({
    super.key,
    required this.bookingData,
    required this.mainService,
    required this.additionalServices,
    required this.durationHours,
    required this.bookingType,
  });

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final BookingCheckoutViewModel _viewModel = BookingCheckoutViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadData(widget.bookingData);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final response = await _viewModel.processPayment(widget.bookingData);

    if (!mounted) return;

    if (response['insufficientBalance'] == true) {
      _showInsufficientBalanceDialog();
      return;
    }

    if (response['success'] == true) {
      final data = response['data'];
      final totalPaid = data['totalPaid'];
      final newBalance = data['newBalance'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đã thanh toán ${_formatCurrency(totalPaid?.toDouble() ?? 0)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Số dư ví còn lại: ${_formatCurrency(newBalance?.toDouble() ?? 0)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng đã được gửi đến nhân viên.\nVui lòng chờ nhận việc.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(this.context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8225),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('XONG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } else {
      final msg = response['message'] ?? 'Thanh toán thất bại.';
      if (msg.contains('Số dư') || msg.contains('ví') || msg.contains('không đủ')) {
        _showInsufficientBalanceDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Số Dư Không Đủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Số dư ví CleanGoPay không đủ để thanh toán. Vui lòng nạp thêm tiền.',
          style: TextStyle(height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerWalletScreen()),
              ).then((_) => _viewModel.loadData(widget.bookingData));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8225),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Nạp tiền ví', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Xác Nhận Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }

          final finalPrice = _viewModel.finalPrice;
          final gioBatDau = widget.bookingData['GioBatDau']?.toString().substring(0, 5) ?? '';
          final gioKetThuc = widget.bookingData['GioKetThuc']?.toString().substring(0, 5) ?? '';
          final diaChi = widget.bookingData['DiaChiLamViec'] ?? '';
          final ngayBatDau = widget.bookingData['NgayBatDau'] ?? '';
          final ngayKetThuc = widget.bookingData['NgayKetThuc'] ?? '';
          final thuTrongTuan = widget.bookingData['ThuTrongTuan'] as String?;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === Card 1: Thông tin đơn hàng ===
                    _buildCard([
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: orangeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.cleaning_services_rounded, color: orangeColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mainService.tenDichVu,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.bookingType == 1 ? 'Lịch làm 1 lần' : 'Lịch làm định kỳ',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Thời gian
                      _buildInfoRow(Icons.access_time_rounded, 'Khung giờ: $gioBatDau - $gioKetThuc'),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.timelapse_rounded, () {
                        final h = widget.durationHours.floor();
                        final m = ((widget.durationHours - h) * 60).round();
                        final label = (m == 0) ? '$h giờ/buổi' : '$h giờ $m phút/buổi';
                        return 'Thời lượng: $label';
                      }()),
                      const SizedBox(height: 10),

                      // Ngày
                      _buildInfoRow(
                        Icons.calendar_month_outlined,
                        widget.bookingType == 1
                            ? 'Ngày làm: $ngayBatDau'
                            : 'Từ $ngayBatDau đến $ngayKetThuc',
                      ),

                      if (thuTrongTuan != null && thuTrongTuan.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.repeat_rounded, color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Thứ: $thuTrongTuan',
                              style: const TextStyle(fontSize: 14, color: orangeColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.location_on_outlined, diaChi),
                    ]),
                    const SizedBox(height: 16),

                    // === Card 2: Danh sách dịch vụ ===
                    _buildCard([
                      const Text('Dịch Vụ Đã Chọn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                      const SizedBox(height: 12),

                      // Dịch vụ chính
                      _buildServiceRow(widget.mainService.tenDichVu, widget.mainService.donGia, 1, isMain: true),

                      // Dịch vụ bổ sung
                      ...widget.additionalServices.map((svc) {
                        final qty = widget.bookingData['DichVus']
                            .where((d) => d['MaDichVu'] == svc.maDichVu)
                            .map((d) => d['SoLuong'] as int)
                            .fold(0, (a, b) => a + b);
                        return _buildServiceRow(svc.tenDichVu, svc.donGia, qty);
                      }),
                    ]),
                    const SizedBox(height: 16),

                    // === Card 3: Phương thức thanh toán ===
                    _buildCard([
                      const Text('Phương Thức Thanh Toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: orangeColor.withOpacity(0.5), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          color: orangeColor.withOpacity(0.04),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: orangeColor.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: orangeColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ví CleanGoPay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Số dư: ${_formatCurrency(_viewModel.walletBalance)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _viewModel.walletBalance >= finalPrice ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: orangeColor, size: 24),
                          ],
                        ),
                      ),
                      if (_viewModel.walletBalance < finalPrice) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Số dư ví không đủ. Vui lòng nạp thêm.',
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CustomerWalletScreen()),
                                  ).then((_) => _viewModel.loadData(widget.bookingData));
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Nạp tiền', style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),

                    // === Card 5: Chi tiết thanh toán ===
                    _buildCard([
                      const Text('Chi Tiết Thanh Toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                      const SizedBox(height: 16),
                      ..._viewModel.detailedServices.map((service) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${service['serviceName']} (${service['hours']} Giờ)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              Text(_formatCurrency((service['price'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: darkColor)),
                            ],
                          ),
                        );
                      }),
                      Builder(builder: (ctx) {
                        double totalCaPrice = 0;
                        double totalCaHours = 0;
                        for (var s in _viewModel.detailedServices) {
                          totalCaPrice += (s['price'] as num).toDouble();
                          totalCaHours += (s['hours'] as num).toDouble();
                        }
                        if (totalCaPrice == 0) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            _buildPriceRow('Tổng / 1 ca (${totalCaHours.toStringAsFixed(1)} Giờ)', totalCaPrice),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildPriceRow('Số buổi', _viewModel.totalSessions.toDouble(), isSuffix: ' buổi'),
                      if (_viewModel.packageDiscountPercent > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giảm giá gói', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                              '-${_viewModel.packageDiscountPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                      if (_viewModel.totalDurationDiscount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giảm giá ca làm ${widget.durationHours.toStringAsFixed(1)} giờ (${((1.0 - _viewModel.durationCoeff) * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            Text(
                              '-${_formatCurrency(_viewModel.totalDurationDiscount)}',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                      if (_viewModel.providerSurchargePercent > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phụ phí chọn nhân viên', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(
                              '+${_viewModel.providerSurchargePercent.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.orange),
                            ),
                          ],
                        ),
                      ],
                      if (_viewModel.totalTimeSlotSurcharge > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Phụ thu khung giờ', _viewModel.totalTimeSlotSurcharge),
                      ],
                      if (_viewModel.totalWeekendSurcharge > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Phụ thu Thứ 7 / Chủ nhật', _viewModel.totalWeekendSurcharge),
                      ],
                      if (_viewModel.totalSpecialDaySurcharge > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Phụ thu ngày Lễ/Tết', _viewModel.totalSpecialDaySurcharge),
                      ],
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 4),
                      _buildPriceRow('Thành tiền (đã áp hệ số)', _viewModel.estimatedPrice),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkColor)),
                          Text(
                            _formatCurrency(finalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: orangeColor),
                          ),
                        ],
                      ),
                    ]),
                  ],
                ),
              ),

              // Bottom sticky button
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
                            const Text('Tổng thanh toán:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(finalPrice),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _viewModel.isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        child: _viewModel.isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'XÁC NHẬN THANH TOÁN',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_viewModel.isProcessing)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: orangeColor)),
                ),
            ],
          );
        },
      ),
    );
  }

  // === Helper Widgets ===
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E24), height: 1.3)),
        ),
      ],
    );
  }

  Widget _buildServiceRow(String name, double price, int qty, {bool isMain = false}) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isMain ? orangeColor : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: darkColor,
                fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (!isMain && qty > 0) Text('$qty giờ  ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            '${_formatCurrency(price)}/giờ',
            style: TextStyle(
              fontSize: 13,
              color: isMain ? orangeColor : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, String? isSuffix}) {
    String displayValue;
    if (isSuffix != null) {
      displayValue = '${amount.toStringAsFixed(0)}$isSuffix';
    } else if (isDiscount) {
      displayValue = '- ${_formatCurrency(amount.abs())}';
    } else {
      displayValue = _formatCurrency(amount);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          displayValue,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDiscount ? Colors.red : const Color(0xFF1E1E24),
          ),
        ),
      ],
    );
  }
}
