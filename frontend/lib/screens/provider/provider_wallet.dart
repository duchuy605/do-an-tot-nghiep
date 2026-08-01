import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_formatter.dart';
import '../../viewmodels/provider/provider_wallet_viewmodel.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => ProviderWalletScreenState();
}

class ProviderWalletScreenState extends State<ProviderWalletScreen> {
  final ProviderWalletViewModel _viewModel = ProviderWalletViewModel();
  final _withdrawAmountController = TextEditingController();

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
    _withdrawAmountController.dispose();
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

  Future<void> _handleWithdraw() async {
    final amountText = _withdrawAmountController.text.trim();
    if (amountText.isEmpty) return;
    // Loại bỏ dấu chấm hoặc phẩy phân cách hàng nghìn trước khi parse
    final rawAmount = amountText.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(rawAmount);
    if (amount == null || amount < 100000) {
      _showMessageBox('Số tiền rút tối thiểu mỗi lần là 100.000 VNĐ.');
      return;
    }

    if (amount > 10000000) {
      _showMessageBox('Số tiền rút tối đa mỗi lần là 10.000.000 VNĐ.');
      return;
    }

    if (amount > _viewModel.balance) {
      _showMessageBox('Số dư ví không đủ để rút.');
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    final response = await _viewModel.withdrawWallet(amount);

    if (!mounted) return;

    if (response['success'] == true) {
      _withdrawAmountController.clear();
      _showMessageBox('Rút tiền từ ví thành công!', isSuccess: true);
      _viewModel.loadWalletData();
    } else {
      _showMessageBox(response['message'] ?? 'Rút tiền thất bại.');
    }
  }

  void _showWithdrawBottomSheet() {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    _withdrawAmountController.clear();

    final balanceFormatted = NumberFormat('#,###').format(_viewModel.balance);

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
                'Rút Tiền Từ Ví',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Số dư hiện tại: $balanceFormatted đ',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Quick amount selector chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [100000, 200000, 500000, 1000000].map((amt) {
                  final label = amt >= 1000000
                      ? '${(amt / 1000000).toStringAsFixed(0)}tr đ'
                      : '${(amt / 1000).toStringAsFixed(0)}k đ';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _withdrawAmountController.text.replaceAll(RegExp(r'[^0-9]'), '') == amt.toString(),
                    selectedColor: orangeColor.withOpacity(0.15),
                    checkmarkColor: orangeColor,
                    labelStyle: TextStyle(
                      color: _withdrawAmountController.text.replaceAll(RegExp(r'[^0-9]'), '') == amt.toString() ? orangeColor : darkColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setSheetState(() {
                        if (selected) {
                          _withdrawAmountController.text = NumberFormat('#,###', 'vi_VN').format(amt);
                        } else {
                          _withdrawAmountController.clear();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _withdrawAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyTextInputFormatter()],
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Số tiền muốn rút (đ)',
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
                onPressed: _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('XÁC NHẬN RÚT TIỀN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
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
        return 'Thu nhập ca làm việc';
      case 6:
        return 'Rút tiền ví';
      case 7:
        return 'Trừ tiền phạt';
      default:
        return 'Giao dịch ví';
    }
  }

  Color _getTransactionColor(int type) {
    if (type == 4 || type == 1 || type == 3) {
      return Colors.green;
    }
    // type 2 (thanh toán), type 6 (rút tiền), type 7 (phạt) = red
    return Colors.red;
  }

  String _formatAmount(double amt, int type) {
    final String formatted = NumberFormat('#,###', 'vi_VN').format(amt.toInt());
    if (type == 4 || type == 1 || type == 3) {
      return '+$formatted đ';
    }
    // type 2, 6 = outgoing
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
        title: const Text('Ví Thu Nhập', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        // ATM Card Styled Panel
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [orangeColor, Color(0xFFFF9E59)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: orangeColor.withOpacity(0.3),
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
                                    'bTaskee Helper Card',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  Icon(Icons.nfc_rounded, color: Colors.white.withOpacity(0.8), size: 28),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'TỔNG THU NHẬP HIỆN TẠI',
                                style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2),
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
                                    'Lương giải ngân tự động sau ca dọn',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showWithdrawBottomSheet,
                                    icon: const Icon(Icons.account_balance_outlined, size: 16),
                                    label: const Text('Rút tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: orangeColor,
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
                                'Lịch Sử Giao Dịch Ví',
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
                                      const Text('Chưa có phát sinh giao dịch nào.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
                                    final int type = tx['LoaiGiaoDich'] ?? 4;
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
