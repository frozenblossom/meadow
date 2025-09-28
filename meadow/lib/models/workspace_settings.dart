import 'dart:convert';

/// Model for workspace settings that are stored in settings.json
class WorkspaceSettings {
  final int? defaultWidth;
  final int? defaultHeight;
  final int videoDurationSeconds;

  const WorkspaceSettings({
    this.defaultWidth,
    this.defaultHeight,
    this.videoDurationSeconds = 5,
  });

  /// Create WorkspaceSettings from JSON
  factory WorkspaceSettings.fromJson(Map<String, dynamic> json) {
    return WorkspaceSettings(
      defaultWidth: json['defaultWidth'] as int?,
      defaultHeight: json['defaultHeight'] as int?,
      videoDurationSeconds: json['videoDurationSeconds'] as int? ?? 5,
    );
  }

  /// Convert WorkspaceSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'defaultWidth': defaultWidth,
      'defaultHeight': defaultHeight,
      'videoDurationSeconds': videoDurationSeconds,
    };
  }

  /// Create a copy with updated values
  WorkspaceSettings copyWith({
    int? defaultWidth,
    int? defaultHeight,
    int? videoDurationSeconds,
  }) {
    return WorkspaceSettings(
      defaultWidth: defaultWidth ?? this.defaultWidth,
      defaultHeight: defaultHeight ?? this.defaultHeight,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory WorkspaceSettings.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return WorkspaceSettings.fromJson(json);
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkspaceSettings &&
        other.defaultWidth == defaultWidth &&
        other.defaultHeight == defaultHeight &&
        other.videoDurationSeconds == videoDurationSeconds;
  }

  @override
  int get hashCode {
    return defaultWidth.hashCode ^
        defaultHeight.hashCode ^
        videoDurationSeconds.hashCode;
  }

  @override
  String toString() {
    return 'WorkspaceSettings(defaultWidth: $defaultWidth, defaultHeight: $defaultHeight, videoDurationSeconds: $videoDurationSeconds)';
  }
}
