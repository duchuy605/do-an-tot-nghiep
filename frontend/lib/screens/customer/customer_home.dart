import 'package:flutter/material.dart';
import '../../viewmodels/customer/customer_home_viewmodel.dart';
import 'booking_form.dart';
import 'customer_wallet.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => CustomerHomeScreenState();
}

class CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final CustomerHomeViewModel _viewModel = CustomerHomeViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadData();
  }

  void reloadData() {
    _viewModel.loadData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  IconData _getServiceIcon(String serviceName) {
    serviceName = serviceName.toLowerCase();
    if (serviceName.contains('dọn dẹp') || serviceName.contains('don dep')) {
      return Icons.cleaning_services_rounded;
    } else if (serviceName.contains('giặt') || serviceName.contains('giat')) {
      return Icons.local_laundry_service_rounded;
    } else if (serviceName.contains('nấu') || serviceName.contains('nau')) {
      return Icons.restaurant_rounded;
    } else if (serviceName.contains('trẻ') || serviceName.contains('tre')) {
      return Icons.child_care_rounded;
    } else if (serviceName.contains('già') || serviceName.contains('gia')) {
      return Icons.elderly_rounded;
    } else if (serviceName.contains('đi chợ') || serviceName.contains('di cho')) {
      return Icons.shopping_bag_rounded;
    } else if (serviceName.contains('máy lạnh') || serviceName.contains('ac') || serviceName.contains('dieu hoa')) {
      return Icons.ac_unit_rounded;
    }
    return Icons.work_outline_rounded;
  }

  Widget _buildPromoSlider(Color orangeColor) {
    final List<Map<String, dynamic>> promos = [
      {
        'title': 'Ưu đãi Khách hàng mới',
        'desc': 'Nhập mã NHAMOI giảm ngay 10% khi đặt dịch vụ dọn dẹp nhà.',
        'code': 'NHAMOI',
        'color': const Color(0xFFFFF2E6),
        'textColor': orangeColor,
      },
      {
        'title': 'Giảm ngay 50.000 đ',
        'desc': 'Trải nghiệm bPay - Nạp tiền ví, thanh toán trực tiếp cực nhanh.',
        'code': 'BTASKEE50',
        'color': const Color(0xFFE6F7FF),
        'textColor': Colors.blue.shade700,
      },
      {
        'title': 'Tổng vệ sinh nhà đón Lễ',
        'desc': 'Căn nhà sáng bóng sạch sẽ. Đặt lịch ngay hôm nay nhận ưu đãi.',
        'code': 'DONNHA',
        'color': const Color(0xFFEBFDF2),
        'textColor': Colors.green.shade700,
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Khuyến Mãi & Tin Tức',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Container(
                width: 290,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: promo['color'],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (promo['textColor'] as Color).withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo['title'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: promo['textColor']),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promo['desc'],
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: promo['textColor'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promo['code'],
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : RefreshIndicator(
                  onRefresh: _viewModel.loadData,
                  color: orangeColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header Block (Orange Gradient Card)
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [orangeColor, Color(0xFFFF9E59)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Chào bạn,',
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _viewModel.customerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white30, width: 2),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.person, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Premium Wallet Card inside Header (Sleek Dark Card)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [darkColor, Color(0xFF33333F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: orangeColor, size: 26),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ví điện tử bPay',
                                            style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_viewModel.walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const CustomerWalletScreen()),
                                        ).then((_) => _viewModel.loadData());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orangeColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Nạp tiền',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Grid Services Section (4-column sleek circular icons layout)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dịch Vụ Giúp Việc CleanGo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GridView.builder(
                                padding: EdgeInsets.zero,// triệt tiêu padding ngầm
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 20,
                                  mainAxisExtent: 95// ép cứng chiều cao mỗi ô
                                ),
                                itemCount: _viewModel.services.length,
                                itemBuilder: (context, index) {
                                  final service = _viewModel.services[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingFormScreen(service: service),
                                        ),
                                      ).then((_) => _viewModel.loadData());
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.shade200,
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: const Color(0xFFFFF2E6),
                                            radius: 26,
                                            child: Icon(
                                              _getServiceIcon(service.tenDichVu),
                                              color: orangeColor,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Text(
                                            service.tenDichVu,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: darkColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        _buildPromoSlider(orangeColor),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
