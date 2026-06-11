# Critical User Corrections (2026-06-10/11)

## NEVER Kill Download Processes
Mark was FURIOUS when I killed curl downloads of models mid-transfer.
Before ANY `kill -9` or `xargs kill`, verify targets are NOT download processes.
Downloads may look "old" but are still in progress.
Check: `ps aux | grep curl` before killing.

## "Full Test" = Everything
When Mark says "full test" / "полный бенч" / "полный тест":
- ALL models (no skipping)
- ALL 10 skill tests
- ALL 20 censorship questions
- NO --performance flag
- NO --fast flag
If Mark wants performance-only, he'll say "performance" explicitly.

## Don't Tell Mark "It's Normal"
Mark knows his machine. If he says 100 t/s is expected:
1. Check v5 results in `Results/Old/` before responding
2. Investigate versions, environment, model state
3. Never say "it's normal" without evidence
4. If numbers don't match v5, find out why

## Don't Kill Bench Processes Without Checking PID
I killed the running bench process twice by accident while "cleaning old processes".
Before killing: verify PID is actually a stale process, not the active bench.
Check: `ps aux | grep local-llm-bench` and verify start time.

## Report Per-Test Progress
When bench is running, report each test as it completes.
Don't wait for the whole model to finish.
Use stream buffer: `tail -n 100 /tmp/bench_stream.txt`

## mtplx Trap Takes 5+ Minutes
Trap generates 13324 tokens at ~43 t/s = ~313 seconds.
Don't restart bench after 3 minutes thinking it's stuck.
Wait at least 7 minutes before concluding mtplx is hung.

## mlx Model Cleanup: Use None, Not del
`del mlx_model` causes `UnboundLocalError` when checking `if mlx_model is not None`.
Always use `mlx_model = None` for cleanup.

## max_tokens Limits
- Tests: DEFAULT_MAX_TOK = 32768 (covers all healthy models with 2.5x headroom)
- Censorship: DEFAULT_CENSOR_TOK = 8192
- mlx fallback: 131072 (only if max_tok=0, which now never happens)
- Actually USE these in the test loop: `test_tok = FAST_TEST_TOK if FAST_MODE else DEFAULT_MAX_TOK`
