import 'package:flutter/material.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/editor/media_detail.dart';

class DocumentTab {
  final String id;
  String? title;
  bool isDirty = false;
  Widget? content;
  Asset? asset;

  DocumentTab({
    required this.id,
    this.title,
    this.content,
    this.asset,
    this.isDirty = false,
  });

  // Create a tab from an asset
  factory DocumentTab.fromAsset(Asset asset) {
    return DocumentTab(
      id: asset.id,
      title: asset.displayName,
      asset: asset,
      content: MediaDetailTab(asset: asset),
    );
  }
}
