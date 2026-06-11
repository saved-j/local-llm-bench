# VRAM Verification — Implementation Details

## Why Real Verification Matters

User was FURIOUS about decorative status checkmarks:
"А они ДОЛЖНЫ СУКА БЫТЬ!!!! 1. Перед запуском инференса нужно проверить, нет ли сирот в памяти. 
2. Перед загрузкой следующей модели ТОГО ЖЕ инференса — убедиться что предыдущий выгрузился. 
3. Перед загрузкой следующего ИНФЕРЕНСА — убедиться что предыдущий убит."

## Provider-Specific VRAM Checks

### ollama — `/api/ps`
```python
def check_vram_ollama():
    try:
        r = requests.get(f"{OLLAMA}/api/ps", timeout=3)
        models = r.json().get("models", [])
        if not models:
            return 0  # No models loaded → VRAM freed
        total_vram = sum(m.get("size_vram", 0) for m in models)
        return total_vram / (1024**3)
    except:
        return -1
```

- GPU Freed: `/api/ps` returns empty → 0GB (< 200MB) → ✅
- Loaded: `/api/ps` shows VRAM > 1GB → ✅
- Ready: `/api/tags` → 200 OK → ✅

### mlx — `mx.get_active_memory()`
```python
import mlx.core as mx
vram_gb = mx.get_active_memory() / (1024**3)
```

- GPU Freed: `mx.get_active_memory()` < 200MB → ✅
- Loaded: `mx.get_active_memory()` > 1GB after model load → ✅
- Ready: model loaded successfully → ✅

### mtplx — `ps -o rss=` on PID
```python
def get_mtplx_vram(mtplx_pid):
    out = subprocess.check_output(
        ["ps", "-o", "rss=", "-p", str(mtplx_pid)],
        timeout=5, text=True
    ).strip()
    return int(out) / (1024**2)  # KB → GB
```

- `mtplx_stats.active_memory_bytes` is NOT returned by mtplx API (always 0)
- mtplx runs in separate Python 3.13 process — `mx.get_active_memory()` from bench doesn't see it
- **FIX:** Store PID at subprocess launch: `global MTPLX_PID; MTPLX_PID = mtplx_proc.pid`
- GPU Freed: `ps -o rss=` < 200MB → ✅
- Loaded: `ps -o rss=` > 1GB → ✅
- Ready: `/v1/models` → 200 OK → ✅

## Provider Cleanup — Three-State Pattern

```
prev_prov = None
for prov, label, model_id, size_gb in selected:
    if prov != prev_prov:
        # PROVIDER SWITCH: kill ALL three
        kill_provider("ollama")   # pkill -9 ollama runner + server
        kill_provider("mtplx")    # pkill -9 mtplx
        del mlx_model; gc.collect(); mx.clear_cache()
        time.sleep(2)
        prev_prov = prov
    else:
        # SAME PROVIDER: only unload MODEL
        if prov == "mlx":
            del mlx_model; gc.collect(); mx.clear_cache()
        elif prov == "ollama":
            # keep_alive=0 unloads model, keeps server
            requests.post(f"{OLLAMA}/api/generate",
                json={"model": model_id, "keep_alive": 0})
            time.sleep(2)
        # mtplx: no hot-swap — server restart handles this
```

## Verification Loop

```python
def verify_gpu_freed(prov, prev_prov, timeout=15):
    """Poll until VRAM freed or timeout."""
    for _ in range(timeout):
        if prov == "ollama":
            vram = check_vram_ollama()
        elif prov == "mlx":
            vram = mx.get_active_memory() / (1024**3)
        elif prov == "mtplx":
            vram = get_mtplx_vram(MTPLX_PID)
        if vram < 0.2:  # < 200MB
            return True
        time.sleep(1)
    return False  # Timeout — VRAM still in use
```

Always poll (don't sleep fixed time) — some models release memory quickly, others take 15-30s.
