import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/controllers/workspace_controller.dart';

class AssetTypeInfo {
  final String name;
  final FileType fileType;
  final List<String>? extensions;
  final IconData icon;

  AssetTypeInfo({
    required this.name,
    required this.fileType,
    this.extensions,
    required this.icon,
  });
}

class AssetSelector extends StatelessWidget {
  final ValueChanged<Asset?> onAssetSelected;
  final AssetType assetType;

  const AssetSelector({
    super.key,
    required this.onAssetSelected,
    this.assetType = AssetType.image,
  });

  AssetTypeInfo _getAssetTypeInfo(AssetType type) {
    switch (type) {
      case AssetType.image:
        return AssetTypeInfo(
          name: 'Image',
          fileType: FileType.image,
          icon: Icons.image,
        );
      case AssetType.video:
        return AssetTypeInfo(
          name: 'Video',
          fileType: FileType.video,
          icon: Icons.videocam,
        );
      case AssetType.audio:
        return AssetTypeInfo(
          name: 'Audio',
          fileType: FileType.audio,
          icon: Icons.audiotrack,
        );
      default:
        return AssetTypeInfo(
          name: 'File',
          fileType: FileType.any,
          icon: Icons.insert_drive_file,
        );
    }
  }

  Widget _buildAssetPreview(Asset asset, ThemeData theme) {
    switch (asset.type) {
      case AssetType.image:
        return Image(
          image: asset.getImageProvider(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPreview(theme, Icons.broken_image_outlined);
          },
        );
      case AssetType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            // For video files, try to show a thumbnail if available
            // Otherwise show a video icon
            _buildErrorPreview(theme, Icons.videocam),
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        );
      case AssetType.audio:
        return _buildErrorPreview(theme, Icons.audiotrack);
      default:
        return _buildErrorPreview(theme, Icons.insert_drive_file);
    }
  }

  Widget _buildErrorPreview(ThemeData theme, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(125),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.onSecondaryContainer,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceController = Get.find<WorkspaceController>();

    // Get asset type specific properties
    final typeInfo = _getAssetTypeInfo(assetType);

    return AlertDialog(
      title: Text('Select ${typeInfo.name} Asset'),
      actions: [
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final result = await FilePicker.platform.pickFiles(
                type: typeInfo.fileType,
                allowedExtensions: typeInfo.extensions,
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);

                var asset = await workspaceController.addAssetFromFile(
                  file,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${typeInfo.name} added to assets and selected.",
                      ),
                    ),
                  );
                  // Select the newly added asset (last in the list)
                  onAssetSelected(asset);

                  Get.back(result: asset);
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error adding ${typeInfo.name.toLowerCase()}: $e',
                    ),
                  ),
                );
              }
            }
          },
          icon: Icon(typeInfo.icon),
          label: Text('Add New ${typeInfo.name}'),
        ),
        TextButton(
          onPressed: () {
            onAssetSelected(null);
            Get.back();
          },
          child: const Text('Cancel'),
        ),
      ],
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Obx(() {
          final filteredAssets = workspaceController.assets
              .where((a) => a.type == assetType)
              .toList();

          if (workspaceController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (filteredAssets.isEmpty) {
            return Center(
              child: Text(
                'No ${typeInfo.name.toLowerCase()} assets found.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.0,
            ),
            itemCount: filteredAssets.length,
            itemBuilder: (gbCtx, index) {
              final asset = filteredAssets[index];
              return InkWell(
                onTap: () {
                  onAssetSelected(asset);
                  Get.back(result: asset);
                },
                borderRadius: BorderRadius.circular(8.0),
                child: GridTile(
                  footer: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      asset.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _buildAssetPreview(asset, theme),
                  ),
                ),
              );
            },
          );
        }),
      ),
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}
