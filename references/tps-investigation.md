# mlx TPS Investigation (2026-06-11)

## Problem
mlx models show lower TPS than v5 benchmark results (2026-06-09).

## Findings

### In-process vs CLI subprocess
| Model | In-process `generate()` | CLI `mlx_lm.generate` | v5 Result |
|-------|------------------------|----------------------|-----------|
| gemma3-4b | 44-48 t/s | 117-120 t/s | 121-131 t/s |
| gemma4-26b | 43-48 t/s | 73-80 t/s | 95-104 t/s |
| qwen3-next-80b | ~37 t/s | 39 t/s | 27-28 t/s |

**Root cause:** Metal runtime initialization differs between CLI module execution and in-process import. The CLI runs through `python3-mlx -m mlx_lm.generate` which uses a different initialization path.

**Fix:** Use subprocess CLI in `ask_mlx()`:
```python
subprocess.run(["python3-mlx", "-m", "mlx_lm.generate",
                "--model", model_id, "--prompt", prompt,
                "--max-tokens", str(max_tok)], ...)
```

### smbd CPU runaway
System `smbd` can consume 1400%+ CPU. Even though mlx inference is GPU-bound, thermal throttling and memory pressure degrade TPS by 15-25%.

**Detection:** `uptime` shows load averages >10, `ps aux | grep smbd` shows high %CPU.

**Fix:** `sudo kill -9 <smbd_pid>` or `sudo reboot`. Cannot be done without sudo.

### mlx-lm version doesn't matter
Tested mlx-lm 0.27.0, 0.29.1, 0.31.3 — all give identical in-process TPS. The version is not the cause.

### macOS version gap
v5 was run on 2026-06-09, current is 2026-06-11 with macOS 26.5.1. The 20% gap between CLI results and v5 for gemma4-26b may be due to OS/Metal changes.

## v5 Results Were Misleading
v5 had `max_tokens=256` bug (mlx default). All tests showed ctok=256. The 104 t/s was on short 256-token generations. With proper max_tokens (32768), TPS is lower because KV cache grows.

## Recommendations
1. Always use CLI subprocess for mlx inference (1.6-2x faster)
2. Use `generation_tps` from CLI output, not wall-clock measurement
3. Monitor system load — smbd can silently degrade performance
4. Compare CLI results with v5, not in-process results
