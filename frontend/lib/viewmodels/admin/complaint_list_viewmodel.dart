import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class ComplaintListViewModel extends ChangeNotifier {
  // Các trường trạng thái nội bộ
  List _complaints = [];
  List _resolutionTypes = [];
  bool _isLoading = true;
  int? _filterStatus;

  // Các phương thức getter công khai
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
  // [BẢO VỆ ĐỒ ÁN - GIẢI THÍCH LOGIC XỬ LÝ KHIẾU NẠI & HOÀN TIỀN]
  // Hàm `resolveComplaint` chịu trách nhiệm gọi API xử lý khiếu nại dựa trên `hinhThuc` (hình thức giải quyết) và `refund` (số tiền liên quan).
  // - `hinhThuc`: Là định danh (ID) của phương án giải quyết được quản trị viên lựa chọn (ví dụ: hoàn tiền toàn bộ, hoàn tiền một phần, phạt nhân viên...).
  // - `refund`: Là số tiền cụ thể được hoàn lại cho khách hàng hoặc số tiền phạt áp dụng lên nhân viên.
  // 
  // CHI TIẾT LOGIC HOÀN TIỀN VÀ PHẠT:
  // 1. Nếu quyết định là HOÀN TIỀN (Refund) cho khách:
  //    - Backend sẽ tiến hành cộng trực tiếp số tiền `refund` vào ví điện tử (wallet) của khách hàng trên hệ thống.
  //    - Đồng thời, nếu lỗi hoàn toàn do nhân viên, số tiền này (hoặc một phần tùy quy định) có thể bị khấu trừ từ thu nhập hoặc số dư ví của nhân viên đó.
  // 2. Nếu quyết định là PHẠT TIỀN (Fine) nhân viên:
  //    - Số tiền `refund` trong trường hợp này mang ý nghĩa là khoản tiền phạt. Backend sẽ tiến hành tạo giao dịch trừ tiền từ tài khoản của nhân viên.
  // 3. Tính toàn vẹn và đối soát dữ liệu (Data Integrity & Auditing):
  //    - Mọi sự thay đổi về tiền (cộng/trừ) đều sinh ra các bản ghi giao dịch (transaction logs) trong cơ sở dữ liệu. Điều này giúp đảm bảo tính minh bạch, dễ dàng đối soát (reconciliation) về sau và là bằng chứng giải quyết khiếu nại.
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
