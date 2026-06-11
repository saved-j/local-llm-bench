# Modality Detection

## Current Implementation (2026-06-11)

The bench's `detect_modality()` checks `config.json` for vision/audio/video support.

### Detection Logic:
```python
arch = cfg.get("architectures", [""])[0].lower()
vision = any(v in arch for v in ["vision", "gemma3", "gemma4", "llava", "qwen2_vl", "qwen2.5_vl", "internvl"])
audio = any(v in arch for v in ["whisper", "audio", "qwen2_audio"])
video = any(v in arch for v in ["video", "qwen2_vl"])
```

### Known Issues:
- gemma4-26b-heretic has `image_token_id: 258880` in config but NO `vision_config` key
- The architecture `Gemma4ForConditionalGeneration` IS detected as vision (contains "gemma4")
- Detection depends on architecture name, not on presence of vision_config

### ollama Model Detection (2026-06-11)
For ollama models (no config.json available), detect modality from model name:
```python
if "vision" in model_name.lower():
    vision = True
if "audio" in model_name.lower() or "whisper" in model_name.lower():
    audio = True
if "video" in model_name.lower():
    video = True
```
Example: `llama3.2-vision:11b-instruct-q4_K_M` → `text ✅ vision ✅ audio ❌ video ❌`

### Status display:
```
text ✅ vision ❌ audio ❌ video ❌
```
Only shows ✅ for detected modalities. Currently no actual vision/audio testing is implemented.
