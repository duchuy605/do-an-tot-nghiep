import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'customer_wallet.dart';
import 'customer_bookings.dart';
import 'customer_notifications.dart';
import 'customer_profile.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  // Dùng GlobalKey để gọi reload data khi chuyển tab
  final _homeKey = GlobalKey<CustomerHomeScreenState>();
  final _bookingsKey = GlobalKey<CustomerBookingsScreenState>();
  final _walletKey = GlobalKey<CustomerWalletScreenState>();
  final _notificationsKey = GlobalKey<CustomerNotificationsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CustomerHomeScreen(key: _homeKey),
      CustomerBookingsScreen(key: _bookingsKey),
      CustomerWalletScreen(key: _walletKey),
      CustomerNotificationsScreen(key: _notificationsKey),
      const CustomerProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Reload data khi chuyển tab
    switch (index) {
      case 0:
        _homeKey.currentState?.reloadData();
        break;
      case 1:
        _bookingsKey.currentState?.reloadData();
        break;
      case 2:
        _walletKey.currentState?.reloadData();
        break;
      case 3:
        _notificationsKey.currentState?.reloadData();
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Ví tiền',
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

