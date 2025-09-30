import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> detailFaceWorkflow({
  required String prompt,
  required Uint8List initialImage,
  String? modelName = 'dreamshaper_lightning.safetensors',
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'detail_face',
    {
      'prompt': prompt,
      'initialImage': initialImage,
      'modelName': modelName,
    },
  );
}
