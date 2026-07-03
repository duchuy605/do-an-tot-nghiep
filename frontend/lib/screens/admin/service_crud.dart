import 'package:flutter/material.dart';
import '../../viewmodels/admin/service_crud_viewmodel.dart';
import '../../models/service_model.dart';

class ServiceCrudScreen extends StatefulWidget {
  const ServiceCrudScreen({super.key});

  @override
  State<ServiceCrudScreen> createState() => _ServiceCrudScreenState();
}

class _ServiceCrudScreenState extends State<ServiceCrudScreen> {
  final ServiceCrudViewModel _viewModel = ServiceCrudViewModel();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này không? Dịch vụ sẽ không hiển thị với khách hàng nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Đóng')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa Dịch Vụ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _viewModel.deleteService(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa dịch vụ thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadServices();
    }
  }

  void _showServiceFormDialog({ServiceModel? service}) {
    const orangeColor = Color(0xFFFF8225);
    final bool isEdit = service != null;

    if (isEdit) {
      _nameController.text = service.tenDichVu;
      _descController.text = service.motaDichVu;
      _priceController.text = service.donGia.toStringAsFixed(0);
      _hoursController.text = service.soGioQuyDinh.toString();
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _hoursController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa Dịch Vụ' : 'Thêm Dịch Vụ Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên dịch vụ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả dịch vụ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn giá mỗi giờ (đ)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số giờ quy định tối thiểu', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty ||
                  _descController.text.trim().isEmpty ||
                  _priceController.text.trim().isEmpty ||
                  _hoursController.text.trim().isEmpty) return;

              Navigator.pop(context);

              final data = {
                'TenDichVu': _nameController.text.trim(),
                'MotaDichVu': _descController.text.trim(),
                'DonGia': double.parse(_priceController.text.trim()),
                'SoGioQuyDinh': int.parse(_hoursController.text.trim()),
                'TrangThai': true,
              };

              final response = isEdit
                  ? await _viewModel.updateService(service.maDichVu, data)
                  : await _viewModel.createService(data);

              if (!mounted) return;
              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Cập nhật dịch vụ thành công!' : 'Tạo dịch vụ mới thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _viewModel.loadServices();
              }
            },
            child: Text(isEdit ? 'Cập Nhật' : 'Thêm Mới', style: const TextStyle(color: orangeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceFormDialog(),
        backgroundColor: orangeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }
          return RefreshIndicator(
            onRefresh: _viewModel.loadServices,
            color: orangeColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.services.length,
              itemBuilder: (context, index) {
                final service = _viewModel.services[index];
                final String priceStr = '${service.donGia.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ/giờ';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(service.tenDichVu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(service.motaDichVu, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Giá: $priceStr • Tối thiểu: ${service.soGioQuyDinh}h', style: const TextStyle(fontSize: 13, color: orangeColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showServiceFormDialog(service: service),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _handleDelete(service.maDichVu),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
