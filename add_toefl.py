import json
import os

filepath = '/Users/maoliangliang/workspace/app/VocabApp/Resources/WordBanks/TOEFL.json'

with open(filepath, 'r', encoding='utf-8') as f:
    data = json.load(f)

existing_words = {w['word'].lower() for w in data['words']}
print(f"Existing words: {len(data['words'])}")
print(f"Last ID: {data['words'][-1]['id']}")
print(f"Last word: {data['words'][-1]['word']}")
print(f"Will add words starting from ID: TOEFL_{len(data['words'])+1:04d}")

# 490 TOEFL academic vocabulary words with full metadata
new_words = [
