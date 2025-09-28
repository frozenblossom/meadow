import 'dart:convert';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import 'comfyui_api_service.dart';

class ComfyUIModelInfo {
  final String name;
  final String fileName;
  final String type;
  final String? displayName;
  final Map<String, dynamic>? metadata;
  final int? sizeBytes;
  final DateTime? lastModified;
  final bool isAvailable;
  final String? description;
  final List<String>? tags;

  ComfyUIModelInfo({
    required this.name,
    required this.fileName,
    required this.type,
    this.displayName,
    this.metadata,
    this.sizeBytes,
    this.lastModified,
    this.isAvailable = true,
    this.description,
    this.tags,
  });

  factory ComfyUIModelInfo.fromJson(Map<String, dynamic> json) {
    return ComfyUIModelInfo(
      name: json['name'],
      fileName: json['file_name'],
      type: json['type'],
      displayName: json['display_name'],
      metadata: json['metadata'],
      sizeBytes: json['size_bytes'],
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'])
          : null,
      isAvailable: json['is_available'] ?? true,
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'file_name': fileName,
      'type': type,
      'display_name': displayName,
      'metadata': metadata,
      'size_bytes': sizeBytes,
      'last_modified': lastModified?.toIso8601String(),
      'is_available': isAvailable,
      'description': description,
      'tags': tags,
    };
  }

  String get friendlyName => displayName ?? name;

  String get sizeFormatted {
    if (sizeBytes == null) return 'Unknown';

    const units = ['B', 'KB', 'MB', 'GB'];
    double size = sizeBytes!.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  bool get hasSafetensorsMetadata => metadata != null && metadata!.isNotEmpty;

  String? get modelType => metadata?['type'] ?? metadata?['model_type'];
  String? get baseModel => metadata?['base_model'] ?? metadata?['sd_version'];
  String? get architecture => metadata?['architecture'];

  List<String> get allTags {
    final allTags = <String>[];
    if (tags != null) allTags.addAll(tags!);
    if (modelType != null) allTags.add(modelType!);
    if (baseModel != null) allTags.add(baseModel!);
    return allTags;
  }
}

class ComfyUIModelFolder {
  final String name;
  final String type;
  final List<ComfyUIModelInfo> models;
  final int modelCount;
  final int totalSizeBytes;

  ComfyUIModelFolder({
    required this.name,
    required this.type,
    required this.models,
    required this.modelCount,
    required this.totalSizeBytes,
  });

  String get sizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = totalSizeBytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  List<ComfyUIModelInfo> get availableModels =>
      models.where((model) => model.isAvailable).toList();

  List<ComfyUIModelInfo> get modelsWithMetadata =>
      models.where((model) => model.hasSafetensorsMetadata).toList();
}

class ComfyUIModelManager extends GetxService {
  final ComfyUIAPIService _apiService = Get.find<ComfyUIAPIService>();

  // Observable data
  final RxMap<String, ComfyUIModelFolder> folders =
      <String, ComfyUIModelFolder>{}.obs;
  final RxList<ComfyUIModelInfo> allModels = <ComfyUIModelInfo>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> selectedTypes = <String>[].obs;
  final RxList<String> selectedTags = <String>[].obs;

