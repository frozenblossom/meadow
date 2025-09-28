import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/integrations/comfyui/predefined_workflows/tts_workflow.dart';

class SpeechPromptBar extends StatefulWidget {
  const SpeechPromptBar({super.key});

  @override
  State<SpeechPromptBar> createState() => _SpeechPromptBarState();
}

class _SpeechPromptBarState extends State<SpeechPromptBar> {
  final _formKey = GlobalKey<FormState>();
  final _refTextController = TextEditingController();
  final _genTextController = TextEditingController();

  File? _refAudioFile;
  bool _useReferenceAudio = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refTextController.dispose();
    _genTextController.dispose();
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
              const Icon(Icons.record_voice_over, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Speech Generation',
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
                // Text to generate
                TextFormField(
                  controller: _genTextController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Text to Generate',
                    hintText: 'Enter the text you want to convert to speech...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter text to generate';
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
                            _refAudioFile = null;
                          }
                        });
                      },
                    ),
                    const Text('Use reference voice'),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Upload a reference audio to clone the voice',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                if (_useReferenceAudio) ...[
                  const SizedBox(height: 16),

                  // Reference text
                  TextFormField(
                    controller: _refTextController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reference Text',
                      hintText:
                          'Enter the text that matches your reference audio...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (_useReferenceAudio &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter reference text';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reference audio file picker
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
                                  _refAudioFile?.path.split('/').last ??
                                      'No reference audio selected',
                                  style: TextStyle(
                                    color: _refAudioFile != null
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
                      if (_refAudioFile != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() {
                            _refAudioFile = null;
                          }),
                          icon: const Icon(Icons.clear, size: 16),
                        ),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateSpeech,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.record_voice_over),
                    label: Text(
                      _isGenerating
                          ? 'Generating Speech...'
                          : 'Generate Speech',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
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

  Future<void> _pickReferenceAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _refAudioFile = File(result.files.single.path!);
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

  Future<void> _generateSpeech() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useReferenceAudio && _refAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reference audio file')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final text = _genTextController.text.trim();
      String? referenceAudioPath;
      String? referenceText;

      if (_useReferenceAudio && _refAudioFile != null) {
        referenceAudioPath = _refAudioFile!.path;
        referenceText = _refTextController.text.trim();
      }

      final workflow = ttsWorkflow(
        text: text,
        referenceAudioPath: referenceAudioPath,
        referenceText: referenceText,
      );

      await generateAsset(
        workflow: workflow,
        ext: 'mp3',
        metadata: {
          // Simple, user-focused metadata for easy reuse
          'type': 'speech',
          'prompt': text,
          'reference_audio': referenceAudioPath,
          'reference_text': referenceText,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech generation started! Check tasks for progress.',
            ),
          ),
        );

        // Clear form
        _genTextController.clear();
        _refTextController.clear();
        setState(() {
          _refAudioFile = null;
          _useReferenceAudio = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start speech generation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
