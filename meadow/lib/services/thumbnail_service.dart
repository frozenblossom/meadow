import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
// import 'package:audiotags/audiotags.dart';

class ThumbnailService {
  static const int defaultThumbnailSize = 1024;
  static const String thumbnailSuffix = '.thumb.jpg';

  /// Generate or retrieve thumbnail for an asset
  static Future<File?> getThumbnail(
    LocalAsset asset, {
    int size = defaultThumbnailSize,
  }) async {
    final thumbnailPath = '${asset.file.path}$thumbnailSuffix';
    final thumbnailFile = File(thumbnailPath);

    // Return existing thumbnail if it exists and is newer than the source file
    if (await thumbnailFile.exists()) {
      final sourceStat = await asset.file.stat();
      final thumbStat = await thumbnailFile.stat();

      if (thumbStat.modified.isAfter(sourceStat.modified)) {
        return thumbnailFile;
      }
    }

    // Generate new thumbnail based on asset type
    try {
      switch (asset.type) {
        case AssetType.image:
          return await _generateImageThumbnail(asset, thumbnailFile, size);
        case AssetType.video:
          return await _generateVideoThumbnail(asset, thumbnailFile, size);
        case AssetType.audio:
          return await _generateAudioThumbnail(asset, thumbnailFile, size);
        default:
          return await _generateGenericThumbnail(asset, thumbnailFile, size);
      }
    } catch (e) {
      // print('Error generating thumbnail for ${asset.displayName}: $e');
      return null;
    }
  }

  /// Generate thumbnail for image assets
  static Future<File> _generateImageThumbnail(
    LocalAsset asset,
    File thumbnailFile,
    int size,
  ) async {
    final imageBytes = await asset.file.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate thumbnail dimensions maintaining aspect ratio
    final aspectRatio = originalImage.width / originalImage.height;
    int thumbWidth, thumbHeight;

    if (aspectRatio > 1) {
      thumbWidth = size;
      thumbHeight = (size / aspectRatio).round();
    } else {
      thumbWidth = (size * aspectRatio).round();
      thumbHeight = size;
    }

    // Resize image
    final thumbnail = img.copyResize(
      originalImage,
      width: thumbWidth,
      height: thumbHeight,
      interpolation: img.Interpolation.linear,
    );

    // Encode as JPEG
    final jpegBytes = img.encodeJpg(thumbnail, quality: 85);

    // Save thumbnail
    await thumbnailFile.writeAsBytes(jpegBytes);
    return thumbnailFile;
  }

  /// Generate thumbnail for video assets using ProVideoEditor
  static Future<File> _generateVideoThumbnail(
    LocalAsset asset,
    File thumbnailFile,
    int size,
  ) async {
    try {
      // Use ProVideoEditor to extract thumbnail
      final thumbnails = await ProVideoEditor.instance.getThumbnails(
        ThumbnailConfigs(
          video: EditorVideo.file(asset.file),
          outputFormat: ThumbnailFormat.jpeg,
          timestamps: const [
            Duration(seconds: 2),
          ], // Extract frame at 2 seconds
          outputSize: Size(size.toDouble(), size.toDouble()),
          boxFit: ThumbnailBoxFit.cover,
        ),
      );

      if (thumbnails.isNotEmpty) {
        await thumbnailFile.writeAsBytes(thumbnails.first);
        return thumbnailFile;
      } else {
        throw Exception('No thumbnails generated');
      }
    } catch (e) {
      // print('ProVideoEditor failed, trying fallback: $e');
      // Fallback to generic thumbnail
      return await _generateGenericThumbnail(asset, thumbnailFile, size);
    }
  }

  /// Generate thumbnail for audio assets by extracting embedded artwork
  static Future<File> _generateAudioThumbnail(
    LocalAsset asset,
    File thumbnailFile,
    int size,
  ) async {
    /*try {
      // Try to extract embedded artwork from audio metadata using audiotags
      final tag = await AudioTags.read(asset.file.path);

      if (tag != null && tag.pictures.isNotEmpty) {
        final artwork = tag.pictures.first;

        if (artwork.bytes.isNotEmpty) {
          // Decode and resize the embedded artwork
          final originalImage = img.decodeImage(artwork.bytes);

          if (originalImage != null) {
            final thumbnail = img.copyResize(
              originalImage,
              width: size,
              height: size,
              interpolation: img.Interpolation.linear,
            );

            final jpegBytes = img.encodeJpg(thumbnail, quality: 85);
            await thumbnailFile.writeAsBytes(jpegBytes);
            return thumbnailFile;
          }
        }
      }
    } catch (e) {
      print('Failed to extract audio artwork: $e');
    }
    */

    // Fallback to audio placeholder
    return await _generateAudioPlaceholder(thumbnailFile, size);
  }

