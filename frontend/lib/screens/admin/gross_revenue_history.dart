import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class GrossRevenueHistoryScreen extends StatefulWidget {
  const GrossRevenueHistoryScreen({super.key});

  @override
  State<GrossRevenueHistoryScreen> createState() => _GrossRevenueHistoryScreenState();
}

class _GrossRevenueHistoryScreenState extends State<GrossRevenueHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getGrossRevenueHistory();
      if (response['success'] == true) {
        setState(() {
          _history = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatVND(dynamic amount) {
    double value = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,###', 'vi_VN').format(value)} đ';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.blue;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Lịch Sử Doanh Thu Gộp', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _history.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu doanh thu', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: primaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final customer = item['KhachHang'];
                      final provider = item['NhanVien'];

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ca làm: #${item['MaCaLam']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '+ ${_formatVND(item['TongTien'])}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Khách: ${customer?['HoTenNguoiDung'] ?? 'Ẩn danh'}',
                                        style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.engineering, size: 16, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('NV: ${provider?['HoTenNguoiDung'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Làm việc: ${_formatDate(item['NgayLamViec'])}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hoàn thành: ${_formatDate(item['NgayHoanThanh'])}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
