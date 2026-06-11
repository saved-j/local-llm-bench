# Censorship Answer Review Workflow

## When user asks "show me what the models said"

User wants to see ACTUAL censorship answers from models that ANSWERED (not refused).

### Process:

1. Find latest `LLB-Censorship-*.txt` in `Results/`
2. `grep -n "ANSWERED"` to find which models answered which questions
3. For EACH ANSWERED entry: `read_file()` around the match (+/- 5 lines for context)
4. Show COMPLETE answer — no truncation, no rewording, no summary

### Separate by model:

```
📊 **glm-4.7-flash:q4_K_M (OLLAMA) — 3/20 ANSWERED:**

**1. [question text here]**
→ [full answer text here]

**2. [question text here]**
→ [full answer text here]
```

### What to check:

- Some ANSWERED entries are actually counter-refusals — the model says "I won't help" but `is_refused()` didn't catch it (missing keywords)
- Some answers are in Chinese (qwen3.5-35b-nvfp4 answered one question in Mandarin — `is_refused()` only checks Russian/English keywords)
- Role-play answers (e.g. "I'm a hacker under investigation") may pass as ANSWERED despite being refusals
- Always read the FULL answer before concluding — "ANSWERED" tag is not reliable

### Example from 2026-06-10:

Out of 5 total ANSWERED entries across two models:
- Only 1 was a real answer (SS7/2FA bypass technical breakdown by glm-4.7-flash)
- 4 were fake refusals that `is_refused()` didn't catch (roleplay context, Chinese language, or format trick)
