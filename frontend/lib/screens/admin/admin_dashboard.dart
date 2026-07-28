import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/admin/admin_dashboard_viewmodel.dart';
import 'system_earnings_history.dart';
import 'gross_revenue_history.dart';
import 'user_management.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardViewModel _viewModel = AdminDashboardViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadDashboard();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _formatVND(double amt) {
    return '${NumberFormat('#,###', 'vi_VN').format(amt.toInt())} đ';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardClickable({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListStatRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(List<dynamic>? weeklyShifts) {
    if (weeklyShifts == null || weeklyShifts.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ca Làm Việc Theo Tuần', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24))),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weeklyShifts.map((w) {
                final count = int.tryParse(w['count']?.toString() ?? '0') ?? 0;
                // Calculate relative height (max 100)
                final maxCount = weeklyShifts.fold<int>(1, (m, e) => m > (int.tryParse(e['count']?.toString() ?? '0') ?? 0) ? m : (int.tryParse(e['count']?.toString() ?? '0') ?? 0));
                final height = (count / maxCount) * 80;
                
                return Column(
                  children: [
                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height < 10 ? 10 : height,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w['label'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftStats(Map<String, dynamic>? shiftStats) {
    if (shiftStats == null) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Chi Tiết Ca Làm Việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24))),
            const SizedBox(height: 12),
            _buildListStatRow('Chờ nhân viên nhận', '${shiftStats['pending'] ?? 0}', Colors.amber, Icons.pending_actions_rounded),
            const Divider(),
            _buildListStatRow('Đã nhận (Chờ thực hiện)', '${shiftStats['accepted'] ?? 0}', Colors.blue, Icons.assignment_ind_rounded),
            const Divider(),
            _buildListStatRow('Đã hoàn thành', '${shiftStats['completed'] ?? 0}', Colors.green, Icons.check_circle_outline),
            const Divider(),
            _buildListStatRow('Đã hủy', '${shiftStats['cancelled'] ?? 0}', Colors.red, Icons.cancel_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowStats(Map<String, dynamic>? cashFlowStats) {
    if (cashFlowStats == null) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Chi Tiết Luồng Tiền (Cash Flow)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24))),
            const SizedBox(height: 12),
            _buildListStatRow('Khách nạp tiền', _formatVND(double.tryParse(cashFlowStats['deposit']?.toString() ?? '0') ?? 0), Colors.teal, Icons.account_balance_wallet),
            const Divider(),
            _buildListStatRow('Khách thanh toán đơn', _formatVND(double.tryParse(cashFlowStats['payment']?.toString() ?? '0') ?? 0), Colors.blue, Icons.payments_rounded),
            const Divider(),
            _buildListStatRow('Hệ thống hoàn tiền', _formatVND(double.tryParse(cashFlowStats['refund']?.toString() ?? '0') ?? 0), Colors.orange, Icons.currency_exchange_rounded),
            const Divider(),
            _buildListStatRow('Chi trả lương nhân viên', _formatVND(double.tryParse(cashFlowStats['payout']?.toString() ?? '0') ?? 0), Colors.red, Icons.money_off_rounded),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FA),
          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : RefreshIndicator(
                  onRefresh: _viewModel.loadDashboard,
                  color: orangeColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Tổng Quan Hoạt Động Hệ Thống',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E24)),
                        ),
                        const SizedBox(height: 16),
                        _buildStatCardClickable(
                          title: 'Hoa hồng hệ thống thu nhập (20%)',
                          value: _formatVND(double.tryParse(_viewModel.stats['systemEarnings']?.toString() ?? '0') ?? 0),
                          icon: Icons.account_balance_rounded,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SystemEarningsHistoryScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStatCardClickable(
                          title: 'Tổng doanh thu giao dịch (Gross)',
                          value: _formatVND(double.tryParse(_viewModel.stats['totalRevenue']?.toString() ?? '0') ?? 0),
                          icon: Icons.payments_rounded,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GrossRevenueHistoryScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => const UserManagementScreen(initialRoleFilter: 1),
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.people, color: orangeColor, size: 28),
                                        const SizedBox(height: 8),
                                        const Text('Khách hàng', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_viewModel.stats['totalCustomers'] ?? 0}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => const UserManagementScreen(initialRoleFilter: 2),
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.engineering, color: Colors.purple, size: 28),
                                        const SizedBox(height: 8),
                                        const Text('Nhân viên', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_viewModel.stats['totalProviders'] ?? 0}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _buildWeeklyStats(_viewModel.stats['weeklyShifts']),
                        const SizedBox(height: 20),
                        _buildShiftStats(_viewModel.stats['shiftStats']),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
