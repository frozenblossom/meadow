import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/generation_settings_controller.dart';
import 'package:meadow/controllers/tasks_controller.dart';

class GenerationStatusSummary extends StatelessWidget {
  const GenerationStatusSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GenerationSettingsController>(
      builder: (genController) => GetBuilder<TasksController>(
        builder: (taskController) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generation Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildTaskStatusChip(
                        'Running',
                        taskController.runningTasksCount,
                        Colors.blue,
                        Icons.play_circle,
                      ),
                      const SizedBox(width: 8),
                      _buildTaskStatusChip(
                        'Pending',
                        taskController.pendingTasksCount,
                        Colors.orange,
                        Icons.schedule,
                      ),
                      const SizedBox(width: 8),
                      _buildTaskStatusChip(
                        'Failed',
                        taskController.failedTasksCount,
                        Colors.red,
                        Icons.error,
                      ),
                      const SizedBox(width: 8),
                      _buildTaskStatusChip(
                        'Completed',
                        taskController.completedTasksCount,
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskStatusChip(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
