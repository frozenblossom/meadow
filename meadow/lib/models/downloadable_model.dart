/// Represents a weight file that needs to be downloaded for a model
class ModelWeight {
  /// The filename to save as
  final String filename;

  /// The directory relative to ComfyUI models folder (e.g., "diffusion_models", "text_encoders")
  final String dir;

  /// The download URL for this weight file
  final String url;

  /// File size in bytes (optional, fetched from server)
  final int? fileSize;

  /// Whether this file is already downloaded
  final bool isDownloaded;

  /// Download progress percentage (0.0 to 1.0)
  final double downloadProgress;

  const ModelWeight({
    required this.filename,
    required this.dir,
    required this.url,
    this.fileSize,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });

  factory ModelWeight.fromJson(Map<String, dynamic> json) {
    return ModelWeight(
      filename: json['filename'] as String,
      dir: json['dir'] as String,
      url: json['url'] as String,
      fileSize: json['fileSize'] as int?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      downloadProgress: json['downloadProgress'] as double? ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'dir': dir,
      'url': url,
      'fileSize': fileSize,
      'isDownloaded': isDownloaded,
      'downloadProgress': downloadProgress,
    };
  }

  /// Get the full relative path for this weight file
  String get relativePath => '$dir/$filename';

  /// Create a copy with updated download status
  ModelWeight copyWith({
    String? filename,
    String? dir,
    String? url,
    int? fileSize,
    bool? isDownloaded,
    double? downloadProgress,
  }) {
    return ModelWeight(
      filename: filename ?? this.filename,
      dir: dir ?? this.dir,
      url: url ?? this.url,
      fileSize: fileSize ?? this.fileSize,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

/// Represents a ComfyUI workflow for a model (optional)
class ModelWorkflow {
  /// Workflow name or identifier
  final String? name;

  /// Workflow description
  final String? description;

  /// ComfyUI workflow JSON data
  final Map<String, dynamic>? workflowData;

  /// URL to download the workflow file
  final String? workflowUrl;

  const ModelWorkflow({
    this.name,
    this.description,
    this.workflowData,
    this.workflowUrl,
  });

  factory ModelWorkflow.fromJson(Map<String, dynamic> json) {
    return ModelWorkflow(
      name: json['name'] as String?,
      description: json['description'] as String?,
      workflowData: json['workflowData'] as Map<String, dynamic>?,
      workflowUrl: json['workflowUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'workflowData': workflowData,
      'workflowUrl': workflowUrl,
    };
  }
}

/// Download status for a model
enum ModelDownloadStatus {
  /// Not started downloading
  notStarted,

  /// Currently downloading
  downloading,

  /// Download completed successfully
  completed,

  /// Download failed or was cancelled
  failed,

  /// Download is paused (can be resumed)
  paused,
}

/// Represents a downloadable AI model with its weights and metadata
class DownloadableModel {
  /// Unique identifier for the model
  final String id;

  /// Display name of the model
  final String name;

  /// Model description
  final String description;

  /// List of weight files to download
  final List<ModelWeight> weights;

  /// Optional workflow information
  final ModelWorkflow? workflow;

  /// Model category (e.g., "diffusion", "text-encoder", "vae")
  final String? category;

  /// Current download status
  final ModelDownloadStatus downloadStatus;

  /// Overall download progress (0.0 to 1.0)
  final double overallProgress;

  const DownloadableModel({
    required this.id,
    required this.name,
    required this.description,
    required this.weights,
    this.workflow,
    this.category,
    this.downloadStatus = ModelDownloadStatus.notStarted,
    this.overallProgress = 0.0,
  });

  factory DownloadableModel.fromJson(Map<String, dynamic> json) {
    return DownloadableModel(
      id: json['id'] as String? ?? json['name'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      weights:
          (json['weights'] as List<dynamic>?)
              ?.map((w) => ModelWeight.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      workflow: json['workflow'] != null
          ? ModelWorkflow.fromJson(json['workflow'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      downloadStatus: ModelDownloadStatus.values.firstWhere(
        (status) => status.name == (json['downloadStatus'] as String?),
        orElse: () => ModelDownloadStatus.notStarted,
      ),
      overallProgress: json['overallProgress'] as double? ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'weights': weights.map((w) => w.toJson()).toList(),
      'workflow': workflow?.toJson(),
      'category': category,
      'downloadStatus': downloadStatus.name,
      'overallProgress': overallProgress,
    };
  }

  /// Get total size of all weight files in bytes
  int get totalSize {
    return weights.fold(0, (sum, weight) => sum + (weight.fileSize ?? 0));
  }

  /// Get human-readable total size
  String get totalSizeFormatted {
    final bytes = totalSize;
    if (bytes == 0) return '';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int index = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[index]}';
  }

  /// Check if all weights are downloaded
  bool get isFullyDownloaded {
    return weights.every((weight) => weight.isDownloaded);
  }

  /// Get number of downloaded weights
  int get downloadedWeightCount {
    return weights.where((weight) => weight.isDownloaded).length;
  }

  /// Get download progress summary text
  String get downloadProgressText {
    if (isFullyDownloaded) return 'Downloaded';
    if (downloadStatus == ModelDownloadStatus.downloading) {
      return 'Downloading ${(overallProgress * 100).toStringAsFixed(1)}%';
    }
    if (downloadStatus == ModelDownloadStatus.failed) return 'Failed';
    if (downloadStatus == ModelDownloadStatus.paused) return 'Paused';

    return '$downloadedWeightCount/${weights.length} files';
  }

  /// Create a copy with updated status and progress
  DownloadableModel copyWith({
    String? id,
    String? name,
    String? description,
    List<ModelWeight>? weights,
    ModelWorkflow? workflow,
    String? category,
    ModelDownloadStatus? downloadStatus,
    double? overallProgress,
  }) {
    return DownloadableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      weights: weights ?? this.weights,
      workflow: workflow ?? this.workflow,
      category: category ?? this.category,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}

/// Container for a list of downloadable models
class ModelCatalog {
  /// List of available models
  final List<DownloadableModel> models;

  /// Catalog version for caching
  final String? version;

  /// Last updated timestamp
  final DateTime? lastUpdated;

  const ModelCatalog({
    required this.models,
    this.version,
    this.lastUpdated,
  });

  factory ModelCatalog.fromJson(Map<String, dynamic> json) {
    return ModelCatalog(
      models:
          (json['models'] as List<dynamic>?)
              ?.map(
                (m) => DownloadableModel.fromJson(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      version: json['version'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'models': models.map((m) => m.toJson()).toList(),
      'version': version,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create empty catalog
  factory ModelCatalog.empty() {
    return const ModelCatalog(models: []);
  }

  /// Filter models by category
  List<DownloadableModel> getModelsByCategory(String category) {
    return models.where((model) => model.category == category).toList();
  }

  /// Search models by name or description
  List<DownloadableModel> searchModels(String query) {
    final lowerQuery = query.toLowerCase();
    return models.where((model) {
      return model.name.toLowerCase().contains(lowerQuery) ||
          model.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
