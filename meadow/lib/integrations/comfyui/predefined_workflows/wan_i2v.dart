import 'dart:typed_data';

import 'package:meadow/integrations/comfyui/workflow.dart';

ComfyUIWorkflow videoWorkflow({
  Uint8List? refImage,
  required String prompt,
  int? seed,
  int? width,
  int? height,
  int? durationSeconds,
  int? fps,
}) {
  // Calculate frames from duration and fps
  final frameCount = (durationSeconds ?? 5) * (fps ?? 24);

  var workflow = ComfyUIWorkflow(
    workflow: {
      "3": {
        "inputs": {
          "seed": seed ?? 513174557100788,
          "steps": 20,
          "cfg": 5,
          "sampler_name": "uni_pc",
          "scheduler": "simple",
          "denoise": 1,
          "model": ["48", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "latent_image": ["55", 0],
        },
        "class_type": "KSampler",
        "_meta": {"title": "KSampler"},
      },
      "6": {
        "inputs": {
          "text": prompt,
          "clip": ["38", 0],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Positive Prompt)"},
      },
      "7": {
        "inputs": {
          "text":
              "色调艳丽，过曝，静态，细节模糊不清，字幕，风格，作品，画作，画面，静止，整体发灰，最差质量，低质量，JPEG压缩残留，丑陋的，残缺的，多余的手指，画得不好的手部，画得不好的脸部，畸形的，毁容的，形态畸形的肢体，手指融合，静止不动的画面，杂乱的背景，三条腿，背景人很多，倒着走, anime",
          "clip": ["38", 0],
        },
        "class_type": "CLIPTextEncode",
        "_meta": {"title": "CLIP Text Encode (Negative Prompt)"},
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["39", 0],
        },
        "class_type": "VAEDecode",
        "_meta": {"title": "VAE Decode"},
      },
      "37": {
        "inputs": {
          "unet_name": "wan2.2_ti2v_5B_fp16.safetensors",
          "weight_dtype": "default",
        },
        "class_type": "UNETLoader",
        "_meta": {"title": "Load Diffusion Model"},
      },
      "38": {
        "inputs": {
          "clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors",
          "type": "wan",
          "device": "default",
        },
        "class_type": "CLIPLoader",
        "_meta": {"title": "Load CLIP"},
      },
      "39": {
        "inputs": {"vae_name": "wan2.2_vae.safetensors"},
        "class_type": "VAELoader",
        "_meta": {"title": "Load VAE"},
      },
      "48": {
        "inputs": {
          "shift": 8,
          "model": ["37", 0],
        },
        "class_type": "ModelSamplingSD3",
        "_meta": {"title": "ModelSamplingSD3"},
      },
      "55": {
        "inputs": {
          "width": width ?? 1280,
          "height": height ?? 704,
          "length": frameCount,
          "batch_size": 1,
          "vae": ["39", 0],
        },
        "class_type": "Wan22ImageToVideoLatent",
        "_meta": {"title": "Wan22ImageToVideoLatent"},
      },
      "62": {
        "inputs": {
          "filename_prefix": "video/ComfyUI",
          "format": "mp4",
          "codec": "h264",
          "video": ["63", 0],
        },
        "class_type": "SaveVideo",
        "_meta": {"title": "Save Video"},
      },
      "63": {
        "inputs": {
          "fps": 24,
          "images": ["8", 0],
        },
        "class_type": "CreateVideo",
        "_meta": {"title": "Create Video"},
      },
    },
  );

  if (refImage != null && refImage.isNotEmpty) {
    workflow.workflow["57"] = {
      "inputs": {"image": imageBase64(refImage)},
      "class_type": "ETN_LoadImageBase64",
      "_meta": {"title": "Load Image"},
    };
    workflow.workflow["55"]!["inputs"]!["start_image"] = ["57", 0];
  }

  return workflow;
}
