import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/controllers/video_transcript_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/acestep_workflow.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/generation_context.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/services/background_video_assembly_service.dart';
import 'package:meadow/services/background_batch_generation_service.dart';
import 'package:meadow/widgets/shared/asset_selector.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:meadow/widgets/video_transcript/video_clip_card.dart';
import 'package:meadow/widgets/video_transcript/video_clip_detail_page.dart';
import 'package:meadow/widgets/video_transcript/video_clip_thumbnail.dart';
import 'package:meadow/widgets/video_transcript/video_transcript_form.dart';

class VideoTranscriptViewer extends StatefulWidget {
  final VideoTranscript transcript;

  const VideoTranscriptViewer({
    super.key,
    required this.transcript,
  });

  @override
  State<VideoTranscriptViewer> createState() => _VideoTranscriptViewerState();
}

class _VideoTranscriptViewerState extends State<VideoTranscriptViewer> {
  late VideoTranscript _transcript;
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transcript = widget.transcript;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoTranscriptController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withAlpha(100),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _transcript.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcript.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addNewClip,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Clip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _showShareDialog,
                tooltip: 'Export',
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_title',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Title'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_properties',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Properties'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'background_music',
                    child: Row(
                      children: [
                        Icon(Icons.music_note, size: 16),
                        SizedBox(width: 8),
                        Text('Background Music'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'batch_generate',
                    child: Row(
                      children: [
                        Icon(Icons.auto_fix_high, size: 16),
                        SizedBox(width: 8),
                        Text('Generate Missing Assets'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'video_assembly',
                    child: Row(
                      children: [
                        Icon(Icons.video_library, size: 16),
                        SizedBox(width: 8),
                        Text('Assemble Video'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'regenerate_all',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 8),
                        Text('Regenerate All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit_title':
                      _editTitle();
                      break;
                    case 'edit_properties':
                      _editProperties();
                      break;
                    case 'background_music':
                      _showBackgroundMusicOptions();
                      break;
                    case 'batch_generate':
                      _batchGenerateMissingAssets();
                      break;
                    case 'video_assembly':
                      _showVideoAssemblyDialog();
                      break;
                    case 'regenerate_all':
                      _regenerateAll();
                      break;
                    case 'delete':
                      _deleteTranscript();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
        // Readiness Summary
        _buildReadinessSummary(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating clips...'),
                  ],
                ),
              );
            }

            // Get the latest version of the transcript
            final latestTranscript =
                controller.getTranscript(_transcript.id) ?? _transcript;

            return Column(
              children: [
                if (controller.errorMessage.value.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: theme.colorScheme.errorContainer,
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                _buildTranscriptInfo(latestTranscript, theme),
                _buildClipsHint(theme),
                Expanded(
                  child: _buildClipsList(latestTranscript, controller),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTranscriptInfo(VideoTranscript transcript, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transcript.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.timer,
                label: '${transcript.durationSeconds}s',
                theme: theme,
              ),
              _buildInfoChip(
                icon: Icons.video_library,
                label: '${transcript.clips.length} clips',
                theme: theme,
              ),
              if (transcript.generateSpeech)
                _buildInfoChip(
                  icon: Icons.record_voice_over,
                  label: 'Speech',
                  theme: theme,
                ),
              if (transcript.generateMusic)
                _buildInfoChip(
                  icon: Icons.music_note,
                  label: 'Music',
                  theme: theme,
                ),
            ],
          ),
          if (transcript.backgroundMusic != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Background Music',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transcript.backgroundMusic!.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipsHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Tap to view details • Drag to reorder clips',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipsList(
    VideoTranscript transcript,
    VideoTranscriptController controller,
  ) {
    // Use different column counts based on screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        // Generate children for ReorderableBuilder
        final generatedChildren = List.generate(
          transcript.clips.length,
          (index) {
            final clip = transcript.clips[index];
            final duration = transcript.getClipDuration(index);

            // Create a more unique key using clip content hash
            final uniqueKey =
                '${clip.imagePrompt.hashCode}_${clip.videoPrompt.hashCode}_$index';

            return VideoClipThumbnail(
              key: Key(uniqueKey),
              clip: clip,
              clipIndex: index,
              duration: duration,
              onTap: () => _showClipDetail(
                context,
                clip,
                transcript,
                index,
                duration,
              ),
            );
          },
        );

        return ReorderableBuilder(
          scrollController: _scrollController,
          enableLongPress: true,
          longPressDelay: const Duration(milliseconds: 500),
          enableDraggable: true,
          enableScrollingWhileDragging: true,
          onReorder: (ReorderedListFunction reorderedListFunction) {
            _reorderClips(reorderedListFunction);
          },
          builder: (children) {
            return GridView(
              key: _gridViewKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: children,
            );
          },
          children: generatedChildren,
        );
      },
    );
  }

  void _showClipDetail(
    BuildContext context,
    VideoClip clip,
    VideoTranscript transcript,
    int clipIndex,
    double duration,
  ) {
    final generationContext = GenerationContext.fromTranscript(transcript);

    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Navigate to a new page on mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoClipDetailPage(
            clip: clip,
            generationContext: generationContext,
            clipIndex: clipIndex,
            duration: duration,
            onRegenerate: () {
              Navigator.of(context).pop();
              _regenerateClip(clipIndex);
            },
            onEdit: () {
              Navigator.of(context).pop();
              _editClip(clipIndex);
            },
            onDelete: () {
              Navigator.of(context).pop();
              _deleteClip(clipIndex);
            },
            onClipUpdated: (updatedClip) {
              _updateClipAssets(clipIndex, updatedClip);
            },
            onClipPromptsUpdated: (updatedClip) {
              _updateClipPrompts(clipIndex, updatedClip);
            },
          ),
        ),
      );
    } else {
      // Show dialog on desktop/tablet
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(100),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Clip ${clipIndex + 1}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Dialog content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: VideoClipCard(
                      clip: clip,
                      generationContext: generationContext,
                      clipIndex: clipIndex,
                      duration: duration,
                      onRegenerate: () {
                        Navigator.of(context).pop();
                        _regenerateClip(clipIndex);
                      },
                      onEdit: () {
                        Navigator.of(context).pop();
                        _editClip(clipIndex);
                      },
                      onDelete: () {
                        Navigator.of(context).pop();
                        _deleteClip(clipIndex);
                      },
                      onClipUpdated: (updatedClip) {
                        _updateClipAssets(clipIndex, updatedClip);
                      },
                      onClipPromptsUpdated: (updatedClip) {
                        _updateClipPrompts(clipIndex, updatedClip);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _reorderClips(ReorderedListFunction reorderedListFunction) async {
    // Create a new list with reordered clips
    final reorderedClips =
        reorderedListFunction(_transcript.clips) as List<VideoClip>;

    // Update the transcript with reordered clips
    final updatedTranscript = _transcript.copyWith(
      clips: reorderedClips,
      lastModified: DateTime.now(),
    );

    // Update local state immediately for responsive UI
    setState(() {
      _transcript = updatedTranscript;
    });

    // Save to backend
    try {
      final controller = Get.find<VideoTranscriptController>();
      await controller.updateTranscript(updatedTranscript);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save clip order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _regenerateClip(int clipIndex) async {
    final controller = Get.find<VideoTranscriptController>();

    final success = await controller.regenerateClip(
      transcriptId: _transcript.id,
      clipIndex: clipIndex,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clip regenerated successfully')),
      );
    }
  }

  void _editClip(int clipIndex) async {
    final clip = _transcript.clips[clipIndex];
    final imagePromptController = TextEditingController(text: clip.imagePrompt);
    final videoPromptController = TextEditingController(text: clip.videoPrompt);
    final speechController = TextEditingController(text: clip.speech ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Clip ${clipIndex + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: imagePromptController,
                decoration: const InputDecoration(
                  labelText: 'Image Prompt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: videoPromptController,
                decoration: const InputDecoration(
                  labelText: 'Video Prompt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (_transcript.generateSpeech) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: speechController,
                  decoration: const InputDecoration(
                    labelText: 'Speech Text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'imagePrompt': imagePromptController.text,
                'videoPrompt': videoPromptController.text,
                'speech': speechController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final controller = Get.find<VideoTranscriptController>();
      await controller.updateClip(
        transcriptId: _transcript.id,
        clipIndex: clipIndex,
        imagePrompt: result['imagePrompt']!,
        videoPrompt: result['videoPrompt']!,
        speech: result['speech'],
      );

      // Refresh the transcript
      final updatedTranscript = controller.getTranscript(_transcript.id);
      if (updatedTranscript != null) {
        setState(() {
          _transcript = updatedTranscript;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clip ${clipIndex + 1} updated successfully')),
        );
      }
    }

    imagePromptController.dispose();
    videoPromptController.dispose();
    speechController.dispose();
  }

  void _editTitle() async {
    final controller = TextEditingController(text: _transcript.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != _transcript.title) {
      await Get.find<VideoTranscriptController>().updateTranscriptProperties(
        transcriptId: _transcript.id,
        title: newTitle,
      );
      setState(() {
        _transcript = _transcript.copyWith(title: newTitle);
      });
    }
  }

  void _editProperties() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => VideoTranscriptForm(transcript: _transcript),
      ),
    );

    if (result == true) {
      // Refresh the transcript after successful edit
      final controller = Get.find<VideoTranscriptController>();
      final updatedTranscript = controller.getTranscript(_transcript.id);
      if (updatedTranscript != null) {
        setState(() {
          _transcript = updatedTranscript;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcript properties updated successfully'),
          ),
        );
      }
    }
  }

  void _regenerateAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate All Clips'),
        content: const Text(
          'This will regenerate all clips with new prompts. The current clips will be replaced. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = Get.find<VideoTranscriptController>();

      // Generate a completely new transcript
      final newTranscript = await controller.generateTranscript(
        title: _transcript.title,
        description: _transcript.description,
        durationSeconds: _transcript.durationSeconds,
        generateSpeech: _transcript.generateSpeech,
        generateMusic: _transcript.generateMusic,
      );

      if (newTranscript != null) {
        // Delete the old transcript and update with new one
        await controller.deleteTranscript(_transcript.id);
        setState(() {
          _transcript = newTranscript;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All clips regenerated successfully')),
          );
        }
      }
    }
  }

  void _deleteTranscript() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transcript'),
        content: Text(
          'Are you sure you want to delete "${_transcript.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Get.find<VideoTranscriptController>().deleteTranscript(
        _transcript.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _updateClipAssets(int clipIndex, VideoClip updatedClip) async {
    // Update the clip in the transcript
    final updatedClips = List<VideoClip>.from(_transcript.clips);
    updatedClips[clipIndex] = updatedClip;

    final updatedTranscript = _transcript.copyWith(
      clips: updatedClips,
      lastModified: DateTime.now(),
    );

    // Update the local state immediately for responsive UI
    if (mounted) {
      setState(() {
        _transcript = updatedTranscript;
      });
    }

    // Save to backend using the controller
    try {
      final controller = Get.find<VideoTranscriptController>();
      await controller.updateClipAssets(
        transcriptId: _transcript.id,
        clipIndex: clipIndex,
        updatedClip: updatedClip,
      );
    } catch (e) {
      // Show error if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save asset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateClipPrompts(int clipIndex, VideoClip updatedClip) async {
    // Update the local state immediately for responsive UI
    final updatedClips = List<VideoClip>.from(_transcript.clips);
    updatedClips[clipIndex] = updatedClip;

    final updatedTranscript = _transcript.copyWith(
      clips: updatedClips,
      lastModified: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _transcript = updatedTranscript;
      });
    }

    // Save to backend using the controller's updateClip method
    try {
      final controller = Get.find<VideoTranscriptController>();
      await controller.updateClip(
        transcriptId: _transcript.id,
        clipIndex: clipIndex,
        imagePrompt: updatedClip.imagePrompt,
        videoPrompt: updatedClip.videoPrompt,
        speech: updatedClip.speech,
      );
    } catch (e) {
      // Show error if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBackgroundMusicOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BackgroundMusicSheet(
        transcript: _transcript,
        onUpdate: _updateBackgroundMusic,
      ),
    );
  }

  void _updateBackgroundMusic(Asset? musicAsset) async {
    // Update the local state immediately for responsive UI
    setState(() {
      _transcript = _transcript.copyWith(backgroundMusic: musicAsset);
    });

    // Save to backend using the controller
    try {
      final controller = Get.find<VideoTranscriptController>();
      await controller.updateTranscript(_transcript);
    } catch (e) {
      // Show error if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save background music: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareDialog() {
    final controller = Get.find<VideoTranscriptController>();
    final latestTranscript =
        controller.getTranscript(_transcript.id) ?? _transcript;

    // Calculate readiness stats
    int readyClips = 0;
    for (final clip in latestTranscript.clips) {
      if (clip.readinessStatus == ClipReadinessStatus.ready) {
        readyClips++;
      }
    }

    final totalClips = latestTranscript.clips.length;
    final canExportVideo = readyClips > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose export format:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Export readiness summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canExportVideo
                    ? Colors.green.withAlpha(50)
                    : Colors.orange.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canExportVideo ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canExportVideo ? Icons.check_circle : Icons.warning_amber,
                    color: canExportVideo ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      canExportVideo
                          ? 'Ready: $readyClips/$totalClips clips can be exported'
                          : 'No clips ready for video export',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),

          // JSON Export
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final path = await controller.exportTranscript(_transcript.id);
              if (path != null) {
                Get.snackbar('Success', 'JSON exported to: $path');
              }
            },
            icon: const Icon(Icons.code),
            label: const Text('Export JSON'),
          ),

          // Video Export (only if clips are ready)
          if (canExportVideo)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showVideoExportDialog(readyClips, totalClips);
              },
              icon: const Icon(Icons.video_file),
              label: const Text('Export Video'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  void _showVideoExportDialog(int readyClips, int totalClips) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video export will combine $readyClips ready clips into a single video file.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            if (readyClips < totalClips) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${totalClips - readyClips} clips will be skipped (not ready)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'Export features:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Clips in current order'),
            const Text('• Background music (if set)'),
            const Text('• Speech audio overlay'),
            const Text('• HD video quality'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _startVideoExport();
            },
            icon: const Icon(Icons.video_file),
            label: const Text('Start Export'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _startVideoExport() {
    // Use the existing video assembly dialog functionality
    _showVideoAssemblyDialog();
  }

  Widget _buildReadinessSummary() {
    final controller = Get.find<VideoTranscriptController>();
    final latestTranscript =
        controller.getTranscript(_transcript.id) ?? _transcript;

    int readyClips = 0;
    int needsVideo = 0;
    int needsAssets = 0;

    for (final clip in latestTranscript.clips) {
      switch (clip.readinessStatus) {
        case ClipReadinessStatus.ready:
          readyClips++;
          break;
        case ClipReadinessStatus.needsVideo:
          needsVideo++;
          break;
        case ClipReadinessStatus.needsAssets:
          needsAssets++;
          break;
      }
    }

    final totalClips = latestTranscript.clips.length;
    final hasIncompleteClips = needsVideo > 0 || needsAssets > 0;

    if (totalClips == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hasIncompleteClips
            ? theme.colorScheme.errorContainer.withAlpha(30)
            : theme.colorScheme.primaryContainer.withAlpha(30),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasIncompleteClips ? Icons.warning_amber : Icons.check_circle,
            size: 20,
            color: hasIncompleteClips
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasIncompleteClips
                  ? 'Export readiness: $readyClips/$totalClips clips ready'
                  : 'All clips ready for export',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasIncompleteClips
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasIncompleteClips) ...[
            TextButton.icon(
              onPressed: _batchGenerateMissingAssets,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Generate Missing'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _batchGenerateMissingAssets() async {
    final controller = Get.find<VideoTranscriptController>();
    final latestTranscript =
        controller.getTranscript(_transcript.id) ?? _transcript;

    // Find clips that need assets
    final clipsNeedingAssets = latestTranscript.clips
        .where((clip) => clip.readinessStatus != ClipReadinessStatus.ready)
        .toList();

    if (clipsNeedingAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All clips are already ready for export')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Missing Assets'),
        content: Text(
          'This will generate missing assets for ${clipsNeedingAssets.length} clips. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Start batch generation as a background task
    BackgroundBatchGenerationService.startBatchGeneration(
      transcript: latestTranscript,
      onClipUpdated: (clip, index) {
        // Update the transcript when clips are updated
        setState(() {
          _transcript = controller.getTranscript(_transcript.id) ?? _transcript;
        });
      },
      onCompleted: () {
        // Refresh the local transcript data
        setState(() {
          _transcript = controller.getTranscript(_transcript.id) ?? _transcript;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch generation completed!')),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Batch generation failed: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    // Show immediate feedback that task was started
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batch generation started in background. Check the Tasks panel for progress.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showVideoAssemblyDialog() async {
    final controller = Get.find<VideoTranscriptController>();
    final latestTranscript =
        controller.getTranscript(_transcript.id) ?? _transcript;

    // Check if all clips are ready
    final readyClips = latestTranscript.clips
        .where((clip) => clip.readinessStatus == ClipReadinessStatus.ready)
        .toList();

    if (readyClips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clips are ready for video assembly')),
      );
      return;
    }

    if (readyClips.length != latestTranscript.clips.length) {
      final needsGeneration = latestTranscript.clips.length - readyClips.length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Some Clips Not Ready'),
          content: Text(
            'Only ${readyClips.length} of ${latestTranscript.clips.length} clips are ready. '
            '$needsGeneration clips still need generation.\n\n'
            'Continue with available clips only?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Start video assembly as a background task
    BackgroundVideoAssemblyService.startVideoAssembly(
      transcript: latestTranscript,
      onCompleted: (outputPath) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video assembly completed! Output: $outputPath'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video assembly failed: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    // Show immediate feedback that task was started
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video assembly started in background. Check the Tasks panel for progress.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Add a new clip to the transcript
  void _addNewClip() async {
    final controller = Get.find<VideoTranscriptController>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Adding new clip...'),
          ],
        ),
      ),
    );

    try {
      // First check if LLM service is available
      bool useLLM = false;
      try {
        useLLM = await controller.testLLMConnection();
      } catch (e) {
        // LLM not available, continue with blank prompts
        useLLM = false;
      }

      bool success;
      if (useLLM) {
        // Use LLM service to generate prompts
        success = await controller.addClip(
          transcriptId: _transcript.id,
        );
      } else {
        // Create a blank clip without LLM
        success = await controller.addBlankClip(
          transcriptId: _transcript.id,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          // Refresh the transcript from controller
          final updatedTranscript = controller.getTranscript(_transcript.id);
          if (updatedTranscript != null) {
            setState(() {
              _transcript = updatedTranscript;
            });

            // Navigate to the detail page for the new clip (last in the list)
            final newClipIndex = _transcript.clips.length - 1;
            final newClip = _transcript.clips[newClipIndex];
            final duration = _transcript.clipLengthSeconds.toDouble();

            // Navigate to detail page for editing
            _showClipDetail(
              context,
              newClip,
              _transcript,
              newClipIndex,
              duration,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                useLLM
                    ? 'New clip added with generated prompts!'
                    : 'New clip added! Please edit the prompts.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add clip: ${controller.errorMessage.value}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding clip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete a clip from the transcript
  void _deleteClip(int clipIndex) async {
    final controller = Get.find<VideoTranscriptController>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Clip'),
        content: Text(
          'Are you sure you want to delete Clip ${clipIndex + 1}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      var ctrl = Get.snackbar(
        'Deleting Clip',
        'Please wait while the clip is being deleted...',
        showProgressIndicator: true,
      );

      try {
        final success = await controller.deleteClip(
          transcriptId: _transcript.id,
          clipIndex: clipIndex,
        );

        ctrl.close();

        if (success) {
          // Refresh the transcript from controller
          final updatedTranscript = controller.getTranscript(_transcript.id);
          if (updatedTranscript != null) {
            setState(() {
              _transcript = updatedTranscript;
            });
          }

          Get.snackbar(
            'Success',
            'Clip deleted successfully!',
            backgroundColor: Colors.green,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to delete clip: ${controller.errorMessage.value}',
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Get.snackbar(
            'Error',
            'Error deleting clip: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }
}

// Background Music Options Sheet
class _BackgroundMusicSheet extends StatelessWidget {
  final VideoTranscript transcript;
  final Function(Asset?) onUpdate;

  const _BackgroundMusicSheet({
    required this.transcript,
    required this.onUpdate,
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
            'Background Music',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Current music (if any)
          if (transcript.backgroundMusic != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      transcript.backgroundMusic!.displayName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      onUpdate(null);
                    },
                    tooltip: 'Remove background music',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],

          // Generate new music
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Generate Music'),
            subtitle: Text('Create music for "${transcript.title}"'),
            onTap: () {
              Navigator.pop(context);
              _generateBackgroundMusic(context);
            },
          ),

          const Divider(),

          // Select existing asset
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Select Existing Music'),
            subtitle: const Text('Choose from workspace assets'),
            onTap: () {
              Navigator.pop(context);
              _selectExistingMusic(context);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _generateBackgroundMusic(BuildContext context) async {
    final tasksController = Get.find<TasksController>();

    // Create a prompt based on the transcript content
    final musicPrompt = _createMusicPrompt();

    final workflow = await aceStepWorkflow(
      lyrics: musicPrompt,
      genre: "cinematic",
      audioLength: transcript.durationSeconds,
    );

    final task = Task(
      workflow: workflow,
      description: 'Generating background music for ${transcript.title}',
      metadata: {'prompt': musicPrompt},
    );

    tasksController.addTask(task);

    // TODO: Implement generateAsset function call here
    // This would need to be imported from wherever it's defined
    Get.snackbar('Success', 'Music generation started! Check the tasks panel.');
  }

  void _selectExistingMusic(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AssetSelector(
        assetType: AssetType.audio,
        onAssetSelected: (asset) {
          if (asset != null) {
            onUpdate(asset);
          }
        },
      ),
    );
  }

  String _createMusicPrompt() {
    // Create a musical description based on the transcript
    String prompt = "Background music for '${transcript.title}'. ";

    if (transcript.description.isNotEmpty) {
      prompt += "Theme: ${transcript.description}. ";
    }

    prompt += "Duration: ${transcript.durationSeconds} seconds. ";
    prompt += "Style: Cinematic, atmospheric background music.";

    return prompt;
  }
}
