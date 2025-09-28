import 'dart:io';

import 'package:flutter/material.dart';

class MediaPlaceholder extends StatelessWidget {
  final String? selectedInitialImagePath;

  const MediaPlaceholder({super.key, required this.selectedInitialImagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        color: isDarkMode
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(50)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(125),
        child: Center(
          child:
              selectedInitialImagePath != null &&
                  File(selectedInitialImagePath!).existsSync()
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(selectedInitialImagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            "Preview not available.",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_search,
                      size: 80,
                      color: theme.hintColor.withAlpha(125),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Image preview will appear here',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
