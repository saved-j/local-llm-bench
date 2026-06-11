# Provider Cleanup Pattern

## User Mandate (2026-06-09)
"Перед загрузкой каждого инференса грохнуть нужно все три, каждый раз, на случай если они в памяти висят."

## Implementation

```python
# BEFORE EACH MODEL — kill all three
kill_provider("ollama")
kill_provider("mtplx")
if mlx_model is not None:
    del mlx_model; del mlx_tokenizer
    mlx_model = None; mlx_tokenizer = None
    gc.collect()
    try:
        import mlx.core as mx
        mx.clear_cache()
    except:
        pass
time.sleep(2)
```

## kill_provider Implementation

```python
def kill_provider(prov):
    if prov == "ollama":
        subprocess.run("pkill -9 -f 'ollama runner'", shell=True, capture_output=True)
        subprocess.run("pkill -9 -f ollama_llama_server", shell=True, capture_output=True)
    elif prov == "mtplx":
        subprocess.run("pkill -9 -f mtplx", shell=True, capture_output=True)
    time.sleep(1)
```

## Verification

After cleanup, verify GPU memory is actually freed:
- ollama: `requests.get(f"{OLLAMA}/api/ps")` → sum(size_vram) < 200MB
- mtplx: `ps -o rss=` on any mtplx PID → < 200MB  
- mlx: `mx.get_active_memory()` → < 200MB

## Why Kill All Three Every Time

User was FURIOUS about orphan processes:
1. "Перед запуском инференса нужно проверить, нет ли сирот в памяти"
2. "Перед загрузкой следующей модели ТОГО ЖЕ инференса — убедиться что предыдущий выгрузился"
3. "Перед загрузкой следующего ИНФЕРЕНСА — убедиться что предыдущий убит"

Even within same provider, previous model might not have fully unloaded.
`kill_provider` is idempotent — safe to call even if nothing is running.
