import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/models/asset.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioEditMode extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onAudioSaved;
  final VoidCallback? onCloseEditor;

  const AudioEditMode({
    super.key,
    required this.asset,
    this.onAudioSaved,
    this.onCloseEditor,
  });

  @override
  State<AudioEditMode> createState() => _AudioEditModeState();
}

class _AudioEditModeState extends State<AudioEditMode> {
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isExporting = false;
  File? _tempAudioFile;

  // Basic editing parameters
  double _volume = 1.0;
  double _speed = 1.0;
  bool _isLooping = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
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

  Future<void> _initializeEditor() async {
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
          'edit_audio_${DateTime.now().millisecondsSinceEpoch}${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(audioBytes);
      _tempAudioFile = tempFile;

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(tempFile.path);

      // Listen to state changes
      _audioPlayer!.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
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

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
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
          _errorMessage = 'Failed to initialize audio editor: $e';
        });
      }
    }
  }

  Future<void> _saveAudio() async {
    if (_tempAudioFile == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // For now, we'll just save a copy of the original audio
      // In a full implementation, this would use FFmpeg to apply edits

      final audioBytes = await widget.asset.getBytes();
      final tempDir = await getTemporaryDirectory();
      final editedFile = File(
        path.join(
          tempDir.path,
          'edited_${DateTime.now().millisecondsSinceEpoch}${widget.asset.extension}',
        ),
      );

      await editedFile.writeAsBytes(audioBytes);

      Get.snackbar(
        'Success',
        'Audio saved! Note: Advanced editing features require FFmpeg integration.',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        widget.onAudioSaved?.call();
        widget.onCloseEditor?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        Get.snackbar(
          'Error',
          'Save failed: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  Future<void> _seekTo(Duration position) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  Future<void> _setVolume(double volume) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.setVolume(volume);
      setState(() {
        _volume = volume;
      });
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> _setSpeed(double speed) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.setSpeed(speed);
      setState(() {
        _speed = speed;
      });
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  Future<void> _setLooping(bool loop) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      setState(() {
        _isLooping = loop;
      });
    } catch (e) {
      debugPrint('Error setting loop: $e');
    }
  }

  Widget _buildEditor() {
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
              _errorMessage ?? 'Failed to load audio editor',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeEditor,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading || _audioPlayer == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading audio editor...'),
          ],
        ),
      );
    }

    if (_isExporting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Saving audio...'),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Audio preview area
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio visualizer placeholder
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPlaying ? Icons.music_note : Icons.music_off,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.asset.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPlaying ? 'Playing' : 'Paused',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (value * _duration.inMilliseconds)
                              .round(),
                        );
                        _seekTo(position);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      final newPosition =
                          _position - const Duration(seconds: 10);
                      _seekTo(
                        newPosition < Duration.zero
                            ? Duration.zero
                            : newPosition,
                      );
                    },
                    iconSize: 36,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _togglePlayPause,
                      iconSize: 48,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final newPosition =
                          _position + const Duration(seconds: 10);
                      _seekTo(
                        newPosition > _duration ? _duration : newPosition,
                      );
                    },
                    iconSize: 36,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Editing controls sidebar
        Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
          ),
          child: _buildEditingControls(),
        ),
      ],
    );
  }

  Widget _buildEditingControls() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio Editor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Editor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a basic audio editor. For advanced features like trimming, effects, and format conversion, FFmpeg integration would be needed.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Volume control
          Text(
            'Volume',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _volume,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: '${(_volume * 100).round()}%',
            onChanged: _setVolume,
          ),

          const SizedBox(height: 24),

          // Speed control
          Text(
            'Playback Speed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            label: '${_speed.toStringAsFixed(1)}x',
            onChanged: _setSpeed,
          ),

          const SizedBox(height: 24),

          // Looping control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loop',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Switch(
                value: _isLooping,
                onChanged: _setLooping,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Audio info
          Text(
            'Audio Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Duration: ${_formatDuration(_duration)}'),
          Text('Format: ${widget.asset.extension}'),
          if (widget.asset.sizeBytes != null)
            Text(
              'Size: ${(widget.asset.sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB',
            ),

          const SizedBox(height: 32),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _saveAudio,
                icon: const Icon(Icons.save),
                label: const Text('Save Audio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.onCloseEditor,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit ${widget.asset.displayName}'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: _buildEditor(),
    );
  }
}
