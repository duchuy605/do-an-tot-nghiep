import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/customer/booking_form_viewmodel.dart';
import '../../models/service_model.dart';
import '../../widgets/provider_calendar_dialog.dart';
import '../../widgets/top_banner_notification.dart';
import '../../widgets/custom_time_picker.dart';

class BookingFormScreen extends StatefulWidget {
  final ServiceModel service;

  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final BookingFormViewModel _viewModel = BookingFormViewModel();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _viewModel.setMainServiceId(widget.service.maDichVu);
    final addr = await _viewModel.loadDefaultAddress();
    setState(() {
      _addressController.text = addr;
    });
    _viewModel.loadPackages(widget.service.soGioQuyDinh);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => ProviderCalendarDialog(
        initialDate: isStart ? _viewModel.startDate : _viewModel.endDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        // Truyền danh sách ca làm đầy đủ {date, start, end}
        providerShifts: _viewModel.providerBusyShifts,
        // Giờ bắt đầu và số giờ dự kiến đặt của khách
        plannedStartTime: _viewModel.startTime,
        plannedDurationHours: _viewModel.durationHours,
      ),
    );
    if (picked != null) {
      if (isStart) {
        _viewModel.setStartDate(picked);
      } else {
        _viewModel.setEndDate(picked);
      }
    }
  }

