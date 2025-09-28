import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/models/asset.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoEditMode extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onVideoSaved;
  final VoidCallback? onCloseEditor;

  const VideoEditMode({
    super.key,
    required this.asset,
    this.onVideoSaved,
    this.onCloseEditor,
  });

  @override
  State<VideoEditMode> createState() => _VideoEditModeState();
}

class _VideoEditModeState extends State<VideoEditMode> {
  /// Video editor configuration settings.
  late final VideoEditorConfigs _videoConfigs = const VideoEditorConfigs(
    initialMuted: false,
    initialPlay: false,
    isAudioSupported: true,
    minTrimDuration: Duration(seconds: 1),
  );

  /// The target format for the exported video.
  final _outputFormat = VideoOutputFormat.mp4;

  /// Indicates whether a seek operation is in progress.
  bool _isSeeking = false;

  /// Stores the currently selected trim duration span.
  TrimDurationSpan? _durationSpan;

  /// Temporarily stores a pending trim duration span.
  TrimDurationSpan? _tempDurationSpan;

  /// Controls video playback and trimming functionalities.
  ProVideoController? _proVideoController;

  /// Stores generated thumbnails for the trimmer bar and filter background.
  List<ImageProvider>? _thumbnails;

  /// Holds information about the selected video.
  VideoMetadata? _videoMetadata;

  /// Number of thumbnails to generate across the video timeline.
  final int _thumbnailCount = 7;

  /// The video currently loaded in the editor.
  EditorVideo? _video;

  String? outputPath;

  /// The duration it took to generate the exported video.
  Duration videoGenerationTime = Duration.zero;

  VideoPlayerController? _videoController;
  File? _tempVideoFile;

  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
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

  /// Loads and sets [_videoMetadata] for the given [_video].
  Future<void> _setMetadata() async {
    if (_video != null) {
      _videoMetadata = await ProVideoEditor.instance.getMetadata(_video!);
    }
  }

