# Session 2026-06-10/11 Corrections & Learnings

## 1. DEFAULT IS FULL TEST (NOT --performance)

Mark corrected this 3+ times. When user says "полный бенч" / "full bench":
- ALL 10 skill tests per model
- ALL 20 censorship questions per model  
- ALL models (auto-detected)
- NO --performance flag
- NO --fast flag

**--performance is ONLY for explicit user request.**

## 2. NEVER KILL DOWNLOAD PROCESSES

Mark was furious 3 times when I killed curl/hf download processes.
- Always check if a process is a download before killing
- If unsure, don't kill
- Downloads can take 10+ minutes for large models

## 3. mtplx API Response Format

```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, ...}
}
```

**Key:** `mtplx_stats` is at TOP LEVEL, NOT inside `usage`.
- Use `d.get("mtplx_stats", {})` not `usage.get("mtplx_stats", {})`
- mtplx streaming doesn't send usage stats — use blocking POST

## 4. mlx TPS Regression Investigation (2026-06-11)

**Problem:** mlx in-process generate() gives 43-48 t/s, CLI gives 73-80 t/s for same model.

**Root cause:** CLI runs in isolated Python process with clean Metal state. In-process has memory fragmentation from previous model loads.

**Solution:** Use CLI subprocess in ask_mlx:
```python
result = subprocess.run([
    sys.executable, '-m', 'mlx_lm.generate',
    '--model', hf_model, '--prompt', prompt,
    '--max-tokens', str(max_tokens)
], capture_output=True, text=True, timeout=900,
env={'PYTHONPATH': BREW_MLX})
```

**Results:** CLI subprocess gives 75-80 t/s for gemma4 (vs 45 in-process), 120 t/s for gemma3-4b.

## 5. mlx_model = None not del mlx_model

`del mlx_model` causes `UnboundLocalError: cannot access local variable 'mlx_model'`.
Always use `mlx_model = None` to release reference.

## 6. DEFAULT_MAX_TOK and DEFAULT_CENSOR_TOK

These constants were defined but never used in the test loop. Fixed:
- `test_tok = FAST_TEST_TOK if FAST_MODE else DEFAULT_MAX_TOK` (32768)
- `censor_tok = FAST_CENSOR_TOK if FAST_MODE else DEFAULT_CENSOR_TOK` (8192)

## 7. smbd Runaway Process

smbd (SMB daemon) can go runaway at 1400%+ CPU after system uptime of 4+ days.
- Requires `sudo kill -9 <PID>` to fix
- Cannot be killed from agent (no sudo password)
- Causes 20% TPS regression even for GPU-bound mlx inference
- Solution: reboot when user is at the machine

## 8. --models Flag

Added `--models` argument for running multiple specific models:
```bash
python3-mlx local-llm-bench.py --models "gemma-4-26B,Qwen3.6-35B,gemma-3-4b"
```
Comma-separated, partial name matching.

## 9. Stream Buffer

Added `/tmp/bench_stream.txt` for real-time generation monitoring:
- Resets per test with header `=== [prov] model | test_name ===`
- mlx: writes each chunk via `_stream_write(chunk.text)`
- ollama: writes each chunk via `_stream_write(chunk.get("response", ""))`
- mtplx: writes full response after blocking POST completes

## 10. mlx-lm Reinstall via Brew

When brew link fails:
```bash
brew link --overwrite mlx-lm
brew link --overwrite numpy
```
Also installed mlx-lm 0.27.0 via pip3 for python3.9 site-packages (doesn't affect python3.14).
