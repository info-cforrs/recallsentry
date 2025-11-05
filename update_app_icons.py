#!/usr/bin/env python3
"""
Update all app icon references to use shield_logo3.png
"""

import os
import re
from pathlib import Path

def update_icon_references(filepath):
    """Update app_icon.png and shield_logo.png references to shield_logo3.png"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Replace app_icon.png with shield_logo3.png
        content = content.replace('app_icon.png', 'shield_logo3.png')

        # Replace shield_logo.png with shield_logo3.png (but not shield_logo3.png)
        content = re.sub(r'shield_logo\.png(?!3)', 'shield_logo3.png', content)

        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Updated: {filepath.name}")
            return True
        else:
            return False

    except Exception as e:
        print(f"  ERROR: {filepath.name}: {e}")
        return False

def main():
    pages_dir = Path('lib/pages')

    if not pages_dir.exists():
        print("Error: lib/pages directory not found")
        return

    print("Updating app icon references to shield_logo3.png...")
    print()

    dart_files = list(pages_dir.glob('*.dart'))
    updated_count = 0

    for filepath in sorted(dart_files):
        if update_icon_references(filepath):
            updated_count += 1

    print()
    print(f"Summary: Updated {updated_count} out of {len(dart_files)} pages")

if __name__ == '__main__':
    main()
