# LCM Context Loss — fresh_tail_count Problem

## Problem
LCM `fresh_tail_count` defaults to 64 — only last 64 messages survive in prompt.
Combined with Session Hygiene `hygiene_hard_message_limit` (default 400), old messages are GONE.

## Root Cause
- LCM `fresh_tail_count = 64` — protects only last 64 messages
- Session Hygiene `hygiene_hard_message_limit = 400` — compresses at 400 messages
- With 1M context (DeepSeek), 64 messages = 0.6% of context = absurd

## User Reaction
- "Счётчик контекста за весь диалог не поднялся выше 11%"
- "Ты его забываешь, ты не можешь найти в истории то о чём я говорил даже когда я тебе точно называю время"
- Lost their GitHub username from earlier in conversation

## Fix
1. `LCM_FRESH_TAIL_COUNT=999999` in `~/.hermes/.env` (env var only, NOT config.yaml)
2. `hygiene_hard_message_limit: 999999` in `~/.hermes/config.yaml`
3. LCM was removed per user request (2026-06-09). If reinstalled, set fresh_tail_count immediately.

## LCM Config Sources
- `fresh_tail_count` → env var `LCM_FRESH_TAIL_COUNT` only (not in config.yaml)
- `context_threshold` → config.yaml `lcm.context_threshold` or `LCM_CONTEXT_THRESHOLD`
- `fresh_tail_max_tokens` → env var `LCM_FRESH_TAIL_MAX_TOKENS` (optional token cap)

## Honesty Rule
If user says "я тебе уже говорил" and you can't find it — be HONEST.
Say "не нашла в контексте, скорее потерялось при компрессии" and ask them to repeat.
NEVER pretend to search endlessly or fake-find something.
