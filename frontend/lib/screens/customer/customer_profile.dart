import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/customer/customer_profile_viewmodel.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final CustomerProfileViewModel _viewModel = CustomerProfileViewModel();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _viewModel.loadProfile();
    if (_viewModel.user != null) {
      setState(() {
        _nameController.text = _viewModel.user?['HoTenNguoiDung'] ?? '';
        _phoneController.text = _viewModel.user?['SoDienThoai'] ?? '';
        _addressController.text = _viewModel.user?['DiaChi'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final response = await _viewModel.updateProfile({
      'HoTenNguoiDung': _nameController.text.trim(),
      'SoDienThoai': _phoneController.text.trim(),
      'DiaChi': _addressController.text.trim(),
    });

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trang cá nhân thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _initData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Cập nhật thất bại.')),
      );
    }
  }

  void _showChangePasswordDialog() {
    const orangeColor = Color(0xFFFF8225);
    _oldPassController.clear();
    _newPassController.clear();

    showDialog(
      context: context,
      // Không cho đóng dialog khi bấm ra ngoài ngoài ý muốn lúc đang nhập liệu
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đổi Mật Khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy đổi mật khẩu',
              style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_oldPassController.text.isEmpty ||
                  _newPassController.text.isEmpty)
                return;
              Navigator.pop(context);
              final response = await _viewModel.changePassword(
                _oldPassController.text,
                _newPassController.text,
              );
              if (!mounted) return;
              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đổi mật khẩu thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response['message'] ?? 'Lỗi đổi mật khẩu.'),
                  ),
                );
              }
            },
            child: const Text(
              'Đổi Mật Khẩu',
              style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Đăng Xuất',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _viewModel.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final fileName = picked.name;
      final response = await _viewModel.uploadAvatar(bytes, fileName);
      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _initData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Lỗi cập nhật ảnh.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Tài Khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: orangeColor),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Beautiful Avatar Header block with gradient background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [orangeColor, Color(0xFFFF9E59)],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.white,
                                    backgroundImage:
                                        _viewModel.user?['AnhDaiDien'] !=
                                                null &&
                                            _viewModel.user!['AnhDaiDien']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(_viewModel.avatarUrl)
                                        : null,
                                    child:
                                        _viewModel.user?['AnhDaiDien'] ==
                                                null ||
                                            _viewModel.user!['AnhDaiDien']
                                                .toString()
                                                .isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 54,
                                            color: orangeColor,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickAndUploadAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: orangeColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _viewModel.user?['HoTenNguoiDung'] ??
                                  'Khách hàng',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _viewModel.user?['Email'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Form Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông Tin Cá Nhân',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Họ và tên',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: orangeColor,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: orangeColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: orangeColor,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: orangeColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Address field
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ thường trú',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.home_outlined,
                                  color: orangeColor,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: orangeColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save changes button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orangeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'CẬP NHẬT THÔNG TIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Extra Setting Actions styled like modern list cards
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: orangeColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: orangeColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: const Text(
                                        'Thay đổi mật khẩu',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.grey,
                                      ),
                                      onTap: _showChangePasswordDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
