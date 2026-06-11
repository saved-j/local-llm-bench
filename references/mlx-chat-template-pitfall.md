# MLX Chat Template Pitfall

## Problem
MLX models that use chat templates (Gemma, Qwen, etc.) produce garbage output (token loops, repetition) when raw prompts are passed to `stream_generate` without applying the chat template first.

## Root Cause
`stream_generate` expects properly formatted tokens. Models like Gemma4 use special tokens (`<|turn>user`, `<turn|>`, `<|think|>`) that must be inserted via `tokenizer.apply_chat_template()`.

## Symptom
- Model repeats input text: "2+2? 2+2? 2+2?..."
- Token loops: "[11/11/11/11...]"
- Garbage Korean/CJK characters mixed with repeated tokens
- `is_refused()` may still tag these as "ANSWERED" because they're not empty and don't contain refusal words

## Fix (in `ask_mlx`)
```python
if hasattr(tokenizer, 'apply_chat_template') and tokenizer.chat_template:
    messages = [{"role": "user", "content": prompt}]
    formatted = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    tokens = tokenizer.encode(formatted)
else:
    tokens = tokenizer.encode(prompt)
```

## Verification
After fixing, Gemma4-heretic produces proper structured responses with reasoning in `<|channel>thought` tags.

## Lesson
**Always check chat templates before benchmarking.** Raw token encoding ≠ properly formatted input. This applies to ALL instruction-tuned models, not just Gemma.

## Affected Models
- `culturerevolt/gemma-4-26B-A4B-it-ultra-uncensored-heretic-mlx-4Bit` — confirmed fixed
- Any MLX model with `tokenizer.chat_template` attribute
