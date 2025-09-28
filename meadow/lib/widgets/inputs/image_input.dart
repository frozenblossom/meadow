import 'package:flutter/material.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';

class ImageInput extends StatefulWidget {
  const ImageInput({super.key, this.onChanged, this.initialValue});
  final Asset? initialValue;
  final ValueChanged<Asset?>? onChanged;

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  late Asset? _selectedAsset = widget.initialValue;

  @override
  void didUpdateWidget(covariant ImageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedAsset = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_selectedAsset != null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: theme.dividerColor.withAlpha(125)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: theme.hintColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: "Clear Selection",
                    onPressed: () {
                      widget.onChanged?.call(null);
                      setState(() {
                        _selectedAsset = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 180,
                    maxWidth: double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(
                      image: _selectedAsset!.getImageProvider(),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withAlpha(
                              125,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              "Error loading preview",
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Change Image"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: theme.textTheme.labelLarge,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: _showImageSourceSelectionSheet,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: _showImageSourceSelectionSheet,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12.0),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14.0),
              Text(
                'Select Initial Image',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Choose from assets or upload new',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showImageSourceSelectionSheet() {
    showDialog<Asset?>(
      context: context,
      builder: (context) {
        return AssetSelector(
          onAssetSelected: (asset) {
            if (asset != null) {
              setState(() {
                _selectedAsset = asset;
              });
            }
            widget.onChanged?.call(asset);
          },
        );
      },
    );
  }
}
