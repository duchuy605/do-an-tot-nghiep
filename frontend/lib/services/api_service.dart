import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';

/// Lớp ApiService chứa tất cả các hàm gọi API đến backend.
/// Sử dụng thư viện http để gửi request và shared_preferences để lưu token.
class ApiService {
  // Cấu hình URL cơ sở của backend.
  // Khi chạy trên thiết bị Android Emulator: dùng 'http://10.0.2.2:3000/api'
  // Khi chạy trên Windows/Web/iOS Emulator: dùng 'http://localhost:3000/api'
  static String baseUrl = 'http://localhost:3000/api';

  /// Lấy token JWT đã lưu trong bộ nhớ cục bộ
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Lưu token JWT vào bộ nhớ cục bộ sau khi đăng nhập thành công
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Lưu vai trò người dùng (1: Khách hàng, 2: Nhân viên, 3: Admin)
  static Future<void> saveUserRole(int role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_role', role);
  }

  /// Lấy vai trò người dùng đã lưu
  static Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_role');
  }

  //Lưu email người dùng vào bộ nhớ cục bộ
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// Lấy email người dùng đã lưu
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// Lưu userId vào bộ nhớ cục bộ
  static Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }

  /// Lấy userId đã lưu
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Xóa toàn bộ thông tin xác thực khi đăng xuất
  /// (token, vai trò, email)
  static Future<void> clearAuth() async {
    try {
      SocketService().disconnect();
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
  }

  /// Tạo header chung cho mọi request cần xác thực
  /// Tự động gắn token JWT vào header Authorization
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // CÁC API XÁC THỰC (AUTH) - Bảng: NguoiDung

  /// Đăng nhập tài khoản
  /// POST /api/auth/login
  /// Tham số: Email, MatKhau
  /// Trả về: token JWT + thông tin người dùng
  /// Tự động lưu token, vai trò, email vào SharedPreferences
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'MatKhau': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['token'];
      final user = data['data']['user'];
      await saveToken(token);
      await saveUserRole(user['VaiTro']);
      await saveUserEmail(user['Email']);
      await saveUserId(user['MaNguoiDung']);
    }
    return data;
  }

  /// Đăng ký tài khoản mới
  /// POST /api/auth/register
  /// Tham số: HoTenNguoiDung, Email, MatKhau, SoDienThoai, DiaChi, VaiTro, CCCD (nếu nhân viên)
  /// Trả về: thông tin tài khoản vừa tạo
  static Future<Map<String, dynamic>> register(Map<String, dynamic> regData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(regData),
    );
    return jsonDecode(response.body);
  }

  /// Lấy thông tin hồ sơ cá nhân của người dùng đang đăng nhập
  /// GET /api/auth/profile
  /// Yêu cầu: Token JWT
  /// Trả về: thông tin NguoiDung (trừ mật khẩu)
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật thông tin hồ sơ cá nhân
  /// PUT /api/auth/profile
  /// Tham số: HoTenNguoiDung, SoDienThoai, DiaChi, GioiTinh, ...
  /// Yêu cầu: Token JWT
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _headers(),
      body: jsonEncode(profileData),
    );
    return jsonDecode(response.body);
  }

  /// Đổi mật khẩu
  /// PUT /api/auth/change-password
  /// Tham số: MatKhauCu (mật khẩu hiện tại), MatKhauMoi (mật khẩu mới)
  /// Yêu cầu: Token JWT
  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _headers(),
      body: jsonEncode({'MatKhauCu': currentPassword, 'MatKhauMoi': newPassword}),
    );
    return jsonDecode(response.body);
  }

  /// Quên mật khẩu - Gửi mã OTP về email
  /// POST /api/auth/forgot-password
  /// Tham số: Email
  /// Trả về: thông báo đã gửi mã OTP
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email}),
    );
    return jsonDecode(response.body);
  }

  /// Đặt lại mật khẩu bằng mã OTP
  /// POST /api/auth/reset-password
  /// Tham số: Email, Code (mã OTP), MatKhauMoi
  static Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Email': email,
        'Code': code,
        'MatKhauMoi': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  // ============================================================
  // CÁC API DÀNH CHO KHÁCH HÀNG (CUSTOMER) - VaiTro = 1
  // ============================================================

  /// Lấy danh sách tất cả dịch vụ
  /// GET /api/services
  /// Bảng: DichVu
  /// Trả về: danh sách dịch vụ (MaDichVu, TenDichVu, DonGia, MoTa, ...)
  static Future<Map<String, dynamic>> getServices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/services'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy chi tiết một dịch vụ theo mã
  /// GET /api/services/:id
  /// Bảng: DichVu
  /// Tham số: id (MaDichVu)
  static Future<Map<String, dynamic>> getServiceDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách nhân viên đang hoạt động để chọn khi đặt lịch
  /// GET /api/providers
  /// Bảng: NguoiDung + HoSoNhanVien (VaiTro = 2, TrangThaiHoatDong = true)
  /// Trả về: danh sách nhân viên (tên, SĐT, đánh giá, giờ làm việc, ...)
  static Future<Map<String, dynamic>> getProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/providers'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách ngày bận của nhân viên (đã có lịch)
  /// GET /api/providers/:id/busy-dates
  static Future<Map<String, dynamic>> getProviderBusyDates(int providerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/providers/$providerId/busy-dates'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tạo đơn đặt lịch mới
  /// POST /api/bookings
  /// Bảng: DonDatLich, CaLamViec, DatDichVu
  /// Tham số: NgayBatDau, NgayKetThuc, GioBatDau, GioKetThuc,
  ///          DiaChiLamViec, LoaiDatLich, DichVus, MaNhanVien (tùy chọn), ...
  /// Trả về: thông tin đơn đặt lịch + danh sách ca làm việc
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _headers(),
      body: jsonEncode(bookingData),
    );
    return jsonDecode(response.body);
  }

  /// Xem trước giá đơn đặt lịch (không tạo đơn)
  /// POST /api/bookings/preview
  /// Dùng cùng logic tính giá như createBooking nhưng chỉ trả về kết quả
  /// Trả về: tổng tiền, chi tiết từng ca, hệ số giá, ...
  static Future<Map<String, dynamic>> previewBookingPrice(Map<String, dynamic> bookingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/preview'),
      headers: await _headers(),
      body: jsonEncode(bookingData),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách tất cả đơn đặt lịch của khách hàng đang đăng nhập
  /// GET /api/bookings
  /// Bảng: DonDatLich + CaLamViec + DatDichVu
  /// Trả về: danh sách đơn kèm ca làm việc, dịch vụ, trạng thái
  static Future<Map<String, dynamic>> getBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy chi tiết một đơn đặt lịch theo mã
  /// GET /api/bookings/:id
  /// Bảng: DonDatLich + CaLamViec (kèm NhanVien) + DatDichVu + DichVu
  /// Tham số: id (MaDatLich)
  /// Trả về: toàn bộ thông tin đơn, ca làm việc, nhân viên, dịch vụ
  static Future<Map<String, dynamic>> getBookingDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Đổi ngày/giờ của một ca làm việc
  /// PATCH /api/bookings/shifts/:id/reschedule
  /// Dùng cho khách hàng sở hữu ca hoặc nhân viên đã nhận ca.
  static Future<Map<String, dynamic>> rescheduleShift(
    int caLamId, {
    required String ngayLamViec,
    required String gioBatDau,
    String lyDo = '',
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/shifts/$caLamId/reschedule'),
      headers: await _headers(),
      body: jsonEncode({
        'NgayLamViec': ngayLamViec,
        'GioBatDau': gioBatDau,
        'LyDo': lyDo,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Đồng ý hoặc từ chối yêu cầu đổi lịch
  /// PATCH /api/bookings/reschedule-requests/:id/respond
  static Future<Map<String, dynamic>> respondRescheduleRequest(int requestId, bool dongY) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/reschedule-requests/$requestId/respond'),
      headers: await _headers(),
      body: jsonEncode({'DongY': dongY}),
    );
    return jsonDecode(response.body);
  }

  /// Đổi nhân viên (chỉ khi hệ thống tự gán)
  /// PATCH /api/bookings/shifts/:id/change-provider
  static Future<Map<String, dynamic>> changeProvider(int caLamId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/shifts/$caLamId/change-provider'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    return jsonDecode(response.body);
  }

  /// Hủy đơn đặt lịch kèm lý do
  /// DELETE /api/bookings/:id
  /// Bảng: DonDatLich, ViTien, LichSuViTien
  /// Tham số: id (MaDatLich), LyDoHuy (lý do hủy đơn)
  /// Nếu đã thanh toán → hoàn tiền vào ví khách hàng
  static Future<Map<String, dynamic>> cancelBooking(int id, {String lyDoHuy = ''}) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/bookings/$id'));
    final headers = await _headers();
    request.headers.addAll(headers);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'LyDoHuy': lyDoHuy});
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  /// Thanh toán đơn đặt lịch bằng ví bPay
  /// POST /api/payments
  /// Bảng: DonDatLich, ViTien, LichSuViTien
  /// Tham số: MaDatLich
  /// Trừ tiền ví khách hàng → chuyển vào ví hệ thống (Escrow)
  static Future<Map<String, dynamic>> payBooking(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _headers(),
      body: jsonEncode({'MaDatLich': id}),
    );
    return jsonDecode(response.body);
  }

  /// Nạp tiền vào ví bPay
  /// POST /api/wallet/topup
  /// Bảng: ViTien, LichSuViTien
  /// Tham số: SoTien (số tiền muốn nạp)
  static Future<Map<String, dynamic>> topupWallet(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: await _headers(),
      body: jsonEncode({'SoTien': amount}),
    );
    return jsonDecode(response.body);
  }

  /// Lấy thông tin ví bPay (số dư hiện tại)
  /// GET /api/wallet
  /// Bảng: ViTien
  /// Trả về: SoDu, LoaiVi, ...
  static Future<Map<String, dynamic>> getWallet() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy lịch sử giao dịch ví bPay
  /// GET /api/wallet/history
  /// Bảng: LichSuViTien
  /// Trả về: danh sách giao dịch (nạp, thanh toán, hoàn tiền, rút tiền, ...)
  static Future<Map<String, dynamic>> getWalletHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/history'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Rút tiền từ ví nhân viên
  /// POST /api/provider/wallet/withdraw
  /// Bảng: ViTien, LichSuViTien
  /// Tham số: SoTien (số tiền muốn rút)
  static Future<Map<String, dynamic>> withdrawWallet(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/wallet/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'SoTien': amount}),
    );
    return jsonDecode(response.body);
  }

  /// Gửi đánh giá cho ca làm việc đã hoàn thành
  /// POST /api/reviews
  /// Bảng: DanhGia
  /// Tham số: MaCaLam, SoSao (1-5), NoiDungDanhGia
  static Future<Map<String, dynamic>> createReview(int caLamId, int rating, String comment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: await _headers(),
      body: jsonEncode({
        'MaCaLam': caLamId,
        'SoSao': rating,
        'NoiDungDanhGia': comment,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Gửi khiếu nại cho ca làm việc
  /// POST /api/complaints
  /// Bảng: KhieuNai
  /// Tham số: MaCaLam, TieuDe, NoiDung
  static Future<Map<String, dynamic>> createComplaint(int caLamId, String title, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: await _headers(),
      body: jsonEncode({
        'MaCaLam': caLamId,
        'TieuDe': title,
        'NoiDung': content,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Upload ảnh đại diện người dùng
  /// PUT /api/auth/profile (MultipartRequest)
  /// Tham số: bytes (dữ liệu ảnh), fileName (tên file)
  /// Gửi dạng multipart/form-data thay vì JSON
  static Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String fileName) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/auth/profile');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'AnhDaiDien',
        bytes,
        filename: fileName,
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tải ảnh đại diện'};
    }
  }

  // ============================================================
  // CÁC API DÀNH CHO NHÂN VIÊN (PROVIDER) - VaiTro = 2
  // ============================================================

  /// Lấy hồ sơ nhân viên (bao gồm thông tin HoSoNhanVien)
  /// GET /api/provider/profile
  /// Bảng: NguoiDung + HoSoNhanVien
  /// Trả về: thông tin cá nhân + hồ sơ (số sao, giờ làm, trạng thái duyệt, ...)
  static Future<Map<String, dynamic>> getProviderProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/profile'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật hồ sơ nhân viên
  /// PUT /api/provider/profile
  /// Bảng: NguoiDung, HoSoNhanVien
  /// Tham số: TrangThaiHoatDong, thông tin cá nhân, ...
  static Future<Map<String, dynamic>> updateProviderProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/provider/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách ca làm việc (bao gồm việc chờ nhận + việc đã nhận)
  /// GET /api/provider/jobs
  /// Bảng: CaLamViec + NguoiDung (KhachHang) + DonDatLich
  /// Trả về: danh sách ca (ngày, giờ, dịch vụ, khách hàng, trạng thái, loại đặt lịch)
  static Future<Map<String, dynamic>> getJobs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/jobs'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy chi tiết một ca làm việc
  /// GET /api/provider/jobs/:id
  /// Bảng: CaLamViec
  /// Tham số: id (MaCaLam)
  static Future<Map<String, dynamic>> getJobDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/provider/jobs/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Nhận ca làm việc
  /// POST /api/provider/jobs/:id/accept
  /// Bảng: CaLamViec
  /// Tham số: id (MaCaLam)
  /// Cập nhật MaNhanVien = ID nhân viên, gửi thông báo cho khách hàng
  static Future<Map<String, dynamic>> acceptJob(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/jobs/$id/accept'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Từ chối ca làm việc đã nhận kèm lý do
  /// POST /api/provider/jobs/:id/reject
  /// Bảng: CaLamViec
  /// Tham số: id (MaCaLam), LyDoHuy (lý do từ chối)
  /// Đưa ca về trạng thái chờ nhận (MaNhanVien = null)
  static Future<Map<String, dynamic>> rejectJob(int id, {String lyDoHuy = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/jobs/$id/reject'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'LyDoHuy': lyDoHuy}),
    );
    return jsonDecode(response.body);
  }

  /// Bắt đầu ca làm việc
  /// POST /api/provider/jobs/:id/start
  static Future<Map<String, dynamic>> startJob(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/jobs/$id/start'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Hoàn thành ca làm việc
  /// POST /api/provider/jobs/:id/complete
  /// Bảng: CaLamViec, ViTien, LichSuViTien
  /// Tham số: id (MaCaLam)
  /// Chia tiền: 80% cho nhân viên, 20% cho hệ thống
  /// Gửi thông báo cho khách hàng đánh giá
  static Future<Map<String, dynamic>> completeJob(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/provider/jobs/$id/complete'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ============================================================
  // CÁC API DÀNH CHO ADMIN (QUẢN TRỊ VIÊN) - VaiTro = 3
  // ============================================================

  /// Lấy dữ liệu tổng quan dashboard
  /// GET /api/admin/dashboard
  /// Trả về: tổng doanh thu, số đơn, số người dùng, thống kê, ...
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy lịch sử hoa hồng hệ thống
  /// GET /api/admin/system-earnings
  static Future<Map<String, dynamic>> getSystemEarningsHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/system-earnings'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy lịch sử doanh thu gộp (Gross Revenue)
  /// GET /api/admin/gross-revenue
  static Future<Map<String, dynamic>> getGrossRevenueHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/gross-revenue'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách tất cả người dùng
  /// GET /api/admin/users
  /// Bảng: NguoiDung
  /// Trả về: danh sách người dùng (khách hàng + nhân viên + admin)
  static Future<Map<String, dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUserStats(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$id/stats'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Khóa tài khoản người dùng
  /// PUT /api/admin/users/:id/lock
  /// Bảng: NguoiDung
  /// Tham số: id (MaNguoiDung)
  static Future<Map<String, dynamic>> lockUser(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$id/lock'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Mở khóa tài khoản người dùng
  /// PUT /api/admin/users/:id/unlock
  /// Bảng: NguoiDung
  /// Tham số: id (MaNguoiDung)
  static Future<Map<String, dynamic>> unlockUser(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$id/unlock'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách nhân viên (kèm hồ sơ để duyệt)
  /// GET /api/admin/providers
  /// Bảng: NguoiDung + HoSoNhanVien (VaiTro = 2)
  /// Trả về: danh sách nhân viên kèm trạng thái duyệt hồ sơ
  static Future<Map<String, dynamic>> getAdminProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/providers'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Duyệt hồ sơ nhân viên
  /// PUT /api/admin/providers/:id/approve
  /// Bảng: HoSoNhanVien
  /// Tham số: id (MaNguoiDung)
  /// Cập nhật TrangThaiDuyet = true
  static Future<Map<String, dynamic>> approveProvider(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/providers/$id/approve'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Từ chối hồ sơ nhân viên
  /// PUT /api/admin/providers/:id/reject
  /// Bảng: HoSoNhanVien
  /// Tham số: id (MaNguoiDung)
  static Future<Map<String, dynamic>> rejectProvider(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/providers/$id/reject'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tạo dịch vụ mới
  /// POST /api/admin/services
  /// Bảng: DichVu
  /// Tham số: TenDichVu, DonGia, MoTa, ...
  static Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/services'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật thông tin dịch vụ
  /// PUT /api/admin/services/:id
  /// Bảng: DichVu
  /// Tham số: id (MaDichVu), TenDichVu, DonGia, MoTa, ...
  static Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/services/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Xóa dịch vụ
  /// DELETE /api/admin/services/:id
  /// Bảng: DichVu
  /// Tham số: id (MaDichVu)
  static Future<Map<String, dynamic>> deleteService(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/services/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách tất cả đơn đặt lịch (Admin xem tất cả)
  /// GET /api/admin/bookings
  /// Bảng: DonDatLich + NguoiDung + CaLamViec
  /// Trả về: danh sách đơn kèm thông tin khách hàng, nhân viên
  static Future<Map<String, dynamic>> getAdminBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/bookings'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật trạng thái đơn đặt lịch
  /// PUT /api/admin/bookings/:id/status
  /// Bảng: DonDatLich
  /// Tham số: id (MaDatLich), TrangThai (1-4)
  static Future<Map<String, dynamic>> updateBookingStatus(int id, int status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/bookings/$id/status'),
      headers: await _headers(),
      body: jsonEncode({'TrangThai': status}),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách ngày đặc biệt (lễ, tết, ...)
  /// GET /api/admin/special-days
  /// Bảng: NgayDacBiet
  /// Trả về: danh sách ngày kèm hệ số giá
  static Future<Map<String, dynamic>> getSpecialDays() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/special-days'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tạo ngày đặc biệt mới
  /// POST /api/admin/special-days
  /// Bảng: NgayDacBiet
  /// Tham số: Ngay (yyyy-MM-dd), TenNgay, HeSoGia (ví dụ: 1.5 = tăng 50%)
  static Future<Map<String, dynamic>> createSpecialDay(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/special-days'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Xóa ngày đặc biệt
  /// DELETE /api/admin/special-days/:id
  /// Bảng: NgayDacBiet
  /// Tham số: id (MaNgayDacBiet)
  static Future<Map<String, dynamic>> deleteSpecialDay(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/special-days/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật ngày đặc biệt
  /// PUT /api/admin/special-days/:id
  /// Bảng: NgayDacBiet
  /// Tham số: id (MaNgayDacBiet), Ngay, TenNgay, HeSoGia
  static Future<Map<String, dynamic>> updateSpecialDay(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/special-days/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách khung giờ kèm hệ số giá
  /// GET /api/admin/time-slots
  /// Bảng: KhungGio
  /// Trả về: danh sách khung giờ (GioBatDau, GioKetThuc, HeSoGia, ...)
  static Future<Map<String, dynamic>> getTimeSlots() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/time-slots'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tạo khung giờ mới
  /// POST /api/admin/time-slots
  /// Bảng: KhungGio
  /// Tham số: GioBatDau, GioKetThuc, HeSoGia, MoTa
  static Future<Map<String, dynamic>> createTimeSlot(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/time-slots'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Xóa khung giờ
  /// DELETE /api/admin/time-slots/:id
  /// Bảng: KhungGio
  /// Tham số: id (MaKhungGio)
  static Future<Map<String, dynamic>> deleteTimeSlot(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/time-slots/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật khung giờ
  /// PUT /api/admin/time-slots/:id
  /// Bảng: KhungGio
  /// Tham số: id (MaKhungGio), GioBatDau, GioKetThuc, HeSoGia
  static Future<Map<String, dynamic>> updateTimeSlot(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/time-slots/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách loại gói dịch vụ (Admin quản lý)
  /// GET /api/admin/packages
  /// Bảng: LoaiGoi
  /// Trả về: danh sách gói (SoThang, SoBuoi, PhanTramGiamGia, ...)
  static Future<Map<String, dynamic>> getPackages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/packages'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách loại gói dịch vụ (Khách hàng xem khi đặt lịch định kỳ)
  /// GET /api/packages
  /// Bảng: LoaiGoi (TrangThai = 1: đang hoạt động)
  /// Trả về: danh sách gói khả dụng cho khách hàng chọn
  static Future<Map<String, dynamic>> getCustomerPackages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tạo loại gói dịch vụ mới
  /// POST /api/admin/packages
  /// Bảng: LoaiGoi
  /// Tham số: SoThang, SoBuoi, PhanTramGiamGia, TrangThai
  static Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/packages'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Xóa loại gói dịch vụ
  /// DELETE /api/admin/packages/:id
  /// Bảng: LoaiGoi
  /// Tham số: id (MaLoaiGoi)
  static Future<Map<String, dynamic>> deletePackage(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/packages/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Cập nhật loại gói dịch vụ
  /// PUT /api/admin/packages/:id
  /// Bảng: LoaiGoi
  /// Tham số: id (MaLoaiGoi), SoThang, SoBuoi, PhanTramGiamGia
  static Future<Map<String, dynamic>> updatePackage(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/packages/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách khiếu nại từ khách hàng
  /// GET /api/admin/complaints
  /// Bảng: KhieuNai + CaLamViec + NguoiDung
  /// Trả về: danh sách khiếu nại kèm thông tin ca làm, khách hàng
  static Future<Map<String, dynamic>> getComplaints() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/complaints'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Tiếp nhận xử lý khiếu nại (chuyển sang trạng thái đang xử lý)
  /// PUT /api/admin/complaints/:id/process
  /// Bảng: KhieuNai
  /// Tham số: id (MaKhieuNai)
  static Future<Map<String, dynamic>> processComplaint(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/complaints/$id/process'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Giải quyết khiếu nại (chọn hình thức xử lý)
  /// PUT /api/admin/complaints/:id/resolve
  /// Bảng: KhieuNai, ViTien, LichSuViTien
  /// Tham số: id (MaKhieuNai), MaHinhThucXuLy, SoTienDenBu (nếu hoàn tiền)
  static Future<Map<String, dynamic>> resolveComplaint(int id, int hinhThucXuLyId, double? refundAmount) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/complaints/$id/resolve'),
      headers: await _headers(),
      body: jsonEncode({
        'MaHinhThucXuLy': hinhThucXuLyId,
        if (refundAmount != null) 'SoTienDenBu': refundAmount,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Lấy danh sách hình thức xử lý khiếu nại
  /// GET /api/admin/resolution-types
  /// Bảng: HinhThucXuLy
  /// Trả về: danh sách hình thức (cảnh cáo, hoàn tiền, khóa tài khoản, ...)
  static Future<Map<String, dynamic>> getResolutionTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/resolution-types'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ============================================================
  // CÁC API THÔNG BÁO (DÙNG CHUNG) - Bảng: ThongBao
  // ============================================================

  /// Lấy danh sách thông báo của người dùng đang đăng nhập
  /// GET /api/notifications
  /// Bảng: ThongBao
  /// Trả về: danh sách thông báo (tiêu đề, nội dung, ngày tạo, trạng thái đọc)
  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  /// Đánh dấu thông báo đã đọc
  /// PUT /api/notifications/:id/read
  /// Bảng: ThongBao
  /// Tham số: id (MaThongBao)
  /// Cập nhật TrangThaiThongBao = true
  static Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }
}
