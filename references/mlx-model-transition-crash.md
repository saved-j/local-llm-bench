# mlx Model Transition Crash Fix

## Problem
When transitioning between mlx models, using `del mlx_model` causes `UnboundLocalError` if the variable is referenced later in the cleanup section.

## Error
```
UnboundLocalError: cannot access local variable 'mlx_model' where it is not associated with a value
```

## Root Cause
The cleanup section checks `if prov == "mlx" and mlx_model is not None:` but `del mlx_model` removes the variable entirely, making the reference fail.

## Fix
Replace `del mlx_model` with `mlx_model = None`:

```python
# WRONG
del mlx_model
del mlx_tokenizer

# CORRECT
mlx_model = None
mlx_tokenizer = None
```

## Why This Works
The cleanup section checks `if prov == "mlx" and mlx_model is not None:` which handles `None` correctly. The `del` statement removes the variable entirely, causing `UnboundLocalError` when referenced.

## Location in Code
The cleanup section is in `main()` after each model completes:
```python
# Cleanup
if prov == "mlx" and mlx_model is not None:
    import gc
    import mlx.core as mx
    del mlx_model  # WRONG — use mlx_model = None
    gc.collect()
    mx.clear_cache()
```

## History
- 2026-06-10: Initial implementation used `del mlx_model` — caused crash on model transition
- 2026-06-10: Fixed by replacing with `mlx_model = None`
