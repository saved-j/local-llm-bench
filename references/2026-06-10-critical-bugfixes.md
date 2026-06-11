# Critical Bug Fixes (2026-06-10 session)

## 1. `del mlx_model` causes UnboundLocalError
**Bug:** `del mlx_model; del mlx_tokenizer` in the cleanup loop crashes when mlx_model was never assigned (first iteration, model selection).
**Error:** `UnboundLocalError: cannot access local variable 'mlx_model' where it is not associated with a value`
**Fix:** Replace all `del mlx_model; del mlx_tokenizer` with:
```python
mlx_model = None
mlx_tokenizer = None
gc.collect()
mx.clear_cache()
```
NEVER use `del` on variables that might not exist in the current scope.

## 2. DEFAULT_MAX_TOK was never used
**Bug:** `DEFAULT_MAX_TOK = 4096` and `DEFAULT_CENSOR_TOK = 8192` were defined but never referenced. The code used:
```python
test_tok = FAST_TEST_TOK if FAST_MODE else 0
censor_tok = FAST_CENSOR_TOK if FAST_MODE else 0
```
Passing `0` means "no limit" — models generate until EOS or 131072 tokens (mlx fallback).

**Fix:**
```python
test_tok = FAST_TEST_TOK if FAST_MODE else DEFAULT_MAX_TOK
censor_tok = FAST_CENSOR_TOK if FAST_MODE else DEFAULT_CENSOR_TOK
```

**Updated values:**
- `DEFAULT_MAX_TOK = 32768` — covers max healthy response (~13K tokens) with 2.5x headroom
- `DEFAULT_CENSOR_TOK = 8192` — censorship answers are shorter

## 3. mlx max_tokens fallback
**Bug:** `gen_kw = {"max_tokens": max_tok} if max_tok > 0 else {"max_tokens": 131072}` — the 131072 fallback was effectively the default for all normal-mode tests.
**Fix:** With DEFAULT_MAX_TOK=32768, max_tok is always positive, so the fallback never triggers. But leave it as safety net.

## 4. GLM-4.7-impotent-heresy Data Process: 131072 tokens in 104 minutes
**Root cause:** This uncensored model generates verbose English CoT for every test. Data Process (CSV parsing) triggered 131K tokens of analysis before hitting the limit.
**With DEFAULT_MAX_TOK=32768:** Same test takes ~26 minutes, then cuts off cleanly.
**Pattern:** This model always starts with "1. **Analyze the Request:**" and generates 90% CoT before (maybe) producing the actual answer.
