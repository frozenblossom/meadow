import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/models/menu_item.dart';
import 'package:meadow/widgets/pages/tab_list.dart';

enum MediaType {
  image,
  video,
  music,
  speech,
  transcript,
}

class FloatingDock extends StatefulWidget {
  final Function(MediaType)? onMediaTypeChanged;
  final Function(String)? onPromptSubmitted;

  const FloatingDock({
    super.key,
    this.onMediaTypeChanged,
    this.onPromptSubmitted,
  });

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  MediaType _selectedMediaType = MediaType.image;
  final TextEditingController _promptController = TextEditingController();

  // Desktop resizability
  double _dockWidth = 600.0; // Default width
  static const double _minWidth = 400.0;
  bool _isResizing = false;

  // Map media types to their corresponding menu items
  Map<MediaType, MenuItem> get _mediaTypeMenuItems {
    return {
      MediaType.image: tabList[0], // Image
      MediaType.video: tabList[1], // Clips
      MediaType.music: tabList[2], // Music
      MediaType.speech: tabList[3], // Speech
      MediaType.transcript: tabList[4], // Transcript
    };
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Widget _buildMediaTypeIcon(MediaType mediaType, {bool isSelected = false}) {
    final menuItem = _mediaTypeMenuItems[mediaType];
    if (menuItem == null) return const Icon(Icons.help, color: Colors.white);

    final color = isSelected ? Colors.white : Colors.white70;

    return menuItem.getIconWidget(
      color: color,
      size: 24,
    );
  }

  Widget _buildMediaTypeDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF4F46E5).withAlpha(200),
                  const Color(0xFF7C3AED).withAlpha(200),
                ]
              : [
                  const Color(0xFF6366F1).withAlpha(200),
                  const Color(0xFF8B5CF6).withAlpha(200),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1))
                .withAlpha(75),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PopupMenuButton<MediaType>(
        initialValue: _selectedMediaType,
        onSelected: (MediaType value) {
          setState(() {
            _selectedMediaType = value;
          });
          widget.onMediaTypeChanged?.call(value);
        },
        itemBuilder: (BuildContext context) {
          return MediaType.values.map((MediaType mediaType) {
            final menuItem = _mediaTypeMenuItems[mediaType];
            return PopupMenuItem<MediaType>(
              value: mediaType,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMediaTypeIcon(mediaType),
                    const SizedBox(width: 12),
                    Text(
                      menuItem?.title ?? mediaType.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaTypeIcon(_selectedMediaType, isSelected: true),
              const SizedBox(width: 10),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withAlpha(50)
              : Colors.white.withAlpha(75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(25)
                : Colors.black.withAlpha(25),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(75)
                  : Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _promptController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText:
                'Enter your ${_mediaTypeMenuItems[_selectedMediaType]?.title.toLowerCase()} prompt...',
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withAlpha(128)
                  : Colors.black.withAlpha(128),
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              widget.onPromptSubmitted?.call(value.trim());
            }
          },
        ),
      ),
    );
  }

  Widget _buildOptionsButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(50)
              : Colors.black.withAlpha(25),
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.tune,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 24,
        ),
        onPressed: () {
          // TODO: Options functionality to be implemented later
        },
        tooltip: 'Options',
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _promptController.text.trim().isNotEmpty;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: canGenerate
            ? LinearGradient(
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
                colors: isDark
                    ? [
                        Colors.grey.withAlpha(75),
                        Colors.grey.withAlpha(50),
                      ]
                    : [
                        Colors.grey.withAlpha(100),
                        Colors.grey.withAlpha(75),
                      ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: canGenerate
            ? [
                BoxShadow(
                  color:
                      (isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF34D399))
                          .withAlpha(100),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canGenerate
            ? () {
                final prompt = _promptController.text.trim();
                if (prompt.isNotEmpty) {
                  widget.onPromptSubmitted?.call(prompt);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: canGenerate ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              'Generate',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: canGenerate ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Ensure dock width is within screen bounds
    final maxAllowedWidth = screenWidth - 40; // 20px margin on each side
    final effectiveWidth = isMobile
        ? maxAllowedWidth
        : _dockWidth.clamp(_minWidth, maxAllowedWidth);

    return AnimatedBuilder(
      animation: _promptController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: isMobile
              ? _buildMobileLayout(isDark, effectiveWidth)
              : _buildDesktopLayout(isDark, effectiveWidth),
        );
      },
    );
  }

  // Mobile layout: Column with 2 rows
  Widget _buildMobileLayout(bool isDark, double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: _buildGlassDecoration(isDark),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Prompt input
              _buildPromptInputMobile(),
              const SizedBox(height: 12),
              // Bottom row: Media type, options, and generate button
              Row(
                children: [
                  _buildMediaTypeDropdown(),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      // TODO: Options functionality to be implemented later
                    },
                    child: _buildOptionsButton(),
                  ),
                  const SizedBox(width: 12),
                  _buildGenerateButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Desktop layout: Resizable row with drag handle
  Widget _buildDesktopLayout(bool isDark, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Resize handle (left)
        GestureDetector(
          onPanStart: (_) => setState(() => _isResizing = true),
          onPanEnd: (_) => setState(() => _isResizing = false),
          onPanUpdate: (details) {
            setState(() {
              _dockWidth = (_dockWidth - details.delta.dx * 2).clamp(
                _minWidth,
                Get.width - 100,
              );
            });
          },
          child: Container(
            width: 20,
            height: 80,
            decoration: BoxDecoration(
              color: _isResizing
                  ? (isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.black.withAlpha(30))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(50)
                      : Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        // Main dock content
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(20),
              decoration: _buildGlassDecoration(isDark),
              child: Row(
                children: [
                  _buildMediaTypeDropdown(),
                  _buildPromptInput(),
                  InkWell(
                    onTap: () {
                      // TODO: Options functionality to be implemented later
                    },
                    child: _buildOptionsButton(),
                  ),
                  const SizedBox(width: 16),
                  _buildGenerateButton(),
                ],
              ),
            ),
          ),
        ),
        // Resize handle (right)
        GestureDetector(
          onPanStart: (_) => setState(() => _isResizing = true),
          onPanEnd: (_) => setState(() => _isResizing = false),
          onPanUpdate: (details) {
            setState(() {
              _dockWidth = (_dockWidth + details.delta.dx * 2).clamp(
                _minWidth,
                Get.width - 100,
              );
            });
          },
          child: Container(
            width: 20,
            height: 80,
            decoration: BoxDecoration(
              color: _isResizing
                  ? (isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.black.withAlpha(30))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(50)
                      : Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile-specific prompt input (full width)
  Widget _buildPromptInputMobile() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withAlpha(50) : Colors.white.withAlpha(75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(25)
              : Colors.black.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(75)
                : Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        minLines: 1,
        maxLines: 6,
        controller: _promptController,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText:
              'Enter your ${_mediaTypeMenuItems[_selectedMediaType]?.title.toLowerCase()} prompt...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withAlpha(128)
                : Colors.black.withAlpha(128),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onPromptSubmitted?.call(value.trim());
          }
        },
      ),
    );
  }

  // Shared glass decoration
  BoxDecoration _buildGlassDecoration(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.black.withAlpha(75),
                Colors.black.withAlpha(25),
              ]
            : [
                Colors.white.withAlpha(75),
                Colors.white.withAlpha(25),
              ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withAlpha(50) : Colors.black.withAlpha(25),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(64)
              : Colors.black.withAlpha(20),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: isDark
              ? Colors.white.withAlpha(6)
              : Colors.white.withAlpha(100),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
