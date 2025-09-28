import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching file metadata such as size from URLs
class FileMetadataService {
  static final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10);
  static final Map<String, int> _sizeCache = {};

  /// Fetch file size from URL using HTTP HEAD request
  static Future<int?> getFileSize(String url) async {
    // Check cache first
    if (_sizeCache.containsKey(url)) {
      return _sizeCache[url];
    }

    try {
      debugPrint('Fetching file size for: $url');

      final response = await _dio.head(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Get content-length header
      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        final size = int.tryParse(contentLength);
        if (size != null) {
          // Cache the result
          _sizeCache[url] = size;
          debugPrint('File size for $url: ${_formatBytes(size)}');
          return size;
        }
      }

      // If HEAD request doesn't work, try OPTIONS
      if (response.statusCode != 200) {
        return await _tryOptionsRequest(url);
      }

      debugPrint('No content-length header found for: $url');
      return null;
    } catch (e) {
      debugPrint('Error fetching file size for $url: $e');

      // Try with different headers (some servers require User-Agent)
      return await _tryWithUserAgent(url);
    }
  }

  /// Try OPTIONS request as fallback
  static Future<int?> _tryOptionsRequest(String url) async {
    try {
      final response = await _dio.fetch(
        RequestOptions(
          path: url,
          method: 'OPTIONS',
        ),
      );

      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        final size = int.tryParse(contentLength);
        if (size != null) {
          _sizeCache[url] = size;
          return size;
        }
      }
    } catch (e) {
      debugPrint('OPTIONS request failed for $url: $e');
    }
    return null;
  }

  /// Try with User-Agent header (some servers require this)
  static Future<int?> _tryWithUserAgent(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          },
        ),
      );

      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        final size = int.tryParse(contentLength);
        if (size != null) {
          _sizeCache[url] = size;
          return size;
        }
      }
    } catch (e) {
      debugPrint('User-Agent request failed for $url: $e');
    }
    return null;
  }

  /// Fetch file sizes for multiple URLs concurrently
  static Future<Map<String, int?>> getFileSizes(List<String> urls) async {
    final results = <String, int?>{};

    // Process in batches to avoid overwhelming servers
    const batchSize = 5;
    for (int i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize).toList();
      final futures = batch.map((url) => getFileSize(url));
      final sizes = await Future.wait(futures);

      for (int j = 0; j < batch.length; j++) {
        results[batch[j]] = sizes[j];
      }

      // Small delay between batches to be respectful to servers
      if (i + batchSize < urls.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Clear the cache
  static void clearCache() {
    _sizeCache.clear();
  }

  /// Get cached size if available
  static int? getCachedSize(String url) {
    return _sizeCache[url];
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Format bytes to human readable string (public method)
  static String formatBytes(int bytes) => _formatBytes(bytes);
}
