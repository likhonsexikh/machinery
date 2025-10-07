# machinery

Utility scripts for experimenting with agent orchestration workflows.

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
