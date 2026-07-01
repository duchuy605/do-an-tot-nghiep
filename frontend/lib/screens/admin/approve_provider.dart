import 'package:flutter/material.dart';
import '../../viewmodels/admin/approve_provider_viewmodel.dart';

class ApproveProviderScreen extends StatefulWidget {
  const ApproveProviderScreen({super.key});

  @override
  State<ApproveProviderScreen> createState() => _ApproveProviderScreenState();
}

class _ApproveProviderScreenState extends State<ApproveProviderScreen> {
  final ApproveProviderViewModel _viewModel = ApproveProviderViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadProviders();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(int id) async {
    final response = await _viewModel.approveProvider(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã duyệt hồ sơ nhân viên thành công!'), backgroundColor: Colors.green),
      );
      _viewModel.loadProviders();
    }
  }

  Future<void> _handleReject(int id) async {
    final response = await _viewModel.rejectProvider(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối hồ sơ nhân viên.'), backgroundColor: Colors.orange),
      );
      _viewModel.loadProviders();
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }
          return RefreshIndicator(
            onRefresh: _viewModel.loadProviders,
            color: orangeColor,
            child: _viewModel.providers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Không có hồ sơ nhân viên nào trong danh sách', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viewModel.providers.length,
                    itemBuilder: (context, index) {
                      final provider = _viewModel.providers[index];
                      final int id = provider['MaNguoiDung'] ?? 0;
                      final String name = provider['HoTenNguoiDung'] ?? '';
                      final String email = provider['Email'] ?? '';
                      final String phone = provider['SoDienThoai'] ?? '';
                      final String address = provider['DiaChi'] ?? '';
                      
                      final hoso = provider['HoSoNhanVien'] ?? {};
                      final String cccd = hoso['CCCD'] ?? '';
                      final int status = hoso['TrangThaiDuyet'] ?? 0; // 0: Pending, 1: Approved, 2: Rejected

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (status == 1 ? Colors.green : (status == 2 ? Colors.red : Colors.orange)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status == 1 ? 'Đã duyệt' : (status == 2 ? 'Đã từ chối' : 'Chờ duyệt'),
                                      style: TextStyle(
                                        color: status == 1 ? Colors.green : (status == 2 ? Colors.red : Colors.orange),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Email: $email', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('SĐT: $phone', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('Địa chỉ: $address', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('Số CCCD: $cccd', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: orangeColor)),
                              
                              if (status == 0) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _handleReject(id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      child: const Text('Từ Chối'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () => _handleApprove(id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('DUYỆT HỒ SƠ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
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
