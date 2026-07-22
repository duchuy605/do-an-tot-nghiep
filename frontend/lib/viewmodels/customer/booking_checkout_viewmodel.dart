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
  double _durationCoeff = 1.0;
  double _totalDurationDiscount = 0.0;
  List<dynamic> _detailedServices = [];
  double _totalTimeSlotSurcharge = 0;
  double _totalWeekendSurcharge = 0;
  double _totalSpecialDaySurcharge = 0;
  double _totalProviderSurcharge = 0;

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
  double get durationCoeff => _durationCoeff;
  double get totalDurationDiscount => _totalDurationDiscount;
  List<dynamic> get detailedServices => _detailedServices;
  double get discountAmount => _discountAmount;
  String? get promoSuccessMessage => _promoSuccessMessage;
  String? get promoErrorMessage => _promoErrorMessage;
  double get totalTimeSlotSurcharge => _totalTimeSlotSurcharge;
  double get totalWeekendSurcharge => _totalWeekendSurcharge;
  double get totalSpecialDaySurcharge => _totalSpecialDaySurcharge;
  double get totalProviderSurcharge => _totalProviderSurcharge;

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
        _durationCoeff = (data['durationCoeff'] as num?)?.toDouble() ?? 1.0;
        _detailedServices = data['detailedServices'] ?? [];

        double baseServicesPrice = 0.0;
        for (var s in _detailedServices) {
          baseServicesPrice += (s['price'] as num?)?.toDouble() ?? 0.0;
        }
        _totalDurationDiscount = baseServicesPrice * (1.0 - _durationCoeff) * _totalSessions;
        _totalDurationDiscount = (_totalDurationDiscount / 1000).round() * 1000;

        debugPrint('[CLEANGO] API response durationCoeff: $_durationCoeff');
        debugPrint('[CLEANGO] Calculated totalDurationDiscount: $_totalDurationDiscount');

        // Tính tổng phụ thu từ sessionDetails bằng cách sử dụng các hệ số
        final sessions = data['sessionDetails'] as List<dynamic>? ?? [];
        _totalTimeSlotSurcharge = 0;
        _totalWeekendSurcharge = 0;
        _totalSpecialDaySurcharge = 0;
        _totalProviderSurcharge = 0;
        for (var session in sessions) {
          final double basePrice = (session['BasePrice'] as num?)?.toDouble() ?? 0.0;
          final double hskg = (session['HeSoKhungGio'] as num?)?.toDouble() ?? 1.0;
          final double hsct = (session['HeSoCuoiTuan'] as num?)?.toDouble() ?? 1.0;
          final double hsdb = (session['HeSoDacBiet'] as num?)?.toDouble() ?? 1.0;

          // Tính phụ thu thực tế theo hệ số
          final double phuThuKhungGio = basePrice * (hskg - 1.0);
          final double phuThuCuoiTuan = basePrice * (hsct - 1.0);
          final double phuThuNgayDacBiet = basePrice * (hsdb - 1.0);

          _totalTimeSlotSurcharge += (phuThuKhungGio / 1000).round() * 1000;
          _totalWeekendSurcharge += (phuThuCuoiTuan / 1000).round() * 1000;
          _totalSpecialDaySurcharge += (phuThuNgayDacBiet / 1000).round() * 1000;

          if (_providerSurchargePercent > 0) {
            double sessionFinalPrice = basePrice * hskg * hsct * hsdb;
            if (_packageDiscountPercent > 0) {
              sessionFinalPrice = sessionFinalPrice * (1.0 - _packageDiscountPercent / 100.0);
            }
            final double phuThuChonNhanVien = sessionFinalPrice * (_providerSurchargePercent / 100.0);
            _totalProviderSurcharge += (phuThuChonNhanVien / 1000).round() * 1000;
          }
        }
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
