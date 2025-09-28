import 'package:flutter/material.dart';

enum AssetType {
  image,
  video,
  audio,
  text,
}

IconData getIconForAssetType(AssetType type) {
  switch (type) {
    case AssetType.image:
      return Icons.image_outlined;
    case AssetType.video:
      return Icons.video_library_outlined;
    case AssetType.audio:
      return Icons.music_note_outlined;
    case AssetType.text:
      return Icons.article_outlined;
  }
}
