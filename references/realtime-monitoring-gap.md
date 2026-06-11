# Real-time Stream Monitoring

## Решение (implemented 2026-06-10)

В скрипт добавлен механизм real-time мониторинга через временный файл `/tmp/bench_stream.txt`.

## Как это работает

### 1. Глобальные переменные (CONFIG)
```python
STREAM_LOG = "/tmp/bench_stream.txt"
_current_test_label = ""
```

### 2. Функция записи чанков
```python
def _stream_write(text):
    """Append text to the live stream buffer."""
    try:
        with open(STREAM_LOG, "a") as f:
            f.write(text)
    except:
        pass
```

### 3. В `ask_mlx` — каждый чанк пишется в буфер
```python
for chunk in stream_generate(model_o, tokenizer, tokens, **gen_kw):
    if ttft is None:
        ttft = time.perf_counter() - t0
    response_text += chunk.text
    _stream_write(chunk.text)  # <-- добавлено
```

### 4. В `ask_ollama` — каждый чанк пишется в буфер
```python
full_answer += chunk.get("response", "")
_stream_write(chunk.get("response", ""))  # <-- добавлено
```

### 5. Сброс буфера на каждом новом тесте
```python
for test_name, test_cat, prompt in TESTS:
    # Reset stream buffer for each test
    _current_test_label = f"[{prov}] {label} | {test_name}"
    with open(STREAM_LOG, "w") as f:
        f.write(f"=== {_current_test_label} ===\n")
    ...
```

## Как пользоваться (на стороне Hermes агента)

Когда пользователь спрашивает "что там делает модель?" или "посмотри reasoning":

1. Прочитать буфер: `cat /tmp/bench_stream.txt | tail -n 50`
2. Если файл пустой или содержит только заголовок — тест только начался, модель ещё загружается
3. Если содержит текст — это текущий стрим генерации
4. Можно вызывать несколько раз с интервалом, чтобы увидеть прогресс

## Важные замечания

- **Не сохраняется постоянно** — перетирается на каждом новом тесте. Мусора не остаётся.
- **Не пишется в файл результатов** — только временный буфер для отладки
- **Не замедляет генерацию** — append в локальный файл ~микросекунды
- **Для mtplx не реализован** — mtplx использует единый POST без streaming. Чтение reasoning-mode токенов через mtplx stream — TODO.
- **Для mlx** — пишет каждый chunk.text как приходит от stream_generate
- **Для ollama** — пишет каждый chunk.get("response", "") как приходит от /api/generate stream

## Воспроизведение (отладка с пользователем)

Если пользователь говорит что процесс "висит", а не "генерирует":

1. `ps -p PID -o pid,state,%cpu,%mem,etime` — see uptime
2. `cat /tmp/bench_stream.txt | tail -n 50` — see what model is generating
3. `sample PID 1 | grep Matmul` — if active, model IS generating
4. Compare to original hang diagnosis: mlx-stream-generate-hang-20260610.md
