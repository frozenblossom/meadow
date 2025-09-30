import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';
import 'package:meadow/services/workflow_template_service.dart';

Future<ComfyUIWorkflow> ttsWorkflow({
  required String text,
  String? referenceAudioPath,
  String? referenceText,
}) async {
  return WorkflowTemplateService.createFromTemplate(
    'tts',
    {
      'text': text,
      'referenceAudioPath': referenceAudioPath ?? "",
      'referenceText': referenceText ?? "",
    },
    description: "Generate speech: ${text.substring(0, text.length.clamp(0, 50))}${text.length > 50 ? '...' : ''}",
    assetType: AssetType.audio,
  );
}
