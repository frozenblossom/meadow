import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/document_tabs_controller.dart';
import 'package:meadow/widgets/dialogs/confirm_save_dialog.dart';
import 'package:meadow/widgets/pages/assets_tab.dart';

class DocumentTabs extends StatefulWidget {
  const DocumentTabs({super.key});

  @override
  State<DocumentTabs> createState() => _DocumentTabsState();
}

class _DocumentTabsState extends State<DocumentTabs>
    with TickerProviderStateMixin {
  TabController? _controller;
  int _lastTabCount = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Obx for reactive updates
    return GetBuilder<DocumentsTabsController>(
      builder: (controller) {
        final tabs = controller.documents;
        final totalTabs = tabs.length + 1;
        final activeTabIndex = controller.activeTabIndex;

        // Recreate controller if tab count changes
        if (_controller == null || _lastTabCount != totalTabs) {
          _controller?.dispose();
          _controller = TabController(
            length: totalTabs,
            vsync: this,
            initialIndex: (activeTabIndex.value < totalTabs)
                ? activeTabIndex.value
                : 0,
          );
          _lastTabCount = totalTabs;
        }

        return Column(
          children: [
            TabBar(
              controller: _controller,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(child: Text('Assets')),
                ...tabs.map((tab) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tab.title ?? 'Untitled'),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            if (tab.isDirty) {
                              final shouldClose = await Get.dialog(
                                ConfirmSaveDialog(),
                              );
                              if (shouldClose != true) return;
                            }
                            controller.closeTab(tab);
                          },
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  const AssetsTab(),
                  ...tabs.map(
                    (tab) =>
                        tab.content ??
                        const Center(child: Text('No content available')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
