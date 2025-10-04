import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/theme_controller.dart';
import 'package:meadow/services/update_check_service.dart';
import 'package:meadow/widgets/pages/model_manager_page.dart';
import 'package:meadow/widgets/dialogs/theme_settings_dialog.dart';
import 'package:meadow/widgets/dialogs/app_settings_dialog.dart';
import 'package:meadow/widgets/dialogs/transcripts_dialog.dart';
import 'package:meadow/widgets/pages/assets_tab.dart';
import 'package:meadow/widgets/dock/floating_dock.dart';
import 'package:meadow/widgets/shared/workspace_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  MediaType _selectedMediaType = MediaType.image;

  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Use GetX for theme mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildModernAppBar(context, theme, isDark, isMobile: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0B),
                    const Color(0xFF1A1A1B),
                    const Color(0xFF2A2A2B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles/orbs
            ..._buildBackgroundOrbs(isDark),

            // Main content area
            const Positioned.fill(
              child: AssetsTab(),
            ),

            // Floating dock at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context, theme, isDark, isMobile: false),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0B),
                    const Color(0xFF1A1A1B),
                    const Color(0xFF2A2A2B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles/orbs
            ..._buildBackgroundOrbs(isDark),

            // Main content area
            const Positioned.fill(
              top: 56, // Leave space for app bar
              child: AssetsTab(),
            ),

            // Floating dock at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingDock(
                onMediaTypeChanged: (MediaType mediaType) {
                  setState(() {
                    _selectedMediaType = mediaType;
                  });
                },
                onPromptSubmitted: (String prompt) {
                  // TODO: Handle prompt submission based on selected media type
                  print(
                    'Prompt submitted: $prompt for ${_selectedMediaType.name}',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to switch between mobile and desktop layouts
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout
          return _buildMobileLayout(context);
        } else {
          // Desktop layout
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  /// Build modern app bar with regular title and glass action buttons
  PreferredSizeWidget _buildModernAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required bool isMobile,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: theme.appBarTheme.elevation ?? 1,
      centerTitle: false,
      title: Row(
        children: [
          Text(
            'Meadow',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add WorkspaceSelector on desktop
          if (!isMobile) ...[
            const SizedBox(width: 32),
            const Expanded(
              child: WorkspaceSelector(
                showInAppBar: true,
              ),
            ),
          ],
        ],
      ),
      actions: _buildAppBarActions(context, theme, isDark, isMobile),
    );
  }
}

/// Build app bar actions with modern styling
List<Widget> _buildAppBarActions(
  BuildContext context,
  ThemeData theme,
  bool isDark,
  bool isMobile,
) {
  final actions = <Widget>[];

  // Transcripts button (always visible)
  actions.add(
    _buildGlassButton(
      icon: Icons.video_library,
      tooltip: 'Video Transcripts',
      onPressed: () => _showTranscriptsDialog(context),
      isDark: isDark,
    ),
  );

  if (!isMobile) {
    // Models button (desktop only)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      actions.add(
        _buildGlassButton(
          icon: Icons.model_training,
          tooltip: 'Models',
          onPressed: () => showModelManagerDialog(context),
          isDark: isDark,
        ),
      );
    }

    // Settings button
    actions.add(
      _buildGlassButton(
        icon: Icons.settings,
        tooltip: 'Settings',
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AppSettingsDialog(),
        ),
        isDark: isDark,
      ),
    );

    // Update notification
    actions.add(
      Obx(() {
        final updateService = Get.find<UpdateCheckService>();
        if (!updateService.isUpdateAvailable) {
          return const SizedBox.shrink();
        }

        return _buildGlassButton(
          icon: Icons.system_update,
          tooltip: 'Update Available',
          onPressed: () => _showUpdateDialog(context),
          isDark: isDark,
          hasNotification: true,
        );
      }),
    );
  }

  // Theme toggle
  actions.add(
    Obx(
      () {
        final themeController = Get.find<ThemeController>();
        return GestureDetector(
          onLongPress: () => showDialog(
            context: context,
            builder: (context) => const ThemeSettingsDialog(),
          ),
          child: _buildGlassButton(
            icon: themeController.themeIcon,
            tooltip: 'Toggle Theme (${themeController.themeName})',
            onPressed: () => themeController.toggleTheme(),
            isDark: isDark,
          ),
        );
      },
    ),
  );

  actions.add(const SizedBox(width: 16));

  return actions;
}

/// Build glass-effect button
Widget _buildGlassButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
  required bool isDark,
  bool hasNotification = false,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(25)
                : Colors.black.withAlpha(12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(50)
                  : Colors.black.withAlpha(25),
            ),
          ),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                if (hasNotification)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withAlpha(128),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      ),
    ),
  );
}

/// Build animated background orbs
List<Widget> _buildBackgroundOrbs(bool isDark) {
  return [
    // Large orb top-right
    Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? [
                    const Color(0xFF4F46E5).withAlpha(25),
                    const Color(0xFF4F46E5).withAlpha(1),
                  ]
                : [
                    const Color(0xFF6366F1).withAlpha(25),
                    const Color(0xFF6366F1).withAlpha(1),
                  ],
          ),
        ),
      ),
    ),
    // Medium orb middle-left
    Positioned(
      top: 200,
      left: -80,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? [
                    const Color(0xFF7C3AED).withAlpha(25),
                    const Color(0xFF7C3AED).withAlpha(1),
                  ]
                : [
                    const Color(0xFF8B5CF6).withAlpha(25),
                    const Color(0xFF8B5CF6).withAlpha(1),
                  ],
          ),
        ),
      ),
    ),
    // Small orb bottom-right
    Positioned(
      bottom: 100,
      right: -50,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? [
                    const Color(0xFF06B6D4).withAlpha(25),
                    const Color(0xFF06B6D4).withAlpha(0),
                  ]
                : [
                    const Color(0xFF0EA5E9).withAlpha(25),
                    const Color(0xFF0EA5E9).withAlpha(0),
                  ],
          ),
        ),
      ),
    ),
  ];
}

/// Show transcripts dialog
void _showTranscriptsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TranscriptsDialog(),
  );
}

/// Show update available dialog
void _showUpdateDialog(BuildContext context) {
  final updateService = Get.find<UpdateCheckService>();
  final updateInfo = updateService.latestUpdateInfo;

  if (updateInfo == null) return;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(dialogContext).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version of Meadow is available!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Current version: '),
              Text(
                updateService.currentVersion,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Latest version: '),
              Text(
                updateInfo.version,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Platform: ${updateService.getCurrentPlatformName()}',
            style: TextStyle(
              color: Theme.of(
                dialogContext,
              ).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            updateService.dismissUpdate();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Later'),
        ),
        if (updateInfo.moreInfoUrl.isNotEmpty)
          TextButton(
            onPressed: () async {
              final url = Uri.parse(updateInfo.moreInfoUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text('More Info'),
          ),
        ElevatedButton(
          onPressed: () async {
            final downloadUrl = updateService
                .getDownloadUrlForCurrentPlatform();
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              final url = Uri.parse(downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            }
            Get.back();
          },
          child: const Text('Download'),
        ),
      ],
    ),
  );
}
