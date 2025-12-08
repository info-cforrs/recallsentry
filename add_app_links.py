#!/usr/bin/env python3
"""Add app_links package to pubspec.yaml"""

pubspec_path = 'c:/RS_Flutter/rs_flutter/pubspec.yaml'

with open(pubspec_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add app_links after flutter_local_notifications
if 'app_links:' not in content:
    old_text = '  flutter_local_notifications: ^18.0.1'
    new_text = '''  flutter_local_notifications: ^18.0.1

  # Deep Links for email notifications
  app_links: ^6.3.3'''

    content = content.replace(old_text, new_text)

    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[OK] Added app_links package to pubspec.yaml")
else:
    print("[OK] app_links already in pubspec.yaml")
