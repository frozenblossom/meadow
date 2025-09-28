class WorkspaceSize {
  final String name;
  final int width;
  final int height;
  final String aspectRatio;

  const WorkspaceSize({
    required this.name,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  @override
  String toString() => '$name ($width x $height - $aspectRatio)';

  String get dimensionString => '${width}x$height';

  double get aspectRatioValue => width / height;
}

/// Predefined workspace sizes for common use cases
class WorkspaceSizes {
  static const square = WorkspaceSize(
    name: 'Square',
    width: 1024,
    height: 1024,
    aspectRatio: '1:1',
  );

  static const landscapeHD = WorkspaceSize(
    name: 'Landscape HD',
    width: 1280,
    height: 720,
    aspectRatio: '16:9',
  );

  static const portraitHD = WorkspaceSize(
    name: 'Portrait HD',
    width: 720,
    height: 1280,
    aspectRatio: '9:16',
  );

  static const landscape43 = WorkspaceSize(
    name: 'Landscape 4:3',
    width: 1024,
    height: 768,
    aspectRatio: '4:3',
  );

  static const portrait34 = WorkspaceSize(
    name: 'Portrait 3:4',
    width: 768,
    height: 1024,
    aspectRatio: '3:4',
  );

  static const ultrawide = WorkspaceSize(
    name: 'Ultrawide',
    width: 1920,
    height: 1080,
    aspectRatio: '16:9',
  );

  static const instagram = WorkspaceSize(
    name: 'Instagram Post',
    width: 1080,
    height: 1080,
    aspectRatio: '1:1',
  );

  static const instagramStory = WorkspaceSize(
    name: 'Instagram Story',
    width: 1080,
    height: 1920,
    aspectRatio: '9:16',
  );

  static const youtubeThumb = WorkspaceSize(
    name: 'YouTube Thumbnail',
    width: 1280,
    height: 720,
    aspectRatio: '16:9',
  );

  static const tiktok = WorkspaceSize(
    name: 'TikTok',
    width: 1080,
    height: 1920,
    aspectRatio: '9:16',
  );

  /// All predefined sizes
  static const List<WorkspaceSize> all = [
    square,
    landscapeHD,
    portraitHD,
    landscape43,
    portrait34,
    ultrawide,
    instagram,
    instagramStory,
    youtubeThumb,
    tiktok,
  ];

  /// Get a preset by name
  static WorkspaceSize? getByName(String name) {
    try {
      return all.firstWhere((size) => size.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get a preset by dimensions
  static WorkspaceSize? getByDimensions(int width, int height) {
    try {
      return all.firstWhere(
        (size) => size.width == width && size.height == height,
      );
    } catch (e) {
      return null;
    }
  }
}
