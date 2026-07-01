import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class CustomerNotificationsViewModel extends ChangeNotifier {
  List _notifications = [];
  bool _isLoading = true;

  List get notifications => _notifications;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getNotifications();
      if (response['success'] == true) {
        List allNotifs = response['data'] ?? [];

        // Lọc thông báo theo vai trò
        final userRole = await ApiService.getUserRole();
        if (userRole == 2) {
          // Nhân viên: chỉ hiện thông báo đơn mới cần nhận
          allNotifs = allNotifs.where((n) {
            final title = (n['TieuDe'] ?? '').toString().toLowerCase();
            final body = (n['NoiDung'] ?? '').toString().toLowerCase();
            // Hiện: thông báo đơn mới, đơn đặt lịch
            // Ẩn: thanh toán, hoàn thành, nạp tiền, rút tiền
            final isRelevant = title.contains('đơn đặt lịch') ||
                title.contains('cần nhận') ||
                title.contains('việc mới') ||
                body.contains('đơn đặt lịch') ||
                body.contains('cần nhận');
            return isRelevant;
          }).toList();
        }

        _notifications = allNotifs;
      }
    } catch (_) {
      // Ignored for offline support
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId, int index) async {
    try {
      final response = await ApiService.markNotificationAsRead(notificationId);
      if (response['success'] == true) {
        if (index < _notifications.length) {
          _notifications[index]['TrangThaiThongBao'] = true;
          notifyListeners();
        }
      }
    } catch (_) {}
  }
}
