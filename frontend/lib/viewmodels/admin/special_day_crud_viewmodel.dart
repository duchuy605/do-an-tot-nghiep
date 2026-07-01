import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class SpecialDayCrudViewModel extends ChangeNotifier {
  List _specialDays = [];
  bool _isLoading = true;

  List get specialDays => _specialDays;
  bool get isLoading => _isLoading;

  Future<void> loadSpecialDays() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getSpecialDays();
      if (response['success'] == true) {
        _specialDays = response['data'] ?? [];
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteSpecialDay(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.deleteSpecialDay(id);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createSpecialDay(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.createSpecialDay(data);
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
