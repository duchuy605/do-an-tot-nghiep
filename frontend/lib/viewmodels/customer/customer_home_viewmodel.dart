import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/service_model.dart';

class CustomerHomeViewModel extends ChangeNotifier {
  List<ServiceModel> _services = [];
  double _walletBalance = 0;
  String _customerName = 'Khách hàng';
  bool _isLoading = true;

  List<ServiceModel> get services => _services;
  double get walletBalance => _walletBalance;
  String get customerName => _customerName;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final svcResponse = await ApiService.getServices();
      final walletResponse = await ApiService.getWallet();
      final profileResponse = await ApiService.getProfile();

      if (svcResponse['success'] == true) {
        final List list = svcResponse['data'];
        _services = list.map((e) => ServiceModel.fromJson(e)).toList();
      }

      if (walletResponse['success'] == true) {
        _walletBalance = double.tryParse(walletResponse['data']['SoDu']?.toString() ?? '0') ?? 0;
      }

      if (profileResponse['success'] == true) {
        _customerName = profileResponse['data']['HoTenNguoiDung'] ?? 'Khách hàng';
      }
    } catch (_) {
      // Ignored for robustness
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
