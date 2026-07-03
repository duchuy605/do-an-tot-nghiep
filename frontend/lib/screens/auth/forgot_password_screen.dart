import 'package:flutter/material.dart';
import '../../viewmodels/auth/forgot_password_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ForgotPasswordViewModel _viewModel = ForgotPasswordViewModel();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await _viewModel.sendCode(_emailController.text.trim());
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã xác nhận đã được gửi đến email của bạn'),
          backgroundColor: Color(0xFFFF8225),
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await _viewModel.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _newPasswordController.text,
    );
    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.'),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.35,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [orangeColor, Color(0xFFFF9E59)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Quên Mật Khẩu',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _viewModel.currentStep == 1
                                ? 'Nhập email để nhận mã xác nhận'
                                : 'Nhập mã xác nhận và mật khẩu mới',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 32),
                              Text(
                                _viewModel.currentStep == 1 ? 'BƯỚC 1: XÁC NHẬN EMAIL' : 'BƯỚC 2: ĐẶT LẠI MẬT KHẨU',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Error message
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
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              if (_viewModel.currentStep == 1) ...[
                                // Step 1: Email input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: darkColor, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Email của bạn',
                                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.email_outlined, color: orangeColor),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: orangeColor, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập Email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Send code button
                                ElevatedButton(
                                  onPressed: _viewModel.isLoading ? null : _handleSendCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: _viewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'GỬI MÃ XÁC NHẬN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                ),
                              ],

                              if (_viewModel.currentStep == 2) ...[
                                // Step 2: OTP code
                                TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    color: darkColor,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 4,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: 'Mã xác nhận (6 số)',
                                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.pin_outlined, color: orangeColor),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7FA),
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: orangeColor, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập mã xác nhận';
                                    }
                                    if (value.trim().length != 6) {
                                      return 'Mã xác nhận phải có 6 số';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // New password
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: _viewModel.obscureNewPassword,
                                  style: const TextStyle(color: darkColor, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu mới',
                                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: orangeColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _viewModel.obscureNewPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: _viewModel.toggleObscureNewPassword,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: orangeColor, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu mới';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải từ 6 ký tự trở lên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _viewModel.obscureConfirmPassword,
                                  style: const TextStyle(color: darkColor, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu mới',
                                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: orangeColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _viewModel.obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: _viewModel.toggleObscureConfirmPassword,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: orangeColor, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'Mật khẩu xác nhận không khớp';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Reset password button
                                ElevatedButton(
                                  onPressed: _viewModel.isLoading ? null : _handleResetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: _viewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'ĐẶT LẠI MẬT KHẨU',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),

                                // Resend code link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Không nhận được mã? ',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    GestureDetector(
                                      onTap: _viewModel.isLoading ? null : _handleSendCode,
                                      child: const Text(
                                        'Gửi lại',
                                        style: TextStyle(
                                          color: orangeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Back to login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Quay lại đăng nhập',
                                      style: TextStyle(
                                        color: orangeColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
