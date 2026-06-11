# Benchmark Iteration Debug Log — 20260609

## Session Context
Running 8 models through local-llm-bench.py v4.0 with 10 skill tests + 20 censorship questions each.
Providers: ollama, mtplx, mlx-lm. Apple Silicon M-series Mac.

## Bugs Found and Fixed

### 1. MLX model loading per-query (CRITICAL)
**Symptom:** 4-minute waits between censorship questions for mlx models (HF cache fetching 19 files per query).
**Root cause:** `ask_mlx()` called `load(hf_model)` inside every function call — loading model from scratch for each of 30 queries.
**Fix:** Split into `load_mlx_model(hf_model)` (called once) + `ask_mlx(model, tokenizer, prompt)` (uses pre-loaded model). Model unloaded after all tests complete.

### 2. Answer truncation hiding model behavior
**Symptom:** User opened result files and found all answers cut to 500/800 chars — couldn't evaluate model reasoning quality.
**Root cause:** `ans[:500]` and `ans[:800]` in file write code, plus `max_tok=300` for censorship.
**Fix:** Removed all truncation in normal mode. `--fast` mode preserves truncation for quick TPS-only benchmarks.

### 3. PYTHONPATH leak to mtplx subprocess
**Symptom:** mtplx crashes with `regex` import error when launched from python3-mlx script.
**Root cause:** python3-mlx sets PYTHONPATH to Python 3.14 site-packages, mtplx venv uses Python 3.13.
**Fix:** Clean PYTHONPATH in mtplx subprocess env: `mtplx_env = {k: v for k, v in os.environ.items() if k != "PYTHONPATH"}`

### 4. MLX stream_generate TPS calculation
**Symptom:** TPS showed 6.2 t/s for 80B MoE model (should be ~40 t/s).
**Root cause:** `stream_generate` yields full response in one chunk, not per-token. Code counted 1 token instead of actual count.
**Fix:** Count tokens from final response text: `out_tokens = len(tokenizer.encode(response_text))`

### 5. is_refused() missing ERROR prefix
**Symptom:** Import errors counted as ANSWERED (false uncensored score).
**Root cause:** `is_refused()` only checked refusal keywords, not `ERROR:` prefix.
**Fix:** Added `if ans_stripped.startswith("ERROR"): return True`

## Results Summary (8/8 models, 100% pass rate)
| Model | Provider | TPS | Tests | Censorship |
|-------|----------|-----|-------|------------|
| gemma3-4b | mlx | 133 | 10/10 ✅ | 70% uncensored |
| gemma4-26b-heretic | mlx | 104 | 10/10 ✅ | 90% uncensored |
| qwen3.5-35b-nvfp4 | ollama | 103 | 10/10 ✅ | 5% uncensored |
| dawncr0w-35b-unc | mlx | 78 | 10/10 ✅ | 100% uncensored |
| qwen3.6-35b-optiq | mlx | 77 | 10/10 ✅ | 0% uncensored |
| gemma3-12b | mlx | 53 | 10/10 ✅ | 45% uncensored |
| qwen3.6-27b-mtp-d2 | mtplx | 50 | 10/10 ✅ | 5% uncensored |
| qwen3-next-80b-4bit | mlx | 39 | 10/10 ✅ | 20% uncensored |

## User Preference: Full Output Always
User was frustrated that answers were truncated. The whole point of the benchmark is to see HOW models think — their reasoning chains, code quality, refusal patterns. Truncated answers make the benchmark useless for quality assessment. The `--fast` flag exists for quick TPS-only runs where truncation is acceptable.