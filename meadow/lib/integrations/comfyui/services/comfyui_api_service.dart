import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class ComfyUIPromptRequest {
  final Map<String, dynamic> prompt;
  final String? clientId;
  final String? promptId;
  final Map<String, dynamic>? extraData;
  final int? number;
  final bool? front;
  final List<String>? partialExecutionTargets;

  ComfyUIPromptRequest({
    required this.prompt,
    this.clientId,
    this.promptId,
    this.extraData,
    this.number,
    this.front,
    this.partialExecutionTargets,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'prompt': prompt,
    };

    if (clientId != null) data['client_id'] = clientId;
    if (promptId != null) data['prompt_id'] = promptId;
    if (extraData != null) data['extra_data'] = extraData;
    if (number != null) data['number'] = number;
    if (front != null) data['front'] = front;
    if (partialExecutionTargets != null) {
      data['partial_execution_targets'] = partialExecutionTargets;
    }

    return data;
  }
}

class ComfyUIPromptResponse {
  final String promptId;
  final int number;
  final Map<String, dynamic>? nodeErrors;

  ComfyUIPromptResponse({
    required this.promptId,
    required this.number,
    this.nodeErrors,
  });

  factory ComfyUIPromptResponse.fromJson(Map<String, dynamic> json) {
    return ComfyUIPromptResponse(
      promptId: json['prompt_id'],
      number: json['number'],
      nodeErrors: json['node_errors'],
    );
  }
}

class ComfyUIQueueInfo {
  final List<dynamic> queueRunning;
  final List<dynamic> queuePending;

  ComfyUIQueueInfo({
    required this.queueRunning,
    required this.queuePending,
  });

  factory ComfyUIQueueInfo.fromJson(Map<String, dynamic> json) {
    return ComfyUIQueueInfo(
      queueRunning: json['queue_running'] ?? [],
      queuePending: json['queue_pending'] ?? [],
    );
  }

  int get totalItems => queueRunning.length + queuePending.length;
  bool get isIdle => totalItems == 0;
}

class ComfyUISystemStats {
  final Map<String, dynamic> system;
  final List<Map<String, dynamic>> devices;

  ComfyUISystemStats({
    required this.system,
    required this.devices,
  });

  factory ComfyUISystemStats.fromJson(Map<String, dynamic> json) {
    return ComfyUISystemStats(
      system: json['system'] ?? {},
      devices: List<Map<String, dynamic>>.from(json['devices'] ?? []),
    );
  }

  String get os => system['os'] ?? 'Unknown';
  int get ramTotal => system['ram_total'] ?? 0;
  int get ramFree => system['ram_free'] ?? 0;
  String get comfyuiVersion => system['comfyui_version'] ?? 'Unknown';
  String get pythonVersion => system['python_version'] ?? 'Unknown';
  String get pytorchVersion => system['pytorch_version'] ?? 'Unknown';

  double get ramUsagePercent {
    if (ramTotal == 0) return 0.0;
    return ((ramTotal - ramFree) / ramTotal) * 100;
  }

  Map<String, dynamic>? get primaryDevice {
    return devices.isNotEmpty ? devices.first : null;
  }

  int get vramTotal => primaryDevice?['vram_total'] ?? 0;
  int get vramFree => primaryDevice?['vram_free'] ?? 0;
  String get deviceName => primaryDevice?['name'] ?? 'Unknown';

  double get vramUsagePercent {
    if (vramTotal == 0) return 0.0;
    return ((vramTotal - vramFree) / vramTotal) * 100;
  }
}

class ComfyUIUploadResponse {
  final String name;
  final String subfolder;
  final String type;

  ComfyUIUploadResponse({
    required this.name,
    required this.subfolder,
    required this.type,
  });

  factory ComfyUIUploadResponse.fromJson(Map<String, dynamic> json) {
    return ComfyUIUploadResponse(
      name: json['name'],
      subfolder: json['subfolder'],
      type: json['type'],
    );
  }
}

