// Music Options Dialog
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MusicOptionsDialog extends StatefulWidget {
  final String initialGenre;
  final int initialLength;
  final File? initialReferenceAudio;

  const MusicOptionsDialog({
    super.key,
    required this.initialGenre,
    required this.initialLength,
    this.initialReferenceAudio,
  });

  @override
  State<MusicOptionsDialog> createState() => MusicOptionsDialogState();
}

class MusicOptionsDialogState extends State<MusicOptionsDialog> {
  late final TextEditingController _genreController;
  late final TextEditingController _lengthController;
  File? _referenceAudio;

  @override
  void initState() {
    super.initState();
    _genreController = TextEditingController(text: widget.initialGenre);
    _lengthController = TextEditingController(
      text: widget.initialLength.toString(),
    );
    _referenceAudio = widget.initialReferenceAudio;
  }

  @override
  void dispose() {
    _genreController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Future<void> _pickReferenceAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _referenceAudio = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.music_note, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Text('Music Options'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'Genre/Style',
                hintText: 'e.g., melodic, uplifting, piano',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lengthController,
              decoration: const InputDecoration(
                labelText: 'Length (seconds)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _lengthController.text = '30',
                  child: const Text('30s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _lengthController.text = '95',
                  child: const Text('95s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _lengthController.text = '180',
                  child: const Text('180s'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _referenceAudio?.path.split('/').last ??
                        'No reference audio',
                    style: TextStyle(
                      color: _referenceAudio != null ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickReferenceAudio,
                  icon: const Icon(Icons.audiotrack, size: 16),
                  label: const Text('Browse'),
                ),
                if (_referenceAudio != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _referenceAudio = null),
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
            final length = int.tryParse(_lengthController.text);

            if (length != null && _genreController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'genre': _genreController.text,
                'length': length,
                'referenceAudio': _referenceAudio,
              });
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
