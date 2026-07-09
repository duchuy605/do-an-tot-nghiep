import 'package:flutter/material.dart';
import '../../viewmodels/admin/user_management_viewmodel.dart';
import '../../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  final int? initialRoleFilter;
  const UserManagementScreen({super.key, this.initialRoleFilter});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementViewModel _viewModel = UserManagementViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _toggleLockUser(int id, bool isCurrentlyActive) async {
    final response = await _viewModel.toggleLockUser(id, isCurrentlyActive);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyActive ? 'Đã khóa tài khoản thành công!' : 'Đã mở khóa tài khoản thành công!'),
          backgroundColor: isCurrentlyActive ? Colors.orange : Colors.green,
        ),
      );
      _viewModel.loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Thay đổi trạng thái thất bại.')),
      );
    }
  }

  Future<void> _showUserStatsDialog(int id, String name, int role) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.getUserStats(id);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response['success'] == true) {
        final stats = response['data'] ?? {};
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Thống kê: $name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: role == 1 
                ? [
                    Text('Tổng tiền nạp: ${_formatPrice(stats['totalDeposited'] ?? 0)}'),
                    const SizedBox(height: 8),
                    Text('Tiền thanh toán ca làm: ${_formatPrice(stats['totalPaid'] ?? 0)}'),
                    const SizedBox(height: 8),
                    Text('Số ca làm đã đặt: ${stats['totalShifts'] ?? 0}'),
                  ]
                : [
                    Text('Số ca đã nhận: ${stats['totalAccepted'] ?? 0}'),
                    const SizedBox(height: 8),
                    Text('Số ca đã hoàn thành: ${stats['totalCompleted'] ?? 0}'),
                    const SizedBox(height: 8),
                    Text('Tổng lương nhận được: ${_formatPrice(stats['totalEarned'] ?? 0)}'),
                  ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Lỗi tải dữ liệu')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối máy chủ')),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${price.toString().replaceAllMapped(formatter, (Match m) => '${m[1]}.')} đ';
  }

  String _getRoleLabel(int role) {
    if (role == 3) return 'Admin';
    if (role == 2) return 'Nhân viên';
    return 'Khách hàng';
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: widget.initialRoleFilter != null
          ? AppBar(
              title: Text(widget.initialRoleFilter == 1 ? 'Danh sách khách hàng' : 'Danh sách nhân viên'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }

          final filteredUsers = widget.initialRoleFilter != null 
              ? _viewModel.users.where((u) => u['VaiTro'] == widget.initialRoleFilter).toList()
              : _viewModel.users;

          return RefreshIndicator(
            onRefresh: _viewModel.loadUsers,
            color: orangeColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final int id = user['MaNguoiDung'] ?? 0;
                final String name = user['HoTenNguoiDung'] ?? '';
                final String email = user['Email'] ?? '';
                final int role = user['VaiTro'] ?? 1;
                final int accountStatus = user['TrangThaiTaiKhoan'] ?? 1; // 1: Active, 2: Locked
                final bool isActive = accountStatus == 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showUserStatsDialog(id, name, role),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: role == 2 ? const Color(0xFFFFF2E6) : Colors.blue.shade50,
                          child: Icon(
                            role == 2 ? Icons.engineering_rounded : Icons.person_rounded,
                            color: role == 2 ? orangeColor : Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getRoleLabel(role),
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isActive ? 'Hoạt động' : 'Đã khóa',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Chỉ cho phép khóa/mở khóa các user không phải là Admin
                        if (role != 3)
                          IconButton(
                            icon: Icon(
                              isActive ? Icons.lock_open_rounded : Icons.lock_rounded,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            onPressed: () => _toggleLockUser(id, isActive),
                            tooltip: isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                          ),
                      ],
                    ),
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
