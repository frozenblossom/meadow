import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/document_tabs_controller.dart';
import 'package:meadow/controllers/video_transcript_controller.dart';
import 'package:meadow/models/video_transcript.dart';

class VideoTranscriptForm extends StatefulWidget {
  final VideoTranscript?
  transcript; // null for creation, transcript for editing

  const VideoTranscriptForm({
    super.key,
    this.transcript,
  });

  @override
  State<VideoTranscriptForm> createState() => _VideoTranscriptFormState();
}

class _VideoTranscriptFormState extends State<VideoTranscriptForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _clipLengthController = TextEditingController();

  bool _generateSpeech = true;
  bool _generateMusic = false;
  bool get _isEditing => widget.transcript != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeFromTranscript();
    } else {
      _initializeDefaults();
    }
  }

  void _initializeFromTranscript() {
    final transcript = widget.transcript!;
    _titleController.text = transcript.title;
    _descriptionController.text = transcript.description;
    _durationController.text = transcript.durationSeconds.toString();
    _widthController.text = transcript.mediaWidth.toString();
    _heightController.text = transcript.mediaHeight.toString();
    _clipLengthController.text = transcript.clipLengthSeconds.toString();
    _generateSpeech = transcript.generateSpeech;
    _generateMusic = transcript.generateMusic;
  }

  void _initializeDefaults() {
    _durationController.text = '60';
    _widthController.text = '1024';
    _heightController.text = '1024';
    _clipLengthController.text = '5';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _clipLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcriptController = Get.find<VideoTranscriptController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Video Transcript' : 'Create Video Transcript',
        ),
        elevation: 0,
      ),
      body: Obx(() {
        return Column(
          children: [
            if (transcriptController.errorMessage.value.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.errorContainer,
                child: Text(
                  transcriptController.errorMessage.value,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            Expanded(
              child: transcriptController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTranscriptForm(context, transcriptController),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTranscriptForm(
    BuildContext context,
    VideoTranscriptController controller,
  ) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Video Title',
              hintText: 'Enter a title for your video',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Video Description',
              hintText: 'Describe what you want to see in your video...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Duration
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                    suffixText: 'seconds',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter duration';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid duration';
                    }
                    if (duration > 300) {
                      return 'Maximum duration is 5 minutes (300 seconds)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_calculateClips()} clips',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Media Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Media Dimensions
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _widthController,
                          decoration: const InputDecoration(
                            labelText: 'Width',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.width_normal),
                            suffixText: 'px',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter width';
                            }
                            final width = int.tryParse(value);
                            if (width == null || width < 64 || width > 4096) {
                              return 'Width must be 64-4096px';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.height),
                            suffixText: 'px',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter height';
                            }
                            final height = int.tryParse(value);
                            if (height == null ||
                                height < 64 ||
                                height > 4096) {
                              return 'Height must be 64-4096px';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Clip Length
                  TextFormField(
                    controller: _clipLengthController,
                    decoration: const InputDecoration(
                      labelText: 'Clip Length',
                      hintText: 'Duration of each clip',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.movie),
                      suffixText: 'seconds',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter clip length';
                      }
                      final length = int.tryParse(value);
                      if (length == null || length < 1 || length > 30) {
                        return 'Clip length must be 1-30 seconds';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Refresh the clips counter
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          if (!_isEditing) // Only show generation options when creating
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generation Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Generate Speech'),
                      subtitle: const Text('Add narration text for each clip'),
                      value: _generateSpeech,
                      onChanged: (value) {
                        setState(() {
                          _generateSpeech = value;
                        });
                      },
                      secondary: const Icon(Icons.record_voice_over),
                    ),
                    SwitchListTile(
                      title: const Text('Generate Background Music'),
                      subtitle: const Text(
                        'Add music prompt for the entire video',
                      ),
                      value: _generateMusic,
                      onChanged: (value) {
                        setState(() {
                          _generateMusic = value;
                        });
                      },
                      secondary: const Icon(Icons.music_note),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Test Connection Button (only for creation)
          if (!_isEditing)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: controller.isLoading.value ? null : _testConnection,
                icon: const Icon(Icons.network_check),
                label: const Text('Test Local LLM Connection'),
                style: OutlinedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          if (!_isEditing) const SizedBox(height: 16),

          // Action Button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : _isEditing
                  ? _updateTranscript
                  : _generateTranscript,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.auto_awesome),
              label: Text(
                controller.isLoading.value
                    ? (_isEditing ? 'Saving...' : 'Generating...')
                    : (_isEditing
                          ? 'Save Changes'
                          : 'Generate Video Transcript'),
              ),
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateClips() {
    final duration = int.tryParse(_durationController.text) ?? 60;
    final clipLength = int.tryParse(_clipLengthController.text) ?? 5;
    return (duration / clipLength).ceil();
  }

  Future<void> _testConnection() async {
    final transcriptController = Get.find<VideoTranscriptController>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing connection to Local LLM...'),
        duration: Duration(seconds: 2),
      ),
    );

    final isConnected = await transcriptController.testLLMConnection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Local LLM connection successful!'
                : 'Local LLM connection failed. Check the URL in settings.',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _generateTranscript() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<VideoTranscriptController>();

    final transcript = await controller.generateTranscript(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: int.parse(_durationController.text),
      generateSpeech: _generateSpeech,
      generateMusic: _generateMusic,
      mediaWidth: int.parse(_widthController.text),
      mediaHeight: int.parse(_heightController.text),
      clipLengthSeconds: int.parse(_clipLengthController.text),
    );

    if (transcript != null && mounted) {
      // Open transcript in a new tab and close the creator
      final tabsController = Get.find<DocumentsTabsController>();
      tabsController.openVideoTranscriptTab(transcript);
      Navigator.of(context).pop(); // Close the creator dialog/page
    }
  }

  void _updateTranscript() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<VideoTranscriptController>();

    await controller.updateTranscriptProperties(
      transcriptId: widget.transcript!.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: int.parse(_durationController.text),
      mediaWidth: int.parse(_widthController.text),
      mediaHeight: int.parse(_heightController.text),
      clipLengthSeconds: int.parse(_clipLengthController.text),
    );

    if (mounted) {
      Navigator.of(context).pop(true); // Return true to indicate success
    }
  }
}
