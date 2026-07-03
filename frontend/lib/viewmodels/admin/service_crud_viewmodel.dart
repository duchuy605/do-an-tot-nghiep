import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/service_model.dart';

class ServiceCrudViewModel extends ChangeNotifier {
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getServices();
      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        _services = list.map((e) => ServiceModel.fromJson(e)).toList();
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteService(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.deleteService(id);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.createService(data);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.updateService(id, data);
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
