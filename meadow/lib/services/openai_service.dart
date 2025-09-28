import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/app_settings_controller.dart';
import 'package:meadow/models/video_clip.dart';
import 'package:meadow/models/video_transcript.dart';

class LocalLLMService {
  static const String _defaultModel = 'llama3';

  final Dio _dio;
  final AppSettingsController _settingsController = Get.find();

  LocalLLMService()
    : _dio = Dio(
        BaseOptions(
          headers: {
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

  Future<VideoTranscript> generateVideoTranscript({
    required String title,
    required String description,
    required int durationSeconds,
    required bool generateSpeech,
    required bool generateMusic,
    int mediaWidth = 1024,
    int mediaHeight = 1024,
    int clipLengthSeconds = 5,
  }) async {
    final requiredClips = (durationSeconds / clipLengthSeconds).ceil();

    final prompt = _buildTranscriptPrompt(
      description: description,
      durationSeconds: durationSeconds,
      requiredClips: requiredClips,
      generateSpeech: generateSpeech,
      generateMusic: generateMusic,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      clipLengthSeconds: clipLengthSeconds,
    );

    try {
      final baseUrl = _settingsController.localLlmUrl.value;

      // Prepare the request data without response_format initially
      final requestData = {
        'model': _defaultModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional video production assistant. Generate detailed, creative prompts for image and video generation based on user descriptions. Always respond with valid JSON format.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.8,
        'max_tokens': 4000,
      };

      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: requestData,
      );

      final content = response.data['choices'][0]['message']['content'];

      // Try to extract JSON from the response if it's embedded in markdown
      String jsonString = content;
      if (content.contains('```json')) {
        final jsonMatch = RegExp(
          r'```json\s*(.*?)\s*```',
          dotAll: true,
        ).firstMatch(content);
        if (jsonMatch != null) {
          jsonString = jsonMatch.group(1)!;
        }
      } else if (content.contains('```')) {
        final jsonMatch = RegExp(
          r'```\s*(.*?)\s*```',
          dotAll: true,
        ).firstMatch(content);
        if (jsonMatch != null) {
          jsonString = jsonMatch.group(1)!;
        }
      }

      final jsonData = jsonDecode(jsonString);

      // Parse clips
      final clips = (jsonData['clips'] as List<dynamic>)
          .map((clipData) => VideoClip.fromJson(clipData))
          .toList();

      return VideoTranscript(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        durationSeconds: durationSeconds,
        clips: clips,
        backgroundMusic:
            null, // Will be set separately when music is generated/selected
        generateSpeech: generateSpeech,
        generateMusic: generateMusic,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        clipLengthSeconds: clipLengthSeconds,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
    } catch (e) {
      if (e is DioException) {}
      throw Exception('Failed to generate video transcript: $e');
    }
  }

  /// Regenerate a specific clip
  Future<VideoClip> regenerateClip({
    required String description,
    required int clipIndex,
    required int totalClips,
    required bool generateSpeech,
    String? previousContext,
  }) async {
    final prompt = _buildClipRegenerationPrompt(
      description: description,
      clipIndex: clipIndex,
      totalClips: totalClips,
      generateSpeech: generateSpeech,
      previousContext: previousContext,
    );

    try {
      final baseUrl = _settingsController.localLlmUrl.value;

      final requestData = {
        'model': _defaultModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional video production assistant. Generate a single video clip with image prompt, video prompt, and optional speech. Always respond with valid JSON format.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.8,
        'max_tokens': 1000,
      };

      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: requestData,
      );

      final content = response.data['choices'][0]['message']['content'];

      // Try to extract JSON from the response if it's embedded in markdown
      String jsonString = content;
      if (content.contains('```json')) {
        final jsonMatch = RegExp(
          r'```json\s*(.*?)\s*```',
          dotAll: true,
        ).firstMatch(content);
        if (jsonMatch != null) {
          jsonString = jsonMatch.group(1)!;
        }
      } else if (content.contains('```')) {
        final jsonMatch = RegExp(
          r'```\s*(.*?)\s*```',
          dotAll: true,
        ).firstMatch(content);
        if (jsonMatch != null) {
          jsonString = jsonMatch.group(1)!;
        }
      }

      final jsonData = jsonDecode(jsonString);

      return VideoClip.fromJson(jsonData);
    } catch (e) {
      if (e is DioException) {}
      throw Exception('Failed to regenerate clip: $e');
    }
  }

  /// Test connection to the local LLM server
  Future<bool> testConnection() async {
    try {
      final baseUrl = _settingsController.localLlmUrl.value;

      // Try to make a simple request to test connectivity
      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: {
          'model': _defaultModel,
          'messages': [
            {
              'role': 'user',
              'content': 'Hello, are you working?',
            },
          ],
          'max_tokens': 10,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {}
      return false;
    }
  }

  String _buildTranscriptPrompt({
    required String description,
    required int durationSeconds,
    required int requiredClips,
    required bool generateSpeech,
    required bool generateMusic,
    int mediaWidth = 1024,
    int mediaHeight = 1024,
    int clipLengthSeconds = 5,
  }) {
    return '''
You must respond with ONLY valid JSON. Do not include any explanations or markdown formatting.

Generate a detailed video transcript for a $durationSeconds-second video based on this description:

"$description"

Requirements:
- Create exactly $requiredClips clips (each $clipLengthSeconds seconds long)
- Each clip should have an "image_prompt" for generating a high-quality image at ${mediaWidth}x$mediaHeight resolution
- Each clip should have a "video_prompt" for converting that image into a $clipLengthSeconds-second video
- ${generateSpeech ? 'Include "speech" text for each clip (narration/dialogue)' : 'Do not include speech'}
- ${generateMusic ? 'Include a "music" prompt for background music' : 'Do not include music'}

Image prompts should be:
- Highly detailed and descriptive
- Include camera angles, lighting, composition
- Specify art style if relevant
- Include mood and atmosphere

Video prompts should be:
- Describe motion and movement
- Include camera movement if any
- Specify transitions and effects
- Keep within $clipLengthSeconds-second constraints

${generateSpeech ? '''
Speech should be:
- Natural and engaging
- Appropriate for the timing ($clipLengthSeconds seconds max)
- Match the visual content
- Professional narration style
''' : ''}

${generateMusic ? '''
Music prompt should be:
- Describe style, mood, and instrumentation
- Match the overall video tone
- Be suitable for background music
''' : ''}

Respond with ONLY this JSON format (no markdown, no explanations):
{
    "clips": [
        {
            "image_prompt": "detailed image generation prompt",
            "video_prompt": "detailed video generation prompt"${generateSpeech ? ',\n            "speech": "narration text for this clip"' : ''}
        }
    ]${generateMusic ? ',\n    "music": "background music generation prompt"' : ''}
}
''';
  }

  String _buildClipRegenerationPrompt({
    required String description,
    required int clipIndex,
    required int totalClips,
    required bool generateSpeech,
    String? previousContext,
  }) {
    return '''
You must respond with ONLY valid JSON. Do not include any explanations or markdown formatting.

Regenerate clip ${clipIndex + 1} of $totalClips for this video:

"$description"

${previousContext != null ? 'Previous context: $previousContext' : ''}

This is a 5-second clip. Generate:
- A detailed "image_prompt" for generating a high-quality image
- A "video_prompt" for converting that image into a 5-second video
${generateSpeech ? '- "speech" text for narration (5 seconds max)' : ''}

Respond with ONLY this JSON format (no markdown, no explanations):
{
    "image_prompt": "detailed image generation prompt",
    "video_prompt": "detailed video generation prompt"${generateSpeech ? ',\n    "speech": "narration text for this clip"' : ''}
}
''';
  }
}
