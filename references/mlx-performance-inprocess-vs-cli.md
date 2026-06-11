# mlx Performance: In-Process vs CLI Subprocess

## Problem (discovered 2026-06-10)
mlx models run 1.6-2x slower when called in-process vs CLI subprocess.

## Measurements (gemma4-26b-heretic, ctok=256)
| Method | TPS | Notes |
|--------|-----|-------|
| In-process generate() | 45-48 | Same mlx-lm, same Python |
| CLI subprocess | 77-80 | Fresh process per call |
| v5 benchmark | 95-104 | Was with max_tokens=256 bug |

## Root Cause
Unknown. Tested:
- mlx-lm versions: 0.27.0, 0.29.1, 0.31.3 — all give same in-process TPS
- Environment: clean env gives same 44 t/s
- model_config, trust_remote_code — no effect
- CLI and in-process use identical `generate()` function

## Evidence
- gemma3-4b: CLI 120 t/s ≈ v5 131 t/s ✅
- gemma4-26b: CLI 80 t/s ≈ v5 104 t/s (80%) ⚠️
- qwen3-next-80b: CLI 39 t/s > v5 28 t/s ✅

## v5 Was Inflated
v5 results (2026-06-09) showed 95-131 t/s but ALL tests had ctok=256 = mlx default max_tokens bug.
The script had `max_tokens=256` hardcoded (not the intended 100000+). This gave inflated TPS because:
- 256 tokens = small KV cache = fast generation
- Real tests generate 1000-13000+ tokens = larger cache = slower

## Fix
Rewrite `ask_mlx()` to use subprocess CLI call instead of in-process `stream_generate()`.
Expected: 80-120 t/s for most models (matching v5 for small models, 80% for large).

## Implications for Bench
- Current bench uses in-process → shows 45-50 t/s for mlx
- CLI subprocess would show 77-120 t/s
- Need to handle stream_write for real-time monitoring via subprocess
