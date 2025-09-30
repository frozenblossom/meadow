import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/wan_i2v.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';
import 'package:meadow/widgets/tasks/task.dart';

/// Video generation options sheet
class VideoGenerationSheet extends StatelessWidget {
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

  const VideoGenerationSheet({
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
            'Video Generation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Text to video
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Generate Text-to-Video'),
            subtitle: const Text('Create video from image + video prompts'),
            onTap: () {
              Navigator.pop(context);
              _generateTextToVideo();
            },
          ),

          const Divider(),

          // Image to video (if image exists)
          if (clip.hasGeneratedImage)
            ListTile(
              leading: const Icon(Icons.transform),
              title: const Text('Generate Image-to-Video'),
              subtitle: const Text('Animate the generated image'),
              onTap: () {
                Navigator.pop(context);
                _generateImageToVideo();
              },
            ),

          if (clip.hasGeneratedImage) const Divider(),

          // Select existing asset
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Select Existing Video'),
            subtitle: const Text('Choose from workspace assets'),
            onTap: () {
              Navigator.pop(context);
              _selectExistingVideo(context);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _generateTextToVideo() async {
    final tasksController = Get.find<TasksController>();

    final workflow = await videoWorkflow(
      prompt: '${clip.imagePrompt}, ${clip.videoPrompt}',
      refImage: null, // Text-to-video mode
      width: context.mediaWidth,
      height: context.mediaHeight,
      durationSeconds: context.clipLengthSeconds,
    );

    final task = Task(
      workflow: workflow,
      description: 'Generating text-to-video for clip',
      metadata: {'prompt': '${clip.imagePrompt}, ${clip.videoPrompt}'},
    );

    tasksController.addTask(task);

    generateAssetWithUpdate(
      workflow: workflow,
      ext: 'mp4',
      metadata: {'prompt': '${clip.imagePrompt}, ${clip.videoPrompt}'},
      existingTask: task,
      assetType: 'video',
    );
  }

  void _generateImageToVideo() async {
    if (!clip.hasGeneratedImage) return;

    final tasksController = Get.find<TasksController>();

    // Read image file as bytes
    final imageBytes = await clip.generatedImageFile!.readAsBytes();

    final workflow = await videoWorkflow(
      prompt: clip.videoPrompt,
      refImage: imageBytes,
      width: context.mediaWidth,
      height: context.mediaHeight,
      durationSeconds: context.clipLengthSeconds,
    );

    final task = Task(
      workflow: workflow,
      description: 'Generating image-to-video for clip',
      metadata: {'prompt': clip.videoPrompt},
    );

    tasksController.addTask(task);

    generateAssetWithUpdate(
      workflow: workflow,
      ext: 'mp4',
      metadata: {'prompt': clip.videoPrompt},
      existingTask: task,
      assetType: 'video',
    );
  }

  void _selectExistingVideo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AssetSelector(
        assetType: AssetType.video,
        onAssetSelected: (asset) {
          if (asset != null) {
            // Convert Asset to file path and update clip
            final filePath = (asset as LocalAsset).file.path;
            final updatedClip = clip.copyWith(generatedVideoPath: filePath);
            onUpdate(updatedClip);
          }
        },
      ),
    );
  }
}
