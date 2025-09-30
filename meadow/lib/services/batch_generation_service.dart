import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/simple_checkpoint.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/tts_workflow.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/wan_i2v.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';

/// Simplified batch generation service
class BatchGenerationService {
  /// Generate missing assets for a video transcript
  static Future<void> generateMissingAssets({
    required VideoTranscript transcript,
    required Function(VideoClip, int) onClipUpdated,
    Function(String)? onStatusUpdate,
    Function(double)? onProgressUpdate,
  }) async {
    final generationContext = GenerationContext.fromTranscript(transcript);

    // Find clips that need assets
    final clipsNeedingAssets = <int, VideoClip>{};
    for (int i = 0; i < transcript.clips.length; i++) {
      final clip = transcript.clips[i];
      if (clip.readinessStatus != ClipReadinessStatus.ready) {
        clipsNeedingAssets[i] = clip;
      }
    }

    if (clipsNeedingAssets.isEmpty) {
      onStatusUpdate?.call('No assets to generate');
      onProgressUpdate?.call(1.0);
      return;
    }

    int totalAssets = 0;
    int completedAssets = 0;

    // Count total assets needed
    for (final clip in clipsNeedingAssets.values) {
      totalAssets += clip.missingAssets.length;
    }

    onProgressUpdate?.call(0.0);

    // Process each clip sequentially
    for (final entry in clipsNeedingAssets.entries) {
      final clipIndex = entry.key;
      final clip = entry.value;

      onStatusUpdate?.call(
        'Processing clip ${clipIndex + 1}/${clipsNeedingAssets.length}',
      );

      // Generate missing assets for this clip
      final updatedClip = await _generateClipAssets(
        clip: clip,
        context: generationContext,
        onAssetCompleted: () {
          completedAssets++;
          onProgressUpdate?.call(completedAssets / totalAssets);
        },
      );

      // Update the clip
      onClipUpdated(updatedClip, clipIndex);
    }

    onStatusUpdate?.call('Batch generation completed');
    onProgressUpdate?.call(1.0);
  }

  /// Generate missing assets for a single clip
  static Future<VideoClip> _generateClipAssets({
    required VideoClip clip,
    required GenerationContext context,
    VoidCallback? onAssetCompleted,
  }) async {
    var updatedClip = clip;

    // Generate image if missing
    if (clip.missingAssets.contains('Image')) {
      try {
        await generateAsset(
          workflow: await simpleCheckpointWorkflow(
            prompt: clip.imagePrompt,
            height: context.mediaHeight,
            width: context.mediaWidth,
            seed: clip.imagePrompt.hashCode,
          ),
          ext: 'png',
          metadata: {
            'type': 'image',
            'prompt': clip.imagePrompt,
            'width': context.mediaWidth,
            'height': context.mediaHeight,
            'transcript_id': context.transcriptId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        // In a real implementation, you would find the generated asset
        // and update the clip with the actual asset reference
        onAssetCompleted?.call();
      } catch (e) {
        debugPrint('Failed to generate image for clip: $e');
      }
    }

    // Generate speech if missing
    if (clip.missingAssets.contains('Speech Audio') && clip.speech != null) {
      try {
        await generateAsset(
          workflow: await ttsWorkflow(
            text: clip.speech!,
          ),
          ext: 'mp3',
          metadata: {
            'type': 'speech',
            'text': clip.speech!,
            'transcript_id': context.transcriptId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        // In a real implementation, you would find the generated asset
        // and update the clip with the actual asset reference
        onAssetCompleted?.call();
      } catch (e) {
        debugPrint('Failed to generate speech for clip: $e');
      }
    }

    // Generate video if missing
    if (clip.missingAssets.contains('Video')) {
      try {
        await generateAsset(
          workflow: await videoWorkflow(
            prompt: '${clip.imagePrompt}, ${clip.videoPrompt}',
            refImage: clip.hasGeneratedImage
                ? await clip.generatedImageFile!.readAsBytes()
                : null,
            width: context.mediaWidth,
            height: context.mediaHeight,
            durationSeconds: context.clipLengthSeconds,
          ),
          ext: 'mp4',
          metadata: {
            'type': 'video',
            'image_prompt': clip.imagePrompt,
            'video_prompt': clip.videoPrompt,
            'transcript_id': context.transcriptId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        // In a real implementation, you would find the generated asset
        // and update the clip with the actual asset reference
        onAssetCompleted?.call();
      } catch (e) {
        debugPrint('Failed to generate video for clip: $e');
      }
    }

    return updatedClip;
  }
}
