import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../enums/asset_status.dart';
import '../enums/asset_type.dart';

/// Abstract base class for all assets in the application.
/// This provides a unified interface for both local and cloud assets.
abstract class Asset {
  /// Unique identifier for the asset
  String get id;

  /// Display name for the asset
  String get displayName;

  /// Type of the asset (image, video, audio, etc.)
  AssetType get type;

  AssetStatus get status;

  /// Whether this asset is stored locally
  bool get isLocal;

  /// Whether this asset is stored in the cloud
  bool get isCloud;

  /// File size in bytes (if available)
  int? get sizeBytes;

  /// Creation timestamp
  DateTime get createdAt;

  /// Last modified timestamp
  DateTime get lastModified;

  /// Custom metadata associated with the asset
  Map<String, dynamic> get metadata;

  /// Get an ImageProvider for displaying this asset
  ImageProvider getImageProvider();

  /// Load the asset content as bytes
  Future<Uint8List> getBytes();

  /// Load the asset content as bytes
  Future<String> getBase64();

  /// Get the file extension
  String get extension;

  /// Check if the asset exists and is accessible
  Future<bool> exists();

  /// Delete this asset
  Future<void> delete();

  /// Update metadata for this asset
  Future<void> updateMetadata(Map<String, dynamic> newMetadata);

  /// Get a thumbnail ImageProvider (for performance in grids)
  ImageProvider? getThumbnailProvider() => getImageProvider();

  Future<void> save(Uint8List data);

  String? comfyuiPromptId;
  String? errorMessage;
}
