# **AutoOpsScaler — A LowOps environment to implement the #1 GenAI scaling statergy**

## KubeRay on EKS + Karpenter is the leading production strategy for highly scalable, cost-effective GenAI clusters.
| **Aspect**                           | **KubeRay on EKS + Karpenter**                                        | **Alternatives (summary)**                                                                         |
| ------------------------------------ | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Node provisioning latency**        | Sub‑minute: just‑in‑time EC2 nodes on unschedulable Ray pods          | 2–5 min boot (Cluster Autoscaler, EC2, Fargate); instant but opaque (serverless)                   |
| **GPU flexibility & fractional use** | Any EC2 GPU (A10G/A100/H100); Ray supports fractional scheduling      | Predefined pools(EKS-Auto), no fractional (EKS CA); limited SKUs (GKE); no GPU (Fargate)                     |
| **Spot + On‑Demand cost mix**        | Optimized Spot usage with fallback; Ray handles preemptions           | Slower rebalancing (CA); extra fees (EKS‑Auto); manual Spot handling (EC2); high cost (serverless) |
| **Observability & debugging**        | Full: Kubernetes events, Ray Dashboard, Prometheus                    | Limited logs (managed Ray services); less verbose (CA); manual scripts (EC2)                       |
| **Operational overhead**             | Minimal: single Karpenter CRD + RayService, basic IAM policies        | Multiple CRDs/HPA/KEDA/CA rules; custom EC2 scripts; YAML bloat                                    |
| **Self‑healing**                     | Automatic node replacement and Ray task restarts                      | Slower node recovery (CA); manual scripts (EC2); vendor dependent (serverless)                     |
| **Use‑case suitability**             | Top choice: LLM training, fine‑tuning, batch inference, RAG pipelines | Prototype only (serverless); stateless services (ECS); DIY clusters (bare‑metal)                   |

---
### Known Limitation: The only significant limitation is that **KubeRay depends on Kubernetes control-plane stability and Karpenter’s Spot capacity**.  In rare cases of severe Spot market volatility, On-Demand fallback may slightly increase costs.  This is standard for any Spot-based scaling strategy and can be mitigated with well-tuned capacity pools and fallback rules.

---

## **AutoOpsScaler** significantly reduces the manual complexity by providing a declarative, fully automated backend for KubeRay on EKS + Karpenter and a self-hosted AI stack to run production workloads from day one.

- **Provisions infrastructure:** VPC, EKS, Karpenter, IAM, networking  
- **Configures Ray clusters:** fractional GPU scheduling, Serve, Train, Data components  
- **Self-hosts AI stack:** LLM models, embedding models, self managed postgres(zalando), and a vector database(qdrant) — all deployed in your cluster  
- **Enables safe autoscaling:** sub-minute GPU scaling with Spot fallback  
- **Provides observability:** Ray Dashboard, Prometheus, Kubernetes events  
- **Reduces YAML overhead:** no custom HPA, KEDA, or Cluster Autoscaler scripts

---

## Run a Fully Self-Hosted GenAI Backend

With **AutoOpsScaler**, you can deploy and operate your own LLMs, embeddings, vector search, and RAG pipelines on your AWS account — with production-grade cost efficiency and without needing deep Kubernetes or Ray expertise.

# **AutoOpsScaler Architecture:**


















# **AutoOpsScaler — Quick Start**

### **Prerequisite:**

A full Linux setup is required (do **not** use Docker Desktop, WSL,devcontainers).

---

## **One-time installation prerequisites**

| Windows                                                                                                              | macOS/Linux                                                        |
| -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [Visual Studio Code](https://code.visualstudio.com/) *(required)*                                                    | [Visual Studio Code](https://code.visualstudio.com/) *(required)*  |
| [Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) | *(not required)*                                                   |
| [Git](https://git-scm.com/downloads)                                                                                 | [Git](https://git-scm.com/downloads)                               |
| [Vagrant 2.4.3](https://developer.hashicorp.com/vagrant/downloads)                                                   | [Vagrant 2.4.3](https://developer.hashicorp.com/vagrant/downloads) |
| [VirtualBox](https://www.virtualbox.org/wiki/Downloads)                                                              | [VirtualBox](https://www.virtualbox.org/wiki/Downloads)            |

> **Note:** If the latest VirtualBox version has compatibility issues with Vagrant 2.4.3, use [VirtualBox 7.0.14](https://download.virtualbox.org/virtualbox/7.0.14/).

---

## **Restart your system and get started**

> Open a **Git Bash** terminal and run the following command. The first run may take longer as the Ubuntu Jammy VM box will be downloaded.

```bash
cd $HOME && git config --global core.autocrlf false && git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler.git && cd AutoOpsScaler && vagrant up && bash ssh.sh
```

---

## **Connecting via Visual Studio Code (Alternative method)**

1. Run `vagrant up` (if the VM is not already running).
2. Open Visual Studio Code on your local machine.
3. Install the **Remote - SSH** extension (if not already installed).
4. Click the green icon in the lower-left corner, or press `Ctrl+Shift+P` and select **Remote-SSH: Connect to Host**.
5. Choose **`AutoOpsScaler`** from the list.
6. When prompted for the platform, select **Linux** (the VM runs Linux).

To open the project in VS Code, run:

```bash
cd /vagrant/ && code .
```

---

## **Important: VM Lifecycle**

 ### **After a system reboot**, the VM will be shut down. Always start it manually before connecting from VS Code:

  * Open VirtualBox → Right-click the VM → **Start → Headless Start**

  ![Start the VM](.vscode/Start_the_VM.png)

### **Optionally, you can save the VM state before shutting down your system for faster resumption:**

  * Open VirtualBox → Right-click the VM → **Close → Save State**

  ![Save VM state](.vscode/Save_VM_state.png)




