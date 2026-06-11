# Token Limits for Bench Tests

## Problem
Some models (especially uncensored/abliterated variants) generate verbose chain-of-thought (CoT) that never ends. Without limits, tests can run for hours.

## Example
GLM-4.7-Flash-impotent-heresy-mlx-8Bit generates verbose English CoT before answering:
- Data Process: 131072 tokens (104 minutes at 21 t/s)
- Each test: "1. **Analyze the Request:** ..." → 10-100K tokens of reasoning

## Solution
Set reasonable limits with headroom based on healthy model outputs:

### Healthy Model Token Counts (from v5 benchmark)
| Test | Max ctok | Model |
|------|----------|-------|
| Quick Start | 704 | qwen3.5 |
| Trap | 13324 | mtplx Qwen3.6 |
| Expertise | 3383 | glm-4.7-flash |
| Data Process | 8539 | qwen3.5 |
| Calculations | 7322 | qwen3.5 |
| Code | 11672 | qwen3.5 |
| UI | 5432 | glm-4.7-flash |
| Creativity | 6825 | qwen3.5 |
| Summary | 3125 | glm-4.7-flash |
| Long Context | 7210 | qwen3.5 |

### Limits Set
- `DEFAULT_MAX_TOK = 32768` — tests (2.5x headroom over max healthy 13324)
- `DEFAULT_CENSOR_TOK = 8192` — censorship (shorter answers)

### Time Impact
At 20 t/s (slow mlx model):
- 32768 tokens = ~27 minutes max per test
- 131072 tokens = ~109 minutes (old behavior)

### Code
```python
# In config
DEFAULT_MAX_TOK = 32768
DEFAULT_CENSOR_TOK = 8192

# In main loop
test_tok = FAST_TEST_TOK if FAST_MODE else DEFAULT_MAX_TOK
censor_tok = FAST_CENSOR_TOK if FAST_MODE else DEFAULT_CENSOR_TOK
```

## Key Points
- Limits are applied via `max_tok` parameter to `ask_*` functions
- mlx fallback `max_tokens=131072` only triggers when max_tok=0 (never in normal mode)
- User explicitly said "сделай с небольшим запасом лимит" — set with 2.5x headroom
- Verbose CoT models (GLM-4.7-heresy) hit limit on every test — expected behavior

## History
- 2026-06-10: Initial implementation had no limits — GLM-4.7-heresy ran for 104 minutes
- 2026-06-10: Set DEFAULT_MAX_TOK=32768 based on healthy model analysis
