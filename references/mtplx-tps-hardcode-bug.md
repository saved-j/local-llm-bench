# mtplx TPS Hardcoded at 50 tok/s — Bug Analysis

## Root Cause

`ask_mtplx()` in `local-llm-bench.py` estimated request duration using assumed TPS:

```python
# BUG: hardcoded assumption
approx_ns = int(comp_tok / 50.0 * 1e9) if comp_tok > 0 else 0
return (text, approx_ns, ttft_ns, comp_tok, approx_ns)
```

TPS was then calculated as:
```python
tps = eval_count / (eval_dur / 1e9)
# = comp_tok / (comp_tok / 50)
# = 50.0 ALWAYS
```

## Impact

- ALL mtplx tests showed exactly 50.0 t/s regardless of actual performance
- `draft_accept=0/0` in mtplx_stats = MTP not working, but nobody noticed
- Real performance without MTP: 14-16 t/s
- Real performance with MTP (performance-cold, depth 2): 47 t/s
- User spent entire evening tuning mtplx MTP to 47 t/s — hardcode hid that MTP wasn't enabled in bench

## Fix

```python
t0 = time.perf_counter()
r = requests.post(f"http://127.0.0.1:{MTPLX_PORT}/v1/completions", ...)
t1 = time.perf_counter()
total_ns = int((t1 - t0) * 1e9)
return (text, total_ns, ttft_ns, comp_tok, total_ns)
```

## How to detect

- All tests show identical TPS (e.g., 50.0 for every test including Quick Start and Summary)
- `draft_accept=0/0` in stats file = MTP not active
- TPS doesn't vary with test complexity (Quick Start should be fastest, Summary slowest)

## Lesson

Never hardcode expected values into measurement code. Always measure actual wall-clock time.
A measurement tool that lies is worse than no measurement tool.
