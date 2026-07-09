import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';

class BookingDetailViewModel extends ChangeNotifier {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId;

  BookingModel? get booking => _booking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentUserId => _currentUserId;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadBookingDetails(int maDatLich) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getBookingDetail(maDatLich);
      if (response['success'] == true) {
        _booking = BookingModel.fromJson(response['data']);
      } else {
        _errorMessage = response['message'] ?? 'Lỗi tải thông tin đơn hàng';
      }
    } catch (_) {
      _errorMessage = 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int maDatLich, {String? lyDoHuy}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.cancelBooking(maDatLich, lyDoHuy: lyDoHuy ?? '');
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createReview(int caLamId, int rating, String comment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.createReview(caLamId, rating, comment);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  Future<Map<String, dynamic>> createComplaint(int caLamId, String title, String content) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.createComplaint(caLamId, title, content);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
  /// Gửi yêu cầu đổi lịch làm việc cho một ca làm cụ thể.
  /// Trong đồ án, luồng đổi lịch được thiết kế để đảm bảo tính linh hoạt cho người dùng (khách hàng hoặc nhân viên)
  /// khi có sự cố phát sinh không thể thực hiện đúng lịch đã hẹn.
  /// Logic:
  /// 1. Nhận thông tin ca làm (caLamId), ngày giờ mới (ngayLamViec, gioBatDau), và lý do (lyDo).
  /// 2. Gửi request lên server (thông qua ApiService.rescheduleShift).
  /// 3. Server sẽ kiểm tra tính hợp lệ của thời gian mới (không nằm trong quá khứ, không trùng lịch, v.v.).
  /// 4. Nếu hợp lệ, hệ thống sẽ tạo một yêu cầu đổi lịch và gửi thông báo cho phía đối tác (nhân viên/khách hàng) để họ quyết định.
  /// 5. Cập nhật lại UI thông qua việc quản lý trạng thái (_isLoading) và trả về kết quả response từ API.
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
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  /// Phản hồi (Đồng ý hoặc Từ chối) yêu cầu đổi lịch từ phía đối tác (nhân viên).
  /// Giải thích chi tiết cho hội đồng bảo vệ đồ án:
  /// - Tính năng này giúp hoàn thiện quy trình thương lượng (negotiation) giữa khách hàng và nhân viên, giải quyết bài toán thực tế khi lịch trình có phát sinh.
  /// - Tham số `requestId`: Khóa chính của yêu cầu đổi lịch để xác định chính xác giao dịch.
  /// - Tham số `dongY` (boolean): true nếu người dùng chấp nhận thời gian mới, false nếu từ chối.
  /// - Luồng xử lý từ Client đến Server:
  ///   + Client gửi quyết định (dongY) lên hệ thống API.
  ///   + Server kiểm tra quyền truy cập. Nếu dongY = true, hệ thống tự động cập nhật thời gian ca làm và lưu lịch sử thay đổi.
  ///   + Nếu dongY = false, hệ thống hủy yêu cầu đổi lịch và ca làm giữ nguyên thời gian cũ (hoặc có thể hủy luôn ca làm tùy logic nghiệp vụ).
  /// - Hàm này áp dụng quản lý trạng thái loading để chặn các tương tác rác (spam clicks) trong lúc chờ phản hồi từ Server.
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
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  /// Đổi nhân viên (chỉ khi hệ thống tự gán)
  Future<Map<String, dynamic>> changeProvider(int caLamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.changeProvider(caLamId);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }
}
