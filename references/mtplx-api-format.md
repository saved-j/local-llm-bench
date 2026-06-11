# mtplx API Response Format Quirks

## Key Findings

### 1. mtplx_stats is at TOP LEVEL, not inside `usage`
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"completion_tokens": 8},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293}  // ← HERE
}
```

**WRONG:** `mtplx_stats = usage.get("mtplx_stats", {})` → always empty
**CORRECT:** `mtplx_stats = d.get("mtplx_stats", {})` → works

### 2. SSE Streaming (stream=true) does NOT send `usage` or `finish_reason`
mtplx SSE chunks:
```
data: {"choices":[{"text":"\n\n<think>\n\n","finish_reason":null}]}
data: {"choices":[{"text":" response","finish_reason":null}]}
data: {"choices":[{"text":"\n\nREADY.","finish_reason":null}]}
data: [DONE]
```

No `finish_reason: "stop"` in stream — only `null` then `[DONE]`.
No `usage` object in stream — completion_tokens not available.

**Consequence:** Streaming mode makes it impossible to get `completion_tokens` and `mtplx_stats` metrics.

**Fix:** Use blocking POST (non-streaming) for correct metrics:
```python
body = {"prompt": prompt, "temperature": 0.0}  # No "stream" key
r = requests.post(url, json=body, timeout=900)
d = r.json()
comp_tok = d["usage"]["completion_tokens"]
mtplx_stats = d.get("mtplx_stats", {})
```

### 3. TTFT from mtplx_stats
TTFT is available in `mtplx_stats.ttft_s`:
```python
ttft_s = mtplx_stats.get("ttft_s", 0)
ttft_ns = int(ttft_s * 1e9) if ttft_s else 0
```

### 4. Blocking POST vs Stream Buffer
Blocking POST means the stream buffer (`/tmp/bench_stream.txt`) gets the full response after completion, not per-token. This is a trade-off: correct metrics vs real-time visibility.

### 5. VRAM measurement
mtplx runs in a separate process, so `mx.get_active_memory()` from the bench process doesn't see its memory.
Use `ps -o rss=` on mtplx PID instead:
```python
def get_mtplx_vram():
    if MTPLX_PID:
        r = subprocess.run(["ps", "-o", "rss=", "-p", str(MTPLX_PID)], capture_output=True, text=True)
        return int(r.stdout.strip()) / 1024**3 if r.stdout.strip() else 0
    return 0
```
