# mtplx Tuning & Configuration

## Tuning Results (2026-06-09)

Model: qwen3.6-27b-mtp-d2 (Qwen3.6-27B-MTPLX-Optimized-Speed)

| Mode | TPS | Multiplier |
|------|-----|-----------|
| AR (no MTP) | 25.50 | 1x |
| D1 | 42.21 | 1.66x |
| **D2 🏆** | **47.37** | **1.86x** |
| D3 | 41.14 | 1.61x |

Acceptance: depth0=92.75%, depth1=86.76%

## Correct Launch Command

```bash
mtplx quickstart \
  --profile performance-cold \
  --mtp --depth 2 \
  --model "$MTPLX_SNAP" \
  --port 8077 \
  --device mps \
  --context-size 262144
```

**NEVER use `--profile stable`** — kills MTP performance, drops to 14.5 t/s

## Model Path

The model name `qwen3.6-27b-mtp-d2` is NOT registered in mtplx's local model cache.
Must use full HF snapshot path:
```
/Users/saved/.cache/huggingface/hub/models--Youssofal--Qwen3.6-27B-MTPLX-Optimized-Speed/snapshots/be5190f2349594ec941753efc90a4ca5641af174
```

## Cold Start Behavior

Quick Start shows ~15-17 t/s (cold). After 2-3 tests, TPS climbs to 42-47 t/s.
This is normal — model needs warmup. Don't panic at low Quick Start numbers.

## PYTHONPATH Conflict

mtplx venv (Python 3.13) conflicts with python3-mlx's PYTHONPATH (Python 3.14).
Fix: unset PYTHONPATH before launching mtplx subprocess.
```python
subprocess.Popen([...], env={k: v for k, v in os.environ.items() if k != "PYTHONPATH"})
```

## API Response Format (CRITICAL)

mtplx `/v1/completions` (non-streaming) returns:
```json
{
  "choices": [{"text": "...", "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 7, "completion_tokens": 8, "total_tokens": 15},
  "mtplx_stats": {"completion_tokens": 8, "decode_tok_s": 32.5, "ttft_s": 0.293, ...}
}
```

⚠️ **`mtplx_stats` is at TOP LEVEL, NOT inside `usage`!**
- ✅ `d.get("mtplx_stats", {})` 
- ❌ `usage.get("mtplx_stats", {})` — always empty!

Key fields in mtplx_stats: `completion_tokens`, `decode_tok_s`, `ttft_s`, `accepted_drafts`, `verify_calls`

## SSE Streaming Limitation

mtplx SSE streaming (`stream: true`) does NOT send `usage` object in stream chunks.
Must use blocking POST for correct token counts.

## MTP Stats from mtplx_stats

When MTP works, `usage.mtplx_stats` contains:
- `accepted_drafts` / `verify_calls` — draft acceptance rate
- `ttft_s` — time to first token
- `active_memory_bytes` — GPU memory usage

When `draft_accept=0/0`, MTP is NOT active (wrong profile or --mtp not passed).
