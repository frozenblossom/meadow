import 'package:flutter/material.dart';
import 'package:meadow/widgets/shared/generation_metadata_viewer.dart';

class MetadataViewerDemo extends StatelessWidget {
  const MetadataViewerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generation Metadata Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Generation Metadata Viewer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'This demonstrates how generation metadata is displayed and how users can selectively choose parameters for reproduction.',
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => _showImageMetadata(context),
              child: const Text('View Image Generation Metadata'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => _showVideoMetadata(context),
              child: const Text('View Video Generation Metadata'),
            ),
            const SizedBox(height: 24),

            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• View all generation parameters'),
            const Text('• Copy individual parameters to clipboard'),
            const Text(
              '• Selectively choose which parameters to use for reproduction',
            ),
            const Text('• Support for both image and video generation'),
            const Text('• Automatic detection of generation type'),
            const Text('• One-click reproduction with selected parameters'),
          ],
        ),
      ),
    );
  }

  void _showImageMetadata(BuildContext context) {
    final sampleImageMetadata = {
      // Simple, user-focused metadata format
      'type': 'image',
      'prompt':
          'A beautiful landscape with mountains and a serene lake at sunset, highly detailed, 4k',
      'width': 1024,
      'height': 1024,
      'seed': 1234567890,
      'model': 'dreamshaper_lightning.safetensors',
      'created_at': '2024-01-15T14:30:00.000Z',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GenerationMetadataViewer(metadata: sampleImageMetadata),
      ),
    );
  }

  void _showVideoMetadata(BuildContext context) {
    final sampleVideoMetadata = {
      // Simple, user-focused metadata format
      'type': 'video',
      'prompt':
          'A peaceful river flowing through a forest, gentle water movement, natural lighting',
      'seed': 987654321,
      'width': 1280,
      'height': 704,
      'duration_seconds': 5,
      'fps': 24,
      'frame_count': 120,
      'created_at': '2024-01-15T16:45:00.000Z',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GenerationMetadataViewer(metadata: sampleVideoMetadata),
      ),
    );
  }
}
