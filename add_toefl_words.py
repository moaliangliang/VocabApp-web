import json
import os

filepath = '/Users/maoliangliang/workspace/app/VocabApp/Resources/WordBanks/TOEFL.json'

with open(filepath, 'r', encoding='utf-8') as f:
    data = json.load(f)

existing_lower = {w['word'].lower() for w in data['words']}
start_id = len(data['words']) + 1
print(f"Existing words: {len(data['words'])}")
print(f"Existing word set: {sorted(existing_lower)[:10]}...")

# Complete TOEFL vocabulary data
all_new_words = [
# Define all 490 new TOEFL words as tuples:
# (word, phonetic, partOfSpeech, meaning_cn, example1, example2, rootAffix, [synonyms], [antonyms])

WORD_DATA = [
