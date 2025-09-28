import 'video_transcript.dart';

/// Context information needed for asset generation
/// This breaks the circular dependency between VideoTranscript and VideoClipCard
class GenerationContext {
  final int mediaWidth;
  final int mediaHeight;
  final int clipLengthSeconds;
  final String transcriptId; // For proper asset linking

  const GenerationContext({
    required this.mediaWidth,
    required this.mediaHeight,
    required this.clipLengthSeconds,
    required this.transcriptId,
  });

  /// Create from VideoTranscript
  factory GenerationContext.fromTranscript(VideoTranscript transcript) {
    return GenerationContext(
      mediaWidth: transcript.mediaWidth,
      mediaHeight: transcript.mediaHeight,
      clipLengthSeconds: transcript.clipLengthSeconds,
      transcriptId: transcript.id,
    );
  }
}
