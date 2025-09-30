import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> aceStepWorkflow({
  required String lyrics,
  String? genre,
  String? referenceAudioPath,
  required int audioLength,
  int? seed,
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'ace_step',
    {
      'lyrics': lyrics,
      'genre': genre,
      'audioLength': audioLength,
      'seed': seed ?? WorkflowTemplateService.generateSeed(),
    },
    description: "Generate music with DiffRhythm: ${lyrics.split('\n').first.substring(0, lyrics.split('\n').first.length.clamp(0, 50))}${lyrics.split('\n').first.length > 50 ? '...' : ''}",
    assetType: AssetType.audio,
  );
}
