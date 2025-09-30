import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/simple_checkpoint.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';
import 'package:meadow/widgets/tasks/task.dart';

/// Image generation options sheet
class ImageGenerationSheet extends StatelessWidget {
  final VideoClip clip;
  final GenerationContext context;
  final Function(VideoClip) onUpdate;
  final Function({
    required ComfyUIWorkflow workflow,
    required String ext,
    required String assetType,
    Map<String, dynamic>? metadata,
    Task? existingTask,
  })
  generateAssetWithUpdate;

  const ImageGenerationSheet({
    super.key,
    required this.clip,
    required this.context,
    required this.onUpdate,
    required this.generateAssetWithUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image Generation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Generate from prompt
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Generate from Image Prompt'),
            subtitle: Text(clip.imagePrompt),
            onTap: () {
              Navigator.pop(context);
              _generateImageFromPrompt();
            },
          ),

          const Divider(),

          // Select existing asset
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Select Existing Image'),
            subtitle: const Text('Choose from workspace assets'),
            onTap: () {
              Navigator.pop(context);
              _selectExistingImage(context);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _generateImageFromPrompt() async {
    final tasksController = Get.find<TasksController>();

    final workflow = await simpleCheckpointWorkflow(
      prompt: clip.imagePrompt,
      negativePrompt: "",
      width: context.mediaWidth,
      height: context.mediaHeight,
    );

    final task = Task(
      workflow: workflow,
      description: 'Generating image for clip',
      metadata: {'prompt': clip.imagePrompt},
    );

    tasksController.addTask(task);

    // Custom generation with clip update callback
    generateAssetWithUpdate(
      workflow: workflow,
      ext: 'png',
      metadata: {'prompt': clip.imagePrompt},
      existingTask: task,
      assetType: 'image',
    );
  }

  void _selectExistingImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AssetSelector(
        assetType: AssetType.image,
        onAssetSelected: (asset) {
          if (asset != null) {
            // Convert Asset to file path and update clip
            final filePath = (asset as LocalAsset).file.path;
            final updatedClip = clip.copyWith(generatedImagePath: filePath);
            onUpdate(updatedClip);
          }
        },
      ),
    );
  }
}
