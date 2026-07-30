import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../viewmodels/admin/admin_main_viewmodel.dart';
import 'admin_dashboard.dart';
import 'user_management.dart';
import 'approve_provider.dart';
import 'service_crud.dart';
import 'complaint_list.dart';
import 'special_day_crud.dart';
import 'time_slot_crud.dart';
import 'package_crud.dart';
import '../customer/customer_notifications.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final AdminMainViewModel _viewModel = AdminMainViewModel();
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.loadEmail();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const UserManagementScreen(),
    const ApproveProviderScreen(),
    const ServiceCrudScreen(),
    const ComplaintListScreen(),
    const SpecialDayCrudScreen(),
    const TimeSlotCrudScreen(),
    const PackageCrudScreen(),
    const CustomerNotificationsScreen(hideAppBar: true),
  ];

  final List<String> _titles = [
    'Thống Kê Doanh Thu',
    'Quản Lý Người Dùng',
    'Duyệt Hồ Sơ Nhân Viên',
    'Quản Lý Dịch Vụ',
    'Xử Lý Khiếu Nại',
    'Quản Lý Ngày Lễ Tết',
    'Quản Lý Khung Giờ',
    'Quản Lý Gói Định Kỳ',
    'Thông Báo Hệ Thống',
  ];

  Future<void> _handleLogout() async {
    await _viewModel.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkBlueColor = Color(0xFF1E1E24);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIdx]),
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: darkBlueColor),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: orangeColor,
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
              ),
              accountName: const Text(
                'Hệ Thống Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Text(_viewModel.email ?? 'admin@gmail.com');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: orangeColor),
              title: const Text('Thống kê doanh thu'),
              selected: _selectedIdx == 0,
              onTap: () {
                setState(() => _selectedIdx = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: orangeColor),
              title: const Text('Quản lý người dùng'),
              selected: _selectedIdx == 1,
              onTap: () {
                setState(() => _selectedIdx = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_rounded, color: orangeColor),
              title: const Text('Duyệt nhân viên mới'),
              selected: _selectedIdx == 2,
              onTap: () {
                setState(() => _selectedIdx = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.design_services_rounded, color: orangeColor),
              title: const Text('Quản lý dịch vụ'),
              selected: _selectedIdx == 3,
              onTap: () {
                setState(() => _selectedIdx = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_rounded, color: orangeColor),
              title: const Text('Giải quyết khiếu nại'),
              selected: _selectedIdx == 4,
              onTap: () {
                setState(() => _selectedIdx = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: orangeColor),
              title: const Text('Quản lý ngày lễ tết'),
              selected: _selectedIdx == 5,
              onTap: () {
                setState(() => _selectedIdx = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_time_rounded, color: orangeColor),
              title: const Text('Quản lý khung giờ'),
              selected: _selectedIdx == 6,
              onTap: () {
                setState(() => _selectedIdx = 6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.style_rounded, color: orangeColor),
              title: const Text('Quản lý gói định kỳ'),
              selected: _selectedIdx == 7,
              onTap: () {
                setState(() => _selectedIdx = 7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_rounded, color: orangeColor),
              title: const Text('Thông báo hệ thống'),
              selected: _selectedIdx == 8,
              onTap: () {
                setState(() => _selectedIdx = 8);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
              title: const Text('Đăng xuất'),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _screens[_selectedIdx],
    );
  }
}
