# 📊 Local LLM Benchmark — Full Analysis

## Performance (avg TPS, 10 tests each)

gemma-3-4b          ████████████████████ 151.1 t/s  ← fastest
Qwen3.6-5bpw        █████████████████░░░ 109.0 t/s
gemma-4-heretic      █████████████████░░░ 106.2 t/s
qwen3.5-coding      ████████████████░░░░ 102.3 t/s
Qwen3.6-OptiQ       ███████████████░░░░░  98.6 t/s
Qwen3-Next-80B      ██████████████░░░░░░  93.3 t/s
gemma-4-qat-6bit    █████████████░░░░░░░  83.1 t/s
glm-4.7-flash       ███████████░░░░░░░░░  71.7 t/s
gemma-4-qat-4bit    █████████░░░░░░░░░░░  59.9 t/s
Huihui-GLM          █████████░░░░░░░░░░░  59.3 t/s
gemma-3-12b         █████████░░░░░░░░░░░  58.5 t/s
GLM-4.7-REAP        █████████░░░░░░░░░░░  58.0 t/s
GLM-4.7-heresy      ████████░░░░░░░░░░░░  56.1 t/s
Qwen3.6-MTPLX       ██████░░░░░░░░░░░░░░  40.6 t/s

## Uncensoredness (higher = more permissive)

gemma-4-heretic      ████████████████████ 100% (20/20)
Qwen3.6-5bpw        ████████████████████ 100% (20/20)
Huihui-GLM          ████████████████░░░░  80% (16/20)
GLM-4.7-heresy      ███████████████░░░░░  75% (15/20)
GLM-4.7-REAP        ████░░░░░░░░░░░░░░░░  20% (4/20)
glm-4.7-flash       ███░░░░░░░░░░░░░░░░░  15% (3/20)
qwen3.5-coding      ██░░░░░░░░░░░░░░░░░░  10% (2/20)
Qwen3-Next-80B      ██░░░░░░░░░░░░░░░░░░  10% (2/20)
gemma-3-4b          ██░░░░░░░░░░░░░░░░░░  10% (2/20)
gemma-4-qat-6bit    █░░░░░░░░░░░░░░░░░░░   5% (1/20)
gemma-4-qat-4bit    ░░░░░░░░░░░░░░░░░░░░   0% (0/20)
Qwen3.6-OptiQ       ░░░░░░░░░░░░░░░░░░░░   0% (0/20)
gemma-3-12b         ░░░░░░░░░░░░░░░░░░░░   0% (0/20)
Qwen3.6-MTPLX       ░░░░░░░░░░░░░░░░░░░░   0% (0/20)
llama3.2-vision     ░░░░░░░░░░░░░░░░░░░░   0% (0/20)

## Quality Scores (10-point scale, based on answer analysis)

Model                   Style  Depth  Notes
─────────────────────── ────── ────── ──────────────────────────────────────
Qwen3-Next-80B          9.5    9.5    Exceptional depth, rich vocabulary
Qwen3.6-MTPLX           8.0    8.5    Consistent quality, well-structured
qwen3.5-coding          7.5    7.0    Good technical output, dry style
glm-4.7-flash           7.0    6.5    Reliable but generic responses
gemma-4-heretic         7.0    6.0    Creative, uncensored, occasionally verbose
Qwen3.6-OptiQ           7.0    6.5    Decent quality, some hallucinations
Qwen3.6-5bpw            6.5    6.0    OK quality, can be repetitive
GLM-4.7-heresy          6.5    6.0    Good uncensored output, verbose CoT
Huihui-GLM              6.0    5.5    OK quality, verbose
gemma-4-qat-4bit        6.0    5.5    OK quality, some artifacts
GLM-4.7-REAP            5.5    5.0    OK but verbose
gemma-4-qat-6bit        5.5    5.0    OK but verbose
gemma-3-4b              5.0    4.5    Fast but hallucinates, crude output
gemma-3-12b             5.0    4.5    Fast but shallow, some artifacts

## Recommendations

### Best for Speed
gemma-3-4b (151 t/s) — Use for quick tasks, not for quality

### Best for Quality
Qwen3-Next-80B (93 t/s) — Best depth, best style, but large (45GB)

### Best for Uncensored
gemma-4-heretic (106 t/s) — 100% uncensored, good balance
Qwen3.6-5bpw (109 t/s) — 100% uncensored, good speed

### Best All-Around
Qwen3.6-MTPLX (40 t/s) — Best quality, best consistency, but slow
glm-4.7-flash (71 t/s) — Good balance of speed and quality

### Models to Remove (overlapping/weak)
- gemma-3-12b (58 t/s, 0% uncensored, weak quality)
- gemma-4-qat-6bit (83 t/s, 5% uncensored, verbose)
- GLM-4.7-REAP (58 t/s, 20% uncensored, weak quality)

### Keep These
- gemma-3-4b (speed demon)
- Qwen3-Next-80B (quality king)
- gemma-4-heretic (uncensored + fast)
- Qwen3.6-5bpw (uncensored + fast)
- Qwen3.6-MTPLX (best quality)
- glm-4.7-flash (reliable)
- qwen3.5-coding (good balance)
