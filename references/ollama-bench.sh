#!/usr/bin/env bash
# ollama-bench.sh — Ollama model benchmark v3.0
# Benchmark engine based on bench.sh (MarkVictorson)
# Compatible with macOS bash 3.2+ with Python3
#
# Usage:
#   ./ollama-bench.sh              # Interactive model selection
#   ./ollama-bench.sh --all        # Auto-select all non-embedding models
#   ./ollama-bench.sh --all --chat # Agent mode (progress to stdout)
#   ./ollama-bench.sh --all --suffix=_m4max  # Custom output suffix

# Detect mode: --chat sends progress to stdout, --all auto-selects all models
CHAT_MODE=false
AUTO_ALL=false
OUTPUT_SUFFIX=""
for arg in "$@"; do
    if [ "$arg" = "--chat" ]; then
        CHAT_MODE=true
    elif [ "$arg" = "--all" ]; then
        AUTO_ALL=true
    elif [[ "$arg" == --suffix=* ]]; then
        OUTPUT_SUFFIX="${arg#--suffix=}"
    fi
done

# Progress output: chat mode → stdout (forwarded to user), console mode → stderr (silent)
chat_msg() {
    if [ "$CHAT_MODE" = true ]; then
        echo -e "$@"
    else
        echo -e "$@" >&2
    fi
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Output directory
RESULTS_DIR="${RESULTS_DIR:-.}"

# System info
AVAILABLE_MEM=$(sysctl -n hw.memsize 2>/dev/null || echo "16384")
AVAILABLE_MEM=$((AVAILABLE_MEM / 1073741824))
NUM_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "4")

chat_msg "${BOLD}${CYAN}==========================================================${NC}"
chat_msg "${BOLD}${CYAN}   Ollama Benchmark v3.0${NC}"
chat_msg "${BOLD}${CYAN}==========================================================${NC}"
chat_msg "${BLUE}System: ${NUM_CORES} cores, ${AVAILABLE_MEM} GB RAM${NC}"
chat_msg ""

# Custom settings (from bench.sh)
CUSTOM_TEMP=0.6
CUSTOM_SEED=42
CUSTOM_CTX=16384
CUSTOM_TOP_P=0.9
CUSTOM_TOP_K=40

if [ "$AUTO_ALL" = true ]; then
    USE_CUSTOM=true
    chat_msg "${GREEN}>>> Mode: CUSTOM (auto) — Temp=$CUSTOM_TEMP, Ctx=$CUSTOM_CTX${NC}"
else
    echo -e "${BOLD}ATTENTION:${NC} Run with CUSTOM settings?"
    echo "  [Enter] = Custom (Temp=$CUSTOM_TEMP, Seed=$CUSTOM_SEED, Ctx=$CUSTOM_CTX)"
    echo "  'default' = Use each model's own defaults"
    read -p "Your choice [Enter/custom]: " user_input
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    case "$input_lower" in
        "n" | "def" | "default")
            USE_CUSTOM=false
            echo -e "${GREEN}>>> Mode: DEFAULT${NC}"
            ;;
        *)
            USE_CUSTOM=true
            echo -e "${GREEN}>>> Mode: CUSTOM (Temp=$CUSTOM_TEMP, Seed=$CUSTOM_SEED, Ctx=$CUSTOM_CTX)${NC}"
            ;;
    esac
fi

# Check dependencies
check_deps() {
    local missing=""
    for cmd in ollama fzf bc jq python3; do
        if ! command -v "$cmd" &> /dev/null; then
            missing="$missing $cmd"
        fi
    done
    if [ -n "$missing" ]; then
        echo -e "${RED}Missing commands:${missing}${NC}"
        exit 1
    fi
}

# Memory flush between models (from bench.sh)
flush_memory() {
    curl -s -X POST http://localhost:11434/api/generate -d '{"model": "'"$1"'", "keep_alive": 0}' > /dev/null
    sleep 2
}

