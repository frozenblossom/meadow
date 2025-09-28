import 'package:flutter/material.dart';
import 'package:meadow/models/video_clip.dart';

/// A compact thumbnail representation of a video clip for grid view
class VideoClipThumbnail extends StatelessWidget {
  final VideoClip clip;
  final int clipIndex;
  final double duration;
  final VoidCallback onTap;

  const VideoClipThumbnail({
    super.key,
    required this.clip,
    required this.clipIndex,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main thumbnail content
            _buildThumbnailContent(context, theme),

            // Top overlay with clip number and status
            _buildTopOverlay(context, theme),

            // Bottom overlay with duration
            _buildBottomOverlay(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(BuildContext context, ThemeData theme) {
    // Show generated image if available, otherwise show placeholder
    if (clip.hasGeneratedImage) {
      return Image.file(
        clip.generatedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context, theme);
        },
      );
    } else {
      return _buildPlaceholder(context, theme);
    }
  }

  Widget _buildPlaceholder(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              clip.imagePrompt.length > 50
                  ? '${clip.imagePrompt.substring(0, 50)}...'
                  : clip.imagePrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context, ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(180),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Clip number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${clipIndex + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Drag indicator
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(127),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.drag_indicator,
                size: 12,
                color: Colors.white.withAlpha(204),
              ),
            ),
            const Spacer(),
            // Readiness status indicator
            _buildStatusIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final status = clip.readinessStatus;
    IconData icon;
    Color color;

    switch (status) {
      case ClipReadinessStatus.ready:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ClipReadinessStatus.needsVideo:
        icon = Icons.video_camera_back;
        color = Colors.orange;
        break;
      case ClipReadinessStatus.needsAssets:
        icon = Icons.warning_amber;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(127),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context, ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(180),
            ],
          ),
        ),
        child: Row(
          children: [
            // Duration info
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 12,
                  color: Colors.white.withAlpha(204),
                ),
                const SizedBox(width: 4),
                Text(
                  '${duration.toStringAsFixed(1)}s',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Asset indicators
            _buildAssetIndicators(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetIndicators(ThemeData theme) {
    return Row(
      children: [
        // Image indicator
        _buildAssetIndicator(
          icon: Icons.image,
          hasAsset: clip.hasGeneratedImage,
        ),
        const SizedBox(width: 4),
        // Video indicator
        _buildAssetIndicator(
          icon: Icons.videocam,
          hasAsset: clip.hasGeneratedVideo,
        ),
        const SizedBox(width: 4),
        // Audio indicator
        _buildAssetIndicator(
          icon: Icons.audiotrack,
          hasAsset: clip.hasGeneratedSpeechAudio,
        ),
      ],
    );
  }

  Widget _buildAssetIndicator({
    required IconData icon,
    required bool hasAsset,
  }) {
    return Icon(
      icon,
      size: 12,
      color: hasAsset ? Colors.white : Colors.white.withAlpha(100),
    );
  }
}
