import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';

// Custom widget for Tasks tab icon with progress indicator and badge
class TasksTabIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const TasksTabIcon({super.key, this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<TasksController>();

      return Obx(() {
        final runningTasks = controller.runningTasksCount;
        final pendingTasks = controller.pendingTasksCount;
        final activeTasks = runningTasks + pendingTasks;
        final hasRunningTasks = runningTasks > 0;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circular progress indicator for running tasks
              if (hasRunningTasks)
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

              // Main icon
              Icon(
                Icons.task_alt_outlined,
                color: color,
                size: size,
              ),

              // Task count badge
              if (activeTasks > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasRunningTasks ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      activeTasks.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      });
    } catch (e) {
      // Fallback when controller is not found
      return Icon(
        Icons.task_alt_outlined,
        color: color,
        size: size,
      );
    }
  }
}
