# mlx Performance: CLI Subprocess vs In-Process

## Discovery (2026-06-10/11)

### Problem
v5 benchmark (2026-06-09) showed gemma4-26b-heretic at 95-104 t/s.
Current in-process `generate()` gives 43-48 t/s — 2x regression.

### Root Cause
mlx Metal runtime behaves differently in isolated subprocess vs in-process.
CLI `python3-mlx -m mlx_lm.generate` gives 73-80 t/s — 1.6-2x faster than in-process.

### Verified
- mlx-lm version doesn't matter (tested 0.27, 0.29, 0.31 — all same)
- mlx core version doesn't matter (0.29.3, 0.31.2 — all same)
- Environment doesn't matter (clean env, hermes env — all same)
- Model loading method doesn't matter (load() with various configs — all same)
- System load (smbd 1400% CPU) causes ~20% additional degradation via thermal throttling

### Solution
Use subprocess CLI for mlx generation:
```python
cmd = [sys.executable, "-m", "mlx_lm.generate",
       "--model", model_id, "--prompt", prompt, "--max-tokens", str(max_tok)]
env = os.environ.copy()
env["PYTHONPATH"] = _brew_mlx + ":" + env.get("PYTHONPATH", "")
result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env)
# Parse generation_tps from stdout
```

### Results with CLI subprocess
- gemma3-4b: 120 t/s (v5: 121-131) ✅
- gemma3-12b: 60 t/s (v5: 49-52) ✅ faster
- gemma4-26b-heretic: 75-80 t/s (v5: 95-104) ⚠️ 80%
- qwen3-next-80b: 39 t/s (v5: 27-28) ✅ faster
- dawncr0w-35b: 57 t/s (v5: 70-74) ⚠️ 77%
- qwen3.6-35b-optiq: 55 t/s (v5: 68-71) ⚠️ 78%

### TPS Calculation Fix
CLI reports `generation_tps` which excludes model loading time.
Must use this instead of wall-clock time:
```python
generation_time_ns = int(completion_tokens / generation_tps * 1e9) if generation_tps > 0 else int(elapsed * 1e9)
```
