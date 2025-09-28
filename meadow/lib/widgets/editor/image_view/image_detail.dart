import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/editor/image_view/view_mode.dart';
import 'package:meadow/widgets/editor/image_view/edit_mode.dart';
import 'package:flutter/material.dart';

enum ImageDetailMode { view, edit }

class ImageDetailTab extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onImageSaved;

  const ImageDetailTab({
    super.key,
    required this.asset,
    this.onImageSaved,
  });

  @override
  State<ImageDetailTab> createState() => _ImageDetailTabState();
}

class _ImageDetailTabState extends State<ImageDetailTab> {
  ImageDetailMode _mode = ImageDetailMode.view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget content;
    switch (_mode) {
      case ImageDetailMode.view:
        content = ViewMode(
          asset: widget.asset,
          onEditModeSelected: () {
            setState(() {
              _mode = ImageDetailMode.edit;
            });
          },
        );
        break;
      case ImageDetailMode.edit:
        content = ImageDetailEditMode(
          asset: widget.asset,
          onImageSaved: widget.onImageSaved,
          onCloseEditor: () {
            setState(() {
              _mode = ImageDetailMode.view;
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
