import 'dart:io';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/local_workspace.dart';
import 'package:meadow/services/thumbnail_service.dart';
import 'package:path/path.dart' as p;

class LocalAssetService {
  final LocalWorkspace workspace;

  LocalAssetService(this.workspace);

  /// Get all assets from the workspace, optionally filtered by type
  Future<List<Asset>> getAssets({AssetType? filterType}) async {
    final assets = await workspace.getAssets(page: 1, pageSize: 1000);

    if (filterType != null) {
      return assets.where((asset) => asset.type == filterType).toList();
    }

    return assets;
  }

  /// Add an asset from a file
  Future<LocalAsset> addAsset(
    File file, {
    String? desiredName,
  }) async {
    return await workspace.addAssetFromFile(
      file,
      customName: desiredName,
    );
  }

  /// Rename an asset
  Future<LocalAsset> renameAsset(String assetId, String newName) async {
    final asset = await workspace.getAssetById(assetId);
    if (asset == null || asset is! LocalAsset) {
      throw Exception('Asset not found');
    }

    final currentFile = asset.file;
    final currentDir = currentFile.parent;
    final extension = p.extension(currentFile.path);
    final newFileName = newName.endsWith(extension)
        ? newName
        : '$newName$extension';
    final newFile = File(p.join(currentDir.path, newFileName));

    // Check if target name already exists
    if (await newFile.exists()) {
      throw Exception('An asset with this name already exists');
    }

    // Rename the main file
    await currentFile.rename(newFile.path);

    // Rename the metadata file if it exists
    final metadataFile = File('${currentFile.path}.metadata.json');
    if (await metadataFile.exists()) {
      final newMetadataFile = File('${newFile.path}.metadata.json');
      await metadataFile.rename(newMetadataFile.path);
    }

    // Return new LocalAsset with the renamed file
    return LocalAsset.fromPath(newFile.path);
  }

  /// Delete an asset
  Future<void> deleteAsset(String assetId) async {
    await workspace.removeAsset(assetId);
  }

  /// Get asset by ID
  Future<Asset?> getAssetById(String assetId) async {
    return await workspace.getAssetById(assetId);
  }

  /// Count total assets
  Future<int> countAssets() async {
    return await workspace.countAssets();
  }

  /// Generate thumbnails for all assets
  Future<void> generateAllThumbnails({
    void Function(int current, int total)? onProgress,
  }) async {
    final assets = await getAssets();
    final localAssets = assets.whereType<LocalAsset>().toList();

    await ThumbnailService.generateThumbnails(
      localAssets,
      onProgress: onProgress,
    );
  }

  /// Generate thumbnail for a specific asset
  Future<File?> generateThumbnail(String assetId, {int size = 256}) async {
    final asset = await getAssetById(assetId);
    if (asset is LocalAsset) {
      return await ThumbnailService.getThumbnail(asset, size: size);
    }
    return null;
  }

  /// Clean up orphaned thumbnails in the workspace
  Future<void> cleanupThumbnails() async {
    final workspaceDir = await workspace.getWorkspaceDirectory();
    await ThumbnailService.cleanupOrphanedThumbnails(workspaceDir);
  }

  /// Regenerate all thumbnails (force recreate)
  Future<void> regenerateAllThumbnails({
    void Function(int current, int total)? onProgress,
  }) async {
    final assets = await getAssets();
    final localAssets = assets.whereType<LocalAsset>().toList();

    for (int i = 0; i < localAssets.length; i++) {
      onProgress?.call(i + 1, localAssets.length);
      await localAssets[i].regenerateThumbnail();
    }
  }
}

/// Utility function to determine asset type from filename
AssetType determineAssetType(String filename) {
  final ext = p.extension(filename).toLowerCase();

  switch (ext) {
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.bmp':
    case '.webp':
    case '.svg':
    case '.ico':
      return AssetType.image;
    case '.mp4':
    case '.mov':
    case '.avi':
    case '.mkv':
    case '.webm':
    case '.flv':
    case '.wmv':
      return AssetType.video;
    case '.mp3':
    case '.wav':
    case '.aac':
    case '.flac':
    case '.ogg':
    case '.m4a':
      return AssetType.audio;
    case '.txt':
    case '.md':
    case '.doc':
    case '.docx':
    case '.pdf':
    case '.rtf':
      return AssetType.text;
    default:
      return AssetType.image; // Default fallback
  }
}
