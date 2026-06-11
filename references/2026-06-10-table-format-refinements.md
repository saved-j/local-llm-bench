# Table Format Refinements (2026-06-10)

## Status Line — NO Duplicate Model Name

**WRONG (before user correction):**
```
[MTPLX] qwen3-5-4bit-15gb (15GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB free  Loaded: ✅ 15.8GB in VRAM  Ready: ✅

[OLLAMA] glm-4.7-flash:q4_K_M (19GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  loaded: ✅  Ready: ✅
```

**Problems user pointed out:**
- mtplx shows `0.0GB free` (should be `0.0GB in VRAM` for consistency)
- ollama doesn't show how much VRAM is loaded (`loaded: ✅` without GB value)
- Both lines have `GPU Mem Freed` which is fine, but format must be consistent

**CORRECT format:**
```
[MTPLX] qwen3-6-4bit-15gb (15GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  Loaded: ✅ 15.8GB in VRAM  Ready: ✅

[OLLAMA] glm-4.7-flash:q4_K_M (19GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  loaded: ✅ 18.6GB in VRAM  Ready: ✅

[MLX] gemma4-26b-heretic (13GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB in VRAM  Loaded: ✅ 13.2GB in VRAM  Ready: ✅
```

**Rules:**
1. **ALL three providers** must show the SAME format
2. `GPU Mem Freed` always shows `0.0GB in VRAM` (the amount of VRAM before loading, not "free")
3. `Loaded` always shows actual VRAM usage after model loaded (e.g. `15.8GB in VRAM`)
4. For ollama: VRAM comes from `/api/ps` response (ollama shows VRAM differently)
5. For mtplx: VRAM comes from `ps -o rss=` on mtplx PID
6. For mlx: VRAM comes from `mx.get_active_memory()`

## Model Name in Status Line — SHORT Tech Name

**User's example of what they want:**
```
qwen3.6-27b-4bit-16gb (youssofal)
glm4.7-flash-8bit-32gb (muxodious)
glm4.7-flash-4bit-17gb (huihui)
```

Parsed from config.json:
- `model_type` (e.g. `glm4_moe_lite`, `gemma4`, `qwen3_next`)
- Bits from `quantization_config.bits`
- Size from model directory size
- Author from HF repo org
- **JOINED with hyphens: `{model_type}-{bits}bit-{size}gb`**
- Example: `glm4_moe_lite-4bit-16gb`
- NOT the full HF repo path or made-up names

**PITFALL:** DO NOT use `format_model_name()` for table rows — use `shorten(label, width=22)` which gives `first 8 + .. + last 12`.

## Model Name in TABLE — shorten() ONLY

**User definitively stated (2026-06-10):**
```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat 
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- -----
GLM-4.7-..esy-mlx-8Bit Quick Start  5.5s    1738ms  40.3   29.6GB  59.3GB   16384  0.6   0.9  OK   
GLM-4.7-..esy-mlx-8Bit Trap         4.5s    243ms   56.5   29.6GB  59.3GB   16384  0.6   0.9  OK   
```

- `shorten(label, width=22)` — first 8 chars + `..` + last 12 chars
- **NO author/organization in table** — user explicitly said "не надо подписывать оллама и хуйхуй, убери это"
- **NO `format_model_name()` in table rows**
- Table column width: 22 chars (NOT 30, NOT 50 — user was angry about 50: "где ты планируешь сами результаты тестов писать бля??")

## Model Name in STATUS Line — Short Tech Name

**User preference for status line (2026-06-10):**
```
[MTPLX] qwen3-5-4bit-15gb (15GB)
```

The short tech name `qwen3-5-4bit-15gb` is used. NOT the full HF repo path.
The size in parens `(15GB)` is the model weight file size.

## Model Name in TABLE for ollama

**User said (2026-06-10):** "для оламы можно как есть, там они довольно ясные и не дублируются"

So ollama models use their tag as-is: `glm-4.7-flash:q4_K_M`, `qwen3.5:35b-a3b-coding-nvfp4`.

## Author NOT shown anywhere in output

User said (2026-06-10, multiple times):
- "не надо подписывать оллама и хуйхуй, убери это" (remove ollama/huihui labels from table)
- "я передумал, ты убого это сделала" (removed author from status line too)

**Author/organization is NEVER shown in stdout output.** It lives only in the model selection menu.
