import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/simple_checkpoint.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/wan_i2v.dart';

class GenerationMetadataViewer extends StatefulWidget {
  final Map<String, dynamic> metadata;

  const GenerationMetadataViewer({
    super.key,
    required this.metadata,
  });

  @override
  State<GenerationMetadataViewer> createState() =>
      _GenerationMetadataViewerState();
}

class _GenerationMetadataViewerState extends State<GenerationMetadataViewer> {
  Map<String, bool> selectedParams = {};
  late TextEditingController _promptController;
  late TextEditingController _negativePromptController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _seedController;
  late TextEditingController _stepsController;
  late TextEditingController _cfgController;
  late TextEditingController _durationController;
  late TextEditingController _fpsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeSelectedParams();
  }

  void _initializeControllers() {
    // Use simplified metadata format directly
    final metadata = widget.metadata;

    _promptController = TextEditingController(
      text: metadata['prompt']?.toString() ?? '',
    );
    _negativePromptController = TextEditingController(
      text: metadata['negative_prompt']?.toString() ?? '',
    );
    _widthController = TextEditingController(
      text: metadata['width']?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: metadata['height']?.toString() ?? '',
    );
    _seedController = TextEditingController(
      text: metadata['seed']?.toString() ?? '',
    );
    _stepsController = TextEditingController(
      text: metadata['steps']?.toString() ?? '',
    );
    _cfgController = TextEditingController(
      text: metadata['cfg']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: metadata['duration_seconds']?.toString() ?? '',
    );
    _fpsController = TextEditingController(
      text: metadata['fps']?.toString() ?? '',
    );
  }

  void _initializeSelectedParams() {
    // Use simplified metadata format directly
    final metadata = widget.metadata;

    selectedParams = {
      'prompt': true,
      'negative_prompt': metadata.containsKey('negative_prompt'),
      'width': true,
      'height': true,
      'seed': true,
      'steps': metadata.containsKey('steps'),
      'cfg': metadata.containsKey('cfg'),
      'duration': metadata.containsKey('duration_seconds'),
      'fps': metadata.containsKey('fps'),
    };
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    _stepsController.dispose();
    _cfgController.dispose();
    _durationController.dispose();
    _fpsController.dispose();
    super.dispose();
  }

  bool get _isVideoGeneration {
    return widget.metadata['type'] == 'video';
  }

  void _reproduceGeneration() async {
    // Collect selected parameters
    final selectedData = <String, dynamic>{};

    if (selectedParams['prompt'] == true) {
      selectedData['prompt'] = _promptController.text;
    }
    if (selectedParams['width'] == true) {
      selectedData['width'] = int.tryParse(_widthController.text) ?? 1024;
    }
    if (selectedParams['height'] == true) {
      selectedData['height'] = int.tryParse(_heightController.text) ?? 1024;
    }
    if (selectedParams['seed'] == true) {
      selectedData['seed'] = int.tryParse(_seedController.text);
    }

    if (_isVideoGeneration) {
      // Video generation reproduction
      if (selectedParams['duration'] == true) {
        selectedData['durationSeconds'] =
            int.tryParse(_durationController.text) ?? 5;
      }
      if (selectedParams['fps'] == true) {
        selectedData['fps'] = int.tryParse(_fpsController.text) ?? 24;
      }

      generateAsset(
        ext: 'mp4',
        workflow: await videoWorkflow(
          prompt: selectedData['prompt'] ?? '',
          seed:
              selectedData['seed'] ??
              DateTime.now().millisecondsSinceEpoch % 2147483647,
          width: selectedData['width'] ?? 1280,
          height: selectedData['height'] ?? 704,
          durationSeconds: selectedData['durationSeconds'] ?? 5,
          fps: selectedData['fps'] ?? 24,
        ),
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'video',
          'prompt': selectedData['prompt'] ?? '',
          'seed':
              selectedData['seed'] ??
              DateTime.now().millisecondsSinceEpoch % 2147483647,
          'width': selectedData['width'] ?? 1280,
          'height': selectedData['height'] ?? 704,
          'duration_seconds': selectedData['durationSeconds'] ?? 5,
          'fps': selectedData['fps'] ?? 24,
          'frame_count':
              (selectedData['durationSeconds'] ?? 5) *
              (selectedData['fps'] ?? 24),
          'reproduced_from': widget.metadata['created_at'],
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      // Image generation reproduction
      if (selectedParams['negative_prompt'] == true) {
        selectedData['negative_prompt'] = _negativePromptController.text;
      }
      if (selectedParams['steps'] == true) {
        selectedData['steps'] = int.tryParse(_stepsController.text) ?? 4;
      }
      if (selectedParams['cfg'] == true) {
        selectedData['cfg'] = double.tryParse(_cfgController.text) ?? 2.0;
      }

      generateAsset(
        ext: 'png',
        workflow: await simpleCheckpointWorkflow(
          prompt: selectedData['prompt'] ?? '',
          height: selectedData['height'] ?? 1024,
          width: selectedData['width'] ?? 1024,
          seed: selectedData['seed'],
          steps: selectedData['steps'],
          cfg: selectedData['cfg'],
          negativePrompt: selectedData['negative_prompt'],
        ),
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'image',
          'prompt': selectedData['prompt'] ?? '',
          'width': selectedData['width'] ?? 1024,
          'height': selectedData['height'] ?? 1024,
          'seed':
              selectedData['seed'] ??
              DateTime.now().millisecondsSinceEpoch % 2147483647,
          'negative_prompt':
              selectedData['negative_prompt'] ??
              'blurry, bokeh, depth of field',
          'model':
              widget.metadata['model'] ?? 'dreamshaper_lightning.safetensors',
          'reproduced_from': widget.metadata['created_at'],
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }

    // Show success message
    Get.snackbar(
      'Generation Started',
      'Reproducing ${_isVideoGeneration ? 'video' : 'image'} with selected parameters',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
    );
  }

  Widget _buildParameterTile({
    required String label,
    required String paramKey,
    required TextEditingController controller,
    String? subtitle,
  }) {
    return Card(
      child: CheckboxListTile(
        title: Text(label),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: selectedParams[paramKey] ?? false,
        onChanged: (value) {
          setState(() {
            selectedParams[paramKey] = value ?? false;
          });
        },
        secondary: SizedBox(
          width: 120,
          child: TextFormField(
            controller: controller,
            enabled: selectedParams[paramKey] ?? false,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $label to clipboard')),
                  );
                },
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generationType = widget.metadata['type'] ?? 'unknown';
    final model = widget.metadata['model'] ?? 'Unknown Model';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generation Metadata - ${generationType.toString().toUpperCase()}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              setState(() {
                selectedParams.updateAll((key, value) => true);
              });
            },
            tooltip: 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                selectedParams.updateAll((key, value) => false);
              });
            },
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Model and type info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model: $model',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Type: ${generationType.toString().toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.metadata['created_at'] != null)
                  Text(
                    'Generated: ${widget.metadata['created_at']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),

          // Parameters list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildParameterTile(
                  label: 'Prompt',
                  paramKey: 'prompt',
                  controller: _promptController,
                  subtitle: 'The text prompt used for generation',
                ),

                if (!_isVideoGeneration &&
                    _negativePromptController.text.isNotEmpty)
                  _buildParameterTile(
                    label: 'Negative Prompt',
                    paramKey: 'negative_prompt',
                    controller: _negativePromptController,
                    subtitle: 'What to avoid in the generation',
                  ),

                _buildParameterTile(
                  label: 'Width',
                  paramKey: 'width',
                  controller: _widthController,
                  subtitle: 'Width in pixels',
                ),

                _buildParameterTile(
                  label: 'Height',
                  paramKey: 'height',
                  controller: _heightController,
                  subtitle: 'Height in pixels',
                ),

                _buildParameterTile(
                  label: 'Seed',
                  paramKey: 'seed',
                  controller: _seedController,
                  subtitle: 'Random seed for reproducibility',
                ),

                if (!_isVideoGeneration && _stepsController.text.isNotEmpty)
                  _buildParameterTile(
                    label: 'Steps',
                    paramKey: 'steps',
                    controller: _stepsController,
                    subtitle: 'Number of denoising steps',
                  ),

                if (!_isVideoGeneration && _cfgController.text.isNotEmpty)
                  _buildParameterTile(
                    label: 'CFG Scale',
                    paramKey: 'cfg',
                    controller: _cfgController,
                    subtitle: 'Classifier-free guidance scale',
                  ),

                if (_isVideoGeneration && _durationController.text.isNotEmpty)
                  _buildParameterTile(
                    label: 'Duration (seconds)',
                    paramKey: 'duration',
                    controller: _durationController,
                    subtitle: 'Video length in seconds',
                  ),

                if (_isVideoGeneration && _fpsController.text.isNotEmpty)
                  _buildParameterTile(
                    label: 'FPS',
                    paramKey: 'fps',
                    controller: _fpsController,
                    subtitle: 'Frames per second',
                  ),
              ],
            ),
          ),
        ],
      ),

      // Reproduce button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: selectedParams.values.any((selected) => selected)
              ? _reproduceGeneration
              : null,
          icon: const Icon(Icons.replay),
          label: Text('Reproduce ${_isVideoGeneration ? 'Video' : 'Image'}'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
