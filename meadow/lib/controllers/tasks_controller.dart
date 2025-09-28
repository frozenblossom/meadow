import 'package:get/get.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';

class TasksController extends GetxController {
  // Use RxList for reactive updates
  final RxList<Task> _tasks = <Task>[].obs;

  // Auto-retry settings
  final RxBool _autoRetryEnabled = false.obs;
  final RxInt _autoRetryDelay = 5.obs; // seconds

  // Getter to access the reactive list
  RxList<Task> get tasks => _tasks;

  // Auto-retry getters and setters
  bool get autoRetryEnabled => _autoRetryEnabled.value;
  int get autoRetryDelay => _autoRetryDelay.value;

  void setAutoRetry(bool enabled) => _autoRetryEnabled.value = enabled;
  void setAutoRetryDelay(int seconds) => _autoRetryDelay.value = seconds;

  // Getter for regular list access if needed
  List<Task> get tasksList => _tasks.toList();

  // Add a task to the reactive list
  void addTask(Task task) {
    _tasks.add(task);
    _setupAutoRetry(task);
    // No need to call update() - RxList handles reactivity automatically
  }

  // Remove a task from the reactive list
  void removeTask(Task task) {
    _tasks.remove(task);
  }

  // Remove a task by index
  void removeTaskAt(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks.removeAt(index);
    }
  }

  // Update a task in the reactive list
  void updateTask(Task oldTask, Task newTask) {
    final index = _tasks.indexOf(oldTask);
    if (index != -1) {
      _tasks[index] = newTask;
    }
  }

  // Update task status by reference (now uses Task's reactive method)
  void updateTaskStatus(Task task, String newStatus) {
    if (_tasks.contains(task)) {
      task.updateStatus(newStatus);
      // Trigger list update to notify listeners
      _tasks.refresh();
    }
  }

  // Update task status by index (now uses Task's reactive method)
  void updateTaskStatusAt(int index, String newStatus) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index].updateStatus(newStatus);
      // Trigger list update to notify listeners
      _tasks.refresh();
    }
  }

  // Update task progress
  void updateTaskProgress(Task task, String progress) {
    if (_tasks.contains(task)) {
      task.updateProgress(progress);
      _tasks.refresh();
    }
  }

  // Set task error
  void setTaskError(Task task, String error) {
    if (_tasks.contains(task)) {
      task.setError(error);
      _tasks.refresh();
    }
  }

  // Find task by workflow reference
  Task? findTaskByWorkflow(ComfyUIWorkflow workflow) {
    try {
      return _tasks.firstWhere((task) => task.workflow == workflow);
    } catch (e) {
      return null;
    }
  }

  // Get tasks by status
  List<Task> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Get task count
  int get taskCount => _tasks.length;

  // Check if list is empty
  bool get isEmpty => _tasks.isEmpty;

  // Check if list is not empty
  bool get isNotEmpty => _tasks.isNotEmpty;

  // Clear all tasks
  void clearAllTasks() {
    _tasks.clear();
  }

  // Get pending tasks count
  int get pendingTasksCount => _tasks.where((task) => task.isPending).length;

  // Get running tasks count
  int get runningTasksCount => _tasks.where((task) => task.isRunning).length;

  // Get completed tasks count
  int get completedTasksCount =>
      _tasks.where((task) => task.isCompleted).length;

  // Get failed tasks count
  int get failedTasksCount => _tasks.where((task) => task.isFailed).length;

  // Get retryable tasks count
  int get retryableTasksCount => _tasks.where((task) => task.canRetry).length;

  // Get finished tasks count (completed + failed)
  int get finishedTasksCount => _tasks.where((task) => task.isFinished).length;

  // Reactive counters that automatically update
  int get pendingTasksCountReactive =>
      _tasks.where((task) => task.isPending).length;
  int get runningTasksCountReactive =>
      _tasks.where((task) => task.isRunning).length;
  int get completedTasksCountReactive =>
      _tasks.where((task) => task.isCompleted).length;
  int get failedTasksCountReactive =>
      _tasks.where((task) => task.isFailed).length;

  // Retry functionality
  Future<void> retryTask(Task task) async {
    if (!task.canRetry) {
      Get.snackbar('Error', 'Task cannot be retried: ${task.description}');
      return;
    }

    try {
      // Call the retry function from the service
      await retryTaskExecution(task);
    } catch (e) {
      Get.snackbar('Error', 'Error retrying task: $e');
      task.setError('Retry failed: $e');
    }
  }

  Future<void> retryAllFailedTasks() async {
    final failedTasks = _tasks.where((task) => task.canRetry).toList();

    for (final task in failedTasks) {
      await retryTask(task);
      // Add delay between retries to avoid overwhelming the system
      await Future.delayed(Duration(seconds: 1));
    }
  }

  // Auto-retry functionality
  void _setupAutoRetry(Task task) {
    if (!_autoRetryEnabled.value) return;

    // Listen to task status changes
    ever(task.statusStream, (status) async {
      if (status == 'Failed' && task.canRetry) {
        // Wait for the specified delay before retrying
        await Future.delayed(Duration(seconds: _autoRetryDelay.value));

        // Check if auto-retry is still enabled and task can still be retried
        if (_autoRetryEnabled.value && task.canRetry) {
          // print('Auto-retrying task: ${task.description}');
          await retryTask(task);
        }
      }
    });
  }
}
