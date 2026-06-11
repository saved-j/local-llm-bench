# Modality Detection Bug (2026-06-11)

## Problem
Gemma4 models showing `vision ❌` despite having vision capabilities in config.json.

## Root Cause
`detect_modality()` only checked root `config.json`:
```python
model_dir = Path("/Users/saved/.cache/huggingface/hub") / f"models--{hf_model.replace('/', '--')}"
cfg_path = model_dir / "config.json"
```

But HF cache stores config in `snapshots/<hash>/config.json`, not root.

## Fix
```python
if not cfg_path.exists():
    # Try snapshots directory (common HF cache structure)
    snap_dir = model_dir / "snapshots"
    if snap_dir.exists():
        for snap in snap_dir.iterdir():
            snap_cfg = snap / "config.json"
            if snap_cfg.exists():
                cfg_path = snap_cfg
                break
```

## Verification
```python
# Gemma4 config has:
{
  "architectures": ["Gemma4ForConditionalGeneration"],
  "model_type": "gemma4",
  "image_token_id": 256000,
  "vision_soft_tokens_per_image": 256
}
```

`Gemma4ForConditionalGeneration` contains "gemma4" → vision check passes:
```python
vision = any(v in arch.lower() for v in ["vision", "gemma3", "gemma4", "llava", ...])
```

## Impact
- Gemma4 models now correctly show `vision ✅`
- Other models with HF cache structure also benefit
- No more false `vision ❌` for vision-capable models
