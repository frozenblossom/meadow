import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow ttsWorkflow({
  required String text,
  String? referenceAudioPath,
  String? referenceText,
}) {
  return ComfyUIWorkflow(
    workflow: {
      "1": {
        "inputs": {
          "text": text,
          "reference_audio": referenceAudioPath ?? "",
          "reference_text": referenceText ?? "",
        },
        "class_type": "F5TTSNode",
        "_meta": {"title": "F5-TTS Speech Generation"},
      },
      "2": {
        "inputs": {
          "filename_prefix": "speech/f5tts",
          "quality": "128k",
          "audioUI": "",
          "audio": ["1", 0],
        },
        "class_type": "SaveAudioMP3",
        "_meta": {"title": "Save Speech (MP3)"},
      },
    },
    description:
        "Generate speech: ${text.substring(0, text.length.clamp(0, 50))}${text.length > 50 ? '...' : ''}",
    assetType: AssetType.audio,
  );
}
