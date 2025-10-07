Of course. This is an excellent use case for a shell script, as it excels at file manipulation, command-line execution (`curl`), and persistent state management.

This script will perform exactly as requested:

1.  **One-Time API Key Prompt:** On the very first run, it will ask for the API key and save it securely to a hidden file (`~/.gemini_api_key`).
2.  **Automatic Key Loading:** On all subsequent runs, it will automatically and silently load the key from that file.
3.  **Fully Autonomous Loop:** The agent starts its building task immediately and runs without any user interaction until its goal is complete.
4.  **Persistent Goal:** The goal is to build a simulated model file (`TermuxOmniModel_core.sh.py`) until it reaches 500 MB.
5.  **Pure Shell:** It is written in `bash` and uses common command-line tools like `curl`, `sed`, and `wc`, which are universally available on systems like Termux.

---

### The Shell Script: `build_model.sh`

```bash
#!/bin/bash

# --- 🤖 Autonomous Model Builder Agent (Shell Edition) ---
# This agent's sole purpose is to build a simulated AI model file until it
# reaches the TARGET_SIZE_MB. It securely saves your API key after the first use.

# --- CONFIGURATION ---
TARGET_SIZE_MB=500
MODEL_FILENAME="TermuxOmniModel_core.sh.py"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

# --- STATE & SECURITY ---
# The API key will be stored in a hidden file in your home directory.
API_KEY_FILE="$HOME/.gemini_api_key"

# --- GOAL CALCULATION ---
BYTES_PER_MB=$((1024 * 1024))
TARGET_SIZE_BYTES=$(($TARGET_SIZE_MB * $BYTES_PER_MB))

# --- FUNCTION: Securely get the API Key ---
get_api_key() {
  if [ -f "$API_KEY_FILE" ]; then
    # If the key file exists, read it.
    API_KEY=$(cat "$API_KEY_FILE")
    echo "🔑 API Key loaded securely from $API_KEY_FILE."
  else
    # If not, prompt the user ONCE.
    echo "🔑 Google AI API Key not found."
    echo "Please enter your API key to save it for future runs."
    read -sp "API Key: " API_KEY # -s flag hides the input
    echo # Newline after hidden input
    if [ -n "$API_KEY" ]; then
      echo "$API_KEY" > "$API_KEY_FILE"
      chmod 600 "$API_KEY_FILE" # Set permissions to read/write only for the current user
      echo "✅ API Key saved securely to $API_KEY_FILE."
    else
      echo "🛑 No API Key entered. Exiting."
      exit 1
    fi
  fi

  if [ -z "$API_KEY" ]; then
    echo "🛑 API Key is empty. Please check $API_KEY_FILE or run again. Exiting."
    exit 1
  fi
}

# --- FUNCTION: The agent's "action" - calls the LLM ---
call_llm() {
  local prompt=$1

  # Sanitize the prompt for JSON by escaping quotes. A simple approach:
  local sanitized_prompt=$(echo "$prompt" | sed 's/"/\\"/g')

  # Construct the JSON payload
  local json_payload
  json_payload=$(printf '{"contents": [{"parts": [{"text": "%s"}]}]}' "$sanitized_prompt")

  # Use curl to call the API and sed to parse the response
  # This is a robust way to extract the "text" field without complex JSON tools like jq
  local response
  response=$(curl -s -X POST -H "Content-Type: application/json" \
    -H "X-goog-api-key: $API_KEY" \
    -d "$json_payload" \
    "$API_URL" | sed -n 's/.*"text": "\(.*\)"/\1/p' | sed 's/\\n/\n/g') # Handle newlines

  # Fallback in case of API error or parsing failure
  if [ -z "$response" ]; then
    echo "# Generation failed. API error or rate limit reached."
  else
    echo "$response"
  fi
}

# --- MAIN AGENT LOOP ---
run_agent() {
  echo "--- 🤖 Autonomous Model Builder Agent Initialized ---"
  echo "🎯 GOAL: Create '$MODEL_FILENAME' with a size of $TARGET_SIZE_MB MB."
  echo "--- AGENT IS NOW RUNNING. PRESS CTRL+C TO INTERRUPT. ---"

  local start_time=$(date +%s)

  # Create or clear the file at the start
  echo "# --- AUTONOMOUSLY GENERATED AI MODEL: TermuxOmniModel ---" > "$MODEL_FILENAME"
  echo "# --- GOAL: Reach $TARGET_SIZE_MB MB ---" >> "$MODEL_FILENAME"

  while true; do
    # 1. OBSERVE: Check current state (file size)
    local current_size_bytes=0
    if [ -f "$MODEL_FILENAME" ]; then
      current_size_bytes=$(wc -c < "$MODEL_FILENAME")
    fi

    # 2. DECIDE: Check if goal is met
    if (( current_size_bytes >= TARGET_SIZE_BYTES )); then
      printf "\n" # Move to a new line after the final status
      echo "--- ✅ GOAL ACHIEVED ---"
      local final_size_mb=$(echo "scale=2; $current_size_bytes / $BYTES_PER_MB" | bc)
      echo "Model '$MODEL_FILENAME' has reached the target size ($final_size_mb MB)."
      break # Exit the loop
    fi

    # Display status on a single updating line
    local current_size_mb=$(echo "scale=3; $current_size_bytes / $BYTES_PER_MB" | bc)
    local progress=$(echo "scale=2; $current_size_bytes * 100 / $TARGET_SIZE_BYTES" | bc)
    local elapsed_time=$(( $(date +%s) - start_time ))
    printf "\r    STATUS: %s / %s MB [%s%%] | Elapsed: %ss" "$current_size_mb" "$TARGET_SIZE_MB" "$progress" "$elapsed_time"

    # 3. PLAN: Decide what to build next
    local components=(
      "a complex, multi-headed self-attention mechanism"
      "a novel activation function with detailed mathematical comments"
      "a data preprocessing pipeline for image augmentation"
      "a custom loss function for handling sparse data"
      "a sophisticated learning rate scheduler"
      "a complete transformer encoder block"
      "a tokenizer utility with BPE implementation comments"
      "a memory-efficient gradient checkpointing function"
    )
    local chosen_component=${components[$RANDOM % ${#components[@]}]}
    local task_prompt="As an expert AI model architect, generate a large, detailed, and well-commented Python code block for a conceptual 'Any-to-Any' model. Your specific task is to generate the code for: **$chosen_component**. RULES: The code must be pure Python. Include extensive docstrings and inline comments. Do NOT include the full class definition or imports, only the methods or functions for this component."

    # 4. ACT: Call LLM and append the result to the model file
    local code_chunk=$(call_llm "$task_prompt")
    printf "\n\n# --- Component: %s ---\n%s" "${chosen_component^^}" "$code_chunk" >> "$MODEL_FILENAME"
    
    # Small delay to avoid hitting API rate limits
    sleep 2
  done
}


# --- SCRIPT EXECUTION STARTS HERE ---
get_api_key
run_agent
```

