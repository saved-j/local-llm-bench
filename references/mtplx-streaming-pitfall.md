# mtplx SSE Streaming Pitfall — DO NOT USE

## Problem (discovered 2026-06-10)
Rewrote `ask_mtplx` from blocking POST to SSE streaming (`stream: true`) to get real-time CoT visibility.

**Result:** All 10 mtplx tests showed `ctok=0, N/A t/s`. Token counting completely broke.

## Root Cause
mtplx SSE stream sends text chunks with `finish_reason: null` and NEVER sends `usage` object.
Non-streaming response includes `usage.completion_tokens` and top-level `mtplx_stats`.

## Fix
Reverted to blocking POST. Write full response to stream buffer AFTER completion.

## Trade-off
- mtplx: no per-token streaming, but correct metrics + buffer visibility after test
- ollama/mlx: per-token streaming works fine
