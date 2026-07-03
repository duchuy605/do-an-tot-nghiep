import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class RegisterViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  int _role = 1; // 1: Customer, 2: Provider
  String _gender = 'Nam';
  DateTime _birthDate = DateTime(1995, 1, 1);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get role => _role;
  String get gender => _gender;
  DateTime get birthDate => _birthDate;

  void setRole(int value) {
    _role = value;
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void setBirthDate(DateTime value) {
    _birthDate = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> regData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(regData);
      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return response;
      } else {
        _errorMessage = response['message'] ?? 'Đăng ký thất bại. Vui lòng kiểm tra lại.';
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
