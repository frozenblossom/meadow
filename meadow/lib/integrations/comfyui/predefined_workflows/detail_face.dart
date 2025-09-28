import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow detailFaceWorkflow({
  required String prompt,
  required Uint8List initialImage,
  String? modelName = 'dreamshaper_lightning.safetensors',
}) {
  return ComfyUIWorkflow(
    workflow: {
      "4": {
        "inputs": {"ckpt_name": modelName},
        "class_type": "CheckpointLoaderSimple",
        "_meta": {"title": "Load Checkpoint"},
      },
      "5": {
        "inputs": {
          "text": prompt,
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "Positive"},
      },
      "6": {
        "inputs": {
          "text":
              "lowres, normal quality, (monochrome), (grayscale), skin spots, acnes, skin blemishes, age spot, glans",
          "clip": ["4", 1],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "Negative"},
      },
      "7": {
        "inputs": {
          "images": ["51", 0],
        },
        "class_type": "PreviewImage",
        "_meta": {"title": "Enhanced"},
      },
      "16": {
        "inputs": {"model_name": "sam_vit_b_01ec64.pth", "device_mode": "AUTO"},
        "class_type": "SAMLoader",
        "_meta": {"title": "SAMLoader (Impact)"},
      },
      "51": {
        "inputs": {
          "guide_size": 360,
          "guide_size_for": true,
          "max_size": 768,
          "seed": 999333703368595,
          "steps": 8,
          "cfg": 2,
          "sampler_name": "euler_ancestral",
          "scheduler": "normal",
          "denoise": 0.5,
          "feather": 5,
          "noise_mask": true,
          "force_inpaint": false,
          "bbox_threshold": 0.5,
          "bbox_dilation": 15,
          "bbox_crop_factor": 3,
          "sam_detection_hint": "center-1",
          "sam_dilation": 0,
          "sam_threshold": 0.93,
          "sam_bbox_expansion": 0,
          "sam_mask_hint_threshold": 0.7,
          "sam_mask_hint_use_negative": "False",
          "drop_size": 10,
          "wildcard": "",
          "cycle": 2,
          "inpaint_model": false,
          "noise_mask_feather": 20,
          "tiled_encode": false,
          "tiled_decode": false,
          "image": ["62", 0],
          "model": ["4", 0],
          "clip": ["4", 1],
          "vae": ["4", 2],
          "positive": ["5", 0],
          "negative": ["6", 0],
          "bbox_detector": ["53", 0],
          "sam_model_opt": ["16", 0],
        },
        "class_type": "FaceDetailer",
        "_meta": {"title": "FaceDetailer"},
      },
      "53": {
        "inputs": {"model_name": "bbox/face_yolov8m.pt"},
        "class_type": "UltralyticsDetectorProvider",
        "_meta": {"title": "UltralyticsDetectorProvider"},
      },
      "62": {
        "inputs": {"image": imageBase64(initialImage)},
        "class_type": "ETN_LoadImageBase64",
        "_meta": {"title": "Load Image"},
      },
    },
  );
}
