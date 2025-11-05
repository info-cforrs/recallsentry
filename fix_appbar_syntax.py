#!/usr/bin/env python3
"""
Fix AppBar syntax errors caused by automated back button insertion
"""

import os
import re
from pathlib import Path

def fix_appbar_syntax(content):
    """Fix malformed AppBar with leading parameter"""
    # Pattern: AppBar( ... backgroundColor: ...
    # leading: const CustomBackButton(),),
    # Should be: backgroundColor: ...),
    # leading: const CustomBackButton(),

    # Fix pattern where leading is inserted incorrectly
    pattern = r'(backgroundColor:\s*const\s*Color\([^)]+\))\s*\n\s*(leading:\s*const\s*CustomBackButton\(\),),([^\n]*)'
    replacement = r'),\n      \2\n      \1\3'

    content = re.sub(pattern, replacement, content)

    # Another pattern: fix double commas and misplaced closing parens
    content = re.sub(r',\),\s*\n\s*(leading:)', r',\n      \1', content)

    return content

def process_file(filepath):
    """Process a single Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        content = fix_appbar_syntax(content)

        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Fixed: {filepath.name}")
            return True
        else:
            return False

    except Exception as e:
        print(f"  ERROR: {filepath.name}: {e}")
        return False

def main():
    pages_dir = Path('lib/pages')
    dart_files = list(pages_dir.glob('*.dart'))

    print("Fixing AppBar syntax errors...")
    fixed_count = 0

    for filepath in sorted(dart_files):
        if process_file(filepath):
            fixed_count += 1

    print(f"\nFixed {fixed_count} files")

if __name__ == '__main__':
    main()
