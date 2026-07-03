import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class CustomerProfileViewModel extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        _user = response['data'];
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.updateProfile(data);
      _isLoading = false;
      if (response['success'] == true) {
        _user = response['data'];
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }

  String get avatarUrl {
    final avatar = _user?['AnhDaiDien'];
    if (avatar == null || avatar.toString().isEmpty) return '';
    return '${ApiService.baseUrl.replaceAll('/api', '')}$avatar';
  }

  Future<Map<String, dynamic>> uploadAvatar(dynamic bytes, String fileName) async {
    try {
      final response = await ApiService.uploadAvatar(bytes, fileName);
      if (response['success'] == true) {
        await loadProfile();
      }
      return response;
    } catch (_) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<void> logout() async {
    await ApiService.clearAuth();
  }
}
