import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:meadow/models/local_asset.dart';
import 'package:meadow/models/workspace_settings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/workspace.dart';
import 'package:meadow/services/thumbnail_service.dart';

class LocalWorkspace extends Workspace {
  LocalWorkspace({
    required super.id,
    required super.ownerId,
    required super.isTeamOwned,
    required super.name,
    super.defaultWidth,
    super.defaultHeight,
    super.videoDurationSeconds = 5,
  });

  Future<Directory> _getWorkspaceDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final wsDir = Directory(
      p.join(appDocDir.path, 'meadow_user_assets', name),
    );
    if (!await wsDir.exists()) {
      await wsDir.create(recursive: true);
    }
    return wsDir;
  }

  /// Get the workspace directory (public access for services)
  Future<Directory> getWorkspaceDirectory() async {
    return await _getWorkspaceDir();
  }

  /// Get the settings file path for this workspace
  Future<File> _getSettingsFile() async {
    final wsDir = await _getWorkspaceDir();
    return File(p.join(wsDir.path, 'settings.json'));
  }

  /// Load workspace settings from settings.json
  Future<WorkspaceSettings> loadSettings() async {
    final settingsFile = await _getSettingsFile();

    if (await settingsFile.exists()) {
      try {
        final content = await settingsFile.readAsString();
        return WorkspaceSettings.fromJsonString(content);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading workspace settings: $e');
        }
        // Return default settings if file is corrupted
        return WorkspaceSettings(
          defaultWidth: defaultWidth,
          defaultHeight: defaultHeight,
          videoDurationSeconds: videoDurationSeconds,
        );
      }
    }

    // Create default settings if file doesn't exist
    final defaultSettings = WorkspaceSettings(
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
      videoDurationSeconds: videoDurationSeconds,
    );

    // Save the default settings
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  /// Save workspace settings to settings.json
  Future<void> saveSettings(WorkspaceSettings settings) async {
    final settingsFile = await _getSettingsFile();

    try {
      await settingsFile.writeAsString(settings.toJsonString());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving workspace settings: $e');
      }
      rethrow;
    }
  }

  /// Create a new LocalWorkspace instance from settings
  static Future<LocalWorkspace> fromSettings({
    required String id,
    required String name,
    required String ownerId,
    required bool isTeamOwned,
  }) async {
    // Create initial workspace to load settings
    final tempWorkspace = LocalWorkspace(
      id: id,
      name: name,
      ownerId: ownerId,
      isTeamOwned: isTeamOwned,
    );

    // Load settings and create workspace with proper values
    final settings = await tempWorkspace.loadSettings();

    return LocalWorkspace(
      id: id,
      name: name,
      ownerId: ownerId,
      isTeamOwned: isTeamOwned,
      defaultWidth: settings.defaultWidth,
      defaultHeight: settings.defaultHeight,
      videoDurationSeconds: settings.videoDurationSeconds,
    );
  }

  Future<File> _getAssetFile(String assetId) async {
    final wsDir = await _getWorkspaceDir();
    return File(p.join(wsDir.path, assetId));
  }

  @override
  Future<void> addAsset(covariant LocalAsset asset) async {
    final wsDir = await _getWorkspaceDir();

    // Handle file name conflicts
    final originalName = p.basename(asset.file.path);
    var targetFile = File(p.join(wsDir.path, originalName));
    int counter = 1;
    while (await targetFile.exists()) {
      final nameWithoutExt = p.basenameWithoutExtension(originalName);
      final ext = p.extension(originalName);
      final newName = '${nameWithoutExt}_$counter$ext';
      targetFile = File(p.join(wsDir.path, newName));
      counter++;
    }

    // Copy the asset file to the workspace directory
    await asset.file.copy(targetFile.path);

    // Copy metadata file if it exists
    final sourceMetadataFile = File('${asset.file.path}.metadata.json');
    if (await sourceMetadataFile.exists()) {
      final targetMetadataFile = File('${targetFile.path}.metadata.json');
      await sourceMetadataFile.copy(targetMetadataFile.path);
    }

    // If the asset has in-memory metadata, save it (this will merge or override)
    if (asset.metadata.isNotEmpty) {
      final newAsset = LocalAsset(targetFile, metadata: asset.metadata);
      await newAsset.updateMetadata(asset.metadata);
    }
  }

  /// Add an asset from file with optional custom name
  Future<LocalAsset> addAssetFromFile(
    File sourceFile, {
    String? customName,
  }) async {
    final wsDir = await _getWorkspaceDir();

    // Determine target filename
    final originalName = p.basename(sourceFile.path);
    final targetName = customName ?? originalName;
    final targetFile = File(p.join(wsDir.path, targetName));

    // Handle file name conflicts
    var finalTargetFile = targetFile;
    int counter = 1;
    while (await finalTargetFile.exists()) {
      final nameWithoutExt = p.basenameWithoutExtension(targetName);
      final ext = p.extension(targetName);
      final newName = '${nameWithoutExt}_$counter$ext';
      finalTargetFile = File(p.join(wsDir.path, newName));
      counter++;
    }

    // Copy the file
    await sourceFile.copy(finalTargetFile.path);

    // Create and return LocalAsset
    final asset = LocalAsset(finalTargetFile);

    // Initialize metadata
    await asset.updateMetadata({
      'addedAt': DateTime.now().toIso8601String(),
      'originalName': originalName,
      'status': 'completed',
    });

    // Generate thumbnail in the background
    ThumbnailService.getThumbnail(asset)
        .then((thumbnail) {
          if (thumbnail != null) {
            if (kDebugMode) {
              print('Thumbnail generated for ${asset.displayName}');
            }
          }
        })
        .catchError((error) {
          if (kDebugMode) {
            print(
              'Failed to generate thumbnail for ${asset.displayName}: $error',
            );
          }
        });

    return asset;
  }

  @override
  Future<int> countAssets() async {
    final wsDir = await _getWorkspaceDir();
    final files = wsDir.listSync().whereType<File>().where(
      (f) =>
          !f.path.endsWith('.metadata.json') && !f.path.endsWith('.thumb.jpg'),
    );
    return files.length;
  }

  @override
  Future<void> deleteWorkspace() async {
    final wsDir = await _getWorkspaceDir();
    if (await wsDir.exists()) {
      await wsDir.delete(recursive: true);
    }
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    final file = await _getAssetFile(assetId);
    if (await file.exists()) {
      return await _createLocalAssetWithMetadata(file);
    }
    return null;
  }

  @override
  Future<List<Asset>> getAssets({
    required int page,
    required int pageSize,
  }) async {
    final wsDir = await _getWorkspaceDir();
    final files = wsDir.listSync().whereType<File>().where(
      (f) {
        final excludedExtensions = [
          '.metadata.json',
          '.thumb.jpg',
          'settings.json',
          '.DS_Store',
        ];
        return !excludedExtensions.any((ext) => f.path.endsWith(ext));
      },
    ).toList();
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    final pagedFiles = files.sublist(
      start,
      end > files.length ? files.length : end,
    );

    // Load metadata for each file
    final assetsWithMetadata = <LocalAsset>[];
    for (final file in pagedFiles) {
      final asset = await _createLocalAssetWithMetadata(file);
      assetsWithMetadata.add(asset);
    }

    return assetsWithMetadata;
  }

  @override
  Future<void> removeAsset(String assetId) async {
    final file = await _getAssetFile(assetId);
    if (await file.exists()) {
      // Create LocalAsset to access thumbnail cleanup
      final asset = LocalAsset(file);

      // Delete thumbnail if it exists
      try {
        await ThumbnailService.deleteThumbnail(asset);
      } catch (e) {
        // Continue if thumbnail deletion fails
        debugPrint('Failed to delete thumbnail for $assetId: $e');
      }

      // Delete metadata file if exists
      final metaFile = File('${file.path}.metadata.json');
      if (await metaFile.exists()) {
        await metaFile.delete();
      }

      // Delete the main file
      await file.delete();
    }
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    //
  }

  @override
  Future<void> updateWorkspaceDetails({
    String? name,
    int? width,
    int? height,
    int? videoDurationSeconds,
  }) async {
    if (name != null && name.isNotEmpty) {
      final wsDir = await _getWorkspaceDir();
      final appDocDir = await getApplicationDocumentsDirectory();
      final newDir = Directory(
        p.join(appDocDir.path, 'meadow_user_assets', name),
      );
      if (!await newDir.exists()) {
        await wsDir.rename(newDir.path);
      }
      // Optionally, update workspaceName if needed
    }

    // Load current settings
    final currentSettings = await loadSettings();

    // Create updated settings
    final updatedSettings = currentSettings.copyWith(
      defaultWidth: width,
      defaultHeight: height,
      videoDurationSeconds: videoDurationSeconds,
    );

    // Save updated settings to settings.json
    await saveSettings(updatedSettings);
  }

  /// Helper method to create LocalAsset with metadata loaded from .metadata.json file
  Future<LocalAsset> _createLocalAssetWithMetadata(File file) async {
    Map<String, dynamic> metadata = {};

    try {
      final metadataFile = File('${file.path}.metadata.json');
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // If metadata loading fails, continue with empty metadata
    }

    return LocalAsset(file, metadata: metadata);
  }
}
