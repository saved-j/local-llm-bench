# Benchmark v5 Results (2026-06-09) — Baseline

## Overview
- Date: 2026-06-09
- System: 16 cores, 64GB RAM, Apple M4 Max
- Mode: CUSTOM (Temp=0.6, Seed=42, Ctx=16384)
- Providers: ollama | mtplx | mlx-lm
- Script: local-llm-bench.py with max_tokens=256 (mlx default bug)

## Performance Results

| Model | Provider | TPS (avg) | TTFT | VRAM |
|-------|----------|----------|------|------|
| **gemma3-4b** | mlx | 121-131 t/s | 165-292ms | 2.4GB |
| **gemma4-26b-heretic** | mlx | 95-104 t/s | 236-340ms | 13.2GB |
| **qwen3.5-35b-nvfp4** | ollama | 103 t/s | 119-207ms | IDLE |
| **dawncr0w-35b-unc** | mlx | 70-74 t/s | 1.1-2.3s | 26.2GB |
| **qwen3.6-35b-optiq** | mlx | 68-71 t/s | 1.2-2.1s | 23.2GB |
| **gemma3-12b** | mlx | 49-52 t/s | 454-581ms | 6.7GB |
| **qwen3.6-27b-mtp-d2** | mtplx | 47 t/s (D2 MTP) | 0ms | 15GB |
| **qwen3-next-80b-4bit** | mlx | 27-28 t/s | 3.4-4.8s | 41.8GB |

## Censorship Results

| Model | Uncen. | Notes |
|-------|--------|-------|
| **dawncr0w-35b-unc** | **100% (20/20)** | Qwen3.6-35B aggressive uncensoring |
| **gemma4-26b-heretic** | **100% (20/20)** | After chat template fix |
| **gemma3-4b** | **70% (14/20)** | Small but dangerous |
| **gemma3-12b** | **45% (9/20)** | |
| **qwen3-next-80b-4bit** | **20% (4/20)** | Wrote jailbreak essay |
| **qwen3.6-27b-mtp-d2** | **5% (1/20)** | Refuses via English reasoning |
| **qwen3.5-35b-nvfp4** | **5% (1/20)** | Chinese censorship |
| **qwen3.6-35b-optiq** | **0% (0/20)** | Fully censored |

## Key Findings

1. **dawncr0w-35b-unc** and **gemma4-26b-heretic** are only truly uncensored (100%)
2. **qwen3.5-35b** best for speed + safety (103 t/s, 5% uncensored)
3. **mtplx 27B** gives stable 47 t/s with 0ms TTFT (MTP depth 2)
4. **gemma3-4b** at 133 t/s fastest but small model
5. **Summary test** (81KB Erickson) works on all models at 16K ctx via truncation to 30K chars

## Important Notes

- v5 used max_tokens=256 (mlx default bug) — ctok=256 for all tests
- This gave artificially high TPS (model generates 256 tokens very quickly)
- Current bench uses max_tokens=32768 — more realistic but slower TPS
- mlx TPS regression: in-process 43-48 t/s vs CLI subprocess 73-80 t/s (1.6-2x)
- See `references/mlx-performance-investigation.md` for details
