import 'dart:io';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';

/// Video assembly progress information
class VideoAssemblyProgress {
  final int totalSteps;
  final int currentStep;
  final String currentOperation;
  final double progressPercentage;
  final bool isCompleted;
  final String? outputPath;
  final String? errorMessage;

  VideoAssemblyProgress({
    required this.totalSteps,
    required this.currentStep,
    required this.currentOperation,
    required this.progressPercentage,
    required this.isCompleted,
    this.outputPath,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
}

/// Service for assembling video clips into a final video using FFmpeg
///
/// This service provides video assembly functionality with the following features:
/// - Video concatenation with format normalization (1920x1080, 30fps)
/// - Speech audio overlay from generated clips
/// - Background music integration with volume adjustment
/// - H.264/AAC encoding for maximum compatibility
/// - Progress tracking with detailed step-by-step feedback
///
/// Requirements:
/// - FFmpeg must be installed and accessible from command line
/// - Compatible with macOS, Windows, and Linux (when sandboxing is disabled)
/// - Supports most video formats for input clips
///
/// Output format: MP4 with H.264 video codec and AAC audio codec
class VideoAssemblyService {
  /// Assemble video clips into a final video
  static Future<VideoAssemblyProgress> assembleVideo({
    required VideoTranscript transcript,
    required Function(VideoAssemblyProgress) onProgress,
    String? outputDir,
    bool includeAudio = true,
    bool includeBackgroundMusic = true,
  }) async {
    try {
      // Step 1: Validate clips
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 1,
          currentOperation: 'Validating video clips...',
          progressPercentage: 0.1,
          isCompleted: false,
        ),
      );

      final readyClips = transcript.clips
          .where((clip) => clip.hasGeneratedVideo)
          .toList();

      if (readyClips.isEmpty) {
        return VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 1,
          currentOperation: 'Failed',
          progressPercentage: 0.0,
          isCompleted: true,
          errorMessage: 'No video clips are ready for assembly',
        );
      }

      // Step 2: Prepare output directory
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 2,
          currentOperation: 'Preparing output directory...',
          progressPercentage: 0.2,
          isCompleted: false,
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final assemblyDir = Directory(
        p.join(tempDir.path, 'video_assembly', transcript.id),
      );
      await assemblyDir.create(recursive: true);

      final finalOutputDir = outputDir != null
          ? Directory(outputDir)
          : await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(
        finalOutputDir.path,
        '${transcript.title}_$timestamp.mp4',
      );

      // Step 3: Create concat file list
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 3,
          currentOperation: 'Creating video sequence...',
          progressPercentage: 0.3,
          isCompleted: false,
        ),
      );

      final concatFilePath = p.join(assemblyDir.path, 'concat_list.txt');
      final concatFile = File(concatFilePath);

      final concatContent = StringBuffer();
      for (int i = 0; i < readyClips.length; i++) {
        final clip = readyClips[i];
        if (clip.hasGeneratedVideo) {
          // Get the video file path directly
          final videoPath = clip.generatedVideoPath!;
          concatContent.writeln("file '$videoPath'");
        }
      }

      await concatFile.writeAsString(concatContent.toString());

      // Step 4: Concatenate video clips with proper encoding
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 4,
          currentOperation: 'Concatenating video clips...',
          progressPercentage: 0.4,
          isCompleted: false,
        ),
      );

      final tempVideoPath = p.join(assemblyDir.path, 'concatenated_video.mp4');

      // Use filter_complex for better compatibility and format consistency
      final concatCommand = _buildConcatenationCommand(
        readyClips,
        tempVideoPath,
      );
      final concatSession = await FFmpegKit.execute(concatCommand);
      final concatReturnCode = await concatSession.getReturnCode();

      if (!ReturnCode.isSuccess(concatReturnCode)) {
        final logs = await concatSession.getAllLogsAsString();
        return VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 4,
          currentOperation: 'Failed',
          progressPercentage: 0.4,
          isCompleted: true,
          errorMessage: 'Failed to concatenate videos: $logs',
        );
      }

      String currentVideoPath = tempVideoPath;

      // Step 5: Add speech audio if needed
      if (includeAudio) {
        onProgress(
          VideoAssemblyProgress(
            totalSteps: 8,
            currentStep: 5,
            currentOperation: 'Adding speech audio...',
            progressPercentage: 0.5,
            isCompleted: false,
          ),
        );

        final audioAssembledPath = await _addSpeechAudio(
          readyClips,
          currentVideoPath,
          assemblyDir.path,
        );

        if (audioAssembledPath != null) {
          currentVideoPath = audioAssembledPath;
        }
      } else {
        onProgress(
          VideoAssemblyProgress(
            totalSteps: 8,
            currentStep: 5,
            currentOperation: 'Skipping speech audio...',
            progressPercentage: 0.5,
            isCompleted: false,
          ),
        );
      }

      // Step 6: Add background music if needed
      if (includeBackgroundMusic && transcript.backgroundMusic != null) {
        onProgress(
          VideoAssemblyProgress(
            totalSteps: 8,
            currentStep: 6,
            currentOperation: 'Adding background music...',
            progressPercentage: 0.7,
            isCompleted: false,
          ),
        );

        // Extract file path from Asset - temporary until we refactor VideoTranscript
        String? musicPath;
        try {
          if (transcript.backgroundMusic is LocalAsset) {
            musicPath = (transcript.backgroundMusic as LocalAsset).file.path;
          }
        } catch (e) {
          debugPrint('Could not extract music file path: $e');
        }

        if (musicPath != null) {
          final musicAssembledPath = await _addBackgroundMusic(
            currentVideoPath,
            musicPath,
            transcript.durationSeconds,
            assemblyDir.path,
          );

          if (musicAssembledPath != null) {
            currentVideoPath = musicAssembledPath;
          }
        }
      } else {
        onProgress(
          VideoAssemblyProgress(
            totalSteps: 8,
            currentStep: 6,
            currentOperation: 'Skipping background music...',
            progressPercentage: 0.7,
            isCompleted: false,
          ),
        );
      }

      // Step 7: Apply final encoding and optimization
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 7,
          currentOperation: 'Final encoding and optimization...',
          progressPercentage: 0.8,
          isCompleted: false,
        ),
      );

      // Use high compatibility H.264/AAC encoding for maximum compatibility
      final finalCommand = _buildFinalEncodingCommand(
        currentVideoPath,
        outputPath,
      );
      final finalSession = await FFmpegKit.execute(finalCommand);
      final finalReturnCode = await finalSession.getReturnCode();

      if (!ReturnCode.isSuccess(finalReturnCode)) {
        final logs = await finalSession.getAllLogsAsString();
        return VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 7,
          currentOperation: 'Failed',
          progressPercentage: 0.8,
          isCompleted: true,
          errorMessage: 'Failed to encode final video: $logs',
        );
      }

      // Step 8: Cleanup and complete
      onProgress(
        VideoAssemblyProgress(
          totalSteps: 8,
          currentStep: 8,
          currentOperation: 'Cleaning up temporary files...',
          progressPercentage: 0.9,
          isCompleted: false,
        ),
      );

      // Clean up temporary directory
      try {
        await assemblyDir.delete(recursive: true);
      } catch (e) {
        debugPrint('Warning: Could not clean up temp directory: $e');
      }

      // Final success
      return VideoAssemblyProgress(
        totalSteps: 8,
        currentStep: 8,
        currentOperation: 'Video assembly completed!',
        progressPercentage: 1.0,
        isCompleted: true,
        outputPath: outputPath,
      );
    } catch (e) {
      return VideoAssemblyProgress(
        totalSteps: 8,
        currentStep: 0,
        currentOperation: 'Failed',
        progressPercentage: 0.0,
        isCompleted: true,
        errorMessage: 'Unexpected error during video assembly: $e',
      );
    }
  }

  /// Build FFmpeg command for final encoding with maximum compatibility
  static String _buildFinalEncodingCommand(
    String inputPath,
    String outputPath,
  ) {
    return '-i "$inputPath" '
        '-c:v libx264 '
        '-preset medium '
        '-crf 23 '
        '-c:a aac '
        '-b:a 128k '
        '-ar 44100 '
        '-ac 2 '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '-f mp4 '
        '"$outputPath"';
  }

  /// Build FFmpeg command for concatenating videos with format normalization
  static String _buildConcatenationCommand(
    List<VideoClip> clips,
    String outputPath,
  ) {
    // Build input parameters for all video files
    final inputParams = StringBuffer();
    final filterComplex = StringBuffer();

    for (int i = 0; i < clips.length; i++) {
      final videoPath = clips[i].generatedVideoPath!;
      inputParams.write('-i "$videoPath" ');

      // Scale and set standard frame rate for each input
      filterComplex.write(
        '[$i:v]scale=1920:1080:force_original_aspect_ratio=decrease,',
      );
      filterComplex.write('pad=1920:1080:-1:-1:color=black,fps=30[v$i];');
    }

    // Concatenate all normalized videos
    filterComplex.write('[');
    for (int i = 0; i < clips.length; i++) {
      filterComplex.write('v$i');
      if (i < clips.length - 1) filterComplex.write('][');
    }
    filterComplex.write(']concat=n=${clips.length}:v=1[outv]');

    return '$inputParams-filter_complex "${filterComplex.toString()}" -map "[outv]" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p "$outputPath"';
  }

  /// Add speech audio to video clips using direct file paths
  static Future<String?> _addSpeechAudio(
    List<VideoClip> clips,
    String videoPath,
    String workingDir,
  ) async {
    try {
      final audioClips = <String>[];

      // Collect audio clips that exist
      for (final clip in clips) {
        if (clip.hasGeneratedSpeechAudio) {
          final audioPath = clip.generatedSpeechAudioPath!;
          // Verify the file exists before adding
          if (await File(audioPath).exists()) {
            audioClips.add(audioPath);
          }
        }
      }

      if (audioClips.isEmpty) {
        return videoPath; // No audio to add
      }

      // If only one audio clip, combine directly
      if (audioClips.length == 1) {
        final outputPath = p.join(workingDir, 'video_with_speech.mp4');
        final combineCommand =
            '-i "$videoPath" -i "${audioClips[0]}" '
            '-c:v copy -c:a aac -b:a 128k -ar 44100 -ac 2 '
            '-map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

        final combineSession = await FFmpegKit.execute(combineCommand);
        if (ReturnCode.isSuccess(await combineSession.getReturnCode())) {
          return outputPath;
        } else {
          return videoPath;
        }
      }

      // Multiple audio clips - concatenate them first
      final mergedAudioPath = p.join(workingDir, 'merged_audio.mp3');
      final audioInputs = audioClips.map((path) => '-i "$path"').join(' ');
      final filterInputs = List.generate(
        audioClips.length,
        (i) => '[$i:a]',
      ).join('');

      final audioCommand =
          '$audioInputs -filter_complex '
          '"${filterInputs}concat=n=${audioClips.length}:v=0:a=1[outa]" '
          '-map "[outa]" -c:a aac -b:a 128k -ar 44100 -ac 2 "$mergedAudioPath"';

      final audioSession = await FFmpegKit.execute(audioCommand);

      if (!ReturnCode.isSuccess(await audioSession.getReturnCode())) {
        return videoPath; // Failed to merge audio, return original video
      }

      // Add merged audio to video
      final outputPath = p.join(workingDir, 'video_with_speech.mp4');
      final combineCommand =
          '-i "$videoPath" -i "$mergedAudioPath" '
          '-c:v copy -c:a aac -b:a 128k -ar 44100 -ac 2 '
          '-map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

      final combineSession = await FFmpegKit.execute(combineCommand);

      if (ReturnCode.isSuccess(await combineSession.getReturnCode())) {
        return outputPath;
      } else {
        return videoPath; // Failed to combine, return original
      }
    } catch (e) {
      debugPrint('Error adding speech audio: $e');
      return videoPath;
    }
  }

  /// Add background music to video
  static Future<String?> _addBackgroundMusic(
    String videoPath,
    String musicPath,
    int durationSeconds,
    String workingDir,
  ) async {
    try {
      // Verify music file exists
      if (!await File(musicPath).exists()) {
        debugPrint('Background music file not found: $musicPath');
        return videoPath;
      }

      final outputPath = p.join(workingDir, 'video_with_music.mp4');

      // Add background music with volume adjustment and proper looping
      final musicCommand =
          '-i "$videoPath" -i "$musicPath" '
          '-filter_complex "'
          '[1:a]volume=0.3,aloop=loop=-1:size=2e+09,aformat=sample_rates=44100:channel_layouts=stereo[bg];'
          '[0:a][bg]amix=inputs=2:duration=first:dropout_transition=2[a]" '
          '-map 0:v -map "[a]" -c:v copy -c:a aac -b:a 128k -ar 44100 -ac 2 '
          '-t $durationSeconds "$outputPath"';

      final musicSession = await FFmpegKit.execute(musicCommand);

      if (ReturnCode.isSuccess(await musicSession.getReturnCode())) {
        return outputPath;
      } else {
        final logs = await musicSession.getAllLogsAsString();
        debugPrint('Failed to add background music: $logs');
        return videoPath; // Failed to add music, return original
      }
    } catch (e) {
      debugPrint('Error adding background music: $e');
      return videoPath;
    }
  }

  /// Check if FFmpeg is available
  static Future<bool> isFFmpegAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      return ReturnCode.isSuccess(await session.getReturnCode());
    } catch (e) {
      return false;
    }
  }
}