# Web context for Creativity test — gives models real facts to base headlines on
get_web_context() {
    local query="Huawei Mate XT"
    local res=$(curl -s "https://api.duckduckgo.com/?q=${query// /+}&format=json&no_html=1" | jq -r '.Abstract' 2>/dev/null)
    if [[ -z "$res" || "$res" == "null" ]]; then
        res=$(curl -s "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&explaintext&titles=${query// /_}&format=json" | jq -r '.query.pages | to_entries[0].value.extract' 2>/dev/null)
    fi
    [[ -z "$res" || "$res" == "null" ]] && echo "Huawei Mate XT is the world's first triple-folding smartphone." || echo "$res" | tr -d '"' | tr -d '\n' | cut -c1-500
}

# Test matrix — 10 tests covering: latency, traps, expertise, data, math, code, UI, creativity, long context
TESTS=(
  "Quick Start|Latency|Ответь одним словом: READY."
  "Trap|Reasoning|Дан список чисел: [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]. Найди второе по величине ДУНОВНОЕ число."
  "Expertise|Knowledge|Объясни три ключевых отличия между протоколами ELRS и Crossfire для FPV дронов."
  "Data Process|Data|На базе этого текста подготовь JSON: 'У нас в чате не так много людей. Ивану 25 лет, он из Москвы, работает курьером; его другу Паше из Вологды 23, он - программист. Ещё в чате есть Женя, ей 30 лет, она из Нью-Йорка, и она работает в SMM вместе с Машей, которой всего 18 лет. Девочки живут вместе. Ещё есть Вовчик из Гуанчжоу, ему под сорок, а занимается он... Непонятно чем.' Сам реши, сколько и каких полей в таблице должно быть."
  "Calculations|Math|Рассчитай стоимость доставки до Москвы из Китая 400кг груза при цене доставки \$2.5 за кг, страховке 2%, растаможке 15%, НДС 20%. Цена груза \$1000, Выдай расчёт с объяснением."
  "Code|Codegen|Напиши на Python скрипт, который: 1) Читает CSV файл с колонками name, email, department, salary. 2) Фильтрует сотрудников с зарплатой выше 100000. 3) Группирует по отделам, считает среднюю зарплату. 4) Сохраняет результат в JSON. Добавь обработку ошибок, type hints и docstrings."
  "UI|Frontend|Создай одностраничный HTML-файл (без внешних зависимостей) для дашборда. Шапка: заголовок Dashboard, справа бейдж Online (зелёный кружок). Три карточки: Requests 1247 | Avg TPS 142.8 | Uptime 99.7%. Таблица с колонками Model, Status, TPS, Last Used — 5 строк. Низ: кнопка Export CSV (синяя) и текст Updated 2 min ago. Тёмная тема, всё в одном HTML с inline CSS."
  "Creativity|Writing|Напиши 5 агрессивных кликбейтных заголовков для YouTube-ролика про новый складной смартфон Huawei Mate XT (тройной сгиб, мировая новинка)."
  "Summary|Context|Сделай краткое резюме дня на основе лога: 09:15 - Созвон с китайцем Ли Вэй, 400кг груз, логистика $2.5/кг, страховка 2%, 14 дней. 11:30 - Моторы Foxeer Datura 2105.5, проверить KV 2650/1650. 14:00 - Обед, поездку в Тайчжоу отложили. 16:45 - Premiere вылетает на 4K рендере, чистить кэш. 19:20 - Pixel 11 Pro XL на таможне, ошибка в акте. 22:00 - Бэкап NAS, OpenClaw тупит в TUI."
  "Long Context|LongContext|LONGCTX_FILE:data/incident_log.txt"
)

# Get list of installed models
get_installed_models() {
    ollama list 2>/dev/null | awk 'NR>1 && $2 != "-" && $2 ~ /[0-9]/ {print $1}' | sort
}

# Get models (installed only, with real sizes from ollama list)
get_models_info() {
    ollama list 2>/dev/null | awk 'NR>1 && $2 != "-" && $3 ~ /[0-9]/ {
        name = $1; size = $3; unit = $4
        if (unit == "GB") gb = size + 0
        else if (unit == "MB") gb = size / 1024
        else gb = size + 0
        printf "%s %.2f\n", name, gb
    }' | sort -k2 -n
}

