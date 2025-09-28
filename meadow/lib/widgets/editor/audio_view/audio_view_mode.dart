import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meadow/models/asset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Audio view mode widget that supports the unified Asset system
class AudioViewMode extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onEditModeSelected;

  const AudioViewMode({
    super.key,
    required this.asset,
    this.onEditModeSelected,
  });

  @override
  State<AudioViewMode> createState() => _AudioViewModeState();
}

class _AudioViewModeState extends State<AudioViewMode> {
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLooping = false;
  File? _tempAudioFile;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempAudioFile != null && await _tempAudioFile!.exists()) {
      try {
        await _tempAudioFile!.delete();
      } catch (e) {
        debugPrint('Failed to clean up temp audio file: $e');
      }
    }
  }

  Future<void> _initializeAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get audio bytes and create a temporary file
      final audioBytes = await widget.asset.getBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        path.join(
          tempDir.path,
          'temp_audio_${DateTime.now().millisecondsSinceEpoch}.${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(audioBytes);
      _tempAudioFile = tempFile;

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(tempFile.path);

      // Listen to state changes
      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer!.playingStream.listen((isPlaying) {
        if (mounted) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });

      _audioPlayer!.loopModeStream.listen((loopMode) {
        if (mounted) {
          setState(() {
            _isLooping = loopMode == LoopMode.one;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load audio: $e';
        });
      }
    }
  }

  void _togglePlayPause() async {
    if (_audioPlayer != null) {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    }
  }

  void _seekTo(Duration position) async {
    await _audioPlayer?.seek(position);
  }

  void _toggleLooping() async {
    if (_audioPlayer != null) {
      final newLoopMode = _isLooping ? LoopMode.off : LoopMode.one;
      await _audioPlayer!.setLoopMode(newLoopMode);
    }
  }

  void _skipForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    final clampedPosition = newPosition > _duration ? _duration : newPosition;
    _seekTo(clampedPosition);
  }

  void _skipBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : newPosition;
    _seekTo(clampedPosition);
  }

  Widget _buildAudioPlayer() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load audio',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeAudio,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio visualizer/artwork placeholder
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(75),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audiotrack,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.asset.displayName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Audio File',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Progress slider
        _buildProgressSlider(),
        const SizedBox(height: 20),
        // Time display
        _buildTimeDisplay(),
        const SizedBox(height: 30),
        // Control buttons
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildProgressSlider() {
    return SizedBox(
      width: 350,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          trackHeight: 4,
        ),
        child: Slider(
          value: _duration.inMilliseconds > 0
              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(
                  0.0,
                  1.0,
                )
              : 0.0,
          onChanged: (value) {
            final newPosition = Duration(
              milliseconds: (_duration.inMilliseconds * value).round(),
            );
            _seekTo(newPosition);
          },
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return SizedBox(
      width: 350,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(_position),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            _formatDuration(_duration),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            _isLooping ? Icons.repeat_one : Icons.repeat,
            color: _isLooping
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(153),
          ),
          onPressed: _toggleLooping,
          iconSize: 28,
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: _skipBackward,
          iconSize: 32,
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _togglePlayPause,
            iconSize: 40,
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: _skipForward,
          iconSize: 32,
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Widget _buildSidebarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebarActionButton(
            icon: Icons.edit,
            label: 'Edit',
            onTap: widget.onEditModeSelected,
          ),
          const SizedBox(height: 16),
          _buildSidebarActionButton(
            icon: Icons.download,
            label: 'Save Copy',
            onTap: _saveCopy,
          ),
          const SizedBox(height: 16),
          _buildSidebarActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _shareAudio,
          ),
          const SizedBox(height: 16),
          _buildSidebarActionButton(
            icon: Icons.info_outline,
            label: 'Info',
            onTap: _showAudioInfo,
          ),
        ],
      ),
    );
  }

  Future<void> _saveCopy() async {
    try {
      final audioBytes = await widget.asset.getBytes();

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        path.join(
          tempDir.path,
          'copy_${DateTime.now().millisecondsSinceEpoch}${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(audioBytes);

      Get.snackbar(
        'Success',
        'Audio copy saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save copy: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _shareAudio() async {
    Get.snackbar(
      'Info',
      'Share functionality coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showAudioInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.asset.displayName}'),
            Text('Type: ${widget.asset.type.name}'),
            if (widget.asset.sizeBytes != null)
              Text(
                'Size: ${(widget.asset.sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB',
              ),
            Text(
              'Created: ${widget.asset.createdAt.toString().split('.')[0]}',
            ),
            Text('Duration: ${_formatDuration(_duration)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildAudioPlayer()),
        _buildSidebar(),
      ],
    );
  }
}
