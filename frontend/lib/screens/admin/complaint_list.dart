import 'package:flutter/material.dart';
import '../../viewmodels/admin/complaint_list_viewmodel.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final ComplaintListViewModel _viewModel = ComplaintListViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadComplaints();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleProcess(int id) async {
    final response = await _viewModel.processComplaint(id);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái khiếu nại sang: Đang xử lý'), backgroundColor: Colors.blue),
      );
    }
  }

  void _showResolveDialog(int complaintId, double maxRefundAmount) {
    if (_viewModel.resolutionTypes.isEmpty) return;
    int selectedHinhThuc = _viewModel.resolutionTypes.first['MaHinhThucXuLy'];
    final refundController = TextEditingController(text: maxRefundAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Giải Quyết Khiếu Nại'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedHinhThuc,
                decoration: const InputDecoration(labelText: 'Hình thức giải quyết', border: OutlineInputBorder()),
                items: _viewModel.resolutionTypes.map<DropdownMenuItem<int>>((type) {
                  return DropdownMenuItem<int>(
                    value: type['MaHinhThucXuLy'],
                    child: Text(type['TenHinhThuc'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedHinhThuc = val;
                    });
                  }
                },
              ),
              if (_isRefundType(selectedHinhThuc)) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: refundController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền đền bù (đ)',
                    helperText: 'Tối đa: ${maxRefundAmount.toStringAsFixed(0)} đ',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final refundVal = _isRefundType(selectedHinhThuc) ? double.tryParse(refundController.text.trim()) : null;
                _submitResolution(complaintId, selectedHinhThuc, refundVal);
              },
              child: const Text('Giải Quyết', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Gửi yêu cầu giải quyết khiếu nại lên server
  Future<void> _submitResolution(int id, int hinhThuc, double? refund) async {
    final response = await _viewModel.resolveComplaint(id, hinhThuc, refund);
    if (!mounted) return;
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giải quyết khiếu nại thành công!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Lỗi giải quyết khiếu nại.')),
      );
    }
  }

  String _getComplaintStatusText(int status) {
    if (status == 0) return 'Chờ xử lý';
    if (status == 1) return 'Đang xử lý';
    return 'Đã giải quyết';
  }

  // Kiểm tra hình thức xử lý có phải hoàn tiền không (dựa vào tên)
  bool _isRefundType(int hinhThucId) {
    final type = _viewModel.resolutionTypes.firstWhere(
      (t) => t['MaHinhThucXuLy'] == hinhThucId,
      orElse: () => null,
    );
    if (type == null) return false;
    final name = (type['TenHinhThuc'] ?? '').toString().toLowerCase();
    return name.contains('hoàn tiền') || name.contains('đền bù') || name.contains('refund');
  }

  Color _getComplaintStatusColor(int status) {
    if (status == 0) return Colors.orange;
    if (status == 1) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: orangeColor));
          }
          return RefreshIndicator(
            onRefresh: _viewModel.loadComplaints,
            color: orangeColor,
            child: _viewModel.complaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Không có khiếu nại nào cần giải quyết', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viewModel.complaints.length,
                    itemBuilder: (context, index) {
                      final comp = _viewModel.complaints[index];
                      final int id = comp['MaKhieuNai'] ?? 0;
                      final String title = comp['TieuDe'] ?? '';
                      final String content = comp['NoiDung'] ?? '';
                      final int status = comp['TrangThaiXuLy'] ?? 0; // 0: Pending, 1: Processing, 2: Resolved
                      
                      final String clientName = comp['NguoiGui']?['HoTenNguoiDung'] ?? 'Khách hàng';
                      final String providerName = comp['NguoiBiKhieuNai']?['HoTenNguoiDung'] ?? 'Nhân viên';
                      
                      final shift = comp['CaLamViec'] ?? {};
                      final double shiftTotal = double.tryParse(shift['TongTien']?.toString() ?? '0') ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: orangeColor),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getComplaintStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getComplaintStatusText(status),
                                      style: TextStyle(
                                        color: _getComplaintStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                content,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 6),
                              Text('Người khiếu nại: $clientName', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              Text('Nhân viên bị khiếu nại: $providerName', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              Text('Số tiền ca làm: ${shiftTotal.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              
                              if (comp['HinhThucXuLy'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Hình thức đã xử lý: ${comp['HinhThucXuLy']['TenHinhThuc']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],

                              if (status == 0) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _handleProcess(id),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                      child: const Text('TIẾP NHẬN XỬ LÝ'),
                                    ),
                                  ],
                                ),
                              ] else if (status == 1) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _showResolveDialog(id, shiftTotal),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text('GIẢI QUYẾT'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
