import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/app_settings_controller.dart';

class AppSettingsDialog extends StatelessWidget {
  const AppSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.put(AppSettingsController());
    final theme = Theme.of(context);
    final urlController = TextEditingController();
    final localLlmUrlController = TextEditingController();

    return AlertDialog(
      title: const Text('App Settings'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ComfyUI URL Setting
            Text(
              'ComfyUI Server',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () {
                urlController.text = settingsController.comfyuiUrl.value;
                return TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'ComfyUI URL',
                    hintText: 'http://127.0.0.1:8188',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    settingsController.setComfyUIUrl(value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Local LLM URL Setting
            Text(
              'Local LLM Server',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () {
                localLlmUrlController.text =
                    settingsController.localLlmUrl.value;
                return TextFormField(
                  controller: localLlmUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Local LLM URL',
                    hintText: 'http://127.0.0.1:5001',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    settingsController.setLocalLlmUrl(value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Image Comparison Setting
            Text(
              'Display Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => SwitchListTile(
                title: const Text('Show Image Comparison'),
                subtitle: Text(
                  'When enabled, edited images will show side-by-side comparison with the original',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                value: settingsController.showImageComparison.value,
                onChanged: (value) {
                  settingsController.setShowImageComparison(value);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
