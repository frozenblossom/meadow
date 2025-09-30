import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> videoWorkflow({
  Uint8List? refImage,
  required String prompt,
  int? seed,
  int? width,
  int? height,
  int? durationSeconds,
  int? fps,
}) async {
  return WorkflowTemplateService.createVideoWorkflow(
    refImage: refImage,
    prompt: prompt,
    seed: seed,
    width: width,
    height: height,
    durationSeconds: durationSeconds,
    fps: fps,
  );
}
