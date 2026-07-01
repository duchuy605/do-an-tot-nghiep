import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class UserManagementViewModel extends ChangeNotifier {
  List _users = [];
  bool _isLoading = true;

  List get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getUsers();
      if (response['success'] == true) {
        _users = response['data'] ?? [];
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> toggleLockUser(int id, bool isCurrentlyActive) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = isCurrentlyActive
          ? await ApiService.lockUser(id)
          : await ApiService.unlockUser(id);
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
