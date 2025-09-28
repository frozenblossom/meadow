import 'dart:async';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/services/batch_generation_service.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

/// Service for handling batch generation as background tasks
class BackgroundBatchGenerationService {
  static final TasksController _tasksController = Get.find<TasksController>();

  /// Start batch generation as a background task
  static Task startBatchGeneration({
    required VideoTranscript transcript,
    Function(VideoClip clip, int index)? onClipUpdated,
    Function()? onCompleted,
    Function(String error)? onError,
  }) {
    // Create a dummy workflow for the task system
    final workflow = ComfyUIWorkflow(
      workflow: {},
      description: 'Batch Generation: ${transcript.title}',
    );

    // Create the background task
    final task = Task(
      workflow: workflow,
      description: 'Batch generating for: ${transcript.title}',
      taskType: TaskType.batchGeneration,
      status: 'Pending',
      progress: 'Starting batch generation...',
      metadata: {
        'transcriptId': transcript.id,
        'transcriptTitle': transcript.title,
      },
    );

    // Add to task controller
    _tasksController.addTask(task);

    // Start the generation process
    _runBatchGeneration(task, transcript, onClipUpdated, onCompleted, onError);

    return task;
  }

  /// Internal method to run the actual batch generation
  static Future<void> _runBatchGeneration(
    Task task,
    VideoTranscript transcript,
    Function(VideoClip clip, int index)? onClipUpdated,
    Function()? onCompleted,
    Function(String error)? onError,
  ) async {
    try {
      task.updateStatus('Running');

      await BatchGenerationService.generateMissingAssets(
        transcript: transcript,
        onClipUpdated: (clip, index) {
          // Update the transcript with the new clip
          onClipUpdated?.call(clip, index);
        },
        onStatusUpdate: (status) {
          task.updateProgress(status);
        },
        onProgressUpdate: (progress) {
          // Update detailed progress
          task.updateProgressDetail(
            TaskProgressDetail(
              progressPercentage: progress,
              progressText: task.progress,
            ),
          );
        },
      );

      task.updateStatus('Completed');
      task.updateProgress('Batch generation completed successfully');
      onCompleted?.call();
    } catch (e) {
      task.updateStatus('Failed');
      task.setError(e.toString());
      onError?.call(e.toString());
    }
  }

  /// Cancel a batch generation task
  static bool cancelBatchGeneration(Task task) {
    if (task.taskType == TaskType.batchGeneration) {
      task.updateStatus('Cancelled');
      // Note: Actual generation cancellation would need additional implementation
      return true;
    }
    return false;
  }

  /// Get all batch generation tasks
  static List<Task> getBatchGenerationTasks() {
    return _tasksController.tasks
        .where((task) => task.taskType == TaskType.batchGeneration)
        .toList();
  }

  /// Get batch generation task by transcript ID
  static Task? getBatchGenerationTaskByTranscript(String transcriptId) {
    return _tasksController.tasks.firstWhereOrNull(
      (task) =>
          task.taskType == TaskType.batchGeneration &&
          task.metadata?['transcriptId'] == transcriptId,
    );
  }
}
