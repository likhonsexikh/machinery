#!/bin/bash

# --- 🤖 Autonomous Multi-Agent System (XML Prompting Edition) ---
# This version avoids baking credentials into the repository. Provide an API key via
# the GEMINI_API_KEY environment variable or the ~/.gemini_api_key file before use.

set -euo pipefail

# --- CONFIGURATION ---
TARGET_SIZE_MB=${TARGET_SIZE_MB:-500}
MODEL_FILENAME=${MODEL_FILENAME:-TermuxOmniModel_XML_Built.py}
API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
API_KEY_FILE=${API_KEY_FILE:-"$HOME/.gemini_api_key"}

# --- GOAL CALCULATION ---
BYTES_PER_MB=$((1024 * 1024))
TARGET_SIZE_BYTES=$((TARGET_SIZE_MB * BYTES_PER_MB))

# --- DYNAMIC FEEDBACK ENGINE ---
ANIM_PID=
run_animation() {
  local message=$1 emoji=$2
  local spinners=("|" "/" "-" "\\")
  while true; do
    for char in "${spinners[@]}"; do
      printf "\r# %s... %s %s" "$message" "$emoji" "$char"
      sleep 0.1
    done
  done
}
start_animation() { run_animation "$1" "$2" & ANIM_PID=$!; }
stop_animation() {
  if [ -n "${ANIM_PID:-}" ]; then
    kill "$ANIM_PID" >/dev/null 2>&1 || true
    printf "\r%*s\r" "$(tput cols 2>/dev/null || echo 80)" ""
  fi
}

# --- API KEY MANAGEMENT ---
load_api_key() {
  if [ -n "${GEMINI_API_KEY:-}" ]; then
    API_KEY=$GEMINI_API_KEY
    return
  fi

  if [ -f "$API_KEY_FILE" ]; then
    API_KEY=$(<"$API_KEY_FILE")
  else
    read -rsp "Enter Google Generative AI API key: " API_KEY
    echo
    if [ -z "$API_KEY" ]; then
      echo "API key missing; aborting." >&2
      exit 1
    fi
    printf "%s" "$API_KEY" >"$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
  fi
}

# --- CORE TOOL: LLM API Call ---
call_llm() {
  local prompt=$1
  local sanitized_prompt
  sanitized_prompt=$(printf '%s' "$prompt" | sed 's/\\/\\\\/g; s/"/\\"/g')
  local json_payload
  json_payload=$(printf '{"contents": [{"parts": [{"text": "%s"}]}]}' "$sanitized_prompt")

  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-goog-api-key: $API_KEY" \
    -d "$json_payload" \
    "$API_URL" |
    sed -n 's/.*"text": "\(.*\)"/\1/p' |
    sed 's/\\n/\n/g; s/\\"/"/g'
}

# --- SUB-AGENT: Researcher (with XML Prompting) ---
run_researcher_agent() {
  local research_topic=$1
  local prompt
  prompt=$(cat <<PROMPT
<prompt>
  <persona>
    You are a 'Hugging Face Hub Search API'. Your function is to process a research topic and return a single, relevant model ID.
  </persona>
  <instructions>
    <step>Analyze the research topic provided in the context.</step>
    <step>Identify the most popular and relevant model repository on the Hugging Face Hub that matches the topic.</step>
    <step>Return ONLY the repository ID.</step>
  </instructions>
  <context>
    <research_topic>${research_topic}</research_topic>
  </context>
  <formatting>
    <rule>Your entire response must be only the model ID.</rule>
    <rule>Do not include any other text, greetings, explanations, or markdown formatting.</rule>
  </formatting>
</prompt>
PROMPT
)

  start_animation "Researching" "🔍"
  local model_id
  model_id=$(call_llm "$prompt" | tr -d '\n[:space:]')
  stop_animation
  if [ -z "$model_id" ]; then
    echo "GENERATION_FAILED"
  else
    echo "$model_id"
  fi
}

