"""
SAYN GEC & Speech Corruptor Engine
Generates realistic mobile keyboard typos and spoken voice disfluencies
to train robust grammar correction and conciseness models.
"""

import random
import re
from typing import Tuple, List

# Proximity map on standard QWERTY layout
QWERTY_NEIGHBORS = {
    'q': ['w', 'a', 's'],
    'w': ['q', 'e', 'a', 's', 'd'],
    'e': ['w', 'r', 's', 'd', 'f'],
    'r': ['e', 't', 'd', 'f', 'g'],
    't': ['r', 'y', 'f', 'g', 'h'],
    'y': ['t', 'u', 'g', 'h', 'j'],
    'u': ['y', 'i', 'h', 'j', 'k'],
    'i': ['u', 'o', 'j', 'k', 'l'],
    'o': ['i', 'p', 'k', 'l'],
    'p': ['o', 'l'],
    'a': ['q', 'w', 's', 'z'],
    's': ['w', 'e', 'a', 'd', 'z', 'x'],
    'd': ['e', 'r', 's', 'f', 'x', 'c'],
    'f': ['r', 't', 'd', 'g', 'c', 'v'],
    'g': ['t', 'y', 'f', 'h', 'v', 'b'],
    'h': ['y', 'u', 'g', 'j', 'b', 'n'],
    'j': ['u', 'i', 'h', 'k', 'n', 'm'],
    'k': ['i', 'o', 'j', 'l', 'm'],
    'l': ['o', 'p', 'k'],
    'z': ['a', 's', 'x'],
    'x': ['z', 's', 'd', 'c'],
    'c': ['x', 'd', 'f', 'v'],
    'v': ['c', 'f', 'g', 'b'],
    'b': ['v', 'g', 'h', 'n'],
    'n': ['b', 'h', 'j', 'm'],
    'm': ['n', 'j', 'k']
}

# Common contractions with dropped apostrophes
CONTRACTIONS = {
    "don't": "dont",
    "can't": "cant",
    "won't": "wont",
    "it's": "its",
    "i'm": "im",
    "you're": "youre",
    "they're": "theyre",
    "we're": "were",
    "haven't": "havent",
    "hasn't": "hasnt",
    "wasn't": "wasnt",
    "weren't": "werent",
    "shouldn't": "shouldnt",
    "wouldn't": "wouldnt",
    "couldn't": "couldnt",
    "that's": "thats",
    "there's": "theres",
    "what's": "whats",
    "let's": "lets",
}

# Common homophone confusions in typed/spoken text
HOMOPHONES = [
    ("their", "there"),
    ("there", "they're"),
    ("they're", "there"),
    ("your", "you're"),
    ("you're", "your"),
    ("its", "it's"),
    ("it's", "its"),
    ("too", "to"),
    ("to", "too"),
    ("two", "to"),
    ("affect", "effect"),
    ("effect", "affect"),
    ("then", "than"),
    ("than", "then"),
    ("lose", "loose"),
    ("loose", "lose"),
    ("weather", "whether"),
    ("hear", "here"),
    ("here", "hear"),
    ("buy", "by"),
    ("by", "buy"),
    ("piece", "peace"),
    ("accept", "except")
]

# Spoken disfluencies and conversational fillers
FILLERS = [
    "um", "uh", "you know", "like", "basically", "sort of",
    "kind of", "I mean", "actually", "so yeah", "right", "honestly"
]

# Spoken punctuation dictation terms
SPOKEN_PUNCTUATION = {
    ".": ["period", "full stop"],
    ",": ["comma"],
    "?": ["question mark"],
    "!": ["exclamation point", "exclamation mark"],
    "\n": ["new line", "next line"]
}

# Verbose / rambling sentence starters that models should condense
RAMBLING_PATTERNS = [
    (r"\bI was thinking that maybe we could\b", "We could"),
    (r"\bIn my personal opinion I really feel that\b", "I believe"),
    (r"\bAt this current point in time\b", "Currently"),
    (r"\bDue to the fact that\b", "Because"),
    (r"\bFor the purpose of\b", "To"),
    (r"\bIn order to make sure that\b", "To ensure"),
    (r"\bWould it be possible for you to please\b", "Could you please"),
    (r"\bI am writing this message to let you know that\b", "Please note that")
]


