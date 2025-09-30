import 'dart:ui';
import 'package:flutter/material.dart';

class AssetTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AssetTypeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: selected ? 20 : 15,
              sigmaY: selected ? 20 : 15,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
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
                  color: selected
                      ? (isDark
                            ? Colors.white.withAlpha(100)
                            : Colors.white.withAlpha(150))
                      : (isDark
                            ? Colors.white.withAlpha(40)
                            : Colors.black.withAlpha(30)),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: [
                  if (selected)
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
                    blurRadius: selected ? 15 : 8,
                    offset: Offset(0, selected ? 6 : 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                    size: 16,
                  ),
                  if (label.isNotEmpty) const SizedBox(width: 6),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
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
}
