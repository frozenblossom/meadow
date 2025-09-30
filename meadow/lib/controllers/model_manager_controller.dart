import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../models/downloadable_model.dart';
import '../services/model_download_service.dart';
import '../services/file_metadata_service.dart';

/// Controller for managing AI model downloads and ComfyUI integration
class ModelManagerController extends GetxController {
  static ModelManagerController get instance =>
      Get.find<ModelManagerController>();

  // Reactive state
  final RxList<DownloadableModel> _availableModels = <DownloadableModel>[].obs;
  final RxList<DownloadableModel> _filteredModels = <DownloadableModel>[].obs;
  final RxString _comfyUIDirectory = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isDownloading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedCategory = 'all'.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isOnline = true.obs;

  // Progress tracking
  final RxMap<String, double> _downloadProgress = <String, double>{}.obs;
  final RxMap<String, String> _downloadStatus = <String, String>{}.obs;

  // Getters
  List<DownloadableModel> get availableModels => _availableModels;
  List<DownloadableModel> get filteredModels => _filteredModels;
  String get comfyUIDirectory => _comfyUIDirectory.value;
  bool get isLoading => _isLoading.value;
  bool get isDownloading => _isDownloading.value;
  String get searchQuery => _searchQuery.value;
  String get selectedCategory => _selectedCategory.value;
  String get errorMessage => _errorMessage.value;
  bool get isOnline => _isOnline.value;
  Map<String, double> get downloadProgress => _downloadProgress;
  Map<String, String> get downloadStatus => _downloadStatus;

  // Constants
  static const String _comfyUIDirKey = 'comfyui_directory';
  static const String _modelCatalogKey = 'model_catalog_cache';
  static const String _remoteCatalogUrl =
      'https://lyviaai.com/model_catalog.json';

  late final ModelDownloadService _downloadService;

  @override
  void onInit() {
    super.onInit();
    _downloadService = Get.put(ModelDownloadService());
    _loadSettings();
    _loadCachedModels();
    refreshModelCatalog();
  }

  /// Load saved settings from preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDir = prefs.getString(_comfyUIDirKey);
      if (savedDir != null && savedDir.isNotEmpty) {
        _comfyUIDirectory.value = savedDir;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  /// Save settings to preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_comfyUIDirKey, _comfyUIDirectory.value);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Load cached model catalog from local storage
  Future<void> _loadCachedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_modelCatalogKey);

