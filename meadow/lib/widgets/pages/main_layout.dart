import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/theme_controller.dart';
import 'package:meadow/services/update_check_service.dart';
import 'package:meadow/widgets/pages/model_manager_page.dart';
import 'package:meadow/widgets/dialogs/theme_settings_dialog.dart';
import 'package:meadow/widgets/dialogs/app_settings_dialog.dart';
import 'package:meadow/widgets/pages/document_tabs.dart';
import 'package:meadow/widgets/pages/tab_list.dart';
import 'package:meadow/models/menu_item.dart';
import 'package:url_launcher/url_launcher.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;

  TabController? _tabController;

  double _sidebarWidth = 350.0;

  final List<MenuItem> _tabs = tabList;

  // Get ThemeController
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildMobileLayout(BuildContext context) {
    _tabController ??= TabController(length: _tabs.length, vsync: this);
    _tabController!.index = _selectedTabIndex;

    // Use GetX for theme mode
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meadow'),
          actions: [
            GestureDetector(
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => const ThemeSettingsDialog(),
                );
              },
              child: IconButton(
                icon: Icon(_themeController.themeIcon),
                tooltip:
                    'Toggle Theme (${_themeController.themeName}) - Long press for options',
                onPressed: () {
                  _themeController.toggleTheme();
                },
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs
                .map(
                  (tab) =>
                      Tab(text: tab.title, icon: tab.getIconWidget(size: 24)),
                )
                .toList(),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            indicatorWeight: 2.0,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe if using onTap
          children: _tabs.map((tab) => tab.content).toList(),
        ),
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    // Use GetX for theme mode
    return Obx(() {
      final theme = Theme.of(context);

      final selectedTab = _tabs[_selectedTabIndex];
      final hasSubTabs = selectedTab.subTabs.isNotEmpty;

      TabController? subTabController;
      if (hasSubTabs) {
        subTabController = TabController(
          length: selectedTab.subTabs.length,
          vsync: this,
          initialIndex: selectedTab.selectedSubTabIndex,
        );
        subTabController.addListener(() {
          if (subTabController!.index != selectedTab.selectedSubTabIndex) {
            setState(() {
              selectedTab.selectedSubTabIndex = subTabController!.index;
            });
          }
        });
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          centerTitle: false,
          title: Text('Meadow Studio'),
          actions: [
            InkWell(
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => const ThemeSettingsDialog(),
                );
              },
              child: IconButton(
                icon: Icon(_themeController.themeIcon),
                tooltip:
                    'Toggle Theme (${_themeController.themeName}) - Long press for options',
                onPressed: () {
                  _themeController.toggleTheme();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: <Widget>[
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tabs.length,
                      itemBuilder: (context, idx) {
                        final tab = _tabs[idx];
                        final isActive = idx == _selectedTabIndex;
                        return Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = idx;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary.withAlpha(40)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    tab.getIconWidget(
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.iconTheme.color,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tab.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? theme.colorScheme.primary
                                            : theme.textTheme.bodyMedium?.color,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Update notification icon (above Models and Settings)
                  _buildUpdateNotificationIcon(),
                  if (!kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.macOS ||
                          defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.linux))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModelManagerDialog(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.model_training),
                              const SizedBox(height: 6),
                              Text(
                                'Models',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AppSettingsDialog(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings),
                            const SizedBox(height: 6),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: theme.colorScheme.surface.withAlpha(120),
              child: Stack(
                children: [
                  SizedBox(
                    width: _sidebarWidth,
                    child: Column(
                      children: [
                        hasSubTabs
                            ? Container(
                                color: theme.colorScheme.surface,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 0,
                                ),
                                child: TabBar(
                                  controller: subTabController,
                                  isScrollable: true,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      25,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      4,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  tabAlignment: TabAlignment.center,
                                  tabs: selectedTab.subTabs
                                      .map(
                                        (subTab) => Tab(
                                          text: subTab.title,
                                          icon: Icon(subTab.icon),
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                        Expanded(
                          child: hasSubTabs
                              ? TabBarView(
                                  controller: subTabController,
                                  children: selectedTab.subTabs
                                      .map((subTab) => subTab.content)
                                      .toList(),
                                )
                              : selectedTab.content,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _sidebarWidth += details.delta.dx;
                            _sidebarWidth = _sidebarWidth.clamp(200.0, 600.0);
                          });
                        },
                        child: Container(
                          width: 8,
                          color: Colors.transparent,
                          child: const Center(
                            child: VerticalDivider(
                              width: 4,
                              thickness: 2,
                              color: Color(0x22eeeeee),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DocumentTabs(),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to switch between mobile and desktop layouts
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Typical breakpoint for mobile
          // Mobile layout
          if (_tabController == null ||
              _tabController!.length != _tabs.length) {
            _tabController?.dispose();
            _tabController = TabController(
              length: _tabs.length,
              vsync: this,
              initialIndex: _selectedTabIndex,
            );
          }
          _tabController!.addListener(() {
            if (_tabController!.indexIsChanging) {
              // If tab is changed by swipe, update _selectedIndex
              // setState(() {
              //   _selectedIndex = _tabController!.index;
              // });
            } else {
              // If tab is changed programmatically (e.g. by onTap in TabBar), ensure _selectedIndex is synced
              if (_selectedTabIndex != _tabController!.index) {
                // This case should ideally be handled by the TabBar's onTap
              }
            }
          });
          return _buildMobileLayout(context);
        } else {
          // Desktop layout
          _tabController?.dispose();
          _tabController = null;
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  /// Build update notification icon for sidebar
  Widget _buildUpdateNotificationIcon() {
    final updateService = Get.find<UpdateCheckService>();

    return Obx(() {
      if (!updateService.isUpdateAvailable) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showUpdateDialog(),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.system_update,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Show update available dialog
  void _showUpdateDialog() {
    final updateService = Get.find<UpdateCheckService>();
    final updateInfo = updateService.latestUpdateInfo;

    if (updateInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Platform: ${updateService.getCurrentPlatformName()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              updateService.dismissUpdate();
              Navigator.of(context).pop();
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
}
