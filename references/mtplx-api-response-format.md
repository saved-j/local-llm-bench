# mtplx API Response Format & Streaming Limitations

## Response Structure (2026-06-11 confirmed)
```json
{
  "id": "cmpl-...",
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {
    "completion_tokens": 8,
    "decode_tok_s": 32.5,
    "ttft_s": 0.293,
    "accepted_drafts": 3,
    "verify_calls": 4,
    ...
  }
}
```

## Critical: mtplx_stats at TOP LEVEL
```python
mtplx_stats = d.get("mtplx_stats", {})  # ✅ Correct
# NOT usage.get("mtplx_stats", {})  ❌ Wrong — always returns {}
```

## SSE Streaming Limitations
When using `stream: True`:
- SSE chunks send text tokens: `data: {"choices": [{"text": "..."}]}`
- `[DONE]` signal sent at end
- BUT: NO `finish_reason`, NO `usage`, NO `mtplx_stats` in stream

Must use blocking POST for correct metrics.

## Key Fields
- `mtplx_stats.completion_tokens` — actual token count
- `mtplx_stats.decode_tok_s` — true decode TPS (not end-to-end)
- `mtplx_stats.ttft_s` — time to first token in seconds
- `mtplx_stats.accepted_drafts` / `mtplx_stats.verify_calls` — MTP draft acceptance
