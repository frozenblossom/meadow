import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/wan_i2v.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/services/prompt_preferences_service.dart';
import 'package:meadow/widgets/inputs/image_input.dart';

class VideoPromptBar extends StatefulWidget {
  const VideoPromptBar({super.key});

  @override
  State<VideoPromptBar> createState() => _VideoPromptBarState();
}

class _VideoPromptBarState extends State<VideoPromptBar> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  Asset? initialImage;

  @override
  void initState() {
    super.initState();
    _loadSavedPrompt();
  }

  /// Load the last saved video prompt
  Future<void> _loadSavedPrompt() async {
    final savedPrompt = await PromptPreferencesService.instance
        .getVideoPrompt();
    if (savedPrompt != null && savedPrompt.isNotEmpty) {
      _controller.text = savedPrompt;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGenerate() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle generate action
      final prompt = _controller.text;
      final workspace = Get.find<WorkspaceController>().currentWorkspace.value;

      // Save the prompt for next time
      PromptPreferencesService.instance.saveVideoPrompt(prompt);

      // Generate a random seed for reproducibility
      final seed = DateTime.now().millisecondsSinceEpoch % 2147483647;

      // Get generation parameters
      final width = workspace?.defaultWidth ?? 1280;
      final height = workspace?.defaultHeight ?? 704;
      final durationSeconds = workspace?.videoDurationSeconds ?? 5;
      final fps = 24; // Default fps
      final frameCount = durationSeconds * fps;

      // Debug: Check if initialImage is available and get bytes
      Uint8List? refImageBytes;
      if (initialImage != null) {
        try {
          refImageBytes = await initialImage!.getBytes();
        } catch (e) {
          Get.snackbar('Error', 'Error loading reference image: $e');
        }
      } else {}

      generateAsset(
        ext: 'mp4',
        workflow: videoWorkflow(
          prompt: prompt,
          seed: seed,
          width: width,
          height: height,
          durationSeconds: durationSeconds,
          fps: fps,
          refImage: refImageBytes,
        ),
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'video',
          'prompt': prompt,
          'seed': seed,
          'width': width,
          'height': height,
          'duration_seconds': durationSeconds,
          'fps': fps,
          'frame_count': frameCount,
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
          ImageInput(
            onChanged: (image) {
              setState(() {
                initialImage = image;
              });
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
