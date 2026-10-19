#!/usr/bin/env python3
"""
SAYN GEC & Spoken Thought Dataset Builder
=========================================
Generates massive-scale (1M to 50M+ pairs) Grammatical Error Correction (GEC)
and Spoken-to-Clean-Prose training datasets for training lightweight models
(Llama-3.2-1B, Gemma-2-2B) to perform sub-120ms Wispr Flow-style conciseness.
"""

import os
import re
import json
import random
import argparse
from typing import List, Tuple, Generator, Dict

# ─────────────────────────────────────────────────────────────────────────────
# 1. Physical Keyboard QWERTY Adjacent-Key Distance Model
# ─────────────────────────────────────────────────────────────────────────────
QWERTY_NEIGHBORS: Dict[str, List[str]] = {
    'q': ['w', 'a', 's', '1', '2'],
    'w': ['q', 'e', 's', 'a', 'd', '2', '3'],
    'e': ['w', 'r', 'd', 's', 'f', '3', '4'],
    'r': ['e', 't', 'f', 'd', 'g', '4', '5'],
    't': ['r', 'y', 'g', 'f', 'h', '5', '6'],
    'y': ['t', 'u', 'h', 'g', 'j', '6', '7'],
    'u': ['y', 'i', 'j', 'h', 'k', '7', '8'],
    'i': ['u', 'o', 'k', 'j', 'l', '8', '9'],
    'o': ['i', 'p', 'l', 'k', '9', '0'],
    'p': ['o', 'l', '0'],
    'a': ['q', 'w', 's', 'z'],
    's': ['a', 'w', 'e', 'd', 'x', 'z'],
    'd': ['s', 'e', 'r', 'f', 'c', 'x'],
    'f': ['d', 'r', 't', 'g', 'v', 'c'],
    'g': ['f', 't', 'y', 'h', 'b', 'v'],
    'h': ['g', 'y', 'u', 'j', 'n', 'b'],
    'j': ['h', 'u', 'i', 'k', 'm', 'n'],
    'k': ['j', 'i', 'o', 'l', 'm'],
    'l': ['k', 'o', 'p'],
    'z': ['a', 's', 'x'],
    'x': ['z', 's', 'd', 'c'],
    'c': ['x', 'd', 'f', 'v'],
    'v': ['c', 'f', 'g', 'b'],
    'b': ['v', 'g', 'h', 'n'],
    'n': ['b', 'h', 'j', 'm'],
    'm': ['n', 'j', 'k']
}

COMMON_CONTRACTIONS: Dict[str, str] = {
    "do not": "don't", "cannot": "can't", "will not": "won't",
    "is not": "isn't", "are not": "aren't", "have not": "haven't",
    "has not": "hasn't", "it is": "it's", "I am": "I'm",
    "you are": "you're", "they are": "they're", "we are": "we're",
    "should not": "shouldn't", "would not": "wouldn't", "could not": "couldn't"
}

DISFLUENCY_FILLERS: List[str] = [
    "um", "uh", "you know", "like", "basically", "sort of",
    "kind of", "I mean", "actually", "honestly", "so yeah",
    "right now", "at the end of the day", "literally"
]

