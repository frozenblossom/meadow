import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/tts_workflow.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';
import 'package:meadow/widgets/tasks/task.dart';

/// Audio generation options sheet
class AudioGenerationSheet extends StatelessWidget {
  final VideoClip clip;
  final Function(VideoClip) onUpdate;
  final Function({
    required ComfyUIWorkflow workflow,
    required String ext,
    required String assetType,
    Map<String, dynamic>? metadata,
    Task? existingTask,
  })
  generateAssetWithUpdate;

  const AudioGenerationSheet({
    super.key,
    required this.clip,
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
            'Speech Generation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Generate speech (if speech text exists)
          if (clip.speech != null)
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Generate Speech Audio'),
              subtitle: Text(clip.speech!),
              onTap: () {
                Navigator.pop(context);
                _generateSpeechAudio();
              },
            ),

          if (clip.speech != null) const Divider(),

          // Select existing asset
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Select Existing Audio'),
            subtitle: const Text('Choose from workspace assets'),
            onTap: () {
              Navigator.pop(context);
              _selectExistingAudio(context);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _generateSpeechAudio() async {
    if (clip.speech == null) return;

    final tasksController = Get.find<TasksController>();

    final workflow = ttsWorkflow(
      text: clip.speech!,
      referenceAudioPath: null,
    );

    final task = Task(
      workflow: workflow,
      description: 'Generating speech audio for clip',
      metadata: {'text': clip.speech!},
    );

    tasksController.addTask(task);

    generateAssetWithUpdate(
      workflow: workflow,
      ext: 'mp3',
      metadata: {'text': clip.speech!},
      existingTask: task,
      assetType: 'audio',
    );
  }

  void _selectExistingAudio(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AssetSelector(
        assetType: AssetType.audio,
        onAssetSelected: (asset) {
          if (asset != null) {
            // Convert Asset to file path and update clip
            final filePath = (asset as LocalAsset).file.path;
            final updatedClip = clip.copyWith(
              generatedSpeechAudioPath: filePath,
            );
            onUpdate(updatedClip);
          }
        },
      ),
    );
  }
}
