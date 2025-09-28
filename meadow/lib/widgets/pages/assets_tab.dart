import 'dart:io';
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

    return GetBuilder<WorkspaceController>(
      builder: (controller) => Material(
        elevation: 1.0,
        shadowColor: theme.shadowColor.withAlpha(25),
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            // Workspace Selector Row
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: WorkspaceSelector(),
            ),

            // Assets controls
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add Asset'),
                    onPressed: () => _addAsset(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Obx(
                    () => Row(
                      children: [
                        AssetTypeButton(
                          icon: Icons.inventory_2_outlined,
                          label: 'All',
                          selected: controller.selectedAsset.value == null,
                          onTap: () {
                            controller.setAssetTypeFilter(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...AssetType.values.map(
                          (type) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: AssetTypeButton(
                              icon: getIconForAssetType(type),
                              label:
                                  type.name[0].toUpperCase() +
                                  type.name.substring(1),
                              selected: controller.selectedAsset.value == type,
                              onTap: () {
                                controller.setAssetTypeFilter(type);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DropTarget(
                onDragDone: (details) => _onDropFile(context, details),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final assetsAndTasks = controller.assetsAndTasks;
                  final selectedType = controller.selectedAsset.value;

                  if (assetsAndTasks.isEmpty) {
                    return Center(
                      child: Text(
                        selectedType == null
                            ? 'No assets or active tasks found. Add assets using the button above or start generating content.'
                            : 'No ${selectedType.name} assets or tasks found.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
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
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Center(
                            child: Text(
                              'Unknown item type',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
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
}
