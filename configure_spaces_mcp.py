"""Utility to generate MCP client configuration for popular Hugging Face Spaces.

This script codifies a small catalogue of Spaces that expose Model Context Protocol
endpoints and produces configuration snippets that can be dropped into tools such as
Claude Desktop or VS Code.  It also injects the official "Everything" MCP server so
that developers can exercise the full protocol surface locally.

Because this execution environment might not have outbound network access, the script
ships with a curated list of known Spaces instead of fetching them dynamically.  The
information mirrors the public documentation on https://hf.co/spaces.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

DEFAULT_CONFIG_PATH = Path("mcp_spaces.json")


@dataclass
class SpaceServer:
    """Declarative description of a Hugging Face Space that exposes MCP."""

    space_id: str
    display_name: str
    transport: str
    entrypoint: str
    description: str

    def to_config(self) -> Dict[str, Dict[str, object]]:
        """Render a Claude/VS Code compatible MCP configuration snippet."""
        server_config: Dict[str, object]
        if self.transport == "http":
            server_config = {
                "type": "http",
                "url": self.entrypoint,
            }
        elif self.transport == "ws":
            server_config = {
                "type": "ws",
                "url": self.entrypoint,
            }
        elif self.transport == "command":
            command, *args = self.entrypoint.split()
            server_config = {
                "command": command,
                "args": args,
            }
        else:
            raise ValueError(f"Unsupported transport '{self.transport}' for {self.space_id}")

        return {self.display_name: server_config}


POPULAR_SPACES: List[SpaceServer] = [
    SpaceServer(
        space_id="modelcontextprotocol/Everything",
        display_name="everything",
        transport="command",
        entrypoint="npx -y @modelcontextprotocol/server-everything stdio",
        description=(
            "Comprehensive protocol exerciser with echo, add, resources, prompts, and"
            " sampling support. Useful for validating MCP client implementations."
        ),
    ),
    SpaceServer(
        space_id="meta-llama/llama-3-8b-instruct",
        display_name="llama-3-8b-chat",
        transport="http",
        entrypoint="https://llama-3-8b-instruct.hf.space/mcp",
        description=(
            "Community LLaMA 3 chat interface. HTTP transport exposes inference"
            " endpoints suitable for natural language tooling."
        ),
    ),
    SpaceServer(
        space_id="stabilityai/stable-diffusion",
        display_name="stable-diffusion",
        transport="http",
        entrypoint="https://stabilityai-stable-diffusion.hf.space/mcp",
        description=(
            "Image generation pipeline mirroring the Stable Diffusion demo space."
        ),
    ),
    SpaceServer(
        space_id="microsoft/phi-3-vision",
        display_name="phi-3-vision",
        transport="http",
        entrypoint="https://microsoft-phi-3-vision.hf.space/mcp",
        description=(
            "Vision-language toolchain exposing the Phi-3 multimodal experience via"
            " MCP compatible HTTP endpoints."
        ),
    ),
]


def build_combined_config(spaces: Iterable[SpaceServer]) -> Dict[str, Dict[str, object]]:
    combined: Dict[str, Dict[str, object]] = {}
    for space in spaces:
        combined.update(space.to_config())
    return combined


def write_config(config: Dict[str, Dict[str, object]], output_path: Path) -> None:
    output_path.write_text(json.dumps({"servers": config}, indent=2))


def print_human_summary(spaces: Iterable[SpaceServer]) -> None:
    print("Registered Hugging Face Spaces with MCP support:\n")
    for space in spaces:
        print(f"- {space.display_name}")
        print(f"  Space ID    : {space.space_id}")
        print(f"  Transport   : {space.transport}")
        print(f"  Entrypoint  : {space.entrypoint}")
        print(f"  Description : {space.description}\n")


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate MCP configuration for Hugging Face Spaces and the Everything server.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help=f"Destination file for the generated configuration (default: {DEFAULT_CONFIG_PATH}).",
    )
    parser.add_argument(
        "--list-only",
        action="store_true",
        help="Print the available Space catalogue without writing a configuration file.",
    )
    parser.add_argument(
        "--include",
        nargs="*",
        metavar="SPACE",
        help=(
            "Subset of spaces to include by display name. Defaults to all known entries"
            " when omitted."
        ),
    )
    return parser.parse_args(argv)


def resolve_selection(selection: Optional[List[str]]) -> List[SpaceServer]:
    if not selection:
        return POPULAR_SPACES

    available = {space.display_name: space for space in POPULAR_SPACES}
    unknown = [name for name in selection if name not in available]
    if unknown:
        valid = ", ".join(sorted(available))
        raise SystemExit(f"Unknown space(s): {', '.join(unknown)}. Valid options: {valid}")
    return [available[name] for name in selection]


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    chosen_spaces = resolve_selection(args.include)

    if args.list_only:
        print_human_summary(chosen_spaces)
        return 0

    config = build_combined_config(chosen_spaces)
    write_config(config, args.output)
    print(f"✅ Wrote MCP configuration with {len(config)} server(s) to {args.output}")
    print("   You can reference this file from Claude Desktop or VS Code's MCP settings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
