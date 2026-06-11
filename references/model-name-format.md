# Model Name Format

## STATUS LINE (2 lines, NO author)

```
[MLX] GLM-4.7-Flash-impotent-heresy-mlx-8Bit (59.3GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB free  Loaded: ✅ 29.6GB in VRAM  Ready: ✅
```

Line 1: `[PROVIDER] model-label (sizeGB)` — model label is the user-facing name from the model list. NOT parsed from config.json.  
Line 2: modality + GPU checks. NO model name here. NO author annotations anywhere.

For ollama: use model tag as-is: `glm-4.7-flash:q4_K_M (19GB)`

## TABLE ROWS (22 chars, `shorten()`, NO author)

**`format_model_name()` is NOT used for table rows.** Use `shorten(label, width=22)`.

```python
def shorten(name, width=22):
    if len(name) <= width:
        return name
    return name[:8] + ".." + name[-(width-10):]
```

**NO author/organization in table rows.** User: "не надо подписывать оллама и хуйхуй, убери это"

**Table width: 22 chars.** User: "Мне нахуй не всрались простыни в 50 символов"

Example:
```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     ...
---------------------- ------------ ------- ------- ------ ------- -------- ...
GLM-4.7-..esy-mlx-8Bit Quick Start  5.5s    1738ms  40.3   29.6GB  59.3GB   ...
GLM-4.7-..esy-mlx-8Bit Trap         4.5s    243ms   56.5   29.6GB  59.3GB   ...
```

## `format_model_name()` — STILL EXISTS for status line only

Used ONLY in the status header (line 1), NOT in table rows.

For mtplx: snapshot path → read config.json directly
For mlx: HF repo → look in HF cache config.json
For ollama: use tag as-is

Extracts: `model_type`, `quantization_config.bits`, `size_gb`
Returns: `{model_type}-{bits}bit-{size}gb`

But table uses `shorten(label)` — `format_model_name()` is dead code for table output.

## History of corrections (2026-06-09/10)

1. Original: full HF repo name (`MuXodious/GLM-4.7-Flash-impotent-heresy-mlx-8Bit`) — user: "СОКРАЩАЙ ЧТОБЫ ВЛЕЗЛО"
2. First fix: parsed from config.json (`glm4-moe-lite-4bit-16gb`) at 22 chars
3. Second: expanded to 50 chars with author — user: "Мне нахуй не всрались простыни в 50 символов"
4. Third: `shorten()` with author annotations — user: "не надо подписывать оллама и хуйхуй"
5. **FINAL: `shorten(label, width=22)`, NO author anywhere**
