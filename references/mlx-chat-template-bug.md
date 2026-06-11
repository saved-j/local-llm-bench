# MLX Chat Template Bug — gemma4-heretic garbage output

## Problem
gemma4-26b-heretic produced garbage when benchmarked from `~/local-llm-bench.py`:
- `[11/11/11/11/11/11/11/11...]` token loops
- `The-The-The-The-The...` word repetition
- `READY. READY. READY. READY. READY...` 70x repetitions

Same model worked perfectly when run from skill directory.

## Root Cause
Script was sending raw prompts without applying chat template. Gemma4 requires:
```
<|turn>user
<prompt>
<|turn|>
<|turn>model
```

Without this, the model enters a degenerate loop because it doesn't know where to start generating.

## Fix
```python
if tokenizer and hasattr(tokenizer, "apply_chat_template"):
    prompt = tokenizer.apply_chat_template(
        [{"role": "user", "content": prompt}],
        tokenize=False, add_generation_prompt=True
    )
```

Applied to BOTH `ask_mlx()` (for tests) and `ask_mlx_censorship()` (for censorship).

## Detection
User reported gemma4-heretic "100% uncensored" but outputs were all garbage.
TPS looked normal (104 t/s) — the garbage was being generated fast.
The `is_refused()` check passed because garbage doesn't contain refusal words.

## Lesson
ALWAYS apply chat template for mlx models. Raw prompts ≠ chat-formatted prompts.
Different models have different template requirements — check tokenizer.chat_template.
