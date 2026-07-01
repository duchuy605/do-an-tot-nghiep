import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/service_model.dart';

class BookingFormViewModel extends ChangeNotifier {
  int _bookingType = 1; // 1: Một lần, 2: Định kỳ
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  int _durationHours = 2;
  bool _isLoading = false;
  String? _errorMessage;

  // Dịch vụ bổ sung
  List<ServiceModel> _availableServices = [];
  final Map<int, int> _selectedAdditionalServices = {}; // MaDichVu -> SoGio (số giờ)

  // Chọn nhân viên yêu thích
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;

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

  // Getters
  int get bookingType => _bookingType;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  TimeOfDay get startTime => _startTime;
  int get durationHours => _durationHours;
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

  void setBookingType(int type) {
    _bookingType = type;
    updateEndDate();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    updateEndDate();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    notifyListeners();
  }

  void setDurationHours(int h) {
    _durationHours = h;
    notifyListeners();
  }

  void toggleWeekday(String day, bool value) {
    _weekdays[day] = value;
    updateEndDate();
    notifyListeners();
  }

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    filterPackages();
    notifyListeners();
  }

  void setSelectedPackage(Map<String, dynamic> pkg) {
    _selectedPackage = pkg;
    updateEndDate();
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
    notifyListeners();
  }

  void setAdditionalServiceQuantity(int serviceId, int quantity) {
    if (quantity <= 0) {
      _selectedAdditionalServices.remove(serviceId);
    } else {
      _selectedAdditionalServices[serviceId] = quantity;
    }
    notifyListeners();
  }

  void setSelectedProvider(Map<String, dynamic>? provider) {
    _selectedProvider = provider;
    notifyListeners();
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

  Future<void> loadPackages(int defaultDuration) async {
    _durationHours = defaultDuration;
    _isLoading = true;
    notifyListeners();

    // Lấy danh sách loại gói từ API (bảng LoaiGoi)
    try {
      final response = await ApiService.getCustomerPackages();
      if (response['success'] == true) {
        final List pkgs = response['data'] ?? [];
        _allPackages = pkgs;
        _availableMonths = pkgs.map<int>((p) => p['SoThang'] as int).toSet().toList()..sort();
        if (_availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
          filterPackages();
        }
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();

    // Load danh sách dịch vụ để hiển thị dịch vụ bổ sung
    try {
      final svcResponse = await ApiService.getServices();
      if (svcResponse['success'] == true) {
        final List svcList = svcResponse['data'] ?? [];
        _availableServices = svcList
            .map<ServiceModel>((s) => ServiceModel.fromJson(s))
            .where((s) => s.trangThai)
            .toList();
        notifyListeners();
      }
    } catch (_) {}

    // Load danh sách nhân viên
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

  void updateEndDate() {
    if (_bookingType == 1 || _selectedPackage == null) {
      _endDate = _startDate;
      return;
    }

    final int targetSessions = _selectedPackage!['SoBuoi'] ?? 1;
    final selectedDays = _weekdays.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedDays.isEmpty) {
      final int months = _selectedPackage!['SoThang'] ?? 1;
      final int totalDays = months * 30;
      final int interval = (totalDays / targetSessions).round().clamp(1, 30);
      _endDate = _startDate.add(Duration(days: (targetSessions - 1) * interval));
      return;
    }

    DateTime currentDate = _startDate;
    int sessionCount = 0;

    String getDayVN(int weekday) {
      if (weekday == 7) return 'CN';
      return (weekday + 1).toString();
    }

    while (sessionCount < targetSessions) {
      final dayVN = getDayVN(currentDate.weekday);
      if (selectedDays.contains(dayVN)) {
        sessionCount++;
        if (sessionCount == targetSessions) {
          break;
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    _endDate = currentDate;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _calculateEndTime(TimeOfDay start, int durationHours) {
    int endHour = start.hour + durationHours;
    int endMinute = start.minute;
    if (endHour >= 24) {
      endHour = endHour - 24;
    }
    final String hour = endHour.toString().padLeft(2, '0');
    final String minute = endMinute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// Build dữ liệu booking mà không gọi API.
  /// Dùng để truyền sang BookingCheckoutScreen.
  Map<String, dynamic> buildBookingData(String address, String desc, int serviceId) {
    final String startStr = _startDate.toIso8601String().split('T')[0];
    final String endStr = _bookingType == 1 ? startStr : _endDate.toIso8601String().split('T')[0];
    final String gioBatDauStr = _formatTimeOfDay(_startTime);
    final String gioKetThucStr = _calculateEndTime(_startTime, _durationHours);

    return {
      'LoaiDatLich': _bookingType,
      'NgayBatDau': startStr,
      'NgayKetThuc': endStr,
      'GioBatDau': gioBatDauStr,
      'GioKetThuc': gioKetThucStr,
      'DiaChiLamViec': address,
      'MoTaCongViec': desc,
      'DichVus': [
        {
          'MaDichVu': serviceId,
          'SoLuong': 1,
          'LaDichVuChinh': true,
        },
        ..._selectedAdditionalServices.entries.map((e) => {
          'MaDichVu': e.key,
          'SoLuong': e.value,
          'LaDichVuChinh': false,
        }),
      ],
      if (_bookingType == 2 && _selectedPackage != null)
        'MaLoaiGoi': _selectedPackage!['MaLoaiGoi'],
      if (_bookingType == 2)
        'ThuTrongTuan': _weekdays.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .join(','),
      if (_selectedProvider != null)
        'MaNhanVien': _selectedProvider!['MaNguoiDung'],
    };
  }

  Future<Map<String, dynamic>> submitBooking(String address, String desc, int serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bookingData = buildBookingData(address, desc, serviceId);

    try {
      final response = await ApiService.createBooking(bookingData);
      _isLoading = false;
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Tạo đơn đặt lịch thất bại.';
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối hoặc dữ liệu gửi đi không hợp lệ.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }
}

