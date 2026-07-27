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

  // Dịch vụ bổ sung
  List<ServiceModel> _availableServices = [];
  final Map<int, int> _selectedAdditionalServices = {}; // MaDichVu -> SoGio (số giờ)

  // Chọn nhân viên yêu thích
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  // Danh sách ca làm của nhân viên {date: YYYY-MM-DD, start: HH:mm, end: HH:mm}
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

  // Getters
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

  void setMainServiceId(int id) {
    _mainServiceId = id;
    _triggerPreviewPrice();
  }

  void _triggerPreviewPrice() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_mainServiceId == null) return;
      _isCalculatingPrice = true;
      notifyListeners();
      
      final bookingData = buildBookingData("dummy", "dummy", _mainServiceId!);
      try {
        final response = await ApiService.previewBookingPrice(bookingData);
        if (response['success'] == true) {
          _temporaryTotalPrice = double.parse(response['data']['totalPrice'].toString());
        } else {
          _temporaryTotalPrice = 0;
        }
      } catch (_) {
        _temporaryTotalPrice = 0;
      }
      
      _isCalculatingPrice = false;
      notifyListeners();
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

  Future<void> setSelectedProvider(Map<String, dynamic>? provider) async {
    _selectedProvider = provider;
    _providerBusyShifts = [];
    _triggerPreviewPrice();
    notifyListeners();
    
    // Load ca làm của nhân viên được chọn
    if (provider != null) {
      final providerId = provider['MaNguoiDung'];
      if (providerId != null) {
        try {
          final response = await ApiService.getProviderBusyDates(providerId as int);
          if (response['success'] == true) {
            final List data = response['data'] ?? [];
            _providerBusyShifts = data.map<Map<String, dynamic>>((item) => {
              'date': item['date'].toString().substring(0, 10),
              'start': item['start'].toString().substring(0, 5), // HH:mm
              'end': item['end'].toString().substring(0, 5),     // HH:mm
            }).toList();
          }
        } catch (_) {}
        notifyListeners();
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

  Future<void> loadPackages(int defaultDuration) async {
    if (defaultDuration > 0) {
      _durationHours = defaultDuration.toDouble();
    }
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
    if (_bookingType == 1 || (_selectedPackage == null && _selectedMonth == null)) {
      _endDate = _startDate;
      return;
    }

    int months = 1;
    if (_selectedPackage != null) {
      months = _selectedPackage!['SoThang'] ?? 1;
    } else if (_selectedMonth != null) {
      months = _selectedMonth!;
    }
    
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

