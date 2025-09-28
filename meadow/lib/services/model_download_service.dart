import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import '../models/downloadable_model.dart';

/// Download progress information for a specific file
class DownloadProgress {
  final String filename;
  final int downloadedBytes;
  final int totalBytes;
  final double percentage;
  final double speed; // bytes per second
  final String status;

  const DownloadProgress({
    required this.filename,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.percentage,
    required this.speed,
    required this.status,
  });

  String get speedFormatted {
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get downloadedFormatted => _formatBytes(downloadedBytes);
  String get totalFormatted => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Service for downloading AI model weights with resume capability
class ModelDownloadService extends GetxService {
  static ModelDownloadService get instance => Get.find<ModelDownloadService>();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _activeTasks = {};
  final Map<String, DateTime> _lastProgressUpdate = {};

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Download a complete model to the specified ComfyUI directory
  Future<bool> downloadModel({
    required DownloadableModel model,
    required String comfyUIDirectory,
    required Function(DownloadProgress) onProgress,
    Function(String error)? onError,
    Function()? onCompleted,
  }) async {
    try {
      // Validate ComfyUI directory
      final comfyUIDir = Directory(comfyUIDirectory);
      if (!await comfyUIDir.exists()) {
        onError?.call('ComfyUI directory does not exist: $comfyUIDirectory');
        return false;
      }

      // Download each weight file
      for (int i = 0; i < model.weights.length; i++) {
        final weight = model.weights[i];
        final success = await downloadWeight(
          weight: weight,
          comfyUIDirectory: comfyUIDirectory,
          onProgress: (progress) {
            // Calculate overall model progress
            final overallProgress = DownloadProgress(
              filename: model.name,
              downloadedBytes: progress.downloadedBytes,
              totalBytes: progress.totalBytes,
              percentage:
                  (i + progress.percentage / 100) / model.weights.length,
              speed: progress.speed,
              status:
                  'Downloading ${weight.filename} (${i + 1}/${model.weights.length})',
            );
            onProgress(overallProgress);
          },
          onError: onError,
        );

        if (!success) {
          return false;
        }
      }

      onCompleted?.call();
      return true;
    } catch (e) {
      onError?.call('Download failed: $e');
      return false;
    }
  }

  /// Download a single weight file with resume capability
  Future<bool> downloadWeight({
    required ModelWeight weight,
    required String comfyUIDirectory,
    required Function(DownloadProgress) onProgress,
    Function(String error)? onError,
  }) async {
    final taskId = '${weight.dir}_${weight.filename}';

    try {
      // Create target directory
      final targetDir = Directory(
        path.join(comfyUIDirectory, 'models', weight.dir),
      );
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetFile = File(path.join(targetDir.path, weight.filename));
      final tempFile = File('${targetFile.path}.download');

      // Check if file already exists and is complete
      if (await targetFile.exists()) {
        final fileSize = await targetFile.length();
        if (weight.fileSize != null && fileSize == weight.fileSize) {
          onProgress(
            DownloadProgress(
              filename: weight.filename,
              downloadedBytes: fileSize,
              totalBytes: fileSize,
              percentage: 100.0,
              speed: 0.0,
              status: 'Already downloaded',
            ),
          );
          return true;
        }
      }

      // Check for partial download
      int startByte = 0;
      if (await tempFile.exists()) {
        startByte = await tempFile.length();
      }

      // Setup cancel token
      final cancelToken = CancelToken();
      _activeTasks[taskId] = cancelToken;

      // Get file info if not available
      int? totalBytes = weight.fileSize;
      if (totalBytes == null) {
        try {
          final headResponse = await _dio.head(weight.url);
          totalBytes =
              int.tryParse(
                headResponse.headers.value('content-length') ?? '0',
              ) ??
              0;
        } catch (e) {
          // Ignore head request errors, we'll get the size during download
        }
      }

      // Download with resume support
      final response = await _dio.download(
        weight.url,
        tempFile.path,
        cancelToken: cancelToken,
        options: Options(
          headers: startByte > 0 ? {'Range': 'bytes=$startByte-'} : null,
        ),
        onReceiveProgress: (received, total) {
          final now = DateTime.now();
          final lastUpdate = _lastProgressUpdate[taskId];

          // Throttle progress updates to avoid UI spam
          if (lastUpdate == null ||
              now.difference(lastUpdate).inMilliseconds > 100) {
            _lastProgressUpdate[taskId] = now;

            final actualReceived = startByte + received;
            final actualTotal = totalBytes ?? (startByte + total);
            final percentage = actualTotal > 0
                ? (actualReceived / actualTotal) * 100
                : 0.0;

            // Calculate speed (bytes per second)
            double speed = 0.0;
            if (lastUpdate != null) {
              final timeDiff =
                  now.difference(lastUpdate).inMilliseconds / 1000.0;
              if (timeDiff > 0) {
                speed = received / timeDiff;
              }
            }

            onProgress(
              DownloadProgress(
                filename: weight.filename,
                downloadedBytes: actualReceived,
                totalBytes: actualTotal,
                percentage: percentage,
                speed: speed,
                status: 'Downloading',
              ),
            );
          }
        },
      );

      // Move temp file to final location
      if (response.statusCode == 200 || response.statusCode == 206) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);

        // Final progress update
        final finalSize = await targetFile.length();
        onProgress(
          DownloadProgress(
            filename: weight.filename,
            downloadedBytes: finalSize,
            totalBytes: finalSize,
            percentage: 100.0,
            speed: 0.0,
            status: 'Completed',
          ),
        );

        return true;
      } else {
        onError?.call('Download failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        onError?.call('Download cancelled');
      } else {
        onError?.call('Download error: $e');
      }
      return false;
    } finally {
      _activeTasks.remove(taskId);
      _lastProgressUpdate.remove(taskId);
    }
  }

  /// Cancel a specific download task
  void cancelDownload(String taskId) {
    final cancelToken = _activeTasks[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled');
    }
  }

  /// Cancel all active downloads
  void cancelAllDownloads() {
    for (final cancelToken in _activeTasks.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('All downloads cancelled');
      }
    }
    _activeTasks.clear();
    _lastProgressUpdate.clear();
  }

