import 'dart:ui';
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
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.black.withAlpha(200),
                        Colors.black.withAlpha(150),
                      ]
                    : [
                        Colors.white.withAlpha(200),
                        Colors.white.withAlpha(150),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(50)
                    : Colors.black.withAlpha(25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(100)
                      : Colors.black.withAlpha(50),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(25)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF4F46E5).withAlpha(150),
                                    const Color(0xFF7C3AED).withAlpha(150),
                                  ]
                                : [
                                    const Color(0xFF6366F1).withAlpha(150),
                                    const Color(0xFF8B5CF6).withAlpha(150),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.video_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Video Transcripts',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      _buildGlassIconButton(
                        icon: Icons.close,
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Obx(() {
                    if (controller.transcripts.isEmpty) {
                      return _buildEmptyState(
                        context,
                        theme,
                        controller,
                        isDark,
                      );
                    }

                    return Column(
                      children: [
                        // Add new transcript button
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              _buildGlassButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const VideoTranscriptForm(),
                                    ),
                                  );
                                },
                                label: 'New Transcript',
                                icon: Icons.add,
                                isPrimary: true,
                                isDark: isDark,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            Colors.white.withAlpha(20),
                                            Colors.white.withAlpha(10),
                                          ]
                                        : [
                                            Colors.black.withAlpha(15),
                                            Colors.black.withAlpha(8),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withAlpha(25)
                                        : Colors.black.withAlpha(15),
                                  ),
                                ),
                                child: Text(
                                  '${controller.transcripts.length} transcript${controller.transcripts.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Transcripts list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: controller.transcripts.length,
                            itemBuilder: (context, index) {
                              final transcript = controller.transcripts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildTranscriptCard(
                                  context,
                                  transcript,
                                  theme,
                                  isDark,
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    VideoTranscriptController controller,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withAlpha(15),
                          Colors.white.withAlpha(8),
                        ]
                      : [
                          Colors.black.withAlpha(10),
                          Colors.black.withAlpha(5),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(25)
                      : Colors.black.withAlpha(15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF4F46E5).withAlpha(100),
                                const Color(0xFF7C3AED).withAlpha(100),
                              ]
                            : [
                                const Color(0xFF6366F1).withAlpha(100),
                                const Color(0xFF8B5CF6).withAlpha(100),
                              ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.video_library_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Video Transcripts',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create your first video transcript to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildGlassButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VideoTranscriptForm(),
                        ),
                      );
                    },
                    label: 'Create Transcript',
                    icon: Icons.add,
                    isPrimary: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(
    BuildContext context,
    VideoTranscript transcript,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // Close dialog after opening transcript
        _openTranscriptDialog(context, transcript);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withAlpha(25),
                        Colors.white.withAlpha(12),
                      ]
                    : [
                        Colors.black.withAlpha(15),
                        Colors.black.withAlpha(8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(30)
                    : Colors.black.withAlpha(20),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(50)
                      : Colors.black.withAlpha(15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
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
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildGlassPopupMenu(context, transcript, isDark),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  transcript.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Stats
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      icon: Icons.timer,
                      label: '${transcript.durationSeconds}s',
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.video_library,
                      label: '${transcript.clips.length} clips',
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.photo_size_select_large,
                      label:
                          '${transcript.mediaWidth}×${transcript.mediaHeight}',
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildStatChip(
                      icon: Icons.movie,
                      label: '${transcript.clipLengthSeconds}s/clip',
                      theme: theme,
                      isDark: isDark,
                    ),
                    if (transcript.generateSpeech)
                      _buildStatChip(
                        icon: Icons.record_voice_over,
                        label: 'Speech',
                        theme: theme,
                        isDark: isDark,
                      ),
                    if (transcript.generateMusic)
                      _buildStatChip(
                        icon: Icons.music_note,
                        label: 'Music',
                        theme: theme,
                        isDark: isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date
                Text(
                  'Created ${_formatDate(transcript.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withAlpha(20),
                  Colors.white.withAlpha(10),
                ]
              : [
                  Colors.black.withAlpha(15),
                  Colors.black.withAlpha(8),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(25)
              : Colors.black.withAlpha(15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required String label,
    required bool isPrimary,
    required bool isDark,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ]
                          : [
                              const Color(0xFF34D399),
                              const Color(0xFF10B981),
                            ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withAlpha(30),
                              Colors.white.withAlpha(15),
                            ]
                          : [
                              Colors.black.withAlpha(20),
                              Colors.black.withAlpha(10),
                            ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary
                    ? (isDark
                          ? Colors.white.withAlpha(100)
                          : Colors.white.withAlpha(150))
                    : (isDark
                          ? Colors.white.withAlpha(30)
                          : Colors.black.withAlpha(20)),
                width: isPrimary ? 1.5 : 1,
              ),
              boxShadow: [
                if (isPrimary)
                  BoxShadow(
                    color:
                        (isDark
                                ? const Color(0xFF10B981)
                                : const Color(0xFF34D399))
                            .withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(50)
                      : Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: isPrimary
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withAlpha(20),
                  Colors.white.withAlpha(10),
                ]
              : [
                  Colors.black.withAlpha(15),
                  Colors.black.withAlpha(5),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(30)
              : Colors.black.withAlpha(20),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildGlassPopupMenu(
    BuildContext context,
    VideoTranscript transcript,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withAlpha(20),
                  Colors.white.withAlpha(10),
                ]
              : [
                  Colors.black.withAlpha(15),
                  Colors.black.withAlpha(5),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(30)
              : Colors.black.withAlpha(20),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
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
        onSelected: (value) => _handleMenuAction(context, transcript, value),
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
