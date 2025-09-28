import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meadow/models/workspace_size.dart';

class WorkspaceFormDialog extends StatefulWidget {
  final String? initialName;
  final int? initialWidth;
  final int? initialHeight;
  final int? initialVideoDurationSeconds;
  final bool isEdit;

  const WorkspaceFormDialog({
    super.key,
    this.initialName,
    this.initialWidth,
    this.initialHeight,
    this.initialVideoDurationSeconds,
    this.isEdit = false,
  });

  @override
  State<WorkspaceFormDialog> createState() => _WorkspaceFormDialogState();
}

class _WorkspaceFormDialogState extends State<WorkspaceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _videoDurationController;

  WorkspaceSize? _selectedPreset;
  bool _useCustomDimensions = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _widthController = TextEditingController(
      text: widget.initialWidth?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.initialHeight?.toString() ?? '',
    );
    _videoDurationController = TextEditingController(
      text: widget.initialVideoDurationSeconds?.toString() ?? '5',
    );

    // Check if initial dimensions match a preset
    if (widget.initialWidth != null && widget.initialHeight != null) {
      _selectedPreset = WorkspaceSizes.getByDimensions(
        widget.initialWidth!,
        widget.initialHeight!,
      );
      _useCustomDimensions = _selectedPreset == null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _videoDurationController.dispose();
    super.dispose();
  }

  void _applyPreset(WorkspaceSize preset) {
    setState(() {
      _selectedPreset = preset;
      _useCustomDimensions = false;
      _widthController.text = preset.width.toString();
      _heightController.text = preset.height.toString();
    });
  }

  void _toggleCustomDimensions() {
    setState(() {
      _useCustomDimensions = !_useCustomDimensions;
      if (_useCustomDimensions) {
        _selectedPreset = null;
      }
    });
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }

    if (_useCustomDimensions || _selectedPreset != null) {
      final width = int.tryParse(_widthController.text);
      final height = int.tryParse(_heightController.text);

      if (width == null || height == null || width <= 0 || height <= 0) {
        return false;
      }
    }

    // Validate video duration
    final videoDuration = int.tryParse(_videoDurationController.text);
    if (videoDuration == null || videoDuration <= 0) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Workspace' : 'Create New Workspace'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workspace name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Name *',
                  hintText: 'Enter workspace name',
                  border: OutlineInputBorder(),
                ),
                autofocus: !widget.isEdit,
              ),

              const SizedBox(height: 24),

              // Dimensions section
              const Text(
                'Default Media Dimensions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set default dimensions for media generated in this workspace. This ensures consistency when creating video sequences or image sets.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 16),

              // Preset options
              const Text('Quick Presets:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WorkspaceSizes.all.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return FilterChip(
                    label: Text(
                      '${preset.name}\n${preset.dimensionString}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _applyPreset(preset);
                      }
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Custom dimensions toggle
              Row(
                children: [
                  Checkbox(
                    value: _useCustomDimensions,
                    onChanged: (value) => _toggleCustomDimensions(),
                  ),
                  const Text('Use custom dimensions'),
                ],
              ),

              if (_useCustomDimensions || _selectedPreset != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _widthController,
                        decoration: const InputDecoration(
                          labelText: 'Width (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: _useCustomDimensions,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('×'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: _useCustomDimensions,
                      ),
                    ),
                  ],
                ),

                if (_widthController.text.isNotEmpty &&
                    _heightController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final width = int.tryParse(_widthController.text);
                      final height = int.tryParse(_heightController.text);
                      if (width != null && height != null && height > 0) {
                        final ratio = width / height;
                        String ratioText;
                        if (ratio == 1.0) {
                          ratioText = '1:1 (Square)';
                        } else if ((ratio - 16 / 9).abs() < 0.01) {
                          ratioText = '16:9 (Landscape)';
                        } else if ((ratio - 9 / 16).abs() < 0.01) {
                          ratioText = '9:16 (Portrait)';
                        } else if ((ratio - 4 / 3).abs() < 0.01) {
                          ratioText = '4:3 (Traditional)';
                        } else if ((ratio - 3 / 4).abs() < 0.01) {
                          ratioText = '3:4 (Portrait)';
                        } else {
                          ratioText = '${ratio.toStringAsFixed(2)}:1';
                        }

                        return Text(
                          'Aspect Ratio: $ratioText',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],

              const SizedBox(height: 8),
              Text(
                'Leave dimensions empty to have no default size restrictions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Video Settings section
              const Text(
                'Video Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Default settings for video generation and playback in this workspace.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 16),

              // Video Duration input
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _videoDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Default Duration (seconds)',
                    hintText: '5',
                    border: OutlineInputBorder(),
                    helperText: 'Must be greater than 0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _validateForm()
              ? () {
                  final name = _nameController.text.trim();
                  int? width;
                  int? height;

                  if (_selectedPreset != null || _useCustomDimensions) {
                    width = int.tryParse(_widthController.text);
                    height = int.tryParse(_heightController.text);
                  }

                  final videoDurationSeconds =
                      int.tryParse(_videoDurationController.text) ?? 5;

                  Navigator.of(context).pop({
                    'name': name,
                    'width': width,
                    'height': height,
                    'videoDurationSeconds': videoDurationSeconds,
                  });
                }
              : null,
          child: Text(widget.isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
