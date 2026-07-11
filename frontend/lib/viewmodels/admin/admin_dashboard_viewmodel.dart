import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _currentWeekOffset = 0;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  int get currentWeekOffset => _currentWeekOffset;

  void changeWeek(int delta) {
    _currentWeekOffset += delta;
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getDashboard(weekOffset: _currentWeekOffset);
      if (response['success'] == true) {
        _stats = response['data'] ?? {};
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
