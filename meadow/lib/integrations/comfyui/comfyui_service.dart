import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/integrations/comfyui/services/comfyui_api_service.dart';
import 'package:meadow/integrations/comfyui/services/comfyui_websocket_service.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ComfyUIService extends GetxService {
  late ComfyUIAPIService _apiService;
  late ComfyUIWebSocketService _wsService;

  final RxBool isServerAvailable = false.obs;
  final RxString lastError = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _apiService = ComfyUIAPIService();
      _wsService = ComfyUIWebSocketService();

      _apiService.onInit();
      _wsService.onInit();

      // Register with GetX
      Get.put<ComfyUIAPIService>(_apiService, permanent: true);
      Get.put<ComfyUIWebSocketService>(_wsService, permanent: true);

      // Configure and connect
      _apiService.updateBaseUrl('127.0.0.1', 8188);
      _wsService.updateConnection('127.0.0.1', 8188);

      await _wsService.connect();

      await checkServerAvailability();
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<bool> checkServerAvailability() async {
    try {
      final available = await _apiService.checkConnection();

      if (available) {
        // If API is available but WebSocket is disconnected, try to reconnect
        if (!_wsService.isConnected.value) {
          try {
            await _wsService.connect();
          } catch (e) {
            // Don't fail the check just because WebSocket failed - API might still work
          }
        }
      }

      isServerAvailable.value = available;
      return available;
    } catch (e) {
      isServerAvailable.value = false;
      lastError.value = e.toString();
      return false;
    }
  }
}

/// Simple generateAsset function - direct workflow submission
Future<void> generateAsset({
  required ComfyUIWorkflow workflow,
  required String ext,
  Map<String, dynamic>? metadata,
  Task? existingTask,
  Function(Asset?)? onAssetGenerated,
}) async {
  final tasksController = Get.find<TasksController>();
  final comfyUIService = Get.find<ComfyUIService>();

  final isAvailable = await comfyUIService.checkServerAvailability();

  if (!isAvailable) {
    Get.snackbar(
      'Error',
      'ComfyUI server not available. Please ensure ComfyUI is running and accessible at 127.0.0.1:8188',
    );
  }

  final task =
      existingTask ??
      Task(
        workflow: workflow,
        description: metadata?['prompt'] ?? 'No prompt',
        metadata: metadata,
        taskType: TaskType.localComfyUIGeneration,
      );

  if (existingTask == null) {
    tasksController.addTask(task);
  } else {}

  var result = await workflow.invoke();

  if (result.isEmpty) {
    throw Exception('No output file found');
  }

  final tempDir = await getTemporaryDirectory();
  final tempFile = File(
    p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.$ext',
    ),
  );
  await Dio().download(result, tempFile.path);

  task.updateProgress('Adding to workspace...');

  // Save to workspace
  final finalMetadata = {
    ...?metadata,
    'generation_source': 'comfyui',
    'generated_at': DateTime.now().toIso8601String(),
  };

  await Get.find<WorkspaceController>().addAssetFromFile(
    tempFile,
    metadata: finalMetadata,
  );

  // Cleanup
  if (await tempFile.exists()) {
    await tempFile.delete();
  }

  task.updateProgress('Added to workspace');
  task.updateStatus('Completed');
}

/// Retry failed task
Future<void> retryTaskExecution(Task task) async {
  if (!task.canRetry) {
    throw Exception('Task cannot be retried');
  }

  // Check server availability before retrying
  final comfyUIService = Get.find<ComfyUIService>();
  final isAvailable = await comfyUIService.checkServerAvailability();

  if (!isAvailable) {
    throw Exception(
      'ComfyUI server not available. Please ensure ComfyUI is running and accessible at 127.0.0.1:8188',
    );
  }

  String ext = 'png';
  if (task.workflow.assetType.toString().contains('video')) {
    ext = 'mp4';
  } else if (task.workflow.assetType.toString().contains('audio')) {
    ext = 'mp3';
  }

  task.resetForRetry();

  await generateAsset(
    workflow: task.workflow,
    ext: ext,
    metadata: task.metadata,
    existingTask: task,
  );
}