# --- SUB-AGENT: Architect (with XML Prompting) ---
run_architect_agent() {
  local topic=$1
  local model=$2
  local prompt
  prompt=$(cat <<PROMPT
<prompt>
  <persona>
    You are an expert AI Model Architect and Senior Python Developer specializing in building blocks for large-scale neural networks.
  </persona>
  <instructions>
    Generate a large, detailed, and syntactically correct Python code block. The code must implement a key architectural component based on the provided research topic and inspiration model.
  </instructions>
  <context>
    <research_topic>${topic}</research_topic>
    <inspiration_model_id>${model}</inspiration_model_id>
  </context>
  <formatting>
    <rule>The code must be pure Python using hypothetical, self-explanatory class or method names.</rule>
    <rule>Include extensive docstrings and inline comments explaining the logic, the purpose of variables, and the overall data flow.</rule>
    <rule>Explicitly mention in comments how the implementation is inspired by the referenced model.</rule>
    <rule>Do NOT include module imports or a full class definition—only the specific functions or methods for the requested component.</rule>
  </formatting>
</prompt>
PROMPT
)

  start_animation "Generating Code" "📝"
  local code_chunk
  code_chunk=$(call_llm "$prompt")
  stop_animation
  if [ -z "$code_chunk" ]; then
    echo "GENERATION_FAILED"
  else
    echo "$code_chunk"
  fi
}

# --- PARENT AGENT: Coordinator ---
run_coordinator_agent() {
  echo "# --- 🚀 Initializing XML-Powered Multi-Agent System ---"
  echo "# 🎯 GOAL: Create '$MODEL_FILENAME' (${TARGET_SIZE_MB} MB)"
  echo "# --- [Coordinator Agent] is running the build loop. ---"

  printf "# --- AUTONOMOUSLY GENERATED AI MODEL (XML Prompting Method) ---\n" >"$MODEL_FILENAME"

  while true; do
    local current_size_bytes
    current_size_bytes=$(wc -c <"$MODEL_FILENAME")
    if (( current_size_bytes >= TARGET_SIZE_BYTES )); then
      local final_size_mb
      final_size_mb=$(echo "scale=2; $current_size_bytes / $BYTES_PER_MB" | bc)
      echo "# Finalizing... ✅ Goal Achieved!"
      echo "# [Coordinator] Task complete. Model '$MODEL_FILENAME' is ${final_size_mb} MB."
      break
    fi

    local research_topics=(
      "a state-of-the-art vision transformer (ViT) architecture"
      "a cross-attention mechanism for multi-modal fusion"
      "an efficient mixture-of-experts (MoE) layer"
      "the architecture of a modern LLM like Llama or Mistral"
      "a decoder block from a text-to-image diffusion model"
    )
    local planned_topic=${research_topics[$RANDOM % ${#research_topics[@]}]}
    echo "# Thinking... 🧠 [Coordinator] Planning component: '${planned_topic}'."

    local model_id
    model_id=$(run_researcher_agent "$planned_topic")
    if [[ "$model_id" == "GENERATION_FAILED" ]]; then
      echo "# Reasoning... 🔍 [Researcher] failed. Retrying cycle."
      sleep 5
      continue
    fi
    echo "# Reasoning... 🔍 [Researcher] found inspiration model: '$model_id'."

    local code_chunk
    code_chunk=$(run_architect_agent "$planned_topic" "$model_id")
    if [[ "$code_chunk" == "GENERATION_FAILED" ]]; then
      echo "# Generating... 📝 [Architect] failed. Retrying cycle."
      sleep 5
      continue
    fi

    printf "\n\n# --- Component: %s ---\n# --- Inspiration: %s ---\n%s" \
      "$planned_topic" "$model_id" "$code_chunk" >>"$MODEL_FILENAME"

    local current_size_mb
    current_size_mb=$(echo "scale=2; $(wc -c <"$MODEL_FILENAME") / $BYTES_PER_MB" | bc)
    echo "# Finalizing... ✅ [Coordinator] Integrated code. Current size: ${current_size_mb} MB."
    echo "------------------------------------------------------------"
    sleep 1
  done
}

main() {
  load_api_key
  run_coordinator_agent
}

main "$@"
