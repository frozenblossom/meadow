/*import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

enum WebSocketConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class WebSocketMessage {
  final String type;
  final dynamic data;
  final String? channel;
  final String? token;

  WebSocketMessage({
    required this.type,
    this.data,
    this.channel,
    this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (data != null) 'data': data,
      if (channel != null) 'channel': channel,
      if (token != null) 'token': token,
    };
  }

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'],
      channel: json['channel'],
      token: json['token'],
    );
  }
}

class WebSocketService extends GetxService {
  static const String _wsUrl = 'ws://localhost:3001/ws';
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  int _reconnectAttempts = 0;
  bool _isManualDisconnect = false;
  String? _authToken;

  // Reactive state
  final connectionState = WebSocketConnectionState.disconnected.obs;
  final isAuthenticated = false.obs;

  // Event streams
  final _taskUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _creditUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get taskUpdates => _taskUpdateController.stream;
  Stream<Map<String, dynamic>> get creditUpdates =>
      _creditUpdateController.stream;
  Stream<WebSocketMessage> get messages => _messageController.stream;

  @override
  void onInit() {
    super.onInit();
    _loadAuthToken();
  }

  @override
  void onClose() {
    disconnect();
    _taskUpdateController.close();
    _creditUpdateController.close();
    _messageController.close();
    super.onClose();
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (_authToken != null) {
        connect();
      }
    } catch (e) {
      print('Error loading auth token: $e');
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      connect();
    } else {
      disconnect();
    }
  }

  void connect() {
    if (_authToken == null) {
      print('Cannot connect: No auth token available');
      return;
    }

    if (_channel != null) {
      print('WebSocket already connected or connecting');
      return;
    }

    _isManualDisconnect = false;
    _reconnectAttempts = 0;
    _connectInternal();
  }

  void _connectInternal() {
    connectionState.value = WebSocketConnectionState.connecting;

    try {
      print('Connecting to WebSocket: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Listen to connection stream
      _channel!.stream.listen(
        _onMessage,
        onDone: _onConnectionClosed,
        onError: _onConnectionError,
      );

      // Send authentication after connection
      _authenticateConnection();

      connectionState.value = WebSocketConnectionState.connected;
      _reconnectAttempts = 0;

      // Start ping timer to keep connection alive
      _startPingTimer();

      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection error: $e');
      connectionState.value = WebSocketConnectionState.error;
      _scheduleReconnect();
    }
  }

  void _authenticateConnection() {
    if (_authToken == null) return;

    final authMessage = WebSocketMessage(
      type: 'auth',
      data: {'token': _authToken},
    );

    _sendMessage(authMessage);
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final wsMessage = WebSocketMessage.fromJson(data);

      print('WebSocket message received: ${wsMessage.type}');

      // Handle specific message types
      switch (wsMessage.type) {
        case 'authenticated':
          isAuthenticated.value = true;
          print(
            'WebSocket authenticated for user: ${wsMessage.data?['userId']}',
          );
          break;

        case 'task_created':
        case 'task_updated':
        case 'task_deleted':
          _taskUpdateController.add({
            'action': wsMessage.type.replaceFirst('task_', ''),
            'task': wsMessage.data,
          });
          break;

        case 'credits_updated':
          _creditUpdateController.add({
            'action': 'balance_updated',
            'credits': wsMessage.data,
          });
          break;

        case 'credits_transaction':
          _creditUpdateController.add({
            'action': 'transaction_added',
            'transaction': wsMessage.data,
          });
          break;

        case 'error':
          print('WebSocket error: ${wsMessage.data}');
          if (wsMessage.data == 'Authentication failed') {
            isAuthenticated.value = false;
          }
          break;

        case 'subscribed':
          print('Subscribed to channel: ${wsMessage.channel}');
          break;

        case 'unsubscribed':
          print('Unsubscribed from channel: ${wsMessage.channel}');
          break;
      }

      // Emit to general message stream
      _messageController.add(wsMessage);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _onConnectionClosed() {
    print('WebSocket connection closed');
    connectionState.value = WebSocketConnectionState.disconnected;
    isAuthenticated.value = false;
    _channel = null;
    _stopPingTimer();

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _onConnectionError(error) {
    print('WebSocket connection error: $error');
    connectionState.value = WebSocketConnectionState.error;
    isAuthenticated.value = false;
    _channel = null;
    _stopPingTimer();

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManualDisconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached or manual disconnect');
      return;
    }

    _reconnectAttempts++;
    connectionState.value = WebSocketConnectionState.reconnecting;

    print(
      'Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s',
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isManualDisconnect) {
        _connectInternal();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (connectionState.value == WebSocketConnectionState.connected) {
        _sendMessage(WebSocketMessage(type: 'ping'));
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void disconnect() {
    print('Manually disconnecting WebSocket');
    _isManualDisconnect = true;
    isAuthenticated.value = false;
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _channel?.sink.close();
    _channel = null;
    connectionState.value = WebSocketConnectionState.disconnected;
  }

  void _sendMessage(WebSocketMessage message) {
    if (_channel == null) {
      print('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      final jsonString = jsonEncode(message.toJson());
      _channel!.sink.add(jsonString);
      print('WebSocket message sent: ${message.type}');
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }

  void subscribe(String channel) {
    if (!isAuthenticated.value) {
      print('Cannot subscribe: Not authenticated');
      return;
    }

    _sendMessage(
      WebSocketMessage(
        type: 'subscribe',
        channel: channel,
      ),
    );
  }

  void unsubscribe(String channel) {
    if (!isAuthenticated.value) {
      print('Cannot unsubscribe: Not authenticated');
      return;
    }

    _sendMessage(
      WebSocketMessage(
        type: 'unsubscribe',
        channel: channel,
      ),
    );
  }

  // Convenience methods for UI
  bool get isConnected =>
      connectionState.value == WebSocketConnectionState.connected &&
      isAuthenticated.value;
  bool get isConnecting =>
      connectionState.value == WebSocketConnectionState.connecting;
  bool get isReconnecting =>
      connectionState.value == WebSocketConnectionState.reconnecting;
  bool get hasError => connectionState.value == WebSocketConnectionState.error;

  String get connectionStatusText {
    switch (connectionState.value) {
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.connected:
        return isAuthenticated.value ? 'Connected' : 'Authenticating...';
      case WebSocketConnectionState.disconnected:
        return 'Disconnected';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting... ($_reconnectAttempts/$_maxReconnectAttempts)';
      case WebSocketConnectionState.error:
        return 'Connection Error';
    }
  }
}
*/
