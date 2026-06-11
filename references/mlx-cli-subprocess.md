# MLX CLI Subprocess Approach (TPS Fix)

## The Problem
In-process `stream_generate()` / `generate()` gives **43-48 t/s** for gemma4-26b-heretic. CLI `mlx_lm.generate` via subprocess gives **75-80 t/s**. Same model, same mlx-lm version, same hardware. The CLI is consistently **1.6-2x faster**.

## Root Cause
Unknown. The `generate()` function internally calls `stream_generate()` which is the same code path. Even `python3-mlx -c "from mlx_lm import generate; ..."` gives the slower speed. Only `python3-mlx -m mlx_lm.generate` (module entry point) achieves v5-matching TPS.

Hypothesis: CLI module entry point initializes mlx/Metal runtime differently than in-process calls.

## The Fix
Use subprocess calls to `mlx_lm.generate` module instead of in-process `stream_generate()`/`generate()`.

### Implementation in `ask_mlx()`

```python
def ask_mlx(model_id, prompt, max_tok=0):
    \"\"\"Returns: (response, total_ns, ttft_ns, completion_tokens, generation_ns)
    Uses CLI subprocess for correct TPS (1.6-2x faster than in-process).\"\"\"
    try:
        cmd = [
            "/opt/homebrew/bin/python3.14", "-m", "mlx_lm.generate",
            "--model", model_id,
            "--prompt", prompt,
            "--max-tokens", str(max_tok) if max_tok > 0 else "32768",
            "--ignore-chat-template",
        ]
        env = os.environ.copy()
        env["PYTHONPATH"] = "/opt/homebrew/Cellar/mlx-lm/0.31.3_1/libexec/lib/python3.14/site-packages"
        
        t0 = time.perf_counter()
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300, env=env)
        elapsed = time.perf_counter() - t0
        
        # Parse CLI output for metrics
        # Generation: 256 tokens, 78.8 tokens-per-sec
        # Peak memory: 14.344 GB
        gen_line = [l for l in result.stdout.split('\n') if 'Generation:' in l]
        prompt_line = [l for l in result.stdout.split('\n') if 'Prompt:' in l]
        mem_line = [l for l in result.stdout.split('\n') if 'Peak memory:' in l]
        
        generated_text = result.stdout
        completion_tokens = 0
        generation_tps = 0
        prompt_tokens = 0
        prompt_tps = 0
        peak_memory_gb = 0
        
        if gen_line:
            # "Generation: 256 tokens, 78.8 tokens-per-sec"
            parts = gen_line[0].split(',')
            tok_part = parts[0].replace('Generation:', '').replace('tokens', '').strip()
            completion_tokens = int(tok_part)
            tps_part = parts[1].replace('tokens-per-sec', '').strip()
            generation_tps = float(tps_part)
        
        if prompt_line:
            parts = prompt_line[0].split(',')
            tok_part = parts[0].replace('Prompt:', '').replace('tokens', '').strip()
            prompt_tokens = int(tok_part) if tok_part.isdigit() else 0
            tps_part = parts[1].replace('tokens-per-sec', '').strip()
            prompt_tps = float(tps_part) if parts[1] else 0
        
        if mem_line:
            mem_str = mem_line[0].replace('Peak memory:', '').replace('GB', '').strip()
            peak_memory_gb = float(mem_str) if mem_str else 0
        
        # Calculate TTFT
        ttft_s = prompt_tokens / prompt_tps if prompt_tps > 0 else 0
        ttft_ns = int(ttft_s * 1e9)
        
        # Use generation time from CLI metrics (accurate)
        generation_time_ns = int(completion_tokens / generation_tps * 1e9) if generation_tps > 0 else int(elapsed * 1e9)
        
        global LAST_METRICS
        LAST_METRICS = {
            "ttft_ms": int(ttft_s * 1000),
            "vram_gb": round(peak_memory_gb, 2),
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "provider": "mlx",
            "generation_tps": generation_tps,
        }
        
        return (generated_text, generation_time_ns, ttft_ns, completion_tokens, generation_time_ns)
    except Exception as e:
        return (f"ERROR: {e}", 0, 0, 0, 0)
```

### Caveats
- Each CLI call loads the model **fresh** — no model reuse across tests
- For 256-token tests: ~7-8 seconds per call (4s model load + 3s generation)
- For 32768-token tests: ~27 minutes per call at 20 t/s
- Stream buffer (`_stream_write`) won't show live tokens — only after completion
- The `--ignore-chat-template` flag means prompt must already have chat template applied if needed

### Expected TPS (CLI subprocess vs v5 benchmark)
| Model | CLI TPS | v5 TPS | Match |
|-------|---------|--------|-------|
| gemma3-4b | 117-120 | 121-131 | 93% ✅ |
| gemma3-12b | 59-60 | 49-52 | 115% ✅ |
| gemma4-26b-heretic | 75-80 | 95-104 | 75-80% ⚠️ |
| dawncr0w-35b | 57 | 70-74 | 77% ⚠️ |
| qwen3.6-35b-optiq | 55 | 68-71 | 78% ⚠️ |
| qwen3-next-80b | 39 | 27-28 | 140% 🔥 |

Small models (gemma3) match v5. Large models (gemma4, qwen3.6-35b) are 75-85% of v5 — possible macOS/MLX regression.
