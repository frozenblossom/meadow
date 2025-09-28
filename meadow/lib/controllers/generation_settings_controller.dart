import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  error,
}

class GenerationSettingsController extends GetxController {
  static const String _comfyUIUrlKey = 'comfyui_server_url';
  static const String _autoConnectKey = 'auto_connect_comfyui';
  static const Duration _statusCheckInterval = Duration(seconds: 30);

  // ComfyUI connection settings
  final RxString comfyUIServerUrl = 'http://127.0.0.1:8188'.obs;
  final RxBool autoConnectComfyUI = true.obs;
  final RxBool showComfyUIStatus = true.obs;

  // Connection status
  final Rx<ConnectionStatus> _comfyUIStatus = ConnectionStatus.disconnected.obs;

  // Status check timer
  Timer? _statusCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _startStatusMonitoring();
  }

  @override
  void onClose() {
    _statusCheckTimer?.cancel();
    super.onClose();
  }

  /// Get connection status for ComfyUI
  ConnectionStatus get comfyUIStatus => _comfyUIStatus.value;

  /// Update ComfyUI server URL
  Future<void> updateComfyUIServerUrl(String url) async {
    comfyUIServerUrl.value = url;
    await _saveSettings();

    // Trigger reconnection if auto-connect is enabled
    if (autoConnectComfyUI.value) {
      _checkComfyUIStatus();
    }
  }

  /// Toggle auto-connect for ComfyUI
  Future<void> setAutoConnectComfyUI(bool autoConnect) async {
    autoConnectComfyUI.value = autoConnect;
    await _saveSettings();

    if (autoConnect) {
      _startStatusMonitoring();
    } else {
      _statusCheckTimer?.cancel();
      _comfyUIStatus.value = ConnectionStatus.disconnected;
    }
  }

  /// Manually check ComfyUI connection status
  Future<void> checkComfyUIConnection() async {
    await _checkComfyUIStatus();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      comfyUIServerUrl.value =
          prefs.getString(_comfyUIUrlKey) ?? 'http://127.0.0.1:8188';
      autoConnectComfyUI.value = prefs.getBool(_autoConnectKey) ?? true;
    } catch (e) {
      //
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_comfyUIUrlKey, comfyUIServerUrl.value);
      await prefs.setBool(_autoConnectKey, autoConnectComfyUI.value);
    } catch (e) {
      //
    }
  }

  /// Start monitoring ComfyUI connection status
  void _startStatusMonitoring() {
    if (!autoConnectComfyUI.value) return;

    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(_statusCheckInterval, (_) {
      _checkComfyUIStatus();
    });

    // Check immediately
    _checkComfyUIStatus();
  }

  /// Check ComfyUI connection status
  Future<void> _checkComfyUIStatus() async {
    if (!autoConnectComfyUI.value) return;

    try {
      _comfyUIStatus.value = ConnectionStatus.connecting;

      if (Get.isRegistered<ComfyUIService>()) {
        final comfyUIService = Get.find<ComfyUIService>();
        if (comfyUIService.isServerAvailable.value) {
          _comfyUIStatus.value = ConnectionStatus.connected;
        } else {
          // Try to check availability
          final isAvailable = await comfyUIService.checkServerAvailability();
          _comfyUIStatus.value = isAvailable
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected;
        }
      } else {
        _comfyUIStatus.value = ConnectionStatus.disconnected;
      }
    } catch (e) {
      _comfyUIStatus.value = ConnectionStatus.error;
    }
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (_comfyUIStatus.value) {
      case ConnectionStatus.connected:
        return const Color(0xFF4CAF50); // Green
      case ConnectionStatus.connecting:
        return const Color(0xFFFF9800); // Orange
      case ConnectionStatus.disconnected:
        return const Color(0xFF9E9E9E); // Grey
      case ConnectionStatus.error:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Get status text for UI
  String getStatusText() {
    switch (_comfyUIStatus.value) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }
}
