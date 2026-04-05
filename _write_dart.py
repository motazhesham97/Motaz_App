#!/usr/bin/env python3
"""Helper to write Dart files without corruption."""
import sys
import os

filepath = sys.argv[1]
content = sys.stdin.read()

os.makedirs(os.path.dirname(filepath), exist_ok=True)
with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print(f"Written {len(content)} chars to {filepath}")
