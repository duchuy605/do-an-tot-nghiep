import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class AdminMainViewModel extends ChangeNotifier {
  String? _email;

  String? get email => _email;

  Future<void> loadEmail() async {
    _email = await ApiService.getUserEmail();
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.clearAuth();
  }
}
