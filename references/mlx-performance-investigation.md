# mlx Performance Investigation (2026-06-11)

## Problem
mlx models running 1.6-2x slower than v5 benchmark results.

## Root Cause: Process Isolation
- **In-process** `generate()` / `stream_generate()`: 43-48 t/s for gemma4-26b
- **CLI subprocess** `mlx_lm.generate`: 73-80 t/s for same model
- **v5 benchmark**: 95-104 t/s (but used max_tokens=256 bug, real sustained was lower)

## Why CLI is Faster
CLI runs in a clean Python process with no memory fragmentation from previous model loads.
In-process calls share the same Metal runtime state, causing contention.

## Solution: Use CLI subprocess in ask_mlx()
```python
result = subprocess.run([
    "/opt/homebrew/bin/python3.14", "-m", "mlx_lm.generate",
    "--model", model_id,
    "--prompt", prompt,
    "--max-tokens", str(max_tok)
], capture_output=True, text=True, timeout=900,
env={"PYTHONPATH": BREW_MLX_PATH})
```

Parse output for generation_tps, prompt_tps, generation_tokens, prompt_tokens, peak_memory.

## Update: mlx 0.31.2 + macOS 26.5.1 (2026-06-11)
mlx-lm version doesn't matter (tested 0.27, 0.29.1, 0.31.3 — all give same TPS).
The gap between v5 (95-104 t/s) and current (75-80 t/s) may be due to:
- macOS 26.5.1 Metal runtime changes
- smbd runaway consuming CPU/thermal budget
- System uptime (4+ days without reboot)

## Lock File Issue
HuggingFace lock files remain even after deleting model folders.
Fix: `rm -rf ~/.cache/huggingface/hub/.locks/models--*/` before retrying download.
Mirror downloads may fail with SSL errors — use direct HuggingFace instead.

## QAT Models (2026-06-11)
Downloaded via hf download:
- gemma-4-26B-A4B-it-qat-4bit (14.5GB) ✅ — **117-123 t/s** (exceeds v5!)
- gemma-4-26B-A4B-it-qat-6bit (20.3GB) 🔄 downloading
- gemma-4-31B-it-qat-4bit (26.8GB) 🔄 downloading

### QAT Performance Results (2026-06-11)
```
gemma-4-26B-A4B-it-qat-4bit (CLI subprocess, --fast mode):
  Quick Start:  117.8 t/s
  Trap:         123.0 t/s
  Expertise:    122.0 t/s
  Data Process: 121.4 t/s
  Calculations: 120.7 t/s
  Code:         121.2 t/s
  UI:           121.0 t/s
```
QAT 4bit model is **+20% faster** than v5's gemma4-26b-heretic (95-104 t/s).
QAT = Quantization-Aware Training — produces better quality at same bit-width.


## Other Performance Factors
- **smbd runaway**: Can eat 1400%+ CPU, causes thermal throttling
  - Check: `ps aux | grep smbd`
  - Fix: `sudo kill -9 <pid>` (needs sudo)
  - User says mlx is GPU-bound so shouldn't matter, but 20% gap suggests otherwise
- **Load averages > 20**: System under stress, affects all processes
