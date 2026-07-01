import 'package:flutter/material.dart';
import '../../viewmodels/admin/user_management_viewmodel.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

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
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }
          return RefreshIndicator(
            onRefresh: _viewModel.loadUsers,
            color: orangeColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.users.length,
              itemBuilder: (context, index) {
                final user = _viewModel.users[index];
                final int id = user['MaNguoiDung'] ?? 0;
                final String name = user['HoTenNguoiDung'] ?? '';
                final String email = user['Email'] ?? '';
                final int role = user['VaiTro'] ?? 1;
                final int accountStatus = user['TrangThaiTaiKhoan'] ?? 1; // 1: Active, 2: Locked
                final bool isActive = accountStatus == 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
