# mtplx Streaming Investigation (2026-06-11)

## Problem
mtplx SSE streaming doesn't return `usage` in stream chunks, causing ctok=0 and TPS=N/A.

## Root Cause
mtplx SSE stream format:
```
data: {"choices": [{"text": "...", "finish_reason": null}]}
data: {"choices": [{"text": "...", "finish_reason": null}]}
data: [DONE]
```

No `usage` field in any chunk. No `finish_reason: "stop"` either.

## Solution
Reverted to blocking POST (no streaming) for correct metrics:
```python
body = {"prompt": prompt, "temperature": 0.0}
if max_tok > 0:
    body["max_tokens"] = max_tok
r = requests.post(f"http://127.0.0.1:{MTPLX_PORT}/v1/completions",
    json=body, timeout=900)
d = r.json()
text = d.get("choices", [{}])[0].get("text", "")
usage = d.get("usage", {})
comp_tok = usage.get("completion_tokens", 0)
mtplx_stats = d.get("mtplx_stats", {})  # TOP LEVEL, not inside usage
```

## mtplx_stats Location
`mtplx_stats` is at TOP LEVEL of JSON response, NOT inside `usage`:
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, ...}
}
```

## Stream Buffer
Even with blocking POST, we write to stream buffer after completion:
```python
_stream_write(text)
```
This gives visibility into model output (not real-time, but after test completes).

## Impact
- ctok now correctly reported
- TPS calculation works
- mtplx_stats (draft_accept, decode_tok_s, etc.) now available
- Stream buffer shows model output after test completes
