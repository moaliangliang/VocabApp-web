#!/usr/bin/env python3
"""Add 490 TOEFL vocabulary words to TOEFL.json"""

import json, os, sys

FILEPATH = '/Users/maoliangliang/workspace/app/VocabApp/Resources/WordBanks/TOEFL.json'

# ============ Word Data ============
# (word, phonetic, pos, meaning_cn, ex1, ex2, root, [syns], [ants])
WORDS = [
