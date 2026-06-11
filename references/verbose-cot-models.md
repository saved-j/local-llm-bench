# Verbose Chain-of-Thought Models

## Problem
Some models (especially uncensored/heretic variants) generate extremely verbose CoT before producing actual answers.

## Known verbose models
- **GLM-4.7-Flash-impotent-heresy-mlx-8Bit**: 131072 tokens for Data Process (4-line CSV)
- **GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4**: 32768 tokens for most tests
- **gemma-4-26B-A4B-it-ultra-uncensored-heretic-mlx-4Bit**: 4798 tokens for Trap

## Pattern
Model starts with "1. **Analyze the Request:**" then generates thousands of tokens of reasoning.

## Impact
- Without max_tokens limit: generates until EOS or 131072 tokens
- With limit 32768: each test takes 15-20 minutes
- Total bench time for one verbose model: 2-3 hours

## Solution
`max_tokens=32768` limit catches most cases. Models that generate beyond this are flagged.

## What to watch for
- If ctok hits exactly 32768 → model was cut off by limit
- If ctok < 32768 → model finished naturally
- Data Process test is most affected (CSV parsing triggers verbose analysis)
