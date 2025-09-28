import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';

enum ComfyUIBinaryEventType {
  previewImage(1),
  unencodedPreviewImage(2),
  previewImageWithMetadata(3),
  text(4);

  const ComfyUIBinaryEventType(this.value);
  final int value;

  static ComfyUIBinaryEventType? fromValue(int value) {
    for (final type in ComfyUIBinaryEventType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class ComfyUIWebSocketMessage {
  final String type;
  final dynamic data;

  ComfyUIWebSocketMessage({
    required this.type,
    required this.data,
  });

  factory ComfyUIWebSocketMessage.fromJson(Map<String, dynamic> json) {
    return ComfyUIWebSocketMessage(
      type: json['type'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
}

class ComfyUIProgressData {
  final String? node;
  final Map<String, dynamic>? progress;
  final String? text;

  ComfyUIProgressData({
    this.node,
    this.progress,
    this.text,
  });

  factory ComfyUIProgressData.fromJson(Map<String, dynamic> json) {
    return ComfyUIProgressData(
      node: json['node'],
      progress: json['progress'],
      text: json['text'],
    );
  }

  double? get progressValue {
    if (progress == null) return null;
    final value = progress!['value'];
    final max = progress!['max'];
    if (value == null || max == null) return null;
    return (value as num) / (max as num);
  }

  String get progressText {
    if (progress == null) return '';
    final value = progress!['value'];
    final max = progress!['max'];
    if (value == null || max == null) return '';
    return '$value/$max';
  }
}

class ComfyUIExecutionData {
  final String? node;
  final String? promptId;

  ComfyUIExecutionData({
    this.node,
    this.promptId,
  });

  factory ComfyUIExecutionData.fromJson(Map<String, dynamic> json) {
    return ComfyUIExecutionData(
      node: json['node'],
      promptId: json['prompt_id'],
    );
  }
}

class ComfyUIStatusData {
  final Map<String, dynamic> status;
  final String? sid;

  ComfyUIStatusData({
    required this.status,
    this.sid,
  });

  factory ComfyUIStatusData.fromJson(Map<String, dynamic> json) {
    return ComfyUIStatusData(
      status: json['status'] ?? {},
      sid: json['sid'],
    );
  }

  int get queueRemaining {
    final execInfo = status['exec_info'];
    if (execInfo == null) return 0;
    return execInfo['queue_remaining'] ?? 0;
  }
}

class ComfyUIPreviewImage {
  final String format; // 'PNG' or 'JPEG'
  final Uint8List data;
  final Map<String, dynamic>? metadata;

  ComfyUIPreviewImage({
    required this.format,
    required this.data,
    this.metadata,
  });
}

class ComfyUIProgressText {
  final String nodeId;
  final String text;

  ComfyUIProgressText({
    required this.nodeId,
    required this.text,
  });
}

class ComfyUIWebSocketService extends GetxService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  String _host = '127.0.0.1';
  int _port = 8188;
  String? _clientId;

  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 5);

  // Reactive streams for different event types
  final Rx<bool> isConnected = false.obs;
  final RxString connectionStatus = 'disconnected'.obs;
  final Rx<ComfyUIStatusData?> status = Rx<ComfyUIStatusData?>(null);
  final Rx<ComfyUIProgressData?> progress = Rx<ComfyUIProgressData?>(null);
  final Rx<ComfyUIExecutionData?> execution = Rx<ComfyUIExecutionData?>(null);
  final Rx<ComfyUIPreviewImage?> previewImage = Rx<ComfyUIPreviewImage?>(null);
  final Rx<ComfyUIProgressText?> progressText = Rx<ComfyUIProgressText?>(null);

  // Stream controllers for custom event handling
  final StreamController<ComfyUIWebSocketMessage> _messageController =
      StreamController<ComfyUIWebSocketMessage>.broadcast();
  final StreamController<ComfyUIPreviewImage> _previewController =
      StreamController<ComfyUIPreviewImage>.broadcast();
  final StreamController<ComfyUIProgressData> _progressController =
      StreamController<ComfyUIProgressData>.broadcast();
  final StreamController<ComfyUIExecutionData> _executionController =
      StreamController<ComfyUIExecutionData>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Public streams
  Stream<ComfyUIWebSocketMessage> get messageStream =>
      _messageController.stream;
  Stream<ComfyUIPreviewImage> get previewStream => _previewController.stream;
  Stream<ComfyUIProgressData> get progressStream => _progressController.stream;
  Stream<ComfyUIExecutionData> get executionStream =>
      _executionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get connected => _isConnected;
  String? get clientId => _clientId;

  @override
  void onInit() {
    super.onInit();
    _clientId = _generateClientId();
  }

  @override
  void onClose() {
    disconnect();
    _messageController.close();
    _previewController.close();
    _progressController.close();
    _executionController.close();
    _errorController.close();
    super.onClose();
  }

  /// Update connection settings
  void updateConnection(String host, int port) {
    _host = host;
    _port = port;
  }

  /// Connect to ComfyUI WebSocket server
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      return;
    }

    _isConnecting = true;
    connectionStatus.value = 'connecting';

    try {
      final uri = Uri.parse('ws://$_host:$_port/ws?clientId=$_clientId');

      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      isConnected.value = true;
      connectionStatus.value = 'connected';

      // Start listening to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Send feature flags
      _sendFeatureFlags();
    } catch (e) {
      _isConnecting = false;
      connectionStatus.value = 'error';
      _handleError(e);
    }
  }

  /// Disconnect from ComfyUI WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = _maxReconnectAttempts; // Prevent auto-reconnection

    isConnected.value = false;
    connectionStatus.value = 'disconnected';
  }

  /// Send feature flags to server
  void _sendFeatureFlags() {
    final featureFlags = {
      'type': 'feature_flags',
      'data': {
        'supports_binary_preview': true,
        'supports_progress_text': true,
      },
    };

    send(featureFlags);
  }

  /// Send a message to the server
  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        _errorController.add('Failed to send message: $e');
      }
    } else {
      _errorController.add('Cannot send message: WebSocket not connected');
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        // Handle JSON messages
        final data = jsonDecode(message);
        final wsMessage = ComfyUIWebSocketMessage.fromJson(data);
        _handleJSONMessage(wsMessage);
      } else if (message is List<int>) {
        // Handle binary messages
        final bytes = Uint8List.fromList(message);
        _handleBinaryMessage(bytes);
      }
    } catch (e) {
      _errorController.add('Error handling message: $e');
    }
  }

  /// Handle JSON messages
  void _handleJSONMessage(ComfyUIWebSocketMessage message) {
    // Emit to message stream
    _messageController.add(message);

    // Handle specific message types
    switch (message.type) {
      case 'status':
        final statusData = ComfyUIStatusData.fromJson(message.data);
        status.value = statusData;
        break;

      case 'progress':
        final progressData = ComfyUIProgressData.fromJson(message.data);
        progress.value = progressData;
        _progressController.add(progressData);
        break;

      case 'executing':
        final executionData = ComfyUIExecutionData.fromJson(message.data);
        execution.value = executionData;
        _executionController.add(executionData);
        break;

      case 'progress_state':
        // Handle detailed progress state with node-by-node progress
        _handleProgressState(message.data);
        break;

      case 'executed':
        // Handle execution completion
        break;

      case 'execution_start':
        break;

      case 'execution_success':
        break;

      case 'execution_error':
        _errorController.add('Execution error: ${message.data}');
        break;

      case 'feature_flags':
        break;

      default:
    }
  }

  /// Handle binary messages
  void _handleBinaryMessage(Uint8List data) {
    if (data.length < 4) {
      return;
    }

    // Read the event type (first 4 bytes, big-endian)
    final eventTypeBytes = data.sublist(0, 4);
    final eventType =
        (eventTypeBytes[0] << 24) |
        (eventTypeBytes[1] << 16) |
        (eventTypeBytes[2] << 8) |
        eventTypeBytes[3];

    final payload = data.sublist(4);
    final binaryEventType = ComfyUIBinaryEventType.fromValue(eventType);

    switch (binaryEventType) {
      case ComfyUIBinaryEventType.previewImage:
        _handlePreviewImage(payload);
        break;

      case ComfyUIBinaryEventType.previewImageWithMetadata:
        _handlePreviewImageWithMetadata(payload);
        break;

      case ComfyUIBinaryEventType.text:
        _handleProgressTextBinary(payload);
        break;

      default:
    }
  }

  /// Handle progress state messages with detailed node information
  void _handleProgressState(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final promptId = data['prompt_id'] as String?;
    final nodes = data['nodes'] as Map<String, dynamic>?;

    if (promptId == null || nodes == null) return;

    // Find the currently running node with progress
    String? currentRunningNode;
    double? overallProgress;
    int currentStep = 0;
    int totalSteps = 0;
    bool isFinished = true;

    for (final entry in nodes.entries) {
      final nodeId = entry.key;
      final nodeData = entry.value as Map<String, dynamic>;

      final state = nodeData['state'] as String?;
      final value = nodeData['value'];
      final max = nodeData['max'];

      if (state == 'running') {
        currentRunningNode = nodeId;
        isFinished = false;

        // Calculate progress for this node
        if (value != null && max != null) {
          final nodeProgress = (value as num) / (max as num);
          overallProgress = nodeProgress;
          currentStep = value.toInt();
          totalSteps = max.toInt();
        }
      } else if (state == 'finished') {
        // Count finished nodes for overall progress calculation
        if (value != null) {
          totalSteps += (value as num).toInt();
        }
      }
    }

    // If all nodes are finished, set progress to 100%
    if (isFinished) {
      overallProgress = 1.0;
    }

    // Create progress data and emit
    final progressData = ComfyUIProgressData(
      node: currentRunningNode,
      progress: overallProgress != null
          ? {
              'value': currentStep,
              'max': totalSteps,
            }
          : null,
      text: currentRunningNode != null
          ? 'Executing node: $currentRunningNode'
          : (isFinished ? 'Execution completed' : 'Processing...'),
    );

    progress.value = progressData;
    _progressController.add(progressData);
  }

  /// Handle preview image binary data
  void _handlePreviewImage(Uint8List data) {
    if (data.length < 4) return;

    // Read image type (first 4 bytes)
    final imageTypeBytes = data.sublist(0, 4);
    final imageType =
        (imageTypeBytes[0] << 24) |
        (imageTypeBytes[1] << 16) |
        (imageTypeBytes[2] << 8) |
        imageTypeBytes[3];

    final imageData = data.sublist(4);
    final format = imageType == 1 ? 'JPEG' : 'PNG';

    final preview = ComfyUIPreviewImage(
      format: format,
      data: imageData,
    );

    previewImage.value = preview;
    _previewController.add(preview);
  }

  /// Handle preview image with metadata
  void _handlePreviewImageWithMetadata(Uint8List data) {
    if (data.length < 4) return;

    // Read metadata length (first 4 bytes)
    final metadataLengthBytes = data.sublist(0, 4);
    final metadataLength =
        (metadataLengthBytes[0] << 24) |
        (metadataLengthBytes[1] << 16) |
        (metadataLengthBytes[2] << 8) |
        metadataLengthBytes[3];

    if (data.length < 4 + metadataLength) return;

    // Extract metadata
    final metadataBytes = data.sublist(4, 4 + metadataLength);
    final imageData = data.sublist(4 + metadataLength);

    try {
      final metadataJson = utf8.decode(metadataBytes);
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      final format = metadata['image_type'] == 'image/jpeg' ? 'JPEG' : 'PNG';

      final preview = ComfyUIPreviewImage(
        format: format,
        data: imageData,
        metadata: metadata,
      );

      previewImage.value = preview;
      _previewController.add(preview);
    } catch (e) {
      //
    }
  }

  /// Handle progress text binary data
  void _handleProgressTextBinary(Uint8List data) {
    if (data.length < 4) return;

    // Read node ID length (first 4 bytes)
    final nodeIdLengthBytes = data.sublist(0, 4);
    final nodeIdLength =
        (nodeIdLengthBytes[0] << 24) |
        (nodeIdLengthBytes[1] << 16) |
        (nodeIdLengthBytes[2] << 8) |
        nodeIdLengthBytes[3];

    if (data.length < 4 + nodeIdLength) return;

    final nodeIdBytes = data.sublist(4, 4 + nodeIdLength);
    final textBytes = data.sublist(4 + nodeIdLength);

    try {
      final nodeId = utf8.decode(nodeIdBytes);
      final text = utf8.decode(textBytes);

      final progressTextData = ComfyUIProgressText(
        nodeId: nodeId,
        text: text,
      );

      progressText.value = progressTextData;
    } catch (e) {
      //
    }
  }

  /// Handle connection errors
  void _handleError(dynamic error) {
    _errorController.add('Connection error: $error');

    _isConnected = false;
    _isConnecting = false;
    isConnected.value = false;
    connectionStatus.value = 'error';

    // Attempt to reconnect
    _attemptReconnect();
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    isConnected.value = false;
    connectionStatus.value = 'disconnected';

    // Attempt to reconnect
    _attemptReconnect();
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      connectionStatus.value = 'failed';
      return;
    }

    _reconnectAttempts++;
    connectionStatus.value = 'reconnecting';

    _reconnectTimer = Timer(_reconnectInterval, () {
      connect();
    });
  }

  /// Generate a unique client ID
  String _generateClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${timestamp}_$random';
  }

  /// Get current connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'host': _host,
      'port': _port,
      'client_id': _clientId,
      'connected': _isConnected,
      'connecting': _isConnecting,
      'reconnect_attempts': _reconnectAttempts,
      'status': connectionStatus.value,
    };
  }

  /// Reset reconnection attempts (useful when manually reconnecting)
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
  }
}
