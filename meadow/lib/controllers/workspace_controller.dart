import 'dart:io';

import 'package:get/get.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/workspace.dart';
import 'package:meadow/models/local_workspace.dart';
import 'package:meadow/services/local_asset_service.dart';
import 'package:meadow/widgets/tasks/task.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class WorkspaceController extends GetxController {
  static const String _selectedWorkspaceKey = 'selected_workspace_id';

  var currentWorkspace = Rx<Workspace?>(null);
  var availableWorkspaces = <Workspace>[].obs;
  var selectedAsset = Rx<AssetType?>(null);
  var assets = <Asset>[].obs;
  var isLoading = false.obs;

  LocalAssetService? _assetService;

  LocalAssetService? get assetService => _assetService;

  /// Unified getter that combines assets with active tasks for display in the grid
  List<dynamic> get assetsAndTasks {
    try {
      final tasksController = Get.find<TasksController>();
      final activeTasks = tasksController.tasks
          .where(
            (task) =>
                !task.isCompleted ||
                task.isFailed ||
                task.isRunning ||
                task.isPending,
          )
          .toList();

      // Filter tasks by selected asset type if applicable
      List<Task> filteredTasks = activeTasks;
      if (selectedAsset.value != null) {
        filteredTasks = activeTasks
            .where((task) => _getTaskAssetType(task) == selectedAsset.value)
            .toList();
      }

      // Combine tasks (first) with assets (after)
      final List<dynamic> combined = <dynamic>[];
      combined.addAll(filteredTasks);
      combined.addAll(assets);

      return combined;
    } catch (e) {
      // If TasksController is not available, just return assets
      return assets.toList();
    }
  }

  /// Helper method to determine asset type from task metadata
  AssetType? _getTaskAssetType(Task task) {
    final metadata = task.metadata;

    if (metadata != null && metadata.containsKey('type')) {
      final type = metadata['type'];
      switch (type) {
        case 'image':
          return AssetType.image;
        case 'video':
          return AssetType.video;
        case 'audio':
          return AssetType.audio;
      }
    }

    // Fallback: try to guess from description
    final description = task.description.toLowerCase();
    if (description.contains('image') || description.contains('picture')) {
      return AssetType.image;
    }
    if (description.contains('video')) {
      return AssetType.video;
    }
    if (description.contains('audio') ||
        description.contains('speech') ||
        description.contains('music')) {
      return AssetType.audio;
    }

    return null; // Unknown type
  }

  @override
  void onInit() {
    super.onInit();
    _initializeDefaultWorkspace();
  }

  void setWorkspace(Workspace workspace) {
    currentWorkspace.value = workspace;
    if (workspace is LocalWorkspace) {
      _assetService = LocalAssetService(workspace);
    }
    // Future: Add cloud workspace service here

    // Save the selected workspace
    _saveSelectedWorkspace(workspace.id);

    reloadAssets();
  }

  /// Save the selected workspace ID to SharedPreferences
  Future<void> _saveSelectedWorkspace(String workspaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedWorkspaceKey, workspaceId);
    } catch (e) {
      // print('Error saving selected workspace: $e');
    }
  }

  /// Load the last selected workspace ID from SharedPreferences
  Future<String?> _getSelectedWorkspaceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedWorkspaceKey);
    } catch (e) {
      //print('Error loading selected workspace: $e');
      return null;
    }
  }

  Future<void> _initializeDefaultWorkspace() async {
    final workspaces = await discoverLocalWorkspaces();
    availableWorkspaces.value = workspaces;

    // Try to load the last selected workspace
    final savedWorkspaceId = await _getSelectedWorkspaceId();
    Workspace? targetWorkspace;

    if (savedWorkspaceId != null && workspaces.isNotEmpty) {
      // Try to find the saved workspace
      try {
        targetWorkspace = workspaces.firstWhere(
          (ws) => ws.id == savedWorkspaceId,
        );
      } catch (e) {
        // Workspace not found, will use default
        targetWorkspace = null;
      }
    }

    if (targetWorkspace == null) {
      if (workspaces.isEmpty) {
        // Create a default workspace
        final defaultWorkspace = await createWorkspace('Default Workspace');
        availableWorkspaces.add(defaultWorkspace);
        targetWorkspace = defaultWorkspace;
      } else {
        // Look for a workspace named "Default Workspace" or use the first one
        try {
          targetWorkspace = workspaces.firstWhere(
            (ws) => ws.name == 'Default Workspace',
          );
        } catch (e) {
          targetWorkspace = workspaces.first;
        }
      }
    }

    setWorkspace(targetWorkspace);
  }

  Future<LocalWorkspace> createWorkspace(
    String name, {
    int? width,
    int? height,
    int? videoDurationSeconds,
  }) async {
    final workspace = LocalWorkspace(
      id: const Uuid().v4(),
      name: name,
      ownerId: 'currentUser',
      isTeamOwned: false,
      defaultWidth: width,
      defaultHeight: height,
      videoDurationSeconds: videoDurationSeconds ?? 5,
    );

    // Ensure workspace directory is created
    final appDocDir = await getApplicationDocumentsDirectory();
    final wsDir = Directory(
      p.join(appDocDir.path, 'meadow_user_assets', name),
    );
    if (!await wsDir.exists()) {
      await wsDir.create(recursive: true);
    }

    // Save initial settings
    final initialSettings = await workspace.loadSettings();
    await workspace.saveSettings(initialSettings);

    availableWorkspaces.add(workspace);
    return workspace;
  }

  Future<void> deleteWorkspace(Workspace workspace) async {
    if (workspace == currentWorkspace.value) {
      throw Exception('Cannot delete the currently active workspace');
    }

    await workspace.deleteWorkspace();
    availableWorkspaces.remove(workspace);

    // If this was the saved workspace, clear the preference
    final savedWorkspaceId = await _getSelectedWorkspaceId();
    if (savedWorkspaceId == workspace.id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedWorkspaceKey);
    }
  }

  Future<void> renameWorkspace(Workspace workspace, String newName) async {
    await workspace.updateWorkspaceDetails(name: newName);

    // Update the workspace in our list
    final index = availableWorkspaces.indexWhere((w) => w.id == workspace.id);
    if (index != -1) {
      // For LocalWorkspace, create a new instance with updated name
      if (workspace is LocalWorkspace) {
        final updatedWorkspace = LocalWorkspace(
          id: workspace.id,
          name: newName,
          ownerId: workspace.ownerId,
          isTeamOwned: workspace.isTeamOwned,
          defaultWidth: workspace.defaultWidth,
          defaultHeight: workspace.defaultHeight,
          videoDurationSeconds: workspace.videoDurationSeconds,
        );
        availableWorkspaces[index] = updatedWorkspace;

        // If this is the current workspace, update the reference and save
        if (workspace == currentWorkspace.value) {
          currentWorkspace.value = updatedWorkspace;
          // Update the asset service reference
          _assetService = LocalAssetService(updatedWorkspace);
          // Save the workspace selection (ID should be the same)
          _saveSelectedWorkspace(updatedWorkspace.id);
        }
      }
    }
  }

  Future<void> updateWorkspaceDimensions(
    Workspace workspace,
    int? width,
    int? height,
  ) async {
    await workspace.updateWorkspaceDetails(width: width, height: height);

    // Update the workspace in our list
    final index = availableWorkspaces.indexWhere((w) => w.id == workspace.id);
    if (index != -1) {
      // For LocalWorkspace, create a new instance with updated dimensions
      if (workspace is LocalWorkspace) {
        final updatedWorkspace = LocalWorkspace(
          id: workspace.id,
          name: workspace.name,
          ownerId: workspace.ownerId,
          isTeamOwned: workspace.isTeamOwned,
          defaultWidth: width,
          defaultHeight: height,
          videoDurationSeconds: workspace.videoDurationSeconds,
        );
        availableWorkspaces[index] = updatedWorkspace;

        // If this is the current workspace, update the reference
        if (workspace == currentWorkspace.value) {
          currentWorkspace.value = updatedWorkspace;
          // Update the asset service reference
          _assetService = LocalAssetService(updatedWorkspace);
        }
      }
    }
  }

  Future<void> updateWorkspaceVideoDuration(
    Workspace workspace,
    int videoDurationSeconds,
  ) async {
    await workspace.updateWorkspaceDetails(
      videoDurationSeconds: videoDurationSeconds,
    );

    // Update the workspace in our list
    final index = availableWorkspaces.indexWhere((w) => w.id == workspace.id);
    if (index != -1) {
      // For LocalWorkspace, create a new instance with updated video duration
      if (workspace is LocalWorkspace) {
        final updatedWorkspace = LocalWorkspace(
          id: workspace.id,
          name: workspace.name,
          ownerId: workspace.ownerId,
          isTeamOwned: workspace.isTeamOwned,
          defaultWidth: workspace.defaultWidth,
          defaultHeight: workspace.defaultHeight,
          videoDurationSeconds: videoDurationSeconds,
        );
        availableWorkspaces[index] = updatedWorkspace;

        // If this is the current workspace, update the reference
        if (workspace == currentWorkspace.value) {
          currentWorkspace.value = updatedWorkspace;
          // Update the asset service reference
          _assetService = LocalAssetService(updatedWorkspace);
        }
      }
    }
  }

  Future<void> updateWorkspaceSettings(
    Workspace workspace, {
    int? width,
    int? height,
    int? videoDurationSeconds,
  }) async {
    await workspace.updateWorkspaceDetails(
      width: width,
      height: height,
      videoDurationSeconds: videoDurationSeconds,
    );

    // Update the workspace in our list
    final index = availableWorkspaces.indexWhere((w) => w.id == workspace.id);
    if (index != -1) {
      // For LocalWorkspace, create a new instance with updated settings
      if (workspace is LocalWorkspace) {
        final updatedWorkspace = LocalWorkspace(
          id: workspace.id,
          name: workspace.name,
          ownerId: workspace.ownerId,
          isTeamOwned: workspace.isTeamOwned,
          defaultWidth: width ?? workspace.defaultWidth,
          defaultHeight: height ?? workspace.defaultHeight,
          videoDurationSeconds:
              videoDurationSeconds ?? workspace.videoDurationSeconds,
        );
        availableWorkspaces[index] = updatedWorkspace;

        // If this is the current workspace, update the reference
        if (workspace == currentWorkspace.value) {
          currentWorkspace.value = updatedWorkspace;
          // Update the asset service reference
          _assetService = LocalAssetService(updatedWorkspace);
        }
      }
    }
  }

  Future<void> moveAsset(Asset asset, Workspace targetWorkspace) async {
    if (currentWorkspace.value == null ||
        targetWorkspace == currentWorkspace.value) {
      return;
    }

    try {
      // First, add to target workspace (this copies the file)
      await targetWorkspace.addAsset(asset);

      // Only after successful copy, remove from current workspace
      await currentWorkspace.value!.removeAsset(asset.id);

      // Reload assets to reflect changes
      await reloadAssets();
    } catch (e) {
      // If move fails, ensure we don't leave partial state
      rethrow;
    }
  }

  Future<void> copyAsset(Asset asset, Workspace targetWorkspace) async {
    if (currentWorkspace.value == null) {
      return;
    }

    // Add a copy to target workspace
    await targetWorkspace.addAsset(asset);
  }

  Future<List<LocalWorkspace>> discoverLocalWorkspaces() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final rootDir = Directory(p.join(appDocDir.path, 'meadow_user_assets'));
    if (!await rootDir.exists()) {
      availableWorkspaces.value = [];
      return [];
    }

    final dirs = rootDir.listSync().whereType<Directory>();
    final workspaces = <LocalWorkspace>[];

    for (final dir in dirs) {
      try {
        final workspace = await LocalWorkspace.fromSettings(
          id: dir.path,
          name: p.basename(dir.path),
          ownerId: 'currentUser',
          isTeamOwned: false,
        );
        workspaces.add(workspace);
      } catch (e) {
        // If loading settings fails, create workspace with defaults
        final workspace = LocalWorkspace(
          id: dir.path,
          name: p.basename(dir.path),
          ownerId: 'currentUser',
          isTeamOwned: false,
          defaultWidth: null,
          defaultHeight: null,
          videoDurationSeconds: 5,
        );
        workspaces.add(workspace);
      }
    }

    availableWorkspaces.value = workspaces;
    return workspaces;
  }

  Future<void> reloadAssets() async {
    if (_assetService == null) return;

    isLoading.value = true;
    try {
      final filteredAssets = await _assetService!.getAssets(
        filterType: selectedAsset.value,
      );
      assets.value = filteredAssets;
    } catch (e) {
      // print('Error loading assets: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Asset?> addAssetFromFile(
    File file, {
    String? customName,
    Map<String, dynamic>? metadata,
  }) async {
    if (_assetService == null) return null;

    try {
      var asset = await _assetService!.addAsset(
        file,
        desiredName: customName,
      );

      if (metadata != null) {
        asset.updateMetadata(metadata);
      }

      await reloadAssets();

      return asset;
    } catch (e) {
      //print('Error adding asset: $e');
      rethrow;
    }
  }

  Future<void> deleteAsset(String assetId) async {
    if (_assetService == null) return;

    try {
      await _assetService!.deleteAsset(assetId);
      await reloadAssets();
    } catch (e) {
      //print('Error deleting asset: $e');
      rethrow;
    }
  }

  Future<void> renameAsset(String assetId, String newName) async {
    if (_assetService == null) return;

    try {
      await _assetService!.renameAsset(assetId, newName);
      await reloadAssets();
    } catch (e) {
      //print('Error renaming asset: $e');
      rethrow;
    }
  }

  void setAssetTypeFilter(AssetType? type) {
    selectedAsset.value = type;
    reloadAssets();
  }
}
