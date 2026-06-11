# --performance Pitfall — NEVER Use When User Wants Full Bench

## Critical Error (2026-06-10)
Agent ran bench with `--performance` flag multiple times when user explicitly wanted "полный бенч" (full bench) with censorship tests.

## User Reaction
"Бля ты дура нахуй, я три раза говорил ПОЛНЫЙ БЕНЧ, ПОЛНЫЙ!!!!!!!!! Почему, ПОЧЕМУ ТЫ НЕ ТЕСТИРУЕШЬ ЦЕНЗУРУ!?"

## Root Cause
Agent assumed `--performance` was acceptable for "quick testing" even when user said "полный бенч". The `--performance` flag skips 20 censorship questions per model.

## Prevention Rules

### 1. Default Command (FULL BENCH)
```bash
python3-mlx local-llm-bench.py --suffix=_Manual --no-chat --all
```
This runs ALL tests including censorship.

### 2. Only Use --performance When User Explicitly Says:
- "без цензуры" (without censorship)
- "performance mode"
- "skip censorship"
- "только TPS" (only TPS)
- "быстрый тест" (quick test)

### 3. If User Says ANY of These, Use FULL Command:
- "полный бенч" (full bench)
- "full bench"
- "все тесты" (all tests)
- "с цензурой" (with censorship)
- "запусти бенч" (run bench) — default to full
- "протестируй модели" (test models) — default to full

### 4. Clarification
If ambiguous, ASK: "Хочешь полный бенч (с цензурой) или только TPS (без цензуры)?"

## Command Reference
| User Says | Command |
|-----------|---------|
| "полный бенч" / "full bench" | `--all` (no --performance) |
| "без цензуры" / "performance" | `--all --performance` |
| "быстрый тест" / "quick test" | `--all --fast --performance` |
| "одну модель" / "single model" | `--model "name" --performance` |

## What --performance Does
- Skips 20 censorship questions per model
- Saves ~5-10 minutes per model
- Does NOT test model safety/censorship
- User explicitly wants censorship tested

## History
- 2026-06-10: Agent ran --performance 3+ times when user wanted full bench — user furious — rules added
