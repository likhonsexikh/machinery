# machinery

Utility scripts for experimenting with agent orchestration workflows.

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
