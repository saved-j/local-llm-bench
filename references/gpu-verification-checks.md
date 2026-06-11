# GPU Memory Verification — Real Checks (Not Decorative)

## Problem
Status lines (GPU Mem Freed, Loaded, Ready) were printing ✅ without actually verifying anything.
User was furious: "А они ДОЛЖНЫ СУКА БЫТЬ!!!!"

## Implementation

### Before each provider:
1. Kill orphan processes: `kill_provider("ollama")`, `kill_provider("mtplx")`, sleep 2s
2. For mlx: `del mlx_model; gc.collect(); mx.clear_cache()` to unload previous model
3. Check VRAM freed: `mx.get_active_memory() < 0.2` GB

### Ollama:
```python
# Cleanup
kill_provider("ollama")
time.sleep(2)
ensure_ollama()

# Check GPU mem freed
mem_before = 0
try:
    r = requests.get(f"{OLLAMA}/api/ps", timeout=5)
    mem_before = sum(m.get("size_vram", 0) for m in r.json().get("models", []))
except:
    pass
gpu_freed = mem_before < 200 * 1024 * 1024  # < 200MB
```

### MTPLX:
```python
# Cleanup
kill_provider("ollama")
kill_provider("mtplx")
time.sleep(2)

# Check GPU mem freed (via process RSS)
mem_before = get_mtplx_vram()  # ps -o rss= on PID
gpu_freed = mem_before < 0.2

# After server ready:
mem_after = get_mtplx_vram()
loaded = mem_after > 1.0  # > 1GB = model loaded
```

### MLX:
```python
# Cleanup previous model
if mlx_model is not None:
    del mlx_model
    del mlx_tokenizer
    mlx_model = None
    mlx_tokenizer = None
    import gc
    gc.collect()
    try:
        import mlx.core as mx
        mx.clear_cache()
    except:
        pass

# Check GPU mem freed
mem_before = get_mlx_vram()  # mx.get_active_memory()
gpu_freed = mem_before < 0.2

# After load:
mem_after = get_mlx_vram()
loaded = mem_after > 1.0
```

## Status Output Format
```
[MTPLX] qwen3.6-27b-mtplx-15gb (Youssofal)
  text ✅ vision ❌ audio ❌ video ❌
  GPU Mem Freed: ✅ 0.0GB still loaded
  Loaded: ✅ 15.8GB in VRAM
  Ready: ✅
```

On failure:
```
  GPU Mem Freed: ❌ 18.5GB still loaded
  Loaded: ❌ 0.0GB in VRAM
  Ready: ❌ Timeout
```

## Key Points
- ✅ only when CONFIRMED by real measurement
- ❌ with actual values when check fails
- Never print ✅ without verifying
- User: "если реальных проверок нет то и писать ничего не надо"
