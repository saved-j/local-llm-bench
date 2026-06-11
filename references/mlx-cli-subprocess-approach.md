# mlx CLI Subprocess Approach (2026-06-11)

## Problem
In-process `generate()` gives 45-50 t/s for gemma4-26b. CLI gives 75-80 t/s.
v5 showed 95-104 t/s but used max_tokens=256 bug.

## Root Cause
mlx Metal runtime: fresh CLI process > in-process call for throughput.

## Solution
`ask_mlx()` uses `subprocess.run()` calling `mlx_lm.generate` CLI.
Parse stdout for `Generation: N tokens, X t/s`.

## Results
- gemma3-4b: 120 t/s ✅
- gemma4-26b: 75-80 t/s
- Qwen3-Next-80B: 37-39 t/s ✅
- smbd runaway (1473% CPU) = additional 20% loss, needs sudo/reboot

## mtplx
- SSE streaming: no `usage` in chunks — use blocking POST
- `mtplx_stats` at TOP LEVEL, not inside `usage`
