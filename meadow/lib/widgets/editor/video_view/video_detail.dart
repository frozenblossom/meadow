import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/editor/video_view/video_view_mode.dart';
import 'package:meadow/widgets/editor/video_view/video_edit_mode.dart';
import 'package:flutter/material.dart';

enum VideoDetailMode { view, edit }

/// Video detail view that supports the unified Asset system
class VideoDetailTab extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onVideoSaved;

  const VideoDetailTab({
    super.key,
    required this.asset,
    this.onVideoSaved,
  });

  @override
  State<VideoDetailTab> createState() => _VideoDetailTabState();
}

class _VideoDetailTabState extends State<VideoDetailTab> {
  VideoDetailMode _mode = VideoDetailMode.view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget content;
    switch (_mode) {
      case VideoDetailMode.view:
        content = VideoViewMode(
          asset: widget.asset,
          onEditModeSelected: () {
            setState(() {
              _mode = VideoDetailMode.edit;
            });
          },
        );
        break;
      case VideoDetailMode.edit:
        content = VideoEditMode(
          asset: widget.asset,
          onVideoSaved: widget.onVideoSaved,
          onCloseEditor: () {
            setState(() {
              _mode = VideoDetailMode.view;
            });
          },
        );
        break;
    }

    return Container(
      color: isDarkMode
          ? theme.colorScheme.surfaceContainerHighest.withAlpha(50)
          : theme.colorScheme.surfaceContainerHighest.withAlpha(125),
      child: Center(child: content),
    );
  }
}
