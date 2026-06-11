# mlx stream_generate max_tokens Hidden Default (256)

## Root Cause

`mlx_lm.utils.stream_generate()` has a **hidden default** `max_tokens=256`:

```python
def stream_generate(model, tokenizer, prompt, max_tokens=256, ...):
```

Without explicitly passing `max_tokens`, models generate ~256 tokens then stop.

## Impact

- All mlx tests complete in 1-2 seconds with tiny outputs
- Code test generates incomplete function
- Summary test generates 2-3 sentences instead of full analysis
- User sees "модели просто пролетают тесты моментально"

## Fix

```python
effective_max = max_tok if max_tok > 0 else 100000
for chunk in stream_generate(model, tokenizer, tokens, max_tokens=effective_max):
    ...
```

Where `max_tok=0` in our script means "no limit" → pass 100000 to mlx.

## How to detect

- All mlx tests complete in <2 seconds
- Outputs are suspiciously short (~200-300 chars)
- TPS looks normal but total time is tiny
- Other providers (ollama, mtplx) show reasonable times for same tests

## Lesson

Always check default parameter values in library functions.
Hidden defaults can silently truncate output without any error message.
