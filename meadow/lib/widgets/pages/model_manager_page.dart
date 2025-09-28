import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/model_manager_controller.dart';
import '../../models/downloadable_model.dart';

/// Show the ComfyUI Model Manager in a dialog
void showModelManagerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ModelManagerDialog(),
  );
}

/// Desktop-only dialog for managing ComfyUI model downloads
class ModelManagerDialog extends StatelessWidget {
  const ModelManagerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ModelManagerController());

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
          maxWidth: 1400,
          maxHeight: 1000,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ComfyUI Model Manager'),
            automaticallyImplyLeading: false,
            actions: [
              Obx(
                () => IconButton(
                  onPressed: controller.isLoading
                      ? null
                      : controller.refreshModels,
                  icon: controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh Model Catalog',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ModelManagerContent(controller: controller),
        ),
      ),
    );
  }
}

/// Content widget for the model manager
class ModelManagerContent extends StatelessWidget {
  final ModelManagerController controller;

  const ModelManagerContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with ComfyUI directory and search
        _buildHeader(controller),

        // Filters and stats
        _buildFiltersSection(controller),

        // Error message
        Obx(
          () => controller.errorMessage.isNotEmpty
              ? _buildErrorBanner(controller)
              : const SizedBox.shrink(),
        ),

        // Model grid
        Expanded(
          child: Obx(
            () => controller.filteredModels.isEmpty
                ? _buildEmptyState(controller)
                : _buildModelGrid(controller),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ModelManagerController controller) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outline)),
          ),
          child: Column(
            children: [
              // ComfyUI Directory Section
              Row(
                children: [
                  Icon(Icons.folder, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'ComfyUI Directory:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(6),
                          color: colorScheme.surfaceContainer,
                        ),
                        child: Text(
                          controller.comfyUIDirectory.isEmpty
                              ? 'No directory selected'
                              : controller.comfyUIDirectory,
                          style: TextStyle(
                            color: controller.comfyUIDirectory.isEmpty
                                ? colorScheme.onSurface.withAlpha(153)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: controller.selectComfyUIDirectory,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Directory'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Section
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: controller.searchModels,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: controller.availableCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category == 'all'
                                  ? 'All Categories'
                                  : category.capitalize!,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            controller.filterByCategory(value ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(ModelManagerController controller) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(51),
              border: Border(bottom: BorderSide(color: colorScheme.outline)),
            ),
            child: Row(
              children: [
                _buildStatChip(
                  context,
                  'Total',
                  controller.availableModels.length.toString(),
                  Icons.apps,
                  colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  context,
                  'Downloaded',
                  controller.downloadedModelCount.toString(),
                  Icons.download_done,
                  colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  context,
                  'Filtered',
                  controller.filteredModels.length.toString(),
                  Icons.filter_list,
                  colorScheme.secondary,
                ),
                const Spacer(),
                if (!controller.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 14,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ModelManagerController controller) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            border: Border.all(color: colorScheme.error),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.errorMessage,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              IconButton(
                onPressed: controller.clearError,
                icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ModelManagerController controller) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        if (controller.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Loading model catalog...',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurface.withAlpha(102),
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.isNotEmpty
                    ? 'No models found matching "${controller.searchQuery}"'
                    : 'No models available',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Check your internet connection or try refreshing',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(128),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.refreshModels,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelGrid(ModelManagerController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enhanced responsive grid columns for dialog layout
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 500) {
          // Very small screens - 1 column
          crossAxisCount = 1;
          childAspectRatio = 1.6;
        } else if (constraints.maxWidth < 750) {
          // Small screens - 2 columns
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else if (constraints.maxWidth < 1000) {
          // Medium screens - 3 columns
          crossAxisCount = 3;
          childAspectRatio = 1.2;
        } else if (constraints.maxWidth < 1300) {
          // Large screens - 4 columns
          crossAxisCount = 4;
          childAspectRatio = 1.1;
        } else {
          // Extra large screens - 5 columns
          crossAxisCount = 5;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: controller.filteredModels.length,
          itemBuilder: (context, index) {
            final model = controller.filteredModels[index];
            return _buildModelCard(context, controller, model);
          },
        );
      },
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    ModelManagerController controller,
    DownloadableModel model,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showModelDetails(context, controller, model),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusIcon(context, controller, model),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  model.description,
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(153),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 12),

              // Size and download info
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 14,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    model.totalSizeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${model.downloadedWeightCount}/${model.weights.length} files',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Download progress or button
              Obx(() => _buildDownloadSection(context, controller, model)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
    BuildContext context,
    ModelManagerController controller,
    DownloadableModel model,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = controller.getModelProgress(model.id);
    final isDownloading = progress > 0 && progress < 1;

    // Use actual download status from controller
    if (isDownloading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: progress,
          color: colorScheme.primary,
        ),
      );
    }

    switch (model.downloadStatus) {
      case ModelDownloadStatus.completed:
        return Icon(Icons.check_circle, color: colorScheme.tertiary, size: 20);
      case ModelDownloadStatus.failed:
        return Icon(Icons.error, color: colorScheme.error, size: 20);
      case ModelDownloadStatus.paused:
        return Icon(Icons.pause_circle, color: colorScheme.secondary, size: 20);
      default:
        return Icon(
          Icons.download,
          color: colorScheme.onSurface.withAlpha(153),
          size: 20,
        );
    }
  }

  Widget _buildDownloadSection(
    BuildContext context,
    ModelManagerController controller,
    DownloadableModel model,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = controller.getModelProgress(model.id);
    final status = controller.getModelStatus(model.id);
    final isDownloading = progress > 0 && progress < 1;

    if (isDownloading) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(width: 8),
              // Cancel button
              IconButton(
                onPressed: () => controller.cancelDownload(model.id),
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: colorScheme.error,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                tooltip: 'Cancel Download',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (model.isFullyDownloaded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.tertiary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: colorScheme.onTertiaryContainer,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Downloaded',
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            controller.isComfyUIDirectoryValid && !controller.isDownloading
            ? () => controller.downloadModel(model)
            : null,
        icon: const Icon(Icons.download, size: 16),
        label: Text(
          controller.isComfyUIDirectoryValid ? 'Download' : 'Select Directory',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  void _showModelDetails(
    BuildContext context,
    ModelManagerController controller,
    DownloadableModel model,
  ) {
    showDialog(
      context: context,
      builder: (context) => ModelDetailDialog(
        model: model,
        controller: controller,
      ),
    );
  }
}

/// Dialog showing detailed model information
class ModelDetailDialog extends StatelessWidget {
  final DownloadableModel model;
  final ModelManagerController controller;

  const ModelDetailDialog({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              model.description,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),

            const SizedBox(height: 16),

            // Weight files
            Text(
              'Weight Files:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: model.weights.length,
                itemBuilder: (context, index) {
                  final weight = model.weights[index];
                  final colorScheme = Theme.of(context).colorScheme;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        weight.isDownloaded
                            ? Icons.check_circle
                            : Icons.download,
                        color: weight.isDownloaded
                            ? colorScheme.tertiary
                            : colorScheme.onSurface.withAlpha(153),
                      ),
                      title: Text(
                        weight.filename,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        '${weight.dir}/ • ${weight.fileSize != null ? _formatBytes(weight.fileSize!) : 'Unknown size'}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      trailing: weight.isDownloaded
                          ? Icon(Icons.done, color: colorScheme.tertiary)
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Download button and progress
            Obx(
              () {
                final progress = controller.getModelProgress(model.id);
                final status = controller.getModelStatus(model.id);
                final isDownloading = progress > 0 && progress < 1;

                if (isDownloading) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  controller.cancelDownload(model.id),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(153),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isComfyUIDirectoryValid &&
                            !controller.isDownloading
                        ? () {
                            Navigator.pop(context);
                            controller.downloadModel(model);
                          }
                        : null,
                    icon: const Icon(Icons.download),
                    label: Text(
                      model.isFullyDownloaded
                          ? 'Already Downloaded'
                          : controller.isComfyUIDirectoryValid
                          ? 'Download Model'
                          : 'Select ComfyUI Directory First',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
