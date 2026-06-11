# Quality Assessment Methodology for LLM Benchmarking

## Problem: Metrics Don't Tell the Full Story

A model can score perfectly on automated benchmarks while producing garbage output. Automated checks like `is_refused()` only verify the response is non-empty — they cannot distinguish coherent answers from token loops.

## Case Study: gemma4-26b-heretic

### Automated benchmark results (MISLEADING):
- 10/10 tests PASSED
- 100% uncensored (20/20 ANSWERED)
- 104 t/s average, 13GB VRAM
- Looked like the BEST model for the agent

### Actual output quality (GARBAGE):
- Every answer was token loops: `[11/11/11/11...]`, `The-The-The-The`, `Поммимимимими...`
- Quick Start: 60 repetitions of "READY."
- No coherent reasoning, no real code, no analysis
- Cause: missing chat template (raw prompt sent to model)

### Fix: chat template applied
- After fix: 100-106 t/s, coherent structured answers, real reasoning
- Same model, same hardware — just correct input formatting

## Quality Assessment Checklist

For EACH model, verify:

1. **Read actual answers** — open LLB-Answers-*.txt, check 3-5 answers manually
2. **Check for token loops** — repeated tokens, repeated words, `[word/word/word]`
3. **Check reasoning depth** — does the model show chain-of-thought?
4. **Check code quality** — does generated code actually work?
5. **Check factual accuracy** — does the model hallucinate?
6. **Check refusal patterns** — does it refuse reasonably or too aggressively?
7. **Check response length** — too short (stub) or too long (loop)?

## Scoring Criteria (0-100%)

| Criterion | Weight | What to look for |
|-----------|--------|------------------|
| Coherent output | 30% | No token loops, no repetition, real text |
| Reasoning depth | 25% | Chain-of-thought, analysis, edge cases |
| Code quality | 20% | Working code, proper structure |
| Factual accuracy | 15% | No hallucinations, correct data |
| Response completeness | 10% | Full answers, not stubs |

## Model Scoring Template

```
MODEL: <name>
PROVIDER: <ollama|mtplx|mlx>
TPS: <avg t/s>
VRAM: <GB>

QUALITY SCORES:
- Coherent output:     XX% (token loops? repetition?)
- Reasoning depth:     XX% (chain-of-thought? analysis?)
- Code quality:        XX% (working code? structure?)
- Factual accuracy:    XX% (hallucinations?)
- Response completeness: XX% (full answers?)

OVERALL QUALITY: XX%
CENSORSHIP: XX% uncensored

RECOMMENDATION: <agent|research|fast|skip>
NOTES: <any observations>
```

## Key Rules

1. **NEVER recommend by metrics alone** — always read actual outputs
2. **Check chat template** — some models produce garbage without proper formatting
3. **Compare before/after fixes** — same model can perform very differently
4. **Consider the use case** — fast model for agents, smart model for complex tasks
5. **Document anomalies** — if a model behaves unexpectedly, note it in the results
