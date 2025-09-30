import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

class WorkflowTemplateService {
  static final Map<String, String> _templateCache = {};

  /// Load a workflow template from assets
  static Future<String> _loadTemplate(String templateName) async {
    if (_templateCache.containsKey(templateName)) {
      return _templateCache[templateName]!;
    }

    try {
      final String content = await rootBundle.loadString(
        'assets/workflows/$templateName.json',
      );
      _templateCache[templateName] = content;
      return content;
    } catch (e) {
      throw Exception(
        'Failed to load workflow template: $templateName. Error: $e',
      );
    }
  }

  /// Replace parameters in template with actual values
  static String _replaceParameters(
    String template,
    Map<String, dynamic> parameters,
  ) {
    String result = template;

    for (final entry in parameters.entries) {
      final placeholder = '\$${entry.key}\$';
      final value = entry.value;

      String replacementValue;
      if (value == null) {
        // Handle null values - you might want to remove the parameter or use a default
        replacementValue = 'null';
      } else if (value is String) {
        replacementValue = value.replaceAll('"', '\\"');
      } else if (value is Uint8List) {
        replacementValue = '"${imageBase64(value)}"';
      } else if (value is List || value is Map) {
        replacementValue = jsonEncode(value);
      } else {
        replacementValue = value.toString();
      }

      result = result.replaceAll(placeholder, replacementValue);
    }

    return result;
  }

  /// Create a workflow from a template
  static Future<ComfyUIWorkflow> createFromTemplate(
    String templateName,
    Map<String, dynamic> parameters, {
    String? description,
    AssetType assetType = AssetType.image,
  }) async {
    final template = await _loadTemplate(templateName);
    final processedTemplate = _replaceParameters(template, parameters);

    try {
      final Map<String, dynamic> workflowData = jsonDecode(processedTemplate);
      return ComfyUIWorkflow(
        workflow: workflowData,
        description: description,
        assetType: assetType,
      );
    } catch (e) {
      throw Exception('Failed to parse workflow template $templateName: $e');
    }
  }

  /// Generate a random seed if not provided
  static int generateSeed() => Random().nextInt(1 << 32);

  /// Handle special processing for complex workflows (like video with conditional nodes)
  static Future<ComfyUIWorkflow> createVideoWorkflow({
    Uint8List? refImage,
    required String prompt,
    int? seed,
    int? width,
    int? height,
    int? durationSeconds,
    int? fps,
  }) async {
    final frameCount = (durationSeconds ?? 5) * (fps ?? 24);

    final parameters = <String, dynamic>{
      'seed': seed ?? generateSeed(),
      'prompt': prompt,
      'width': width ?? 1280,
      'height': height ?? 704,
      'frameCount': frameCount,
    };

    // Handle conditional reference image
    if (refImage != null && refImage.isNotEmpty) {
      parameters['refImage'] = refImage;
      parameters['refImageNode'] = ['57', 0];
    } else {
      parameters['refImage'] = null;
      parameters['refImageNode'] = null;
    }

    final template = await _loadTemplate('wan_i2v');
    String processedTemplate = _replaceParameters(template, parameters);

    // Post-process to handle conditional nodes
    final Map<String, dynamic> workflowData = jsonDecode(processedTemplate);

    // Remove reference image node if not needed
    if (refImage == null || refImage.isEmpty) {
      workflowData.remove('57');
      // Remove start_image parameter from node 55
      (workflowData['55']!['inputs'] as Map<String, dynamic>).remove(
        'start_image',
      );
    }

    return ComfyUIWorkflow(
      workflow: workflowData,
      assetType: AssetType.video,
    );
  }
}
