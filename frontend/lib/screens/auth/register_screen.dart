import 'package:flutter/material.dart';
import '../../viewmodels/auth/register_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cccdController = TextEditingController();
  final RegisterViewModel _viewModel = RegisterViewModel();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.birthDate,
      firstDate: DateTime(1960),
      lastDate: DateTime(2010),
    );
    if (picked != null) {
      _viewModel.setBirthDate(picked);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final regData = {
      'HoTenNguoiDung': _nameController.text.trim(),
      'Email': _emailController.text.trim(),
      'SoDienThoai': _phoneController.text.trim(),
      'MatKhau': _passwordController.text,
      'DiaChi': _addressController.text.trim(),
      'GioiTinh': _viewModel.gender,
      'NgaySinh': _viewModel.birthDate.toIso8601String().split('T')[0],
      'VaiTro': _viewModel.role,
      if (_viewModel.role == 2) 'CCCD': _cccdController.text.trim(),
    };

    final response = await _viewModel.register(regData);

    if (response['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tài khoản thành công! Bạn có thể đăng nhập ngay.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tham Gia Hệ Thống Giúp Việc',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vui lòng điền đầy đủ các thông tin dưới đây',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
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

                    // Choice Chips for Role selection (styled nicely)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Khách Hàng')),
                            selected: _viewModel.role == 1,
                            selectedColor: orangeColor.withOpacity(0.15),
                            checkmarkColor: orangeColor,
                            backgroundColor: bgColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            labelStyle: TextStyle(
                              color: _viewModel.role == 1 ? orangeColor : darkColor,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) _viewModel.setRole(1);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Người Giúp Việc')),
                            selected: _viewModel.role == 2,
                            selectedColor: orangeColor.withOpacity(0.15),
                            checkmarkColor: orangeColor,
                            backgroundColor: bgColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            labelStyle: TextStyle(
                              color: _viewModel.role == 2 ? orangeColor : darkColor,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) _viewModel.setRole(2);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Họ và Tên
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Họ và Tên',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.person_outline, color: orangeColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ tên';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_outlined, color: orangeColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập Email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số Điện Thoại
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Số Điện Thoại',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.phone_outlined, color: orangeColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                        if (value.length < 10) return 'Số điện thoại không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mật Khẩu
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _viewModel.obscurePassWord,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Mật Khẩu',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: orangeColor),
                        suffixIcon: IconButton(onPressed: (){
                          _viewModel.toggleObscurePassWord();
                        }, icon: Icon(_viewModel.obscurePassWord? Icons.visibility_off:Icons.visibility)),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                        if (value.length < 6) return 'Mật khẩu phải dài ít nhất 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Địa Chỉ Thường Trú
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Địa Chỉ Thường Trú',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.home_outlined, color: orangeColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập địa chỉ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // CCCD (Hiển thị động nếu chọn vai trò Người Giúp Việc)
                    if (_viewModel.role == 2) ...[
                      TextFormField(
                        controller: _cccdController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Số CCCD (Căn cước công dân)',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.badge_outlined, color: orangeColor),
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                        ),
                        validator: (value) {
                          if (_viewModel.role == 2 && (value == null || value.trim().isEmpty)) {
                            return 'Vui lòng nhập số CCCD';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Giới Tính & Ngày Sinh
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _viewModel.gender,
                            decoration: InputDecoration(
                              labelText: 'Giới Tính',
                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: const Icon(Icons.wc_outlined, color: orangeColor),
                              filled: true,
                              fillColor: bgColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                            ),
                            items: ['Nam', 'Nữ']
                                .map((label) => DropdownMenuItem(
                                      value: label,
                                      child: Text(label),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) _viewModel.setGender(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectBirthDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Ngày Sinh',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: const Icon(Icons.calendar_today_outlined, color: orangeColor),
                                filled: true,
                                fillColor: bgColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                              ),
                              child: Text(
                                '${_viewModel.birthDate.day}/${_viewModel.birthDate.month}/${_viewModel.birthDate.year}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _handleRegister,
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
                          : const Text(
                              'ĐĂNG KÝ NGAY',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
