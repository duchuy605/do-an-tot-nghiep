import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';

class CustomerBookingsViewModel extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getBookings();
      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        _bookings = list.map((e) => BookingModel.fromJson(e)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Lỗi tải danh sách đơn đặt lịch';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createReview(int caLamId, int rating, String comment) async {
    try {
      final response = await ApiService.createReview(caLamId, rating, comment);
      return response;
    } catch (_) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createComplaint(int caLamId, String title, String content) async {
    try {
      final response = await ApiService.createComplaint(caLamId, title, content);
      return response;
    } catch (_) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
