import 'package:flutter/material.dart';
import '../../viewmodels/admin/package_crud_viewmodel.dart';

class PackageCrudScreen extends StatefulWidget {
  const PackageCrudScreen({super.key});

  @override
  State<PackageCrudScreen> createState() => _PackageCrudScreenState();
}

class _PackageCrudScreenState extends State<PackageCrudScreen> {
  final PackageCrudViewModel _viewModel = PackageCrudViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadPackages();
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
        content: const Text('Bạn có chắc chắn muốn xóa gói định kỳ này không?'),
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

    final response = await _viewModel.deletePackage(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa gói định kỳ thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadPackages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Xóa thất bại.')),
      );
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final monthsController = TextEditingController(text: '1');
    final sessionsController = TextEditingController(text: '4');
    final discountController = TextEditingController(text: '5.0');
    int status = 1; // 1: Dang ap dung

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm Gói Định Kỳ'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: monthsController,
                    decoration: const InputDecoration(labelText: 'Số Tháng (Chu kỳ gói)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tháng';
                      if (int.tryParse(val) == null) return 'Phải là số nguyên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sessionsController,
                    decoration: const InputDecoration(labelText: 'Số Buổi Làm Việc (Ví dụ: 4, 8, 12)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số buổi';
                      if (int.tryParse(val) == null) return 'Phải là số nguyên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: discountController,
                    decoration: const InputDecoration(labelText: 'Phần Trăm Giảm Giá (%)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập % giảm giá';
                      if (double.tryParse(val) == null) return 'Phải là số';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng Thái:'),
                      DropdownButton<int>(
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Đang áp dụng')),
                          DropdownMenuItem(value: 2, child: Text('Ngừng áp dụng')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              status = val;
                            });
                          }
                        },
                      ),
                    ],
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

                final response = await _viewModel.createPackage({
                  'SoThang': int.parse(monthsController.text),
                  'SoBuoi': int.parse(sessionsController.text),
                  'PhanTramGiamGia': double.parse(discountController.text),
                  'TrangThai': status,
                });

                if (!mounted) return;
                if (response['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm gói định kỳ thành công!'), backgroundColor: Colors.green),
                  );
                  _viewModel.loadPackages();
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
          if (_viewModel.packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa cấu hình gói định kỳ nào', style: TextStyle(color: Colors.black)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.packages.length,
            itemBuilder: (context, index) {
              final pkg = _viewModel.packages[index];
              final String statusStr = pkg['TrangThai'] == 1 ? 'Đang áp dụng' : 'Ngừng áp dụng';
              final Color statusColor = pkg['TrangThai'] == 1 ? Colors.green : Colors.red;

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
                    child: const Icon(Icons.style, color: orangeColor),
                  ),
                  title: Text('Gói định kỳ: ${pkg['SoBuoi']} buổi / ${pkg['SoThang']} tháng', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Text('Giảm giá: ${pkg['PhanTramGiamGia']}% | '),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusStr,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleDelete(pkg['MaLoaiGoi']),
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
