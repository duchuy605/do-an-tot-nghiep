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

  /// Hàm xử lý logic nhận việc (acceptJob) từ góc độ Frontend.
  /// 
  /// Trong hệ thống, thao tác nhận việc yêu cầu nhân viên chọn một ca làm việc đang ở trạng thái trống (chưa có người nhận).
  /// Quá trình này bao gồm các bước sau:
  /// 
  /// 1. Cập nhật trạng thái giao diện: Đặt `_isLoading = true` và gọi `notifyListeners()` để báo cho UI hiển thị vòng lặp tải (loading indicator), ngăn người dùng bấm nhận nhiều lần (tránh spam request).
  /// 2. Gửi yêu cầu API: Gọi `ApiService.acceptJob(caLamId)` để gửi request lên backend.
  /// 3. Kiểm tra trùng lặp thời gian (Overlap checking):
  ///    - Mặc dù frontend có thể kiểm tra danh sách ca hiện tại của nhân viên để xem có trùng lịch không (bằng cách so sánh thời gian bắt đầu và kết thúc của ca sắp nhận với các ca đã có),
  ///    - NHƯNG logic kiểm tra trùng lặp chính xác và an toàn nhất (Source of Truth) PHẢI được đặt ở Backend. Lý do:
  ///      + Tránh Race Condition (Điều kiện tương tranh): Nếu 2 người cùng bấm nhận 1 ca cùng lúc, hoặc nhân viên bấm nhận 2 ca trùng giờ trên 2 thiết bị khác nhau, frontend không thể tự đồng bộ. Backend sử dụng Transaction/Lock trong cơ sở dữ liệu sẽ kiểm tra và ngăn chặn chính xác.
  ///      + Do đó, nhiệm vụ của frontend ở đây là ủy quyền kiểm tra trùng lịch cho backend và nhận kết quả trả về. Nếu backend phát hiện trùng ca hoặc ca đã có người nhận, nó sẽ trả về HTTP response với cờ success là false kèm thông báo lỗi chi tiết (ví dụ: "Thời gian làm việc bị trùng lặp với một ca khác").
  /// 4. Xử lý kết quả: 
  ///    - Nếu thành công (`response['success'] == true`), frontend sẽ truyền kết quả về UI để cập nhật lại danh sách công việc (thông qua việc gọi lại hàm load danh sách hoặc xóa phần tử khỏi mảng hiện tại).
  ///    - Nếu thất bại (bao gồm cả lỗi trùng lịch do backend trả về), UI sẽ hiển thị popup/snackbar dựa trên chuỗi `response['message']`.
  /// 5. Hoàn tất: Đặt lại `_isLoading = false` và `notifyListeners()` để ẩn loading, bất kể kết nối thành công hay có Exception (try-catch block).
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
