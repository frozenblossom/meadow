// Video Options Dialog
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class VideoOptionsDialog extends StatefulWidget {
  final int initialWidth;
  final int initialHeight;
  final int initialDuration;
  final int initialFps;
  final int? initialSeed;
  final File? initialReferenceImage;

  const VideoOptionsDialog({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.initialDuration,
    required this.initialFps,
    this.initialSeed,
    this.initialReferenceImage,
  });

  @override
  State<VideoOptionsDialog> createState() => VideoOptionsDialogState();
}

class VideoOptionsDialogState extends State<VideoOptionsDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _durationController;
  late final TextEditingController _fpsController;
  late final TextEditingController _seedController;
  File? _referenceImage;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.initialWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.initialHeight.toString(),
    );
    _durationController = TextEditingController(
      text: widget.initialDuration.toString(),
    );
    _fpsController = TextEditingController(text: widget.initialFps.toString());
    _seedController = TextEditingController(
      text: widget.initialSeed?.toString() ?? '',
    );
    _referenceImage = widget.initialReferenceImage;
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _durationController.dispose();
    _fpsController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _pickReferenceImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _referenceImage = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.videocam, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Text('Video Options'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (s)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _fpsController,
                    decoration: const InputDecoration(
                      labelText: 'FPS',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seedController,
              decoration: const InputDecoration(
                labelText: 'Seed (optional)',
                hintText: 'Leave empty for random',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _referenceImage?.path.split('/').last ??
                        'No reference image',
                    style: TextStyle(
                      color: _referenceImage != null ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickReferenceImage,
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('Browse'),
                ),
                if (_referenceImage != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _referenceImage = null),
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final width = int.tryParse(_widthController.text);
            final height = int.tryParse(_heightController.text);
            final duration = int.tryParse(_durationController.text);
            final fps = int.tryParse(_fpsController.text);
            final seed = _seedController.text.isEmpty
                ? null
                : int.tryParse(_seedController.text);

            if (width != null &&
                height != null &&
                duration != null &&
                fps != null) {
              Navigator.of(context).pop({
                'width': width,
                'height': height,
                'duration': duration,
                'fps': fps,
                'seed': seed,
                'referenceImage': _referenceImage,
              });
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
