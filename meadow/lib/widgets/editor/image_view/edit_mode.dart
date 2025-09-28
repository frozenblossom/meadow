import 'package:meadow/models/asset.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class ImageDetailEditMode extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onImageSaved;
  final VoidCallback? onCloseEditor;

  const ImageDetailEditMode({
    super.key,
    required this.asset,
    this.onImageSaved,
    this.onCloseEditor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.getBytes(),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: ProImageEditor.memory(
              asyncSnapshot.data!,
              configs: ProImageEditorConfigs(
                theme: Theme.of(context),
                i18n: const I18n(
                  done: 'Save',
                  cancel: 'Cancel',
                ),
              ),
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (bytes) async {
                  try {
                    await asset.save(bytes);

                    Get.snackbar(
                      'Success',
                      'Image saved successfully',
                      snackPosition: SnackPosition.BOTTOM,
                    );

                    onImageSaved?.call();
                    onCloseEditor?.call();
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to save image: $e',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                onCloseEditor: (mode) {
                  onCloseEditor?.call();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
