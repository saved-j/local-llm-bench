# VRAM Measurement Approaches

## ollama — Streaming + Parallel Polling

**Problem:** Non-streaming mode returns response only after completion. By then, model may already be unloaded from VRAM.

**Solution:** Use streaming (`stream: True`) and poll `/api/ps` after each chunk.

```python
r = requests.post(f"{OLLAMA}/api/generate", json=body, stream=True)
vram_bytes = 0
for line in r.iter_lines():
    if line:
        chunk = json.loads(line)
        # Poll VRAM during generation
        ps = requests.get(f"{OLLAMA}/api/ps", timeout=1).json()
        for m in ps.get("models", []):
            if model_tag in m.get("name", ""):
                vr = m.get("size_vram", 0)
                if vr > vram_bytes:
                    vram_bytes = vr
```

**Fields:**
- `/api/ps` → `models[].size_vram` (bytes)
- Convert to GB: `vram_bytes / (1024**3)`

**Gotcha:** If model is unloaded between requests, `/api/ps` returns `{"models": []}` → VRAM = IDLE.

## mtplx — Via process PID RSS (NOT mtplx_stats)

**Problem (discovered 2026-06-09):** `mtplx_stats.active_memory_bytes` is NOT returned by the mtplx API. The field either doesn't exist or is always 0. Using it → VRAM always shows IDLE.

**Root cause:** mtplx runs in a SEPARATE Python process (3.13 venv, port 8099). The bench script runs in Python 3.14. `mx.get_active_memory()` called from the bench process does NOT see mtplx's Metal memory — it reports the bench's own (near-zero) usage.

**Solution:** Get mtplx process RSS via `ps -o rss=` using the PID captured at subprocess launch.

```python
MTPLX_PID = 0  # set after Popen

# When starting mtplx:
mtplx_proc = subprocess.Popen(cmd, ...)
global MTPLX_PID
MTPLX_PID = mtplx_proc.pid

# VRAM measurement:
def get_mtplx_vram():
    try:
        import subprocess
        out = subprocess.check_output(
            ["ps", "-o", "rss=", "-p", str(MTPLX_PID)],
            timeout=5, text=True
        ).strip()
        return int(out) / (1024**2) if out else 0  # KB → GB
    except:
        return 0
```

**Call this in ask_mtplx() AFTER the HTTP response, store in LAST_METRICS:**
```python
vram_gb = get_mtplx_vram()
LAST_METRICS = {
    "vram_gb": vram_gb,  # NOT from mtplx_stats
    ...
}
```

**Gotchas:**
- `ps -o rss=` returns KB on macOS, not bytes. Divide by 1024² for GB.
- If mtplx crashes mid-benchmark, `ps` returns empty → 0 → IDLE.
- RSS includes ALL process memory (model + Python runtime + shared libs), not just Metal VRAM. Expect ~15-16GB for a 27B model (matches disk size).
- `global MTPLX_PID` declaration MUST come BEFORE the assignment in the function.

## mlx — Via mx.get_active_memory()

**Works directly** because mlx model is loaded in the SAME process as the bench script:

```python
import mlx.core as mx
mem = mx.get_active_memory()  # bytes
vram_gb = mem / (1024**3)
```

**⚠️ DEPRECATED APIs (mlx ≥0.31):**
- `mx.metal.set_cache_limit` → `mx.set_cache_limit`
- `mx.metal.get_active_memory` → `mx.get_active_memory`
- `mx.metal.clear_cache` → `mx.clear_cache`

## Summary

| Provider | Source | Reliability | When measured |
|----------|--------|-------------|---------------|
| ollama | `/api/ps` polling | ✅ Reliable if model loaded | During generation (streaming) |
| mtplx | `ps -o rss=` on PID | ✅ Always available if process alive | After each request |
| mlx | `mx.get_active_memory()` | ✅ Always available | After generation |

### Why mtplx can't use mx.get_active_memory()

mtplx runs as a SEPARATE subprocess (Python 3.13, port 8099). The bench script (Python 3.14) calls `mx.get_active_memory()` in its OWN process context, which sees only its own Metal allocations (~0). The mtplx process's Metal memory is invisible from the bench process. That's why `ps -o rss=` (process RSS) is the correct approach — it reads the mtplx process's total memory footprint from the OS.

### Historical: active_memory_bytes approach (BROKEN)

```python
# THIS DOES NOT WORK — mtplx API doesn't return this field
mtplx_stats = usage.get("mtplx_stats", {})
active_mem = mtplx_stats.get("active_memory_bytes", 0)  # always 0
```

Stats files from 2026-06-09 show `vram=  IDLE` for ALL mtplx tests because of this.
