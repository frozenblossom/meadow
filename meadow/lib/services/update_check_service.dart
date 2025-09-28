import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Model for update information from the server
class UpdateInfo {
  final String version;
  final int buildNumber;
  final String moreInfoUrl;
  final Map<String, String> downloadLinks;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.moreInfoUrl,
    required this.downloadLinks,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      moreInfoUrl: json['more_info_url'] as String,
      downloadLinks: Map<String, String>.from(
        json['download_links'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Service for checking app updates
class UpdateCheckService extends GetxService {
  static const String updateCheckUrl =
      'https://lyviaai.com/meadow_version.json';
  static const Duration timeoutDuration = Duration(seconds: 10);

  final Dio _dio = Dio();

  // Reactive state
  final RxBool _isUpdateAvailable = false.obs;
  final Rx<UpdateInfo?> _latestUpdateInfo = Rx<UpdateInfo?>(null);
  final RxString _currentVersion = ''.obs;
  final RxInt _currentBuildNumber = 0.obs;
  final RxBool _isChecking = false.obs;

  // Getters
  bool get isUpdateAvailable => _isUpdateAvailable.value;
  UpdateInfo? get latestUpdateInfo => _latestUpdateInfo.value;
  String get currentVersion => _currentVersion.value;
  int get currentBuildNumber => _currentBuildNumber.value;
  bool get isChecking => _isChecking.value;
  @override
  void onInit() {
    super.onInit();
    _dio.options = BaseOptions(
      connectTimeout: timeoutDuration,
      receiveTimeout: timeoutDuration,
      sendTimeout: timeoutDuration,
    );

    _initializeAppInfo();
  }

  /// Initialize current app version and build number
  Future<void> _initializeAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion.value = packageInfo.version;
      _currentBuildNumber.value = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint(
        'Current app version: ${_currentVersion.value} (${_currentBuildNumber.value})',
      );

      // Check for updates on startup
      await checkForUpdates();
    } catch (e) {
      debugPrint('Failed to get app version info: $e');
    }
  }

  /// Check for updates from the server
  Future<void> checkForUpdates() async {
    if (_isChecking.value) return;

    _isChecking.value = true;

    try {
      debugPrint('Checking for updates from: $updateCheckUrl');

      final response = await _dio.get(updateCheckUrl);

      if (response.statusCode == 200 && response.data != null) {
        final updateInfo = UpdateInfo.fromJson(response.data);
        _latestUpdateInfo.value = updateInfo;

        // Compare build numbers
        final hasUpdate = updateInfo.buildNumber > _currentBuildNumber.value;
        _isUpdateAvailable.value = hasUpdate;

        if (hasUpdate) {
          debugPrint(
            'Update available: ${updateInfo.version} (${updateInfo.buildNumber}) > ${_currentVersion.value} (${_currentBuildNumber.value})',
          );
        } else {
          debugPrint(
            'App is up to date: ${_currentVersion.value} (${_currentBuildNumber.value})',
          );
        }
      }
    } catch (e) {
      // Silently fail - we don't want to bother users with network errors
      debugPrint('Update check failed (will retry on next startup): $e');
      _isUpdateAvailable.value = false;
      _latestUpdateInfo.value = null;
    } finally {
      _isChecking.value = false;
    }
  }

  /// Get download URL for current platform
  String? getDownloadUrlForCurrentPlatform() {
    final updateInfo = _latestUpdateInfo.value;
    if (updateInfo == null) return null;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return updateInfo.downloadLinks['windows'];
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return updateInfo.downloadLinks['mac'];
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return updateInfo.downloadLinks['linux'];
    }

    return null;
  }

  /// Get platform name for display
  String getCurrentPlatformName() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Windows';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macOS';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Linux';
    }
    return 'Unknown';
  }

  /// Reset update notification (when user dismisses it)
  void dismissUpdate() {
    _isUpdateAvailable.value = false;
  }

  /// Force refresh update check
  Future<void> forceRefreshUpdateCheck() async {
    await checkForUpdates();
  }
}
