# MetricsCollector — LAST_METRICS Implementation

## Architecture

Single global dict `LAST_METRICS` filled by each ask_* function after every request.
Set before return so main loop can read it immediately.

```python
LAST_METRICS = {}  # module-level, filled by ask_* functions

def ask_ollama(model_tag, prompt, max_tok=500):
    ...
    global LAST_METRICS
    LAST_METRICS = {
        "ttft_ms": int(d.get("prompt_eval_duration", 0) / 1e6),
        "vram_gb": 0,  # ollama doesn't expose VRAM
        "prompt_tokens": d.get("prompt_eval_count", 0),
        "completion_tokens": d.get("eval_count", 0),
        "provider": "ollama",
    }
```

## Provider-specific fields

### ollama
- ttft_ms: `prompt_eval_duration / 1e6` (nanoseconds → ms)
- vram_gb: always 0 (no API)
- Source: `/api/generate` JSON response

### mtplx
- ttft_ms: `mtplx_stats.ttft_s * 1000` (seconds → ms)
- vram_gb: `mtplx_stats.active_memory_bytes / (1024**3)`
- full mtplx_stats dict saved for detail logging
- Source: `/v1/completions` response → `usage.mtplx_stats`

### mlx
- ttft_ms: wall clock to first yield from `stream_generate()`
- vram_gb: `mx.metal.get_active_memory() / (1024**3)` after generation
- Source: manual timing + mlx.core API

## Stats file output format

```
short_model_name | test_name     | 110.5 t/s | ttft=177ms | vram= 14.2GB | ptok=12 | ctok=45 | ollama
short_model_name | test_name     |  50.0 t/s | ttft=5951ms | vram= 16.0GB | ptok=1 | ctok=10 | mtplx | draft_accept=5/4
short_model_name | test_name     |  31.2 t/s | ttft=112ms | vram=  8.5GB | ptok=15 | ctok=35 | mlx
```

mtplx extra: `draft_accept=<accepted>/<verify_calls>` — shows MTP efficiency.

## Updating

When adding a new provider or metric:
1. Add the metric to the ask_* function's LAST_METRICS dict
2. Add the display logic in main() where last_metrics are read
3. Add stats_file writing for the new field
4. Add to the table header if it becomes a column
