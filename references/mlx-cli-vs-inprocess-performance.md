# mlx Performance: CLI vs In-Process (2026-06-11)

## Problem
mlx `generate()` and `stream_generate()` called in-process give 45-50 t/s.
CLI `python3-mlx -m mlx_lm.generate` subprocess gives 75-80 t/s (gemma4-26B) and 120+ t/s (gemma3-4b).
Ratio: 1.7-2x faster via CLI subprocess.

## Root Cause
Unknown mlx/Metal runtime difference between CLI module execution and in-process Python.
- Same mlx-lm version (0.31.3_1), same mlx core (0.31.2), same hardware (M4 Max 64GB)
- Same model, same prompt, same max_tokens — different TPS
- NOT caused by: environment variables, model loading, warmup, Python version, mlx-lm version
- System load (smbd at 1473% CPU) adds ~20% overhead on top

## Fix: ask_mlx uses subprocess CLI
```python
cmd = [sys.executable, "-m", "mlx_lm.generate", "--model", model_path, "--prompt", prompt, "--max-tokens", str(max_tok)]
result = subprocess.run(cmd, capture_output=True, text=True, timeout=1200, env=env)
# Parse: "Generation: 256 tokens, 80.150 tokens-per-sec"
# Parse: "Prompt: 25 tokens, 133.817 tokens-per-sec"
# Parse: "Peak memory: 14.269 GB"
```

TPS taken from CLI's `generation_tps` (not wall clock which includes model loading ~4s).
Subprocess overhead: ~0.5s per call. Offset by 2x faster generation.

## Verified Results
| Model | In-process | CLI subprocess | v5 reference |
|-------|-----------|---------------|-------------|
| gemma3-4b | 44 t/s | 120 t/s | 121-131 t/s |
| gemma4-26b | 45 t/s | 75-80 t/s | 95-104 t/s |
| qwen3-next-80b | ~30 t/s | 37-39 t/s | 27-28 t/s |

gemma4 gap (80 vs 104) likely due to macOS 26.5.1 system changes.

## Pitfall: Never kill download processes
The user downloads models via curl/hf download. Killing these loses progress and enrages the user.
Before running `kill` or `pkill`, check that targets are NOT curl/hf download processes.
