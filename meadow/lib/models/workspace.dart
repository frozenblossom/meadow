import 'package:meadow/models/asset.dart';

enum WorkspaceType { local, cloud }

abstract class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final bool isTeamOwned;
  final int? defaultWidth;
  final int? defaultHeight;
  final int videoDurationSeconds;

  Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isTeamOwned,
    this.defaultWidth,
    this.defaultHeight,
    this.videoDurationSeconds = 5,
  });

  List<Asset> assets = [];

  Future<List<Asset>> getAssets({required int page, required int pageSize});

  Future<Asset?> getAssetById(String assetId);

  Future<void> addAsset(Asset asset);

  Future<void> removeAsset(String assetId);

  Future<void> updateAsset(Asset asset);

  Future<int> countAssets();

  Future<void> updateWorkspaceDetails({
    String? name,
    int? width,
    int? height,
    int? videoDurationSeconds,
  });

  Future<void> deleteWorkspace();

  /// Get aspect ratio from dimensions if available
  double? get aspectRatio {
    if (defaultWidth != null && defaultHeight != null && defaultHeight! > 0) {
      return defaultWidth! / defaultHeight!;
    }
    return null;
  }

  /// Get a user-friendly dimension string
  String get dimensionString {
    if (defaultWidth != null && defaultHeight != null) {
      return '${defaultWidth}x$defaultHeight';
    }
    return 'No size set';
  }

  // Optionally, fetch owner details (user or team)
  // Future<dynamic> getOwner();
}