# Model selection screen
unified_model_selection() {
    local models_info="$1"
    local temp_file=$(mktemp)
    
    > "$temp_file"
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local model=$(echo "$line" | awk '{print $1}')
        local size_gb=$(echo "$line" | awk '{print $2}')
        printf "%-50s %sGB\n" "$model" "$size_gb" >> "$temp_file"
    done <<< "$models_info"
    
    # Run fzf
    local selected=$(fzf --multi --height=60% --reverse --border \
        --prompt="Select models (SPACE=toggle, ENTER=confirm)> " \
        --header="--- OLLAMA BENCHMARK --- Installed models (sorted by size)" \
        --bind 'space:toggle+down' \
        --bind 'tab:toggle+down' \
        < "$temp_file")
    
    rm -f "$temp_file"
    
    # Extract selected model names
    echo "$selected" | awk '{print $1}' > /tmp/ollama_selected_testing.txt
}

# Run a single benchmark (bench.sh engine: stream:true, TTFT, VRAM, audit)
run_benchmark() {
    local model="$1"
    local test_style="$2"
    local prompt="$3"
    local output_file="$4"
    local audit_file="$5"
    local disk_size="$6"
    local ctx_win="$7"
    local temp_val="$8"
    local top_p="$9"

    # Progress to stderr (not polluting table)
    chat_msg "  ${CYAN}Running ${test_style}...${NC}"

    # Build JSON with custom or default settings (from bench.sh)
    if [ "$USE_CUSTOM" = true ]; then
        json_data=$(jq -n --arg m "$model" --arg p "$prompt" \
          --arg t "$CUSTOM_TEMP" --arg s "$CUSTOM_SEED" --arg c "$CUSTOM_CTX" \
          --arg tp "$CUSTOM_TOP_P" --arg tk "$CUSTOM_TOP_K" \
          '{model: $m, prompt: $p, stream: true, options: {temperature: ($t|tonumber), seed: ($s|tonumber), num_ctx: ($c|tonumber), top_p: ($tp|tonumber), top_k: ($tk|tonumber)}}')
    else
        json_data=$(jq -n --arg m "$model" --arg p "$prompt" '{model: $m, prompt: $p, stream: true}')
    fi

    # Parallel VRAM monitoring (from bench.sh)
    (
        for (( i=0; i<30; i++ )); do
            vram=$(curl -s http://localhost:11434/api/ps | jq -r --arg m "$model" '.models[] | select(.name==$m or (.name | endswith($m))) | .size_vram' 2>/dev/null)
            if [[ -n "$vram" && "$vram" != "null" && "$vram" != "0" ]]; then
                echo "$vram" > /tmp/ollama_mem_tmp
                break
            fi
            sleep 0.5
        done
    ) &
    RAM_PID=$!

    # Stream generation to temp file (from bench.sh)
    tmp_stream="/tmp/ollama_stream.json"
    curl -s -X POST http://localhost:11434/api/generate -d "$json_data" > "$tmp_stream"

    # Wait for VRAM measurement
    wait $RAM_PID 2>/dev/null
    vram_bytes=$(cat /tmp/ollama_mem_tmp 2>/dev/null)
    mem_usage=$(echo "$vram_bytes" | awk '{if ($1>0) printf "%.1fG", $1/1024/1024/1024; else printf "IDLE"}')

    # Extract metrics from last line (final stats chunk)
    raw_response=$(tail -n 1 "$tmp_stream")

    # Full answer from all chunks for audit (from bench.sh)
    full_answer=$(jq -j '.response // empty' "$tmp_stream" 2>/dev/null)

    # Parse metrics (from bench.sh)
    total_ns=$(echo "$raw_response" | jq -r '.total_duration // 0')
    ttft_ns=$(echo "$raw_response" | jq -r '.prompt_eval_duration // 0')
    eval_count=$(echo "$raw_response" | jq -r '.eval_count // 0')
    eval_dur=$(echo "$raw_response" | jq -r '.eval_duration // 0')

    total_sec=$(awk -v ns="$total_ns" 'BEGIN {printf "%.1f", ns/1000000000}')
    ttft_ms=$(awk -v ns="$ttft_ns" 'BEGIN {printf "%.0f", ns/1000000}')

    if (( eval_count > 0 && eval_dur > 0 )); then
        tps=$(awk -v cnt="$eval_count" -v dur="$eval_dur" 'BEGIN {printf "%.1f", cnt/(dur/1000000000)}')
    else
        tps="N/A"
    fi

    status="OK"
    [[ -z "$total_ns" || "$total_ns" == "0" ]] && status="ERR"

    short_name=$(echo "$model" | awk '{ if (length($0) > 22) print substr($0, 1, 8) ".." substr($0, length($0)-11); else print $0 }')

    # Print to table (from bench.sh format)
    log_table "$TABLE_FORMAT" \
      "$short_name" "$test_style" "${total_sec}s" "${ttft_ms}ms" "$tps" \
      "$mem_usage" "$disk_size" "$ctx_win" "$temp_val" "$top_p" "$status"

    # Write to audit file (full response)
    {
      echo "=== Model: $model | Style: $test_style ==="
      echo "Answer: $full_answer"
      echo -e "-----------------------------------\n"
    } >> "$audit_file"

    rm -f /tmp/ollama_mem_tmp

    if [ "$status" = "ERR" ]; then
        chat_msg " ${RED}FAILED${NC}"
        return 1
    fi

    chat_msg " ${GREEN}OK${NC} — ${tps} tok/s"
    return 0
}

# Test a model (bench.sh style)
test_model() {
    local model="$1"
    local output_file="$2"
    local audit_file="$3"

    chat_msg "\n${BOLD}${MAGENTA}Testing: $model${NC}"
    echo "Model: $model" >> "$output_file"

    # Check if model exists
    if ! ollama show "$model" &>/dev/null; then
        chat_msg "  ${RED}Model not found, skipping${NC}"
        echo "  ERROR: Model not found" >> "$output_file"
        return 1
    fi

    # Skip embedding models (not text generators)
    local mod_template=$(ollama show --modelfile "$model" 2>/dev/null | head -5)
    local model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
    if echo "$model_lower" | grep -qE 'embed|mxbai|nomic.*embed|all-minilm'; then
        chat_msg "  ${YELLOW}Embedding model, skipping${NC}"
        return 1
    fi

    # Get model info
    local disk_size=$(ollama list | grep "${model: -12}" | awk '{for(i=1;i<=NF;i++) if($i=="GB" || $i=="MB") {print $(i-1)$i; exit}}')
    [[ -z "$disk_size" ]] && disk_size="???"

    local mod_info=$(ollama show --parameters "$model" 2>/dev/null)
    local ctx_win=$(echo "$mod_info" | grep -i "num_ctx" | awk '{print $2}'); [[ -z "$ctx_win" ]] && ctx_win="8k*"
    local temp_val=$(echo "$mod_info" | grep -i "temperature" | awk '{print $2}'); [[ -z "$temp_val" ]] && temp_val="0.7*"
    local top_p_val=$(echo "$mod_info" | grep -i "top_p" | awk '{print $2}'); [[ -z "$top_p_val" ]] && top_p_val="0.9*"

    if [ "$USE_CUSTOM" = true ]; then
        ctx_win=$CUSTOM_CTX; temp_val=$CUSTOM_TEMP; top_p_val=$CUSTOM_TOP_P
    fi

    # Flush memory before loading (from bench.sh)
    chat_msg "  ${BLUE}Flushing memory...${NC}"
    flush_memory "$model"

    # Run test matrix
    for test in "${TESTS[@]}"; do
        test_style=$(echo "$test" | cut -d'|' -f1)
        test_category=$(echo "$test" | cut -d'|' -f2)
        test_prompt=$(echo "$test" | cut -d'|' -f3)
        # Skip Trap test for coding models — they hang on it
        model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
        if [[ "$model_lower" == *coding* && "$test_style" == "Trap" ]]; then
            chat_msg "  ${YELLOW}⏭ Skipping Trap test for coding model${NC}"
            echo "$model  $test_style              Skip    —      —       —      ${disk_size}GB  $ctx_win  $temp_val  TOP  Skip (coding)" >> "$output_file"
            echo -e "\n=== Model: $model | Style: $test_style ===\nAnswer: SKIP (coding models hang on Trap)\n-----------------------------------\n" >> "$audit_file"
            continue
        fi
        # Load prompt from file if LONGCTX_FILE: prefix
        if [[ "$test_prompt" == LONGCTX_FILE:* ]]; then
            local ctx_file="${test_prompt#LONGCTX_FILE:}"
            # Resolve relative to script dir
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            ctx_file="$script_dir/$ctx_file"
            if [ -f "$ctx_file" ]; then
                test_prompt=$(cat "$ctx_file")
            else
                chat_msg "  ${RED}Long context file not found: $ctx_file${NC}"
                continue
            fi
        fi
        # Prepend web context if WEBCTX: prefix (cached from main, used in Creativity test)
        if [[ "$test_prompt" == WEBCTX:* ]]; then
            test_prompt="${test_prompt#WEBCTX:}"
            test_prompt="Context: $WEB_CONTEXT

$test_prompt"
        fi
        run_benchmark "$model" "$test_style" "$test_prompt" "$output_file" "$audit_file" "$disk_size" "$ctx_win" "$temp_val" "$top_p_val"
    done

    echo "" >> "$output_file"
}

main() {
    check_deps

    # Get installed models
    echo -e "${BLUE}Scanning system...${NC}"
    local installed_models=$(get_installed_models)
    local installed_count=$(echo "$installed_models" | wc -l | tr -d ' ')

    echo -e "  Found ${GREEN}$installed_count${NC} installed models"

    # Get known models
    local models_info=$(get_models_info)
    local total_count=$(echo "$models_info" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')

    echo -e "  Models with sizes: ${GREEN}$total_count${NC}"
    echo ""

    # Auto-selection or interactive
    if [ "$AUTO_ALL" = true ]; then
        # Auto-select all models (except embeddings, vision, cloud)
        local selected_testing=$(echo "$installed_models" | grep -viE 'embed|mxbai|nomic.*embed|all-minilm|-vision:|cloud')
        chat_msg "${BLUE}Auto-selected all models:${NC}"
        echo "$selected_testing" | while read -r m; do [[ -n "$m" ]] && chat_msg "    - $m"; done
    else
        # Show selection
        unified_model_selection "$models_info"

        # Read selection
        selected_testing=$(cat /tmp/ollama_selected_testing.txt 2>/dev/null | grep -v '^[[:space:]]*$')
        rm -f /tmp/ollama_selected_testing.txt
    fi

    local test_count=$(echo "$selected_testing" | grep -c '[^[:space:]]' || true)
    test_count=${test_count:-0}

    if [ "$test_count" -eq 0 ]; then
        echo -e "${YELLOW}No models selected. Exiting.${NC}"
        exit 0
    fi

    echo ""
    echo -e "${BOLD}Selected for testing: ${GREEN}$test_count${NC} models${NC}"
    echo "$selected_testing" | while read -r m; do [[ -n "$m" ]] && echo "    - $m"; done

    # Output files (same as bench.sh)
    local output_file="$RESULTS_DIR/OB-MV-Results${OUTPUT_SUFFIX}.txt"
    local audit_file="$RESULTS_DIR/OB-MV-Answers${OUTPUT_SUFFIX}.txt"

    # Clear previous runs
    > "$output_file"
    > "$audit_file"

    echo -e "\n${BLUE}Results will be saved to:${NC}"
    echo -e "  Results: $output_file"
    echo -e "  Audit:   $audit_file"

    # Header for results
    echo "Ollama Benchmark Results" >> "$output_file"
    echo "========================" >> "$output_file"
    echo "Date: $(date)" >> "$output_file"
    echo "System: $NUM_CORES cores, ${AVAILABLE_MEM}GB RAM" >> "$output_file"
    echo "Mode: $([ "$USE_CUSTOM" = true ] && echo "CUSTOM (Temp=$CUSTOM_TEMP, Seed=$CUSTOM_SEED)" || echo "DEFAULT")" >> "$output_file"
    echo "" >> "$output_file"

    # Table format (from bench.sh): Model(22) Style(12) Time(7) TTFT(7) TPS(6) RAM(7) Disk(8) Ctx(6) Temp(5) P(4) Stat(5)
    TABLE_FORMAT="%-22s %-12s %-7s %-7s %-6s %-7s %-8s %-6s %-5s %-4s %-5s\n"
    log_table() { printf "$@" >> "$output_file"; }

    chat_msg "\n${BOLD}${CYAN}--- OLLAMA ADVANCED BENCHMARK ---${NC}"
    log_table "$TABLE_FORMAT" "Model" "Test Style" "Time" "TTFT" "TPS" "RAM" "Disk" "Ctx" "Temp" "P" "Stat"
    log_table "$TABLE_FORMAT" "----------------------" "------------" "-------" "-------" "------" "-------" "--------" "------" "-----" "----" "-----"

    # Run tests
    chat_msg "\n${BOLD}${CYAN}Starting benchmarks on $test_count models...${NC}"

    # Pre-fetch web context once for Creativity test (not per model)
    chat_msg "${BLUE}Fetching web context...${NC}"
    WEB_CONTEXT=$(get_web_context)
    export WEB_CONTEXT
    chat_msg "  ${GREEN}Cached ${#WEB_CONTEXT} chars${NC}"
    echo "$selected_testing" | while read -r model; do
        [[ -n "$model" ]] && test_model "$model" "$output_file" "$audit_file"
    done

    # Final summary
    chat_msg "\\n${BOLD}${CYAN}==========================================================${NC}"
    chat_msg "${BOLD}${CYAN}   Benchmark Complete${NC}"
    chat_msg "${BOLD}${CYAN}==========================================================${NC}"
    chat_msg "${GREEN}Results saved to:${NC}"
    chat_msg "  Results: $output_file"
    chat_msg "  Audit:   $audit_file"

    # Always generate dashboard + analysis (both console and chat mode)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dashboard_file="$RESULTS_DIR/benchmark_dashboard.html"
    local analysis_file="$RESULTS_DIR/OB-MV-Analysis.md"
    
    chat_msg "\n${BLUE}Generating dashboard...${NC}"
    python3 "$script_dir/generate_dashboard.py" "$output_file" "$RESULTS_DIR" 2>/dev/null
    
    if [ -f "$dashboard_file" ]; then
        chat_msg "${GREEN}Dashboard: $dashboard_file${NC}"
    fi
    if [ -f "$analysis_file" ]; then
        chat_msg "${GREEN}Analysis:   $analysis_file${NC}"
        # In chat mode: print analysis to stdout too
        if [ "$CHAT_MODE" = true ]; then
            chat_msg "\n${BOLD}--- ANALYSIS ---${NC}"
            cat "$analysis_file"
        fi
    fi

    # Print table
    chat_msg "\\n${BOLD}Results table:${NC}"
    cat "$output_file" | while IFS= read -r line; do chat_msg "$line"; done

    # Top 5 by TPS with model names
    chat_msg "\\n${BOLD}Top 5 by TPS:${NC}"
    grep -v '^-|^Model\|^$\|^Date\|^System\|^Mode\|^Ollama' "$output_file" | \
        awk 'NF >= 6 && $5 ~ /^[0-9.]+$/ {printf "%s|%s|%s|%s|%s\n", $5, $1, $4, $6, $2}' | \
        sort -t'|' -k1 -rn | head -5 | \
        awk -F'|' '{printf "  %-22s %8s tok/s  (TTFT: %s, %s, %s)\n", $2, $1, $3, $4, $5}' | \
        while IFS= read -r line; do chat_msg "$line"; done
}

# Run main
main
