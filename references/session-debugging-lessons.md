# Benchmark Session Debugging Lessons

## Pitfall: Killing bench too early
**Never kill bench if only Quick Start done.** mtplx Trap test takes 5+ minutes (13324 tokens at 43 t/s). If you kill after 3 minutes, you lose all progress.

**Rule:** Wait at least 10 minutes before checking mtplx progress.

## Pitfall: Killing bench when cleaning up "old" processes
**NEVER kill bench processes when cleaning up "old" or "orphan" processes.** The bench is a long-running process that can take hours. If you kill it, you lose ALL progress.

**Rule:** Before killing ANY process, verify it's actually an orphan:
1. Check if it's the current bench process (PID matches the one you started)
2. Check if it's a provider server (ollama, mtplx) that the bench needs
3. Only kill processes that are truly orphaned (from previous failed runs)

**Example of WRONG behavior:**
```bash
# WRONG — kills the current bench!
ps aux | grep local-llm-bench | xargs kill -9
```

**Example of CORRECT behavior:**
```bash
# CORRECT — only kill if you started a NEW bench and old one is orphaned
ps aux | grep local-llm-bench | grep -v grep
# Check PID — is it the one you started? If yes, DON'T kill it.
# If it's from a previous failed run, then kill it.
```

## Pitfall: mtplx_stats extraction
`mtplx_stats` is at TOP LEVEL of JSON, NOT inside `usage`. Code must use:
```python
mtplx_stats = d.get("mtplx_stats", {})
```
NOT:
```python
mtplx_stats = usage.get("mtplx_stats", {})
```

## Pitfall: mtplx TPS calculation
Using `total_ns` (HTTP round-trip) gives wrong TPS for short responses (7-14 t/s instead of 32-47 t/s).

**Fix:** Use `mtplx_stats.get("decode_tok_s", 0)` for accurate TPS.

## Pitfall: mtplx SSE streaming
SSE streaming (`stream: true`) does NOT send usage stats. Stream chunks only have `choices[0].text`.

**Fix:** Use blocking POST for correct metrics.

## Pitfall: GLM-4.7-impotent-heresy CoT
Generates 131K tokens for simple CSV task. Never reaches EOS.

**Fix:** Set `DEFAULT_MAX_TOK = 32768` (32K tokens).

## Pitfall: max_tok=0 not applied
`DEFAULT_MAX_TOK = 4096` was defined but never used. Script passed `max_tok=0` which means "no limit".

**Fix:** Use `DEFAULT_MAX_TOK` in test loop: `test_tok = FAST_TEST_TOK if FAST_MODE else DEFAULT_MAX_TOK`
