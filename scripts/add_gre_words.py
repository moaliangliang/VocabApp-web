#!/usr/bin/env python3
"""Script to add 820 GRE vocabulary words to GRE.json."""
import json
import os

FILE_PATH = "/Users/maoliangliang/workspace/app/VocabApp/Resources/WordBanks/GRE.json"

# Load existing data
with open(FILE_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

existing_words_lower = {w["word"].lower() for w in data["words"]}
print(f"Existing words: {len(data['words'])}")

from word_data import NEW_WORDS

# Filter out duplicates
to_add = []
for entry in NEW_WORDS:
    if entry["word"].lower() not in existing_words_lower:
        to_add.append(entry)

print(f"New unique words to add: {len(to_add)}")

# Assign IDs starting from current count
start_id = len(data["words"]) + 1
for i, entry in enumerate(to_add):
    entry["id"] = f"GRE_{start_id + i:04d}"
    data["words"].append(entry)

# Save
with open(FILE_PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Added {len(to_add)} words. Total: {len(data['words'])}")
print(f"Last word: {data['words'][-1]['word']}, Last ID: {data['words'][-1]['id']}")
