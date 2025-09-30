import 'dart:io';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/widgets/shared/asset_type_button.dart';
import 'package:meadow/widgets/shared/assets_grid_item.dart';
import 'package:meadow/widgets/shared/task_grid_item.dart';
import 'package:meadow/widgets/shared/workspace_selector.dart';
import 'package:meadow/widgets/tasks/task.dart';

class AssetsTab extends StatelessWidget {
  const AssetsTab({super.key});

  Future<void> _addAsset(BuildContext context) async {
    final controller = Get.find<WorkspaceController>();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      try {
        await controller.addAssetFromFile(
          file,
          customName: result.files.single.name,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset added successfully!'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding asset: $e')),
          );
        }
      }
    }
  }

  Future<void> _onDropFile(
    BuildContext context,
    DropDoneDetails details,
  ) async {
    final controller = Get.find<WorkspaceController>();

    if (details.files.isNotEmpty) {
      final file = details.files.first;

      try {
        await controller.addAssetFromFile(
          File(file.path),
          customName: file.name,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset added successfully!'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding asset: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GetBuilder<WorkspaceController>(
      builder: (controller) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F0F23).withAlpha(200),
                    const Color(0xFF1A1A2E).withAlpha(200),
                  ]
                : [
                    const Color(0xFFF8FAFC).withAlpha(200),
                    const Color(0xFFE2E8F0).withAlpha(200),
                  ],
          ),
        ),
        child: Column(
          children: [
            // Workspace Selector Row with glass effect
            const WorkspaceSelector(),

            // Assets controls with responsive design
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  return Row(
                    children: [
                      _buildGlassAddButton(context, isDark),
                      const SizedBox(width: 16),
                      const Spacer(),
                      isMobile
                          ? _buildMobileAssetTypeDropdown(controller, isDark)
                          : _buildDesktopAssetTypeButtons(controller),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: DropTarget(
                onDragDone: (details) => _onDropFile(context, details),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isDark
                              ? Colors.black.withAlpha(50)
                              : Colors.white.withAlpha(100),
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }

                  final assetsAndTasks = controller.assetsAndTasks;
                  final selectedType = controller.selectedAsset.value;

                  if (assetsAndTasks.isEmpty) {
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            margin: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        Colors.black.withAlpha(75),
                                        Colors.black.withAlpha(25),
                                      ]
                                    : [
                                        Colors.white.withAlpha(150),
                                        Colors.white.withAlpha(75),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha(30)
                                    : Colors.black.withAlpha(20),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selectedType == null
                                      ? Icons.inventory_2_outlined
                                      : getIconForAssetType(selectedType),
                                  size: 48,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  selectedType == null
                                      ? 'No assets or active tasks found'
                                      : 'No ${selectedType.name} assets or tasks found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add assets using the button above or start generating content',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                        ),
                    itemCount: assetsAndTasks.length,
                    itemBuilder: (context, index) {
                      final item = assetsAndTasks[index];

                      // Check if item is a Task or Asset and render accordingly
                      if (item is Task) {
                        return TaskGridItem(
                          key: ValueKey(
                            'task_${item.workflow.hashCode}_${item.createdAt.millisecondsSinceEpoch}',
                          ),
                          task: item,
                        );
                      } else if (item is Asset) {
                        return AssetGridItem(
                          key: ValueKey('asset_${item.id}'),
                          asset: item,
                        );
                      } else {
                        // Fallback for unknown types
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Unknown item type',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAddButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _addAsset(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF10B981).withAlpha(200),
                        const Color(0xFF059669).withAlpha(200),
                      ]
                    : [
                        const Color(0xFF34D399).withAlpha(200),
                        const Color(0xFF10B981).withAlpha(200),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(50)
                    : Colors.white.withAlpha(100),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF34D399))
                          .withAlpha(75),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(50)
                      : Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Asset',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAssetTypeDropdown(
    WorkspaceController controller,
    bool isDark,
  ) {
    return Obx(
      () {
        final selectedType = controller.selectedAsset.value;
        final selectedLabel = selectedType == null
            ? 'All'
            : selectedType.name[0].toUpperCase() +
                  selectedType.name.substring(1);
        final selectedIcon = selectedType == null
            ? Icons.inventory_2_outlined
            : getIconForAssetType(selectedType);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withAlpha(20),
                          Colors.white.withAlpha(10),
                        ]
                      : [
                          Colors.black.withAlpha(15),
                          Colors.black.withAlpha(5),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(30)
                      : Colors.black.withAlpha(20),
                ),
              ),
              child: DropdownButton<AssetType?>(
                value: selectedType,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 16,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                items: [
                  DropdownMenuItem<AssetType?>(
                    value: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text('All'),
                      ],
                    ),
                  ),
                  ...AssetType.values.map(
                    (type) => DropdownMenuItem<AssetType?>(
                      value: type,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getIconForAssetType(type),
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.name[0].toUpperCase() + type.name.substring(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  controller.setAssetTypeFilter(value);
                },
                selectedItemBuilder: (context) => [
                  // Selected item for 'All'
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedIcon,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedLabel,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Selected items for asset types
                  ...AssetType.values.map(
                    (type) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getIconForAssetType(type),
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopAssetTypeButtons(WorkspaceController controller) {
    return Obx(
      () => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          AssetTypeButton(
            icon: Icons.inventory_2_outlined,
            label: 'All',
            selected: controller.selectedAsset.value == null,
            onTap: () {
              controller.setAssetTypeFilter(null);
            },
          ),
          ...AssetType.values.map(
            (type) => AssetTypeButton(
              icon: getIconForAssetType(type),
              label: type.name[0].toUpperCase() + type.name.substring(1),
              selected: controller.selectedAsset.value == type,
              onTap: () {
                controller.setAssetTypeFilter(type);
              },
            ),
          ),
        ],
      ),
    );
  }
}
