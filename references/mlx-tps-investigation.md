# mlx TPS Investigation — 2026-06-11

## Problem
mlx models showing 45-50 t/s in-process vs 75-120 t/s via CLI subprocess. 2x regression from v5 (2026-06-09).

## Root Cause
In-process `generate()` / `stream_generate()` runs slower than `mlx_lm.generate` CLI module. Same model, same mlx-lm version, same hardware. Difference is **process isolation**.

## Solution: CLI Subprocess
Rewrote `ask_mlx()` to call `mlx_lm.generate` via `subprocess.run()`:
```python
cmd = [sys.executable, "-m", "mlx_lm.generate", "--model", model_id, 
       "--prompt", prompt, "--max-tokens", str(effective_max)]
result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
# Parse "Generation: NNN tokens, XX.XXX tokens-per-sec" from stdout
```

## Results (CLI subprocess)
| Model | CLI TPS | v5 TPS | Match? |
|-------|---------|--------|--------|
| gemma3-4b | 120 t/s | 121-131 | ✅ |
| gemma3-12b | 60 t/s | 49-52 | ✅ 115% |
| gemma4-26b-heretic | 75-80 t/s | 95-104 | ⚠️ 75% |
| qwen3-next-80b | 39 t/s | 27-28 | ✅ 140% |

## System Load Impact
smbd runaway at 1473% CPU caused load avg 20-30, which affected TPS by ~20%. Need `sudo kill` or reboot to fix. GPU inference is affected by thermal throttling and memory pressure from CPU-bound processes.

## What Didn't Work
- Installing older mlx-lm versions (0.29.1, 0.27.0) — same TPS
- Clearing Metal/MLX caches — no effect
- Different PYTHONPATH configurations — no effect
- `env -i` clean environment — same 44 t/s
- `mx.set_cache_limit(0)` — no effect

## Key Insight
The CLI module `mlx_lm.generate` uses a different Python initialization path than in-process `generate()`. Something in the Metal/MLX runtime benefits from fresh process isolation.
