import 'package:shared_preferences/shared_preferences.dart';

class PromptPreferencesService {
  static const String _imagePromptKey = 'last_image_prompt';
  static const String _videoPromptKey = 'last_video_prompt';

  static PromptPreferencesService? _instance;
  static PromptPreferencesService get instance {
    _instance ??= PromptPreferencesService._();
    return _instance!;
  }

  PromptPreferencesService._();

  /// Save the last used image prompt
  Future<void> saveImagePrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imagePromptKey, prompt);
  }

  /// Get the last used image prompt
  Future<String?> getImagePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imagePromptKey);
  }

  /// Save the last used video prompt
  Future<void> saveVideoPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_videoPromptKey, prompt);
  }

  /// Get the last used video prompt
  Future<String?> getVideoPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_videoPromptKey);
  }

  /// Clear all saved prompts
  Future<void> clearAllPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_imagePromptKey);
    await prefs.remove(_videoPromptKey);
  }
}
