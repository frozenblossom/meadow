import 'dart:math';

import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow simpleCheckpointWorkflow({
  int? seed,
  int? steps,
  double? cfg,
  double? denoise,
  String model = 'dreamshaper_lightning.safetensors',
  required String prompt,
  String negativePrompt = 'blurry, bokeh, depth of field',
  int width = 1024,
  int height = 1024,
}) {
  return ComfyUIWorkflow(
    workflow: {
      "3": {
        "inputs": {
          "seed": seed ?? Random().nextInt(1 << 32),
          "steps": steps ?? 4,
          "cfg": cfg ?? 2,
          "sampler_name": "dpmpp_sde",
          "scheduler": "karras",
          "denoise": denoise ?? 1,
          "model": ["4", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "latent_image": ["5", 0],
        },
        "class_type": "KSampler",
        "_meta": {"title": "KSampler"},
      },
      "4": {
        "inputs": {
          "ckpt_name": model,
        },
        "class_type": "CheckpointLoaderSimple",
        "_meta": {"title": "Load Checkpoint"},
      },
      "5": {
        "inputs": {"width": width, "height": height, "batch_size": 1},
        "class_type": "EmptyLatentImage",
        "_meta": {"title": "Empty Latent Image"},
      },
      "6": {
        "inputs": {
          "text": prompt,
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Prompt)"},
      },
      "7": {
        "inputs": {
          "text":
              "$negativePrompt, text, watermark, bokeh, blurry, depth of field",
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Prompt)"},
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2],
        },
        "class_type": "VAEDecode",
        "_meta": {"title": "VAE Decode"},
      },
      "10": {
        "inputs": {
          "images": ["8", 0],
        },
        "class_type": "PreviewImage",
        "_meta": {"title": "Preview Image"},
      },
    },
  );
}
