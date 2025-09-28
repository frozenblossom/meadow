import 'dart:math';

import 'package:meadow/enums/asset_type.dart';
import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow aceStepWorkflow({
  required String lyrics,
  String? genre,
  String? referenceAudioPath,
  required int audioLength,
  int? seed,
}) {
  return ComfyUIWorkflow(
    workflow: {
      "14": {
        "inputs": {
          "tags": genre,
          "lyrics": lyrics,
          "lyrics_strength": 0.99,
          "clip": ["40", 1],
        },
        "class_type": "TextEncodeAceStepAudio",
        "_meta": {"title": "TextEncodeAceStepAudio"},
      },
      "17": {
        "inputs": {"seconds": audioLength, "batch_size": 1},
        "class_type": "EmptyAceStepLatentAudio",
        "_meta": {"title": "EmptyAceStepLatentAudio"},
      },
      "18": {
        "inputs": {
          "samples": ["52", 0],
          "vae": ["40", 2],
        },
        "class_type": "VAEDecodeAudio",
        "_meta": {"title": "VAEDecodeAudio"},
      },
      "40": {
        "inputs": {"ckpt_name": "ace_step_v1_3.5b.safetensors"},
        "class_type": "CheckpointLoaderSimple",
        "_meta": {"title": "Load Checkpoint"},
      },
      "44": {
        "inputs": {
          "conditioning": ["14", 0],
        },
        "class_type": "ConditioningZeroOut",
        "_meta": {"title": "ConditioningZeroOut"},
      },
      "49": {
        "inputs": {
          "model": ["51", 0],
          "operation": ["50", 0],
        },
        "class_type": "LatentApplyOperationCFG",
        "_meta": {"title": "LatentApplyOperationCFG"},
      },
      "50": {
        "inputs": {"multiplier": 1.0},
        "class_type": "LatentOperationTonemapReinhard",
        "_meta": {"title": "LatentOperationTonemapReinhard"},
      },
      "51": {
        "inputs": {
          "shift": 5.0,
          "model": ["40", 0],
        },
        "class_type": "ModelSamplingSD3",
        "_meta": {"title": "ModelSamplingSD3"},
      },
      "52": {
        "inputs": {
          "seed": seed ?? Random().nextInt(1 << 32),
          "steps": 50,
          "cfg": 5,
          "sampler_name": "euler",
          "scheduler": "simple",
          "denoise": 1,
          "model": ["49", 0],
          "positive": ["14", 0],
          "negative": ["44", 0],
          "latent_image": ["17", 0],
        },
        "class_type": "KSampler",
        "_meta": {"title": "KSampler"},
      },
      "59": {
        "inputs": {
          "filename_prefix": "audio/ComfyUI",
          "quality": "V0",
          "audioUI": "",
          "audio": ["18", 0],
        },
        "class_type": "SaveAudioMP3",
        "_meta": {"title": "Save Audio (MP3)"},
      },
    },
    description:
        "Generate music with DiffRhythm: ${lyrics.split('\n').first.substring(0, lyrics.split('\n').first.length.clamp(0, 50))}${lyrics.split('\n').first.length > 50 ? '...' : ''}",
    assetType: AssetType.audio,
  );
}
