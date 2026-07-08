import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class MyJobsViewModel extends ChangeNotifier {
  List _myJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  List get myJobs => _myJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadMyJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileResponse = await ApiService.getProfile();
      final jobsResponse = await ApiService.getJobs();

      if (profileResponse['success'] == true && jobsResponse['success'] == true) {
        final currentUserId = profileResponse['data']['MaNguoiDung'];
        final List list = jobsResponse['data'] ?? [];
        _myJobs = list.where((job) => job['MaNhanVien'] == currentUserId).toList();
      } else {
        _errorMessage = jobsResponse['message'] ?? 'Lỗi tải danh sách công việc của tôi';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> completeJob(int caLamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.completeJob(caLamId);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }

  Future<Map<String, dynamic>> rejectJob(int caLamId, {String? lyDoHuy}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.rejectJob(caLamId, lyDoHuy: lyDoHuy ?? '');
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }

  // Nhận việc cho ca chờ xác nhận
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
  Future<Map<String, dynamic>> rescheduleShift(
    int caLamId, {
    required String ngayLamViec,
    required String gioBatDau,
    String lyDo = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.rescheduleShift(
        caLamId,
        ngayLamViec: ngayLamViec,
        gioBatDau: gioBatDau,
        lyDo: lyDo,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }

  /// Đồng ý hoặc từ chối yêu cầu đổi lịch từ khách hàng
  Future<Map<String, dynamic>> respondRescheduleRequest(int requestId, bool dongY) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.respondRescheduleRequest(requestId, dongY);
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
