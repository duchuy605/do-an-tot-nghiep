import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class TimeSlotCrudViewModel extends ChangeNotifier {
  List _timeSlots = [];
  bool _isLoading = true;

  List get timeSlots => _timeSlots;
  bool get isLoading => _isLoading;

  Future<void> loadTimeSlots() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getTimeSlots();
      if (response['success'] == true) {
        _timeSlots = response['data'] ?? [];
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteTimeSlot(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.deleteTimeSlot(id);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createTimeSlot(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.createTimeSlot(data);
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
