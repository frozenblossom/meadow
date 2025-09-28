import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/simple_checkpoint.dart';
import 'package:meadow/services/prompt_preferences_service.dart';

class ImagePromptBar extends StatefulWidget {
  const ImagePromptBar({super.key});

  @override
  State<ImagePromptBar> createState() => _ImagePromptBarState();
}

class _ImagePromptBarState extends State<ImagePromptBar> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPrompt();
  }

  /// Load the last saved image prompt
  Future<void> _loadSavedPrompt() async {
    final savedPrompt = await PromptPreferencesService.instance
        .getImagePrompt();
    if (savedPrompt != null && savedPrompt.isNotEmpty) {
      _controller.text = savedPrompt;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGenerate() {
    if (_formKey.currentState?.validate() ?? false) {
      final prompt = _controller.text;
      final workspace = Get.find<WorkspaceController>().currentWorkspace.value;

      // Save the prompt for next time
      PromptPreferencesService.instance.saveImagePrompt(prompt);

      // Generate a random seed for reproducibility
      final seed = Random().nextInt(1 << 32);

      final width = workspace?.defaultWidth ?? 1024;
      final height = workspace?.defaultHeight ?? 1024;

      generateAsset(
        ext: 'png',
        workflow: simpleCheckpointWorkflow(
          prompt: prompt,
          height: height,
          width: width,
          seed: seed,
        ),
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'image',
          'prompt': prompt,
          'width': width,
          'height': height,
          'seed': seed,
          'model': 'dreamshaper_lightning.safetensors',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a prompt';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onGenerate,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
