# 2026-06-10: Table & Status Format Corrections

## Context
During a benchmark run, the user verified the output format was finally correct. Key corrections:

## 1. Status Line — NO duplicate model name
**CORRECTION:** Model name was appearing on BOTH lines:
```
[MTPLX] qwen3-5-4bit-15gb (15GB)  text ✅ ...    ← correct
[MTPLX] qwen3-5-4bit-15gb (15GB)  ✅ GPU Mem ... ← WRONG: model name duplicated
```
**FIX:** 
```
[MTPLX] qwen3-5-4bit (15GB)
  text ✅ vision ❌ audio ❌ video ❌  GPU Mem Freed: ✅ 0.0GB free  Loaded: ✅ 15.8GB in VRAM  Ready: ✅
```
User: "[MTPLX] qwen3-5-4bit-15gb (15GB) — тебя ничего не смущает? дублируется два раза одна и та же инфа"

## 2. Table — `shorten()` ONLY, NO `format_model_name()`
**CORRECTION:** Table was using `format_model_name()` which produces different output than `shorten(label)`.
**FIX:** `short = shorten(label, width=22)` — model name in table is simply the shortened LABEL from the model list, not parsed from config.json.
User accepted: `GLM-4.7-..esy-mlx-8Bit` format as correct.

## 3. NO author annotations anywhere
**CORRECTION:** Author annotations `(ollama)`, `(huihui-ai)` etc. were in output.
**FIX:** Removed completely. No `(ollama)` after table block. No `(huihui-ai)` in status line.
User: "не надо подписывать оллама и хуйхуй, убери это, я передумал, ты убого это сделала"

## 4. Ollama model names as-is
**CORRECTION:** Don't parse ollama model tags. Leave as-is: `glm-4.7-flash:q4_K_M`, `qwen3.5:35b-a3b-coding-nvfp4`.

## 5. Provider cleanup refined
**CORRECTION (from same session):**
- Between providers: kill ALL three
- Within same provider: only unload model (user: "при загрузке одной за других моделей внутри одного инференса, выгружать только модель, а не весь инференс")

## Verification
User ran benchmark and saw correct output:
```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat 
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- -----
GLM-4.7-..esy-mlx-8Bit Quick Start  5.5s    1738ms  40.3   29.6GB  59.3GB   16384  0.6   0.9  OK   
GLM-4.7-..esy-mlx-8Bit Trap         4.5s    243ms   56.5   29.6GB  59.3GB   16384  0.6   0.9  OK   
```
