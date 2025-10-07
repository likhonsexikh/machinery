# machinery

Utility scripts for experimenting with agent orchestration workflows.

## GitHub Actions automation

This repository now ships with a **PR Automation** workflow that can be triggered
manually to create pull requests, approve them, or run smoke tests against an
open PR. Launch it from the **Actions** tab and choose the desired `create`,
`approve`, or `run-tests` action. The workflow executes with read/write
permissions across repository scopes so the GitHub CLI can manage pull requests
on your behalf.

## XML multi-agent builder

`build_model_xml.sh` coordinates researcher and architect sub-agents using
structured XML prompts. The script incrementally grows a synthetic model file
until it reaches a configurable size while streaming progress updates to the
terminal.

Before running, set a Google Generative AI API key through either the
`GEMINI_API_KEY` environment variable or a `~/.gemini_api_key` file. Then
execute:

```bash
chmod +x build_model_xml.sh
./build_model_xml.sh
```

### One-liner cheat sheet

The following shell snippets capture common operations end-to-end:

| Goal | Command |
| --- | --- |
| Install publishing dependencies | `python -m pip install --upgrade huggingface_hub` |
| Generate an MCP catalogue with the default servers | `python configure_spaces_mcp.py` |
| Run the XML multi-agent builder | `./build_model_xml.sh` |
| Trigger the shell-based model builder | `./build_model.sh` |
| Publish the generated model artifact to Hugging Face (requires `huggingface_hub`) | `huggingface-cli upload <namespace>/<repo> TermuxOmniModel_core.sh.py` |

Optional environment variables:

* `TARGET_SIZE_MB` – override the goal size (default: 500)
* `MODEL_FILENAME` – customize the generated artifact name
* `API_KEY_FILE` – point to a different key cache path

## MCP configuration generator

`configure_spaces_mcp.py` produces a ready-to-use Model Context Protocol configuration
that treats popular Hugging Face Spaces as tool servers and includes the official
"Everything" MCP server for protocol compliance testing.

### Usage

List the curated catalogue without writing any files:

```bash
python configure_spaces_mcp.py --list-only
```

Generate a configuration containing every known Space:

```bash
python configure_spaces_mcp.py
```

Write a configuration with only the Everything server and Stable Diffusion Space:

```bash
python configure_spaces_mcp.py --include everything stable-diffusion --output custom_mcp.json
```

The resulting JSON follows the structure expected by MCP-aware clients such as Claude
Desktop or the VS Code MCP extension. Point the client to the generated file to make
those Spaces (and the Everything MCP server) available as tools.
