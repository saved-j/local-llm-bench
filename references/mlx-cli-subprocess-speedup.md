# mlx Inference Speed: CLI Subprocess vs In-Process

## Discovery (2026-06-11)
Running `mlx_lm.generate` as a CLI subprocess gives 1.6-1.9x higher TPS than calling `generate()` in-process from the same Python script.

### Benchmark Results (gemma4-26b-heretic, max_tokens=256)
| Method | TPS | Notes |
|--------|-----|-------|
| `python3-mlx -m mlx_lm.generate` (CLI) | 73-80 t/s | Fresh process each time |
| `generate()` in-process | 44-48 t/s | Same mlx-lm, same model |
| `generate()` in clean env | 44-48 t/s | env -i, same result |
| mlx-lm 0.29.1 in-process | 47.9 t/s | Version doesn't matter |
| mlx-lm 0.27.0 in-process | N/A | Can't load gemma4 |

### Small models (gemma3-4b, max_tokens=256)
| Method | TPS | v5 result |
|--------|-----|-----------|
| CLI subprocess | 117-120 t/s | 121-131 t/s ✅ |
| In-process | 43-48 t/s | — |

### Root Cause
CLI runs mlx in isolated process with clean Metal runtime state. In-process calls share Metal context with previous model loads, memory allocations, etc. The exact mechanism is unclear but the effect is consistent and reproducible.

### Implementation in ask_mlx
```python
def ask_mlx(model_id, prompt, max_tok=0):
    """Use CLI subprocess for 1.6-1.9x TPS boost."""
    mlx_path = "/opt/homebrew/Cellar/mlx-lm/0.31.3_1/libexec/lib/python3.14/site-packages"
    env = {
        "HOME": os.environ.get("HOME", "/Users/saved"),
        "PATH": "/opt/homebrew/bin:/usr/bin:/bin",
        "PYTHONPATH": mlx_path,
    }
    cmd = [
        sys.executable, "-m", "mlx_lm.generate",
        "--model", model_id,
        "--prompt", prompt,
        "--max-tokens", str(max_tok if max_tok > 0 else 131072),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True,
                          timeout=900, env=env)
    # Parse: "Generation: 256 tokens, 80.150 tokens-per-sec"
    for line in result.stdout.split("\n"):
        if "Generation:" in line:
            parts = line.split(",")
            generation_tps = float(parts[1].strip().split()[0])
    # Parse: "Prompt: 25 tokens, 133.817 tokens-per-sec"
    for line in result.stdout.split("\n"):
        if "Prompt:" in line:
            prompt_tokens = int(line.split("tokens")[0].split()[-1])
            prompt_tps = float(line.split(",")[1].strip().split()[0])
    # Parse: "Peak memory: 14.350 GB"
    for line in result.stdout.split("\n"):
        if "Peak memory:" in line:
            peak_memory_gb = float(line.split(":")[1].strip().split()[0])
    
    # Extract generated text (between "==========\n" markers)
    # ...
    
    # Return metrics using generation_tps for accurate TPS
    generation_time_ns = int(completion_tokens / generation_tps * 1e9)
    return (generated_text, generation_time_ns, ttft_ns, completion_tokens, generation_time_ns)
```

### Caveats
- CLI subprocess adds ~0.5-1s overhead per call (process startup)
- For short responses (<100 tokens), overhead may negate speedup
- For long responses (32K tokens), the 1.6-1.9x speedup is significant
- Stream buffer write happens after generation (not per-token) with CLI approach
- System load (e.g. runaway smbd) can reduce CLI speed to 60-70 t/s

### smbd CPU Issue
Runaway `/usr/sbin/smbd` can consume 1400%+ CPU. While mlx inference is GPU-bound, heavy CPU load causes:
- Thermal throttling (CPU heat → GPU throttling)
- Memory pressure
- I/O contention
Fix: `sudo kill -9 <smbd_pid>` or reboot. Can't be done without sudo.