Future<void> _selectTime(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CustomTimePicker(
          initialTime: _viewModel.startTime,
          onTimeSelected: (TimeOfDay picked) {
            if (picked.hour < 6 || picked.hour > 22 || (picked.hour == 22 && picked.minute > 0)) {
              showTopBanner(context, 'Lỗi', 'Thời gian hoạt động từ 06:00 đến 22:00. Vui lòng chọn giờ khác.');
              return;
            }

            final now = DateTime.now();
            final selectedDateTime = DateTime(
              _viewModel.startDate.year,
              _viewModel.startDate.month,
              _viewModel.startDate.day,
              picked.hour,
              picked.minute,
            );
            final minDateTime = now.add(const Duration(minutes: 30));
            final isToday =
                _viewModel.startDate.year == now.year &&
                _viewModel.startDate.month == now.month &&
                _viewModel.startDate.day == now.day;

            if (isToday && selectedDateTime.isBefore(minDateTime)) {
              showTopBanner(context, 'Lỗi', 'Vui lòng chọn giờ bắt đầu sau ít nhất 30 phút so với hiện tại.');
              return;
            }

            _viewModel.setStartTime(picked);
          },
        );
      },
    );
  }
 Future<void> _submitBooking() async {
  if (!_formKey.currentState!.validate()) return;

  // Kiểm tra thời gian đặt phải sau hiện tại ít nhất 30 phút
  final now = DateTime.now();

  final bookingDateTime = DateTime(
    _viewModel.startDate.year,
    _viewModel.startDate.month,
    _viewModel.startDate.day,
    _viewModel.startTime.hour,
    _viewModel.startTime.minute,
  );

  if (bookingDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thời gian bắt đầu phải sau thời điểm hiện tại ít nhất 30 phút.',
        ),
      ),
    );
    return;
  }

  if (_viewModel.bookingType == 2) {
    final selectedDays = _viewModel.weekdays.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(',');

    if (selectedDays.isEmpty) {
      _viewModel.setErrorMessage(
        'Vui lòng chọn ít nhất một thứ trong tuần để đặt lịch định kỳ',
      );
      return;
    }

    if (_viewModel.selectedPackage == null) {
      _viewModel.setErrorMessage(
        'Vui lòng chọn một gói định kỳ để tiếp tục',
      );
      return;
    }
  }

  // Build booking data
  final bookingData = _viewModel.buildBookingData(
    _addressController.text.trim(),
    _descController.text.trim(),
    widget.service.maDichVu,
  );

  // Không còn dùng màn hình checkout/payment riêng; đơn sẽ được tạo trực tiếp từ form.
  if (!mounted) return;
  Navigator.pop(context, true);
}
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDuration(double hours) {
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    if (h == 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '$h giờ $m phút';
  }

  // Hiển thị bottom sheet chi tiết nhân viên
  void _showProviderDetail(BuildContext context, String name, String phone, dynamic rating, dynamic soGio, String gioiTinh) {
    const orangeColor = Color(0xFFFF8225);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: orangeColor.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: orangeColor, fontSize: 24),
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Thông tin chi tiết
              _buildProviderInfoRow(Icons.phone_outlined, 'Số điện thoại', phone),
              _buildProviderInfoRow(Icons.star_rounded, 'Đánh giá trung bình', '$rating ★'),
              _buildProviderInfoRow(Icons.access_time, 'Số giờ làm việc', '$soGio giờ'),
              _buildProviderInfoRow(Icons.person_outline, 'Giới tính', gioiTinh),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Dòng thông tin nhân viên trong bottom sheet
  Widget _buildProviderInfoRow(IconData icon, String label, String value) {
    const orangeColor = Color(0xFFFF8225);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: orangeColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Đặt ${widget.service.tenDichVu}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.isLoading && _viewModel.allPackages.isEmpty
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Booking Type Toggle
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Làm Một Lần')),
                                  selected: _viewModel.bookingType == 1,
                                  selectedColor: orangeColor.withOpacity(0.15),
                                  checkmarkColor: orangeColor,
                                  backgroundColor: bgColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  labelStyle: TextStyle(
                                    color: _viewModel.bookingType == 1 ? orangeColor : darkColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) _viewModel.setBookingType(1);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Làm Định Kỳ')),
                                  selected: _viewModel.bookingType == 2,
                                  selectedColor: orangeColor.withOpacity(0.15),
                                  checkmarkColor: orangeColor,
                                  backgroundColor: bgColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  labelStyle: TextStyle(
                                    color: _viewModel.bookingType == 2 ? orangeColor : darkColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) _viewModel.setBookingType(2);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (_viewModel.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Working address
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Địa chỉ làm việc',
                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: orangeColor),
                              filled: true,
                              fillColor: bgColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Vui lòng nhập địa chỉ làm việc';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Start Time select
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Giờ bắt đầu', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                            subtitle: Text(
                              '${_viewModel.startTime.hour.toString().padLeft(2, '0')}:${_viewModel.startTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16, color: orangeColor, fontWeight: FontWeight.bold),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: orangeColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.schedule_rounded, color: orangeColor),
                            ),
                            onTap: () => _selectTime(context),
                          ),
                          const Divider(),

                          // Duration select
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Số giờ dọn dẹp mỗi buổi', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                            subtitle: Text(_formatDuration(_viewModel.durationHours)),
                            trailing: DropdownButton<double>(
                              value: _viewModel.durationHours,
                              items: List.generate(8, (index) => (index + 1) * 0.5)
                                  .map((h) => DropdownMenuItem<double>(
                                        value: h,
                                        child: Text(_formatDuration(h)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) _viewModel.setDurationHours(val);
                              },
                            ),
                          ),
                          const Divider(),

                          // Gói Month & Sessions (Định kỳ)
                          if (_viewModel.bookingType == 2 && _viewModel.availableMonths.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Chọn thời hạn gói (Số tháng)', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                            const SizedBox(height: 8),
                            Row(
                              children: _viewModel.availableMonths.map((month) {
                                final isSelected = _viewModel.selectedMonth == month;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ChoiceChip(
                                    label: Text('Gói $month Tháng'),
                                    selected: isSelected,
                                    selectedColor: orangeColor.withOpacity(0.15),
                                    checkmarkColor: orangeColor,
                                    backgroundColor: bgColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    labelStyle: TextStyle(
                                      color: isSelected ? orangeColor : darkColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) _viewModel.setSelectedMonth(month);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),

                          ],

                          // Date picker or weekday pickers
                          if (_viewModel.bookingType == 1) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Ngày làm việc', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                              subtitle: Text('${_viewModel.startDate.day}/${_viewModel.startDate.month}/${_viewModel.startDate.year}'),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: orangeColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.calendar_month_rounded, color: orangeColor),
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                            const Divider(),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Ngày bắt đầu', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                                    subtitle: Text('${_viewModel.startDate.day}/${_viewModel.startDate.month}/${_viewModel.startDate.year}'),
                                    trailing: const Icon(Icons.date_range, color: orangeColor),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Kết thúc (Tự động)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    subtitle: Text('${_viewModel.endDate.day}/${_viewModel.endDate.month}/${_viewModel.endDate.year}'),
                                    trailing: const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                                    onTap: null,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text('Chọn các thứ làm việc trong tuần', style: TextStyle(fontWeight: FontWeight.bold, color: darkColor)),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _viewModel.weekdays.keys.map((day) {
                                  final isSelected = _viewModel.weekdays[day]!;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(day == 'CN' ? 'CN' : 'T$day'),
                                      selected: isSelected,
                                      selectedColor: orangeColor.withOpacity(0.15),
                                      checkmarkColor: orangeColor,
                                      backgroundColor: bgColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      labelStyle: TextStyle(
                                        color: isSelected ? orangeColor : darkColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onSelected: (val) {
                                        _viewModel.toggleWeekday(day, val);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                          ],

                          // Dịch vụ bổ sung
                          Builder(
                            builder: (context) {
                              final keywords = ['giặt ủi', 'nấu ăn', 'trẻ em', 'dọn dẹp'];
                              
                              var extraServices = _viewModel.availableServices.where((s) {
                                if (s.maDichVu == widget.service.maDichVu) return false;
                                final lowerName = s.tenDichVu.toLowerCase();
                                return keywords.any((kw) => lowerName.contains(kw));
                              }).toList();
                              
                              extraServices.sort((a, b) {
                                int rank(ServiceModel s) {
                                  final name = s.tenDichVu.toLowerCase();
                                  if (name.contains('giặt ủi')) return 1;
                                  if (name.contains('nấu ăn')) return 2;
                                  if (name.contains('trẻ em')) return 3;
                                  if (name.contains('dọn dẹp')) return 4;
                                  return 5;
                                }
                                return rank(a).compareTo(rank(b));
                              });

                              if (extraServices.length > 3) {
                                extraServices = extraServices.take(3).toList();
                              }

                              if (extraServices.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Dịch vụ bổ sung',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkColor),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Chọn thêm dịch vụ và số giờ sử dụng',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  ...extraServices.map((svc) {
                                    final isSelected = _viewModel.selectedAdditionalServices.containsKey(svc.maDichVu);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFFF7F0) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? orangeColor : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: (val) {
                                            _viewModel.toggleAdditionalService(svc.maDichVu, val ?? false);
                                          },
                                          activeColor: orangeColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          side: BorderSide(color: isSelected ? orangeColor : Colors.grey.shade400),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Tên + giá
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              svc.tenDichVu,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected ? darkColor : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_formatCurrency(svc.donGia)}/giờ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected ? orangeColor : Colors.grey,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Hiển thị cố định 1 giờ khi đã chọn
                                      if (isSelected)
                                        Text(
                                          '${svc.soGioQuyDinh} giờ',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: orangeColor),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                                  }).toList(),
                                  const SizedBox(height: 4),
                                  const Divider(),

                                  // Banner tổng thời gian khi có dịch vụ bổ sung
                                  if (_viewModel.selectedAdditionalServices.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Builder(builder: (ctx) {
                                      final total = _viewModel.totalDurationHours;
                                      final extra = total - _viewModel.baseDurationHours;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: orangeColor.withOpacity(0.07),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: orangeColor.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 18, color: orangeColor),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Tổng thời gian: ${_formatDuration(total)}  (+${_formatDuration(extra)} dịch vụ bổ sung)',
                                                style: const TextStyle(fontSize: 13, color: orangeColor, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 4),
                                  ],
                                ],
                              );
                            },
                          ),

                          // Chọn nhân viên (tùy chọn)
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person_search_rounded, color: orangeColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Chọn nhân viên yêu thích', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chọn nhân viên cụ thể sẽ tính phụ phí +10%',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 12),

                          // Option: No provider selected
                          GestureDetector(
                            onTap: () => _viewModel.setSelectedProvider(null),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _viewModel.selectedProvider == null ? orangeColor.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _viewModel.selectedProvider == null ? orangeColor : Colors.grey.shade200,
                                  width: _viewModel.selectedProvider == null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _viewModel.selectedProvider == null ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    color: _viewModel.selectedProvider == null ? orangeColor : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text('Hệ thống tự phân công', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Giá gốc', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // List of providers
                          ...(_viewModel.providers.map((provider) {
                            final isSelected = _viewModel.selectedProvider != null &&
                                _viewModel.selectedProvider!['MaNguoiDung'] == provider['MaNguoiDung'];
                            final name = provider['HoTenNguoiDung'] ?? 'Nhân viên';
                            final hoSo = provider['HoSoNhanVien'];
                            final soGio = hoSo != null ? (hoSo['SoGioLamViec'] ?? 0) : 0;
                            final ratingRaw = hoSo != null ? (hoSo['SoSaoTrungBinh'] ?? 5.0) : 5.0;
                            final rating = double.tryParse(ratingRaw.toString())?.toStringAsFixed(1) ?? '5.0';
                            final soDienThoai = provider['SoDienThoai'] ?? 'Không có';
                            print(provider['GioiTinh']);
                            print(provider['GioiTinh'].runtimeType);  
                            final gioiTinh = provider['GioiTinh'] == 'Nam' ? 'Nam' : 'Nữ';

                            return GestureDetector(
                              onTap: () => _viewModel.setSelectedProvider(provider),
                              // Nhấn giữ để xem chi tiết nhân viên
                              onLongPress: () => _showProviderDetail(context, name, soDienThoai, rating, soGio, gioiTinh),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? orangeColor.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? orangeColor : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      color: isSelected ? orangeColor : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: orangeColor.withValues(alpha: 0.15),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: orangeColor, fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? darkColor : Colors.grey.shade700)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                                              const SizedBox(width: 2),
                                              Text('$rating ★', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                              const SizedBox(width: 8),
                                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                                              const SizedBox(width: 2),
                                              Text('$soGio giờ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Nút xem chi tiết nhân viên
                                    GestureDetector(
                                      onTap: () => _showProviderDetail(context, name, soDienThoai, rating, soGio, gioiTinh),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.info_outline_rounded, size: 20, color: orangeColor),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('+10%', style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList()),

                          // Customer description note
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú công việc (không bắt buộc)',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tạm tính:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    _viewModel.isCalculatingPrice 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: orangeColor))
                                      : Text(_formatCurrency(_viewModel.temporaryTotalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: orangeColor)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _viewModel.isLoading ? null : _submitBooking,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 1,
                                  ),
                                  child: _viewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.payment_rounded, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'THANH TOÁN',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }
}

// ============================================================
// Widget lịch tùy chỉnh hiển thị ngày bận của nhân viên (vòng đỏ)
// Chỉ đánh dấu đỏ khi giờ đặt của khách TRÙNG khung giờ ca làm của nhân viên
// ============================================================

