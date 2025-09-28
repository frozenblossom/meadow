import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/services/openai_service.dart';
import 'package:meadow/services/video_transcript_asset_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoTranscriptController extends GetxController {
  static const String _transcriptsKey = 'video_transcripts';

  var isLoading = false.obs;
  var transcripts = <VideoTranscript>[].obs;
  var errorMessage = ''.obs;

  late LocalLLMService _llmService;
  late VideoTranscriptAssetService _assetService;

  @override
  void onInit() {
    super.onInit();
    _llmService = LocalLLMService();
    _assetService = VideoTranscriptAssetService();
    _loadTranscripts();
  }

  /// Load transcripts from file storage
  Future<void> _loadTranscripts() async {
    try {
      // Check if we need to migrate from SharedPreferences
      await _migrateFromSharedPreferencesIfNeeded();

      final loadedTranscripts = await _assetService.loadAllTranscripts();
      transcripts.value = loadedTranscripts;
    } catch (e) {
      errorMessage.value = 'Error loading transcripts: $e';
    }
  }

  /// Migrate from SharedPreferences if transcripts exist there but not in files
  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transcriptsJson = prefs.getStringList(_transcriptsKey);

      if (transcriptsJson != null && transcriptsJson.isNotEmpty) {
        // Check if we already have transcripts in file storage
        final existingTranscripts = await _assetService.loadAllTranscripts();

        if (existingTranscripts.isEmpty) {
          // Migrate from SharedPreferences
          final oldTranscripts = transcriptsJson
              .map((jsonString) => VideoTranscript.fromJsonString(jsonString))
              .toList();

          await _assetService.migrateFromSharedPreferences(oldTranscripts);

          // Clear SharedPreferences after successful migration
          await prefs.remove(_transcriptsKey);
        }
      }
    } catch (e) {
      // Ignore migration errors, will just start fresh
    }
  }

  /// Generate a new video transcript
  Future<VideoTranscript?> generateTranscript({
    required String title,
    required String description,
    required int durationSeconds,
    required bool generateSpeech,
    required bool generateMusic,
    int mediaWidth = 1024,
    int mediaHeight = 1024,
    int clipLengthSeconds = 5,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final transcript = await _llmService.generateVideoTranscript(
        title: title,
        description: description,
        durationSeconds: durationSeconds,
        generateSpeech: generateSpeech,
        generateMusic: generateMusic,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        clipLengthSeconds: clipLengthSeconds,
      );

      // Save transcript to file storage
      await _assetService.saveTranscript(transcript);

      transcripts.add(transcript);

      return transcript;
    } catch (e) {
      errorMessage.value = 'Error generating transcript: $e';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Regenerate a specific clip
  Future<bool> regenerateClip({
    required String transcriptId,
    required int clipIndex,
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex == -1) {
      errorMessage.value = 'Transcript not found';
      return false;
    }

    final transcript = transcripts[transcriptIndex];
    if (clipIndex < 0 || clipIndex >= transcript.clips.length) {
      errorMessage.value = 'Invalid clip index';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get context from previous clips
      String? previousContext;
      if (clipIndex > 0) {
        final previousClips = transcript.clips.take(clipIndex).toList();
        previousContext = previousClips
            .map((clip) => 'Image: ${clip.imagePrompt}')
            .join('\n');
      }

      final newClip = await _llmService.regenerateClip(
        description: transcript.description,
        clipIndex: clipIndex,
        totalClips: transcript.clips.length,
        generateSpeech: transcript.generateSpeech,
        previousContext: previousContext,
      );

      // Update the transcript
      final updatedClips = List<VideoClip>.from(transcript.clips);
      updatedClips[clipIndex] = newClip;

      final updatedTranscript = transcript.copyWith(
        clips: updatedClips,
        lastModified: DateTime.now(),
      );

      transcripts[transcriptIndex] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);

      return true;
    } catch (e) {
      errorMessage.value = 'Error regenerating clip: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a transcript
  Future<void> deleteTranscript(String transcriptId) async {
    transcripts.removeWhere((t) => t.id == transcriptId);
    await _assetService.deleteTranscript(transcriptId);
  }

  /// Update a transcript
  Future<void> updateTranscript(VideoTranscript transcript) async {
    final index = transcripts.indexWhere((t) => t.id == transcript.id);
    if (index != -1) {
      final updatedTranscript = transcript.copyWith(
        lastModified: DateTime.now(),
      );
      transcripts[index] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);
    }
  }

  /// Update transcript properties
  Future<void> updateTranscriptProperties({
    required String transcriptId,
    String? title,
    String? description,
    int? durationSeconds,
    int? mediaWidth,
    int? mediaHeight,
    int? clipLengthSeconds,
  }) async {
    final index = transcripts.indexWhere((t) => t.id == transcriptId);
    if (index != -1) {
      final transcript = transcripts[index];
      final updatedTranscript = transcript.copyWith(
        title: title,
        description: description,
        durationSeconds: durationSeconds,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        clipLengthSeconds: clipLengthSeconds,
        lastModified: DateTime.now(),
      );
      transcripts[index] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);
    }
  }

  /// Update a specific clip
  Future<void> updateClip({
    required String transcriptId,
    required int clipIndex,
    String? imagePrompt,
    String? videoPrompt,
    String? speech,
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex != -1) {
      final transcript = transcripts[transcriptIndex];
      if (clipIndex >= 0 && clipIndex < transcript.clips.length) {
        final updatedClips = List<VideoClip>.from(transcript.clips);
        updatedClips[clipIndex] = transcript.clips[clipIndex].copyWith(
          imagePrompt: imagePrompt,
          videoPrompt: videoPrompt,
          speech: speech,
        );

        final updatedTranscript = transcript.copyWith(
          clips: updatedClips,
          lastModified: DateTime.now(),
        );
        transcripts[transcriptIndex] = updatedTranscript;
        await _assetService.saveTranscript(updatedTranscript);
      }
    }
  }

  /// Update a specific clip with new assets
  Future<void> updateClipAssets({
    required String transcriptId,
    required int clipIndex,
    required VideoClip updatedClip,
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex != -1) {
      final transcript = transcripts[transcriptIndex];
      if (clipIndex >= 0 && clipIndex < transcript.clips.length) {
        final updatedClips = List<VideoClip>.from(transcript.clips);
        updatedClips[clipIndex] = updatedClip;

        final updatedTranscript = transcript.copyWith(
          clips: updatedClips,
          lastModified: DateTime.now(),
        );
        transcripts[transcriptIndex] = updatedTranscript;
        await _assetService.saveTranscript(updatedTranscript);
      }
    }
  }

  /// Export transcript to JSON file
  Future<String?> exportTranscript(String transcriptId) async {
    final transcript = transcripts.firstWhereOrNull(
      (t) => t.id == transcriptId,
    );
    if (transcript == null) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = p.join(
        directory.path,
        '${transcript.title}_transcript.json',
      );

      return await _assetService.exportTranscript(transcriptId, exportPath);
    } catch (e) {
      errorMessage.value = 'Error exporting transcript: $e';
      return null;
    }
  }

  /// Get transcript by ID
  VideoTranscript? getTranscript(String id) {
    return transcripts.firstWhereOrNull((t) => t.id == id);
  }

  /// Test connection to Local LLM service
  Future<bool> testLLMConnection() async {
    try {
      return await _llmService.testConnection();
    } catch (e) {
      errorMessage.value = 'Connection test failed: $e';
      return false;
    }
  }

  /// Check if Local LLM service is available
  bool get isLLMConfigured => true; // Local LLM service is always available

  /// Save a generated image asset for a clip
  Future<void> saveClipImage(
    String transcriptId,
    int clipIndex,
    Uint8List imageData,
    String extension,
  ) async {
    final filePath = await _assetService.saveClipImage(
      transcriptId,
      clipIndex,
      imageData,
      extension,
    );

    await _assetService.updateClipWithPaths(
      transcriptId,
      clipIndex,
      generatedImagePath: filePath,
    );

    // Refresh the transcript in memory
    final updatedTranscript = await _assetService.loadTranscript(transcriptId);
    if (updatedTranscript != null) {
      final index = transcripts.indexWhere((t) => t.id == transcriptId);
      if (index != -1) {
        transcripts[index] = updatedTranscript;
      }
    }
  }

  /// Save a generated video asset for a clip
  Future<void> saveClipVideo(
    String transcriptId,
    int clipIndex,
    Uint8List videoData,
    String extension,
  ) async {
    final filePath = await _assetService.saveClipVideo(
      transcriptId,
      clipIndex,
      videoData,
      extension,
    );

    await _assetService.updateClipWithPaths(
      transcriptId,
      clipIndex,
      generatedVideoPath: filePath,
    );

    // Refresh the transcript in memory
    final updatedTranscript = await _assetService.loadTranscript(transcriptId);
    if (updatedTranscript != null) {
      final index = transcripts.indexWhere((t) => t.id == transcriptId);
      if (index != -1) {
        transcripts[index] = updatedTranscript;
      }
    }
  }

  /// Save a generated speech audio asset for a clip
  Future<void> saveClipSpeechAudio(
    String transcriptId,
    int clipIndex,
    Uint8List audioData,
    String extension,
  ) async {
    final filePath = await _assetService.saveClipSpeechAudio(
      transcriptId,
      clipIndex,
      audioData,
      extension,
    );

    await _assetService.updateClipWithPaths(
      transcriptId,
      clipIndex,
      generatedSpeechAudioPath: filePath,
    );

    // Refresh the transcript in memory
    final updatedTranscript = await _assetService.loadTranscript(transcriptId);
    if (updatedTranscript != null) {
      final index = transcripts.indexWhere((t) => t.id == transcriptId);
      if (index != -1) {
        transcripts[index] = updatedTranscript;
      }
    }
  }

  /// Add a new blank clip to a transcript (without using LLM)
  Future<bool> addBlankClip({
    required String transcriptId,
    int? insertAt, // If null, adds at the end
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex == -1) {
      errorMessage.value = 'Transcript not found';
      return false;
    }

    final transcript = transcripts[transcriptIndex];

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Create a blank clip with placeholder prompts
      final newClip = VideoClip(
        imagePrompt: '', // Blank image prompt for user to fill
        videoPrompt: '', // Blank video prompt for user to fill
        speech: transcript.generateSpeech
            ? ''
            : null, // Blank speech if enabled
      );

      // Insert the new clip
      final updatedClips = List<VideoClip>.from(transcript.clips);
      if (insertAt != null && insertAt <= updatedClips.length) {
        updatedClips.insert(insertAt, newClip);
      } else {
        updatedClips.add(newClip);
      }

      final updatedTranscript = transcript.copyWith(
        clips: updatedClips,
        lastModified: DateTime.now(),
      );

      transcripts[transcriptIndex] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);

      return true;
    } catch (e) {
      errorMessage.value = 'Error adding blank clip: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a new clip to a transcript
  Future<bool> addClip({
    required String transcriptId,
    int? insertAt, // If null, adds at the end
    String? customPrompt,
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex == -1) {
      errorMessage.value = 'Transcript not found';
      return false;
    }

    final transcript = transcripts[transcriptIndex];

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Generate new clip content
      final newClipIndex = insertAt ?? transcript.clips.length;

      // Get context from existing clips
      String? previousContext;
      if (transcript.clips.isNotEmpty && newClipIndex > 0) {
        final contextClips = transcript.clips.take(newClipIndex).toList();
        previousContext = contextClips
            .map((clip) => 'Image: ${clip.imagePrompt}')
            .join('\n');
      }

      final newClip = await _llmService.regenerateClip(
        description: customPrompt ?? transcript.description,
        clipIndex: newClipIndex,
        totalClips: transcript.clips.length + 1,
        generateSpeech: transcript.generateSpeech,
        previousContext: previousContext,
      );

      // Insert the new clip
      final updatedClips = List<VideoClip>.from(transcript.clips);
      if (insertAt != null && insertAt <= updatedClips.length) {
        updatedClips.insert(insertAt, newClip);
      } else {
        updatedClips.add(newClip);
      }

      final updatedTranscript = transcript.copyWith(
        clips: updatedClips,
        lastModified: DateTime.now(),
      );

      transcripts[transcriptIndex] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);

      return true;
    } catch (e) {
      errorMessage.value = 'Error adding clip: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a clip from a transcript
  Future<bool> deleteClip({
    required String transcriptId,
    required int clipIndex,
  }) async {
    final transcriptIndex = transcripts.indexWhere((t) => t.id == transcriptId);
    if (transcriptIndex == -1) {
      errorMessage.value = 'Transcript not found';
      return false;
    }

    final transcript = transcripts[transcriptIndex];
    if (clipIndex < 0 || clipIndex >= transcript.clips.length) {
      errorMessage.value = 'Invalid clip index';
      return false;
    }

    // Don't allow deleting the last clip
    if (transcript.clips.length <= 1) {
      errorMessage.value = 'Cannot delete the last clip';
      return false;
    }

    try {
      // Clean up any associated assets by removing the clip directory
      final clipDir = await _assetService.getClipDirectory(
        transcriptId,
        clipIndex,
      );
      if (await clipDir.exists()) {
        await clipDir.delete(recursive: true);
      }

      // Remove the clip
      final updatedClips = List<VideoClip>.from(transcript.clips);
      updatedClips.removeAt(clipIndex);

      final updatedTranscript = transcript.copyWith(
        clips: updatedClips,
        lastModified: DateTime.now(),
      );

      transcripts[transcriptIndex] = updatedTranscript;
      await _assetService.saveTranscript(updatedTranscript);

      return true;
    } catch (e) {
      errorMessage.value = 'Error deleting clip: $e';
      return false;
    }
  }

  /// Get the asset service for direct access if needed
  VideoTranscriptAssetService get assetService => _assetService;
}