      if (cachedJson != null) {
        final catalogData = json.decode(cachedJson) as Map<String, dynamic>;
        final catalog = ModelCatalog.fromJson(catalogData);
        _availableModels.value = catalog.models;
        _applyFilters();
      } else {
        // Load fallback local catalog
        _loadFallbackCatalog();
      }
    } catch (e) {
      debugPrint('Error loading cached models: $e');
      _loadFallbackCatalog();
    }
  }

  /// Load fallback local catalog from assets
  Future<void> _loadFallbackCatalog() async {
    try {
      // First try to load from assets
      try {
        final String catalogJson = await rootBundle.loadString(
          'assets/model_catalog.json',
        );
        final catalogData = json.decode(catalogJson) as Map<String, dynamic>;
        final catalog = ModelCatalog.fromJson(catalogData);
        _availableModels.value = catalog.models;
        _applyFilters();
        return;
      } catch (e) {
        debugPrint('Could not load catalog from assets: $e');
      }

      // Fallback to hardcoded catalog with the Qwen model from your idea.json
      final qwenModel = DownloadableModel(
        id: 'qwen-image-2.5b',
        name: 'Qwen-Image 2.5B',
        description:
            'Qwen-Image 2.5B is a large multimodal model for image generation',
        category: 'diffusion',
        weights: [
          const ModelWeight(
            filename: 'qwen_image_distill_full_fp8_e4m3fn.safetensors',
            dir: 'diffusion_models',
            url:
                'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/non_official/diffusion_models/qwen_image_distill_full_fp8_e4m3fn.safetensors',
          ),
          const ModelWeight(
            filename: 'qwen_2.5_vl_7b_fp8_scaled.safetensors',
            dir: 'text_encoders',
            url:
                'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors',
          ),
          const ModelWeight(
            filename: 'qwen_image_vae.safetensors',
            dir: 'vae',
            url:
                'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors',
          ),
        ],
      );

      _availableModels.value = [qwenModel];
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading fallback catalog: $e');
    }
  }

  /// Refresh model catalog from remote source
  Future<void> refreshModelCatalog() async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final response = await dio.get(_remoteCatalogUrl);

      if (response.statusCode == 200 && response.data != null) {
        final catalog = ModelCatalog.fromJson(
          response.data as Map<String, dynamic>,
        );
        _availableModels.value = catalog.models;
        _isOnline.value = true;

        // Cache the catalog
        await _cacheCatalog(catalog);

        // Update download status for all models
        await _updateModelDownloadStatus();

        _applyFilters();
      } else {
        throw Exception('Failed to fetch catalog: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching remote catalog: $e');
      _isOnline.value = false;
      _errorMessage.value = 'Failed to fetch latest models. Using cached data.';

      // Fallback to cached data if available
      if (_availableModels.isEmpty) {
        _loadCachedModels();
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cache the model catalog locally
  Future<void> _cacheCatalog(ModelCatalog catalog) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catalogJson = json.encode(catalog.toJson());
      await prefs.setString(_modelCatalogKey, catalogJson);
    } catch (e) {
      debugPrint('Error caching catalog: $e');
    }
  }

  /// Update download status for all models
  Future<void> _updateModelDownloadStatus() async {
    if (_comfyUIDirectory.value.isEmpty) return;

    for (int i = 0; i < _availableModels.length; i++) {
      final model = _availableModels[i];
      final status = await _downloadService.getModelDownloadStatus(
        model: model,
        comfyUIDirectory: _comfyUIDirectory.value,
      );

      final downloadedWeights = await _downloadService.getDownloadedWeights(
        model: model,
        comfyUIDirectory: _comfyUIDirectory.value,
      );

      final progress = downloadedWeights.length / model.weights.length;

      // Only fetch file sizes if they're missing AND not currently downloading
      final needsSizeUpdate = model.weights.any((w) => w.fileSize == null);
      final isCurrentlyDownloading = _downloadProgress.containsKey(model.id);

      List<ModelWeight> updatedWeights = model.weights;
      if (needsSizeUpdate && !isCurrentlyDownloading) {
        updatedWeights = await _fetchWeightFileSizes(model.weights);
      }

      _availableModels[i] = model.copyWith(
        downloadStatus: status,
        overallProgress: progress,
        weights: updatedWeights.map((weight) {
          final isDownloaded = downloadedWeights.any(
            (dw) => dw.filename == weight.filename,
          );
          return weight.copyWith(isDownloaded: isDownloaded);
        }).toList(),
      );
    }

    _applyFilters();
  }

  /// Fetch file sizes for weights dynamically
  Future<List<ModelWeight>> _fetchWeightFileSizes(
    List<ModelWeight> weights,
  ) async {
    final updatedWeights = <ModelWeight>[];

    for (final weight in weights) {
      // Skip if file size is already available
      if (weight.fileSize != null && weight.fileSize! > 0) {
        updatedWeights.add(weight);
        continue;
      }

      try {
        final fileSize = await FileMetadataService.getFileSize(weight.url);
        updatedWeights.add(weight.copyWith(fileSize: fileSize));
      } catch (e) {
        debugPrint('Failed to fetch file size for ${weight.filename}: $e');
        // Keep original weight if size fetch fails
        updatedWeights.add(weight);
      }
    }

    return updatedWeights;
  }

  /// Select ComfyUI directory
  Future<void> selectComfyUIDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select ComfyUI Directory',
        initialDirectory: _comfyUIDirectory.value.isNotEmpty
            ? _comfyUIDirectory.value
            : null,
      );

      if (result != null) {
        _comfyUIDirectory.value = result;
        await _saveSettings();
        // Only update status if directory actually changed
        await _updateModelDownloadStatus();
        _errorMessage.value = '';
      }
    } catch (e) {
      _errorMessage.value = 'Error selecting directory: $e';
    }
  }

  /// Download a model
  Future<void> downloadModel(DownloadableModel model) async {
    if (_comfyUIDirectory.value.isEmpty) {
      _errorMessage.value = 'Please select ComfyUI directory first';
      return;
    }

    if (_isDownloading.value) {
      _errorMessage.value = 'Another download is already in progress';
      return;
    }

    _isDownloading.value = true;
    _downloadProgress[model.id] = 0.0;
    _downloadStatus[model.id] = 'Starting download...';
    _errorMessage.value = '';

    try {
      final success = await _downloadService.downloadModel(
        model: model,
        comfyUIDirectory: _comfyUIDirectory.value,
        onProgress: (progress) {
          _downloadProgress[model.id] = progress.percentage / 100;
          _downloadStatus[model.id] = progress.status;
        },
        onError: (error) {
          _errorMessage.value = error;
          _downloadStatus[model.id] = 'Failed: $error';
        },
        onCompleted: () {
          _downloadProgress[model.id] = 1.0;
          _downloadStatus[model.id] = 'Completed';
        },
      );

      if (success) {
        // Don't immediately update status here - it will be updated when needed
        // await _updateModelDownloadStatus();
      }
    } catch (e) {
      _errorMessage.value = 'Download failed: $e';
      _downloadStatus[model.id] = 'Failed';
    } finally {
      _isDownloading.value = false;
    }
  }

  /// Cancel download for a model
  void cancelDownload(String modelId) {
    _downloadService.cancelModelDownload(modelId);
    _downloadProgress.remove(modelId);
    _downloadStatus.remove(modelId);
    _isDownloading.value = false;
  }

  /// Cancel all downloads
  void cancelAllDownloads() {
    _downloadService.cancelAllDownloads();
    _downloadProgress.clear();
    _downloadStatus.clear();
    _isDownloading.value = false;
  }

  /// Search models
  void searchModels(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory.value = category;
    _applyFilters();
  }

  /// Apply search and category filters
  void _applyFilters() {
    var filtered = _availableModels.toList();

    // Apply category filter
    if (_selectedCategory.value != 'all') {
      filtered = filtered
          .where((model) => model.category == _selectedCategory.value)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((model) {
        return model.name.toLowerCase().contains(query) ||
            model.description.toLowerCase().contains(query);
      }).toList();
    }

    _filteredModels.value = filtered;
  }

  /// Get available categories
  List<String> get availableCategories {
    final categories = _availableModels
        .map((model) => model.category)
        .where((category) => category != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return ['all', ...categories];
  }

  /// Get download progress for a model
  double getModelProgress(String modelId) {
    return _downloadProgress[modelId] ?? 0.0;
  }

  /// Get download status for a model
  String getModelStatus(String modelId) {
    return _downloadStatus[modelId] ?? '';
  }

  /// Check if ComfyUI directory is valid
  bool get isComfyUIDirectoryValid {
    if (_comfyUIDirectory.value.isEmpty) return false;

    final dir = Directory(_comfyUIDirectory.value);
    return dir.existsSync();
  }

  /// Get total download size for all models
  int get totalDownloadSize {
    return _availableModels.fold(0, (sum, model) => sum + model.totalSize);
  }

  /// Get number of downloaded models
  int get downloadedModelCount {
    return _availableModels.where((model) => model.isFullyDownloaded).length;
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Refresh current view
  Future<void> refreshModels() async {
    await refreshModelCatalog();
  }

  /// Refresh file sizes for all models
  Future<void> refreshFileSizes() async {
    _isLoading.value = true;
    try {
      for (int i = 0; i < _availableModels.length; i++) {
        final model = _availableModels[i];
        final updatedWeights = await _fetchWeightFileSizes(model.weights);
        _availableModels[i] = model.copyWith(weights: updatedWeights);
      }
      _applyFilters();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _downloadService.cancelAllDownloads();
    super.onClose();
  }
}