class TypoAndSpeechCorruptor:
    """Injects human mobile keyboard typos and spoken voice disfluencies."""

    def __init__(self, seed: int = 42):
        self.rng = random.Random(seed)

    def inject_keyboard_typo(self, word: str) -> str:
        """Simulates adjacent key miss, double tap, or dropped character."""
        if len(word) < 3:
            return word

        mutation_type = self.rng.choice(["adjacent", "drop", "swap", "double"])
        idx = self.rng.randint(0, len(word) - 1)
        char = word[idx].lower()

        if mutation_type == "adjacent" and char in QWERTY_NEIGHBORS:
            neighbor = self.rng.choice(QWERTY_NEIGHBORS[char])
            if word[idx].isupper():
                neighbor = neighbor.upper()
            return word[:idx] + neighbor + word[idx + 1:]

        elif mutation_type == "drop" and len(word) > 3:
            return word[:idx] + word[idx + 1:]

        elif mutation_type == "swap" and idx < len(word) - 1:
            chars = list(word)
            chars[idx], chars[idx + 1] = chars[idx + 1], chars[idx]
            return "".join(chars)

        elif mutation_type == "double":
            return word[:idx] + word[idx] + word[idx:]

        return word

    def inject_disfluency(self, words: List[str]) -> List[str]:
        """Injects spoken hesitation particles into sentence."""
        if not words:
            return words
        result = list(words)
        num_fillers = self.rng.randint(1, min(3, max(1, len(words) // 4)))
        for _ in range(num_fillers):
            insert_pos = self.rng.randint(0, len(result))
            filler = self.rng.choice(FILLERS)
            result.insert(insert_pos, filler)
        return result

    def simulate_spoken_punctuation(self, text: str) -> str:
        """Converts literal punctuation to spoken commands (e.g. 'period', 'comma')."""
        for punct, spoken_terms in SPOKEN_PUNCTUATION.items():
            if punct in text and self.rng.random() < 0.4:
                chosen = self.rng.choice(spoken_terms)
                text = text.replace(punct, f" {chosen} ")
        return re.sub(r"\s+", " ", text).strip()

    def corrupt(self, clean_sentence: str, typo_rate: float = 0.25) -> Tuple[str, str]:
        """
        Takes a clean, polished sentence and generates:
        1. A noisy, spoken/typed input with typos, fillers, and dropped formatting.
        2. The clean, concise target.
        """
        clean_target = clean_sentence.strip()
        words = clean_target.split()
        if not words:
            return clean_target, clean_target

        corrupted_words = []
        for word in words:
            lower = word.lower()
            # 1. Check for missing apostrophe
            if lower in CONTRACTIONS and self.rng.random() < 0.6:
                corrupted_words.append(CONTRACTIONS[lower])
                continue

            # 2. Check for homophone substitution
            replaced_homophone = False
            for src, dst in HOMOPHONES:
                if lower == src and self.rng.random() < 0.35:
                    corrupted_words.append(dst if word.islower() else dst.capitalize())
                    replaced_homophone = True
                    break
            if replaced_homophone:
                continue

            # 3. Probabilistic keyboard typo
            if self.rng.random() < typo_rate:
                corrupted_words.append(self.inject_keyboard_typo(word))
            else:
                corrupted_words.append(word)

        # 4. Inject spoken disfluency if sentence is sufficiently long
        if len(corrupted_words) >= 4 and self.rng.random() < 0.45:
            corrupted_words = self.inject_disfluency(corrupted_words)

        corrupted_text = " ".join(corrupted_words)

        # 5. Optionally strip or replace punctuation to mimic fast dictation / mobile typing
        if self.rng.random() < 0.3:
            corrupted_text = self.simulate_spoken_punctuation(corrupted_text)
        elif self.rng.random() < 0.3:
            # Drop trailing period to simulate casual mobile input
            corrupted_text = corrupted_text.rstrip(".")

        # Randomize capitalization on first word (mobile lowercase habit)
        if corrupted_text and self.rng.random() < 0.4:
            corrupted_text = corrupted_text[0].lower() + corrupted_text[1:]

        return corrupted_text, clean_target