class ComfyUIAPIService extends GetxService {
  late dio.Dio _dio;
  String _baseUrl = 'http://127.0.0.1:8188';
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get baseUrl => _baseUrl;

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          _isConnected = false;
          handler.next(error);
        },
      ),
    );
  }

  /// Update the base URL for ComfyUI server
  void updateBaseUrl(String host, int port) {
    _baseUrl = 'http://$host:$port';
    _initializeDio();
  }

  /// Check if ComfyUI server is available
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/system_stats');
      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Submit a prompt for generation
  Future<ComfyUIPromptResponse> submitPrompt(
    ComfyUIPromptRequest request,
  ) async {
    try {
      final response = await _dio.post('/prompt', data: request.toJson());
      return ComfyUIPromptResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to submit prompt: $e');
    }
  }

  /// Get current queue information
  Future<ComfyUIQueueInfo> getQueue() async {
    try {
      final response = await _dio.get('/queue');
      return ComfyUIQueueInfo.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get queue: $e');
    }
  }

  /// Get detailed queue status
  Future<Map<String, dynamic>> getQueueStatus() async {
    try {
      final response = await _dio.get('/prompt');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get queue status: $e');
    }
  }

  /// Clear or delete items from queue
  Future<void> manageQueue({bool? clear, List<String>? delete}) async {
    try {
      final data = <String, dynamic>{};
      if (clear != null) data['clear'] = clear;
      if (delete != null) data['delete'] = delete;

      await _dio.post('/queue', data: data);
    } catch (e) {
      throw Exception('Failed to manage queue: $e');
    }
  }

  /// Interrupt current or specific execution
  Future<void> interrupt({String? promptId}) async {
    try {
      final data = promptId != null
          ? {'prompt_id': promptId}
          : <String, dynamic>{};
      await _dio.post('/interrupt', data: data);
    } catch (e) {
      throw Exception('Failed to interrupt: $e');
    }
  }

  /// Get execution history
  Future<Map<String, dynamic>> getHistory({
    int? maxItems,
    String? promptId,
  }) async {
    try {
      if (promptId != null) {
        final response = await _dio.get('/history/$promptId');
        return response.data;
      }

      final queryParams = maxItems != null ? {'max_items': maxItems} : null;
      final response = await _dio.get('/history', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw Exception('Failed to get history: $e');
    }
  }

  /// Clear or delete history items
  Future<void> manageHistory({bool? clear, List<String>? delete}) async {
    try {
      final data = <String, dynamic>{};
      if (clear != null) data['clear'] = clear;
      if (delete != null) data['delete'] = delete;

      await _dio.post('/history', data: data);
    } catch (e) {
      throw Exception('Failed to manage history: $e');
    }
  }

  /// Get available model types
  Future<List<String>> getModelTypes() async {
    try {
      final response = await _dio.get('/models');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get model types: $e');
    }
  }

  /// Get models in specific folder
  Future<List<String>> getModels(String folder) async {
    if (['custom_nodes', 'configs'].contains(folder)) {
      return [];
    }

    try {
      final response = await _dio.get('/models/$folder');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get models for $folder: $e');
    }
  }

  /// Get all models organized by type
  Future<Map<String, List<String>>> getAllModels() async {
    try {
      final modelTypes = await getModelTypes();
      final allModels = <String, List<String>>{};

      await Future.wait(
        modelTypes.map((type) async {
          try {
            allModels[type] = await getModels(type);
          } catch (e) {
            allModels[type] = [];
          }
        }),
      );

      return allModels;
    } catch (e) {
      throw Exception('Failed to get all models: $e');
    }
  }

  /// Get available embeddings
  Future<List<String>> getEmbeddings() async {
    try {
      final response = await _dio.get('/embeddings');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get embeddings: $e');
    }
  }

  /// Get safetensors metadata
  Future<Map<String, dynamic>> getModelMetadata(
    String folder,
    String filename,
  ) async {
    try {
      final response = await _dio.get(
        '/view_metadata/$folder',
        queryParameters: {'filename': filename},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get model metadata: $e');
    }
  }

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _dio.get('/system_stats');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get system stats: $e');
    }
  }

  /// Get node object information
  Future<Map<String, dynamic>> getObjectInfo({String? nodeClass}) async {
    try {
      final endpoint = nodeClass != null
          ? '/object_info/$nodeClass'
          : '/object_info';
      final response = await _dio.get(endpoint);
      return response.data;
    } catch (e) {
      throw Exception('Failed to get object info: $e');
    }
  }

  /// Get server features
  Future<Map<String, dynamic>> getFeatures() async {
    try {
      final response = await _dio.get('/features');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get features: $e');
    }
  }

  /// Upload an image file
  Future<ComfyUIUploadResponse> uploadImage(
    Uint8List imageData,
    String filename, {
    String type = 'input',
    String? subfolder,
    bool overwrite = false,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(imageData, filename: filename),
        'type': type,
        if (subfolder != null) 'subfolder': subfolder,
        'overwrite': overwrite ? 'true' : 'false',
      });

      final response = await _dio.post('/upload/image', data: formData);
      return ComfyUIUploadResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a mask image
  Future<ComfyUIUploadResponse> uploadMask(
    Uint8List maskData,
    String filename,
    Map<String, dynamic> originalRef, {
    String type = 'input',
    String? subfolder,
    bool overwrite = false,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'image': dio.MultipartFile.fromBytes(maskData, filename: filename),
        'original_ref': jsonEncode(originalRef),
        'type': type,
        if (subfolder != null) 'subfolder': subfolder,
        'overwrite': overwrite ? 'true' : 'false',
      });

      final response = await _dio.post('/upload/mask', data: formData);
      return ComfyUIUploadResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload mask: $e');
    }
  }

  /// View/download a file
  Future<Uint8List> viewFile(
    String filename, {
    String type = 'output',
    String? subfolder,
    String? preview, // e.g., 'webp;90' for webp format with 90% quality
    String? channel, // 'rgba', 'rgb', 'a'
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'filename': filename,
        'type': type,
      };

      if (subfolder != null) queryParams['subfolder'] = subfolder;
      if (preview != null) queryParams['preview'] = preview;
      if (channel != null) queryParams['channel'] = channel;

      final response = await _dio.get(
        '/view',
        queryParameters: queryParams,
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      throw Exception('Failed to view file: $e');
    }
  }

  /// Free memory and unload models
  Future<void> freeMemory({
    bool unloadModels = false,
    bool freeMemory = false,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (unloadModels) data['unload_models'] = true;
      if (freeMemory) data['free_memory'] = true;

      await _dio.post('/free', data: data);
    } catch (e) {
      throw Exception('Failed to free memory: $e');
    }
  }

  /// Get extensions list
  Future<List<String>> getExtensions() async {
    try {
      final response = await _dio.get('/extensions');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get extensions: $e');
    }
  }

  /// Generate a unique client ID
  String generateClientId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  /// Validate a workflow before submission
  Future<Map<String, dynamic>> validateWorkflow(
    Map<String, dynamic> workflow,
  ) async {
    // This would typically be done by submitting with validation flag
    // For now, we'll do basic client-side validation

    final errors = <String, dynamic>{};
    final warnings = <String>[];

    // Check if workflow has required structure
    if (workflow.isEmpty) {
      errors['workflow'] = 'Workflow cannot be empty';
      return {'valid': false, 'errors': errors, 'warnings': warnings};
    }

    // Check for nodes
    bool hasNodes = false;
    for (final value in workflow.values) {
      if (value is Map && value.containsKey('class_type')) {
        hasNodes = true;
        break;
      }
    }

    if (!hasNodes) {
      errors['nodes'] = 'Workflow must contain at least one node';
    }

    // Add more validation logic as needed

    return {
      'valid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Create a simplified workflow for common operations
  Map<String, dynamic> createSimpleWorkflow({
    required String modelPath,
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 20,
    double cfgScale = 7.0,
    int seed = -1,
  }) {
    // This is a simplified workflow structure
    // In practice, you'd want more sophisticated workflow building
    return {
      "1": {
        "class_type": "CheckpointLoaderSimple",
        "inputs": {
          "ckpt_name": modelPath,
        },
      },
      "2": {
        "class_type": "CLIPTextEncode",
        "inputs": {
          "text": prompt,
          "clip": ["1", 1],
        },
      },
      "3": {
        "class_type": "CLIPTextEncode",
        "inputs": {
          "text": negativePrompt ?? "",
          "clip": ["1", 1],
        },
      },
      "4": {
        "class_type": "EmptyLatentImage",
        "inputs": {
          "width": width,
          "height": height,
          "batch_size": 1,
        },
      },
      "5": {
        "class_type": "KSampler",
        "inputs": {
          "seed": seed == -1 ? DateTime.now().millisecondsSinceEpoch : seed,
          "steps": steps,
          "cfg": cfgScale,
          "sampler_name": "euler",
          "scheduler": "normal",
          "denoise": 1.0,
          "model": ["1", 0],
          "positive": ["2", 0],
          "negative": ["3", 0],
          "latent_image": ["4", 0],
        },
      },
      "6": {
        "class_type": "VAEDecode",
        "inputs": {
          "samples": ["5", 0],
          "vae": ["1", 2],
        },
      },
      "7": {
        "class_type": "SaveImage",
        "inputs": {
          "filename_prefix": "meadow_generation",
          "images": ["6", 0],
        },
      },
    };
  }
}
