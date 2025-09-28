import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:meadow/enums/asset_status.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/services/thumbnail_service.dart';
import 'package:path/path.dart' as p;

class LocalAsset extends Asset {
  final File file;
  final Map<String, dynamic> _metadata;

  LocalAsset(this.file, {Map<String, dynamic>? metadata})
    : _metadata = metadata ?? {} {
    // Set status from metadata if available
    final statusStr = _metadata['status'] as String?;
    if (statusStr != null) {
      switch (statusStr) {
        case 'pending':
          _status = AssetStatus.pending;
          break;
        case 'processing':
          _status = AssetStatus.processing;
          break;
        case 'failed':
          _status = AssetStatus.failed;
          break;
        case 'completed':
        default:
          _status = AssetStatus.completed;
          break;
      }
    }
  }

  @override
  String get id => file.path;

  @override
  String get displayName => p.basenameWithoutExtension(file.path);

  @override
  AssetType get type {
    final ext = p.extension(file.path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
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

  AssetStatus _status = AssetStatus.completed;

  @override
  AssetStatus get status => _status;

  set status(AssetStatus value) {
    _status = value;
  }

  @override
  bool get isLocal => true;

  @override
  bool get isCloud => false;

  @override
  int? get sizeBytes => file.existsSync() ? file.lengthSync() : null;

  @override
  DateTime get createdAt => file.lastModifiedSync();

  @override
  DateTime get lastModified => file.lastModifiedSync();

  @override
  Map<String, dynamic> get metadata => Map.from(_metadata);

  @override
  String get extension => p.extension(file.path);

  @override
  ImageProvider getImageProvider() {
    return FileImage(file);
  }

  @override
  Future<Uint8List> getBytes() async {
    return await file.readAsBytes();
  }

  @override
  Future<String> getBase64() async {
    var bytes = await getBytes();
    return base64Encode(bytes);
  }

  @override
  Future<bool> exists() async {
    return file.exists();
  }

  @override
  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
    // Also delete metadata file if it exists
    final metadataFile = File('${file.path}.metadata.json');
    if (await metadataFile.exists()) {
      await metadataFile.delete();
    }
    // Also delete thumbnail if it exists
    await ThumbnailService.deleteThumbnail(this);
  }

  @override
  Future<void> updateMetadata(Map<String, dynamic> newMetadata) async {
    _metadata.addAll(newMetadata);
    _metadata['lastUpdated'] = DateTime.now().toIso8601String();

    // Update status from metadata if it changed
    final statusStr = _metadata['status'] as String?;

    if (statusStr != null) {
      switch (statusStr) {
        case 'pending':
          _status = AssetStatus.pending;
          break;
        case 'processing':
          _status = AssetStatus.processing;
          break;
        case 'failed':
          _status = AssetStatus.failed;
          break;
        case 'completed':
        default:
          _status = AssetStatus.completed;
          break;
      }
    }

    // Save to metadata file
    final metadataFile = File('${file.path}.metadata.json');
    await metadataFile.writeAsString(jsonEncode(_metadata));
  }

  /// Create a LocalAsset from a file path
  static Future<LocalAsset> fromPath(String path) async {
    final file = File(path);
    final metadataFile = File('$path.metadata.json');

    Map<String, dynamic> metadata = {};
    if (await metadataFile.exists()) {
      try {
        final metadataContent = await metadataFile.readAsString();
        metadata = jsonDecode(metadataContent);
      } catch (e) {
        // Ignore metadata parsing errors
      }
    }

    return LocalAsset(file, metadata: metadata);
  }

  @override
  Future<void> save(Uint8List data) {
    return file.writeAsBytes(data);
  }

  /// Get thumbnail file for this asset
  Future<File?> getThumbnail({int size = 256}) async {
    return await ThumbnailService.getThumbnail(this, size: size);
  }

  /// Check if thumbnail exists
  Future<bool> hasThumbnail() async {
    return await ThumbnailService.hasThumbnail(this);
  }

  /// Get thumbnail path
  String getThumbnailPath() {
    return ThumbnailService.getThumbnailPath(this);
  }

  /// Regenerate thumbnail
  Future<File?> regenerateThumbnail({int size = 256}) async {
    return await ThumbnailService.regenerateThumbnail(this, size: size);
  }

  /// Get thumbnail image provider for UI display (async version)
  Future<ImageProvider?> getThumbnailImageProvider({int size = 256}) async {
    final thumbnailFile = await getThumbnail(size: size);
    if (thumbnailFile != null && await thumbnailFile.exists()) {
      return FileImage(thumbnailFile);
    }
    return null;
  }

  @override
  ImageProvider? getThumbnailProvider() {
    // For synchronous access, check if thumbnail exists without async
    final thumbnailPath = ThumbnailService.getThumbnailPath(this);
    final thumbnailFile = File(thumbnailPath);
    if (thumbnailFile.existsSync()) {
      return FileImage(thumbnailFile);
    }
    // Fallback to original image for synchronous access
    return getImageProvider();
  }
}
