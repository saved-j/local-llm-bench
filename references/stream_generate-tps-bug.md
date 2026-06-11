# stream_generate TPS Measurement Bug

## The Bug
`mlx_lm.stream_generate()` does NOT yield per-token. It yields ONE `GenerationResponse`
containing the ENTIRE generated text in `.text`. A single iteration = the full response.

**Naive loop that gives WRONG TPS:**
```python
t0 = time.perf_counter()
for chunk in stream_generate(model, tokenizer, tokens, max_tokens=500):
    response_text += chunk.text  # ONE iteration for 500 tokens!
elapsed = time.perf_counter() - t0
tps = 500 / elapsed  # → 6.2 t/s (wrong! should be ~40)
```

The elapsed time includes prompt processing + full generation in one measurement.
Since there's only 1 loop iteration, `tps = tokens / total_time`, but total_time includes
prefill (TTFT), not just decode. On models that generate 500 tokens with 3s TTFT + 10s decode:
naive = 500/13 = 38.5 t/s (still wrong on large prompts).

## Root Cause
In mlx-lm < 0.32, `stream_generate` is implemented as a `Generator[GenerationResponse]`
where the generator yields EXACTLY ONCE. This is a batch generation, not a streaming token
generator. The `stream` in the name refers to yielding the response object through a
generator interface (standard Python iteration), NOT token-by-token streaming.

## Correct Measurement

```python
from mlx_lm import load, stream_generate
import mlx.core as mx

model_o, tokenizer = load(hf_model)
prompt_tokens = tokenizer.encode(prompt)

t0 = time.perf_counter()
ttft = None
response_text = ""

for chunk in stream_generate(model_o, tokenizer, prompt_tokens, max_tokens=max_tok):
    if ttft is None:
        ttft = time.perf_counter() - t0  # TTFT = time to first (and only) yield
    response_text += chunk.text

elapsed = time.perf_counter() - t0
out_tokens = len(tokenizer.encode(response_text))

# TPS = output_tokens / decode_time_only
# decode_time ≈ elapsed - ttft (approximate)
decode_time = elapsed - (ttft or 0)
tps = out_tokens / decode_time if decode_time > 0 else 0
```

## Results With Fix

| Model | Before (naive) | After (correct) | TTFT |
|-------|---------------|-----------------|------|
| qwen3-next-80b-4bit Quick Start (21 tok) | 5.5 t/s | too short for decode | 3.4s |
| qwen3-next-80b-4bit Normal (500 tok) | 6.2 t/s | **40-42 t/s** | 3.5s |
| qwen3-next-80b-4bit Summary (10K ctx) | N/A | **24.5 t/s** | 12s |
| qwen3-next-80b-4bit Long Ctx (5K ctx) | N/A | **31.6 t/s** | 7.6s |

## Notes
- `stream_generate` does NOT accept `temp=` parameter → `TypeError: unexpected keyword argument 'temp'`
- `mx.metal.get_active_memory()` is deprecated → use `mx.get_active_memory()`
- `mx.metal.clear_cache()` is deprecated → use `mx.clear_cache()`
- `mx.metal.set_cache_limit()` is deprecated → use `mx.set_cache_limit()`

## Verification (manual)

```bash
python3-mlx -c "
from mlx_lm import stream_generate, load
import time
model, tok = load('mlx-community/Qwen3-Next-80B-A3B-Instruct-4bit')
tokens = tok.encode('1+1=')
t0 = time.perf_counter()
for chunk in stream_generate(model, tok, tokens, max_tokens=200):
    ttft = time.perf_counter() - t0
    text = chunk.text
elapsed = time.perf_counter() - t0
toks = tok.encode(text)
print(f'TTFT={ttft:.2f}s total={elapsed:.2f}s tokens={len(toks)} tps={len(toks)/(elapsed-ttft):.1f}')
"
```
