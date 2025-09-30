import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/integrations/comfyui/services/comfyui_api_service.dart';

class ImageOptionsDialog extends StatefulWidget {
  final int initialWidth;
  final int initialHeight;
  final int? initialSeed;
  final String initialModel;

  const ImageOptionsDialog({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    this.initialSeed,
    required this.initialModel,
  });

  @override
  State<ImageOptionsDialog> createState() => ImageOptionsDialogState();
}

class ImageOptionsDialogState extends State<ImageOptionsDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _seedController;
  late String _selectedModel;

  final List<String> _availableModels = [
    'dreamshaper_lightning.safetensors',
  ];

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.initialWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.initialHeight.toString(),
    );
    _seedController = TextEditingController(
      text: widget.initialSeed?.toString() ?? '',
    );
    _selectedModel = widget.initialModel;

    try {
      var apiService = Get.find<ComfyUIAPIService>();
      apiService.getModels('checkpoints').then((models) {
        setState(() {
          _availableModels.clear();
          _availableModels.addAll(models);
          if (!_availableModels.contains(_selectedModel) &&
              _availableModels.isNotEmpty) {
            _selectedModel = _availableModels.first;
          }
        });
      });
    } catch (e) {
      debugPrint('Error fetching models: $e');
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.image, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Text('Image Options'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seedController,
              decoration: const InputDecoration(
                labelText: 'Seed (optional)',
                hintText: 'Leave empty for random',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              items: _availableModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.replaceAll('.safetensors', '')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedModel = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final width = int.tryParse(_widthController.text);
            final height = int.tryParse(_heightController.text);
            final seed = _seedController.text.isEmpty
                ? null
                : int.tryParse(_seedController.text);

            if (width != null && height != null) {
              Navigator.of(context).pop({
                'width': width,
                'height': height,
                'seed': seed,
                'model': _selectedModel,
              });
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
