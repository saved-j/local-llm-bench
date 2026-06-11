# CLI Output Format

## Status Lines (TWO lines per model — user corrected multiple times)

```
[PROVIDER] label (sizeGB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  loaded: ✅  Ready: ✅
```

Line 1: `[PROVIDER] label (sizeGB)` — NO author
Line 2: `  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: {status} {mem}GB in VRAM  loaded: {status}  Ready: {status}`

Status checkmarks are REAL (verified):
- GPU Mem Freed: VRAM < 200MB
- Loaded: VRAM > 1GB after load
- Ready: provider-specific health check

## Table Header

```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat 
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- -----
```

Width: 22 chars for model name. NOT 30, NOT 50. User: "Мне нахуй не всрались простыни в 50 символов длиной"

## Table Rows — `shorten()` function, 22 chars, middle-dots

```
GLM-4.7-..esy-mlx-8Bit Quick Start  5.5s    1738ms  40.3   29.6GB  59.3GB   16384  0.6   0.9  OK   
GLM-4.7-..esy-mlx-8Bit Trap         4.5s    243ms   56.5   29.6GB  59.3GB   16384  0.6   0.9  OK   
```

**Rules:**
- `shorten(label, width=22)` → first 8 chars + `..` + last 12 chars
- Example: `GLM-4.7-..esy-mlx-8Bit` (22 chars)
- **NO author** in table rows. NO `(ollama)`, `(huihui-ai)`, `(mlx-community)`.
  User: "не надо подписывать оллама и хуйхуй, убери это, я передумал"
- Model name repeated on EVERY row (not blank for subsequent rows)
- For ollama: use model tag as-is (e.g. `glm-4.7-flash:q4_K_M`)
- The `format_model_name()` function was REMOVED from table output — `shorten(label)` is used instead
- `short = shorten(label)` is the correct code

## shorten() Function

```python
def shorten(name, width=22):
    if len(name) <= width:
        return name
    return name[:8] + ".." + name[-(width-10):]
```

Keeps first 8 chars + `..` + last 12 chars (for width=22).

## Example Full Output

```
[MTPLX] Qwen3.6-27B-MTPLX-Optimized-Speed (15GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB free  Loaded: ✅ 15.2GB in VRAM  Ready: ✅

Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat 
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- -----
Qwen3.6-..imized-Speed Quick Start  0.6s    0ms     12.4   15.8GB  15GB     16384  0.6   0.9  OK   
Qwen3.6-..imized-Speed Trap         293.6s  0ms     42.5   15.0GB  15GB     16384  0.6   0.9  OK   
Qwen3.6-..imized-Speed Expertise    74.6s   0ms     39.7   15.0GB  15GB     16384  0.6   0.9  OK   
```

## What NOT to Do

- ❌ `format_model_name()` in table rows (use `shorten(label)` instead)
- ❌ Full HF repo name in table rows (e.g. `MuXodious/GLM-4.7-Flash-impotent-heresy-mlx-8Bit`)
- ❌ Author/organization in table rows (NO `(ollama)`, `(huihui-ai)`, `(mlx-community)`)
- ❌ 30-char or 50-char column widths (use 22 chars)
- ❌ Decorative status checkmarks (must be verified)
- ❌ Duplicate model name on status lines
- ❌ One-line status (must be TWO lines)