  // Computed properties
  List<ComfyUIModelInfo> get filteredModels {
    var filtered = allModels.where((model) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!model.friendlyName.toLowerCase().contains(query) &&
            !model.fileName.toLowerCase().contains(query) &&
            !model.allTags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Type filter
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(model.type)) {
        return false;
      }

      // Tag filter
      if (selectedTags.isNotEmpty) {
        final modelTags = model.allTags
            .map((tag) => tag.toLowerCase())
            .toList();
        if (!selectedTags.any((tag) => modelTags.contains(tag.toLowerCase()))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by name
    filtered.sort((a, b) => a.friendlyName.compareTo(b.friendlyName));
    return filtered;
  }

  List<String> get availableTypes => folders.keys.toList()..sort();

  List<String> get availableTags {
    final tags = <String>{};
    for (final model in allModels) {
      tags.addAll(model.allTags);
    }
    return tags.toList()..sort();
  }

  int get totalModels => allModels.length;
  int get totalFolders => folders.length;

  String get totalSizeFormatted {
    final totalBytes = folders.values.fold<int>(
      0,
      (sum, folder) => sum + folder.totalSizeBytes,
    );

    const units = ['B', 'KB', 'MB', 'GB'];
    double size = totalBytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  @override
  void onInit() {
    super.onInit();
    refreshModels();
  }

  /// Refresh all models from ComfyUI server
  Future<void> refreshModels() async {
    if (isLoading.value || isRefreshing.value) return;

    if (folders.isEmpty) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }

    error.value = '';

    try {
      // Check if ComfyUI is connected
      if (!_apiService.isConnected) {
        final connected = await _apiService.checkConnection();
        if (!connected) {
          throw Exception('ComfyUI server is not available');
        }
      }

      // Get all models from ComfyUI
      final modelsMap = await _apiService.getAllModels();

      // Clear existing data
      folders.clear();
      allModels.clear();

      // Process each model type
      for (final entry in modelsMap.entries) {
        final folderType = entry.key;
        final modelFiles = entry.value;

        final models = <ComfyUIModelInfo>[];
        int totalSize = 0;

        for (final fileName in modelFiles) {
          try {
            final modelInfo = await _createModelInfo(fileName, folderType);
            models.add(modelInfo);
            totalSize += modelInfo.sizeBytes ?? 0;
          } catch (e) {
            //
          }
        }

        final folder = ComfyUIModelFolder(
          name: folderType,
          type: folderType,
          models: models,
          modelCount: models.length,
          totalSizeBytes: totalSize,
        );

        folders[folderType] = folder;
        allModels.addAll(models);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Model Manager Error',
        'Failed to load models: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Create model info from filename and type
  Future<ComfyUIModelInfo> _createModelInfo(
    String fileName,
    String type,
  ) async {
    final name = path.basenameWithoutExtension(fileName);
    final extension = path.extension(fileName);

    // Try to get metadata for safetensors files
    Map<String, dynamic>? metadata;
    if (extension.toLowerCase() == '.safetensors') {
      try {
        metadata = await _apiService.getModelMetadata(type, fileName);
      } catch (e) {
        //
      }
    }

    return ComfyUIModelInfo(
      name: name,
      fileName: fileName,
      type: type,
      displayName: _generateDisplayName(name, metadata),
      metadata: metadata,
      description: metadata?['description'],
      tags: _extractTags(metadata),
    );
  }

  /// Generate a friendly display name for the model
  String _generateDisplayName(String name, Map<String, dynamic>? metadata) {
    // Use metadata name if available
    if (metadata != null) {
      final metadataName =
          metadata['name'] ?? metadata['title'] ?? metadata['model_name'];
      if (metadataName != null && metadataName.toString().isNotEmpty) {
        return metadataName.toString();
      }
    }

    // Clean up filename
    return name
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }

  /// Extract tags from model metadata
  List<String>? _extractTags(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;

    final tags = <String>[];

    // Add common metadata fields as tags
    final tagFields = [
      'tags',
      'keywords',
      'category',
      'style',
      'trigger_words',
    ];

    for (final field in tagFields) {
      final value = metadata[field];
      if (value != null) {
        if (value is List) {
          tags.addAll(value.map((e) => e.toString()));
        } else if (value is String && value.isNotEmpty) {
          // Split comma-separated tags
          tags.addAll(value.split(',').map((tag) => tag.trim()));
        }
      }
    }

    return tags.isNotEmpty ? tags : null;
  }

  /// Search models by query
  void searchModels(String query) {
    searchQuery.value = query;
  }

  /// Filter by model types
  void filterByTypes(List<String> types) {
    selectedTypes.value = types;
  }

  /// Filter by tags
  void filterByTags(List<String> tags) {
    selectedTags.value = tags;
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedTypes.clear();
    selectedTags.clear();
  }

  /// Get models by type
  List<ComfyUIModelInfo> getModelsByType(String type) {
    final folder = folders[type];
    return folder?.models ?? [];
  }

  /// Get model by name and type
  ComfyUIModelInfo? getModel(String name, String type) {
    final folder = folders[type];
    if (folder == null) return null;

    try {
      return folder.models.firstWhere(
        (model) => model.name == name || model.fileName == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get model metadata details
  Future<Map<String, dynamic>?> getModelMetadata(
    String fileName,
    String type,
  ) async {
    try {
      return await _apiService.getModelMetadata(type, fileName);
    } catch (e) {
      return null;
    }
  }

  /// Get popular models (most commonly used)
  List<ComfyUIModelInfo> getPopularModels({int limit = 10}) {
    // This could be enhanced with usage tracking
    final popular = allModels
        .where((model) => model.type == 'checkpoints' || model.type == 'loras')
        .take(limit)
        .toList();

    return popular;
  }

  /// Get recently added models
  List<ComfyUIModelInfo> getRecentModels({int limit = 10}) {
    final recent = allModels
        .where((model) => model.lastModified != null)
        .toList();
    recent.sort((a, b) => b.lastModified!.compareTo(a.lastModified!));
    return recent.take(limit).toList();
  }

  /// Get models with specific tags
  List<ComfyUIModelInfo> getModelsByTags(List<String> tags) {
    return allModels.where((model) {
      final modelTags = model.allTags.map((tag) => tag.toLowerCase()).toList();
      return tags.any((tag) => modelTags.contains(tag.toLowerCase()));
    }).toList();
  }

  /// Export model list as JSON
  String exportModelsAsJson() {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'total_models': totalModels,
      'total_folders': totalFolders,
      'folders': folders.map(
        (key, folder) => MapEntry(key, {
          'name': folder.name,
          'type': folder.type,
          'model_count': folder.modelCount,
          'total_size_bytes': folder.totalSizeBytes,
          'models': folder.models.map((model) => model.toJson()).toList(),
        }),
      ),
    };

    return jsonEncode(data);
  }

  /// Get model statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'total_models': totalModels,
      'total_folders': totalFolders,
      'total_size': totalSizeFormatted,
      'by_type': <String, dynamic>{},
      'models_with_metadata': allModels
          .where((m) => m.hasSafetensorsMetadata)
          .length,
      'available_tags': availableTags.length,
    };

    // Statistics by type
    for (final folder in folders.values) {
      stats['by_type'][folder.type] = {
        'count': folder.modelCount,
        'size': folder.sizeFormatted,
        'size_bytes': folder.totalSizeBytes,
      };
    }

    return stats;
  }

  /// Check if ComfyUI server has specific model
  Future<bool> hasModel(String fileName, String type) async {
    try {
      final models = await _apiService.getModels(type);
      return models.contains(fileName);
    } catch (e) {
      return false;
    }
  }

  /// Validate model file (check if it exists and is accessible)
  Future<bool> validateModel(String fileName, String type) async {
    try {
      final models = await _apiService.getModels(type);
      return models.contains(fileName);
    } catch (e) {
      return false;
    }
  }
}
