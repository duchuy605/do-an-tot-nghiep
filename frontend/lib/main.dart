import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_main.dart';
import 'screens/provider/provider_main.dart';
import 'screens/admin/admin_main.dart';
import 'services/socket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return MaterialApp(
      navigatorKey: SocketService.navigatorKey,
      title: 'bTaskee Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeColor,
          primary: orangeColor,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final token = await ApiService.getToken();
    final role = await ApiService.getUserRole();

    if (!mounted) return;

    if (token != null && role != null) {
      // Khởi tạo Socket
      SocketService().initSocket();

      // Token exists, route to dashboard directly
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
    } else {
      // Go to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF8225),
        ),
      ),
    );
  }
}
