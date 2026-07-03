import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return response;
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return response;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối máy chủ. Vui lòng thử lại sau.';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }
}
