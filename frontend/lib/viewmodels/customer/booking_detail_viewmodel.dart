import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';

class BookingDetailViewModel extends ChangeNotifier {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;

  BookingModel? get booking => _booking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadBookingDetails(int maDatLich) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getBookingDetail(maDatLich);
      if (response['success'] == true) {
        _booking = BookingModel.fromJson(response['data']);
      } else {
        _errorMessage = response['message'] ?? 'Lỗi tải thông tin đơn hàng';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int maDatLich, {String? lyDoHuy}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.cancelBooking(maDatLich, lyDoHuy: lyDoHuy ?? '');
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createReview(int caLamId, int rating, String comment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.createReview(caLamId, rating, comment);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createComplaint(int caLamId, String title, String content) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.createComplaint(caLamId, title, content);
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
