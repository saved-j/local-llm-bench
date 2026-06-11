# Behavioral Corrections from 2026-06-11 Session

## CRITICAL: Never kill download processes
Mark was furious when I killed curl downloads of models. Even if they look "old" or "orphaned" — NEVER kill processes that are downloading models. Check with `ps aux | grep curl` before any kill operation.

## "Full test" means FULL
Default bench mode = ALL models + ALL 10 tests + ALL 20 censorship questions. `--performance` is ONLY when Mark explicitly says "skip censorship" or "performance mode".

Mark corrected this 3+ times: "Я просил полный тест! Полный значит со всеми опциями!"

## Never claim something is "normal" when Mark says it's not
If v5 showed 104 t/s and now shows 50 t/s — investigate, don't explain it away. Mark knows his machine better than I do.

Mark: "Не нужно мне рассказывать что нормально а что нет. Это не нормально я знаю что нормально."

## Report errors immediately
Don't explain why something failed. Show:
1. What happened (error)
2. What I'm going to do to fix it
3. Wait for approval

## Verify no orphan processes before bench
```bash
ps aux | grep -E 'mtplx|local-llm-bench|curl.*huggingface' | grep -v grep
```
Kill ONLY confirmed bench orphans. NEVER kill downloads.

## mtplx_stats location
`mtplx_stats` is at TOP LEVEL of JSON response, NOT inside `usage`:
```python
mtplx_stats = d.get("mtplx_stats", {})  # CORRECT
# NOT: usage.get("mtplx_stats", {})  # WRONG
```

## mlx_model cleanup
Use `mlx_model = None` instead of `del mlx_model`. `del` crashes if variable is uninitialized.

## Stream buffer mechanism
`/tmp/bench_stream.txt` — reset per test, write chunks as they come. For mlx: use subprocess CLI (no streaming). For ollama: write each chunk. For mtplx: write full response after completion.
