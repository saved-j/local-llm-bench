# Format Refinements (session 2026-06-10)

## Status line consistency — ALL THREE providers

User's last correction sequence:
1. User showed MTPLX and OLLAMA status lines with different formats
2. "тебя ничего не смущает? mtplx показывает 0гб free. ollama не говорит сколько загружено"
3. FIX: ALL THREE providers use EXACT same format:
   - GPU Mem Freed: `0.0GB in VRAM` (not `free`, not `0.0GB free`)
   - Loaded: `X.XGB in VRAM` (MUST show amount for ALL providers, including ollama)
   - Ready: `✅` (verified)

## Table format — NO author annotations

User clarified: "не надо подписывать оллама и хуйхуй, убери это, я передумал"
- `shorten(label, width=22)` only — NO `format_model_name()`
- NO `(ollama)`, `(mlx-community)`, `(huihui-ai)` in table or status line
- Column width 22 chars (not 30, not 50)
