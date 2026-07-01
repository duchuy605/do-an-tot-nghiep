import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class JobBoardViewModel extends ChangeNotifier {
  List _availableJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  List get availableJobs => _availableJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadAvailableJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getJobs();
      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        _availableJobs = list.where((job) => job['MaNhanVien'] == null && job['TrangThaiDonHang'] == 1).toList();
      } else {
        _errorMessage = response['message'] ?? 'Lỗi tải danh sách công việc';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> acceptJob(int caLamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.acceptJob(caLamId);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }
}
