# mlx Model Bugs & Fixes (2026-06-10)

## Bug 1: `del mlx_model` crashes on first model
**Symptom:** `UnboundLocalError: cannot access local variable 'mlx_model'`
**Cause:** First model in list has `mlx_model = None` initially. `del None` crashes.
**Fix:** Use `mlx_model = None` instead of `del mlx_model` in cleanup.

## Bug 2: Verbose CoT models hit max_tokens
**Symptom:** GLM-4.7 "impotent heresy" / "abliterated" models generate 131072 tokens of chain-of-thought for Data Process test (104 minutes).
**Cause:** These models generate verbose English reasoning before answering. No EOS detection.
**Fix:** Set `DEFAULT_MAX_TOK = 32768` (2.5x headroom over max healthy response of 13324 tokens).
**Impact:** Data Process takes ~26 min instead of 104 min. Other tests unaffected (usually 3-12K tokens).

## Bug 3: mlx stream_generate max_tokens default is 256
**Symptom:** All mlx tests complete in 1-2 seconds with tiny outputs.
**Cause:** `stream_generate()` has hidden default `max_tokens=256`.
**Fix:** Pass `max_tokens=max_tok` explicitly (where max_tok=32768 in normal mode).

## Bug 4: mlx deprecated APIs
**Symptom:** Warnings on every call.
**Fix:** Use `mx.get_active_memory()`, `mx.set_cache_limit()`, `mx.clear_cache()` instead of `mx.metal.*`.

## Bug 5: Chat template not applied
**Symptom:** Models like gemma4 produce garbage output (token loops).
**Fix:** Check `hasattr(tokenizer, 'chat_template')` and apply `tokenizer.apply_chat_template()`.
