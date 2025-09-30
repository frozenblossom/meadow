import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> ultimateUpscaleWorkflow({
  required Uint8List image,
  int scaleFactor = 4,
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'upscale',
    {
      'image': image,
      'scaleFactor': scaleFactor,
    },
  );
}
