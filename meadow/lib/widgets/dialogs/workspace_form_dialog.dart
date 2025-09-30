import 'dart:ui';
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

  Widget _buildContent(bool isDark, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workspace name
        _buildGlassTextField(
          controller: _nameController,
          labelText: 'Workspace Name *',
          hintText: 'Enter workspace name',
          isDark: isDark,
          autofocus: !widget.isEdit,
        ),

        const SizedBox(height: 24),

        // Dimensions section
        Text(
          'Default Media Dimensions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set default dimensions for media generated in this workspace. This ensures consistency when creating video sequences or image sets.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),

        const SizedBox(height: 16),

        // Preset options
        Text(
          'Quick Presets:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WorkspaceSizes.all.map((preset) {
            final isSelected = _selectedPreset == preset;
            return _buildPresetPill(preset, isSelected, isDark);
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Custom dimensions toggle
        _buildGlassCheckbox(
          value: _useCustomDimensions,
          onChanged: (value) => _toggleCustomDimensions(),
          label: 'Use custom dimensions',
          isDark: isDark,
        ),

        if (_useCustomDimensions || _selectedPreset != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGlassTextField(
                  controller: _widthController,
                  labelText: 'Width (px)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: _useCustomDimensions,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '×',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassTextField(
                  controller: _heightController,
                  labelText: 'Height (px)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: _useCustomDimensions,
                  isDark: isDark,
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

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF4F46E5).withAlpha(100),
                                const Color(0xFF7C3AED).withAlpha(100),
                              ]
                            : [
                                const Color(0xFF6366F1).withAlpha(100),
                                const Color(0xFF8B5CF6).withAlpha(100),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.black.withAlpha(20),
                      ),
                    ),
                    child: Text(
                      'Aspect Ratio: $ratioText',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
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
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),

        const SizedBox(height: 24),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withAlpha(0),
                      Colors.white.withAlpha(25),
                      Colors.white.withAlpha(0),
                    ]
                  : [
                      Colors.black.withAlpha(0),
                      Colors.black.withAlpha(15),
                      Colors.black.withAlpha(0),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Video Settings section
        Text(
          'Video Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Default settings for video generation and playback in this workspace.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),

        const SizedBox(height: 16),

        // Video Duration input
        SizedBox(
          width: 200,
          child: _buildGlassTextField(
            controller: _videoDurationController,
            labelText: 'Default Duration (seconds)',
            hintText: '5',
            helperText: 'Must be greater than 0',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.black.withAlpha(200),
                        Colors.black.withAlpha(150),
                      ]
                    : [
                        Colors.white.withAlpha(200),
                        Colors.white.withAlpha(150),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(50)
                    : Colors.black.withAlpha(25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(100)
                      : Colors.black.withAlpha(50),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(25)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isEdit ? Icons.edit : Icons.add_circle_outline,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.isEdit
                            ? 'Edit Workspace'
                            : 'Create New Workspace',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(isDark, theme),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(25)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildGlassButton(
                        onPressed: () => Navigator.of(context).pop(),
                        label: 'Cancel',
                        isPrimary: false,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildGlassButton(
                        onPressed: _validateForm()
                            ? () {
                                final name = _nameController.text.trim();
                                int? width;
                                int? height;

                                if (_selectedPreset != null ||
                                    _useCustomDimensions) {
                                  width = int.tryParse(_widthController.text);
                                  height = int.tryParse(_heightController.text);
                                }

                                final videoDurationSeconds =
                                    int.tryParse(
                                      _videoDurationController.text,
                                    ) ??
                                    5;

                                Navigator.of(context).pop({
                                  'name': name,
                                  'width': width,
                                  'height': height,
                                  'videoDurationSeconds': videoDurationSeconds,
                                });
                              }
                            : null,
                        label: widget.isEdit ? 'Update' : 'Create',
                        isPrimary: true,
                        isDark: isDark,
                        enabled: _validateForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isDark,
    String? hintText,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withAlpha(15),
                  Colors.white.withAlpha(8),
                ]
              : [
                  Colors.black.withAlpha(10),
                  Colors.black.withAlpha(5),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(25)
              : Colors.black.withAlpha(20),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        autofocus: autofocus,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          helperStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildPresetPill(WorkspaceSize preset, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isSelected ? 15 : 10,
              sigmaY: isSelected ? 15 : 10,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF4F46E5).withAlpha(180),
                                const Color(0xFF7C3AED).withAlpha(180),
                              ]
                            : [
                                const Color(0xFF6366F1).withAlpha(180),
                                const Color(0xFF8B5CF6).withAlpha(180),
                              ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withAlpha(30),
                                Colors.white.withAlpha(15),
                              ]
                            : [
                                Colors.black.withAlpha(20),
                                Colors.black.withAlpha(10),
                              ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (isDark
                            ? Colors.white.withAlpha(100)
                            : Colors.white.withAlpha(150))
                      : (isDark
                            ? Colors.white.withAlpha(40)
                            : Colors.black.withAlpha(30)),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color:
                          (isDark
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF6366F1))
                              .withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(50)
                        : Colors.black.withAlpha(15),
                    blurRadius: isSelected ? 15 : 8,
                    offset: Offset(0, isSelected ? 6 : 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.dimensionString,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withAlpha(200)
                          : (isDark ? Colors.white54 : Colors.black45),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String label,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: value
                    ? (isDark
                          ? [
                              const Color(0xFF4F46E5).withAlpha(180),
                              const Color(0xFF7C3AED).withAlpha(180),
                            ]
                          : [
                              const Color(0xFF6366F1).withAlpha(180),
                              const Color(0xFF8B5CF6).withAlpha(180),
                            ])
                    : (isDark
                          ? [
                              Colors.white.withAlpha(30),
                              Colors.white.withAlpha(15),
                            ]
                          : [
                              Colors.black.withAlpha(20),
                              Colors.black.withAlpha(10),
                            ]),
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value
                    ? (isDark
                          ? Colors.white.withAlpha(100)
                          : Colors.white.withAlpha(150))
                    : (isDark
                          ? Colors.white.withAlpha(40)
                          : Colors.black.withAlpha(30)),
              ),
            ),
            child: value
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    required bool isDark,
    bool enabled = true,
  }) {
    final isEnabled = enabled && onPressed != null;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: isPrimary && isEnabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ]
                          : [
                              const Color(0xFF34D399),
                              const Color(0xFF10B981),
                            ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isEnabled
                          ? (isDark
                                ? [
                                    Colors.white.withAlpha(30),
                                    Colors.white.withAlpha(15),
                                  ]
                                : [
                                    Colors.black.withAlpha(20),
                                    Colors.black.withAlpha(10),
                                  ])
                          : (isDark
                                ? [
                                    Colors.white.withAlpha(15),
                                    Colors.white.withAlpha(8),
                                  ]
                                : [
                                    Colors.black.withAlpha(10),
                                    Colors.black.withAlpha(5),
                                  ]),
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary && isEnabled
                    ? (isDark
                          ? Colors.white.withAlpha(100)
                          : Colors.white.withAlpha(150))
                    : (isDark
                          ? Colors.white.withAlpha(30)
                          : Colors.black.withAlpha(20)),
                width: isPrimary ? 1.5 : 1,
              ),
              boxShadow: [
                if (isPrimary && isEnabled)
                  BoxShadow(
                    color:
                        (isDark
                                ? const Color(0xFF10B981)
                                : const Color(0xFF34D399))
                            .withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(50)
                      : Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary && isEnabled
                    ? Colors.white
                    : (isEnabled
                          ? (isDark ? Colors.white70 : Colors.black54)
                          : (isDark ? Colors.white38 : Colors.black26)),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
