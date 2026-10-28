import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

class SocketService {
  static io.Socket? _socket;

  static void init() {
    if (_socket != null && _socket!.connected) return;

    final token = StorageService.getToken();

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print('[Socket] Connected successfully to TELOS real-time server');
    });

    _socket?.onDisconnect((_) {
      print('[Socket] Disconnected from server');
    });
  }

  static void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  static void leaveRoom(String roomId) {
    _socket?.emit('leave_room', roomId);
  }

  static void sendMessage(Map<String, dynamic> data) {
    _socket?.emit('send_message', data);
  }

  static void onReceiveMessage(Function(dynamic) callback) {
    _socket?.on('receive_message', callback);
  }

  static void onTaskUpdated(Function(dynamic) callback) {
    _socket?.on('task_status_changed', callback);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
