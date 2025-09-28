import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../integrations/comfyui/services/comfyui_model_manager.dart';

class ComfyUIModelBrowser extends StatelessWidget {
  const ComfyUIModelBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ComfyUIModelManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ComfyUI Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshModels,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(controller),
          _buildFilterChips(controller),
          Expanded(child: _buildModelList(controller)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ComfyUIModelManager controller) {
    return Obx(
      () => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Models',
                controller.totalModels.toString(),
                Icons.memory,
              ),
              _buildSummaryItem(
                'Types',
                controller.totalFolders.toString(),
                Icons.folder,
              ),
              _buildSummaryItem(
                'Size',
                controller.totalSizeFormatted,
                Icons.storage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ComfyUIModelManager controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        child: Row(
          children: [
            const Text('Filter: '),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Type filter chips
                    ...controller.availableTypes.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: controller.selectedTypes.contains(type),
                          onSelected: (selected) {
                            if (selected) {
                              controller.selectedTypes.add(type);
                            } else {
                              controller.selectedTypes.remove(type);
                            }
                          },
                        ),
                      ),
                    ),
                    // Clear filters
                    if (controller.selectedTypes.isNotEmpty ||
                        controller.selectedTags.isNotEmpty ||
                        controller.searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          label: const Text('Clear'),
                          onPressed: controller.clearFilters,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelList(ComfyUIModelManager controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading models',
                style: Theme.of(Get.context!).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(controller.error.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.refreshModels,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      final filteredModels = controller.filteredModels;
      if (filteredModels.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No models found'),
              Text(
                'Try adjusting your filters or search query',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshModels,
        child: ListView.builder(
          itemCount: filteredModels.length,
          itemBuilder: (context, index) {
            final model = filteredModels[index];
            return _buildModelTile(model, controller);
          },
        ),
      );
    });
  }

  Widget _buildModelTile(
    ComfyUIModelInfo model,
    ComfyUIModelManager controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(model.type),
          child: Text(
            model.type.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          model.friendlyName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.fileName),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(model.type).withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    model.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTypeColor(model.type),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  model.sizeFormatted,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (model.description != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(model.description!),
                  const SizedBox(height: 12),
                ],
                if (model.allTags.isNotEmpty) ...[
                  const Text(
                    'Tags',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: model.allTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (model.hasSafetensorsMetadata) ...[
                  const Text(
                    'Model Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...model.metadata!.entries
                      .take(5)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '${entry.key}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (model.metadata!.length > 5)
                    TextButton(
                      onPressed: () => _showFullMetadata(model),
                      child: const Text('View Full Metadata'),
                    ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      onPressed: () => _showModelDetails(model),
                    ),
                    if (model.type == 'checkpoints')
                      TextButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Use Model'),
                        onPressed: () => _useModel(model),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'checkpoints':
        return Colors.blue;
      case 'loras':
        return Colors.green;
      case 'embeddings':
        return Colors.orange;
      case 'vae':
        return Colors.purple;
      case 'controlnet':
        return Colors.red;
      case 'upscale_models':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showSearchDialog(BuildContext context, ComfyUIModelManager controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Models'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search query',
                hintText: 'Enter model name, filename, or tag',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.searchModels,
            ),
            const SizedBox(height: 16),
            const Text('Filter by tags:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: Obx(
                () => SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: controller.availableTags
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: controller.selectedTags.contains(tag),
                            onSelected: (selected) {
                              if (selected) {
                                controller.selectedTags.add(tag);
                              } else {
                                controller.selectedTags.remove(tag);
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showModelDetails(ComfyUIModelInfo model) {
    Get.dialog(
      AlertDialog(
        title: Text(model.friendlyName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('File Name', model.fileName),
              _buildDetailRow('Type', model.type),
              _buildDetailRow('Size', model.sizeFormatted),
              if (model.description != null)
                _buildDetailRow('Description', model.description!),
              if (model.modelType != null)
                _buildDetailRow('Model Type', model.modelType!),
              if (model.baseModel != null)
                _buildDetailRow('Base Model', model.baseModel!),
              if (model.architecture != null)
                _buildDetailRow('Architecture', model.architecture!),
              const SizedBox(height: 16),
              const Text(
                'Available',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(
                    model.isAvailable ? Icons.check_circle : Icons.error,
                    color: model.isAvailable ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(model.isAvailable ? 'Yes' : 'No'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.overlayContext!).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFullMetadata(ComfyUIModelInfo model) {
    Get.dialog(
      AlertDialog(
        title: Text('${model.friendlyName} - Full Metadata'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: model.metadata!.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.overlayContext!).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _useModel(ComfyUIModelInfo model) {
    // This would trigger workflow creation or selection
    Get.snackbar(
      'Use Model',
      'Would create workflow with ${model.friendlyName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
