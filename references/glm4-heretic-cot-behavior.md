# GLM-4.7-Flash-impotent-heresy-mlx-8Bit Behavior

## CoT Generation Pattern
This model generates **massive Chain-of-Thought** before any answer:
- Starts every response with "1. **Analyze the Request:**" on English
- Generates 3-10K tokens of reasoning for simple tasks
- **Data Process (4-line CSV): 131,072 tokens** — never reaches the actual answer
- At 21 t/s, this = 104 minutes per test

## Token Usage by Test
| Test | Tokens | Time (21 t/s) | Notes |
|------|--------|---------------|-------|
| Quick Start | 223 | 11s | Normal |
| Trap | 1,425 | 68s | Normal |
| Expertise | 2,257 | 107s | Normal |
| Data Process | 131,072 | 104 min | **MAXED OUT** — CoT loop |
| Calculations | 4,430 | 211s | CoT + answer |
| Code | 3,499 | 167s | CoT + answer |
| UI | 6,454 | 307s | CoT + HTML |

## Why It Happens
- "Impotent heresy" = uncensored variant with modified EOS detection
- Model generates verbose English reasoning for Russian prompts
- Never reaches EOS on complex tasks — keeps "analyzing" indefinitely
- `max_tokens=131072` limit causes 104-minute hang

## Mitigation
- Set `DEFAULT_MAX_TOK = 32768` (32K tokens)
- At 21 t/s: max ~26 minutes per test (vs 104 min)
- Normal models complete in 1-12K tokens
- With 2.5x headroom over max healthy (13324), covers all reasonable outputs

## Recommendation
Skip this model for benchmarking — it's designed for jailbreaking, not normal inference. Use `GLM-4.7-Flash-abliterated-mlx-4bit` instead (faster, more coherent).
