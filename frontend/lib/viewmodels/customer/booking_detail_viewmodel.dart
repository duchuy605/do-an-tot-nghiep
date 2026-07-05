import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';

class BookingDetailViewModel extends ChangeNotifier {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId;

  BookingModel? get booking => _booking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentUserId => _currentUserId;

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
  Future<Map<String, dynamic>> rescheduleShift(
    int caLamId, {
    required String ngayLamViec,
    required String gioBatDau,
    String lyDo = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.rescheduleShift(
        caLamId,
        ngayLamViec: ngayLamViec,
        gioBatDau: gioBatDau,
        lyDo: lyDo,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  /// Đồng ý hoặc từ chối yêu cầu đổi lịch từ nhân viên
  Future<Map<String, dynamic>> respondRescheduleRequest(int requestId, bool dongY) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.respondRescheduleRequest(requestId, dongY);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  /// Đổi nhân viên (chỉ khi hệ thống tự gán)
  Future<Map<String, dynamic>> changeProvider(int caLamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.changeProvider(caLamId);
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
