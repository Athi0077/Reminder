import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/config/env.dart';
import 'dart:async';

final socketServiceProvider = Provider<SocketService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocketService(apiClient);
});

class SocketService {
  final ApiClient _apiClient;
  IO.Socket? _socket;

  // Streams for various events
  final _friendRequestReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _friendRequestAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _newEventCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventStatusUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationReceivedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get friendRequestReceivedStream => _friendRequestReceivedController.stream;
  Stream<Map<String, dynamic>> get friendRequestAcceptedStream => _friendRequestAcceptedController.stream;
  Stream<Map<String, dynamic>> get newEventCreatedStream => _newEventCreatedController.stream;
  Stream<Map<String, dynamic>> get eventStatusUpdatedStream => _eventStatusUpdatedController.stream;
  Stream<Map<String, dynamic>> get eventUpdatedStream => _eventUpdatedController.stream;
  Stream<Map<String, dynamic>> get notificationReceivedStream => _notificationReceivedController.stream;

  SocketService(this._apiClient);

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _apiClient.getToken();
    if (token == null) return;

    // Remove /api from the baseUrl if present
    String socketUrl = Env.apiBaseUrl;
    if (socketUrl.endsWith('/api')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    }

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setAuth({'token': token})
      .build()
    );

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((err) {
      print('Socket connect error: $err');
    });

    // Listen to events
    _socket!.on('friend_request_received', (data) {
      if (data != null) {
        _friendRequestReceivedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('friend_request_accepted', (data) {
      if (data != null) {
        _friendRequestAcceptedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('new_event_created', (data) {
      if (data != null) {
        _newEventCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('event_status_updated', (data) {
      if (data != null) {
        _eventStatusUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('event_updated', (data) {
      if (data != null) {
        _eventUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('notification_received', (data) {
      if (data != null) {
        _notificationReceivedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void dispose() {
    disconnect();
    _friendRequestReceivedController.close();
    _friendRequestAcceptedController.close();
    _newEventCreatedController.close();
    _eventStatusUpdatedController.close();
    _eventUpdatedController.close();
    _notificationReceivedController.close();
  }
}
