import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/models/workspace.dart';
import 'package:meadow/widgets/dialogs/workspace_form_dialog.dart';

class WorkspaceSelector extends StatefulWidget {
  const WorkspaceSelector({super.key});

  @override
  State<WorkspaceSelector> createState() => _WorkspaceSelectorState();
}

class _WorkspaceSelectorState extends State<WorkspaceSelector> {
  bool isLoading = false;
  late TextEditingController _dropdownController;

  @override
  void initState() {
    super.initState();
    _dropdownController = TextEditingController();
    _refreshWorkspaces();
  }

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }

  Future<void> _refreshWorkspaces() async {
    setState(() {
      isLoading = true;
    });

    try {
      final controller = Get.find<WorkspaceController>();
      await controller.discoverLocalWorkspaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workspaces: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewWorkspace() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const WorkspaceFormDialog(),
    );

    if (result != null) {
      final workspaceName = result['name'] as String;
      final width = result['width'] as int?;
      final height = result['height'] as int?;
      final videoDurationSeconds = result['videoDurationSeconds'] as int? ?? 5;

      try {
        final workspaceController = Get.find<WorkspaceController>();
        final newWorkspace = await workspaceController.createWorkspace(
          workspaceName,
          width: width,
          height: height,
          videoDurationSeconds: videoDurationSeconds,
        );
        workspaceController.setWorkspace(newWorkspace);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace "$workspaceName" created successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating workspace: $e')),
          );
        }
      }
    }
  }

  Future<void> _editWorkspace(Workspace workspace) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WorkspaceFormDialog(
        initialName: workspace.name,
        initialWidth: workspace.defaultWidth,
        initialHeight: workspace.defaultHeight,
        initialVideoDurationSeconds: workspace.videoDurationSeconds,
        isEdit: true,
      ),
    );

    if (result != null) {
      final newName = result['name'] as String;
      final width = result['width'] as int?;
      final height = result['height'] as int?;
      final videoDurationSeconds = result['videoDurationSeconds'] as int? ?? 5;

      try {
        final workspaceController = Get.find<WorkspaceController>();

        // Update all settings at once using the new method
        await workspaceController.updateWorkspaceSettings(
          workspace,
          width: width,
          height: height,
          videoDurationSeconds: videoDurationSeconds,
        );

        // Update name if changed (this needs to be separate)
        if (newName != workspace.name) {
          await workspaceController.renameWorkspace(workspace, newName);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace updated successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating workspace: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteWorkspace(Workspace workspace) async {
    final workspaceController = Get.find<WorkspaceController>();

    if (workspace == workspaceController.currentWorkspace.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the currently active workspace'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text(
          'Are you sure you want to delete "${workspace.name}"? This action cannot be undone and all assets in this workspace will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await workspaceController.deleteWorkspace(workspace);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Workspace "${workspace.name}" deleted successfully!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting workspace: $e')),
          );
        }
      }
    }
  }

  Widget _buildWorkspaceActions(Workspace workspace) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Workspace Actions',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editWorkspace(workspace);
            break;
          case 'delete':
            _deleteWorkspace(workspace);
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceController>();

    if (isLoading) {
      return const SizedBox(
        width: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () {
            // Update the controller text when the current workspace changes
            final currentWorkspace = controller.currentWorkspace.value;
            _dropdownController.text = currentWorkspace?.name ?? '';

            return Expanded(
              child: DropdownMenu<Workspace>(
                width: 300,
                controller: _dropdownController,
                dropdownMenuEntries: controller.availableWorkspaces.map((ws) {
                  return DropdownMenuEntry(
                    value: ws,
                    label: ws.name,
                    labelWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ws.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            if (ws.defaultWidth != null &&
                                ws.defaultHeight != null)
                              Text(
                                ws.dimensionString,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (ws.defaultWidth != null &&
                                ws.defaultHeight != null)
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            Text(
                              '${ws.videoDurationSeconds}s video',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailingIcon: _buildWorkspaceActions(ws),
                  );
                }).toList(),
                onSelected: (val) {
                  if (val != null) {
                    controller.setWorkspace(val);
                  }
                },
                hintText: 'Select Workspace',
              ),
            );
          },
        ),

        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Create New Workspace',
          onPressed: _createNewWorkspace,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Workspaces',
          onPressed: _refreshWorkspaces,
        ),
      ],
    );
  }
}
