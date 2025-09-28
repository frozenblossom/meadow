import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final Widget content;
  final List<MenuItem> subTabs;
  final Widget Function()? customIconBuilder;
  int selectedSubTabIndex = 0;

  Widget contentWidget() {
    return subTabs.isNotEmpty ? subTabs[selectedSubTabIndex].content : content;
  }

  Widget getIconWidget({Color? color, double size = 28}) {
    if (customIconBuilder != null) {
      if (title == 'Tasks') {
        return TasksTabIcon(color: color, size: size);
      }
      return customIconBuilder!();
    }
    return Icon(icon, color: color, size: size);
  }

  MenuItem({
    required this.title,
    required this.icon,
    required this.content,
    this.subTabs = const <MenuItem>[],
    this.customIconBuilder,
  });
}

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
                CupertinoIcons.doc_checkmark,
                color: color,
                size:
                    size *
                    0.7, // Slightly smaller to fit inside progress indicator
              ),

              // Badge for active tasks count
              if (activeTasks > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasRunningTasks ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      activeTasks > 99 ? '99+' : activeTasks.toString(),
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
      // Fallback if TasksController is not found
      return Icon(
        CupertinoIcons.doc_checkmark,
        color: color,
        size: size,
      );
    }
  }
}
