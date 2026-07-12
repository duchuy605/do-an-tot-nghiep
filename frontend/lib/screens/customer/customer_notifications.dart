import 'package:flutter/material.dart';
import '../../viewmodels/customer/customer_notifications_viewmodel.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  final bool hideAppBar;
  const CustomerNotificationsScreen({super.key, this.hideAppBar = false});

  @override
  State<CustomerNotificationsScreen> createState() => CustomerNotificationsScreenState();
}

class CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final CustomerNotificationsViewModel _viewModel = CustomerNotificationsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadNotifications();
  }

  void reloadData() {
    _viewModel.loadNotifications();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFFF8225);
    const darkColor = Color(0xFF1E1E24);
    const bgColor = Color(0xFFF7F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Thông Báo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: darkColor),
            onPressed: _viewModel.loadNotifications,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: orangeColor))
              : RefreshIndicator(
                  onRefresh: _viewModel.loadNotifications,
                  color: orangeColor,
                  child: _viewModel.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'Bạn chưa nhận được thông báo nào.',
                                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _viewModel.notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _viewModel.notifications[index];
                            final bool isRead = notif['TrangThaiThongBao'] == true || notif['TrangThaiThongBao'] == 1 || notif['TrangThaiThongBao'] == 'true';
                            final int id = notif['MaThongBao'] ?? 0;
                            final String title = notif['TieuDe'] ?? 'Thông báo';
                            final String body = notif['NoiDung'] ?? '';
                            final String date = notif['NgayTao'] != null && notif['NgayTao'].toString().length >= 16
                                ? notif['NgayTao'].toString().substring(0, 16).replaceAll('T', ' ')
                                : notif['NgayTao']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFFFF9F5),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
                                border: Border.all(
                                  color: isRead ? Colors.transparent : orangeColor.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: CircleAvatar(
                                  backgroundColor: isRead ? const Color(0xFFF7F7FA) : const Color(0xFFFFF2E6),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: isRead ? Colors.grey : orangeColor,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                          fontSize: 14,
                                          color: darkColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      date.split(' ')[0],
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    body.replaceAll(RegExp(r'\s*\[ca:\d+\]'), ''),
                                    style: TextStyle(
                                      color: isRead ? Colors.black54 : Colors.black87,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: orangeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  // Đánh dấu đã đọc
                                  if (!isRead && id > 0) {
                                    _viewModel.markAsRead(id, index);
                                  }
                                  // Hiện chi tiết thông báo
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      content: Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Đóng'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
