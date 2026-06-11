# HuggingFace Download Pitfalls

## Lock Files (2026-06-11)

`hf download` creates lock files in `~/.cache/huggingface/hub/.locks/` directory. If download is interrupted (SIGKILL, timeout, crash), locks persist and block ALL subsequent downloads for that model.

### Symptoms:
```
Still waiting to acquire lock on /Users/saved/.cache/huggingface/hub/.locks/models--.../abc123.lock (elapsed: 90.8 seconds)
```

### Fix:
```bash
rm -rf ~/.cache/huggingface/hub/.locks/models--<model-name>/
```

### Best Practice:
- Always use `hf download` (not curl) for LFS files
- If curl downloads return tiny files (15 bytes) — they're LFS pointers, not actual weights
- For mirror: `HF_ENDPOINT=https://hf-mirror.com hf download <model>`

## Duplicate Blobs

If model downloaded multiple times (via different methods), blobs directory accumulates duplicates. `du -sh` shows inflated size. Use `hf cache list` to check actual model sizes.
