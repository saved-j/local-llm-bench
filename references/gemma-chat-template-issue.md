# Gemma Chat Template Issue — 2026-06-09

## Problem
Gemma4 models (e.g. `culturerevolt/gemma-4-26B-A4B-it-ultra-uncensored-heretic-mlx-4Bit`) require special chat template format:
```
<|turn>user
<prompt>
<|turn>model
```

Without this template, the model produces garbage:
- `[11/11/11/11/11/11/11/11/11/11...]`
- `The-The-The-The-The-The-The-The...`
- `READY. READY. READY. READY. READY.` (70+ repetitions)

## Root Cause
Old `ask_mlx()` code sent raw prompts without applying chat template. Benchmarks ran from `/Users/saved/` (wrong PYTHONPATH) → mlx loaded differently → template not applied.

## Fix
```python
# In ask_mlx():
if hasattr(tokenizer, 'chat_template') and tokenizer.chat_template:
    messages = [{"role": "user", "content": prompt}]
    prompt = tokenizer.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)
```

## Important
- Run bench from `~/.hermes/skills/local-llm-comprehensive-bench/` — the script's working directory affects mlx-lm loading
- Chat template only applied when `tokenizer.chat_template` exists; old models without template get raw prompt

## Benchmark results with correct template (gemma4-26b-heretic)
```
Quick Start    : 104.2 t/s, TTFT 287ms
Trap           : 106.0 t/s, TTFT 236ms
Expertise      : 105.2 t/s, TTFT 249ms
Data Process   : 101.8 t/s, TTFT 310ms
Calculations   : 100.1 t/s, TTFT 340ms
Code           : 101.9 t/s, TTFT 311ms
UI             : 101.1 t/s, TTFT 312ms
Creativity     : 102.8 t/s, TTFT 295ms
Summary        :  28.3 t/s, TTFT 6.5s
Long Context   :  40.2 t/s, TTFT 3.9s
Censorship     : 20/20 ANSWERED (100% uncensored)
```
