import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/enums/asset_status.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/workspace.dart';
import 'package:meadow/widgets/shared/generation_metadata_viewer.dart';
import 'package:meadow/widgets/editor/media_detail.dart';

class AssetGridItem extends StatefulWidget {
  final Asset asset;
  const AssetGridItem({super.key, required this.asset});

  @override
  State<AssetGridItem> createState() => _AssetGridItemState();
}

class _AssetGridItemState extends State<AssetGridItem> {
  Asset get asset => widget.asset;

  bool get _hasGenerationMetadata {
    if (asset is LocalAsset) {
      final metadata = (asset as LocalAsset).metadata;
      return metadata.containsKey('type') && metadata.containsKey('prompt');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final status = asset.status;

    Widget content;
    if (status == AssetStatus.completed) {
      content = _buildAssetContent(context);
    } else if (status == AssetStatus.processing) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (status == AssetStatus.pending) {
      content = Center(
        child: Icon(Icons.schedule, size: 36, color: Colors.amber[700]),
      );
    } else if (status == AssetStatus.failed) {
      content = Center(
        child: Icon(Icons.error_outline, size: 36, color: Colors.red[400]),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return InkWell(
      onTap: status == AssetStatus.completed
          ? () {
              // Open asset in modal dialog
              _openAssetDialog(context, asset);
            }
          : null,
      child: GridTile(
        header: GridTileBar(
          // backgroundColor: Colors.black45,
          title: Text(''),
          /*title: Text(
            asset.displayName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),*/
          trailing: PopupMenuButton<String>(
            icon: const Icon(
              CupertinoIcons.ellipsis_circle,
              size: 18,
              color: Colors.white,
            ),
            itemBuilder: (context) => [
              // Asset details section
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDateTime(asset.createdAt)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (asset.lastModified != asset.createdAt)
                      Text(
                        'Modified: ${_formatDateTime(asset.lastModified)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (asset is LocalAsset && _hasGenerationTimestamp())
                      Text(
                        'Generated: ${_getGenerationTimestamp()}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (asset.sizeBytes != null)
                      Text(
                        'Size: ${_formatFileSize(asset.sizeBytes!)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (_hasGenerationMetadata)
                const PopupMenuItem(
                  value: 'view_metadata',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 8),
                      Text('View Generation Metadata'),
                    ],
                  ),
                ),
              if (_hasGenerationMetadata) const PopupMenuDivider(),
              if (asset is LocalAsset)
                const PopupMenuItem(
                  value: 'open_folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Open Containing Folder'),
                    ],
                  ),
                ),
              if (asset is LocalAsset) const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Move to...'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Copy to...'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'view_metadata':
                  await _viewGenerationMetadata(context);
                  break;
                case 'open_folder':
                  await _openContainingFolder(context);
                  break;
                case 'rename':
                  await _renameAsset(context);
                  break;
                case 'move':
                  await _moveAsset(context);
                  break;
                case 'copy':
                  await _copyAsset(context);
                  break;
                case 'delete':
                  await _deleteAsset(context);
                  break;
              }
            },
          ),
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: content,
        ),
      ),
    );
  }

  Widget _buildAssetContent(BuildContext context) {
    // For LocalAsset, use thumbnails when available
    if (asset is LocalAsset) {
      return _buildLocalAssetContent(context, asset as LocalAsset);
    }

    // Fallback to original implementation for other asset types
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          getIconForAssetType(asset.type),
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        if (asset.type == AssetType.image)
          Image(
            image: asset.getImageProvider(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image_outlined, size: 40),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLocalAssetContent(BuildContext context, LocalAsset localAsset) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background icon
        Icon(
          getIconForAssetType(localAsset.type),
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        // Thumbnail or original image
        FutureBuilder<ImageProvider?>(
          future: localAsset.getThumbnailImageProvider(),
          builder: (context, snapshot) {
            ImageProvider? imageProvider;

            if (snapshot.hasData && snapshot.data != null) {
              // Use thumbnail if available
              imageProvider = snapshot.data!;
            } else {
              // Fallback to original for images, use thumbnail provider for others
              imageProvider = localAsset.getThumbnailProvider();
            }

            if (imageProvider != null) {
              return Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      getIconForAssetType(localAsset.type),
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              );
            }

            // Show loading indicator while thumbnail is being generated
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getIconForAssetType(localAsset.type),
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              );
            }

            // Fallback to icon only
            return Center(
              child: Icon(
                getIconForAssetType(localAsset.type),
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _renameAsset(BuildContext context) async {
    final controller = TextEditingController(text: asset.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Asset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Asset Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != asset.displayName) {
      try {
        final workspaceController = Get.find<WorkspaceController>();
        await workspaceController.renameAsset(asset.id, newName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset renamed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error renaming asset: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewGenerationMetadata(BuildContext context) async {
    if (asset is! LocalAsset) return;

    final localAsset = asset as LocalAsset;
    final metadata = localAsset.metadata;

    if (metadata.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No generation metadata found')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenerationMetadataViewer(metadata: metadata),
      ),
    );
  }

  Future<void> _openContainingFolder(BuildContext context) async {
    if (asset is! LocalAsset) return;

    final localAsset = asset as LocalAsset;
    final filePath = localAsset.file.path;

    try {
      final file = File(filePath);
      final directory = file.parent;

      if (Platform.isMacOS) {
        // Use 'open -R' to reveal the file in Finder on macOS
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isWindows) {
        // Use 'explorer /select,' to select the file in File Explorer on Windows
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        // Use 'xdg-open' command to open file manager on Linux
        // Note: Not all Linux file managers support file selection
        await Process.run('xdg-open', [directory.path]);
      } else {
        throw UnsupportedError('Platform not supported');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened containing folder')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening folder: $e')),
        );
      }
    }
  }

  Future<void> _deleteAsset(BuildContext context) async {
    try {
      final workspaceController = Get.find<WorkspaceController>();
      await workspaceController.deleteAsset(asset.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting asset: $e'),
          ),
        );
      }
    }
  }

  Future<void> _moveAsset(BuildContext context) async {
    final workspaceController = Get.find<WorkspaceController>();
    final availableWorkspaces = workspaceController.availableWorkspaces
        .where((ws) => ws != workspaceController.currentWorkspace.value)
        .toList();

    if (availableWorkspaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other workspaces available'),
        ),
      );
      return;
    }

    final targetWorkspace = await showDialog<Workspace>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${asset.displayName}" to...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableWorkspaces.length,
            itemBuilder: (context, index) {
              final workspace = availableWorkspaces[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(workspace.name),
                onTap: () => Navigator.of(context).pop(workspace),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (targetWorkspace != null) {
      try {
        await workspaceController.moveAsset(asset, targetWorkspace);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Asset moved to "${targetWorkspace.name}" successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error moving asset: $e')),
          );
        }
      }
    }
  }

  Future<void> _copyAsset(BuildContext context) async {
    final workspaceController = Get.find<WorkspaceController>();
    final availableWorkspaces = workspaceController.availableWorkspaces
        .where((ws) => ws != workspaceController.currentWorkspace.value)
        .toList();

    if (availableWorkspaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other workspaces available'),
        ),
      );
      return;
    }

    final targetWorkspace = await showDialog<Workspace>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy "${asset.displayName}" to...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableWorkspaces.length,
            itemBuilder: (context, index) {
              final workspace = availableWorkspaces[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(workspace.name),
                onTap: () => Navigator.of(context).pop(workspace),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (targetWorkspace != null) {
      try {
        await workspaceController.copyAsset(asset, targetWorkspace);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Asset copied to "${targetWorkspace.name}" successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error copying asset: $e')),
          );
        }
      }
    }
  }

  bool _hasGenerationTimestamp() {
    if (asset is! LocalAsset) return false;
    final localAsset = asset as LocalAsset;
    final metadata = localAsset.metadata;
    return metadata.containsKey('createdAt') ||
        metadata.containsKey('addedAt') ||
        metadata.containsKey('generation');
  }

  String _getGenerationTimestamp() {
    if (asset is! LocalAsset) return '';
    final localAsset = asset as LocalAsset;
    final metadata = localAsset.metadata;

    // Try different timestamp fields
    if (metadata['createdAt'] != null) {
      try {
        final dateTime = DateTime.parse(metadata['createdAt']);
        return _formatDateTime(dateTime);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    if (metadata['addedAt'] != null) {
      try {
        final dateTime = DateTime.parse(metadata['addedAt']);
        return _formatDateTime(dateTime);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    return _formatDateTime(asset.createdAt);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _openAssetDialog(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(asset.displayName),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: MediaDetailTab(asset: asset),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
