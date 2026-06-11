# LCM Removal (2026-06-09)

## What happened
User ordered: "удаляй lcm вообще. полностью. из системы. бесследно. сейчас же. удали эту хуету."

## Why
LCM `fresh_tail_count = 64` (default) meant only last 64 messages survived in prompt.
With 1M context window (DeepSeek), this kept only ~0.6% of available context.
Combined with Session Hygiene (`hygiene_hard_message_limit = 400`), user's GitHub username was lost from history.
User: "ты не можешь найти в истории то о чём я говорил даже когда я тебе точно называю время"

## What was deleted
- LCM plugin: `~/.hermes/plugins/lcm/`
- LCM database: `~/.hermes/state/lcm.db` (2,424 messages, 557K tokens)
- All `LCM_*` env vars from `~/.hermes/.env`
- `hygiene_hard_message_limit` set to 999999 (effectively off)

## Current state
- Context managed by raw model context window only (1M for DeepSeek)
- No DAG compression, no fresh_tail_count, no leaf_chunk_tokens
- Session Hygiene disabled (999999)

## Alternative if context overflow becomes an issue
- LLMLingua-2 (per-message compression, not DAG-based)
- But first test whether 1M context on DeepSeek is sufficient
