import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing application-wide settings using SharedPreferences.
/// Handles settings like image comparison display, ComfyUI server URL, and Local LLM URL.
class AppSettingsController extends GetxController {
  static const String _showComparisonKey = 'show_image_comparison';
  static const String _comfyuiUrlKey = 'comfyui_url';
  static const String _localLlmUrlKey = 'local_llm_url';
  static const String _defaultComfyUIUrl = 'http://127.0.0.1:8188';
  static const String _defaultLocalLlmUrl = 'http://127.0.0.1:5001';

  var showImageComparison = false.obs;
  var comfyuiUrl = _defaultComfyUIUrl.obs;
  var localLlmUrl = _defaultLocalLlmUrl.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      showImageComparison.value = prefs.getBool(_showComparisonKey) ?? false;
      comfyuiUrl.value = prefs.getString(_comfyuiUrlKey) ?? _defaultComfyUIUrl;
      localLlmUrl.value =
          prefs.getString(_localLlmUrlKey) ?? _defaultLocalLlmUrl;
    } catch (e) {
      // print('Error loading app settings: $e');
    }
  }

  Future<void> setShowImageComparison(bool value) async {
    showImageComparison.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showComparisonKey, value);
    } catch (e) {
      // print('Error saving comparison setting: $e');
    }
  }

  Future<void> setComfyUIUrl(String url) async {
    // Validate and clean the URL
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      cleanUrl = _defaultComfyUIUrl;
    } else if (!cleanUrl.startsWith('http://') &&
        !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    // Remove trailing slash
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    comfyuiUrl.value = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_comfyuiUrlKey, cleanUrl);
    } catch (e) {
      // print('Error saving ComfyUI URL: $e');
    }
  }

  Future<void> setLocalLlmUrl(String url) async {
    // Validate and clean the URL
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      cleanUrl = _defaultLocalLlmUrl;
    } else if (!cleanUrl.startsWith('http://') &&
        !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    // Remove trailing slash
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    localLlmUrl.value = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localLlmUrlKey, cleanUrl);
    } catch (e) {
      // print('Error saving Local LLM URL: $e');
    }
  }

  /// Get the current ComfyUI URL (static method for easy access)
  static String getCurrentComfyUIUrl() {
    try {
      final controller = Get.find<AppSettingsController>();
      return controller.comfyuiUrl.value;
    } catch (e) {
      // Fallback to default if controller not found
      return _defaultComfyUIUrl;
    }
  }
}
