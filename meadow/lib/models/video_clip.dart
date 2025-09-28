import 'dart:io';

/// Readiness status for video clip export
enum ClipReadinessStatus {
  ready, // Has video file, ready for export
  needsVideo, // Has image but needs video generation
  needsAssets, // Missing basic assets
}

/// Represents a single clip in a video transcript
class VideoClip {
  final String imagePrompt;
  final String videoPrompt;
  final String? speech;
  final String? generatedImagePath;
  final String? generatedVideoPath;
  final String? generatedSpeechAudioPath;

  VideoClip({
    required this.imagePrompt,
    required this.videoPrompt,
    this.speech,
    this.generatedImagePath,
    this.generatedVideoPath,
    this.generatedSpeechAudioPath,
  });

  /// Check if this clip has any generated assets
  bool get hasGeneratedAssets =>
      hasGeneratedImage || hasGeneratedVideo || hasGeneratedSpeechAudio;

  /// Check if this clip has a generated image
  bool get hasGeneratedImage =>
      generatedImagePath != null && File(generatedImagePath!).existsSync();

  /// Check if this clip has a generated video
  bool get hasGeneratedVideo =>
      generatedVideoPath != null && File(generatedVideoPath!).existsSync();

  /// Check if this clip has generated speech audio
  bool get hasGeneratedSpeechAudio =>
      generatedSpeechAudioPath != null &&
      File(generatedSpeechAudioPath!).existsSync();

  /// Check if this clip is ready for video export (has video file)
  bool get isReadyForExport => hasGeneratedVideo;

  /// Get the generated image file if it exists
  File? get generatedImageFile =>
      hasGeneratedImage ? File(generatedImagePath!) : null;

  /// Get the generated video file if it exists
  File? get generatedVideoFile =>
      hasGeneratedVideo ? File(generatedVideoPath!) : null;

  /// Get the generated speech audio file if it exists
  File? get generatedSpeechAudioFile =>
      hasGeneratedSpeechAudio ? File(generatedSpeechAudioPath!) : null;

  /// Get readiness status with details
  ClipReadinessStatus get readinessStatus {
    if (hasGeneratedVideo) {
      return ClipReadinessStatus.ready;
    } else if (hasGeneratedImage) {
      return ClipReadinessStatus.needsVideo;
    } else {
      return ClipReadinessStatus.needsAssets;
    }
  }

  /// Get missing assets for this clip
  List<String> get missingAssets {
    final missing = <String>[];
    if (!hasGeneratedImage) missing.add('Image');
    if (!hasGeneratedVideo) missing.add('Video');
    if (speech != null && !hasGeneratedSpeechAudio) {
      missing.add('Speech Audio');
    }
    return missing;
  }

  Map<String, dynamic> toJson() {
    return {
      'image_prompt': imagePrompt,
      'video_prompt': videoPrompt,
      if (speech != null) 'speech': speech,
      if (generatedImagePath != null)
        'generated_image_path': generatedImagePath,
      if (generatedVideoPath != null)
        'generated_video_path': generatedVideoPath,
      if (generatedSpeechAudioPath != null)
        'generated_speech_audio_path': generatedSpeechAudioPath,
    };
  }

  factory VideoClip.fromJson(Map<String, dynamic> json) {
    return VideoClip(
      imagePrompt: json['image_prompt'] ?? '',
      videoPrompt: json['video_prompt'] ?? '',
      speech: json['speech'],
      generatedImagePath: json['generated_image_path'],
      generatedVideoPath: json['generated_video_path'],
      generatedSpeechAudioPath: json['generated_speech_audio_path'],
    );
  }

  VideoClip copyWith({
    String? imagePrompt,
    String? videoPrompt,
    String? speech,
    String? generatedImagePath,
    String? generatedVideoPath,
    String? generatedSpeechAudioPath,
  }) {
    return VideoClip(
      imagePrompt: imagePrompt ?? this.imagePrompt,
      videoPrompt: videoPrompt ?? this.videoPrompt,
      speech: speech ?? this.speech,
      generatedImagePath: generatedImagePath ?? this.generatedImagePath,
      generatedVideoPath: generatedVideoPath ?? this.generatedVideoPath,
      generatedSpeechAudioPath:
          generatedSpeechAudioPath ?? this.generatedSpeechAudioPath,
    );
  }
}
