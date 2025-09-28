import 'dart:async';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/services/video_assembly_service.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

/// Service for handling video assembly as background tasks
class BackgroundVideoAssemblyService {
  static final TasksController _tasksController = Get.find<TasksController>();

  /// Start video assembly as a background task
  static Task startVideoAssembly({
    required VideoTranscript transcript,
    String? outputDir,
    bool includeAudio = true,
    bool includeBackgroundMusic = true,
    Function(String outputPath)? onCompleted,
    Function(String error)? onError,
  }) {
    // Create a dummy workflow for the task system
    final workflow = ComfyUIWorkflow(
      workflow: {},
      description: 'Video Assembly: ${transcript.title}',
    );

    // Create the background task
    final task = Task(
      workflow: workflow,
      description: 'Assembling video: ${transcript.title}',
      taskType: TaskType.videoAssembly,
      metadata: {
        'transcriptId': transcript.id,
        'transcriptTitle': transcript.title,
        'outputDir': outputDir,
        'includeAudio': includeAudio,
        'includeBackgroundMusic': includeBackgroundMusic,
      },
    );

    // Add to task controller
    _tasksController.addTask(task);

    // Start the assembly process
    _runVideoAssembly(
      task,
      transcript,
      outputDir,
      includeAudio,
      includeBackgroundMusic,
      onCompleted,
      onError,
    );

    return task;
  }

  /// Internal method to run the actual video assembly
  static Future<void> _runVideoAssembly(
    Task task,
    VideoTranscript transcript,
    String? outputDir,
    bool includeAudio,
    bool includeBackgroundMusic,
    Function(String outputPath)? onCompleted,
    Function(String error)? onError,
  ) async {
    try {
      task.updateStatus('Running');

      final result = await VideoAssemblyService.assembleVideo(
        transcript: transcript,
        onProgress: (progress) {
          // Update task progress
          task.updateProgress(
            '${progress.currentOperation} (${(progress.progressPercentage * 100).toStringAsFixed(1)}%)',
          );

          // Update detailed progress
          task.updateProgressDetail(
            TaskProgressDetail(
              currentStep: progress.currentStep,
              totalSteps: progress.totalSteps,
              progressPercentage: progress.progressPercentage,
              progressText: progress.currentOperation,
            ),
          );
        },
        outputDir: outputDir,
        includeAudio: includeAudio,
        includeBackgroundMusic: includeBackgroundMusic,
      );

      if (result.hasError) {
        task.updateStatus('Failed');
        task.setError(result.errorMessage!);
        onError?.call(result.errorMessage!);
      } else {
        task.updateStatus('Completed');
        task.updateProgress('Video assembly completed successfully');
        onCompleted?.call(result.outputPath!);
      }
    } catch (e) {
      task.updateStatus('Failed');
      task.setError(e.toString());
      onError?.call(e.toString());
    }
  }

  /// Cancel a video assembly task
  static bool cancelVideoAssembly(Task task) {
    if (task.taskType == TaskType.videoAssembly) {
      task.updateStatus('Cancelled');
      // Note: Actual FFmpeg process cancellation would need additional implementation
      return true;
    }
    return false;
  }

  /// Get all video assembly tasks
  static List<Task> getVideoAssemblyTasks() {
    return _tasksController.tasks
        .where((task) => task.taskType == TaskType.videoAssembly)
        .toList();
  }

  /// Get video assembly task by transcript ID
  static Task? getVideoAssemblyTaskByTranscript(String transcriptId) {
    return _tasksController.tasks.firstWhereOrNull(
      (task) =>
          task.taskType == TaskType.videoAssembly &&
          task.metadata?['transcriptId'] == transcriptId,
    );
  }
}
