# mtplx Streaming & Metrics Debug (2026-06-10)

## Problem 1: mtplx_stats location
**Bug:** Code used `usage.get("mtplx_stats", {})` — always empty.
**Root cause:** mtplx API returns `mtplx_stats` at TOP LEVEL of JSON response, NOT inside `usage`.
**Fix:** `mtplx_stats = d.get("mtplx_stats", {})`

## Problem 2: mtplx SSE streaming doesn't send usage
**Bug:** Tried `stream: True` for real-time CoT visibility. mtplx SSE stream sends text tokens but NEVER sends `usage` or `finish_reason` in the stream chunks.
**Evidence:**
```
data: {"choices":[{"text":"...","finish_reason":null}]}
data: [DONE]
```
No `usage` object, no `finish_reason: "stop"`.
**Fix:** Reverted to blocking POST (`stream: False`). Correct metrics (ctok, usage, mtplx_stats). Writes full response to stream buffer AFTER completion.

## Problem 3: ttft_s not extracted from mtplx_stats
**Bug:** TTFT was hardcoded to 0 for mtplx.
**Fix:** Extract from mtplx_stats: `ttft_s = mtplx_stats.get("ttft_s", 0)`

## Problem 4: MTP (Multi-Token Prediction) intermittent
**Symptom:** First run showed 7.8 t/s, second showed 14.9 t/s, third showed 32.5 t/s.
**Root cause:** MTP effectiveness depends on mtplx server warmup state. Quick Start IS the warmup — subsequent tests climb to 43-47 t/s.
**Key:** mtplx_stats shows `effective_depth: 0` for first request, then `effective_depth: 2` for subsequent ones.
