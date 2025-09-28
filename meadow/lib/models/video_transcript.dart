import 'dart:convert';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/asset.dart';

/// Represents a complete video transcript with multiple clips
class VideoTranscript {
  final String id;
  final String title;
  final String description;
  final int durationSeconds;
  final List<VideoClip> clips;
  final Asset? backgroundMusic;
  final bool generateSpeech;
  final bool generateMusic;
  final int mediaWidth;
  final int mediaHeight;
  final int clipLengthSeconds;
  final DateTime createdAt;
  final DateTime lastModified;

  VideoTranscript({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.clips,
    this.backgroundMusic,
    this.generateSpeech = false,
    this.generateMusic = false,
    this.mediaWidth = 1024,
    this.mediaHeight = 1024,
    this.clipLengthSeconds = 5,
    required this.createdAt,
    required this.lastModified,
  });

  /// Calculate number of clips needed based on duration and clip length
  int get requiredClips => (durationSeconds / clipLengthSeconds).ceil();

  /// Get clip duration (all clips use clipLengthSeconds except possibly the last one)
  double getClipDuration(int clipIndex) {
    if (clipIndex == clips.length - 1) {
      // Last clip might be shorter
      final remainingTime = durationSeconds % clipLengthSeconds;
      return remainingTime == 0
          ? clipLengthSeconds.toDouble()
          : remainingTime.toDouble();
    }
    return clipLengthSeconds.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_seconds': durationSeconds,
      'clips': clips.map((clip) => clip.toJson()).toList(),
      if (backgroundMusic != null) 'background_music': backgroundMusic!.id,
      'generate_speech': generateSpeech,
      'generate_music': generateMusic,
      'media_width': mediaWidth,
      'media_height': mediaHeight,
      'clip_length_seconds': clipLengthSeconds,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }

  factory VideoTranscript.fromJson(Map<String, dynamic> json) {
    return VideoTranscript(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 60,
      clips:
          (json['clips'] as List<dynamic>?)
              ?.map((clipJson) => VideoClip.fromJson(clipJson))
              .toList() ??
          [],
      backgroundMusic: null, // Will be resolved separately by service
      generateSpeech: json['generate_speech'] ?? false,
      generateMusic: json['generate_music'] ?? false,
      mediaWidth: json['media_width'] ?? 1024,
      mediaHeight: json['media_height'] ?? 1024,
      clipLengthSeconds: json['clip_length_seconds'] ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'])
          : DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory VideoTranscript.fromJsonString(String jsonString) {
    return VideoTranscript.fromJson(jsonDecode(jsonString));
  }

  VideoTranscript copyWith({
    String? id,
    String? title,
    String? description,
    int? durationSeconds,
    List<VideoClip>? clips,
    Asset? backgroundMusic,
    bool? generateSpeech,
    bool? generateMusic,
    int? mediaWidth,
    int? mediaHeight,
    int? clipLengthSeconds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return VideoTranscript(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      clips: clips ?? this.clips,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      generateSpeech: generateSpeech ?? this.generateSpeech,
      generateMusic: generateMusic ?? this.generateMusic,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      clipLengthSeconds: clipLengthSeconds ?? this.clipLengthSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
