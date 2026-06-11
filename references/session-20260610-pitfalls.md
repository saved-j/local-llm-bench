# Session 2026-06-10: Critical Pitfalls and Fixes

## Process Management (CRITICAL)

### NEVER kill download processes
Downloading models (curl, hf download) must NEVER be killed. Mark was furious when I killed downloads twice. Check `ps aux | grep curl` before any kill — if it's downloading a model, leave it alone.

### NEVER kill bench processes without checking PID
I killed running bench processes twice thinking they were "old". Always check PID and start time before killing. The bench script spawns its own mtplx server — don't kill that either.

### "Full test" means EVERYTHING
"Full test" = ALL models + ALL 10 tests + ALL 20 censorship questions. NEVER use `--performance` unless explicitly told. "Full" is the DEFAULT.

### Check Old/ results before claiming "normal" TPS
Before saying "this TPS is normal", check `/Results/Old/` for historical results. Mark knows his machine's performance.

## mtplx API Format

### mtplx_stats is at TOP LEVEL
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, "accepted_drafts": 3}
}
```
Use `d.get("mtplx_stats")` NOT `usage.get("mtplx_stats")`.

### mtplx streaming doesn't send usage stats
SSE stream chunks don't include `usage` or `finish_reason: "stop"`. Must use blocking POST for correct metrics.

## mlx Performance

### generate() CLI is 2x faster than in-process
- `python3-mlx -m mlx_lm.generate` → 120 t/s (gemma3-4b)
- `generate()` in-process → 64 t/s (same model)
- Consistent across all models. Cause: unknown (Metal shader compilation? process isolation? mlx core optimization?)

### v5 TPS was inflated by max_tokens=256 bug
v5 showed 104 t/s for gemma4-26b-heretic. All tests had ctok=256 (mlx default). Current with max_tokens=32768: 37-50 t/s. This is real sustained speed.

### mlx_model cleanup
`del mlx_model` causes `UnboundLocalError`. Use `mlx_model = None` instead.

## Constants (now actually wired)

- `DEFAULT_MAX_TOK = 32768` — tests (was defined but unused, now wired)
- `DEFAULT_CENSOR_TOK = 8192` — censorship (same)
- `STREAM_LOG = /tmp/bench_stream.txt` — real-time CoT buffer

## New CLI Flag

`--models "gemma-4,Qwen3.6-35B"` — comma-separated model list for selective testing.
