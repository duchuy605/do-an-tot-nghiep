import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  // Private state fields
  int _currentStep = 1; // 1 = email, 2 = OTP + new password
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Public getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscureNewPassword => _obscureNewPassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void toggleObscureNewPassword() {
    _obscureNewPassword = !_obscureNewPassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  /// Gửi mã xác nhận qua email (Step 1)
  Future<Map<String, dynamic>> sendCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.forgotPassword(email);
      if (response['success'] == true) {
        _currentStep = 2;
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _errorMessage = response['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }
    } catch (_) {
      _errorMessage = 'Không thể kết nối đến máy chủ';
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  /// Đặt lại mật khẩu (Step 2)
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.resetPassword(email, otp, newPassword);
      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _errorMessage = response['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }
    } catch (_) {
      _errorMessage = 'Không thể kết nối đến máy chủ';
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }
}
