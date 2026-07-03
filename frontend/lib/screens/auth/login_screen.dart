import 'package:flutter/material.dart';
import '../../viewmodels/auth/login_viewmodel.dart';
import '../customer/customer_main.dart';
import '../provider/provider_main.dart';
import '../admin/admin_main.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginViewModel _viewModel = LoginViewModel();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await _viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (response['success'] == true) {
      final role = response['data']['user']['VaiTro'];
      if (!mounted) return;

      if (role == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainScreen()),
        );
      } else if (role == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProviderMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // Beautiful Gradient Header with Logo
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'HH Helper',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ứng Dụng Giúp Việc Hàng Đầu',
                        style: TextStyle(
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
                    child: ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                                letterSpacing: 1.1,
                              ),
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
                            
                            // Email Input
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
                            const SizedBox(height: 16),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _viewModel.obscurePassword,
                              style: const TextStyle(color: darkColor, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: orangeColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _viewModel.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _viewModel.toggleObscurePassword,
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
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải từ 6 ký tự trở lên';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Button
                            ElevatedButton(
                              onPressed: _viewModel.isLoading ? null : _handleLogin,
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
                                      'ĐĂNG NHẬP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: orangeColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Register Redirection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Chưa có tài khoản? ',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Đăng ký ngay',
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
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
