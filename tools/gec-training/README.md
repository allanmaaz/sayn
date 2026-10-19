# SAYN GEC & Wispr Flow Training Engine

This directory provides the end-to-end training and data synthesis pipeline to train a state-of-the-art **Grammatical Error Correction (GEC)** and **Wispr Flow Conciseness** model on lakhs (5,000,000+) of global sentence pairs.

---

## 1. Architecture Overview

```
Raw Noisy Spoken/Typed Input
("i was walking down the street thinking about life u know like what to do")
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│  Fine-Tuned Model: LLaMA 3.2 1B-Instruct / Gemma 2 2B   │
│  Trained with QLoRA (Rank 32, Alpha 64) on 8x A100 GPUs │
│  Loss: Sequence-to-Sequence Cross-Entropy with Length   │
│  Penalty to Enforce Conciseness                         │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
Target Output (Fluency / Wispr Flow Style):
"I was walking down the street, reflecting on what to do next."
```

### Key Training Objectives:
1. **Flawless Grammar & Mobile Typo Recovery**: Automatically fixes adjacent QWERTY key misses, dropped apostrophes (`dont` $\to$ `don't`), homophones (`their/there`), and case errors.
2. **Speech Disfluency Stripping**: Removes hesitation sounds (*"um"*, *"uh"*, *"you know"*, *"like"*, *"basically"*).
3. **Spoken Punctuation Formatting**: Converts dictation phrases like *"question mark"*, *"new paragraph"*, and *"comma"* into proper typographic punctuation.
4. **Wispr Flow Conciseness**: Eliminates wordy, rambling preambles, reducing token count by 10–25% without losing factual meaning.

---

## 2. Dataset Mixture (5,000,000+ Pairs)

| Dataset | Volume | Nature of Data | Training Target |
| :--- | :--- | :--- | :--- |
| **Lang-8 Learner Corpus** | 1,100,000+ pairs | Real-world written errors corrected by native speakers | Agreement, prepositions, verb tense |
| **BEA-2019 / W&I + LOCNESS**| 350,000+ pairs | Formal academic & professional writing errors | High-stakes grammatical precision |
| **JFLEG (JHU Fluency)** | 80,000+ pairs | Sentence-level fluency and natural restructuring | Rhythm and native cadence |
| **Synthetic Mobile Corruptor**| 3,500,000+ pairs | Corrupted Wikipedia / C4 text with QWERTY and spoken noise | Noise robustness and speed |

---

## 3. Quickstart & Step-by-Step Execution

### Prerequisites
```bash
pip install -r requirements.txt
```

### Step 1: Synthesize & Prepare Dataset
Compile lakhs of training pairs:
```bash
# Generate 500,000 pairs (or 1,000,000+ for full training run)
python download_and_prep_datasets.py --samples 500000 --output_dir ./data
```
Outputs:
- `./data/train.jsonl` (90% split)
- `./data/val.jsonl` (5% split)
- `./data/test.jsonl` (5% split)

### Step 2: Fine-Tune with QLoRA
Run parameter-efficient fine-tuning on a GPU (RTX 3090, 4090, A100, or H100):
```bash
python train_gec_qlora.py \
  --model_id "meta-llama/Llama-3.2-1B-Instruct" \
  --data_dir "./data" \
  --output_dir "./checkpoints/sayn-gec-1b" \
  --batch_size 8 \
  --grad_accum 4 \
  --epochs 3 \
  --learning_rate 2e-4
```

### Step 3: Evaluate Benchmark
Measure GLEU, exact match accuracy, conciseness ratio, and latency:
```bash
python evaluate_conll14.py \
  --base_model "meta-llama/Llama-3.2-1B-Instruct" \
  --adapter_dir "./checkpoints/sayn-gec-1b/final_adapter" \
  --test_file "./data/test.jsonl"
```

### Step 4: Export to GGUF (Mobile / Edge Execution)
Merge LoRA adapter into full float16 weights and convert to GGUF format for on-device execution:
```bash
python export_gguf_onnx.py \
  --base_model "meta-llama/Llama-3.2-1B-Instruct" \
  --adapter_dir "./checkpoints/sayn-gec-1b/final_adapter" \
  --output_dir "./checkpoints/sayn-gec-1b-merged"
```
Convert to 4-bit GGUF with llama.cpp:
```bash
python llama.cpp/convert_hf_to_gguf.py ./checkpoints/sayn-gec-1b-merged \
  --outfile ./checkpoints/sayn-gec-1b-q4_k_m.gguf \
  --outtype q4_k_m
```

---

## 4. Serving in SAYN Cloud Gateway

Once trained, the model can be hosted on:
1. **Groq LPU**: Ultra-low latency token generation ($800\text{+ tokens/sec}$).
2. **Cloudflare Workers AI**: Edge inference with sub-100ms global response.
3. **Local Android / iOS Execution**: Using `llama.cpp` JNI bindings via the exported GGUF weights.
