# PYTHONPATH Leak → mtplx regex Crash

## Full error transcript from 2026-06-09 session

When running bench via `python3-mlx local-llm-bench.py`, PYTHONPATH leaked from
Python 3.14 to mtplx (Python 3.13), causing:

```
[5/6] Model load failed after 0.1s: ImportError: cannot import name '_regex' 
from partially initialized module 'regex'

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File ".../mtplx/server/openai.py", line 9875, in <module>
    main()
  [ ... through model_scheduler.py → runtime.py → mlx_lm → transformers → regex ... ]
ImportError: cannot import name '_regex' from partially initialized module 'regex'
  (/opt/homebrew/Cellar/mlx-lm/0.31.3_1/libexec/lib/python3.14/site-packages/regex/__init__.py)
```

## Why It Happens

1. `python3-mlx` wrapper sets `PYTHONPATH` to mlx-lm's **Python 3.14** site-packages
2. Bench script starts mtplx via `subprocess.Popen` → mtplx inherits PYTHONPATH
3. mtplx runs under **Python 3.13** (its venv) → loads mlx_lm from PYTHONPATH (3.14)
4. mlx_lm imports `transformers` from 3.14 → `regex` from 3.14
5. `regex._regex` C extension compiled for Python 3.14 → crash on 3.13
6. Circular import exception → fatal

## Version Mismatch

| Component | Python | Path |
|-----------|--------|------|
| Bench script (python3-mlx) | 3.14.5 | `/opt/homebrew/bin/python3.14` |
| mlx-lm (brew) | 3.14.5 | `.../Cellar/mlx-lm/.../lib/python3.14/` |
| mtplx venv | **3.13.13** | `/opt/homebrew/var/mtplx/venv-0.3.7/bin/python` |

## Fix

```python
mtplx_env = {k: v for k, v in os.environ.items() if k != "PYTHONPATH"}
subprocess.Popen([MTPLX_BIN, "quickstart", ...], env=mtplx_env)
```

## Context Window Verified

```json
GET /v1/models → {"context_length": 262144, "max_context_length": 262144}
mtplx-qwen36-27b-optimized-speed supports 256K tokens.
```
