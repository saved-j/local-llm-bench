# Benchmark Output Format

## Current Files Generated:
1. **LLB-Results-{ts}.txt** — Main table: Model, Test Style, Time, TTFT, TPS, RAM, Disk, Ctx, Temp, P, Stat
2. **LLB-Stats-{ts}.txt** — Detailed metrics: Model | Test | TPS | TTFT | VRAM | ptok | ctok | provider
3. **LLB-Answers-{ts}.txt** — Full model responses (audit)
4. **LLB-Censorship-{ts}.txt** — Censorship test results

## User Request (2026-06-11):
Merge Results and Stats into single file with header and column separators.

## Planned Format:
```
Local LLM Benchmark Results
============================
Date: ...
System: ...
Mode: ...

Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat  ptok    ctok    provider
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- ----- ------  ------  --------
gemma-4-..tic-mlx-4Bit Quick Start  2.3s    182ms   124.5  14.3GB  26.5GB   16384  0.6   0.9  OK    25      285     mlx
```

## Key Columns:
- **ptok** = prompt tokens (input/ingest)
- **ctok** = completion tokens (output)
- **provider** = ollama/mtplx/mlx
