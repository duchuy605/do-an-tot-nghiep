import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_formatter.dart';
import '../../viewmodels/customer/customer_wallet_viewmodel.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => CustomerWalletScreenState();
}

class CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final CustomerWalletViewModel _viewModel = CustomerWalletViewModel();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadWalletData();
  }

  void reloadData() {
    _viewModel.loadWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showMessageBox(String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(isSuccess ? 'Thành công' : 'Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTopUp() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final rawAmount = amountText.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(rawAmount);

    if (amount == null || amount < 100000) {
      _showMessageBox('Số tiền nạp tối thiểu mỗi lần là 100.000 VNĐ.');
      return;
    }

    if (amount > 10000000) {
      _showMessageBox('Số tiền nạp tối đa mỗi lần là 10.000.000 VNĐ.');
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    final response = await _viewModel.topUpWallet(amount);

    if (!mounted) return;

    if (response['success'] == true) {
      _amountController.clear();
      _showMessageBox('Nạp tiền vào ví thành công!', isSuccess: true);
      _viewModel.loadWalletData();
    } else {
      _showMessageBox(response['message'] ?? 'Nạp tiền thất bại.');
    }
  }

  void _showTopUpBottomSheet() {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    _amountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nạp Tiền Vào Ví bPay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Quick amount selector chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [100000, 200000, 500000, 1000000].map((amt) {
                  final label = '${(amt / 1000).toStringAsFixed(0)}k đ';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _amountController.text.replaceAll(RegExp(r'[^0-9]'), '') == amt.toString(),
                    selectedColor: orangeColor.withOpacity(0.15),
                    checkmarkColor: orangeColor,
                    labelStyle: TextStyle(
                      color: _amountController.text.replaceAll(RegExp(r'[^0-9]'), '') == amt.toString() ? orangeColor : darkColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setSheetState(() {
                        if (selected) {
                          _amountController.text = NumberFormat('#,###', 'vi_VN').format(amt);
                        } else {
                          _amountController.clear();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Số tiền muốn nạp (đ)',
                  hintText: 'Ví dụ: 200.000',
                  prefixIcon: const Icon(Icons.monetization_on_outlined, color: orangeColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: orangeColor, width: 1.5)),
                ),
                onChanged: (val) {
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('NẠP TIỀN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getTransactionTypeLabel(int type) {
    switch (type) {
      case 1:
        return 'Nạp tiền ví';
      case 2:
        return 'Thanh toán lịch dọn';
      case 3:
        return 'Hoàn tiền khiếu nại';
      case 4:
        return 'Thu nhập ca làm';
      default:
        return 'Giao dịch khác';
    }
  }

  Color _getTransactionColor(int type) {
    if (type == 1 || type == 3 || type == 4) {
      return Colors.green;
    }
    return Colors.red;
  }

  String _formatAmount(double amt, int type) {
    final String formatted = NumberFormat('#,###', 'vi_VN').format(amt.toInt());
    if (type == 1 || type == 3 || type == 4) {
      return '+$formatted đ';
    }
    return '-$formatted đ';
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Ví Tiền bPay', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : RefreshIndicator(
                  onRefresh: _viewModel.loadWalletData,
                  color: orangeColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // ATM Card styled balance panel
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [darkColor, Color(0xFF33333F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: darkColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'bPay Wallet',
                                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  Icon(Icons.nfc_rounded, color: orangeColor.withOpacity(0.8), size: 28),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'SỐ DƯ KHẢ DỤNG',
                                style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${NumberFormat('#,###', 'vi_VN').format(_viewModel.balance.toInt())} đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '**** **** **** 8888',
                                    style: TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 1.5),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showTopUpBottomSheet,
                                    icon: const Icon(Icons.add_card_rounded, size: 16),
                                    label: const Text('NẠP TIỀN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orangeColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Transactions history feed
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lịch Sử Giao Dịch',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
                              ),
                              const SizedBox(height: 16),
                              if (_viewModel.history.isEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 40),
                                      Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      const Text('Chưa có phát sinh giao dịch ví.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _viewModel.history.length,
                                  itemBuilder: (context, index) {
                                    final tx = _viewModel.history[index];
                                    final int type = tx['LoaiGiaoDich'] ?? 1;
                                    final double money = double.tryParse(tx['SoTien']?.toString() ?? '0') ?? 0;
                                    final String date = tx['NgayTao'] != null ? tx['NgayTao'].substring(0, 16).replaceAll('T', ' ') : '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getTransactionTypeLabel(type),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkColor),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                date,
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _formatAmount(money, type),
                                            style: TextStyle(
                                              color: _getTransactionColor(type),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
