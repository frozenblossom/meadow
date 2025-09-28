import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow ultimateUpscaleWorkflow({
  required Uint8List image,
  int scaleFactor = 4,
}) {
  return ComfyUIWorkflow(
    workflow: {
      "4": {
        "inputs": {"ckpt_name": "dreamshaper_lightning.safetensors"},
        "class_type": "CheckpointLoaderSimple",
        "_meta": {"title": "Load Checkpoint"},
      },
      "6": {
        "inputs": {
          "text": "best quality, high quality",
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Prompt)"},
      },
      "7": {
        "inputs": {
          "text": "text, watermark, blurry, bokeh, pixelated, depth of field",
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Prompt)"},
      },
      "11": {
        "inputs": {
          "upscale_by": scaleFactor,
          "seed": 279264743893715,
          "steps": 6,
          "cfg": 2,
          "sampler_name": "euler",
          "scheduler": "normal",
          "denoise": 0.2,
          "mode_type": "Linear",
          "tile_width": 1024,
          "tile_height": 1024,
          "mask_blur": 8,
          "tile_padding": 32,
          "seam_fix_mode": "Band Pass",
          "seam_fix_denoise": 1,
          "seam_fix_width": 64,
          "seam_fix_mask_blur": 8,
          "seam_fix_padding": 16,
          "force_uniform_tiles": true,
          "tiled_decode": false,
          "image": ["13", 0],
          "model": ["4", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "vae": ["4", 2],
          "upscale_model": ["14", 0],
        },
        "class_type": "UltimateSDUpscale",
        "_meta": {"title": "Ultimate SD Upscale"},
      },
      "12": {
        "inputs": {
          "images": ["11", 0],
        },
        "class_type": "PreviewImage",
        "_meta": {"title": "Preview Image"},
      },
      "13": {
        "inputs": {"image": imageBase64(image)},
        "class_type": "ETN_LoadImageBase64",
        "_meta": {"title": "Load Image"},
      },
      "14": {
        "inputs": {"model_name": "4x-UltraSharp.pth"},
        "class_type": "UpscaleModelLoader",
        "_meta": {"title": "Load Upscale Model"},
      },
    },
  );
}
