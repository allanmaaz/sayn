"""
SAYN GEC Model Exporter: LoRA Merge & GGUF / ONNX Preparation
Merges QLoRA weights into full precision model for local mobile & desktop deployment.
"""

import argparse
import os
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel


def parse_args():
    parser = argparse.ArgumentParser(description="Merge and Export SAYN GEC Model")
    parser.add_argument("--base_model", type=str, default="meta-llama/Llama-3.2-1B-Instruct")
    parser.add_argument("--adapter_dir", type=str, default="./checkpoints/sayn-gec-1b/final_adapter")
    parser.add_argument("--output_dir", type=str, default="./checkpoints/sayn-gec-1b-merged")
    return parser.parse_args()


def main():
    args = parse_args()
    print("=== SAYN Model Weight Merging & Export ===")
    print(f"Base Model:  {args.base_model}")
    print(f"LoRA Adapter:{args.adapter_dir}")
    print(f"Output Dir:  {args.output_dir}\n")

    os.makedirs(args.output_dir, exist_ok=True)

    print("1. Loading base model in float16...")
    base_model = AutoModelForCausalLM.from_pretrained(
        args.base_model,
        torch_dtype=torch.float16,
        device_map="cpu",
        low_cpu_mem_usage=True
    )

    print("2. Loading LoRA adapter...")
    model = PeftModel.from_pretrained(base_model, args.adapter_dir)

    print("3. Merging weights into base model...")
    merged_model = model.merge_and_unload()

    print(f"4. Saving merged float16 model to {args.output_dir}...")
    merged_model.save_pretrained(args.output_dir, safe_serialization=True)

    tokenizer = AutoTokenizer.from_pretrained(args.base_model)
    tokenizer.save_pretrained(args.output_dir)

    print("\n✓ Model merge successful!")
    print(f"Saved merged weights at: {args.output_dir}")
    print("\nNext Steps for Mobile / Desktop Deployment:")
    print("  • Convert to GGUF (for llama.cpp / mobile edge):")
    print(f"    python convert_hf_to_gguf.py {args.output_dir} --outfile {args.output_dir}/sayn-gec-1b.gguf --outtype q4_k_m")
    print("  • Deploy to Cloudflare Workers AI / Groq / Ollama / vLLM.")


if __name__ == "__main__":
    main()
