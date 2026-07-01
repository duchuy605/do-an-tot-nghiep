import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class PackageCrudViewModel extends ChangeNotifier {
  List _packages = [];
  bool _isLoading = true;

  List get packages => _packages;
  bool get isLoading => _isLoading;

  Future<void> loadPackages() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getPackages();
      if (response['success'] == true) {
        _packages = response['data'] ?? [];
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deletePackage(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.deletePackage(id);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.createPackage(data);
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
