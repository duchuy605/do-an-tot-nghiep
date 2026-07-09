import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/service_model.dart';

class BookingFormViewModel extends ChangeNotifier {
  int _bookingType = 1; // 1: Một lần, 2: Định kỳ
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  double _durationHours = 2.0;
  bool _isLoading = false;
  String? _errorMessage;

  // Dịch vụ bổ sung (Các dịch vụ được khách hàng chọn thêm ngoài dịch vụ chính)
  List<ServiceModel> _availableServices = [];
  final Map<int, int> _selectedAdditionalServices = {}; // MaDichVu -> SoGio (Lưu trữ danh sách mã dịch vụ và số lượng/số giờ tương ứng)

  // Chọn nhân viên yêu thích (Khách hàng có thể ưu tiên chọn một nhân viên cụ thể)
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider; // Lưu trữ thông tin nhân viên đang được chọn
  // Danh sách ca làm của nhân viên {date: YYYY-MM-DD, start: HH:mm, end: HH:mm}
  // Giúp giao diện hiển thị các khoảng thời gian nhân viên đã có lịch bận để khách hàng tránh chọn trùng
  List<Map<String, dynamic>> _providerBusyShifts = [];

  final Map<String, bool> _weekdays = {
    '2': false,
    '3': false,
    '4': false,
    '5': false,
    '6': false,
    '7': false,
    'CN': false,
  };



  List _allPackages = [];
  List<int> _availableMonths = [];
  List<Map<String, dynamic>> _filteredPackages = [];
  int? _selectedMonth;
  Map<String, dynamic>? _selectedPackage;
  
  int? _mainServiceId;
  double _temporaryTotalPrice = 0.0;
  bool _isCalculatingPrice = false;
  Timer? _debounceTimer;

  // Getters - Trả về các trạng thái hiện tại của form để View hiển thị
  int get bookingType => _bookingType;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  TimeOfDay get startTime => _startTime;
  double get durationHours => _durationHours;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get weekdays => _weekdays;
  List get allPackages => _allPackages;
  List<int> get availableMonths => _availableMonths;
  List<Map<String, dynamic>> get filteredPackages => _filteredPackages;
  int? get selectedMonth => _selectedMonth;
  Map<String, dynamic>? get selectedPackage => _selectedPackage;
  List<ServiceModel> get availableServices => _availableServices;
  Map<int, int> get selectedAdditionalServices => _selectedAdditionalServices;
  List<Map<String, dynamic>> get providers => _providers;
  Map<String, dynamic>? get selectedProvider => _selectedProvider;
  double get temporaryTotalPrice => _temporaryTotalPrice;
  bool get isCalculatingPrice => _isCalculatingPrice;
  List<Map<String, dynamic>> get providerBusyShifts => _providerBusyShifts;

  /// Thiết lập ID dịch vụ chính và tự động gọi API tính toán lại giá tiền tạm tính
  void setMainServiceId(int id) {
    _mainServiceId = id;
    _triggerPreviewPrice();
  }

