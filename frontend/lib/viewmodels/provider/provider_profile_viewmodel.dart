import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ProviderProfileViewModel extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _hoso;
  bool _activeStatus = false;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get hoso => _hoso;
  bool get activeStatus => _activeStatus;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void setActiveStatus(bool val) {
    _activeStatus = val;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getProviderProfile();
      if (response['success'] == true) {
        _user = response['data'];
        _hoso = _user?['HoSoNhanVien'];
        _activeStatus = _hoso?['TrangThaiHoatDong'] == true || _hoso?['TrangThaiHoatDong'] == 1;
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
      final response = await ApiService.updateProviderProfile(data);
      _isLoading = false;
      if (response['success'] == true) {
        _user = response['data'];
        _hoso = _user?['HoSoNhanVien'];
        _activeStatus = _hoso?['TrangThaiHoatDong'] == true || _hoso?['TrangThaiHoatDong'] == 1;
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> toggleActiveStatus(bool value) async {
    _activeStatus = value;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.updateProviderProfile({
        'TrangThaiHoatDong': value,
      });
      _isLoading = false;
      if (response['success'] != true) {
        _activeStatus = !value; // Rollback
      }
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      _activeStatus = !value; // Rollback
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
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