  /// Generate a generic placeholder thumbnail
  static Future<File> _generateGenericThumbnail(
    LocalAsset asset,
    File thumbnailFile,
    int size,
  ) async {
    // Create a simple colored square with file extension text
    final image = img.Image(width: size, height: size);

    // Fill with a color based on asset type
    final color = _getTypeColor(asset.type);
    img.fill(image, color: color);

    // You could add text overlay here if needed
    // For now, just save the colored square
    final jpegBytes = img.encodeJpg(image, quality: 85);
    await thumbnailFile.writeAsBytes(jpegBytes);

    return thumbnailFile;
  }

  /// Generate audio-specific placeholder
  static Future<File> _generateAudioPlaceholder(
    File thumbnailFile,
    int size,
  ) async {
    // Create a music note icon placeholder
    final image = img.Image(width: size, height: size);

    // Fill with audio-themed color (purple/blue)
    img.fill(image, color: img.ColorRgb8(88, 86, 214));

    // Add a simple circle in the center (like a record)
    img.fillCircle(
      image,
      x: size ~/ 2,
      y: size ~/ 2,
      radius: size ~/ 3,
      color: img.ColorRgb8(200, 200, 200),
    );

    // Add smaller inner circle
    img.fillCircle(
      image,
      x: size ~/ 2,
      y: size ~/ 2,
      radius: size ~/ 8,
      color: img.ColorRgb8(88, 86, 214),
    );

    final jpegBytes = img.encodeJpg(image, quality: 85);
    await thumbnailFile.writeAsBytes(jpegBytes);

    return thumbnailFile;
  }

  /// Get color based on asset type
  static img.Color _getTypeColor(AssetType type) {
    switch (type) {
      case AssetType.image:
        return img.ColorRgb8(34, 197, 94); // Green
      case AssetType.video:
        return img.ColorRgb8(239, 68, 68); // Red
      case AssetType.audio:
        return img.ColorRgb8(88, 86, 214); // Purple
      case AssetType.text:
        return img.ColorRgb8(59, 130, 246); // Blue
    }
  }

  /// Check if thumbnail exists for an asset
  static Future<bool> hasThumbnail(LocalAsset asset) async {
    final thumbnailPath = '${asset.file.path}$thumbnailSuffix';
    return await File(thumbnailPath).exists();
  }

  /// Delete thumbnail for an asset
  static Future<void> deleteThumbnail(LocalAsset asset) async {
    final thumbnailPath = '${asset.file.path}$thumbnailSuffix';
    final thumbnailFile = File(thumbnailPath);

    if (await thumbnailFile.exists()) {
      await thumbnailFile.delete();
    }
  }

  /// Get thumbnail path for an asset
  static String getThumbnailPath(LocalAsset asset) {
    return '${asset.file.path}$thumbnailSuffix';
  }

  /// Regenerate thumbnail (force recreate)
  static Future<File?> regenerateThumbnail(
    LocalAsset asset, {
    int size = defaultThumbnailSize,
  }) async {
    // Delete existing thumbnail first
    await deleteThumbnail(asset);

    // Generate new thumbnail
    return await getThumbnail(asset, size: size);
  }

  /// Batch generate thumbnails for multiple assets
  static Future<List<File?>> generateThumbnails(
    List<LocalAsset> assets, {
    int size = defaultThumbnailSize,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <File?>[];

    for (int i = 0; i < assets.length; i++) {
      onProgress?.call(i + 1, assets.length);

      try {
        final thumbnail = await getThumbnail(assets[i], size: size);
        results.add(thumbnail);
      } catch (e) {
        // print('Failed to generate thumbnail for ${assets[i].displayName}: $e');
        results.add(null);
      }
    }

    return results;
  }

  /// Clean up orphaned thumbnails (thumbnails without corresponding assets)
  static Future<void> cleanupOrphanedThumbnails(Directory workspaceDir) async {
    final thumbnailFiles = workspaceDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith(thumbnailSuffix))
        .toList();

    for (final thumbnailFile in thumbnailFiles) {
      // Check if corresponding asset exists
      final assetPath = thumbnailFile.path.substring(
        0,
        thumbnailFile.path.length - thumbnailSuffix.length,
      );
      final assetFile = File(assetPath);

      if (!await assetFile.exists()) {
        // Asset doesn't exist, delete orphaned thumbnail
        try {
          await thumbnailFile.delete();
          //print('Deleted orphaned thumbnail: ${thumbnailFile.path}');
        } catch (e) {
          //print('Failed to delete orphaned thumbnail: $e');
        }
      }
    }
  }
}
