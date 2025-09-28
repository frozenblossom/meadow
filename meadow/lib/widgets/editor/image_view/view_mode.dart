import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/detail_face.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/swap_face.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/upscale.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/local_asset.dart';

class ViewMode extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onEditModeSelected;

  const ViewMode({
    super.key,
    required this.asset,
    this.onEditModeSelected,
  });

  @override
  State<ViewMode> createState() => _ViewModeState();
}

class _ViewModeState extends State<ViewMode> {
  final PhotoViewScaleStateController scaleController =
      PhotoViewScaleStateController();
  Uint8List? _imageBytes;
  Uint8List? _originalImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final bytes = await widget.asset.getBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _originalImageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          'Failed to load image: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Widget _buildSidebarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: theme.colorScheme.primary),
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          side: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) return;

    try {
      await widget.asset.save(_imageBytes!);

      Get.snackbar(
        'Success',
        'Image saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveCopy() async {
    if (_imageBytes == null) return;

    try {
      // Create a copy with a new name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final copyName = '${widget.asset.displayName}_copy_$timestamp';

      // Save as temporary file first
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/$copyName${widget.asset.extension}',
      );
      await tempFile.writeAsBytes(_imageBytes!);

      // Add to local asset service
      final copyAsset = await LocalAsset.fromPath(tempFile.path);
      await copyAsset.updateMetadata({
        'originalAssetId': widget.asset.id,
        'copyOf': widget.asset.displayName,
      });

      Get.snackbar(
        'Success',
        'Copy saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save copy: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Helper to compare Uint8List
    bool listEquals(Uint8List a, Uint8List b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    bool showComparison =
        _originalImageBytes != null &&
        _imageBytes != null &&
        !listEquals(_originalImageBytes!, _imageBytes!);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : showComparison
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Original',
                              style: theme.textTheme.labelMedium,
                            ),
                            Expanded(
                              child: PhotoView(
                                imageProvider: MemoryImage(
                                  _originalImageBytes!,
                                ),
                                scaleStateController: scaleController,
                                backgroundDecoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Edited', style: theme.textTheme.labelMedium),
                            Expanded(
                              child: PhotoView(
                                imageProvider: MemoryImage(_imageBytes!),
                                scaleStateController: scaleController,
                                backgroundDecoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : (_imageBytes != null
                      ? PhotoView(
                          imageProvider: MemoryImage(_imageBytes!),
                          scaleStateController: scaleController,
                          backgroundDecoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        )
                      : PhotoView(
                          imageProvider: widget.asset.getImageProvider(),
                          scaleStateController: scaleController,
                          backgroundDecoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        )),
          ),
          const SizedBox(height: 8.0),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(120),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(16.0),

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSidebarActionButton(
                    icon: Icons.save,
                    label: "Save",
                    onTap: _saveImage,
                  ),
                  _buildSidebarActionButton(
                    icon: Icons.save,
                    label: "Save Copy",
                    onTap: _saveCopy,
                  ),

                  _buildSidebarActionButton(
                    icon: Icons.edit_outlined,
                    label: "Edit",
                    onTap: widget.onEditModeSelected,
                  ),
                  _buildSidebarActionButton(
                    icon: Icons.save,
                    label: "Detail Face",
                    onTap: () {
                      runWorkflow(
                        detailFaceWorkflow(
                          prompt: 'detailed face, detailed skin',
                          initialImage: _imageBytes!,
                        ),
                      );
                    },
                  ),
                  _buildSidebarActionButton(
                    icon: Icons.save,
                    label: "Swap Face",
                    onTap: () async {
                      Asset? asset;
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AssetSelector(
                            onAssetSelected: (selectedAsset) {
                              asset = selectedAsset;
                            },
                          );
                        },
                      );

                      if (asset == null) {
                        return;
                      }

                      runWorkflow(
                        swapfaceWorkflow(
                          face: await asset!.getBytes(),
                          image: _imageBytes!,
                        ),
                      );
                    },
                  ),
                  _buildSidebarActionButton(
                    icon: Icons.arrow_outward_sharp,
                    label: "Upscale 2x",
                    onTap: () {
                      runWorkflow(
                        ultimateUpscaleWorkflow(
                          image: _imageBytes!,
                          scaleFactor: 2,
                        ),
                      );
                    },
                  ),

                  _buildSidebarActionButton(
                    icon: Icons.info_outline,
                    label: "Info",
                    onTap: () => _showImageInfo(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageInfo() async {
    var img = decodeImage(_imageBytes!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.asset.displayName}'),
            Text('Type: ${widget.asset.type.name}'),
            if (widget.asset.sizeBytes != null)
              Text(
                'Size: ${(widget.asset.sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB',
              ),
            Text(
              'Created: ${widget.asset.createdAt.toString().split('.')[0]}',
            ),
            Text('Extension: ${widget.asset.extension}'),
            Text('Status: ${widget.asset.status.name}'),
            if (img != null) ...[
              Text('Dimension: ${img.width} x ${img.height}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }

  void runWorkflow(ComfyUIWorkflow workflow) async {
    // Invoke workflow
    final resultUrl = await workflow.invoke();

    var path = p.join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
    await Dio().download(
      resultUrl,
      path,
    );
    if (mounted) {
      setState(() {
        _imageBytes = File(path).readAsBytesSync();
      });
    }

    // Clean up
    await File(path).delete();
  }
}
