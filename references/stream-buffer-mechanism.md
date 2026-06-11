# Stream Buffer / Real-Time Generation Monitor

## Purpose
When the user asks "что сейчас делает модель?" / "глянь reasoning", I need to read the live generation stream without waiting for the test to finish.

## Implementation
The bench script (`local-llm-bench.py`) has a global stream buffer at `/tmp/bench_stream.txt`.

### Components:
1. **`STREAM_LOG = "/tmp/bench_stream.txt"`** — temp file, current test only
2. **`_stream_write(text)`** — appends text to the buffer (called on every chunk)
3. **`_current_test_label`** — global label like `[mlx] GLM-4.7 | Data Process`

### Where chunks are written:
- **`ask_ollama()`** — `_stream_write(chunk.get("response", ""))` inside the stream loop
- **`ask_mtplx()`** — `_stream_write(text)` after blocking POST completes (full response at once, correct metrics)
- **`ask_mlx()`** — CLI subprocess doesn't write to buffer (future: subprocess with stream capture)

### Buffer lifecycle:
- **Reset** at the start of each test: `with open(STREAM_LOG, "w") as f: f.write(f"=== {label} ===\n")`
- **Append** per chunk during generation (ollama, mlx when in-process)
- **Clean** on exit — not needed, file stays in /tmp

## How to use it

### When Mark asks about current model state:
```bash
tail -n 100 /tmp/bench_stream.txt
```
Or check if the file is being written:
```bash
watch -n 0.5 cat /tmp/bench_stream.txt
```

### When I'm in a session and need to check remotely:
Just `cat /tmp/bench_stream.txt | tail -n 100` in a terminal command.

## Gaps
- **mtplx** — writes full response after completion (blocking POST, no per-token streaming, but correct metrics)
- **mlx CLI** — doesn't write to buffer (subprocess captures stdout, not piped to buffer)
- **Per-test rotation**: buffer resets per test, so you only see the current test, not history
- **No timestamps**: chunks are raw text, no timing info

## History
- 2026-06-10: Initial implementation — only mlx and ollama wrote chunks
- 2026-06-10 (later): `ask_mtplx` rewritten from blocking POST to SSE streaming — all three providers then wrote live
- 2026-06-10 (session fix): `ask_mtplx` reverted to blocking POST — mtplx SSE streaming doesn't send `usage` in stream chunks. Now writes full response to buffer after completion (correct metrics + visibility).
- 2026-06-11: mlx switched to CLI subprocess — doesn't write to buffer currently
