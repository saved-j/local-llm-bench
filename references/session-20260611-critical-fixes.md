# Session Critical Fixes — 2026-06-11

## Output Format (MERGED)
- No more `stats_file` — all data goes to `LLB-Results-{timestamp}.txt`
- Header includes: Model, Test Style, Time, TTFT, TPS, RAM, Disk, Ctx, Temp, P, Stat, ptok, ctok, prov
- Use `─` (Unicode) for header separator, not `-`
- TABLE_FMT: `"%-22s %-12s %-7s %-7s %-6s %-7s %-8s %-6s %-5s %-4s %-5s  %-7s %-8s %-8s\\n"` (14 cols)
- ptok = prompt tokens (input/ingest), ctok = completion tokens (output)

## Skip Line Formatting
- Trap Skip for coding models: use `"Skip"` (NOT `"Skip (coding)"`) to avoid column overflow
- Pass `0, 0, prov` for ptok/ctok/prov columns on skip lines

## GPU Status Line
Before: `GPU Mem Freed: ✅ X.XGB in VRAM Loaded: ✅ Y.YGB in VRAM Ready: ✅`
After:  `GPU Free: ✅ X.XGB  Model VRAM: ✅ Y.YGB  Ready: ✅`

## Interactive Menu Skip
When `--model` or `--models` is specified, SKIP the interactive model selection menu.
Fix: `if not AUTO_ALL and not SINGLE_MODEL and not MULTI_MODELS:` at line 712/713.

## Hardcoded Paths (CRITICAL — user was angry)
NEVER hardcode `/Users/saved/...` or `/opt/homebrew/...` in scripts.
- `RESULTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Results")`
- `MTPLX_BIN = os.popen("which mtplx 2>/dev/null").read().strip() or "/opt/homebrew/var/mtplx/venv-0.3.7/bin/mtplx"`
- `MTPLX_SNAP = os.path.expanduser("~/.cache/...")`
- `_brew_mlx` = auto-detect via `brew --prefix mlx-lm` then walk for mlx_lm package
- HF cache paths: `os.path.expanduser("~/.cache/huggingface/hub")`
- ollama paths: `os.path.expanduser("~/.ollama/...")`

## Disk Size (HF Cache Fix)
Count ONLY snapshot directory (symlinks to blobs), not entire blobs/ directory:
```python
for root, dirs, files in os.walk(snap_dir, followlinks=True):
```
Without `followlinks=True`, symlinks report as 0 bytes. With it, symlinks resolve to actual blob sizes.

## MLX Model Unload
`print("  MLX model unloaded.")` — appears after EACH mlx model, inside the test loop cleanup.
Use `mlx_model = None` NOT `del mlx_model` to avoid UnboundLocalError.

## GLM-4.7-REAP-nvfp4
Works with CLI subprocess at 82-85 t/s. Old script couldn't load nvfp4 in-process.
CLI subprocess handles nvfp4 correctly.

## QAT Models
`mlx-community/*-qat-<bits>bit` — 1.5x faster than regular 4bit. No uncensored QAT variants.

## Process Management
- NEVER kill download processes (curl huggingface.co, hf download)
- Check `ps aux | grep -E 'curl|huggingface|hf.*download'` before any kill

## Modality Detection for ollama
For ollama models (no config.json): check model name for "vision", "audio", "video" keywords.
