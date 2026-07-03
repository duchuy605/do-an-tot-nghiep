import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';

class PaymentViewModel extends ChangeNotifier {
  BookingModel? _booking;
  double _walletBalance = 0;
  bool _isLoading = true;
  String? _errorMessage;

  double _discountAmount = 0;
  String? _promoSuccessMessage;
  String? _promoErrorMessage;

  BookingModel? get booking => _booking;
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get discountAmount => _discountAmount;
  String? get promoSuccessMessage => _promoSuccessMessage;
  String? get promoErrorMessage => _promoErrorMessage;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadPaymentData(int maDatLich) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookingResponse = await ApiService.getBookingDetail(maDatLich);
      final walletResponse = await ApiService.getWallet();

      if (bookingResponse['success'] == true) {
        _booking = BookingModel.fromJson(bookingResponse['data']);
      } else {
        _errorMessage = bookingResponse['message'] ?? 'Lỗi tải thông tin đơn đặt lịch.';
      }

      if (walletResponse['success'] == true) {
        _walletBalance = double.tryParse(walletResponse['data']['SoDu']?.toString() ?? '0') ?? 0.0;
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyPromo(String code) {
    code = code.trim().toUpperCase();
    if (code.isEmpty) return;

    if (_booking == null) return;
    final originalPrice = _booking!.giaGoi;

    _promoErrorMessage = null;
    _promoSuccessMessage = null;

    if (code == 'BTASKEE50') {
      _discountAmount = 50000;
      if (_discountAmount > originalPrice) {
        _discountAmount = originalPrice;
      }
      _promoSuccessMessage = 'Áp dụng mã giảm 50.000 đ thành công!';
    } else if (code == 'NHAMOI') {
      _discountAmount = (originalPrice * 0.1); // Giảm 10%
      _discountAmount = (double.parse((_discountAmount / 1000).toStringAsFixed(0)) * 1000);
      _promoSuccessMessage = 'Áp dụng mã giảm 10% thành công!';
    } else {
      _discountAmount = 0;
      _promoErrorMessage = 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn.';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> processPayment(int maDatLich) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.payBooking(maDatLich);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
