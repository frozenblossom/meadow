// Speech Options Dialog
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SpeechOptionsDialog extends StatefulWidget {
  final File? initialReferenceAudio;
  final String initialReferenceText;

  const SpeechOptionsDialog({
    super.key,
    this.initialReferenceAudio,
    required this.initialReferenceText,
  });

  @override
  State<SpeechOptionsDialog> createState() => SpeechOptionsDialogState();
}

class SpeechOptionsDialogState extends State<SpeechOptionsDialog> {
  late final TextEditingController _referenceTextController;
  File? _referenceAudio;

  @override
  void initState() {
    super.initState();
    _referenceTextController = TextEditingController(
      text: widget.initialReferenceText,
    );
    _referenceAudio = widget.initialReferenceAudio;
  }

  @override
  void dispose() {
    _referenceTextController.dispose();
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
          Icon(Icons.record_voice_over, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Text('Speech Options'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Voice Cloning (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceTextController,
              decoration: const InputDecoration(
                labelText: 'Reference Text',
                hintText: 'Text that matches the reference audio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            const SizedBox(height: 16),
            const Text(
              'Leave both fields empty to use default voice',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
            Navigator.of(context).pop({
              'referenceAudio': _referenceAudio,
              'referenceText': _referenceTextController.text,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
