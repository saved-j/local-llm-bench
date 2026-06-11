# mtplx SSE Streaming API — Token Counting Issue

## Problem
When rewriting `ask_mtplx` from blocking POST to SSE streaming (`stream: true`), token counting broke.

## Root Cause
1. mtplx SSE streaming doesn't send `usage` object in stream chunks
2. `finish_reason` is never "stop" in stream — always `null`
3. Token counting relies on `usage.completion_tokens` which is missing in stream mode

## Response Format (Non-Streaming)
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, ...}
}
```

## Response Format (Streaming)
```
data: {"choices": [{"text": "...", "finish_reason": null}]}
data: [DONE]
```
No `usage` object!

## Solution
- Use blocking POST (non-streaming) for correct metrics
- Write full response to stream buffer after completion
- This gives correct token counts + visibility (just not per-token)

## Key Fields in mtplx_stats (non-streaming)
- `completion_tokens` — token count
- `decode_tok_s` — decode speed
- `ttft_s` — time to first token
- `accepted_drafts` / `verify_calls` — MTP acceptance rate

## To Test
```bash
# Non-streaming (works)
curl -s http://127.0.0.1:8099/v1/completions \
  -X POST -H "Content-Type: application/json" \
  -d '{"prompt":"test","temperature":0.0}' | python3 -m json.tool

# Streaming (no usage)
curl -s http://127.0.0.1:8099/v1/completions \
  -X POST -H "Content-Type: application/json" \
  -d '{"prompt":"test","stream":true,"temperature":0.0}'
```
