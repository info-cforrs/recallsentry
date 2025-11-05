#!/usr/bin/env python3
"""
Simple script to add back buttons by adding the import and inserting
a back button widget before the app icon in the header
"""

import re
from pathlib import Path

def add_back_button(filepath):
    """Add back button to a page file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already has custom_back_button import
    if 'custom_back_button.dart' in content:
        return False, "Already has back button import"

    # Skip main navigation pages
    if filepath.name in ['home_page.dart', 'main_navigation.dart']:
        return False, "Main navigation page"

    # Skip if no Scaffold
    if 'Scaffold' not in content:
        return False, "No Scaffold"

    # Add import after last import line
    import_pattern = r"(import '[^']+';)"
    imports = list(re.finditer(import_pattern, content))
    if imports:
        last_import = imports[-1]
        insert_pos = last_import.end()
        content = (content[:insert_pos] +
                  "\nimport '../widgets/custom_back_button.dart';" +
                  content[insert_pos:])

    # Now add back button in header - look for the Row with app icon pattern
    # Pattern: Row( children: [ GestureDetector (app icon)
    # Insert CustomBackButton before the GestureDetector

    header_pattern = r'(Row\s*\(\s*children:\s*\[)\s*(//[^\n]*)?\s*(GestureDetector\s*\()'

    def add_button(match):
        row_start = match.group(1)
        comment = match.group(2) or ''
        gesture = match.group(3)

        # Add back button before app icon
        return (f"{row_start}\n"
                f"                  const CustomBackButton(),\n"
                f"                  const SizedBox(width: 8),\n"
                f"                  {comment}\n"
                f"                  {gesture}" if comment else
                f"{row_start}\n"
                f"                  const CustomBackButton(),\n"
                f"                  const SizedBox(width: 8),\n"
                f"                  {gesture}")

    new_content = re.sub(header_pattern, add_button, content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True, "Updated"

    return False, "No matching pattern"

def main():
    pages_dir = Path('lib/pages')
    dart_files = list(pages_dir.glob('*.dart'))

    print("Adding back buttons to pages...\n")

    updated = []
    skipped = []

    for filepath in sorted(dart_files):
        success, reason = add_back_button(filepath)
        if success:
            updated.append(filepath.name)
            print(f"  SUCCESS: {filepath.name}")
        else:
            skipped.append((filepath.name, reason))

    print(f"\n=== Summary ===")
    print(f"Updated: {len(updated)} pages")
    print(f"Skipped: {len(skipped)} pages")

    if updated:
        print(f"\nUpdated pages:")
        for name in updated:
            print(f"  - {name}")

if __name__ == '__main__':
    main()
