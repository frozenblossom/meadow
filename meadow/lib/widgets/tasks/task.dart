import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

enum TaskType {
  serverGeneration,
  localComfyUIGeneration,
  videoAssembly,
  batchGeneration,
}

class TaskProgressDetail {
  final String? currentNode;
  final double? progressPercentage;
  final String? progressText;
  final int? currentStep;
  final int? totalSteps;
  final Uint8List? previewImage;
  final int? queuePosition;

  TaskProgressDetail({
    this.currentNode,
    this.progressPercentage,
    this.progressText,
    this.currentStep,
    this.totalSteps,
    this.previewImage,
    this.queuePosition,
  });

  TaskProgressDetail copyWith({
    String? currentNode,
    double? progressPercentage,
    String? progressText,
    int? currentStep,
    int? totalSteps,
    Uint8List? previewImage,
    int? queuePosition,
  }) {
    return TaskProgressDetail(
      currentNode: currentNode ?? this.currentNode,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      progressText: progressText ?? this.progressText,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      previewImage: previewImage ?? this.previewImage,
      queuePosition: queuePosition ?? this.queuePosition,
    );
  }

  String get displayText {
    if (progressText?.isNotEmpty == true) return progressText!;
    if (currentStep != null && totalSteps != null) {
      return 'Step $currentStep/$totalSteps';
    }
    if (progressPercentage != null) {
      return '${(progressPercentage! * 100).toStringAsFixed(1)}%';
    }
    if (queuePosition != null && queuePosition! > 0) {
      return 'Queue position: $queuePosition';
    }
    return '';
  }
}

class Task {
  final ComfyUIWorkflow workflow;
  final RxString _status = 'Pending'.obs;
  final RxString _progress = ''.obs;
  final RxString _error = ''.obs;
  final DateTime createdAt;
  final RxnString _completedAt = RxnString();
  final String description;
  final RxInt _retryCount = 0.obs;
  final int maxRetries;
  final Map<String, dynamic>? metadata;
  final TaskType taskType;
  final RxString _promptId = ''.obs;
  final Rx<TaskProgressDetail?> _progressDetail = Rx<TaskProgressDetail?>(null);

  Task({
    required this.workflow,
    String? status,
    String? progress,
    String? error,
    required this.description,
    this.maxRetries = 3,
    this.metadata,
    this.taskType = TaskType.serverGeneration,
    String? promptId,
  }) : createdAt = DateTime.now() {
    if (status != null) _status.value = status;
    if (progress != null) _progress.value = progress;
    if (error != null) _error.value = error;
    if (promptId != null) _promptId.value = promptId;
  }

  // Reactive getters
  String get status => _status.value;
  String get progress => _progress.value;
  String get error => _error.value;
  String? get completedAt => _completedAt.value;
  int get retryCount => _retryCount.value;
  String get promptId => _promptId.value;
  TaskProgressDetail? get progressDetail => _progressDetail.value;
  bool get isLocalGeneration => taskType == TaskType.localComfyUIGeneration;

  // Reactive streams for listening to changes
  RxString get statusStream => _status;
  RxString get progressStream => _progress;
  RxString get errorStream => _error;
  RxnString get completedAtStream => _completedAt;
  RxInt get retryCountStream => _retryCount;
  RxString get promptIdStream => _promptId;
  Rx<TaskProgressDetail?> get progressDetailStream => _progressDetail;

  // Status update methods
  void updateStatus(String newStatus) {
    _status.value = newStatus;
    if (newStatus == 'Completed' || newStatus == 'Failed') {
      _completedAt.value = DateTime.now().toIso8601String();
    }
  }

  void updateProgress(String newProgress) {
    _progress.value = newProgress;
  }

  void updatePromptId(String newPromptId) {
    _promptId.value = newPromptId;
  }

  void updateProgressDetail(TaskProgressDetail? detail) {
    _progressDetail.value = detail;
    // Also update the basic progress text for backward compatibility
    if (detail != null && detail.displayText.isNotEmpty) {
      updateProgress(detail.displayText);
    }
  }

  void updateProgressFromComfyUI({
    String? currentNode,
    double? progressPercentage,
    String? progressText,
    int? currentStep,
    int? totalSteps,
    Uint8List? previewImage,
    int? queuePosition,
  }) {
    final newDetail = (_progressDetail.value ?? TaskProgressDetail()).copyWith(
      currentNode: currentNode,
      progressPercentage: progressPercentage,
      progressText: progressText,
      currentStep: currentStep,
      totalSteps: totalSteps,
      previewImage: previewImage,
      queuePosition: queuePosition,
    );
    updateProgressDetail(newDetail);
  }

  void setError(String errorMessage) {
    _error.value = errorMessage;
    updateStatus('Failed');
  }

  void clearError() {
    _error.value = '';
  }

  // Retry methods
  void incrementRetryCount() {
    _retryCount.value++;
  }

  bool get canRetry => isFailed && _retryCount.value < maxRetries;

  bool get hasExceededMaxRetries => _retryCount.value >= maxRetries;

  void resetForRetry() {
    _error.value = '';
    _progress.value = '';
    _completedAt.value = null;
    _status.value = 'Pending';
    incrementRetryCount();
  }

  // Status check helpers
  bool get isPending => _status.value == 'Pending';
  bool get isRunning => _status.value == 'Running';
  bool get isCompleted => _status.value == 'Completed';
  bool get isFailed => _status.value == 'Failed';
  bool get isFinished => isCompleted || isFailed;

  // Duration calculation
  Duration get duration {
    if (completedAt != null) {
      return DateTime.parse(completedAt!).difference(createdAt);
    }
    return DateTime.now().difference(createdAt);
  }

  @override
  String toString() {
    return 'Task(status: $status, progress: $progress, created: $createdAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          workflow == other.workflow &&
          createdAt == other.createdAt;

  @override
  int get hashCode => workflow.hashCode ^ createdAt.hashCode;
}
