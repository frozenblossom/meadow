import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/video_transcript_controller.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/widgets/video_transcript/video_transcript_form.dart';
import 'package:meadow/widgets/video_transcript/video_transcript_viewer.dart';

class TranscriptsDialog extends StatelessWidget {
  const TranscriptsDialog({super.key});

  void _openTranscriptDialog(BuildContext context, VideoTranscript transcript) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(transcript.title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: VideoTranscriptViewer(transcript: transcript),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VideoTranscriptController());
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(75),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha(50),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Video Transcripts',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.transcripts.isEmpty) {
                  return _buildEmptyState(context, theme, controller);
                }

                return Column(
                  children: [
                    // Add new transcript button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VideoTranscriptForm(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('New Transcript'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${controller.transcripts.length} transcript${controller.transcripts.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(
                                180,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transcripts list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.transcripts.length,
                        itemBuilder: (context, index) {
                          final transcript = controller.transcripts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTranscriptCard(
                              context,
                              transcript,
                              theme,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    VideoTranscriptController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withAlpha(125),
            ),
            const SizedBox(height: 24),
            Text(
              'No Video Transcripts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first video transcript to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VideoTranscriptForm(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Transcript'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(
    BuildContext context,
    VideoTranscript transcript,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _openTranscriptDialog(context, transcript);
          Navigator.of(context).pop(); // Close dialog after opening transcript
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transcript.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 8),
                            Text('View'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 16),
                            SizedBox(width: 8),
                            Text('Export'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) =>
                        _handleMenuAction(context, transcript, value),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                transcript.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(204),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Stats
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildStatChip(
                    icon: Icons.timer,
                    label: '${transcript.durationSeconds}s',
                    theme: theme,
                  ),
                  _buildStatChip(
                    icon: Icons.video_library,
                    label: '${transcript.clips.length} clips',
                    theme: theme,
                  ),
                  _buildStatChip(
                    icon: Icons.photo_size_select_large,
                    label: '${transcript.mediaWidth}×${transcript.mediaHeight}',
                    theme: theme,
                  ),
                  _buildStatChip(
                    icon: Icons.movie,
                    label: '${transcript.clipLengthSeconds}s/clip',
                    theme: theme,
                  ),
                  if (transcript.generateSpeech)
                    _buildStatChip(
                      icon: Icons.record_voice_over,
                      label: 'Speech',
                      theme: theme,
                    ),
                  if (transcript.generateMusic)
                    _buildStatChip(
                      icon: Icons.music_note,
                      label: 'Music',
                      theme: theme,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Text(
                'Created ${_formatDate(transcript.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    VideoTranscript transcript,
    String action,
  ) {
    final controller = Get.find<VideoTranscriptController>();

    switch (action) {
      case 'view':
        _openTranscriptDialog(context, transcript);
        Navigator.of(context).pop(); // Close dialog after opening transcript
        break;
      case 'export':
        controller.exportTranscript(transcript.id).then((path) {
          if (path != null) {
            Get.snackbar('Success', 'Exported to: $path');
          }
        });
        break;
      case 'delete':
        _showDeleteDialog(context, transcript, controller);
        break;
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    VideoTranscript transcript,
    VideoTranscriptController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transcript'),
        content: Text('Are you sure you want to delete "${transcript.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteTranscript(transcript.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transcript deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
