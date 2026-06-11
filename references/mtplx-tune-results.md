# mtplx Tune Results — 2026-06-09

## Model: qwen3.6-27b-mtp-d2

### Tune Results (mtplx tune)
| Mode | TPS | Multiplier |
|------|-----|-----------|
| AR (no MTP) | 25.50 | 1.00x |
| D1 | 42.21 | 1.66x |
| **D2 🏆** | **47.37** | **1.86x** |
| D3 | 41.14 | 1.61x |

**Acceptance rates:** depth0 = 92.75%, depth1 = 86.76%

### Required mtplx startup flags
```
--profile performance-cold --mtp --depth 2
```

### Pitfalls
- `--profile stable` disables MTP → drops to 14-16 t/s
- `--warmup-tokens 0` can be added but not required (Quick Start test warms model)
- Without MTP: model generates at AR speed (~25 t/s), mtplx_stats shows `draft_accept=0/0`

### Wall-clock vs hardcoded TPS
- OLD (broken): `approx_ns = comp_tok / 50.0 * 1e9` → always 50.0 t/s
- NEW (fixed): `time.perf_counter()` around HTTP request → real timing
- Quick Start = cold start (16-17 t/s), subsequent tests climb to 45-47 t/s

### Benchmark results with real timing
```
Quick Start    : 16.8 t/s  ← cold start, warmup
Trap           : 41.2 t/s
Expertise      : 38.3 t/s
Data Process   : 42.3 t/s
Calculations   : 45.6 t/s
Code           : ~46 t/s
UI             : ~47 t/s
```
