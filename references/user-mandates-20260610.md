# User Mandates (2026-06-10/11 Session Corrections)

## "Full test" = FULL test
When user says "full bench" or "full test", it means ALL models, ALL 10 tests, ALL 20 censorship questions.
NEVER use --performance unless user explicitly says "skip censorship" or "performance only".
Default command: `python3-mlx local-llm-bench.py --suffix=X --no-chat --all`
With --performance: ONLY when user explicitly asks.

## Never kill download processes
Before ANY kill/pkill, check that targets are NOT:
- curl processes downloading models
- hf download processes
- Any background process user explicitly started
Mark was furious when I killed downloads 3 times. This is a HARD RULE.

## Never tell user what's "normal"
When user reports a specific TPS or metric, DO NOT say "this is normal for X model".
User knows their hardware. If they say "should be 100 t/s", investigate, don't dismiss.
Mark: "Не нужно мне рассказывать, что нормально. Это не нормально, я знаю, что нормально."

## mlx_model cleanup: use None, not del
`mlx_model = None` instead of `del mlx_model` — avoids UnboundLocalError.

## --models flag
Multi-model selection: `--models "gemma-4-26B,Qwen3.6-35B,Huihui-GLM"`
Comma-separated, partial name match. Added 2026-06-10.

## Stream buffer
`/tmp/bench_stream.txt` — resets per test, header: `=== [prov] model | test_name ===`
All 3 providers write (mlx via subprocess, ollama via stream, mtplx via blocking POST).
Documented in references/stream-buffer-mechanism.md.
