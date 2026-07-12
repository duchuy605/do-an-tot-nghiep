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

  Future<Map<String, dynamic>> startJob(int caLamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.startJob(caLamId);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối.'};
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

  /// Hàm xử lý logic nhận việc (acceptJob) cho các ca chờ xác nhận từ góc độ Frontend.
  /// 
  /// Trong quy trình của ứng dụng, thao tác nhận việc này cho phép nhân viên xác nhận làm một ca cụ thể.
  /// Logic vận hành và kiểm tra trùng lặp (Overlap checking) được thiết kế như sau:
  /// 
  /// 1. Cập nhật trạng thái giao diện: Biến trạng thái `_isLoading` được gán bằng `true`, kết hợp với `notifyListeners()` để yêu cầu tầng UI render lại và hiển thị biểu tượng loading. Điều này khóa thao tác UI tạm thời, tránh việc nhân viên bấm nút nhận việc nhiều lần liên tiếp gây ra gửi trùng lặp request.
  /// 2. Gọi API đến Server: Sử dụng `ApiService.acceptJob(caLamId)` để giao tiếp với backend qua giao thức HTTP.
  /// 3. Logic kiểm tra trùng lặp thời gian (Overlap checking):
  ///    - Về mặt lý thuyết, Frontend có thể duyệt qua danh sách `_myJobs` để kiểm tra thủ công xem ca làm mới có thời gian (start time - end time) giao thoa với các ca đã nhận hay không.
  ///    - TUY NHIÊN, để đảm bảo tính nhất quán của dữ liệu và bảo mật nghiệp vụ (Bảo vệ luận văn), logic này được quyết định giao hoàn toàn cho Backend xử lý.
  ///    - Nguyên nhân: Backend đóng vai trò "Single Source of Truth". Nếu thực hiện kiểm tra ở Frontend, chúng ta sẽ gặp rủi ro "Race Condition" khi dữ liệu trả về từ API có độ trễ, hoặc nhân viên sử dụng nhiều thiết bị. Backend sử dụng các cơ chế database level (như Transaction lock) để truy vấn và phát hiện Overlap một cách an toàn tuyệt đối.
  ///    - Frontend đóng vai trò tiếp nhận: Khi xảy ra trùng giờ, API từ Backend sẽ trả lời bằng một object JSON chứa `success: false` và `message` mô tả lỗi trùng lặp. Frontend chỉ việc parse thông báo này và báo cho người dùng.
  /// 4. Xử lý phản hồi (Response Handling):
  ///    - Trả về đối tượng `Map<String, dynamic>` cho View (Widget) gọi nó. View sẽ dựa vào trường `success` để hiển thị Snackbar báo lỗi (nếu trùng ca/lỗi) hoặc điều hướng/cập nhật lại danh sách nếu thành công.
  /// 5. Đảm bảo luồng thực thi: Khối `try-catch` đảm bảo mọi ngoại lệ (như mất mạng, server sập) đều được xử lý gọn gàng. Ở mọi tình huống (kể cả Exception), biến `_isLoading` đều được reset về `false` để khôi phục trạng thái UI.
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
