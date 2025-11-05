#!/usr/bin/env python3
"""
Check Card widgets for potential overflow issues
"""

import re
from pathlib import Path

def check_card_for_overflow(filepath):
    """Check if Card widgets have proper constraints"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        issues = []

        # Find Card widgets
        card_pattern = r'Card\('
        cards = re.finditer(card_pattern, content)

        for match in cards:
            # Get context around the Card
            start = max(0, match.start() - 500)
            end = min(len(content), match.end() + 1000)
            context = content[start:end]

            # Check for Row without Expanded/Flexible
            if 'Row(' in context:
                row_match = re.search(r'Row\([^)]*children:\s*\[', context)
                if row_match:
                    # Look ahead from Row to see if Text is wrapped
                    row_children = context[row_match.end():row_match.end()+500]
                    if 'Text(' in row_children and not ('Expanded(' in row_children or 'Flexible(' in row_children):
                        # Check if it's in a child widget
                        if 'child:' in row_children[:row_children.find('Text(')]:
                            issues.append({
                                'type': 'Row with unwrapped Text',
                                'line': content[:match.start()].count('\n') + 1,
                                'context': context[max(0, match.start()-start-50):match.end()-start+50]
                            })

        return issues

    except Exception as e:
        print(f"  ERROR: {filepath.name}: {e}")
        return []

def main():
    pages_dir = Path('lib/pages')

    if not pages_dir.exists():
        print("Error: lib/pages directory not found")
        return

    print("Checking Card widgets for overflow issues...")
    print()

    dart_files = [
        'all_fda_recalls_page.dart',
        'all_recalls_page.dart',
        'all_usda_recalls_page.dart',
        'filtered_recalls_page.dart',
        'home_page.dart',
        'info_page.dart',
        'saved_recalls_page.dart',
        'rmc_list_page.dart'
    ]

    total_issues = 0

    for filename in dart_files:
        filepath = pages_dir / filename
        if filepath.exists():
            issues = check_card_for_overflow(filepath)
            if issues:
                print(f"\n{filename}:")
                for issue in issues:
                    print(f"  Line {issue['line']}: {issue['type']}")
                    total_issues += len(issues)

    print()
    print(f"Total potential issues: {total_issues}")

if __name__ == '__main__':
    main()
