import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import '../widgets/top_banner_notification.dart';

class SocketService {
  // Biến dùng chung để lưu GlobalKey
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Biến singleton
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  int? _userId;

  /// Khởi tạo kết nối Socket tới Backend
  Future<void> initSocket() async {
    // Nếu đã có kết nối, ngắt nó trước khi tạo mới
    if (_socket != null) {
      _socket!.disconnect();
    }

    // Lấy thông tin người dùng từ Local Storage
    final String? token = await ApiService.getToken();
    final int? vaiTro = await ApiService.getUserRole();
    _userId = await ApiService.getUserId();

    if (token == null || _userId == null) {
      return; // Không đăng nhập thì không khởi tạo
    }

    // Bóc tách hostname từ baseUrl (bỏ /api)
    final String socketUrl = ApiService.baseUrl.replaceAll('/api', '');

    // Khởi tạo Socket.IO Client
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('Socket Connected: ${_socket!.id}');
      
      // Emit sự kiện register để Backend biết user này là ai
      _socket!.emit('register', {
        'MaNguoiDung': _userId,
        'VaiTro': vaiTro,
      });
    });

    // Lắng nghe các sự kiện thông báo từ server
    _socket!.on('thong_bao', _handleIncomingNotification);
    _socket!.on('thong_bao_he_thong', _handleIncomingNotification);
    _socket!.on('thong_bao_admin', _handleIncomingNotification);

    _socket!.on('connect_error', (error) => print('Socket connect_error: $error'));
    _socket!.on('connect_timeout', (_) => print('Socket connect_timeout'));
    _socket!.on('reconnect_attempt', (attempt) => print('Socket reconnect_attempt: $attempt'));
    _socket!.on('reconnect', (attempt) => print('Socket reconnected after $attempt attempts'));
    _socket!.on('error', (error) => print('Socket error: $error'));

    _socket!.onDisconnect((_) {
      print('Socket Disconnected');
    });
  }

  void _handleIncomingNotification(dynamic data) {
    print('Nhận được thông báo mới: $data');
    if (data == null || data is! Map) return;

    final title = data['tieuDe'] ?? 'Thông báo';
    final body = data['noiDung'] ?? '';
    final context = navigatorKey.currentContext;
    if (context != null) {
      showTopBanner(context, title, body);
    }
  }

  /// Ngắt kết nối khi đăng xuất
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _userId = null;
  }
}
