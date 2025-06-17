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


## **AutoOpsScaler** significantly reduces manual complexity by providing a declarative, fully automated backend for KubeRay on EKS + Karpenter, along with a highly modular AI stack to run production workloads from day one — all built with modern tools and best practices.

* **Provisions infrastructure:** VPC, EKS, Karpenter, IAM, networking
* **Configures Ray clusters:** fractional GPU scheduling, Serve, Train, and Data components
* **Modular AI stack:** deploy LLMs, embedding models, self-managed Postgres (Zalando), and a vector DB (Qdrant) — fully within your cluster, with high flexibility to plug in external API keys or skip deploying certain stages
* **Enables safe autoscaling:** sub-minute GPU scaling with Spot fallback
* **Provides observability:** Ray Dashboard, Prometheus, Grafana, Kubernetes events, and metrics
* **Abstracts complexity:** Makefile commands and dynamic Python modules handle infrastructure provisioning and deployment

---


# **AutoOpsScaler Architecture:**

```py
AutoOpsScaler/
|── .github/                              # GitHub Actions workflows
|   └── workflows/
|       └── ci.yml                        # CI pipeline: lint, tests, and Makefile integration
|
|── base_configs/                       # Declarative source‑of‑truth configs for core infrastructure
|   ├── iam.yml                         # Defines IAM roles, policies, and trust relationships
|   ├── vpc.yml                         # Specifies VPC CIDRs, subnets, NAT gateways, and Internet Gateway
|   ├── eks.yml                         # Configures EKS cluster settings and base node groups
|   ├── karpenter.yml                   # Defines Karpenter Provisioner settings and Spot capacity pools
|   ├── observability.yml               # Prometheus, Grafana, and Alertmanager deployment settings
|   ├── secrets.yml                     # Template for Secrets Manager entries or external ARNs
|   ├── zalando_operator.yml            # Zalando Postgres Operator CRD and database cluster spec
|   ├── qdrant.yml                      # Qdrant StatefulSet, EBS PVC, and Service manifest
|   └── README.md                       # Guidelines for writing and validating config files
|
|── base_infra/                         # Pulumi modules for validating configs and provisioning infra
|   ├── 01_iam/
|   │   ├── __main__.py                 # Loads & validates iam.yml, provisions IAM roles/policies
|   │   └── iam.py                      # Helper functions for IAM resource definitions
|   ├── 02_vpc/
|   │   ├── __main__.py                 # Loads & validates vpc.yml, provisions VPC, subnets, and IGW
|   │   └── vpc.py                      # Helper functions for VPC and networking setup
|   ├── 03_eks/
|   │   ├── __main__.py                 # Loads & validates eks.yml, provisions EKS cluster & nodegroups
|   │   └── eks.py                      # Helper functions for EKS resource creation
|   ├── 04_karpenter/
|   │   ├── __main__.py                 # Loads & validates karpenter.yml, deploys Karpenter CRDs
|   │   └── karpenter.py                # Helper functions for Karpenter Provisioner logic
|   ├── 05_observability/
|   │   ├── __main__.py                 # Loads & validates observability.yml, deploys monitoring stack
|   │   └── observability.py            # Helper functions for Prometheus/Grafana deployment for eks, RayJob, RayService
|   ├── 06_secrets/
|   │   ├── __main__.py                 # Loads & validates secrets.yml, provisions Secrets Manager entries
|   │   └── secrets.py                  # Helper functions for secrets handling
|   ├── 07_zalando_operator/
|   │   ├── __main__.py                 # Loads & validates zalando_operator.yml, installs Postgres Operator
|   │   └── zalando_operator.py         # Helper logic for Zalando Operator and CRDs
|   ├── 08_qdrant/
|   │   ├── __main__.py                 # Loads & validates qdrant.yml, deploys Qdrant StatefulSet & PVC
|   │   └── qdrant.py                   # Helper functions for Qdrant resource management
|   ├── pulumi.yaml                     # Pulumi project metadata: name, runtime, and backend
|   └── Pulumi.prod.yaml                # Production stack config: region, cluster name, scaling limits
|
|── Makefile                            # Unified commands for validate, build, and deploy workflows
|
├── flux/
│   ├── base/
│   │   ├── ray_service.yaml      # inference pipeline: always-on
│   │   ├── ray_job.yaml          # indexing pipeline: batch job
│   │   ├── namespace.yaml        # common namespaces dev and prod
│   │   ├── k8s-secrets.yaml      # cluster secrets 
│   │   ├── configmap.yaml        # non-secret configs
│   │   ├── kustomization.yaml    # entrypoint
│   |   └── ingress.yml           # IngressRoute + Middleware traefik CRDs
|   |
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml  # dev env-specific patch
│       └── prod/
│           └── kustomization.yaml  # prod env-specific patch
|
|── utils/                              # Shared utility functions and helpers
|   ├── __init__.py                     # Marks the utils directory as a Python package
|   ├── deduplicator.py                 # Implements hashlib based deduplication
|   ├── logger.py                       # Centralized structured logging setup
|   └── s3_util.py                      # Helper functions for S3 upload/download with boto3
|
├── data_pipeline/                         # Unified data pipeline: ELT (CPU) + Embedding (GPU)
│   ├── modules/                           # Python modules for extraction, processing, embedding
│   │   ├── __init__.py                    # Declares modules as a Python package
│   │   ├── extract_load/                  # Extract and load raw data in s3:/<bucket>/data/raw/
│   │   │   ├── __init__.py                # Declares extract_load as a subpackage
│   │   │   ├── file_watcher.py            # Watches local/S3 folders; triggers uploads
│   │   │   ├── llamaindex_loader.py       # Uses LlamaIndex to load and dedupe documents
│   │   │   ├── s3_uploader.py             # Uploads raw files to S3 with boto3
│   │   │   ├── web_scraper.py             # Scrapy+Playwright scraper with deduplication logic
│   │   │   ├── Dockerfile                 # Builds extract/load container 
│   │   │   ├── requirements.txt           # Python dependencies for extract/load container
│   │   │   └── README.md                  # Workflow docs: extract and load stages
│   │   ├── data_processing/               # Detects file types via unstructured.io; cleans & chunks text
│   │   │   ├── __init__.py                # Declares data_processing as a subpackage
│   │   │   ├── chunker_llamaindex.py      # Splits text into chunks; records latency metrics
│   │   │   ├── doc_parser.py              # Parses files with unstructured.io; logs tracing info
│   │   │   ├── filters.py                 # Filters out noise; tracks retention ratios
│   │   │   ├── format_normalizer.py       # Cleans text metadata; logs standardization stats
│   │   │   ├── html_parser.py             # HTML parsing via trafilatura; logs malformed docs
│   │   │   ├── Dockerfile                 # Builds preprocessing container image
│   │   │   ├── requirements.txt           # Python dependencies for preprocessing container
│   │   │   └── README.md                  # Docs: parsing heuristics and chunking strategies
│   │   └── embedding/                     # Batch embedding tasks; GPU intensive
│   │       ├── __init__.py                # Declares embedding as a subpackage
│   │       ├── model_loader.py            # Loads and caches SentenceTransformer models
│   │       ├── insert_metadata.py         # Persists document metadata into Postgres
│   │       ├── embed_to_qdrant.py         # Pushes embeddings to Qdrant; logs latency/stats
│   │       ├── worker.py                  # Task-level embedding logic emitting performance spans
│   │       ├── Dockerfile                 # Builds embedding container image
│   │       ├── requirements.txt           # Python dependencies for embedding container
│   │       └── README.md                  # Docs: embedding pipeline design and metrics
│   ├── main.py                            # Orchestrates the full data pipeline via Ray workflows 
│   └── data_pipeline_config.yml           # Central config: stages, resource params, cluster hints for both ELT and embedding
|
|── inference_pipeline/                          # RayService with CPU and GPU worker nodes for high scaling inference
|   ├── rag/                                     # Core RAG orchestration with integrated evaluation
|   │   ├── Dockerfile                           # Container image build for RAG + eval flows
|   │   ├── requirements.txt                     # Python dependencies for RAG + eval container
|   │   ├── rag_config.yml                       # Central config file for RAG pipeline
|   │   ├── main.py                              # Entrypoint: runs ray workflows for RAG and eval
|   │   └── modules/                             # RAG internal modules for retrieval, generation, and metrics
|   │       ├── __init__.py                      # Declares rag.modules as a Python package
|   │       ├── generator.py                     # Invokes LLMs; logs token usage and model details
|   │       ├── agent.py                         # Simple ReAct agent for better retreival
|   │       ├── retriever.py                     # Vector DB search and chunk retrieval logic
|   │       ├── eval_pipeline.py                 # Quality evaluation pipeline using RAGAS/trulens or custom metrics
|   │       └── ragas_wrapper.py                 # Adapter for invoking RAGAS/trulens evaluation and tracing APIs
|   └── api/                                     # User-facing API and web interface
|       ├── frontend/                            # React frontend application for RAG interaction (not scaled by Ray)
|       │   ├── Dockerfile                       # Builds frontend using Vite and React
|       │   ├── requirements.txt                 # Node/Python dependencies for frontend container (if any)
|       │   ├── vite.config.ts                   # Vite configuration for development and production
|       │   ├── index.html                       # HTML template for mounting React app
|       │   ├── package.json                     # Frontend dependencies and build scripts
|       │   └── src/                             # Frontend source files
|       │       ├── main.tsx                     # App entry point mounting the root component
|       │       ├── App.tsx                      # Root React component with routing logic
|       │       ├── api.ts                       # Axios client configured with Postgres JWT auth
|       │       ├── components/                  # Reusable UI component library
|       │       │   ├── Header.tsx               # Top navigation bar component
|       │       │   └── FileUploader.tsx         # Drag‑and‑drop file uploader component
|       │       ├── pages/                       # Routed page components
|       │       │   ├── Search.tsx               # Semantic search UI and logic
|       │       │   ├── Generate.tsx             # LLM prompt submission and display
|       │       │   └── Login.tsx                # User login page with Postgres JWT authentication
|       │       └── styles/                      # Global styling resources
|       │           └── main.css                 # Application‑wide CSS or Tailwind configuration
|       └── backend/                             # FastAPI backend serving frontend and orchestration APIs
|           ├── Dockerfile                       # Builds backend container with FastAPI and Prefect client
|           ├── requirements.txt                 # Python dependencies for backend container
|           ├── backend_config.yml               # Central config file for backend pipeline
|           ├── __init__.py                      # Declares backend as a Python package
|           ├── main.py                          # FastAPI entrypoint registering all routes
|           ├── dependencies/                    # Shared modules: config, auth, ORM schemas
|           │   ├── __init__.py                  # Declares dependencies as a Python module
|           │   ├── config.py                    # Loads env vars, DB URI, and application settings
|           │   ├── auth_postgres.py             # JWT validation against Postgres session store
|           │   └── tables/                      # SQLAlchemy ORM models for database tables
|           │       ├── __init__.py              # Declares tables as a Python subpackage
|           │       ├── user.py                  # 'User' model schema and helper methods
|           │       ├── session.py               # 'Session' model for JWT sessions and expiry
|           │       ├── feedback.py              # 'Feedback' model for user ratings and corrections
|           │       └── query_log.py             # 'QueryLog' model for auditing and analytics
|           └── routes/                          # FastAPI route handlers grouped by feature
|               ├── __init__.py                  # Declares routes as a module
|               ├── embedding.py                 # Embeddings generation endpoint
|               ├── generate.py                  # LLM generation endpoint
|               ├── health.py                    # Health and readiness probes
|               ├── job.py                       # Endpoints for triggering background jobs
|               └── search.py                    # Semantic search query endpoint
|
|── tests/                                # Test suite for all components
|   ├── __init__.py                       # Marks tests as a Python module
|   ├── conftest.py                       # Shared pytest fixtures and mock clients
|   ├── test_api.py                       # Unit tests for API endpoints
|   ├── test_embedding.py                 # Tests for embedding workflows and model loading
|   ├── test_ingestion.py                 # Tests for extract-load logic and S3 uploads
|   ├── test_rag.py                       # Tests for RAG retriever and generator modules
|   ├── test_vector.py                    # Tests for Qdrant upsert and query operations
|   └── env_check.sh                      # Script to verify CLI tools and environment health
|
|── scripts/                              # Essential scripts like login.sh, install.sh,..etc
|── docs/                                 # Docs about infra, archtecture, configs, troubleshooting ,etc
|── README.md                             # High‑level architecture, setup, and usage guide
|── requirements.txt                      # Pinned Python dependencies for Ubuntu 22.04 environment

```


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
| [VirtualBox 7.0.14](https://download.virtualbox.org/virtualbox/7.0.14/)                                                              | [VirtualBox 7.0.14](https://download.virtualbox.org/virtualbox/7.0.14/)            |

> **Note:** If using windows search windows features and **Turn off Hyper‑V , Windows Hypervisor Platform** and delete **Windows Subsystem for Linux (WSL2)** if possible 


---

## **Restart your system and get started**

> Open a **Git Bash** terminal and run the following command. The first run will take longer(20-30 minutes) as the Ubuntu Jammy VM will be downloaded. 

```bash
cd $HOME && git config --global core.autocrlf false && git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler.git && cd AutoOpsScaler && vagrant up && bash scripts/ssh.sh
```

---

## **Important: VM Lifecycle**

 ### **After a system reboot**, the VM will be shut down. Always start it manually before connecting from VS Code:

  * Open VirtualBox → Right-click the VM → **Start → Headless Start and wait atleast 1 min before opening vscode**

  ![Start the VM](.vscode/Start_the_VM.png)

### **Optionally, you can save the VM state before shutting down your system for faster resumption:**

  * Open VirtualBox → Right-click the VM → **Close → Save State**

  ![Save VM state](.vscode/Save_VM_state.png)



