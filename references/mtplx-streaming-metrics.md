# mtplx Streaming & Metrics (2026-06-11)

## Problem
mtplx SSE streaming (`"stream": True`) does NOT return `usage` object with `completion_tokens`.
Only `finish_reason` may appear in final chunk, but even that's unreliable.

## mtplx_stats Location
`mtplx_stats` is at TOP LEVEL of JSON response, NOT inside `usage`:
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, "accepted_drafts": 3, ...}
}
```

Correct: `d.get("mtplx_stats", {})` — NOT `usage.get("mtplx_stats", {})`.

## Solution: Blocking POST
Reverted to blocking POST (non-streaming) for correct metrics.
Stream buffer written AFTER test completes (not per-token).
TTFT taken from `mtplx_stats.ttft_s`.

## Key mtplx_stats fields
- `completion_tokens` — token count
- `decode_tok_s` — actual decode speed (includes MTP boost)
- `ttft_s` — time to first token
- `accepted_drafts` / `verify_calls` — MTP draft acceptance rate
- `effective_max_tokens` — effective limit considering context window

## Pitfall: finish_reason check
Use `if choice.get("finish_reason"):` (truthy) not `== "stop"` — mtplx may send different values.
