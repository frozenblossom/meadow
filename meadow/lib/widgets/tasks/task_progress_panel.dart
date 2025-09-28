import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/widgets/tasks/enhanced_task_progress_widget.dart';

class TaskProgressPanel extends StatelessWidget {
  final bool showCompletedTasks;
  final bool showPreviewImages;

  const TaskProgressPanel({
    super.key,
    this.showCompletedTasks = false,
    this.showPreviewImages = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TasksController>(
      builder: (taskController) {
        final allTasks = taskController.tasks;

        // Filter tasks based on preferences
        final tasksToShow = allTasks.where((task) {
          if (!showCompletedTasks && task.isCompleted) {
            return false;
          }
          return true;
        }).toList();

        if (tasksToShow.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    showCompletedTasks ? 'No tasks found' : 'No active tasks',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showCompletedTasks
                        ? 'Start generating some content to see tasks here'
                        : 'All tasks are completed!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with task count and filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tasks (${tasksToShow.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildFilterChips(context, taskController),
                ],
              ),
            ),

            // Task list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasksToShow.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasksToShow[index];
                  return EnhancedTaskProgressWidget(
                    task: task,
                    showPreview: showPreviewImages,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    TasksController taskController,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      children: [
        // Running tasks count
        if (taskController.runningTasksCount > 0)
          Chip(
            avatar: Icon(
              Icons.play_circle,
              size: 16,
              color: Colors.blue,
            ),
            label: Text(
              '${taskController.runningTasksCount} running',
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.blue.withAlpha(25),
            side: BorderSide(color: Colors.blue.withAlpha(75)),
          ),

        // Queued tasks count (assuming queued is similar to pending)
        if (taskController.pendingTasksCount > 0)
          Chip(
            avatar: Icon(
              Icons.queue,
              size: 16,
              color: Colors.orange,
            ),
            label: Text(
              '${taskController.pendingTasksCount} queued',
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.orange.withAlpha(25),
            side: BorderSide(color: Colors.orange.withAlpha(75)),
          ),

        // Failed tasks count
        if (taskController.failedTasksCount > 0)
          Chip(
            avatar: Icon(
              Icons.error,
              size: 16,
              color: Colors.red,
            ),
            label: Text(
              '${taskController.failedTasksCount} failed',
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.red.withAlpha(25),
            side: BorderSide(color: Colors.red.withAlpha(75)),
          ),

        // Clear completed button
        if (taskController.completedTasksCount > 0)
          ActionChip(
            avatar: Icon(
              Icons.clear_all,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Clear completed (${taskController.completedTasksCount})',
              style: TextStyle(fontSize: 12),
            ),
            onPressed: () {
              // Remove completed tasks directly
              final completedTasks = taskController.tasks
                  .where((task) => task.isCompleted)
                  .toList();

              for (final task in completedTasks) {
                taskController.removeTask(task);
              }

              Get.snackbar(
                'Tasks Cleared',
                '${completedTasks.length} completed tasks removed',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
      ],
    );
  }
}
