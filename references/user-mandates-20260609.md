# User Mandates — Sessions 2026-06-09/10

## Status Line Format (CORRECTED multiple times, FINAL 2026-06-10)

**TWO lines — NOT one, NOT three. NO model name on line 2:**

```
[OLLAMA] glm-4.7-flash:q4_K_M (19GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  loaded: ✅  Ready: ✅
```

Line 1: `[PROVIDER] label (sizeGB)` — label is the user-facing model tag. NO author.
Line 2: `  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: {status} {mem}GB in VRAM  loaded: {status}  Ready: {status}`
- NO author/organization anywhere in output
- NO model name on line 2 (user: "тебя ничего не смущает?" about duplicate names)

**Status checkmarks are REAL, verified:**
- GPU Mem Freed: `mx.get_active_memory()` / `ps -o rss=` / `/api/ps` → < 200MB
- Loaded: VRAM > 1GB after load
- Ready: MTPLX `/v1/models` → 200, MLX model loaded, Ollama `/api/tags`

## Table Format (FINAL — CORRECTED 10+ times, 2026-06-10)

**ONLY `shorten(label, width=22)` — NOT `format_model_name()`:**

```python
def shorten(name, width=22):
    if len(name) <= width:
        return name
    return name[:8] + ".." + name[-(width-10):]
```

**NO author/organization in table.** User: "не надо подписывать оллама и хуйхуй, убери это, я передумал"
**Table column width: 22 chars.** NOT 30, NOT 50. User: "Мне нахуй не всрались простыни в 50 символов"

Example:
```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat 
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- -----
GLM-4.7-..esy-mlx-8Bit Quick Start  5.5s    1738ms  40.3   29.6GB  59.3GB   16384  0.6   0.9  OK   
GLM-4.7-..esy-mlx-8Bit Trap         4.5s    243ms   56.5   29.6GB  59.3GB   16384  0.6   0.9  OK   
glm-4.7-flash:q4_K_M   Quick Start  13.5s   8116ms  89.2   18.6GB  19GB     16384  0.6   0.9  OK   
glm-4.7-flash:q4_K_M   Trap         12.9s   296ms   87.9   18.6GB  19GB     16384  0.6   0.9  OK   
```

## Provider Cleanup (CORRECTED 2026-06-09, refined 2026-06-10)

**On provider switch (ollama → mtplx → mlx):**
Kill ALL three: user mandate "Перед загрузкой каждого инференса грохнуть нужно все три, каждый раз"
```python
kill_provider("ollama"); kill_provider("mtplx")
del mlx_model; gc.collect(); mx.clear_cache()
time.sleep(2)
```

**Within same provider (ollama → ollama, mlx → mlx):**
Only unload model, NOT kill inference:
- MLX: `del model; gc.collect(); mx.clear_cache()` (keep mlx alive)
- Ollama: `keep_alive=0` on old model (keep ollama serve alive)
- MTPLX: must restart server (no hot-swap) but don't touch ollama/mlx
- User: "при загрузке одной за других моделей внутри одного инференса, выгружать только модель, а не весь инференс"

## Token Limits (CORRECTED 10+ times)

- Normal mode: ZERO limits. `max_tok=0`, no `ans[:N]`. Full EOS generation.
- `--fast` mode ONLY: `max_tok=100` tests, `max_tok=50` censorship, `ans[:200]`
- mlx stream_generate hidden default 256 → MUST override to 100000
- User: "я тебе 10 раз говорил убрать лимит на токены и оставить его только для fast-mode"

## LCM Removed (2026-06-09)

Complete removal: "удаляй lcm вообще. полностью. из системы. бесследно."
- `fresh_tail_count=64` silently dropped messages (user lost GitHub username)
- Context now by Session Hygiene alone (999999 = off)
- Honesty rule when user says "я тебе уже говорил" and you can't find: be honest, don't pretend

## Hardcoding Rules

- NEVER hardcode model names, quantization formats, or filter patterns
- Only `mtplx` remains as provider-specific filter in SKIP_PATTERNS
- User: "я постоянно удаляю и добавляю модели туда-сюда, всё нужно чтобы само собой индексировалось"
- DO NOT add quantization formats (nvfp4) to skip patterns — third-party conversions work

## GitHub

- saved-j/ollama-bench — repo location (confirmed 2026-06-09)
- User says saved-j is NOT their personal nick
- markvictorson is also NOT their GitHub username (corrected by user)
