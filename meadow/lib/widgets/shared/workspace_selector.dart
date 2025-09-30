import 'dart:ui';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.black.withAlpha(100),
                      Colors.black.withAlpha(50),
                    ]
                  : [
                      Colors.white.withAlpha(100),
                      Colors.white.withAlpha(50),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(30)
                  : Colors.black.withAlpha(20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(50)
                    : Colors.black.withAlpha(15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () {
                  // Update the controller text when the current workspace changes
                  final currentWorkspace = controller.currentWorkspace.value;
                  _dropdownController.text = currentWorkspace?.name ?? '';

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withAlpha(30)
                            : Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(20)
                              : Colors.black.withAlpha(15),
                        ),
                      ),
                      child: DropdownMenu<Workspace>(
                        width: 280,
                        controller: _dropdownController,
                        inputDecorationTheme: InputDecorationTheme(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withAlpha(128)
                                : Colors.black.withAlpha(128),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        textStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        dropdownMenuEntries: controller.availableWorkspaces.map(
                          (ws) {
                            return DropdownMenuEntry(
                              value: ws,
                              label: ws.name,
                              labelWidget: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ws.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
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
                          },
                        ).toList(),
                        onSelected: (val) {
                          if (val != null) {
                            controller.setWorkspace(val);
                          }
                        },
                        hintText: 'Select Workspace',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildGlassIconButton(
                icon: Icons.add,
                tooltip: 'Create New Workspace',
                onPressed: _createNewWorkspace,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh Workspaces',
                onPressed: _refreshWorkspaces,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(30)
              : Colors.black.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(30)
                : Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}
