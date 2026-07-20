#!/usr/bin/env python3
"""Check for broken file links in markdown files."""

import os
import re
import sys
from pathlib import Path
from typing import Generator

# ANSI colors
RED = '\033[0;31m'
GREEN = '\033[0;32m'
NC = '\033[0m'

def find_markdown_files(root_dir: Path) -> Generator[Path, None, None]:
    """Find all markdown files excluding .git and generated directories."""
    # Directories to skip during traversal
    skip_dirs = {'.git', 'node_modules'}

    for root, dirs, files in os.walk(root_dir):
        # Skip excluded directories
        dirs[:] = [d for d in dirs if d not in skip_dirs]

        for file in files:
            if file.endswith('.md'):
                yield Path(root) / file


def strip_code_examples(content: str) -> str:
    """Replace fenced blocks and inline code spans before link extraction."""
    content = re.sub(r'(\x60{3,}|\x7e{3,})(.*?)\1', '', content, flags=re.DOTALL)
    return re.sub(r'(\x60+)([^\x60\n]*)\1', '', content)


def extract_file_links(content: str) -> Generator[str, None, None]:
    """Extract file links from markdown content (not URLs).

    Handles both inline links [text](link) and reference-style links [text][ref].
    """
    content = strip_code_examples(content)

    # First, extract reference-style link definitions: [ref]: path
    ref_definitions = {}
    ref_pattern = r'^\[([^\]]+)\]:\s*(.+)$'
    for match in re.finditer(ref_pattern, content, re.MULTILINE):
        ref_id = match.group(1).strip()
        ref_target = match.group(2).strip()
        # Remove fragment identifier from definition
        ref_target = ref_target.split('#')[0].strip()
        ref_definitions[ref_id] = ref_target

    # Extract inline links: [text](link)
    # Fixed pattern to handle parentheses in filenames
    inline_pattern = r'\]\(([^)]+)\)'
    for match in re.finditer(inline_pattern, content):
        link = match.group(1).strip()
        # Remove fragment identifier
        link = link.split('#')[0].strip()

        # Skip empty links
        if not link:
            continue

        # Skip URLs
        if link.startswith(('http://', 'https://', 'mailto:')):
            continue

        # Skip placeholders and template variables
        if (link.startswith('<') and link.endswith('>')) or \
           (link.startswith('{') and link.endswith('}')):
            continue

        yield link

    # Extract reference-style link usages: [text][ref] or [text][]
    ref_usage_pattern = r'\[([^\]]+)\]\[([^\]]*)\]'
    for match in re.finditer(ref_usage_pattern, content):
        ref_text = match.group(1).strip()
        ref_id = match.group(2).strip()

        # If ref_id is empty, use the text as the reference ID
        if not ref_id:
            ref_id = ref_text

        # Look up the reference
        if ref_id in ref_definitions:
            link = ref_definitions[ref_id]

            # Skip URLs
            if link.startswith(('http://', 'https://', 'mailto:')):
                continue

            # Skip placeholders and template variables
            if (link.startswith('<') and link.endswith('>')) or \
               (link.startswith('{') and link.endswith('}')):
                continue

            yield link

def check_links() -> int:
    """Check all markdown files for broken links."""
    errors = 0
    root_dir = Path.cwd()

    for md_file in find_markdown_files(root_dir):
        # Resolve symlinks to get the actual file location
        real_file = md_file.resolve()
        file_dir = real_file.parent

        try:
            content = md_file.read_text(encoding='utf-8')
        except Exception as e:
            print(f"{RED}✖{NC} Error reading {md_file}: {e}")
            errors += 1
            continue

        for link in extract_file_links(content):
            # Build target path
            if link.startswith('/'):
                # Absolute path from repo root
                target = root_dir / link[1:]
            else:
                # Relative path from the actual file location (not symlink)
                target = file_dir / link

            # Normalize the path
            target = target.resolve()

            # Check if file or directory exists
            if not target.exists():
                print(f"{RED}✖{NC} Broken link in {md_file}: {link}")
                print(f"   Expected file at: {target}")
                errors += 1

    print()
    if errors > 0:
        print(f"{RED}Found {errors} broken file link(s){NC}")
        return 1
    else:
        print(f"{GREEN}✓ All file links are valid{NC}")
        return 0

if __name__ == '__main__':
    sys.exit(check_links())
