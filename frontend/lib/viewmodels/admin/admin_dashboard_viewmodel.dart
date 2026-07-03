import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getDashboard();
      if (response['success'] == true) {
        _stats = response['data'] ?? {};
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
