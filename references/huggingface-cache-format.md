# HuggingFace Cache Format

## Structure

```
~/.cache/huggingface/hub/models--{org}--{name}/
├── blobs/          # Actual model files (large, GB-sized)
├── refs/           # Git refs
└── snapshots/      # Symlinks to blobs (tiny, 8KB each)
    └── {commit_hash}/
        ├── config.json
        ├── tokenizer.json
        └── ... (symlinks to ../../blobs/{hash})
```

## Key Gotcha

`du -sh snapshots/` shows ~8KB per model (just symlinks).
Must walk the ENTIRE model directory to get real size:
```python
for root, dirs, files in os.walk(os.path.join(hf_cache, entry)):
    total += sum(os.path.getsize(os.path.join(root, f)) for f in files)
```

## Model Format Compatibility

| Format | mlx-lm | ollama | vLLM |
|--------|--------|--------|------|
| MLX (mlx-community/*) | ✅ | ❌ | ❌ |
| GGUF (unsloth/*) | ❌ | ✅ | ❌ |
| NVFP4 (NVIDIA compressed-tensors) | ❌ | ❌ | ✅ |
| NVFP4 (third-party mlx conversion) | ✅ | ❌ | ❌ |
| SafeTensors (standard HF) | ✅ | ❌ | ✅ |

**NVFP4 nuance:** Not all NVFP4 is equal. NVIDIA's `compressed-tensors` format (from `nvidia/`, `GadflyII/`) only works with vLLM. But third-party conversions to mlx-nvfp4 format (e.g. `RepublicOfKorokke/GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4`) ARE mlx-compatible — they use `.safetensors` with nvfp4 quantization that mlx-lm can load.

**Rule:** Check `config.json` → `quantization_config.mode` = `nvfp4` AND model has `.safetensors` files → likely mlx-compatible. If model has `.gguf` or `compressed-tensors` → not mlx-compatible.

## Auto-Detection Filter

Skip patterns (non-LLM): whisper, flux, ltx, sdxl, vae, clip, ip-adapter,
llmlingua, omnivoice, stable-diffusion, bonsai, tts, audio, vision, encoder,
decoder, tokenizer, embed, rerank, juggernaut, adapter, lora, assistant

Skip models < 1GB (MTP headers, incomplete downloads).

**Provider-specific:** Only `mtplx` is filtered (tested via mtplx provider only). `nvfp4` is NOT filtered — third-party mlx-nvfp4 conversions work fine.

## Known Downloaded Models (2026-06-09)

| Model | Size | Provider | Format |
|-------|------|----------|--------|
| mlx-community/Qwen3.6-35B-A3B-OptiQ-4bit | 53G | mlx | MLX |
| mlx-community/Qwen3-Next-80B-A3B-Instruct-4bit | 45G | mlx | MLX |
| dawncr0w/Qwen3.6-35B-Uncensored-5bpw-MLX | 18G | mlx | MLX |
| Youssofal/Qwen3.6-27B-MTPLX-Optimized-Speed | 15G | mtplx | MTPLX |
| culturerevolt/gemma-4-26B-heretic-mlx-4Bit | 13G | mlx | MLX |
| RepublicOfKorokke/GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4 | 12G | mlx | MLX (nvfp4 quant) |
| mlx-community/gemma-3-12b-it-4bit | 7.5G | mlx | MLX |
| mlx-community/gemma-3-4b-it-4bit | 4.9G | mlx | MLX |

## Deleted NVFP4 Models (NVIDIA compressed-tensors, incompatible)

These were deleted from cache (48.9GB freed):
- nvidia/Qwen3-Next-80B-A3B-Instruct-NVFP4 (50G) — mlx version exists
- GadflyII/GLM-4.7-Flash-NVFP4 (19G) — no mlx/gguf version
- alphakek/GLM-4.7-Flash-heretic-NVFP4 (15G) — no mlx/gguf version