  /// Generates thumbnails for the given [_video].
  void _generateThumbnails() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _video == null) return;

      var imageWidth =
          MediaQuery.sizeOf(context).width /
          _thumbnailCount *
          MediaQuery.devicePixelRatioOf(context);

      List<Uint8List> thumbnailList = [];

      /// On android `getKeyFrames` is a way faster than `getThumbnails` but
      /// the timestamps are more "random". If you want the best results i
      /// recommend you to use only `getThumbnails`.
      if (!kIsWeb && Platform.isAndroid) {
        thumbnailList = await ProVideoEditor.instance.getKeyFrames(
          KeyFramesConfigs(
            video: _video!,
            outputSize: Size.square(imageWidth),
            boxFit: ThumbnailBoxFit.cover,
            maxOutputFrames: _thumbnailCount,
            outputFormat: ThumbnailFormat.jpeg,
          ),
        );
      } else {
        final duration = _videoMetadata?.duration ?? Duration.zero;
        final segmentDuration = duration.inMilliseconds / _thumbnailCount;

        thumbnailList = await ProVideoEditor.instance.getThumbnails(
          ThumbnailConfigs(
            video: _video!,
            outputSize: Size.square(imageWidth),
            boxFit: ThumbnailBoxFit.cover,
            timestamps: List.generate(_thumbnailCount, (i) {
              final midpointMs = (i + 0.5) * segmentDuration;
              return Duration(milliseconds: midpointMs.round());
            }),
            outputFormat: ThumbnailFormat.jpeg,
          ),
        );
      }

      List<ImageProvider> temporaryThumbnails = thumbnailList
          .map(MemoryImage.new)
          .toList();

      /// Optional precache every thumbnail
      var cacheList = temporaryThumbnails.map(
        (item) => precacheImage(item, context),
      );
      await Future.wait(cacheList);
      _thumbnails = temporaryThumbnails;

      if (_proVideoController != null) {
        _proVideoController!.thumbnails = _thumbnails;
      }
    });
  }

  Future<void> _initializeEditor() async {
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
          'edit_video_${DateTime.now().millisecondsSinceEpoch}.${widget.asset.extension}',
        ),
      );

      await tempFile.writeAsBytes(videoBytes);
      _tempVideoFile = tempFile;

      // Create EditorVideo from the file
      _video = EditorVideo.file(tempFile);

      await _setMetadata();
      _generateThumbnails();

      // Initialize video player
      _videoController = VideoPlayerController.file(tempFile);

      await Future.wait([
        _videoController!.initialize(),
        _videoController!.setLooping(false),
        _videoController!.setVolume(_videoConfigs.initialMuted ? 0 : 100),
        _videoConfigs.initialPlay
            ? _videoController!.play()
            : _videoController!.pause(),
      ]);

      if (!mounted) return;

      if (_videoController!.value.isInitialized && _videoMetadata != null) {
        _proVideoController = ProVideoController(
          videoPlayer: _buildVideoPlayer(),
          initialResolution: _videoMetadata!.resolution,
          videoDuration: _videoMetadata!.duration,
          fileSize: _videoMetadata!.fileSize,
          thumbnails: _thumbnails,
        );

        _videoController!.addListener(_onDurationChange);

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize video editor: $e';
        });
      }
    }
  }

  void _onDurationChange() {
    if (_videoMetadata == null || _proVideoController == null) return;

    var totalVideoDuration = _videoMetadata!.duration;
    var duration = _videoController!.value.position;
    _proVideoController!.setPlayTime(duration);

    if (_durationSpan != null && duration >= _durationSpan!.end) {
      _seekToPosition(_durationSpan!);
    } else if (duration >= totalVideoDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;

    if (_isSeeking) {
      _tempDurationSpan = span; // Store the latest seek request
      return;
    }
    _isSeeking = true;

    _proVideoController!.pause();
    _proVideoController!.setPlayTime(_durationSpan!.start);

    await _videoController!.pause();
    await _videoController!.seekTo(span.start);

    _isSeeking = false;

    // Check if there's a pending seek request
    if (_tempDurationSpan != null) {
      TrimDurationSpan nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null; // Clear the pending seek
      await _seekToPosition(nextSeek); // Process the latest request
    }
  }

  /// Generates the final video based on the given [parameters].
  Future<void> generateVideo(CompleteParameters parameters) async {
    final stopwatch = Stopwatch()..start();

    unawaited(_videoController!.pause());

    var exportModel = RenderVideoModel(
      id: _taskId,
      video: _video!,
      outputFormat: _outputFormat,
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      imageBytes: parameters.layers.isNotEmpty ? parameters.image : null,
      blur: parameters.blur,
      colorMatrixList: parameters.colorFilters,
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: parameters.isTransformed
          ? ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
    );

    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now().millisecondsSinceEpoch;
      outputPath = await ProVideoEditor.instance.renderVideoToFile(
        '${directory.path}/edited_video_$now.mp4',
        exportModel,
      );
      videoGenerationTime = stopwatch.elapsed;

      Get.snackbar(
        'Success',
        'Video exported successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      widget.onVideoSaved?.call();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Closes the video editor and opens a preview screen if a video was
  /// exported.
  void onCloseEditor(EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);

    // For now, just close the editor
    widget.onCloseEditor?.call();
    Navigator.pop(context);
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.size.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _buildEditor(),
    );
  }

  final _editor = GlobalKey<ProImageEditorState>();

  Widget _buildEditor() {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Edit ${widget.asset.displayName}'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Center(
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
                _errorMessage ?? 'Failed to load video editor',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeEditor,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading || _proVideoController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Edit ${widget.asset.displayName}'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading video editor...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return ProImageEditor.video(
      _proVideoController!,
      key: _editor,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: generateVideo,
        onCloseEditor: onCloseEditor,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController!.pause,
          onPlay: _videoController!.play,
          onMuteToggle: (isMuted) {
            _videoController!.setVolume(isMuted ? 0 : 100);
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController!.value.isPlaying) {
              _proVideoController!.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
      ),
      configs: ProImageEditorConfigs(
        dialogConfigs: DialogConfigs(
          widgets: DialogWidgets(
            loadingDialog: (message, configs) => StreamBuilder<ProgressModel>(
              stream: ProVideoEditor.instance.progressStream,
              builder: (context, snapshot) {
                var progress = snapshot.data?.progress ?? 0;
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text(message),
                      if (progress > 0) Text('${(progress * 100).toInt()}%'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        paintEditor: const PaintEditorConfigs(
          /// Blur and pixelate are not supported.
          enableModePixelate: false,
          enableModeBlur: false,
        ),
        videoEditor: _videoConfigs.copyWith(
          playTimeSmoothingDuration: const Duration(milliseconds: 600),
        ),
      ),
    );
  }
}
