import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/editor/audio_view/audio_view_mode.dart';
import 'package:meadow/widgets/editor/audio_view/audio_edit_mode.dart';
import 'package:flutter/material.dart';

enum AudioDetailMode { view, edit }

class AudioDetailTab extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onAudioSaved;

  const AudioDetailTab({
    super.key,
    required this.asset,
    this.onAudioSaved,
  });

  @override
  State<AudioDetailTab> createState() => _AudioDetailTabState();
}

class _AudioDetailTabState extends State<AudioDetailTab> {
  AudioDetailMode _mode = AudioDetailMode.view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget content;
    switch (_mode) {
      case AudioDetailMode.view:
        content = AudioViewMode(
          asset: widget.asset,
          onEditModeSelected: () {
            setState(() {
              _mode = AudioDetailMode.edit;
            });
          },
        );
        break;
      case AudioDetailMode.edit:
        content = AudioEditMode(
          asset: widget.asset,
          onAudioSaved: widget.onAudioSaved,
          onCloseEditor: () {
            setState(() {
              _mode = AudioDetailMode.view;
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
