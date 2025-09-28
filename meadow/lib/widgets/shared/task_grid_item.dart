import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/widgets/tasks/task.dart';

class TaskGridItem extends StatelessWidget {
  final Task task;

  const TaskGridItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final progressDetail = task.progressDetail;

      return InkWell(
        onTap: task.isFailed ? () => _showErrorDialog(context) : null,
        child: GridTile(
          header: GridTileBar(
            title: const Text(''),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                CupertinoIcons.ellipsis_circle,
                size: 18,
                color: Colors.white,
              ),
              itemBuilder: (context) => [
                // Timestamp information
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Started: ${_formatDateTime(task.createdAt)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        task.isFinished
                            ? 'Duration: ${_formatDuration(task.duration)}'
                            : 'Running: ${_formatDuration(task.duration)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (task.retryCount > 0)
                        Text(
                          'Retries: ${task.retryCount}/${task.maxRetries}',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                if (task.canRetry)
                  const PopupMenuItem(
                    value: 'retry',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                if (task.error.isNotEmpty)
                  const PopupMenuItem(
                    value: 'show_error',
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text('Show Error Details'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'cancel':
                    await _cancelTask(context);
                    break;
                  case 'retry':
                    await _retryTask(context);
                    break;
                  case 'show_error':
                    await _showErrorDialog(context);
                    break;
                }
              },
            ),
          ),
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                // Main task content
                _buildTaskContent(context, theme, progressDetail),

                // Top-left badges
                Positioned(
                  top: 4,
                  left: 4,
                  child: _buildBadges(theme),
                ),

                // Error indicator (red border when failed)
                if (task.isFailed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTaskContent(
    BuildContext context,
    ThemeData theme,
    TaskProgressDetail? progressDetail,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            // Top section - Status icon and progress
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator
                    _buildStatusIndicator(theme, progressDetail),
                    const SizedBox(height: 8),

                    // Progress text
                    Text(
                      _getProgressText(progressDetail),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.isFailed
                            ? Colors.red[300]
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Error tap hint
                    if (task.isFailed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap for details',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red[200],
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom section - Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(220),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                task.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Preview image overlay if available
        if (progressDetail?.previewImage != null)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: MemoryImage(progressDetail!.previewImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    ThemeData theme,
    TaskProgressDetail? progressDetail,
  ) {
    if (task.isFailed) {
      return Icon(
        Icons.error_outline,
        size: 32,
        color: Colors.red[400],
      );
    }

    if (task.isCompleted) {
      return Icon(
        Icons.check_circle_outline,
        size: 32,
        color: Colors.green[400],
      );
    }

    if (task.isRunning) {
      // Use progress percentage if available
      if (progressDetail?.progressPercentage != null) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: progressDetail!.progressPercentage!,
                strokeWidth: 3,
                backgroundColor: theme.colorScheme.onSurfaceVariant.withAlpha(
                  50,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              '${(progressDetail.progressPercentage! * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        );
      } else {
        return SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.onSurfaceVariant.withAlpha(
              50,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      }
    }

    if (task.isPending) {
      return Icon(
        Icons.schedule,
        size: 32,
        color: Colors.amber[700],
      );
    }

    return const SizedBox.shrink();
  }

  String _getProgressText(TaskProgressDetail? progressDetail) {
    if (task.isFailed) {
      return 'Failed • ${_formatDuration(task.duration)}';
    }

    if (task.isCompleted) {
      return 'Completed • ${_formatDuration(task.duration)}';
    }

    if (task.isRunning) {
      if (progressDetail?.currentNode != null) {
        return 'Processing: ${progressDetail!.currentNode}';
      }
      if (progressDetail?.queuePosition != null) {
        return 'Queue position: ${progressDetail!.queuePosition}';
      }
      return 'Processing • ${_formatDuration(task.duration)}';
    }

    if (task.isPending) {
      return 'Pending';
    }

    return task.status;
  }

  Future<void> _cancelTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Task'),
        content: Text('Are you sure you want to cancel "${task.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tasksController = Get.find<TasksController>();
        tasksController.removeTask(task);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling task: $e')),
          );
        }
      }
    }
  }

  Future<void> _retryTask(BuildContext context) async {
    try {
      final tasksController = Get.find<TasksController>();
      await tasksController.retryTask(task);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task retried')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrying task: $e')),
        );
      }
    }
  }

  Widget _buildBadges(ThemeData theme) {
    final badges = <Widget>[];

    // Local/Cloud badge
    if (task.isLocalGeneration) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(220),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'LOCAL',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(220),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'CLOUD',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Retry count badge
    if (task.retryCount > 0) {
      badges.add(
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(220),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'RETRY ${task.retryCount}',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: badges,
    );
  }

  Future<void> _showErrorDialog(BuildContext context) async {
    if (task.error.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Task Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task: ${task.description}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withAlpha(75)),
              ),
              child: Text(
                task.error,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (task.retryCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Retry attempts: ${task.retryCount}/${task.maxRetries}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (task.canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryTask(context);
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
