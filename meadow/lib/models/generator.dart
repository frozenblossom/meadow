abstract class Generator {
  /// Unique identifier for this provider
  String get providerId;

  /// Human-readable display name
  String get displayName;

  /// Type of provider: 'local', 'cloud', or 'custom'
  String get providerType;

  /// Whether this provider is currently available and configured
  bool get isAvailable;

  /// Version of the provider implementation
  String get version => '1.0.0';
}
