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

/*
/// Execute workflow directly without complex service layers
Future<void> _executeWorkflowDirectly(
  Task task,
  ComfyUIWorkflow workflow,
  String ext,
  Map<String, dynamic>? metadata,
  Function(Asset?)? onAssetGenerated,
) async {
  try {
    final apiService = Get.find<ComfyUIAPIService>();

    task.updateStatus('Preparing');
    task.updateProgress('Submitting workflow to ComfyUI...');

    // Submit workflow directly to ComfyUI API

    final promptResponse = await apiService.submitPrompt(
      ComfyUIPromptRequest(prompt: workflow.workflow),
    );

    final promptId = promptResponse.promptId;

    // Set up completion listener
    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = task.statusStream.listen((status) async {
      if (status == 'Completed' || status == 'Failed') {
        subscription.cancel();
        if (status == 'Completed') {
          try {
            final asset = await _downloadAndSaveResult(
              task,
              promptId,
              ext,
              metadata,
            );

            task.updateStatus('Completed');
            task.updateProgress('Asset generated successfully');

            // Invoke callback if provided
            if (onAssetGenerated != null) {
              onAssetGenerated(asset);
            }

            completer.complete();
          } catch (e) {
            task.setError('Failed to save result: $e');
            completer.completeError(e);
          }
        } else {
          completer.completeError(Exception(task.error));
        }
      }
    });

    // Wait for completion
    await completer.future.timeout(
      Duration(minutes: 10),
      onTimeout: () {
        throw Exception('Generation timed out');
      },
    );
  } catch (e) {
    task.setError('Generation failed: $e');
  }
}

/// Download result and save to workspace
Future<Asset?> _downloadAndSaveResult(
  Task task,
  String promptId,
  String ext,
  Map<String, dynamic>? metadata,
) async {
  try {
    final apiService = Get.find<ComfyUIAPIService>();
    final workspaceController = Get.find<WorkspaceController>();

    task.updateStatus('Downloading');
    task.updateProgress('Downloading generated file...');

    // Get output files
    final historyResponse = await apiService.getHistory(promptId: promptId);

    if (historyResponse.isEmpty) {
      throw Exception('No output files found');
    }

    final historyEntry = historyResponse.values.first;
    final outputs = historyEntry['outputs'] as Map<String, dynamic>?;

    if (outputs == null || outputs.isEmpty) {
      throw Exception('No outputs found');
    }

    // Find output file
    String? outputFilename;

    for (final entry in outputs.entries) {
      final output = entry.value;

      if (output is Map<String, dynamic>) {
        if (output.containsKey('images')) {
          final images = output['images'] as List?;

          if (images != null && images.isNotEmpty) {
            final firstImage = images.first as Map<String, dynamic>;
            outputFilename = firstImage['filename'] as String?;
            break;
          }
        } else if (output.containsKey('videos')) {
          final videos = output['videos'] as List?;

          if (videos != null && videos.isNotEmpty) {
            final firstVideo = videos.first as Map<String, dynamic>;
            outputFilename = firstVideo['filename'] as String?;
            break;
          }
        } else if (output.containsKey('audio')) {
          final audios = output['audio'] as List?;

          if (audios != null && audios.isNotEmpty) {
            final firstAudio = audios.first as Map<String, dynamic>;
            outputFilename = firstAudio['filename'] as String?;
            break;
          }
        }
      }
    }

    if (outputFilename == null) {
      throw Exception('No output file found');
    }

    // Download file
    final fileBytes = await apiService.viewFile(outputFilename);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      p.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_$outputFilename',
      ),
    );
    await tempFile.writeAsBytes(fileBytes);

    task.updateProgress('Adding to workspace...');

    // Save to workspace
    final finalMetadata = {
      ...?metadata,
      'comfyui_prompt_id': promptId,
      'generation_source': 'comfyui',
      'generated_at': DateTime.now().toIso8601String(),
    };

    final asset = await workspaceController.addAssetFromFile(
      tempFile,
      metadata: finalMetadata,
    );

    // Cleanup
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    return asset;
  } catch (e) {
    throw Exception('Failed to download result: $e');
  }
}
*/
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
