# mtplx Bugs & Fixes

## Bug 1: 50 t/s Hardcoded (fixed 2026-06-09)
`ask_mtplx()` returned `approx_ns = int(comp_tok / 50.0 * 1e9)` — hardcoded 50 t/s.
Caller calculated TPS as `eval_count / (eval_dur / 1e9)` = `comp_tok / (comp_tok / 50)` = **always 50.0**.

### Fix
Replaced with real `time.perf_counter()` around HTTP request.

## Bug 2: mtplx_stats extracted from wrong location (fixed 2026-06-10)
`ask_mtplx()` used `usage.get("mtplx_stats", {})` — always empty because mtplx_stats is at TOP LEVEL.

### Root Cause
mtplx API response structure:
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, ...}
}
```
`mtplx_stats` is a sibling of `usage`, NOT nested inside it.

### Fix
`mtplx_stats = d.get("mtplx_stats", {})` instead of `usage.get("mtplx_stats", {})`

## Bug 3: mtplx SSE streaming doesn't send usage stats (fixed 2026-06-10)
Converted ask_mtplx from blocking POST to SSE streaming for real-time CoT visibility.
But mtplx SSE stream sends `choices[].text` with `finish_reason: null` and NO usage object.
The `[DONE]` message has no usage data either.

### Result
All mtplx tests showed `ctok=0, N/A t/s` with streaming.

### Fix
Reverted to blocking POST (without `"stream": true`) for correct metrics.
Stream buffer still works: `_stream_write(text)` after response completes.
Verified: non-streaming response includes `usage.completion_tokens` and `mtplx_stats`.
Added `ttft_s` from `mtplx_stats.get("ttft_s")` for proper TTFT measurement.

## Lesson
NEVER hardcode TPS estimates. Always measure wall-clock time.
mtplx API: mtplx_stats at top level, not inside usage. Streaming doesn't send usage.
