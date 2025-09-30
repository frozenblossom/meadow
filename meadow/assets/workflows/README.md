# ComfyUI Workflow Templates

This directory contains JSON template files for Comf## Usage in Code

All workflow functions now use the template system and are async:

```dart
// All workflows are now template-based and customizable
final workflow = await simpleCheckpointWorkflow(prompt: "a cat");
```ws that can be modified by users without needing to recompile the application.

## How to Use

1. **Template Files**: Each `.json` file in this directory represents a ComfyUI workflow template.
2. **Parameter Placeholders**: Parameters are represented using the format `$parameterName$` (e.g., `$prompt$`, `$seed$`, `$width$`).
3. **Modification**: You can edit these JSON files to customize the workflows according to your needs.

## Available Templates

### simple_checkpoint.json
Basic image generation workflow using checkpoints.

**Parameters:**
- `$seed$` - Random seed for generation
- `$steps$` - Number of sampling steps
- `$cfg$` - Classifier-free guidance scale
- `$denoise$` - Denoising strength
- `$model$` - Checkpoint model name
- `$prompt$` - Positive prompt
- `$negativePrompt$` - Negative prompt  
- `$width$` - Image width
- `$height$` - Image height

### ace_step.json
Audio generation workflow using ACE Step model.

**Parameters:**
- `$lyrics$` - Lyrics for the audio
- `$genre$` - Music genre
- `$audioLength$` - Duration in seconds
- `$seed$` - Random seed for generation

### tts.json
Text-to-speech workflow using F5-TTS.

**Parameters:**
- `$text$` - Text to convert to speech
- `$referenceAudioPath$` - Reference audio file path
- `$referenceText$` - Reference text

### detail_face.json
Face enhancement workflow for improving facial details.

**Parameters:**
- `$prompt$` - Enhancement prompt
- `$initialImage$` - Base64 encoded input image
- `$modelName$` - Model name to use

### swap_face.json
Face swapping workflow using ReActor.

**Parameters:**
- `$image$` - Base64 encoded target image
- `$face$` - Base64 encoded source face image

### upscale.json
Image upscaling workflow using Ultimate SD Upscale.

**Parameters:**
- `$image$` - Base64 encoded input image
- `$scaleFactor$` - Upscaling factor (e.g., 4)

### wan_i2v.json
Video generation workflow for image-to-video conversion.

**Parameters:**
- `$prompt$` - Video generation prompt
- `$seed$` - Random seed for generation
- `$width$` - Video width
- `$height$` - Video height
- `$frameCount$` - Number of frames
- `$refImage$` - Base64 encoded reference image (optional)
- `$refImageNode$` - Reference image node connection (conditional)

## Parameter Types

- **String values**: Should be enclosed in quotes when replaced
- **Numeric values**: Can be replaced directly without quotes
- **Arrays**: Should be valid JSON arrays like `[4, 0]`
- **Base64 images**: Special handling for `Uint8List` parameters

## Usage in Code

The application provides both the original hardcoded workflows and new template-based versions:

```dart
// Original (backward compatible)
final workflow = simpleCheckpointWorkflow(prompt: "a beautiful landscape");

// Template-based (customizable)
final workflow = await simpleCheckpointWorkflowFromTemplate(prompt: "a beautiful landscape");
```

## Important Notes

1. **Backup**: Always backup the original template files before making changes.
2. **Syntax**: Ensure the JSON syntax remains valid after modifications.
3. **Parameters**: Parameter placeholders must match exactly what the code expects.
4. **Testing**: Test your modified workflows in ComfyUI first before using them in the application.

## Example Modification

To change the default sampler in `simple_checkpoint.json`:

```json
{
  "3": {
    "inputs": {
      "sampler_name": "euler_ancestral",  // Changed from "dpmpp_sde"
      // ... other parameters
    }
  }
}
```