  /// Kích hoạt việc gọi API để lấy báo giá tạm tính (Preview Price)
  /// Sử dụng kỹ thuật Debounce (chờ 500ms không có thay đổi mới gọi API)
  /// để tránh gọi API liên tục làm quá tải server khi người dùng thay đổi nhiều tuỳ chọn nhanh chóng
  void _triggerPreviewPrice() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel(); // Hủy timer hiện tại nếu có thay đổi mới
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_mainServiceId == null) return;
      _isCalculatingPrice = true;
      notifyListeners(); // Cập nhật UI hiển thị trạng thái đang tính toán
      
      // Tạo một payload giả (dummy data) cho địa chỉ và mô tả để gọi API tính giá
      final bookingData = buildBookingData("dummy", "dummy", _mainServiceId!);
      try {
        final response = await ApiService.previewBookingPrice(bookingData);
        if (response['success'] == true) {
          _temporaryTotalPrice = double.parse(response['data']['totalPrice'].toString()); // Cập nhật tổng tiền từ API
        } else {
          _temporaryTotalPrice = 0;
        }
      } catch (_) {
        _temporaryTotalPrice = 0;
      }
      
      _isCalculatingPrice = false;
      notifyListeners(); // Thông báo cho UI cập nhật giá tiền mới
    });
  }

  void setBookingType(int type) {
    _bookingType = type;
    updateEndDate();
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    updateEndDate();
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setDurationHours(double h) {
    _durationHours = h;
    _triggerPreviewPrice();
    notifyListeners();
  }

  void toggleWeekday(String day, bool value) {
    _weekdays[day] = value;
    updateEndDate();
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    filterPackages();
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setSelectedPackage(Map<String, dynamic> pkg) {
    _selectedPackage = pkg;
    updateEndDate();
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void toggleAdditionalService(int serviceId, bool selected) {
    if (selected) {
      _selectedAdditionalServices[serviceId] = 1;
    } else {
      _selectedAdditionalServices.remove(serviceId);
    }
    _triggerPreviewPrice();
    notifyListeners();
  }

  void setAdditionalServiceQuantity(int serviceId, int quantity) {
    if (quantity <= 0) {
      _selectedAdditionalServices.remove(serviceId);
    } else {
      _selectedAdditionalServices[serviceId] = quantity;
    }
    _triggerPreviewPrice();
    notifyListeners();
  }

  /// Xử lý việc chọn hoặc bỏ chọn một nhân viên cụ thể
  /// Khi chọn nhân viên, hệ thống sẽ tự động gọi API lấy lịch bận của nhân viên đó
  Future<void> setSelectedProvider(Map<String, dynamic>? provider) async {
    _selectedProvider = provider;
    _providerBusyShifts = []; // Xóa danh sách ca bận cũ
    _triggerPreviewPrice(); // Tính toán lại giá (có thể thay đổi nếu có phụ phí chọn nhân viên)
    notifyListeners();
    
    // Load lịch các ca làm việc mà nhân viên đã được phân công từ trước (ca bận)
    // Dữ liệu này giúp UI chặn khách hàng chọn vào những giờ nhân viên đã có khách
    if (provider != null) {
      final providerId = provider['MaNguoiDung'];
      if (providerId != null) {
        try {
          // Gọi API lấy lịch bận của nhân viên
          final response = await ApiService.getProviderBusyDates(providerId as int);
          if (response['success'] == true) {
            final List data = response['data'] ?? [];
            _providerBusyShifts = data.map<Map<String, dynamic>>((item) => {
              'date': item['date'].toString().substring(0, 10), // Trích xuất ngày YYYY-MM-DD
              'start': item['start'].toString().substring(0, 5), // Trích xuất giờ bắt đầu HH:mm
              'end': item['end'].toString().substring(0, 5),     // Trích xuất giờ kết thúc HH:mm
            }).toList();
          }
        } catch (_) {}
        notifyListeners(); // Cập nhật UI với danh sách ca bận mới
      }
    }
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<String> loadDefaultAddress() async {
    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        return response['data']['DiaChi'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Hàm nạp các dữ liệu cần thiết ban đầu cho form đặt lịch
  /// Bao gồm: Các gói định kỳ, danh sách dịch vụ bổ sung, và danh sách nhân viên
  Future<void> loadPackages(int defaultDuration) async {
    if (defaultDuration > 0) {
      _durationHours = defaultDuration.toDouble(); // Cài đặt thời gian làm việc mặc định theo dịch vụ
    }
    _isLoading = true;
    notifyListeners();

    // 1. Gọi API lấy danh sách các gói đặt lịch định kỳ (bảng LoaiGoi)
    // Các gói này định nghĩa số tháng và số buổi một tuần
    try {
      final response = await ApiService.getCustomerPackages();
      if (response['success'] == true) {
        final List pkgs = response['data'] ?? [];
        _allPackages = pkgs;
        // Trích xuất danh sách số tháng (ví dụ 1 tháng, 3 tháng) và lọc bỏ trùng lặp
        _availableMonths = pkgs.map<int>((p) => p['SoThang'] as int).toSet().toList()..sort();
        if (_availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.first; // Chọn mặc định tháng đầu tiên
          filterPackages(); // Lọc các gói tương ứng với số tháng đã chọn
        }
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();

    // 2. Gọi API lấy danh sách tất cả các dịch vụ đang hoạt động
    // Để hiển thị trong phần chọn Dịch vụ bổ sung (Additional Services)
    try {
      final svcResponse = await ApiService.getServices();
      if (svcResponse['success'] == true) {
        final List svcList = svcResponse['data'] ?? [];
        _availableServices = svcList
            .map<ServiceModel>((s) => ServiceModel.fromJson(s))
            .where((s) => s.trangThai) // Chỉ lấy các dịch vụ có trạng thái đang hoạt động
            .toList();
        notifyListeners();
      }
    } catch (_) {}

    // 3. Gọi API lấy danh sách toàn bộ nhân viên
    // Phục vụ cho tính năng "Chọn nhân viên ưu tiên" của khách hàng
    try {
      final provResponse = await ApiService.getProviders();
      if (provResponse['success'] == true) {
        final List provList = provResponse['data'] ?? [];
        _providers = provList.map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void filterPackages() {
    if (_selectedMonth == null) return;
    _filteredPackages = _allPackages
        .where((p) => p['SoThang'] == _selectedMonth)
        .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
        .toList()
      ..sort((a, b) => (a['SoBuoi'] as int).compareTo(b['SoBuoi'] as int));

    if (_filteredPackages.isNotEmpty) {
      _selectedPackage = _filteredPackages.first;
    } else {
      _selectedPackage = null;
    }
    updateEndDate();
  }

  /// Cập nhật ngày kết thúc dựa trên loại đặt lịch và gói đã chọn
  /// Nếu là đặt 1 lần, ngày kết thúc bằng ngày bắt đầu.
  /// Nếu là đặt định kỳ, tính toán ngày kết thúc bằng cách cộng thêm số tháng của gói.
  void updateEndDate() {
    if (_bookingType == 1 || (_selectedPackage == null && _selectedMonth == null)) {
      _endDate = _startDate; // Đặt lịch một lần thì kết thúc trong ngày
      return;
    }

    int months = 1;
    if (_selectedPackage != null) {
      months = _selectedPackage!['SoThang'] ?? 1; // Lấy số tháng từ gói được chọn
    } else if (_selectedMonth != null) {
      months = _selectedMonth!; // Hoặc từ số tháng đang chọn
    }
    
    // Tạo đối tượng DateTime mới bằng cách cộng số tháng vào tháng của ngày bắt đầu
    _endDate = DateTime(
      _startDate.year,
      _startDate.month + months,
      _startDate.day,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _calculateEndTime(TimeOfDay start, double durationHours) {
    int hoursToAdd = durationHours.floor();
    int minutesToAdd = ((durationHours - hoursToAdd) * 60).round();
    
    int endMinute = start.minute + minutesToAdd;
    int endHour = start.hour + hoursToAdd;
    
    if (endMinute >= 60) {
      endMinute -= 60;
      endHour += 1;
    }
    
    if (endHour >= 24) {
      endHour -= 24;
    }
    final String hour = endHour.toString().padLeft(2, '0');
    final String minute = endMinute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// Hàm tạo payload JSON chuẩn để gửi lên API tạo đơn đặt lịch
  /// Thu thập toàn bộ dữ liệu từ Form (Ngày, Giờ, Địa chỉ, Dịch vụ, Nhân viên, v.v...)
  /// Hàm này cũng được dùng để build dữ liệu ảo khi gọi API báo giá tạm tính
  Map<String, dynamic> buildBookingData(String address, String desc, int serviceId) {
    // Chuyển đổi Ngày bắt đầu và Ngày kết thúc sang chuẩn YYYY-MM-DD
    final String startStr = _startDate.toIso8601String().split('T')[0];
    final String endStr = _bookingType == 1 ? startStr : _endDate.toIso8601String().split('T')[0];
    
    // Định dạng giờ bắt đầu và tính toán giờ kết thúc thành chuỗi HH:mm:ss
    final String gioBatDauStr = _formatTimeOfDay(_startTime);
    final String gioKetThucStr = _calculateEndTime(_startTime, _durationHours);

    return {
      'LoaiDatLich': _bookingType, // 1: Một lần, 2: Định kỳ
      'NgayBatDau': startStr,
      'NgayKetThuc': endStr,
      'GioBatDau': gioBatDauStr,
      'GioKetThuc': gioKetThucStr,
      'DiaChiLamViec': address,
      'MoTaCongViec': desc,
      // Xây dựng danh sách các dịch vụ được chọn (Dịch vụ chính + Dịch vụ bổ sung)
      'DichVus': [
        {
          'MaDichVu': serviceId,
          'SoLuong': 1,
          'LaDichVuChinh': true, // Đánh dấu đây là dịch vụ chính
        },
        // Duyệt qua map các dịch vụ bổ sung và chuyển thành list các object JSON
        ..._selectedAdditionalServices.entries.map((e) => {
          'MaDichVu': e.key,
          'SoLuong': e.value,
          'LaDichVuChinh': false, // Đây là dịch vụ phụ thêm
        }),
      ],
      // Các trường dữ liệu dành riêng cho đặt lịch định kỳ
      if (_bookingType == 2 && _selectedPackage != null)
        'MaLoaiGoi': _selectedPackage!['MaLoaiGoi'],
      if (_bookingType == 2)
        'ThuTrongTuan': _weekdays.entries
            .where((e) => e.value) // Lọc các ngày thứ đã được tick chọn (true)
            .map((e) => e.key)
            .join(','), // Ghép thành chuỗi (vd: '2,4,6')
            
      // Truyền ID nhân viên nếu khách hàng có chọn nhân viên yêu thích
      if (_selectedProvider != null)
        'MaNhanVien': _selectedProvider!['MaNguoiDung'],
    };
  }

  /// Thực hiện quá trình Submit form tạo đơn đặt lịch thực sự lên server API
  /// Trả về một Map chứa success (true/false) và message phản hồi từ server
  Future<Map<String, dynamic>> submitBooking(String address, String desc, int serviceId) async {
    _isLoading = true; // Bật cờ loading để khóa form
    _errorMessage = null;
    notifyListeners();

    // 1. Sinh dữ liệu chuẩn từ Form
    final bookingData = buildBookingData(address, desc, serviceId);

    try {
      // 2. Gửi request POST tạo đơn lịch mới tới API backend
      final response = await ApiService.createBooking(bookingData);
      _isLoading = false;
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Tạo đơn đặt lịch thất bại.'; // Bắt lỗi nghiệp vụ từ server
      }
      notifyListeners();
      return response; // Trả kết quả về cho Controller/UI xử lý tiếp (ví dụ: chuyển trang)
    } catch (e) {
      // Bắt các lỗi về Network hoặc Exception
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối hoặc dữ liệu gửi đi không hợp lệ.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }
}

