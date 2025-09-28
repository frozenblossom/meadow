import 'package:flutter/material.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/widgets/video_transcript/video_clip_card.dart';

/// Full-screen detailed view of a video clip for mobile devices
class VideoClipDetailPage extends StatelessWidget {
  final VideoClip clip;
  final GenerationContext generationContext;
  final int clipIndex;
  final double duration;
  final VoidCallback onRegenerate;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final Function(VideoClip) onClipUpdated;
  final Function(VideoClip)? onClipPromptsUpdated;

  const VideoClipDetailPage({
    super.key,
    required this.clip,
    required this.generationContext,
    required this.clipIndex,
    required this.duration,
    required this.onRegenerate,
    required this.onEdit,
    this.onDelete,
    required this.onClipUpdated,
    this.onClipPromptsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clip ${clipIndex + 1}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: VideoClipCard(
          clip: clip,
          generationContext: generationContext,
          clipIndex: clipIndex,
          duration: duration,
          onRegenerate: onRegenerate,
          onEdit: onEdit,
          onDelete: onDelete,
          onClipUpdated: onClipUpdated,
          onClipPromptsUpdated: onClipPromptsUpdated,
        ),
      ),
    );
  }
}
