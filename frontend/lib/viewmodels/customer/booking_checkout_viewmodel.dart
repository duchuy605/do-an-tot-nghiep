import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

/// ViewModel cho màn hình thanh toán trước khi tạo đơn đặt lịch.
class BookingCheckoutViewModel extends ChangeNotifier {
  // Private state fields
  double _walletBalance = 0;
  double _estimatedPrice = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Chi tiết từ API preview
  int _totalSessions = 1;
  double _baseRatePerHour = 0;
  double _packageDiscountPercent = 0;
  double _providerSurchargePercent = 0;
  List<dynamic> _detailedServices = [];

  // Promo
  double _discountAmount = 0;
  String? _promoSuccessMessage;
  String? _promoErrorMessage;

  // Public getters
  double get walletBalance => _walletBalance;
  double get estimatedPrice => _estimatedPrice;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  int get totalSessions => _totalSessions;
  double get baseRatePerHour => _baseRatePerHour;
  double get packageDiscountPercent => _packageDiscountPercent;
  double get providerSurchargePercent => _providerSurchargePercent;
  List<dynamic> get detailedServices => _detailedServices;
  double get discountAmount => _discountAmount;
  String? get promoSuccessMessage => _promoSuccessMessage;
  String? get promoErrorMessage => _promoErrorMessage;

  double get finalPrice => _estimatedPrice - _discountAmount;

  /// Gọi song song: lấy số dư ví + tính giá từ backend
  Future<void> loadData(Map<String, dynamic> bookingData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getWallet(),
        ApiService.previewBookingPrice(bookingData),
      ]);

      final walletResponse = results[0];
      final previewResponse = results[1];

      if (walletResponse['success'] == true) {
        _walletBalance = double.tryParse(walletResponse['data']['SoDu']?.toString() ?? '0') ?? 0.0;
      }

      if (previewResponse['success'] == true) {
        final data = previewResponse['data'];
        _estimatedPrice = (data['totalPrice'] as num).toDouble();
        _totalSessions = data['totalSessions'] ?? 1;
        _baseRatePerHour = (data['baseRatePerHour'] as num?)?.toDouble() ?? 0;
        _packageDiscountPercent = (data['packageDiscountPercent'] as num?)?.toDouble() ?? 0;
        _providerSurchargePercent = (data['providerSurchargePercent'] as num?)?.toDouble() ?? 0;
        _detailedServices = data['detailedServices'] ?? [];
      } else {
        _errorMessage = previewResponse['message'] ?? 'Không thể tính giá.';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyPromo(String code, double estimatedPrice) {
    final upperCode = code.trim().toUpperCase();
    if (upperCode.isEmpty) return;

    _promoErrorMessage = null;
    _promoSuccessMessage = null;

    if (upperCode == 'BTASKEE50') {
      _discountAmount = 50000;
      if (_discountAmount > estimatedPrice) _discountAmount = estimatedPrice;
      _promoSuccessMessage = 'Áp dụng mã giảm 50.000 đ thành công!';
    } else if (upperCode == 'NHAMOI') {
      _discountAmount = (estimatedPrice * 0.1);
      _discountAmount = (double.parse((_discountAmount / 1000).toStringAsFixed(0)) * 1000);
      _promoSuccessMessage = 'Áp dụng mã giảm 10% thành công!';
    } else {
      _discountAmount = 0;
      _promoErrorMessage = 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn.';
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> bookingData) async {
    final price = _estimatedPrice - _discountAmount;

    if (_walletBalance < price) {
      return {'success': false, 'insufficientBalance': true};
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final response = await ApiService.createBooking(bookingData);
      _isProcessing = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isProcessing = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
