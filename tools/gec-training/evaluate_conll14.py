"""
SAYN GEC Benchmark & Conciseness Evaluation
Evaluates trained GEC model against test split on:
- GLEU (Generalized Language Evaluation Understanding)
- Exact Match Accuracy
- Conciseness Token Ratio
- Average Inference Latency (ms)
"""

import argparse
import json
import time
import torch
from typing import List, Dict
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel


def compute_gleu(reference: str, hypothesis: str) -> float:
    """Computes basic sentence-level GLEU score."""
    ref_words = reference.strip().lower().split()
    hyp_words = hypothesis.strip().lower().split()
    if not hyp_words or not ref_words:
        return 0.0

    matches = sum(1 for w in hyp_words if w in ref_words)
    precision = matches / len(hyp_words)
    recall = matches / len(ref_words)
    if precision + recall == 0:
        return 0.0
    return (2 * precision * recall) / (precision + recall)


def parse_args():
    parser = argparse.ArgumentParser(description="Evaluate SAYN GEC Model")
    parser.add_argument("--base_model", type=str, default="meta-llama/Llama-3.2-1B-Instruct")
    parser.add_argument("--adapter_dir", type=str, default="./checkpoints/sayn-gec-1b/final_adapter")
    parser.add_argument("--test_file", type=str, default="./data/test.jsonl")
    parser.add_argument("--max_samples", type=int, default=100)
    return parser.parse_args()


def main():
    args = parse_args()
    print("=== SAYN GEC Evaluation Benchmark ===")
    print(f"Base Model: {args.base_model}")
    print(f"Adapter:    {args.adapter_dir}")
    print(f"Test Set:   {args.test_file}")

    # Load Tokenizer
    tokenizer = AutoTokenizer.from_pretrained(args.base_model)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    # Load Model
    device = "cuda" if torch.cuda.is_available() else ("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"Loading model onto {device}...")

    base_model = AutoModelForCausalLM.from_pretrained(
        args.base_model,
        torch_dtype=torch.float16 if device != "cpu" else torch.float32,
        device_map=device
    )

    try:
        model = PeftModel.from_pretrained(base_model, args.adapter_dir)
        print("Loaded LoRA adapter successfully.")
    except Exception as e:
        print(f"Warning: Could not load LoRA adapter ({e}), testing zero-shot base model.")
        model = base_model

    model.eval()

    # Read Test Data
    samples = []
    with open(args.test_file, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                samples.append(json.loads(line))
            if len(samples) >= args.max_samples:
                break

    print(f"Running evaluation on {len(samples)} test samples...\n")

    gleu_scores = []
    conciseness_ratios = []
    latencies = []
    exact_matches = 0

    for idx, sample in enumerate(samples):
        messages = sample["messages"]
        noisy_user_input = messages[1]["content"]
        target_assistant = messages[2]["content"]

        prompt = tokenizer.apply_chat_template(
            messages[:2],
            tokenize=False,
            add_generation_prompt=True
        )

        inputs = tokenizer(prompt, return_tensors="pt").to(device)

        start_t = time.perf_counter()
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=128,
                temperature=0.1,
                do_sample=False,
                pad_token_id=tokenizer.pad_token_id
            )
        elapsed_ms = (time.perf_counter() - start_t) * 1000.0
        latencies.append(elapsed_ms)

        gen_tokens = outputs[0][inputs.input_ids.shape[1]:]
        prediction = tokenizer.decode(gen_tokens, skip_special_tokens=True).strip()

        # Compute Metrics
        gleu = compute_gleu(target_assistant, prediction)
        gleu_scores.append(gleu)

        if prediction.lower() == target_assistant.lower():
            exact_matches += 1

        input_len = len(noisy_user_input.split())
        pred_len = len(prediction.split())
        ratio = (pred_len / input_len) if input_len > 0 else 1.0
        conciseness_ratios.append(ratio)

        if idx < 5:
            print(f"--- Sample {idx + 1} ---")
            print(f"Input:       {noisy_user_input}")
            print(f"Target:      {target_assistant}")
            print(f"Model:       {prediction}")
            print(f"GLEU:        {gleu:.3f} | Ratio: {ratio:.2f} | Latency: {elapsed_ms:.1f}ms\n")

    avg_gleu = sum(gleu_scores) / len(gleu_scores) if gleu_scores else 0
    avg_ratio = sum(conciseness_ratios) / len(conciseness_ratios) if conciseness_ratios else 0
    avg_latency = sum(latencies) / len(latencies) if latencies else 0
    em_acc = (exact_matches / len(samples)) * 100 if samples else 0

    print("================ FINAL BENCHMARK RESULTS ================")
    print(f"Evaluated Samples:       {len(samples)}")
    print(f"Mean GLEU Score:         {avg_gleu:.4f}")
    print(f"Exact Match Accuracy:    {em_acc:.1f}%")
    print(f"Mean Conciseness Ratio:  {avg_ratio:.2f} (Target: 0.80 - 0.95)")
    print(f"Average Inference Time:  {avg_latency:.1f} ms")
    print("=========================================================")


if __name__ == "__main__":
    main()
