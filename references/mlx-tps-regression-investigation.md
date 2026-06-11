# mlx TPS Regression Investigation (2026-06-10)

## Problem
mlx models show ~50 t/s end-to-end while v5 results (2026-06-09) showed 104 t/s for same model (gemma4-26b-heretic, ctok=256).

## Root Cause Analysis
1. **v5 used max_tokens=256** (mlx default) — fast because small batch
2. **Current uses max_tokens=131072** — slower due to KV cache growth
3. **But even with max_tokens=256**, current shows 48-50 t/s vs v5's 104 t/s

## Key Findings
- `mlx_lm.benchmark` shows 75-80 t/s (generation-only, excludes TTFT)
- `stream_generate` in bench script shows 48-50 t/s (end-to-end, includes TTFT)
- The 2x difference between v5 and current is NOT just measurement — real regression

## Possible Causes
1. **mlx 0.31.2 regression** — may have introduced performance degradation
2. **macOS update** — thermal/power management changes
3. **Background processes** — other GPU users (model downloads via curl)
4. **Model download I/O** — heavy disk/network during generation

## Diagnostic Steps
1. Check for background processes: `ps aux | grep -E 'curl|mlx|ollama' | grep -v grep`
2. Check thermal state: `pmset -g therm`
3. Check GPU memory: `python3-mlx -c "import mlx.core as mx; print(mx.get_active_memory())"`
4. Run mlx_lm.benchmark directly: `python3-mlx -m mlx_lm.benchmark --model <model> --prompt-tokens 25 --generation-tokens 256`

## Recommendation
- Investigate mlx 0.31.2 vs 0.29.3 performance
- Test with clean GPU (no background processes)
- Consider downgrading mlx if regression confirmed
