#!/usr/bin/env python3
"""
Add back buttons to all Flutter pages that don't have them.
Excludes main navigation pages: home_page, info_page, settings_page
"""

import os
import re
from pathlib import Path

# Pages that should NOT have back buttons (main navigation pages)
EXCLUDED_PAGES = [
    'home_page.dart',
    'main_navigation.dart',
    # Info and Settings can have back buttons since they're accessed from navigation
]

def add_back_button_import(content):
    """Add CustomBackButton import if not present"""
    if "import '../widgets/custom_back_button.dart'" in content:
        return content  # Already imported

    # Find the last import statement
    imports = re.findall(r"^import [^\n]+;$", content, re.MULTILINE)
    if imports:
        last_import = imports[-1]
        # Add our import after the last import
        content = content.replace(
            last_import,
            last_import + "\nimport '../widgets/custom_back_button.dart';"
        )

    return content

def has_back_button(content):
    """Check if page already has a back button"""
    patterns = [
        r'CustomBackButton',
        r'IconButton.*Icons\.arrow_back',
        r'leading:.*IconButton',
    ]
    for pattern in patterns:
        if re.search(pattern, content, re.DOTALL):
            return True
    return False

def add_back_button_to_appbar(content):
    """Add back button to AppBar if it doesn't have one"""
    # Pattern to find AppBar without leading
    appbar_pattern = r'(AppBar\s*\([^)]*?)(\))'

    def add_leading(match):
        appbar_content = match.group(1)
        closing_paren = match.group(2)

        # Check if already has leading
        if 'leading:' in appbar_content:
            return match.group(0)  # Don't modify

        # Check if automaticallyImplyLeading is false
        if 'automaticallyImplyLeading: false' in appbar_content:
            return match.group(0)  # Don't modify

        # Add leading with CustomBackButton
        # Find the last parameter before closing
        if ',' in appbar_content:
            # Add after last comma
            return appbar_content + ',\n      leading: const CustomBackButton(),' + closing_paren
        else:
            # No parameters yet, add as first parameter
            return appbar_content + '\n      leading: const CustomBackButton(),' + closing_paren

    content = re.sub(appbar_pattern, add_leading, content, flags=re.DOTALL)
    return content

def add_back_button_to_custom_header(content):
    """Add back button to custom header (like info_page style)"""
    # Look for custom headers with Row and no back button
    header_pattern = r'(// Custom Header.*?Row\s*\(\s*children:\s*\[)([^\]]+?)(\],?\s*\),)'

    def add_button(match):
        comment = match.group(1)
        children_content = match.group(2)
        closing = match.group(3)

        # Check if already has back button
        if 'arrow_back' in children_content or 'CustomBackButton' in children_content:
            return match.group(0)

        # Add CustomBackButton as first child
        new_children = f"\n                const CustomBackButton(),\n                const SizedBox(width: 8),{children_content}"
        return comment + new_children + closing

    content = re.sub(header_pattern, add_button, content, flags=re.DOTALL)
    return content

def process_file(filepath):
    """Process a single Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Skip if excluded
        if any(excluded in filepath.name for excluded in EXCLUDED_PAGES):
            print(f"  Skipped (excluded): {filepath.name}")
            return False

        # Skip if already has back button
        if has_back_button(content):
            print(f"  Skipped (has back button): {filepath.name}")
            return False

        # Skip if no Scaffold (not a page)
        if 'Scaffold' not in content:
            print(f"  Skipped (no Scaffold): {filepath.name}")
            return False

        original_content = content

        # Add import
        content = add_back_button_import(content)

        # Try to add to AppBar
        content = add_back_button_to_appbar(content)

        # Try to add to custom header
        content = add_back_button_to_custom_header(content)

        # Only write if changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  SUCCESS: Updated {filepath.name}")
            return True
        else:
            print(f"  Skipped (no changes): {filepath.name}")
            return False

    except Exception as e:
        print(f"  ERROR: Error processing {filepath.name}: {e}")
        return False

def main():
    pages_dir = Path('lib/pages')

    if not pages_dir.exists():
        print("Error: lib/pages directory not found")
        return

    print("Adding back buttons to Flutter pages...")
    print()

    dart_files = list(pages_dir.glob('*.dart'))
    updated_count = 0

    for filepath in sorted(dart_files):
        if process_file(filepath):
            updated_count += 1

    print()
    print(f"Summary: Updated {updated_count} out of {len(dart_files)} pages")

if __name__ == '__main__':
    main()
