import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> swapfaceWorkflow({
  required Uint8List image,
  required Uint8List face,
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'swap_face',
    {
      'image': image,
      'face': face,
    },
  );
}
