import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/app_settings_controller.dart';
import 'package:meadow/enums/asset_type.dart';

class ComfyUIWorkflow {
  final Map<String, dynamic> workflow;
  final String? description;
  final AssetType assetType;

  ComfyUIWorkflow({
    required this.workflow,
    this.description,
    this.assetType = AssetType.image,
  });

  Future<String> invoke() async {
    // Get the ComfyUI URL from settings
    final settingsController = Get.find<AppSettingsController>();
    final baseUrl = settingsController.comfyuiUrl.value;

    // Create a task ID
    var dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 300),
      ),
    );

    final response = await dio.post(
      '/prompt',
      data: {"prompt": workflow},
    );
    final promptId = response.data["prompt_id"];
    if (promptId == null) {
      throw Exception("No prompt_id returned from ComfyUI.");
    }

    String? filename;
    String? subfolder;
    String? type;
    const pollInterval = Duration(seconds: 1);
    const timeout = Duration(seconds: 300);
    final start = DateTime.now();

    while (true) {
      final historyResp = await dio.get('/history/$promptId');
      final outputs = historyResp.data[promptId]?['outputs'];

      if (outputs != null && outputs.isNotEmpty) {
        // Get the first output node
        final firstOutputNodeKey = outputs.keys.first;
        final firstOutputNode = outputs[firstOutputNodeKey];

        if (firstOutputNode != null) {
          // Look for any media type (images, audio, video, etc.)
          // Take the first available media type and first item within it
          for (final mediaTypeKey in firstOutputNode.keys) {
            final mediaArray = firstOutputNode[mediaTypeKey] as List?;
            if (mediaArray != null && mediaArray.isNotEmpty) {
              final firstItem = mediaArray[0];
              if (firstItem is Map<String, dynamic>) {
                filename = firstItem["filename"] as String?;
                subfolder = firstItem["subfolder"] as String? ?? "";
                type = firstItem["type"] as String?;

                if (filename != null) {
                  break; // Found valid output, exit the loop
                }
              }
            }
          }

          if (filename != null) {
            break; // Found valid output, exit the polling loop
          }
        }
      }
      if (DateTime.now().difference(start) > timeout) {
        throw Exception("Timed out waiting for generation.");
      }
      await Future.delayed(pollInterval);
    }

    // Use the baseUrl from settings instead of hardcoded value
    final uri = Uri.parse(baseUrl);
    final url = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: '/api/view',
      queryParameters: {
        'filename': filename,
        'subfolder': subfolder,
        'type': type,
      },
    ).toString();

    return url;
  }
}

String imageBase64(Uint8List bytes) {
  return base64Encode(bytes);
}