### How to Use

1.  **Save the Script:** Save the code above into a file named `build_model.sh`.

2.  **Make it Executable:** In your Termux terminal, give the script permission to run:
    ```bash
    chmod +x build_model.sh
    ```

3.  **Run the Agent:**
    ```bash
    ./build_model.sh
    ```

### What Happens on First Run

The script will detect that `~/.gemini_api_key` does not exist and will prompt you:

```
🔑 Google AI API Key not found.
Please enter your API key to save it for future runs.
API Key: *****************************************  <-- your input will be hidden
✅ API Key saved securely to /data/data/com.termux/files/home/.gemini_api_key.
--- 🤖 Autonomous Model Builder Agent Initialized ---
🎯 GOAL: Create 'TermuxOmniModel_core.sh.py' with a size of 500 MB.
--- AGENT IS NOW RUNNING. PRESS CTRL+C TO INTERRUPT. ---
    STATUS: 0.000 / 500 MB [0.00%] | Elapsed: 0s
```

### What Happens on Subsequent Runs

It will find the key file and load it automatically:

```
🔑 API Key loaded securely from /data/data/com.termux/files/home/.gemini_api_key.
--- 🤖 Autonomous Model Builder Agent Initialized ---
🎯 GOAL: Create 'TermuxOmniModel_core.sh.py' with a size of 500 MB.
--- AGENT IS NOW RUNNING. PRESS CTRL+C TO INTERRUPT. ---
    STATUS: 0.000 / 500 MB [0.00%] | Elapsed: 0s
```

The agent will then continue its work, tirelessly adding generated code to the file until it reaches the 500 MB goal, at which point it will gracefully exit. You can monitor its progress on the single updating status line.
