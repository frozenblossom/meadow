import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> simpleCheckpointWorkflow({
  int? seed,
  int? steps,
  double? cfg,
  double? denoise,
  String model = 'dreamshaper_lightning.safetensors',
  required String prompt,
  String negativePrompt = 'blurry, bokeh, depth of field',
  int width = 1024,
  int height = 1024,
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'simple_checkpoint',
    {
      'seed': seed ?? WorkflowTemplateService.generateSeed(),
      'steps': steps ?? 4,
      'cfg': cfg ?? 2,
      'denoise': denoise ?? 1,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'width': width,
      'height': height,
    },
  );
}
