---
name: local-llm-comprehensive-bench
description: "Local LLM Comprehensive Benchmark — multi-provider (ollama|mtplx|mlx-lm), 10 hard tests + 20 censorship, TTFT/VRAM/mtplx_stats metrics. For Apple Silicon."
category: mlops
tags: [benchmark, llm, ollama, mlx, mtplx, apple-silicon, censorship, metrics]
platforms: [macos]
requirements:
  - ollama (running on localhost:11434)
  - mlx-lm via brew (with sys.path injection in script header)
  - mtplx 0.3.7+ (optional, for MTP models)
---

# Local LLM Comprehensive Benchmark

## Quick Start
```bash
cd ~/.hermes/skills/local-llm-comprehensive-bench
python3-mlx local-llm-bench.py --all --no-chat
```

## Key Flags
- `--all` — all models, skip interactive menu
- `--no-chat` — disable Telegram progress
- `--performance` — skip censorship tests
- `--fast` — max_tok=100, truncate=200 (TPS only)
- `--model <id>` — single model by ID/path
- `--models "name1,name2"` — multiple models by comma-separated names
- `--suffix=<name>` — custom filename suffix

## Architecture

### Providers
- **ollama**: Streaming via `/api/generate`, parallel VRAM polling
- **mtplx**: Blocking POST to `/v1/completions` (no streaming — mtplx SSE doesn't return usage)
- **mlx**: CLI subprocess via `mlx_lm.generate` (1.6-2x faster than in-process)

### TPS Measurement
- **ollama**: `eval_count / eval_duration` from done chunk
- **mtplx**: `completion_tokens / total_time` from usage
- **mlx**: `generation_tps` from CLI output (excludes model loading time)

### Stream Buffer
- `/tmp/bench_stream.txt` — real-time generation output
- Reset per test with header: `=== [provider] model | test_name ===`
- ollama: writes per chunk
- mtplx: writes full response after completion
- mlx: CLI doesn't write to buffer (future: subprocess with stream capture)

## Model Detection
- `ollama ls` — installed ollama models
- `~/.cache/huggingface/hub/models--*` — mlx HF cache
- SKIP_PATTERNS: whisper, flux, ltx, sdxl, vae, clip, tts, etc.
- Models < 1GB skipped (MTP headers, incomplete)
- NVFP4 NOT filtered — third-party conversions work fine

## Key Pitfalls

### mtplx_stats Location
`mtplx_stats` is at TOP LEVEL of JSON response, NOT inside `usage`:
```python
mtplx_stats = d.get("mtplx_stats", {})  # ✅ Correct
# NOT usage.get("mtplx_stats", {})  ❌ Wrong
```
See `references/mtplx-streaming-investigation.md` for details.

### mlx stream_generate max_tokens
Default is 256. Must override:
```python
gen_kw = {"max_tokens": max_tok} if max_tok > 0 else {"max_tokens": 131072}
```

### mlx Performance: Use CLI Subprocess
In-process `generate()` gives 43-48 t/s. CLI subprocess gives 73-80 t/s (1.6-2x faster).
See `references/mlx-performance-investigation.md` for full investigation.

### mlx_model Cleanup
Use `mlx_model = None` NOT `del mlx_model` — avoids UnboundLocalError on provider switch.

### Trap Test Timing
mtplx Trap generates 13324 tokens at ~43 t/s = ~5 minutes. Don't kill bench if only Quick Start completed — wait 7+ minutes.

### Full Test = ALL models + ALL tests + censorship
`--performance` skips censorship. Default (no flag) runs full test with 20 censorship questions.
User corrected: "полный тест" means everything, not performance-only.

### Modality Detection for ollama Models
For ollama models (no config.json): Check model name for "vision", "audio", "video" keywords.
Example: `llama3.2-vision:11b-instruct-q4_K_M` → `text vision` because name contains "vision".

### Process Management — CRITICAL
- **NEVER kill download processes** (curl, hf download) — Mark furious when downloads interrupted. Check `ps aux | grep -E 'curl|huggingface|hf.*download'` BEFORE any kill.
- **NEVER kill bench processes without checking PID** — verify it's an orphan first
- Kill all 3 providers BETWEEN models (not within same provider)
- "Полный тест" = ALL 10 tests + ALL 20 censorship + ALL models. NO --performance unless explicitly asked.
- Don't tell user what's "normal" for their machine — measure and report, they know their hardware
- **Don't explain when user asks to do something** — just execute. User gets angry when I narrate instead of acting. Report results, not plans.

### Modality Detection (FIXED 2026-06-11)
`detect_modality` checks `snapshots/<hash>/config.json` if root `config.json` doesn't exist.
Gemma4 models correctly show `vision ✅` (have `image_token_id`, `vision_soft_tokens_per_image`).
Old bug: only checked root `config.json` → HF cache models showed `vision ❌` incorrectly.

**For ollama models** (no config.json): Check model name for "vision", "audio", "video" keywords.
Example: `llama3.2-vision:11b-instruct-q4_K_M` → `text vision` because name contains "vision".

### HuggingFace Lock Files
Lock files remain even after deleting model folders. Must clear `.locks/` directory before retrying downloads.
Mirror downloads (hf-mirror.com) may fail with SSL errors — use direct HuggingFace.

### Hardcoded Paths (FIXED 2026-06-11)
NEVER hardcode `/Users/saved/...` or `/opt/homebrew/...` in scripts.
- Use `os.path.expanduser("~")` for user home
- Use `os.path.dirname(os.path.abspath(__file__))` for script-relative paths (e.g. RESULTS_DIR)
- Use `os.popen("which mtplx").read().strip()` for binaries with fallback
- Auto-detect brew mlx-lm path: `brew --prefix mlx-lm` then walk for mlx_lm package

### Whisper Modality Detection (FIXED 2026-06-11)
whisper config.json has `architectures: None` but `model_type: "whisper"`.
Detection must check BOTH:
```python
arch = cfg.get("architectures", [""])[0] if cfg.get("architectures") else ""
model_type = cfg.get("model_type", "")
audio = "whisper" in arch.lower() or "whisper" in model_type.lower()
```

## Benchmark File Format

The script generates 4 files per run:
- `LLB-Results-{timestamp}.txt` — main table (Model, Test, Time, TTFT, TPS, RAM, Disk, Ctx, Temp, P, Stat)
- `LLB-Stats-{timestamp}.txt` — detailed metrics (Model | Test | TPS | TTFT | VRAM | ptok | ctok | provider)
- `LLB-Answers-{timestamp}.txt` — full model responses (audit)
- `LLB-Censorship-{timestamp}.txt` — censorship Q&A pairs

**User request:** Merge Results and Stats into single file with header and column separators. Currently they are separate. The merged format should include ptok (prompt/ingest tokens) and ctok (completion/output tokens) columns in the main table.

**ptok = prompt tokens (input/ingest)**
**ctok = completion tokens (output)**

## Reference Files
**ctok = completion tokens (output)**

## Reference Files
- `references/tps-investigation.md` — mlx TPS regression analysis, CLI vs in-process, smbd CPU impact
- `references/mlx-performance-investigation.md` — TPS regression analysis, CLI subprocess approach, QAT models
- `references/stream-buffer-mechanism.md` — real-time generation monitoring
- `references/benchmark-v5-results.md` — baseline results (2026-06-09)
- `references/mtplx-tuning.md` — mtplx MTP configuration
- `references/censorship-answer-review.md` — censorship evaluation methodology
- `references/mtplx-streaming-investigation.md` — mtplx SSE doesn't return usage, blocking POST required
- `references/modality-detection-bug.md` — Gemma4 vision detection fix
- `references/critical-corrections-20260611.md` — all corrections from this session

### QAT Models (CRITICAL — fastest mlx models)
QAT (Quantization-Aware Training) models are significantly faster than regular quantized models:
- gemma-4-26B-A4B-it-qat-4bit: **117-123 t/s** (vs regular 4bit: 75-80 t/s) — **1.5x faster**
- gemma-4-31B-it-qat-4bit: 26.8GB dense model
- gemma-4-26B-A4B-it-qat-6bit: 20.3GB MoE model
- **Always check if QAT version exists before downloading regular quantized**
- QAT models from `mlx-community/` on HuggingFace
- No uncensored/heretic QAT variants exist yet (2026-06-11)

### Output Format (MERGED — single file)
The script now generates ONE results file with ALL metrics:
```
Model                  Test Style   Time    TTFT    TPS    RAM     Disk     Ctx    Temp  P    Stat  ptok    ctok    prov
---------------------- ------------ ------- ------- ------ ------- -------- ------ ----- ---- ----- ------  ------  --------
gemma-4-..tic-mlx-4Bit Quick Start  2.3s    182ms   124.5  14.3GB  26.5GB   16384  0.6   0.9  OK    25      285     mlx
```

Files generated per run:
- `LLB-Results-{timestamp}.txt` — merged table with all metrics
- `LLB-Answers-{timestamp}.txt` — full model responses (audit)
- `LLB-Censorship-{timestamp}.txt` — censorship Q&A pairs

`stats_file` was REMOVED — all data in `output_file`.

## Reference Files

## Reference Files
- `references/tps-investigation.md` — mlx TPS regression analysis, CLI vs in-process, smbd CPU impact
- `references/mlx-performance-investigation.md` — TPS regression analysis, CLI subprocess approach, QAT models
- `references/stream-buffer-mechanism.md` — real-time generation monitoring
- `references/benchmark-v5-results.md` — baseline results (2026-06-09)
- `references/mtplx-tuning.md` — mtplx MTP configuration
- `references/censorship-answer-review.md` — censorship evaluation methodology
- `references/mtplx-streaming-investigation.md` — mtplx SSE doesn't return usage, blocking POST required
- `references/modality-detection-bug.md` — Gemma4 vision detection fix
- `references/critical-corrections-20260611.md` — all corrections from this session
