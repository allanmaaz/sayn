# SAYN GEC & Spoken Thought Conciseness Training Suite

This service provides an industrial data generation and fine-tuning pipeline to train lightweight models (`Llama-3.2-1B-Instruct` or `Gemma-2-2B`) on up to **50,000,000+** Grammatical Error Correction (GEC) and spoken disfluency pairs for Wispr Flow-style conciseness.

---

## 1. Environment Setup

```bash
cd services/gec-trainer
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## 2. Generating Datasets (1M to 50M+ Pairs)

The `dataset_builder.py` script synthesizes massive-scale training data using physical QWERTY distance models, spoken disfluency injections (*"um"*, *"like"*, *"you know"*), homophone slips, and missing apostrophes:

```bash
# Generate 100,000 pairs (quick test run)
python3 dataset_builder.py --count 100000 --output ./data/gec_100k.jsonl

# Generate 1,000,000 pairs (production baseline)
python3 dataset_builder.py --count 1000000 --output ./data/gec_1m.jsonl

# Generate 50,000,000 pairs (massive scale for cluster training)
python3 dataset_builder.py --count 50000000 --output ./data/gec_50m.jsonl
```

---

## 3. Launching QLoRA Fine-Tuning

```bash
# Run training on a GPU instance (Single A100 or 8x A100/H100)
python3 train_lora.py \
    --model_id meta-llama/Llama-3.2-1B-Instruct \
    --dataset_path ./data/gec_1m.jsonl \
    --output_dir ./checkpoints/sayn-gec-1b \
    --batch_size 8 \
    --gradient_accumulation_steps 4 \
    --epochs 3
```

---

## 4. Exporting for Sub-120ms Production Deployment

### Option A: Cloud LPU Deployment (Groq / Cloudflare Workers AI)
Export to Hugging Face Hub or ONNX for sub-120ms token streaming:
```bash
python3 -m transformers.onnx --model=./checkpoints/sayn-gec-1b onnx/
```

### Option B: Local On-Device Deployment (GGUF for Android & macOS)
Use `llama.cpp` to quantize the model to 4-bit GGUF:
```bash
python3 llama.cpp/convert_hf_to_gguf.py ./checkpoints/sayn-gec-1b --outfile ./checkpoints/sayn-gec-1b-q4_k_m.gguf
```
This produces an ultra-compact ~750MB model that runs locally on modern Android devices and MacBooks with zero cloud dependency.