HOMOPHONES: Dict[str, List[str]] = {
    "their": ["there", "they're"],
    "there": ["their", "they're"],
    "they're": ["there", "their"],
    "your": ["you're"],
    "you're": ["your"],
    "its": ["it's"],
    "it's": ["its"],
    "then": ["than"],
    "than": ["then"],
    "affect": ["effect"],
    "effect": ["affect"],
    "loose": ["lose"],
    "lose": ["loose"],
    "accept": ["except"],
    "except": ["accept"]
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Synthetic Inverse Noiser (Translates Clean Prose into Noisy Spoken Speech)
# ─────────────────────────────────────────────────────────────────────────────
class SyntheticCorruptor:
    def __init__(self, noise_prob: float = 0.35):
        self.noise_prob = noise_prob

    def corrupt(self, text: str) -> str:
        words = text.split()
        if not words:
            return text

        noised_words = []
        for w in words:
            # 1. Spoken Disfluency Injection (15% chance per word boundary)
            if random.random() < 0.12:
                filler = random.choice(DISFLUENCY_FILLERS)
                if random.random() < 0.5:
                    noised_words.append(filler)
                else:
                    noised_words.extend([filler, "like"])

            lower_w = w.lower()

            # 2. Homophone Confusion
            if lower_w in HOMOPHONES and random.random() < 0.25:
                replacement = random.choice(HOMOPHONES[lower_w])
                noised_words.append(replacement)
                continue

            # 3. Missing Apostrophes (e.g. don't -> dont)
            if "'" in w and random.random() < 0.6:
                noised_words.append(w.replace("'", ""))
                continue

            # 4. Physical QWERTY Key Swap (Fat-finger noise)
            if len(w) > 3 and random.random() < self.noise_prob:
                char_idx = random.randint(0, len(w) - 1)
                char = w[char_idx].lower()
                if char in QWERTY_NEIGHBORS:
                    neighbor = random.choice(QWERTY_NEIGHBORS[char])
                    corrupted = w[:char_idx] + neighbor + w[char_idx+1:]
                    noised_words.append(corrupted)
                    continue

            # 5. Dropped / Doubled Letters
            if len(w) > 4 and random.random() < 0.10:
                idx = random.randint(1, len(w) - 2)
                if random.random() < 0.5:
                    # Drop letter
                    corrupted = w[:idx] + w[idx+1:]
                else:
                    # Double letter
                    corrupted = w[:idx] + w[idx] + w[idx:]
                noised_words.append(corrupted)
                continue

            noised_words.append(w)

        # 6. Lowercase & Punctuation Stripping (Simulating Raw Dictation)
        result = " ".join(noised_words)
        if random.random() < 0.7:
            # Drop trailing period to simulate spoken voice flow
            if result.endswith("."):
                result = result[:-1]
        if random.random() < 0.5:
            # Lowercase first character
            if result:
                result = result[0].lower() + result[1:]

        return result

# ─────────────────────────────────────────────────────────────────────────────
# 3. Benchmark Dataset Generators & Seed Corpora
# ─────────────────────────────────────────────────────────────────────────────
SEED_SAMPLES: List[Tuple[str, str]] = [
    # (Clean Target, Raw Noisy Spoken/Typed Input)
    ("I am heading to the store to get groceries.", "im heaidng to the store to get like groceries"),
    ("Do you have time to catch up tomorrow?", "i was like kind of wondering if u had some time to talk tommorow"),
    ("Please review the attached document when you have a moment.", "can u like please check out the attacehd doc when u get a sec"),
    ("The report was submitted on time despite the system outage.", "the report was submited on time even with the system outtage u know"),
    ("We need to schedule a meeting with the design team.", "we need to like set up a meetting with design team basically"),
    ("I don't think that is the best approach for this feature.", "i dont think that is the best approch for thsi featrue honestly"),
    ("Could you clarify what you meant in your previous email?", "could u like clarify what u meant in the last email u sent"),
    ("The latest deployment resolved the connection timeout issue.", "the latest deploy fixed the conection time out bug basically"),
    ("Let's finalize the proposal before Friday afternoon.", "lets like finalize the proposal before friday after noon"),
    ("Their strategy seems effective, but we should verify the metrics.", "there stratagy seems good but we shoudl check the numbers u know")
]

def generate_streaming_dataset(
    target_count: int,
    output_path: str,
    include_disfluencies: bool = True
):
    """
    Synthesizes up to target_count pairs and writes to a JSONL dataset file.
    """
    corruptor = SyntheticCorruptor(noise_prob=0.35 if include_disfluencies else 0.20)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    print(f"[*] Starting dataset generation: target = {target_count:,} pairs")
    print(f"[*] Destination: {output_path}")

    written = 0
    with open(output_path, "w", encoding="utf-8") as f:
        # 1. Write foundational high-quality seed pairs
        for clean, noisy in SEED_SAMPLES:
            entry = {
                "id": f"seed_{written}",
                "input": noisy,
                "target": clean,
                "type": "spoken_disfluency"
            }
            f.write(json.dumps(entry) + "\n")
            written += 1

        # 2. Generate augmented synthetic pairs
        templates = [
            "I was thinking about {topic} and wanted to see if {action}.",
            "We should definitely consider {topic} before {action}.",
            "Could you please ensure that {topic} is ready for {action}?",
            "It turns out that {topic} was not able to {action} properly.",
            "Our primary objective regarding {topic} is to {action} as quickly as possible.",
            "The engineering team resolved {topic} and will now {action}.",
            "I don't believe that {topic} will cause any issues when we {action}.",
            "Please follow up regarding {topic} once you finish {action}."
        ]

        topics = [
            "the upcoming product release", "the database migration",
            "the mobile keyboard architecture", "the quarterly marketing campaign",
            "the client presentation slides", "the voice dictation pipeline",
            "the new authentication flow", "the performance optimization audit",
            "the API gateway rate limiter", "the cross-platform sync service"
        ]

        actions = [
            "deploy it to staging", "review the pull request",
            "run the test suite", "notify the stakeholders",
            "conduct the user interviews", "verify the telemetry logs",
            "schedule the team sync", "finalize the design tokens"
        ]

        while written < target_count:
            tmpl = random.choice(templates)
            top = random.choice(topics)
            act = random.choice(actions)
            clean_sentence = tmpl.format(topic=top, action=act)

            noisy_sentence = corruptor.corrupt(clean_sentence)

            entry = {
                "id": f"syn_{written}",
                "input": noisy_sentence,
                "target": clean_sentence,
                "type": "synthetic_noise"
            }
            f.write(json.dumps(entry) + "\n")
            written += 1

            if written % 100000 == 0 or written == target_count:
                print(f"[>] Progress: {written:,} / {target_count:,} pairs generated ({(written/target_count)*100:.1f}%)")

    print(f"[✓] Generation complete! {written:,} pairs written to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SAYN GEC & Spoken Dataset Generator")
    parser.add_argument("--count", type=int, default=100000, help="Number of pairs to generate (e.g. 100000, 1000000, 50000000)")
    parser.add_argument("--output", type=str, default="./data/gec_50m_train.jsonl", help="Output JSONL path")
    parser.add_argument("--disfluencies", action="store_true", default=True, help="Include spoken hesitations and disfluencies")

    args = parser.parse_args()
    generate_streaming_dataset(args.count, args.output, args.disfluencies)
