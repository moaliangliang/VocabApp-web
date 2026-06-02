#!/usr/bin/env python3
"""Fix word_data.py by removing the premature list closure and rewriting properly."""
import re

filepath = "/Users/maoliangliang/workspace/app/VocabApp/scripts/word_data.py"

with open(filepath, 'r') as f:
    content = f.read()

# Find the first `]` that's not the final closing - it's at line 2156, after the A section
# The pattern is: match `    },\n]\n\n    # B`
# Replace the `]\n` with nothing, keeping the list open
old = "    },\n]\n\n    # B"
new = "    },\n    # B"

if old in content:
    content = content.replace(old, new, 1)
    print("Fixed premature list closure")
else:
    print("Could not find pattern to fix")
    # Let's see what's around there
    idx = content.find("    # B")
    if idx >= 0:
        print(f"Found '# B' at position {idx}")
        print(repr(content[idx-20:idx+20]))

with open(filepath, 'w') as f:
    f.write(content)

print("Done fixing")
