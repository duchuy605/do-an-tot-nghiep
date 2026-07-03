import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ApproveProviderViewModel extends ChangeNotifier {
  List _providers = [];
  bool _isLoading = true;

  List get providers => _providers;
  bool get isLoading => _isLoading;

  Future<void> loadProviders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getAdminProviders();
      if (response['success'] == true) {
        _providers = response['data'] ?? [];
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> approveProvider(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.approveProvider(id);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> rejectProvider(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.rejectProvider(id);
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
