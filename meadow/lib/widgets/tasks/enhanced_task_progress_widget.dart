import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/widgets/tasks/task.dart';

class EnhancedTaskProgressWidget extends StatelessWidget {
  final Task task;
  final bool showPreview;

  const EnhancedTaskProgressWidget({
    super.key,
    required this.task,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progressDetail = task.progressDetail;
      final theme = Theme.of(context);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task header
              Row(
                children: [
                  Icon(
                    _getStatusIcon(task.status),
                    color: _getStatusColor(task.status),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.isLocalGeneration) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Text(
                        'LOCAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Text(
                        'CLOUD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              if (progressDetail?.progressPercentage != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progressDetail!.progressPercentage!,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(task.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progressDetail.progressPercentage! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (task.isRunning) ...[
                LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(task.status),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Progress details
              if (progressDetail != null) ...[
                _buildProgressDetails(progressDetail, theme),
                const SizedBox(height: 8),
              ],

              // Time and duration information
              _buildTimeInfo(task, theme),
              const SizedBox(height: 8),

              // Basic progress text
              Text(
                task.progress.isNotEmpty ? task.progress : task.status,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),

              // Preview image
              if (showPreview && progressDetail?.previewImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    progressDetail!.previewImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              // Error display
              if (task.error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withAlpha(75)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.error,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (task.canRetry || task.isRunning) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.canRetry) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final controller = Get.find<TasksController>();
                          await controller.retryTask(task);
                        },
                        icon: Icon(Icons.refresh, size: 14),
                        label: Text('Retry', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final controller = Get.find<TasksController>();
                          controller.removeTask(task);
                        },
                        icon: Icon(Icons.delete_outline, size: 14),
                        label: Text('Remove', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Show max retries exceeded message
              if (task.isFailed && task.hasExceededMaxRetries) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Max retries exceeded',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        final controller = Get.find<TasksController>();
                        controller.removeTask(task);
                      },
                      icon: Icon(Icons.delete_outline, size: 14),
                      label: Text('Remove', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTimeInfo(Task task, ThemeData theme) {
    final List<Widget> timeDetails = [];

    // Creation time
    timeDetails.add(
      Row(
        children: [
          Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Started: ${_formatDateTime(task.createdAt)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );

    // Duration and completion time
    if (task.isFinished && task.completedAt != null) {
      timeDetails.add(
        Row(
          children: [
            Icon(Icons.timer, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Duration: ${_formatDuration(task.duration)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

      timeDetails.add(
        Row(
          children: [
            Icon(Icons.check_circle_outline, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Finished: ${_formatDateTime(DateTime.parse(task.completedAt!))}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    } else {
      // Show running duration for active tasks
      timeDetails.add(
        Row(
          children: [
            Icon(Icons.timer, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Running: ${_formatDuration(task.duration)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Retry count if applicable
    if (task.retryCount > 0) {
      timeDetails.add(
        Row(
          children: [
            Icon(Icons.replay, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Retry ${task.retryCount}/${task.maxRetries}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: timeDetails,
    );
  }

  Widget _buildProgressDetails(TaskProgressDetail detail, ThemeData theme) {
    final List<Widget> details = [];

    if (detail.currentNode?.isNotEmpty == true) {
      details.add(
        Row(
          children: [
            Icon(Icons.widgets, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Node: ${detail.currentNode}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (detail.currentStep != null && detail.totalSteps != null) {
      details.add(
        Row(
          children: [
            Icon(Icons.stairs, size: 12, color: theme.colorScheme.secondary),
            const SizedBox(width: 4),
            Text(
              'Step ${detail.currentStep}/${detail.totalSteps}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (detail.queuePosition != null && detail.queuePosition! > 0) {
      details.add(
        Row(
          children: [
            Icon(Icons.queue, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Queue: ${detail.queuePosition}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: details,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'queued':
        return Icons.queue;
      case 'running':
        return Icons.play_circle;
      case 'downloading':
        return Icons.download;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'queued':
        return Colors.orange;
      case 'running':
        return Colors.blue;
      case 'downloading':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
