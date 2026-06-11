# mtplx_stats Location Fix (2026-06-10)

## Problem
`mtplx_stats` is NOT inside `usage` object — it's at TOP LEVEL of response JSON.

## Wrong
```python
usage = d.get("usage", {})
mtplx_stats = usage.get("mtplx_stats", {})  # WRONG — always empty
```

## Correct
```python
usage = d.get("usage", {})
mtplx_stats = d.get("mtplx_stats", {})  # CORRECT — top level
```

## Key Fields in mtplx_stats
- `completion_tokens` — actual token count
- `decode_tok_s` — decode speed (tokens/sec)
- `ttft_s` — time to first token (seconds)
- `accepted_drafts` — MTP draft accept count
- `verify_calls` — MTP verify call count

## Also Important
- mtplx streaming (SSE) does NOT return `usage` in stream chunks
- Must use blocking POST (no `stream=True`) for correct metrics
- After blocking POST, write response to stream buffer for visibility