  /// Check if a weight file exists in the ComfyUI directory
  Future<bool> isWeightDownloaded({
    required ModelWeight weight,
    required String comfyUIDirectory,
  }) async {
    final targetFile = File(
      path.join(comfyUIDirectory, 'models', weight.dir, weight.filename),
    );

    if (!await targetFile.exists()) {
      return false;
    }

    // Check file size if available
    if (weight.fileSize != null) {
      final actualSize = await targetFile.length();
      return actualSize == weight.fileSize;
    }

    return true;
  }

  /// Check which weights are already downloaded for a model
  Future<List<ModelWeight>> getDownloadedWeights({
    required DownloadableModel model,
    required String comfyUIDirectory,
  }) async {
    final downloadedWeights = <ModelWeight>[];

    for (final weight in model.weights) {
      if (await isWeightDownloaded(
        weight: weight,
        comfyUIDirectory: comfyUIDirectory,
      )) {
        downloadedWeights.add(weight.copyWith(isDownloaded: true));
      }
    }

    return downloadedWeights;
  }

  /// Get the download status of a complete model
  Future<ModelDownloadStatus> getModelDownloadStatus({
    required DownloadableModel model,
    required String comfyUIDirectory,
  }) async {
    final downloadedWeights = await getDownloadedWeights(
      model: model,
      comfyUIDirectory: comfyUIDirectory,
    );

    if (downloadedWeights.length == model.weights.length) {
      return ModelDownloadStatus.completed;
    } else if (downloadedWeights.isNotEmpty) {
      return ModelDownloadStatus.paused; // Partially downloaded
    } else {
      return ModelDownloadStatus.notStarted;
    }
  }

  /// Verify the integrity of downloaded files
  Future<bool> verifyModelIntegrity({
    required DownloadableModel model,
    required String comfyUIDirectory,
  }) async {
    for (final weight in model.weights) {
      final isValid = await isWeightDownloaded(
        weight: weight,
        comfyUIDirectory: comfyUIDirectory,
      );
      if (!isValid) {
        return false;
      }
    }
    return true;
  }

  /// Get available storage space in the ComfyUI directory
  Future<int> getAvailableSpace(String comfyUIDirectory) async {
    try {
      final directory = Directory(comfyUIDirectory);
      if (!await directory.exists()) {
        return 0;
      }

      // This is a simplified check - in a real implementation,
      // you might want to use platform-specific APIs for accurate disk space
      final tempFile = File(path.join(comfyUIDirectory, '.space_check_temp'));
      await tempFile.create();
      await tempFile.delete();

      // Return a large number as a placeholder
      // In practice, you'd implement platform-specific disk space checking
      return 1024 * 1024 * 1024 * 100; // 100GB placeholder
    } catch (e) {
      return 0;
    }
  }

  /// Clean up incomplete downloads
  Future<void> cleanupIncompleteDownloads(String comfyUIDirectory) async {
    try {
      final modelsDir = Directory(path.join(comfyUIDirectory, 'models'));
      if (!await modelsDir.exists()) return;

      await for (final entity in modelsDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.download')) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore individual file deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
