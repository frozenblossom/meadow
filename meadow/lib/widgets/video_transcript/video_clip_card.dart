import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/widgets/video_transcript/generation_sheets/audio_generation_sheet.dart';
import 'package:meadow/widgets/video_transcript/generation_sheets/image_generation_sheet.dart';
import 'package:meadow/widgets/video_transcript/generation_sheets/video_generation_sheet.dart';

/// A clean, focused VideoClipCard widget
/// Now uses GenerationContext instead of full VideoTranscript to break circular dependency
class VideoClipCard extends StatefulWidget {
  final VideoClip clip;
  final GenerationContext generationContext;
  final int clipIndex;
  final double duration;
  final VoidCallback onRegenerate;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final Function(VideoClip) onClipUpdated;
  final Function(VideoClip)? onClipPromptsUpdated;

  const VideoClipCard({
    super.key,
    required this.clip,
    required this.generationContext,
    required this.clipIndex,
    required this.duration,
    required this.onRegenerate,
    required this.onEdit,
    this.onDelete,
    required this.onClipUpdated,
    this.onClipPromptsUpdated,
  });

  @override
  State<VideoClipCard> createState() => _VideoClipCardState();
}

class _VideoClipCardState extends State<VideoClipCard> {
  final Map<String, Timer?> _debounceTimers = {};

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          _buildContent(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildClipBadge(theme),
          const SizedBox(width: 12),
          _buildDurationInfo(theme),
          const SizedBox(width: 12),
          _buildReadinessIndicator(theme),
          const Spacer(),
          _buildMenuButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildClipBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Clip ${widget.clipIndex + 1}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDurationInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.duration.toStringAsFixed(1)}s',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReadinessIndicator(ThemeData theme) {
    final status = widget.clip.readinessStatus;
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case ClipReadinessStatus.ready:
        icon = Icons.check_circle;
        color = theme.colorScheme.primary;
        tooltip = 'Ready for export';
        break;
      case ClipReadinessStatus.needsVideo:
        icon = Icons.video_camera_back;
        color = Colors.orange;
        tooltip = 'Needs video generation';
        break;
      case ClipReadinessStatus.needsAssets:
        icon = Icons.warning_amber;
        color = theme.colorScheme.error;
        tooltip = 'Missing assets: ${widget.clip.missingAssets.join(', ')}';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildMenuButton(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'regenerate',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('Regenerate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),

        if (widget.onDelete != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Clip', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromptWithAssetSection(
            context: context,
            title: 'Image Prompt',
            content: widget.clip.imagePrompt,
            icon: Icons.image,
            color: theme.colorScheme.secondary,
            filePath: widget.clip.generatedImagePath,
            assetType: 'image',
            onGenerate: () => _showImageGenerationOptions(context),
          ),
          const SizedBox(height: 16),
          _buildPromptWithAssetSection(
            context: context,
            title: 'Video Prompt',
            content: widget.clip.videoPrompt,
            icon: Icons.videocam,
            color: theme.colorScheme.tertiary,
            filePath: widget.clip.generatedVideoPath,
            assetType: 'video',
            onGenerate: () => _showVideoGenerationOptions(context),
          ),
          if (widget.clip.speech != null) ...[
            const SizedBox(height: 16),
            _buildPromptWithAssetSection(
              context: context,
              title: 'Speech',
              content: widget.clip.speech!,
              icon: Icons.record_voice_over,
              color: theme.colorScheme.primary,
              filePath: widget.clip.generatedSpeechAudioPath,
              assetType: 'audio',
              onGenerate: () => _showAudioGenerationOptions(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptWithAssetSection({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required String? filePath,
    required String assetType,
    required VoidCallback onGenerate,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, size: 16, color: color),
                onPressed: () => _copyToClipboard(context, content),
                tooltip: 'Copy to clipboard',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Editable text field
          TextFormField(
            initialValue: content,
            maxLines: null,
            minLines: 2,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter your ${title.toLowerCase()}...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withAlpha(128)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withAlpha(128)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final trimmedValue = value.trim();
              if (trimmedValue.isNotEmpty && trimmedValue != content) {
                // Cancel any existing timer for this field
                _debounceTimers[title]?.cancel();

                // Set a new timer for debounced update
                _debounceTimers[title] = Timer(
                  const Duration(milliseconds: 500),
                  () {
                    _updateClipPrompt(title, trimmedValue);
                  },
                );
              }
            },
          ),

          const SizedBox(height: 12),

          // Asset generation card
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Stack(
              children: [
                // Thumbnail or placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: filePath != null && File(filePath).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildFileThumbnail(
                            context,
                            filePath,
                            theme,
                            icon,
                            assetType,
                          ),
                        )
                      : _buildPlaceholder(context, icon, assetType),
                ),
                // Overlay with action button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onGenerate,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(77),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        (filePath != null && File(filePath).existsSync())
                            ? Icons.refresh
                            : Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileThumbnail(
    BuildContext context,
    String filePath,
    ThemeData theme,
    IconData fallbackIcon,
    String assetType,
  ) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return _buildPlaceholder(context, fallbackIcon, assetType);
    }

    // Determine file type based on extension or assetType
    final extension = filePath.split('.').last.toLowerCase();

    if (assetType == 'image' ||
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context, fallbackIcon, assetType);
        },
      );
    } else if (assetType == 'video' ||
        ['mp4', 'avi', 'mov', 'webm', 'mkv'].contains(extension)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.videocam,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else if (assetType == 'audio' ||
        ['mp3', 'wav', 'aac', 'ogg', 'flac'].contains(extension)) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audiotrack,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.graphic_eq,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
            ),
          ],
        ),
      );
    } else {
      return _buildPlaceholder(context, fallbackIcon, assetType);
    }
  }

  Widget _buildPlaceholder(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.outline),
          const SizedBox(height: 4),
          Text(
            'No $title',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'regenerate':
        widget.onRegenerate();
        break;
      case 'edit':
        widget.onEdit();
        break;
      case 'copy_image':
        _copyToClipboard(context, widget.clip.imagePrompt);
        break;
      case 'copy_video':
        _copyToClipboard(context, widget.clip.videoPrompt);
        break;
      case 'copy_speech':
        if (widget.clip.speech != null) {
          _copyToClipboard(context, widget.clip.speech!);
        }
        break;
      case 'delete':
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
        break;
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImageGenerationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ImageGenerationSheet(
        clip: widget.clip,
        context: widget.generationContext,
        onUpdate: widget.onClipUpdated,
        generateAssetWithUpdate: _generateAssetWithUpdate,
      ),
    );
  }

  void _showVideoGenerationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => VideoGenerationSheet(
        clip: widget.clip,
        context: widget.generationContext,
        onUpdate: widget.onClipUpdated,
        generateAssetWithUpdate: _generateAssetWithUpdate,
      ),
    );
  }

  void _showAudioGenerationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AudioGenerationSheet(
        clip: widget.clip,
        onUpdate: widget.onClipUpdated,
        generateAssetWithUpdate: _generateAssetWithUpdate,
      ),
    );
  }

  Future<void> _generateAssetWithUpdate({
    required workflow,
    required String ext,
    required String assetType,
    metadata,
    existingTask,
  }) async {
    try {
      // Generate the asset with callback
      await generateAsset(
        workflow: workflow,
        ext: ext,
        metadata: metadata,
        existingTask: existingTask,
        onAssetGenerated: (asset) {
          if (asset != null) {
            // Convert Asset to file path and update the clip
            final String filePath = (asset as LocalAsset).file.path;
            VideoClip updatedClip;
            switch (assetType.toLowerCase()) {
              case 'image':
                updatedClip = widget.clip.copyWith(
                  generatedImagePath: filePath,
                );
                break;
              case 'video':
                updatedClip = widget.clip.copyWith(
                  generatedVideoPath: filePath,
                );
                break;
              case 'audio':
                updatedClip = widget.clip.copyWith(
                  generatedSpeechAudioPath: filePath,
                );
                break;
              default:
                return;
            }

            // Notify parent of the updated clip
            widget.onClipUpdated(updatedClip);
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to generate $assetType: $e');
      // Error handling could be improved by passing context or using a callback
      // For now, just log the error
    }
  }

  /// Update the clip with the new prompt content
  void _updateClipPrompt(String promptType, String newContent) {
    VideoClip updatedClip;

    switch (promptType.toLowerCase()) {
      case 'image prompt':
        updatedClip = widget.clip.copyWith(imagePrompt: newContent);
        break;
      case 'video prompt':
        updatedClip = widget.clip.copyWith(videoPrompt: newContent);
        break;
      case 'speech':
        updatedClip = widget.clip.copyWith(speech: newContent);
        break;
      default:
        return;
    }

    // Use the prompt-specific callback if available, otherwise fall back to general callback
    if (widget.onClipPromptsUpdated != null) {
      widget.onClipPromptsUpdated!(updatedClip);
    } else {
      widget.onClipUpdated(updatedClip);
    }
  }
}
