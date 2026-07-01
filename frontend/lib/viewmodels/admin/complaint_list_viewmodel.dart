import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ComplaintListViewModel extends ChangeNotifier {
  // Private state fields
  List _complaints = [];
  List _resolutionTypes = [];
  bool _isLoading = true;
  int? _filterStatus;

  // Public getters
  List get complaints => _complaints;
  List get resolutionTypes => _resolutionTypes;
  bool get isLoading => _isLoading;
  int? get filterStatus => _filterStatus;

  void setFilterStatus(int? status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> loadComplaints() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getComplaints(),
        ApiService.getResolutionTypes(),
      ]);
      final complaintsResponse = results[0];
      final typesResponse = results[1];
      if (complaintsResponse['success'] == true) {
        _complaints = complaintsResponse['data'] ?? [];
      }
      if (typesResponse['success'] == true) {
        _resolutionTypes = typesResponse['data'] ?? [];
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> processComplaint(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.processComplaint(id);
      _isLoading = false;
      notifyListeners();
      if (response['success'] == true) {
        await loadComplaints();
      }
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  // Gửi yêu cầu giải quyết khiếu nại lên server
  Future<Map<String, dynamic>> resolveComplaint(int id, int hinhThuc, double? refund) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.resolveComplaint(id, hinhThuc, refund);
      _isLoading = false;
      notifyListeners();
      if (response['success'] == true) {
        await loadComplaints();
      }
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
