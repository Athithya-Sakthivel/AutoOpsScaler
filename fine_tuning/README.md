# Fine-Tuning Strategy: EKS + Karpenter + Ray + AutoAWQ

## 🧠 Objective

Efficiently fine-tune large language models (LLMs) on Spot GPU nodes using Ray on EKS, then quantize for optimized inference using AutoAWQ.

---

## ⚙️ Infra Stack

- **Kubernetes (EKS)** + **Karpenter**: Auto-provisioning of CPU/GPU nodes.
- **Ray (RayJob)**: Distributed fine-tuning across Spot GPUs.

---

## 🔁 Fine-Tuning Pipeline

### 1. **Launch Fine-Tuning Job (RayJob)**

- Uses `QLoRA` or `bnb.nn.Linear4bit` via HuggingFace + PEFT.
- Multi-GPU (e.g., A10g, A100) training over Ray cluster.
- Auto-scales GPU nodes using Karpenter Spot constraints.

📂 Example:
```bash
kubectl apply -f fine_tune_rayjob.yaml
````

---

### 2. **Postprocess: Merge + Save**

After training:

* Merge LoRA adapter into the base model.
* Save full model to `s3://bucket/merged_model/`.

---

### 3. **Quantize with AutoAWQ**

* Run AutoAWQ quantization job (can be RayJob or standalone pod).
* Save AWQ quantized model to `s3://bucket/awq_quantized/`.

📂 Example CLI:

```bash
autoawq quantize --model merged_model --wbits 4 --group-size 128 --output awq_model
```

---

### 4. **Serve with vLLM or llama.cpp**

* Deploy quantized model using:

  * `vLLM` + `RayService` for scalable inference
  * `llama.cpp` or `MLC` for CPU/edge inference

---

## 📁 Directory Layout

```
/llms/
├── ray_jobs/
│   └── fine_tune_rayjob.yaml
├── awq_jobs/
│   └── quantize_rayjob.yaml
├── output/
│   ├── merged_model/
│   └── awq_quantized/
```

---

## 🧪 Notes

* Use `Karpenter` provisioners to separate GPU and CPU pools.
* Always merge LoRA before quantizing to AWQ.
* AWQ quantized models are for **inference only**.

---

## 🔥 Pro Tip

> Use **Spot GPU constraints** in your RayJob spec and set `rayResources: {"GPU": 1}` for optimal fine-tuning cost/performance on Karpenter-managed nodes.


