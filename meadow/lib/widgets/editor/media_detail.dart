import 'package:meadow/models/asset.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/widgets/editor/image_view/image_detail.dart';
import 'package:meadow/widgets/editor/video_view/video_detail.dart';
import 'package:meadow/widgets/editor/audio_view/audio_detail.dart';
import 'package:flutter/material.dart';

class MediaDetailTab extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onMediaSaved;

  const MediaDetailTab({
    super.key,
    required this.asset,
    this.onMediaSaved,
  });

  @override
  Widget build(BuildContext context) {
    switch (asset.type) {
      case AssetType.image:
        return ImageDetailTab(
          asset: asset,
          onImageSaved: onMediaSaved,
        );

      case AssetType.video:
        return VideoDetailTab(
          asset: asset,
          onVideoSaved: onMediaSaved,
        );

      case AssetType.audio:
        return AudioDetailTab(
          asset: asset,
          onAudioSaved: onMediaSaved,
        );

      case AssetType.text:
        return _buildTextViewer(context);
    }
  }

  Widget _buildTextViewer(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_snippet,
            size: 80,
            color: theme.colorScheme.primary.withAlpha(153),
          ),
          const SizedBox(height: 24),
          Text(
            'Text Viewer',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Text file viewing is coming soon!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
