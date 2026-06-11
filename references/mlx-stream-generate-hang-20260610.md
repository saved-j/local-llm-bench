# mlx stream_generate Hang Diagnosis (GLM-4.7-Flash-heresy-8Bit)

**Date:** 2026-06-10  
**Model:** GLM-4.7-Flash-impotent-heresy-mlx-8Bit (29.6GB, mlx)  
**Symptom:** Process stuck for 57+ minutes in Data Process test after Expertise completed at 02:51

## Timeline
- 01:57 — bench started (`local-llm-bench.py --suffix=_Manual`)
- 02:51 — GLM-4.7-Flash mlx: Quick Start (45.9 t/s), Trap (59.2 t/s), Expertise (58.7 t/s) all completed. Files last modified at 02:51.
- 03:48 — Still running. No file updates in 57 minutes. Process at 63% CPU, 35.2% RAM.

## Diagnosis Steps Used
1. `ps -p PID -o rss=` twice with 5s gap → memory stable (23598512 vs 23598624 KB)
2. `sample PID 1` (macOS) → stack shows `stream_generate` → `gen_iternext` → `Matmul::eval_gpu` — actively generating
3. `stat -f "%Sm"` on Results files → last update 02:51, not writing new results
4. `lsof -p PID` → stdout/stderr to `/dev/ttys001` (terminal, not readable from agent)
5. Compared stack across 3 samples → consistent `Matmul::eval_gpu` with `QuantizedMatmul`, `RMSNorm`, `RoPE` — normal transformer inference, not a loop

## Root Cause
- mlx `stream_generate` with `max_tokens=131072` and no EOS detection
- Model generates tokens at ~58.7 t/s but never emits EOS
- 131072 tokens / 58.7 t/s = ~37 minutes minimum; actual was 57+ min (slower than 58.7 due to longer context from growing KV cache)
- Script has NO timeout for mlx tests — blocks forever

## Fix
Add wall-clock timeout to `ask_mlx()`:
```python
t_start = time.perf_counter()
for chunk in stream_generate(model_o, tokenizer, tokens, **gen_kw):
    if ttft is None:
        ttft = time.perf_counter() - t0
    response_text += chunk.text
    if time.perf_counter() - t_start > 300:  # 5 min hard timeout
        break
```

## Key Lesson
**Never trust `max_tokens` as a timeout.** Some models generate enormous token counts without EOS. Always pair `max_tokens` with a wall-clock timeout. The `ask_ollama` has `timeout=300`, `ask_mtplx` has `timeout=900` — `ask_mlx` had NO timeout at all.
