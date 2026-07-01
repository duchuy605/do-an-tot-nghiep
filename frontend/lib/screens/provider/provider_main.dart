import 'package:flutter/material.dart';
import 'job_board.dart';
import 'my_jobs.dart';
import 'provider_wallet.dart';
import '../customer/customer_notifications.dart'; // Dùng chung thông báo
import 'provider_profile.dart';

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _selectedIndex = 0;

  // Dùng GlobalKey để gọi reload data khi chuyển tab
  final _jobBoardKey = GlobalKey<JobBoardScreenState>();
  final _myJobsKey = GlobalKey<MyJobsScreenState>();
  final _walletKey = GlobalKey<ProviderWalletScreenState>();
  final _notificationsKey = GlobalKey<CustomerNotificationsScreenState>();
  final _profileKey = GlobalKey<ProviderProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      JobBoardScreen(key: _jobBoardKey),
      MyJobsScreen(key: _myJobsKey),
      ProviderWalletScreen(key: _walletKey),
      CustomerNotificationsScreen(key: _notificationsKey),
      ProviderProfileScreen(key: _profileKey),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Reload data khi chuyển tab
    switch (index) {
      case 0:
        _jobBoardKey.currentState?.reloadData();
        break;
      case 1:
        _myJobsKey.currentState?.reloadData();
        break;
      case 2:
        _walletKey.currentState?.reloadData();
        break;
      case 3:
        _notificationsKey.currentState?.reloadData();
        break;
      case 4:
        _profileKey.currentState?.reloadData();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: orangeColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Nhận việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Việc của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Ví thu nhập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

