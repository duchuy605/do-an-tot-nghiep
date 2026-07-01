import 'package:flutter/material.dart';
import '../../viewmodels/admin/special_day_crud_viewmodel.dart';

class SpecialDayCrudScreen extends StatefulWidget {
  const SpecialDayCrudScreen({super.key});

  @override
  State<SpecialDayCrudScreen> createState() => _SpecialDayCrudScreenState();
}

class _SpecialDayCrudScreenState extends State<SpecialDayCrudScreen> {
  final SpecialDayCrudViewModel _viewModel = SpecialDayCrudViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadSpecialDays();
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
        content: const Text('Bạn có chắc chắn muốn xóa ngày đặc biệt này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.deleteSpecialDay(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa ngày đặc biệt thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadSpecialDays();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Xóa thất bại.')),
      );
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'Ngày Lễ');
    final coeffController = TextEditingController(text: '1.5');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm Ngày Đặc Biệt'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên Ngày (Ví dụ: Tết Dương Lịch)'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên ngày' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chọn Ngày:'),
                    subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_month, color: Color(0xFFFF8225)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Loại Ngày (Ví dụ: Lễ Tết)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: coeffController,
                    decoration: const InputDecoration(labelText: 'Hệ Số Giá (Ví dụ: 1.5, 2.0)'),
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
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context);

                final String dateStr = selectedDate.toIso8601String().split('T')[0];

                final response = await _viewModel.createSpecialDay({
                  'TenNgay': nameController.text.trim(),
                  'Ngay': dateStr,
                  'LoaiNgay': typeController.text.trim(),
                  'HeSoGia': double.parse(coeffController.text),
                });

                if (!mounted) return;
                if (response['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm ngày đặc biệt thành công!'), backgroundColor: Colors.green),
                  );
                  _viewModel.loadSpecialDays();
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
          if (_viewModel.specialDays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa cấu hình ngày đặc biệt nào', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.specialDays.length,
            itemBuilder: (context, index) {
              final sd = _viewModel.specialDays[index];
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
                    child: const Icon(Icons.star, color: orangeColor),
                  ),
                  title: Text(sd['TenNgay'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ngày: ${sd['Ngay']} | Hệ số: x${sd['HeSoGia']} (${sd['LoaiNgay'] ?? "Lễ"})'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleDelete(sd['MaNgay']),
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
