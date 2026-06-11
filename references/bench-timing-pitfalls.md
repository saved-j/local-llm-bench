# Bench Timing Pitfalls (2026-06-11)

## mtplx Trap Test: 5+ Minutes is NORMAL
The Trap test generates ~13324 tokens for mtplx at ~43 t/s = ~313 seconds (~5.2 minutes).

**DO NOT kill the bench thinking it's stuck.** Wait at least 7 minutes.

Quick diagnostic:
```bash
ps aux | grep mtplx | grep -v grep
```
- CPU > 0% → generating (normal)
- CPU = 0% AND elapsed > 10 min → might be stuck

## mlx Data Process: 20+ Minutes with Verbose CoT
GLM-4.7-impotent-heresy generates verbose chain-of-thought (English analysis of every CSV row). With max_tokens=32768, Data Process takes ~26 minutes. With max_tokens=131072 (old), took 104 minutes.

## mlx in-process vs CLI subprocess
mlx `generate()` in-process: 45-50 t/s
CLI subprocess: 73-120 t/s (1.6-2x faster)

Root cause unknown. Not environment, not PYTHONPATH, not model_config.

## Model Loading Time
First model load includes HF cache fetch + Metal shader compilation. Subsequent loads are faster. Budget 30-60s for first load of each model.
