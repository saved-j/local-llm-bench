# GLM-4.7-Flash-heresy-mlx-8Bit Verbose CoT Pattern

## Problem
GLM-4.7-Flash-impotent-heresy-mlx-8Bit generates extremely verbose Chain-of-Thought (CoT) reasoning before producing actual answers.

## Observed Behavior
- **Data Process** (4-line CSV): 131,072 tokens of English reasoning, NEVER reaches actual answer. Hit max_tokens limit after 104 minutes.
- **Calculations** (import math): 4,430 tokens — 4000 tokens of "Analyze the Request", "Step-by-Step Plan", "Self-Correction" + 430 tokens actual answer.
- **UI** (HTML gen): 6,454 tokens — 6000 tokens of "Here's a thinking process that leads to..." + 454 tokens HTML.
- **Quick Start**: 223 tokens (normal)
- **Trap**: 1,425 tokens (normal)
- **Expertise**: 2,257 tokens (normal)

## Pattern
Every answer starts with:
```
1.  **Analyze the Request:**
    *   **Input:** ...
    *   **Goal:** ...
```

Then extensive English reasoning (2-100K tokens) before the actual response.

## Root Cause
"Impotent heresy" variant — ablation removes censorship but also removes EOS detection. Model generates verbose CoT and never stops.

## Mitigation
- `DEFAULT_MAX_TOK = 32768` — limits Data Process to ~27 min (was 104 min at 131072)
- Healthy models complete same tests in 3-8K tokens
- This model's CoT is coherent but wasteful — 90%+ of tokens are reasoning, not answer

## Normal Token Counts (healthy models)
- Summary: 1,460-3,125 tokens
- Long Context: 2,491-7,210 tokens
- Code: 1,331-11,672 tokens
- Data Process: 4,826-8,539 tokens
- UI: 4,778-5,432 tokens
- Trap: 1,109-13,324 tokens (mtplx generates most)
