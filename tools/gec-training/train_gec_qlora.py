"""
SAYN GEC & Wispr Flow Fine-Tuning Pipeline
Fine-tunes LLaMA 3.2 1B-Instruct or Gemma 2 2B using QLoRA
Optimized for ultra-fast, concise grammar correction.
"""

import argparse
import os
import sys
import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments,
    DataCollatorForSeq2Seq
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training
)
from trl import SFTTrainer


def parse_args():
    parser = argparse.ArgumentParser(description="Train SAYN GEC Model with QLoRA")
    parser.add_argument("--model_id", type=str, default="meta-llama/Llama-3.2-1B-Instruct",
                        help="Base model to fine-tune (e.g. meta-llama/Llama-3.2-1B-Instruct, google/gemma-2-2b-it)")
    parser.add_argument("--data_dir", type=str, default="./data",
                        help="Directory containing train.jsonl and val.jsonl")
    parser.add_argument("--output_dir", type=str, default="./checkpoints/sayn-gec-1b",
                        help="Directory to save model checkpoints")
    parser.add_argument("--max_seq_length", type=int, default=256,
                        help="Maximum sequence length (compact for fast mobile text)")
    parser.add_argument("--batch_size", type=int, default=8,
                        help="Per-device training batch size")
    parser.add_argument("--grad_accum", type=int, default=4,
                        help="Gradient accumulation steps")
    parser.add_argument("--learning_rate", type=float, default=2e-4,
                        help="Learning rate for AdamW")
    parser.add_argument("--epochs", type=int, default=3,
                        help="Number of training epochs")
    parser.add_argument("--lora_rank", type=int, default=32,
                        help="LoRA rank dimension")
    parser.add_argument("--lora_alpha", type=int, default=64,
                        help="LoRA alpha scaling factor")
    parser.add_argument("--lora_dropout", type=float, default=0.05,
                        help="LoRA dropout rate")
    return parser.parse_args()


def main():
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)

    print("=====================================================")
    print("      SAYN GEC & Wispr Flow Training Pipeline        ")
    print("=====================================================")
    print(f"Base Model:       {args.model_id}")
    print(f"Data Directory:   {args.data_dir}")
    print(f"Output Directory: {args.output_dir}")
    print(f"Max Seq Length:   {args.max_seq_length}")
    print(f"LoRA Rank / Alpha: {args.lora_rank} / {args.lora_alpha}")
    print(f"Effective Batch:  {args.batch_size * args.grad_accum}")
    print(f"Epochs:           {args.epochs}")
    print("=====================================================\n")

    # 1. 4-bit Quantization Configuration (QLoRA)
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16 if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else torch.float16,
        bnb_4bit_use_double_quant=True
    )

    # 2. Load Tokenizer
    print("Loading tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(args.model_id, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "right"

    # 3. Load Datasets
    train_file = os.path.join(args.data_dir, "train.jsonl")
    val_file = os.path.join(args.data_dir, "val.jsonl")

    if not os.path.exists(train_file):
        print(f"Error: train.jsonl not found at {train_file}")
        print("Please run `python download_and_prep_datasets.py` first.")
        sys.exit(1)

    print(f"Loading dataset from {args.data_dir}...")
    dataset = load_dataset("json", data_files={"train": train_file, "validation": val_file})
    print(f"Loaded {len(dataset['train'])} train examples, {len(dataset['validation'])} val examples.")

    # 4. Load Base Model in 4-bit
    print(f"Loading base model {args.model_id}...")
    model = AutoModelForCausalLM.from_pretrained(
        args.model_id,
        quantization_config=bnb_config,
        device_map="auto",
        torch_dtype=torch.bfloat16 if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else torch.float16,
        trust_remote_code=True
    )
    model = prepare_model_for_kbit_training(model)

    # 5. Setup LoRA Config
    peft_config = LoraConfig(
        r=args.lora_rank,
        lora_alpha=args.lora_alpha,
        lora_dropout=args.lora_dropout,
        bias="none",
        task_type="CAUSAL_LM",
        target_modules=[
            "q_proj", "k_proj", "v_proj", "o_proj",
            "gate_proj", "up_proj", "down_proj"
        ]
    )
    model = get_peft_model(model, peft_config)
    model.print_trainable_parameters()

    # 6. Training Arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        gradient_accumulation_steps=args.grad_accum,
        eval_strategy="epoch",
        save_strategy="epoch",
        learning_rate=args.learning_rate,
        lr_scheduler_type="cosine",
        warmup_ratio=0.05,
        weight_decay=0.01,
        fp16=not (torch.cuda.is_available() and torch.cuda.is_bf16_supported()),
        bf16=torch.cuda.is_available() and torch.cuda.is_bf16_supported(),
        logging_steps=25,
        save_total_limit=2,
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        report_to="none"
    )

    # 7. SFT Trainer
    trainer = SFTTrainer(
        model=model,
        train_dataset=dataset["train"],
        eval_dataset=dataset["validation"],
        peft_config=peft_config,
        tokenizer=tokenizer,
        args=training_args,
        max_seq_length=args.max_seq_length
    )

    print("\nStarting model training...")
    trainer.train()

    # 8. Save Final Model Adapter
    final_adapter_dir = os.path.join(args.output_dir, "final_adapter")
    print(f"\nSaving fine-tuned adapter to {final_adapter_dir}...")
    trainer.model.save_pretrained(final_adapter_dir)
    tokenizer.save_pretrained(final_adapter_dir)

    print("\n✓ SAYN GEC Training complete!")
    print(f"Checkpoints and adapter ready in: {final_adapter_dir}")


if __name__ == "__main__":
    main()
