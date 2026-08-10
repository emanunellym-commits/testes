import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_client.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? socket;
  Future<io.Socket>? _connecting;

  Future<io.Socket> connect() async {
    if (socket?.connected == true) return socket!;
    if (_connecting != null) return _connecting!;

    _connecting = _doConnect();
    try {
      return await _connecting!;
    } finally {
      _connecting = null;
    }
  }

  Future<io.Socket> _doConnect() async {
    final token = await ApiClient.instance.token();
    final s = io.io(
      '${ApiClient.baseUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );
    socket = s;
    s.connect();
    return s;
  }

  void join(String conversationId) {
    socket?.emit('join', {'conversationId': conversationId});
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
