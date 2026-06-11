# MLX Model Transition Bugs

## Bug 1: `del mlx_model` crashes on next model check (2026-06-10)
When transitioning between mlx models, the cleanup code used `del mlx_model` which removed the variable from local scope. The next iteration's check `if prov == "mlx" and mlx_model is not None:` crashed with `UnboundLocalError`.

### Fix
```python
# WRONG - removes variable from scope
del mlx_model
del mlx_tokenizer

# CORRECT - sets to None, keeps variable in scope
mlx_model = None
mlx_tokenizer = None
gc.collect()
mx.clear_cache()
```

## Bug 2: mlx_model not initialized before first use
If the first model in the queue is not mlx, `mlx_model` is never initialized. Later mlx model check crashes.

### Fix
Initialize before the loop:
```python
mlx_model = None
mlx_tokenizer = None
```

## GPU Cleanup Pattern (correct)
```python
# Between different providers: kill all
kill_provider("ollama")
kill_provider("mtplx")
mlx_model = None
mlx_tokenizer = None
gc.collect()
mx.clear_cache()

# Between same provider (mlx→mlx): only unload model
mlx_model = None
mlx_tokenizer = None
gc.collect()
mx.clear_cache()
```
