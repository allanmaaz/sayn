#!/usr/bin/env python3
"""
SAYN QLoRA Fine-Tuning Pipeline
================================
Fine-tunes Llama-3.2-1B-Instruct or Gemma-2-2B on millions of GEC and spoken
disfluency pairs to create a lightweight, sub-120ms Wispr Flow-style conciseness engine.
"""

import os
import argparse
import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments,
    Trainer,
    DataCollatorForSeq2Seq
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training,
    TaskType
)

SYSTEM_PROMPT = (
    "You are an ultra-fast speech and grammar polisher. "
    "Clean the user's spoken or typed text into concise, flawless English. "
    "Remove all filler words and disfluencies. Never add commentary or quotes."
)

def format_instruction(sample: dict) -> dict:
    """Formats each pair into instruction tuning conversational format."""
    noisy_input = sample["input"]
    clean_target = sample["target"]
    
    text = (
        f"<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n"
        f"{SYSTEM_PROMPT}<|eot_id|>"
        f"<|start_header_id|>user<|end_header_id|>\n\n"
        f"{noisy_input}<|eot_id|>"
        f"<|start_header_id|>assistant<|end_header_id|>\n\n"
        f"{clean_target}<|eot_id|>"
    )
    return {"text": text}

def train(args):
    print("=" * 60)
    print(f"[*] Starting SAYN GEC LoRA Fine-Tuning")
    print(f"[*] Base Model: {args.model_id}")
    print(f"[*] Dataset:    {args.dataset_path}")
    print(f"[*] Output Dir: {args.output_dir}")
    print("=" * 60)

    # 1. 4-bit NormalFloat Quantization for Maximum Memory Efficiency
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16 if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else torch.float16,
        bnb_4bit_use_double_quant=True
    )

    # 2. Load Tokenizer & Model
    tokenizer = AutoTokenizer.from_pretrained(args.model_id, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    device_map = "auto" if torch.cuda.is_available() else "cpu"
    print(f"[*] Loading model on device: {device_map}")

    model = AutoModelForCausalLM.from_pretrained(
        args.model_id,
        quantization_config=bnb_config if torch.cuda.is_available() else None,
        device_map=device_map,
        trust_remote_code=True
    )

    if torch.cuda.is_available():
        model = prepare_model_for_kbit_training(model)

    # 3. LoRA Configuration (Rank 32, Alpha 64 targeting query/value projections)
    peft_config = LoraConfig(
        task_type=TaskType.CAUSAL_LM,
        r=args.lora_r,
        lora_alpha=args.lora_alpha,
        lora_dropout=0.05,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
    )
    model = get_peft_model(model, peft_config)
    model.print_trainable_parameters()

    # 4. Load & Format Dataset
    print(f"[*] Ingesting dataset from {args.dataset_path}...")
    dataset = load_dataset("json", data_files=args.dataset_path, split="train")
    dataset = dataset.map(format_instruction)

    def tokenize_function(examples):
        return tokenizer(
            examples["text"],
            truncation=True,
            max_length=args.max_seq_length,
            padding="max_length"
        )

    tokenized_dataset = dataset.map(tokenize_function, batched=True, remove_columns=dataset.column_names)

    # 5. Training Arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        learning_rate=args.learning_rate,
        lr_scheduler_type="cosine",
        warmup_ratio=0.05,
        logging_steps=20,
        num_train_epochs=args.epochs,
        save_strategy="epoch",
        fp16=torch.cuda.is_available() and not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_available() and torch.cuda.is_bf16_supported(),
        optim="paged_adamw_8bit" if torch.cuda.is_available() else "adamw_torch",
        report_to="none"
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_dataset,
        data_collator=DataCollatorForSeq2Seq(tokenizer, pad_to_multiple_of=8, return_tensors="pt")
    )

    print("[*] Launching training loop...")
    trainer.train()

    print(f"[✓] Training complete! Saving LoRA adapter to {args.output_dir}")
    trainer.model.save_pretrained(args.output_dir)
    tokenizer.save_pretrained(args.output_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train SAYN GEC Model via QLoRA")
    parser.add_argument("--model_id", type=str, default="meta-llama/Llama-3.2-1B-Instruct", help="Base model identifier")
    parser.add_argument("--dataset_path", type=str, default="./data/gec_50m_train.jsonl", help="Path to input training JSONL")
    parser.add_argument("--output_dir", type=str, default="./checkpoints/sayn-gec-1b-lora", help="Output directory")
    parser.add_argument("--batch_size", type=int, default=8, help="Per-device batch size")
    parser.add_argument("--gradient_accumulation_steps", type=int, default=4, help="Gradient accumulation steps")
    parser.add_argument("--learning_rate", type=float, default=2e-4, help="Learning rate")
    parser.add_argument("--epochs", type=int, default=3, help="Number of training epochs")
    parser.add_argument("--max_seq_length", type=int, default=256, help="Maximum sequence length")
    parser.add_argument("--lora_r", type=int, default=32, help="LoRA rank")
    parser.add_argument("--lora_alpha", type=int, default=64, help="LoRA alpha")

    args = parser.parse_args()
    train(args)
