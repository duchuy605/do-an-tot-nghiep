import 'package:flutter/material.dart';
import '../../viewmodels/admin/time_slot_crud_viewmodel.dart';

class TimeSlotCrudScreen extends StatefulWidget {
  const TimeSlotCrudScreen({super.key});

  @override
  State<TimeSlotCrudScreen> createState() => _TimeSlotCrudScreenState();
}

class _TimeSlotCrudScreenState extends State<TimeSlotCrudScreen> {
  final TimeSlotCrudViewModel _viewModel = TimeSlotCrudViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadTimeSlots();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa khung giờ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.deleteTimeSlot(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa khung giờ thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadTimeSlots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Xóa thất bại.')),
      );
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final startController = TextEditingController(text: '18:00:00');
    final endController = TextEditingController(text: '22:00:00');
    final coeffController = TextEditingController(text: '1.2');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm Khung Giờ'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên Khung Giờ (Ví dụ: Cao Điểm Tối)'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên khung giờ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: 'Giờ Bắt Đầu (hh:mm:ss)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giờ bắt đầu';
                    final parts = val.split(':');
                    if (parts.length != 3) return 'Định dạng chuẩn là hh:mm:ss';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: 'Giờ Kết Thúc (hh:mm:ss)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giờ kết thúc';
                    final parts = val.split(':');
                    if (parts.length != 3) return 'Định dạng chuẩn là hh:mm:ss';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: coeffController,
                  decoration: const InputDecoration(labelText: 'Hệ Số Giá (Ví dụ: 1.2, 1.5)'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập hệ số';
                    if (double.tryParse(val) == null) return 'Hệ số phải là số';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(context);

              final response = await _viewModel.createTimeSlot({
                'TenKhungGio': nameController.text.trim(),
                'GioBatDau': startController.text.trim(),
                'GioKetThuc': endController.text.trim(),
                'HeSoGia': double.parse(coeffController.text),
              });

              if (!mounted) return;
              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm khung giờ thành công!'), backgroundColor: Colors.green),
                );
                _viewModel.loadTimeSlots();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['message'] ?? 'Thêm thất bại.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8225)),
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }
          if (_viewModel.timeSlots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa cấu hình khung giờ đặc biệt nào', style: TextStyle(color: Colors.black)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.timeSlots.length,
            itemBuilder: (context, index) {
              final ts = _viewModel.timeSlots[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: orangeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, color: orangeColor),
                  ),
                  title: Text(ts['TenKhungGio'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Từ: ${ts['GioBatDau']} Đến: ${ts['GioKetThuc']} | Hệ số: x${ts['HeSoGia']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleDelete(ts['MaQuyDinhGio']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: orangeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
