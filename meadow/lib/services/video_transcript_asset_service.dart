import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for managing video transcripts as assets with JSON file storage
class VideoTranscriptAssetService {
  static const String _transcriptsFolder = 'video_transcripts';

  /// Get the video transcripts directory
  Future<Directory> getTranscriptsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final transcriptsDir = Directory(p.join(appDir.path, _transcriptsFolder));

    if (!await transcriptsDir.exists()) {
      await transcriptsDir.create(recursive: true);
    }

    return transcriptsDir;
  }

  /// Get the directory for a specific transcript
  Future<Directory> getTranscriptDirectory(String transcriptId) async {
    final transcriptsDir = await getTranscriptsDirectory();
    final transcriptDir = Directory(p.join(transcriptsDir.path, transcriptId));

    if (!await transcriptDir.exists()) {
      await transcriptDir.create(recursive: true);
    }

    return transcriptDir;
  }

  /// Get the assets directory for a transcript
  Future<Directory> getTranscriptAssetsDirectory(String transcriptId) async {
    final transcriptDir = await getTranscriptDirectory(transcriptId);
    final assetsDir = Directory(p.join(transcriptDir.path, 'assets'));

    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    return assetsDir;
  }

  /// Get the clips directory for a transcript
  Future<Directory> getTranscriptClipsDirectory(String transcriptId) async {
    final assetsDir = await getTranscriptAssetsDirectory(transcriptId);
    final clipsDir = Directory(p.join(assetsDir.path, 'clips'));

    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
    }

    return clipsDir;
  }

  /// Get the directory for a specific clip
  Future<Directory> getClipDirectory(String transcriptId, int clipIndex) async {
    final clipsDir = await getTranscriptClipsDirectory(transcriptId);
    final clipDir = Directory(p.join(clipsDir.path, 'clip_$clipIndex'));

    if (!await clipDir.exists()) {
      await clipDir.create(recursive: true);
    }

    return clipDir;
  }

  /// Save a video transcript to JSON file
  Future<void> saveTranscript(VideoTranscript transcript) async {
    final transcriptDir = await getTranscriptDirectory(transcript.id);
    final jsonFile = File(p.join(transcriptDir.path, 'transcript.json'));

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(transcript.toJson());
    await jsonFile.writeAsString(jsonString);
  }

  /// Load a video transcript from JSON file
  Future<VideoTranscript?> loadTranscript(String transcriptId) async {
    try {
      final transcriptDir = await getTranscriptDirectory(transcriptId);
      final jsonFile = File(p.join(transcriptDir.path, 'transcript.json'));

      if (!await jsonFile.exists()) {
        return null;
      }

      final jsonString = await jsonFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return VideoTranscript.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Load all video transcripts with asset resolution
  Future<List<VideoTranscript>> loadAllTranscripts() async {
    final transcriptsDir = await getTranscriptsDirectory();
    final transcripts = <VideoTranscript>[];

    if (!await transcriptsDir.exists()) {
      return transcripts;
    }

    final entities = await transcriptsDir.list().toList();
    final directories = entities.whereType<Directory>();

    for (final dir in directories) {
      final transcriptId = p.basename(dir.path);
      final transcript = await loadTranscript(transcriptId);
      if (transcript != null) {
        transcripts.add(transcript);
      }
    }

    // Sort by last modified (newest first)
    transcripts.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return transcripts;
  }

  /// Delete a video transcript and all its assets
  Future<void> deleteTranscript(String transcriptId) async {
    final transcriptDir = await getTranscriptDirectory(transcriptId);

    if (await transcriptDir.exists()) {
      await transcriptDir.delete(recursive: true);
    }
  }

  /// Save a generated image file for a clip
  Future<String> saveClipImage(
    String transcriptId,
    int clipIndex,
    Uint8List imageData,
    String extension,
  ) async {
    final clipDir = await getClipDirectory(transcriptId, clipIndex);
    final imageFile = File(p.join(clipDir.path, 'image$extension'));

    await imageFile.writeAsBytes(imageData);

    return imageFile.path;
  }

  /// Save a generated video file for a clip
  Future<String> saveClipVideo(
    String transcriptId,
    int clipIndex,
    Uint8List videoData,
    String extension,
  ) async {
    final clipDir = await getClipDirectory(transcriptId, clipIndex);
    final videoFile = File(p.join(clipDir.path, 'video$extension'));

    await videoFile.writeAsBytes(videoData);

    return videoFile.path;
  }

  /// Save a generated speech audio file for a clip
  Future<String> saveClipSpeechAudio(
    String transcriptId,
    int clipIndex,
    Uint8List audioData,
    String extension,
  ) async {
    final clipDir = await getClipDirectory(transcriptId, clipIndex);
    final audioFile = File(p.join(clipDir.path, 'speech$extension'));

    await audioFile.writeAsBytes(audioData);

    return audioFile.path;
  }

  /// Update a clip with generated file paths
  Future<void> updateClipWithPaths(
    String transcriptId,
    int clipIndex, {
    String? generatedImagePath,
    String? generatedVideoPath,
    String? generatedSpeechAudioPath,
  }) async {
    final transcript = await loadTranscript(transcriptId);
    if (transcript == null || clipIndex >= transcript.clips.length) {
      return;
    }

    final updatedClips = List<VideoClip>.from(transcript.clips);
    final currentClip = updatedClips[clipIndex];

    updatedClips[clipIndex] = currentClip.copyWith(
      generatedImagePath: generatedImagePath ?? currentClip.generatedImagePath,
      generatedVideoPath: generatedVideoPath ?? currentClip.generatedVideoPath,
      generatedSpeechAudioPath:
          generatedSpeechAudioPath ?? currentClip.generatedSpeechAudioPath,
    );

    final updatedTranscript = transcript.copyWith(
      clips: updatedClips,
      lastModified: DateTime.now(),
    );

    await saveTranscript(updatedTranscript);
  }

  /// Check if transcript exists
  Future<bool> transcriptExists(String transcriptId) async {
    final transcriptDir = await getTranscriptDirectory(transcriptId);
    final jsonFile = File(p.join(transcriptDir.path, 'transcript.json'));
    return await jsonFile.exists();
  }

  /// Get transcript file info
  Future<Map<String, dynamic>?> getTranscriptInfo(String transcriptId) async {
    final transcriptDir = await getTranscriptDirectory(transcriptId);
    final jsonFile = File(p.join(transcriptDir.path, 'transcript.json'));

    if (!await jsonFile.exists()) {
      return null;
    }

    final stat = await jsonFile.stat();
    return {
      'path': jsonFile.path,
      'size': stat.size,
      'modified': stat.modified,
      'created': stat.changed,
    };
  }

  /// Export transcript to a specific location
  Future<String> exportTranscript(
    String transcriptId,
    String exportPath,
  ) async {
    final transcript = await loadTranscript(transcriptId);
    if (transcript == null) {
      throw Exception('Transcript not found');
    }

    final exportFile = File(exportPath);
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(transcript.toJson());
    await exportFile.writeAsString(jsonString);

    return exportFile.path;
  }

  /// Migrate existing SharedPreferences transcripts to file storage
  Future<void> migrateFromSharedPreferences(
    List<VideoTranscript> transcripts,
  ) async {
    for (final transcript in transcripts) {
      await saveTranscript(transcript);
    }
  }
}
