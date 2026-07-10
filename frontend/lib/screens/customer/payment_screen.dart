import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer/payment_viewmodel.dart';
import 'customer_wallet.dart';

class PaymentScreen extends StatefulWidget {
  final int maDatLich;

  const PaymentScreen({super.key, required this.maDatLich});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentViewModel _viewModel = PaymentViewModel();
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadPaymentData(widget.maDatLich);
  }

  @override
  void dispose() {
    _promoController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _applyPromo() {
    _viewModel.applyPromo(_promoController.text);
  }

  Future<void> _processPayment() async {
    final booking = _viewModel.booking;
    if (booking == null) return;

    final finalPrice = booking.giaGoi - _viewModel.discountAmount;

    if (_viewModel.walletBalance < finalPrice) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Số Dư Không Đủ', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Số dư tài khoản ví CleanGoPay của bạn không đủ để thực hiện giao dịch này. Vui lòng nạp thêm tiền vào ví để tiếp tục.',
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
                ).then((_) => _viewModel.loadPaymentData(widget.maDatLich));
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
      return;
    }

    final response = await _viewModel.processPayment(widget.maDatLich);

    if (!mounted) return;

    if (response['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Đơn đặt lịch #${widget.maDatLich} của bạn đã được thanh toán qua ví CleanGoPay.',
                style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return success
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8225),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'XÁC NHẬN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Thanh toán thất bại')),
      );
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount.toInt())} đ';
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
            appBar: AppBar(
              title: const Text('Thanh Toán'),
              backgroundColor: Colors.white,
              foregroundColor: darkColor,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_viewModel.errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadPaymentData(widget.maDatLich),
                    style: ElevatedButton.styleFrom(backgroundColor: orangeColor),
                    child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final booking = _viewModel.booking!;
        final originalPrice = booking.giaGoi;
        final finalPrice = originalPrice - _viewModel.discountAmount;

        String tenDichVu = 'Dịch vụ giúp việc';
        if (booking.datDichVus != null && booking.datDichVus!.isNotEmpty) {
          tenDichVu = booking.datDichVus!.first.service?.tenDichVu ?? booking.caLamViecs?.first.dichVu ?? 'Dịch vụ giúp việc';
        } else if (booking.caLamViecs != null && booking.caLamViecs!.isNotEmpty) {
          tenDichVu = booking.caLamViecs!.first.dichVu;
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: darkColor,
            elevation: 0,
            centerTitle: true,
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
                                        tenDichVu,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        booking.loaiDatLich == 1 ? 'Lịch làm 1 lần' : 'Lịch làm định kỳ (${booking.soBuoi} buổi)',
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
                            
                            // time and dates
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Khung giờ: ${booking.gioBatDau.substring(0, 5)} - ${booking.gioKetThuc.substring(0, 5)}',
                                  style: const TextStyle(fontSize: 14, color: darkColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  booking.loaiDatLich == 1
                                      ? 'Ngày làm: ${booking.ngayBatDau}'
                                      : 'Định kỳ: Từ ${booking.ngayBatDau} đến ${booking.ngayKetThuc}',
                                  style: const TextStyle(fontSize: 14, color: darkColor),
                                ),
                              ],
                            ),
                            if (booking.thuTrongTuan != null && booking.thuTrongTuan!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.repeat_rounded, color: Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Các ngày làm việc: Thứ ${booking.thuTrongTuan}',
                                    style: const TextStyle(fontSize: 14, color: orangeColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.diaChiLamViec,
                                    style: const TextStyle(fontSize: 14, color: darkColor, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method (Single Wallet CleanGoPay)
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
                            const Text(
                              'Phương Thức Thanh Toán',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
                            ),
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
                                    decoration: BoxDecoration(
                                      color: orangeColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: orangeColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ví CleanGoPay',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
                                        ),
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
                                        ).then((_) => _viewModel.loadPaymentData(widget.maDatLich));
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Nạp tiền',
                                        style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Promo Code Cards
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
                            const Text(
                              'Khuyến Mãi',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _promoController,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập mã giảm giá (VD: BTASKEE50)',
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                      prefixIcon: const Icon(Icons.local_offer_outlined, color: Colors.grey, size: 20),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: orangeColor),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _applyPromo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    elevation: 0,
                                  ),
                                  child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            if (_viewModel.promoSuccessMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _viewModel.promoSuccessMessage!,
                                style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                            if (_viewModel.promoErrorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _viewModel.promoErrorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Text(
                              'Mã giảm giá cho bạn:',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _promoController.text = 'BTASKEE50';
                                    _applyPromo();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: const Text(
                                      'BTASKEE50 (-50k)',
                                      style: TextStyle(fontSize: 11, color: orangeColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _promoController.text = 'NHAMOI';
                                    _applyPromo();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: const Text(
                                      'NHAMOI (Giảm 10%)',
                                      style: TextStyle(fontSize: 11, color: orangeColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bill Details
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
                            const Text(
                              'Chi Tiết Thanh Toán',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Giá gói dịch vụ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                Text(_formatCurrency(originalPrice), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: darkColor)),
                              ],
                            ),
                            if (_viewModel.discountAmount > 0) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Khuyến mãi áp dụng', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  Text('- ${_formatCurrency(_viewModel.discountAmount)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.red)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng cộng',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkColor),
                                ),
                                Text(
                                  _formatCurrency(finalPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: orangeColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom sticky footer button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(finalPrice),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        child: const Text(
                          'XÁC NHẬN THANH TOÁN',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_viewModel.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: orangeColor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
