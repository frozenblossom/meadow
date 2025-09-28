import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/acestep_workflow.dart';

class MusicPromptBar extends StatefulWidget {
  const MusicPromptBar({super.key});

  @override
  State<MusicPromptBar> createState() => _MusicPromptBarState();
}

class _MusicPromptBarState extends State<MusicPromptBar> {
  final _formKey = GlobalKey<FormState>();
  final _lyricsController = TextEditingController();
  final _genreController = TextEditingController();
  final _lengthController = TextEditingController(text: '120');

  File? _referenceAudioFile;
  bool _useReferenceAudio = false;

  @override
  void dispose() {
    _lyricsController.dispose();
    _genreController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'Music',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lyrics input
                TextFormField(
                  controller: _lyricsController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Lyrics',
                    hintText:
                        'Enter your song lyrics here...\n\nVerse 1:\nOnce upon a time\nIn a world so bright\n\nChorus:\nDreams come alive\nIn the starlight',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter lyrics';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reference audio toggle
                Row(
                  children: [
                    Checkbox(
                      value: _useReferenceAudio,
                      onChanged: (value) {
                        setState(() {
                          _useReferenceAudio = value ?? false;
                          if (!_useReferenceAudio) {
                            _referenceAudioFile = null;
                          }
                        });
                      },
                    ),
                    const Text('Use reference audio'),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Upload an audio file to guide the musical style',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                if (_useReferenceAudio) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.audiotrack, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _referenceAudioFile?.path.split('/').last ??
                                      'No audio file selected',
                                  style: TextStyle(
                                    color: _referenceAudioFile != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _pickReferenceAudio,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text(
                          'Browse',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (_referenceAudioFile != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() {
                            _referenceAudioFile = null;
                          }),
                          icon: const Icon(Icons.clear, size: 16),
                        ),
                      ],
                    ],
                  ),
                ],

                if (!_useReferenceAudio) ...[
                  const SizedBox(height: 16),
                  // Genre/Style input
                  TextFormField(
                    minLines: 4,
                    maxLines: 6,
                    controller: _genreController,
                    decoration: const InputDecoration(
                      labelText: 'Genre/Style',
                      hintText: 'e.g., classical genres, hopeful mood, piano',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_useReferenceAudio &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter a genre or style description';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Audio length
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        decoration: const InputDecoration(
                          labelText: 'Audio Length (seconds)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter audio length';
                          }
                          final length = int.tryParse(value.trim());
                          if (length == null || length < 10 || length > 300) {
                            return 'Length must be between 10 and 300 seconds';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPresetButton('Short (30s)', 30),
                        _buildPresetButton('Medium (95s)', 95),
                        _buildPresetButton('Long (180s)', 180),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateMusic,
                    icon: const Icon(Icons.music_note),
                    label: Text('Generate Music'),

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, int seconds) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton(
        onPressed: () {
          _lengthController.text = seconds.toString();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(80, 32),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _pickReferenceAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _referenceAudioFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking audio file: $e')),
        );
      }
    }
  }

  Future<void> _generateMusic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useReferenceAudio && _referenceAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reference audio file')),
      );
      return;
    }

    try {
      final lyrics = _lyricsController.text.trim();
      final audioLength = int.parse(_lengthController.text.trim());
      String? genre;
      String? referenceAudioPath;

      if (_useReferenceAudio && _referenceAudioFile != null) {
        referenceAudioPath = _referenceAudioFile!.path;
      } else {
        genre = _genreController.text.trim();
      }

      final workflow = aceStepWorkflow(
        lyrics: lyrics,
        genre: genre,
        referenceAudioPath: referenceAudioPath,
        audioLength: audioLength,
      );

      await generateAsset(
        workflow: workflow,
        ext: 'mp3',
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'music',
          'prompt': lyrics,
          'genre': genre,
          'audio_length': audioLength,
          'reference_audio': referenceAudioPath,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Music generation started! Check tasks for progress.',
            ),
          ),
        );

        // Clear form
        _lyricsController.clear();
        _genreController.clear();
        _lengthController.text = '120';
        setState(() {
          _referenceAudioFile = null;
          _useReferenceAudio = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start music generation: $e')),
        );
      }
    }
  }
}
