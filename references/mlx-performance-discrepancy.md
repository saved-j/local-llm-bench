# mlx Performance: CLI vs In-Process Discrepancy

## Discovery (2026-06-10)
mlx_lm.generate CLI (`python3-mlx -m mlx_lm.generate`) gives 73-77 t/s.
Python `generate()` in-process gives 43-45 t/s. Same model, same mlx-lm 0.31.3, same hardware (M4 Max).

## Measurements (gemma4-26b-heretic, 256 tokens, Quick Start prompt)
| Method | TPS | Wall time |
|--------|-----|-----------|
| CLI `mlx_lm.generate` | 73-77 t/s | 9.4s |
| CLI subprocess from Python | 73.6 t/s | 9.7s |
| Python `generate()` in-process | 43-45 t/s | 11.7s |
| Python `stream_generate()` in-process | 43-48 t/s | 11.7s |

## What was tried (none helped)
- Clean environment (`env -i`) — same 44 t/s
- `model_config={'quantize_activations': None}` — same 43.8 t/s
- `tokenizer_config={'trust_remote_code': True}` — same 44 t/s
- Running script as file vs `-c` — same 43-44 t/s
- Clearing mlx cache — no effect
- Different Python versions (3.9, 3.14) — same

## Root Cause (unresolved)
The CLI's `main()` function does something that Python import doesn't.
Possibilities:
1. Metal shader compilation differences between CLI entry point and import
2. Internal mlx optimization triggered differently
3. Memory allocation patterns differ

## Impact on Bench
The bench script uses `stream_generate()` in-process → 45 t/s.
This is the REAL sustained speed. The v5 results (104 t/s) were inflated because:
- v5 had `max_tokens=256` (mlx default bug) → only 256 tokens generated
- Short responses = small KV cache = faster per-token
- Current `max_tokens=32768` → thousands of tokens → KV cache grows → TPS drops

## v5 vs Current Comparison
| Metric | v5 (2026-06-09) | Current (2026-06-10) |
|--------|-----------------|---------------------|
| max_tokens | 256 (bug) | 32768 |
| gemma4-26b TPS | 104 t/s | 45-50 t/s |
| ctok | 256 (all tests) | 284-32768 |
| Reason | Short responses, small KV | Long responses, large KV |

## Lesson
100+ t/s on mlx was an artifact of the 256-token default limit. Real sustained speed for 26B MoE models is 45-50 t/s. CLI shows higher TPS but the cause is unknown and doesn't affect in-process usage.
