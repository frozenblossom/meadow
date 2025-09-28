import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:meadow/models/asset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Video view mode widget that supports the unified Asset system
class VideoViewMode extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onEditModeSelected;

  const VideoViewMode({
    super.key,
    required this.asset,
    this.onEditModeSelected,
  });

  @override
  State<VideoViewMode> createState() => _VideoViewModeState();
}

class _VideoViewModeState extends State<VideoViewMode> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  File? _tempVideoFile;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempVideoFile != null && await _tempVideoFile!.exists()) {
      try {
        await _tempVideoFile!.delete();
      } catch (e) {
        debugPrint('Failed to clean up temp video file: $e');
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get video bytes and create a temporary file
      final videoBytes = await widget.asset.getBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        path.join(
          tempDir.path,
          'temp_video_${DateTime.now().millisecondsSinceEpoch}${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(videoBytes);
      _tempVideoFile = tempFile;

      // Initialize video player
      _videoController = VideoPlayerController.file(tempFile);
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Listen to playback state changes
      _videoController!.addListener(_onVideoStateChanged);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (_videoController != null && mounted) {
      final isPlaying = _videoController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _seekTo(Duration position) {
    _videoController?.seekTo(position);
  }

  Widget _buildVideoPlayer() {
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
              _errorMessage ?? 'Failed to load video',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeVideo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Video player
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  // Play/pause overlay
                  AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Video controls
        _buildVideoControls(),
      ],
    );
  }

  Widget _buildVideoControls() {
    if (_videoController == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final currentPosition = _videoController!.value.position;
                  final newPosition =
                      currentPosition - const Duration(seconds: 10);
                  _seekTo(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlayPause,
                iconSize: 36,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  final currentPosition = _videoController!.value.position;
                  final duration = _videoController!.value.duration;
                  final newPosition =
                      currentPosition + const Duration(seconds: 10);
                  _seekTo(newPosition > duration ? duration : newPosition);
                },
              ),
            ],
          ),
          // Duration display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_videoController!.value.position)),
              Text(_formatDuration(_videoController!.value.duration)),
            ],
          ),
        ],
      ),
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
            onTap: _shareVideo,
          ),
          const SizedBox(height: 16),
          _buildSidebarActionButton(
            icon: Icons.info_outline,
            label: 'Info',
            onTap: _showVideoInfo,
          ),
        ],
      ),
    );
  }

  Future<void> _saveCopy() async {
    try {
      final videoBytes = await widget.asset.getBytes();

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        path.join(
          tempDir.path,
          'copy_${DateTime.now().millisecondsSinceEpoch}${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(videoBytes);

      Get.snackbar(
        'Success',
        'Video copy saved successfully!',
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

  Future<void> _shareVideo() async {
    Get.snackbar(
      'Info',
      'Share functionality coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Information'),
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
            if (_videoController != null) ...[
              Text(
                'Duration: ${_formatDuration(_videoController!.value.duration)}',
              ),
              Text(
                'Resolution: ${_videoController!.value.size.width.toInt()}x${_videoController!.value.size.height.toInt()}',
              ),
            ],
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
        Expanded(child: _buildVideoPlayer()),
        _buildSidebar(),
      ],
    );
  }
}
