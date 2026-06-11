# mlx Performance: CLI Subprocess vs In-Process

## Key Finding
In-process `generate()` / `stream_generate()` is 1.6-2x slower than CLI subprocess `mlx_lm.generate`.

## Test Results (gemma4-26b-heretic, 256 tokens)

| Method | TPS | Notes |
|--------|-----|-------|
| In-process generate() | 43-48 t/s | Same mlx-lm version |
| CLI subprocess | 73-80 t/s | Fresh process |
| v5 reference (in-process) | 95-104 t/s | Different session |

## Root Cause Analysis

1. **Clean process vs accumulated state**: CLI starts fresh Python, loads model once, exits
2. **Metal initialization**: CLI may get optimal Metal configuration
3. **Memory fragmentation**: In-process has overhead from previous model loads
4. **Environment**: hermes agent environment adds overhead

## Test Protocol

```python
# In-process test
python3-mlx -c "
import time
from mlx_lm import load, generate
model, tok = load('culturerevolt/gemma-4-26B-A4B-it-ultra-uncensored-heretic-mlx-4Bit')
generate(model, tok, 'test', max_tokens=10)  # warmup
t0 = time.perf_counter()
resp = generate(model, tok, prompt, max_tokens=256)
elapsed = time.perf_counter() - t0
print(f'TPS: {len(tok.encode(resp))/elapsed:.1f}')
"

# CLI subprocess test
python3-mlx -m mlx_lm.generate --model <model> --prompt <prompt> --max-tokens 256
# Output: Generation: 256 tokens, XX.XXX tokens-per-sec
```

## Verified Results

- gemma3-4b: CLI 120 t/s, in-process 64 t/s → CLI 1.9x faster
- gemma4-26b: CLI 75-80 t/s, in-process 45-48 t/s → CLI 1.7x faster
- qwen3-next-80b: CLI 39 t/s, in-process 25 t/s → CLI 1.6x faster

## QAT Models — Even Faster

QAT models close the gap to v5 speeds:
- gemma-4-26B-A4B-it-qat-4bit: 117-123 t/s (v5 was 95-104)
- gemma-4-26B-A4B-it-qat-6bit: 81-93 t/s
- gemma-4-31B-it-qat-4bit: 26.8GB dense

## Implementation

`ask_mlx()` in local-llm-bench.py uses subprocess CLI:
```python
result = subprocess.run([
    sys.executable, '-m', 'mlx_lm.generate',
    '--model', hf_model,
    '--prompt', prompt,
    '--max-tokens', str(max_tok)
], capture_output=True, text=True, timeout=1200,
env=cli_env)
```

Parse TPS from stdout line: `Generation: NNN tokens, XX.XXX tokens-per-sec`
