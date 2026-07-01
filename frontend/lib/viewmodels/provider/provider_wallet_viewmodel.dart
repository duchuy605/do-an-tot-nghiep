import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ProviderWalletViewModel extends ChangeNotifier {
  double _balance = 0;
  List _history = [];
  bool _isLoading = true;

  double get balance => _balance;
  List get history => _history;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadWalletData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final walletResponse = await ApiService.getWallet();
      final historyResponse = await ApiService.getWalletHistory();

      if (walletResponse['success'] == true) {
        _balance = double.tryParse(walletResponse['data']['SoDu']?.toString() ?? '0') ?? 0;
      }
      if (historyResponse['success'] == true) {
        _history = historyResponse['data'] ?? [];
      }
    } catch (_) {
      // Ignored for robustness
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> withdrawWallet(int amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.withdrawWallet(amount);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
