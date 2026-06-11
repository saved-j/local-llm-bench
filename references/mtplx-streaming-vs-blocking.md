# mtplx: Blocking POST (NOT streaming)

## Why
mtplx SSE streaming (`"stream": true`) does NOT include `usage` object in stream chunks. No `finish_reason`, no `completion_tokens`, no `mtplx_stats`. This means zero metrics.

## How it works now
- Blocking POST to `/v1/completions` (timeout=900s)
- `usage.completion_tokens` = correct token count
- `mtplx_stats` at **top level** of JSON (NOT inside `usage`): `d.get("mtplx_stats", {})`
- `mtplx_stats.ttft_s` = time to first token
- `mtplx_stats.decode_tok_s` = decode speed
- `mtplx_stats.accepted_drafts` = MTP draft acceptance
- Response written to stream buffer AFTER completion (not per-token)

## Pitfalls
- `mtplx_stats` is TOP LEVEL, not nested in `usage`
- `completion_tokens` is in BOTH `usage` AND `mtplx_stats`
- Non-streaming returns full response at once — no real-time visibility during generation

## Response format (non-streaming)
```json
{
  "choices": [{"text": "response", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {
    "completion_tokens": 8,
    "ttft_s": 0.293,
    "decode_tok_s": 32.5,
    "accepted_drafts": 3,
    ...
  }
}
```
