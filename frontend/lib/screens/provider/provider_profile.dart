import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/provider/provider_profile_viewmodel.dart';
import '../auth/login_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => ProviderProfileScreenState();
}

class ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ProviderProfileViewModel _viewModel = ProviderProfileViewModel();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cccdController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void reloadData() {
    _initData();
  }

  Future<void> _initData() async {
    await _viewModel.loadProfile();
    if (_viewModel.user != null) {
      setState(() {
        _nameController.text = _viewModel.user?['HoTenNguoiDung'] ?? '';
        _phoneController.text = _viewModel.user?['SoDienThoai'] ?? '';
        _addressController.text = _viewModel.user?['DiaChi'] ?? '';
        _cccdController.text = _viewModel.hoso?['CCCD'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
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
      'CCCD': _cccdController.text.trim(),
      'TrangThaiHoatDong': _viewModel.activeStatus,
    });

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin cá nhân và hồ sơ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _initData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Cập nhật hồ sơ thất bại.'),
        ),
      );
    }
  }

  Future<void> _toggleActiveStatus(bool value) async {
    final response = await _viewModel.toggleActiveStatus(value);
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Đã BẬT trạng thái sẵn sàng nhận việc!'
                : 'Đã TẮT trạng thái sẵn sàng nhận việc.',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Không thể đổi trạng thái hoạt động.',
          ),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    const orangeColor = Color(0xFFFF8225);
    _oldPassController.clear();
    _newPassController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đổi Mật Khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy đổi mật khẩu', style: TextStyle(color: orangeColor,fontWeight: FontWeight.bold)),
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
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFFFF8225))),
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
          'Tài Khoản Nhân Viên',
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
                      // Header Avatar
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
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
                                            Icons.engineering_rounded,
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
                              _viewModel.user?['HoTenNguoiDung'] ?? 'Nhân viên',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mã NV: ${_viewModel.hoso?['MaNhanVien'] ?? ''}',
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

                      // Performance Statistics Horizontal Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${double.tryParse(_viewModel.hoso?['SoSaoTrungBinh']?.toString() ?? '5.0')?.toStringAsFixed(1) ?? '5.0'} / 5.0',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: darkColor,
                                    ),
                                  ),
                                  const Text(
                                    'Đánh giá sao',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: orangeColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_viewModel.hoso?['SoGioLamViec'] ?? '0'} giờ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: darkColor,
                                    ),
                                  ),
                                  const Text(
                                    'Số giờ dọn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.rate_review_outlined,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_viewModel.hoso?['TongDanhGia'] ?? '0'} lượt',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: darkColor,
                                    ),
                                  ),
                                  const Text(
                                    'Đánh giá nhận',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Active status switch
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: SwitchListTile(
                                title: const Text(
                                  'Sẵn Sàng Nhận Việc',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: darkColor,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Bật để hiển thị tên nhận ca dọn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                activeColor: orangeColor,
                                value: _viewModel.activeStatus,
                                onChanged: _toggleActiveStatus,
                              ),
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              'Thông Tin Hồ Sơ Cá Nhân',
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
                                labelText: 'Họ và tên nhân viên',
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
                                labelText: 'Địa chỉ của bạn',
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
                            const SizedBox(height: 14),

                            // CCCD field
                            TextFormField(
                              controller: _cccdController,
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Căn cước công dân (CCCD)',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
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

                            // Save Button
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
                                  'CẬP NHẬT HỒ SƠ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Change password list item
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
                                          color: orangeColor.withValues(alpha: 0.1),
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
