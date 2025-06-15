# AutoOpsScaler

> **AutoOpsScaler** provides a reproducible, low-ops environment for dynamic infrastructure and deployment automation, built specifically for GenAI engineers. It leverages a devcontainer for local consistency and integrates tightly with Kubernetes, KubeRay, and AWS infrastructure.


```py
AutoOpsScaler/
infra/
├── generated_manager.py                  #  Manages versioned YAML output snapshots for reproducibility
├── provider.py                           #  Constructs AWS and K8s Pulumi providers from Typer CLI args

├── iam/
│   ├── types.py                          #  IAM schema definitions
│   ├── policies.py                       #  IAM policy JSON specs
│   ├── constants.py                      # IRSA/OIDC constants and helper strings
│   ├── eks_trust_policy.py               # EKS-specific trust doc for IRSA
│   ├── validate.py                       #  Validates IAM inputs passed to CLI
│   ├── component.py                      # Deploys OIDC, IAM roles/policies
│   └── __main__.py                       #  CLI entry point to run IAM via Typer

├── vpc/
│   ├── types.py                          #  Schema for VPC layout (AZs, CIDRs)
│   ├── cidr_plan.py                      # CIDR subnet planning and validation
│   ├── validate.py                       #  Validates VPC inputs passed to CLI
│   ├── component.py                      #  Provisions VPC, subnets, NAT, IGW
│   └── __main__.py                       #  CLI entry point for VPC via Typer

├── s3/
│   ├── types.py                          #  Schema for bucket policies, retention, tags
│   ├── validate.py                       #  Validates S3 config
│   ├── component.py                      # Creates encrypted, versioned buckets
│   └── __main__.py                       # CLI interface to trigger S3 provisioning

├── eks_cluster/
│   ├── types.py                          # Validates cluster version, role ARNs, access
│   ├── kubeconfig.py                     # Writes kubeconfig after cluster creation
│   ├── validate.py                       # Validates EKS cluster input schema
│   ├── component.py                      # Provisions EKS control plane
│   └── __main__.py                       # Typer entry point for EKS provisioning

├── eks_nodegroups/
│   ├── types.py                          # Static nodegroup specs (volumes, taints)
│   ├── launch_templates.py               # EC2 templates for custom IOPS/AMIs
│   ├── validate.py                       #  Validates nodegroup CLI input
│   ├── component.py                      # Provisions nodegroups (e.g. io2 class)
│   └── __main__.py                       #  CLI entry for nodegroup provisioning

├── karpenter/
│   ├── types.py                          #  Subnet tags, AMI types, EC2 limits
│   ├── node_classes.py                   # EC2NodeClass and provisioner specs
│   ├── validate.py                       # Validates Karpenter input for autoscaling
│   ├── component.py                      #  Installs Karpenter and CRDs
│   └── __main__.py                       #  CLI entry for autoscaler setup

├── zalando/
│   ├── types.py                          # Schema for DB clusters, user roles
│   ├── secrets.py                        # Injects DB credentials into K8s secrets
│   ├── users.py                          # Creates DB users via Zalando CRDs
│   ├── validate.py                       #  Validates Zalando config schema
│   ├── component.py                      #  Installs Zalando Postgres operator
│   └── __main__.py                       #  CLI entry for Postgres stack setup

├── cloudwatch_logging/
│   ├── retention.py                      # Retention, KMS, log group tagging
│   ├── validate.py                       #  Validates CloudWatch logging config
│   ├── component.py                      # Installs FluentBit -> CloudWatch pipeline
│   └── __main__.py                       #  CLI for FluentBit + CloudWatch setup

├── prometheus_grafana/
│   ├── alerts.py                         #  Alert rules and routes
│   ├── dashboards.py                     # Grafana dashboards for Ray, nodes, etc.
│   ├── validate.py                       # Validates monitoring stack inputs
│   ├── component.py                      # Deploys kube-prometheus-stack via Helm
│   └── __main__.py                       #  CLI entry for monitoring provisioning

├── loki_fluentbit/
│   ├── configmap.py                      #  FluentBit parser/filter customization
│   ├── validate.py                       #  Validates Loki + FluentBit input
│   ├── component.py                      #  Sidecar log shipping to Loki
│   └── __main__.py                       #  CLI entry for deploying log aggregation

├── ingress_alb/
│   ├── annotations.py                    #  ALB ingress rule templates
│   ├── cert_manager.py                   #  Cert-manager deployment + ACME issuers
│   ├── validate.py                       # Validates ingress and TLS inputs
│   ├── component.py                      #  ALB controller Helm + CRDs
│   └── __main__.py                       #  CLI entry for ALB ingress provisioning

├── traefik/
│   ├── middlewares.py                    #  Rate limiting, TLS redir, auth middleware
│   ├── validate.py                       #  Validates Traefik-specific input
│   ├── component.py                      #  Installs Traefik controller via Helm
│   └── __main__.py                       #  CLI entry point for alternate ingress

├── ray_jobs/
│   ├── types.py                          #  RayJob CR spec schema
│   ├── submit.py                         #  Submission client for RayJobs
│   ├── validate.py                       #  Validates RayJob config
│   ├── component.py                      #  Provisions RayJob workloads
│   └── __main__.py                       #  CLI for batch RayJob orchestration

├── ray_services/
│   ├── types.py                          #  Service config (scaling, runtimeEnv)
│   ├── safe_ray_service.py               #  Validated CRD spec wrapper
│   ├── validate.py                       #  Validates RayService config
│   ├── component.py                      #  Manages RayService controller
│   └── __main__.py                       #  CLI for RayService deployments

├── statefulsets/
│   ├── types.py                          #  PVC profiles, backup flags, anti-affinity
│   ├── pvc_profiles.py                   #  Storage class abstraction (gp3, io2, etc.)
│   ├── velero.py                         #  EBS snapshot and restore via Velero
│   ├── validate.py                       #  Validates workload + backup config
│   ├── component.py                      #  StatefulSets for Redis, Qdrant
│   └── __main__.py                       #  CLI to provision volume-bound workloads

│
├── Makefile                                    # Unified entrypoint for validate/build/deploy workflows
│
├── utils                                       # Utility functions and helpers
│   ├── README.md                               # Documentation for utility functions
│   ├── __init__.py                             # Marks the utils package as a Python module
│   ├── config_loader.py                        # Loads layered config from `config/` directory
│   ├── deduplicator.py                        # Uses hashlib (sha256 by default) for deduplication (replaces xxhash)
│   ├── logger.py                               # Centralized structured logging utility
│   └── s3_util.py                              # S3 upload/download helper (boto3)
│
├── storage                                    # for s3 bucket syncing with local storage/ 
│   ├── data                                   # Data files and backups
│   │   └── raw                                # Raw data files
│   │   ├── processed                          # Processed data files
│   │   │   ├── chunked                       # Chunked data files
│   │   │   └── parsed                        # Parsed data files
│   │   ├── db_backups                        # Database backup files
│   │   │   ├── qdrant_backups                # Qdrant database backups
│   │   │   └── postgres_backups              # postgres database backups
│   │   ├── observability                     # Observability data (e.g., local Prometheus snapshots)
│   ├── llms                                   # LLM and embedding model storage
│   │   ├── mistral                            # Mistral model files
│   │   └── sentence_transformers              # SentenceTransformers model files
│
├── extract_load                                # All raw files are stored in s3://<bucket>/data/raw/ to return the original S3 URLs during RAG inference
│   ├── modules                                # Extract/load modules
│   │   ├── README.md                          # Docs for extract-load flow (loaders, scrapers)
│   │   ├── __init__.py                        # Declares extract_load as Python module
│   │   ├── file_watcher.py                    # Watches S3/local folders for new input files
│   │   ├── llamaindex_loader.py               # Loads docs via LlamaIndex connectors and deduplication via hashlib
│   │   ├── main.py                            # Entrypoint for container: orchestrates extract pipeline via Flytekit (@task/@workflow)
│   │   ├── s3_uploader.py                     # Uploads raw docs to S3 (boto3)
│   │   └── scraper.py                         # Web scraper (Scrapy+Playwright) and deduplication via hashlib
│   ├── Dockerfile                             # Container spec for extract-load (no GPU)
│   ├── app-extract-load.argocd.yaml           # Argo CD manifest for extract-load pipeline
│   └── DynamicRayJobGenerator.py              # Generates Ray Job definitions for extract-load pipeline during runtime
│
├── data_preprocessing                         # Any file type in s3://<bucket>/storage/data/raw/ will be autodetected via unstructured.io and be parsed
│   ├── modules                                # Data preprocessing modules
│   │   ├── README.md                          # Docs covering parsing strategies and filtering heuristics
│   │   ├── __init__.py                        # Declares data_preprocessing as a Python module
│   │   ├── chunker_llamaindex.py              # Splits text into chunks (LlamaIndex); emits latency metrics
│   │   ├── doc_parser.py                      # Parses documents (unstructured.io); adds tracing on performance
│   │   ├── filters.py                         # Filters out junk/boilerplate; records chunk retention ratio metrics
│   │   ├── format_normalizer.py               # Cleans text/metadata; emits chunk count and clean ratio metrics
│   │   ├── html_parser.py                     # Parses HTML (trafilatura); logs malformed doc issues
│   │   ├── main.py                            # Entrypoint for container: orchestrates preprocessing pipeline via Flytekit (@task/@workflow)
│   │   └── (other modules as needed)          # e.g., utilities specific to preprocessing
│   ├── Dockerfile                             # Container for document preprocessing (OCR, chunking, dedup)
│   ├── app-data-preprocess.argocd.yaml        # Argo CD manifest for data preprocessing pipeline
│   └── DynamicRayJobGenerator.py              # Generates Ray Job definitions for data preprocessing pipeline during runtime
│
├── embedding                                  # Embedding pipeline code
│   ├── modules                                # Embedding pipeline modules
│   │   ├── __init__.py                        # Marks modules as a Python package
│   │   ├── batch_embed.py                     # Orchestrates batch embedding via Flyte tasks/workflows (with metrics)
│   │   ├── main.py                            # Entrypoint for container: orchestrates embedding via Flytekit (@task/@workflow)
│   │   ├── model_loader.py                    # Loads SentenceTransformer models; instrumented for tracing
│   │   └── worker.py                          # Embeds text in tasks; emits performance spans
│   ├── Dockerfile                             # Builds container for embedding pipeline using Flyte or runtime dependencies
│   ├── app-embedding.argocd.yaml              # Argo CD manifest for embedding pipeline
│   └── DynamicRayJobGenerator.py              # Generates Ray Job definitions for embedding pipeline during runtime
├── vector_db                                  # Qdrant vector database pipeline
│   ├── modules                                # Qdrant pipeline modules
│   │   ├── __init__.py                        # Marks modules as a Python package
│   │   ├── embed_to_qdrant.py                 # Pushes embeddings to Qdrant; emits latency metrics
│   │   ├── main.py                            # Entrypoint for container: orchestrates Qdrant ingestion via Flyte tasks/workflows instead of Ray
│   │   ├── qdrant_client.py                   # Qdrant client wrapper; monitors search latency
│   │   ├── query_qdrant.py                    # Similarity search query logic
│   │   └── schema.json                        # Qdrant collection schema
│   ├── Dockerfile                             # Builds container for Qdrant ingestion pipeline
│   ├── app-vector.argocd.yaml                 # Argo CD manifest for Qdrant ingestion
│   └── dynamic_StatefulSet_pvc_svc_generator.py # Generates StatefulSet/PVC/Service manifests for Qdrant
│
├── postgres                                   # Postgres metadata service code
│   ├── modules                                # postgres service modules
│   │   ├── __init__.py                        # (module marker)
│   │   ├── insert_metadata.py                 # Inserts document metadata into postgres
│   │   ├── query_metadata.py                  # Fetches metadata from postgres
│   │   └── postgres_client.py                 # postgres client logic for DB operations
│   ├── Dockerfile                             # Container for postgres metadata operations
│   ├── app-postgres.argocd.yaml               # Argo CD manifest for postgres service
│   └── dynamic_StatefulSet_pvc_svc_generator.py # Zalando Postgres Operator to self host postgres db in eks
|
├── fine_tuning/                                # Fine-tuning pipeline code
│   ├── README.md                              # Documentation for fine-tuning procedures
│   ├── DynamicRayJobGenerator.py              # Generates Ray Job definitions for fine-tuning pipeline 
│   └── fine_tune.py           # Script to fine-tune a model via Qlora/DeepSpeed and save in S3 (entrypoint can invoke Flyte tasks/workflows if applicable)
│
|── inference_pipeline/                        # Inference pipelines (RAG, evaluation, API)
|   ├── rag/
|   │   ├── Dockerfile                         # Container to serve full RAG pipeline with Haystack + FastAPI
|   │   ├── DynamicRayServiceGenerator.py      # Generates Ray Service definitions or Ray Serve configurations for RAG orchestration
|   │   ├── app-rag.argocd.yaml                # Argo CD Application manifest for GitOps sync of RAG orchestration
|   │   ├── main.py                            # Entrypoint for container: orchestrates RAG inference via Flytekit (@task/@workflow) if needed
|   │   └── modules/
|   │       ├── __init__.py                    # Marks modules as a Python package
|   │       ├── generator.py                   # Calls LLM for response; must log Langfuse spans and token usage
|   │       ├── pipeline.py                    # End-to-end orchestration logic for RAG using Flytekit (@workflow)
|   │       └── retriever.py                   # Vector + metadata search; should emit QPS and latency metrics
|   │
|   ├── evaluation/
|   │   ├── Dockerfile                         # Container for RAG evaluation service using RAGAS
|   │   ├── DynamicRayServiceGenerator.py      # Generates Ray Service definitions for evaluation pipeline
|   │   ├── main.py                            # Entrypoint for container: orchestrates evaluation via Flytekit (@task/@workflow)
|   │   └── modules/
|   │       ├── __init__.py                    # Marks modules as a Python package
|   │       ├── eval_pipeline.py               # Coordinates scoring of RAG outputs; log success/failure stats
|   │       └── trulens_wrapper.py             # Integrates with trulens metrics; ideal point for OpenLLMetry tracing
|   │
|   ├── api/                                   # API module for frontend + backend inference API and orchestration
|   │   ├── frontend/                          # React frontend for user interaction, served separately from backend
|   │   │   ├── DynamicRayServiceGenerator.py  # Generates Ray Service definitions for frontend CI/CD if needed
|   │   │   ├── Dockerfile                     # Builds React app using multi-stage build; outputs static assets
|   │   │   ├── vite.config.ts                 # Vite config for local dev and optimized build
|   │   │   ├── index.html                     # Main HTML template for React root
|   │   │   ├── package.json                   # Frontend dependencies and build scripts
|   │   │   └── src/
|   │   │       ├── main.tsx                   # React app entry point
|   │   │       ├── App.tsx                    # Root component with routing
|   │   │       ├── api.ts                     # Axios wrapper with Supabase token support
|   │   │       ├── components/
|   │   │       │   ├── Header.tsx             # Header/navigation bar
|   │   │       │   └── FileUploader.tsx       # Upload UI component
|   │   │       ├── pages/
|   │   │       │   ├── Search.tsx             # Semantic search page
|   │   │       │   ├── Generate.tsx           # Prompt-based generation page
|   │   │       │   └── Login.tsx              # Supabase OAuth login page
|   │   │       └── styles/
|   │   │           └── main.css               # Tailwind/custom CSS
|   │   └── main.py                            # Orchestration entrypoint if frontend needs Flyte-triggered actions
|   │   |
|   │   ├── backend/                           # Backend API for inference: FastAPI + Flyte integration
|   │   │   ├── Dockerfile                     # Backend Dockerfile with FastAPI + Flytekit deps
|   │   │   ├── DynamicRayServiceGenerator.py  # Ray Serve config generator for backend API
|   │   │   ├── app-api.argo.yml               # Argo CD App manifest for GitOps sync
|   │   │   ├── __init__.py                    # Makes backend a Python package
|   │   │   ├── main.py                        # FastAPI app entry; triggers Flyte tasks as needed
|   │   │   ├── dependencies/                  # Common config/auth/DB logic
|   │   │   │   ├── __init__.py                # Package marker
|   │   │   │   ├── config.py                  # Loads envs via `os.getenv` or `pydantic.BaseSettings`
|   │   │   │   ├── auth_postgres.py           # Supabase JWT auth and user extraction
|   │   │   │   └── tables/
|   │   │   │       ├── __init__.py            # Binds engine, metadata, migrations
|   │   │   │       ├── user.py                # User model with ID/email/roles
|   │   │   │       ├── session.py             # Session token + expiry info
|   │   │   │       ├── feedback.py            # Stores RAG/LLM feedback (thumbs, corrections)
|   │   │   │       └── query_log.py           # Tracks queries, usage, and logs
|   │   │   └── routes/                        # FastAPI endpoints organized by domain
|   │   │       ├── __init__.py                # Package marker
|   │   │       ├── embedding.py               # Handles text/file → embedding + vector DB insert
|   │   │       ├── generate.py                # Handles prompt → Flyte workflow → LLM output
|   │   │       ├── health.py                  # Health checks for K8s probes
|   │   │       ├── job.py                     # Chunking, ingest, Flyte job triggering
|   │   │       └── search.py                  # Semantic search, returns chunk + source S3 URI
|   │
|   └── README.md                              # Docs for inference pipeline, API, and frontend
|
├── tests                                      # Test suite
│   ├── __init__.py                            # Makes tests a Python module
│   ├── conftest.py                            # Shared pytest fixtures (mock clients, Flyte sandbox or mocks)
│   ├── test_api.py                            # Unit tests for API endpoints
│   ├── test_embedding.py                      # Tests for embedding workers and model loading
│   ├── test_ingestion.py                      # Tests for ingestion (parsing and upload logic)
│   ├── test_rag.py                            # Tests for RAG retriever and generator
│   ├── test_vector.py                         # Tests for Qdrant vector upsert/query logic
│   └── env_check.sh                           # Checks versions, PATH, and k3s/kubectl health
|
├── .devcontainer/                              # devcontainer for reproducible LowOps environment
│   ├── devcontainer.json           			# Devcontainer configuration(root user): Dockerfile path, volume mount configs, optional postCreateCommand(S) 
│   └── Dockerfile   							 # Dockerfile based on Ubuntu 22.04(reliable), default Python 3.10, installs few system neccessaries and provisioning
│
├── .github/                                     # GitHub actions configuration 
│   └── workflows/
│       └── ci.yml                               # CI pipeline for lint (ruff), tests (pytest), fully integrates Makefile commands for flexible CD
|
├── .dockerignore                              # Docker exclusion file to prevent building unnecessary files
├── .gitignore                                 # Git exclusion file to prevent committing irrelevant and sensitive files
├── README.md                                  # High-level documentation describing architecture and usage
└── requirements.txt                           # Pinned dependencies (ensure versions match Ubuntu 22.04 setup)

```










## 🚀 Getting Started

AutoOpsScaler runs inside a pre-configured [**Dev Container**](https://code.visualstudio.com/docs/devcontainers/containers), ensuring full reproducibility across systems. This guide helps you set up the platform with the **least troubleshooting overhead**.

### ✅ Prerequisites

#### 1. Docker (24.0.7)
A stable Docker installation is mandatory. We strongly recommend using **Linux** or **WSL2 on Windows** for full compatibility with root-based container environments.

<details>
<summary><strong>For Windows (WSL2 Recommended)</strong></summary>

If you're using Docker Desktop + Git Bash, it won't support root-mode devcontainers properly. Switch to WSL2 with Ubuntu 22.04:

1. Uninstall Docker Desktop completely.
2. Open **PowerShell as Administrator** and run:
   ```powershell
   wsl.exe --list --verbose
   wsl.exe --unregister docker-desktop
   wsl.exe --install Ubuntu-22.04

3. Launch WSL via:

   * PowerShell: `wsl`
   * VSCode: Click the green/blue left corner bottom icon ➝ *"Connect to WSL"*

4. Then install Docker inside WSL:

   ```bash
   sudo apt update
   sudo apt install -y curl docker.io containerd
   sudo usermod -aG docker $USER
   newgrp docker
   ```

</details>

<details>
<summary><strong>For macOS Users</strong></summary>

Ensure you have:

* Docker Desktop installed and running.
* Rosetta installed (for M1/M2 chips).
* Intel-based Docker images may run slower on ARM without tuning.

Refer to: [https://docs.docker.com/desktop/install/mac-install/](https://docs.docker.com/desktop/install/mac-install/)

</details>

<details>
<summary><strong>For Linux Users</strong></summary>

Install Docker:

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

</details>

---

#### 2. Visual Studio Code (VSCode)

While other IDEs are supported, VSCode is **strongly recommended** for zero-friction Dev Container support.

* Install [**VSCode**](https://code.visualstudio.com/)
* Install the extension: **Dev Containers** (by Microsoft)
* Alternatively, install the CLI: [`devcontainer`](https://containers.dev/docs/devcontainer-cli/)

---

## 🛠️ Setup Instructions

### For VSCode Users

```bash
git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler
cd AutoOpsScaler
code .
```

1. Install the **Dev Containers** extension if not already installed.
2. Press `Ctrl + Shift + P` ➝ Select `Dev Containers: Rebuild Container`.
3. Wait for the container to finish provisioning.
4. Close all terminals after the build.
5. Open a new terminal inside the devcontainer:

   ```bash
   make login     # Uses GitHub Personal Access Token (PAT) login only
   make bootstrap # Installs all CLI binaries and Python dependencies
   ```

---

### For Other IDEs / Terminal Users

```bash
git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler
cd AutoOpsScaler
```
> ❗ JSON doesn't support logic or dynamic expressions, so manual volume binding is required if not using VSCode.

1. Manually mount the volume by configuring `.devcontainer/devcontainer.json`.
2. Build the container using the CLI:

   ```bash
   devcontainer build --workspace-folder .
   ```
3. After container setup completes:

   ```bash
   make login
   make bootstrap
   ```


---

## ☸️ Create a Local Kubernetes Cluster (Minikube)

AutoOpsScaler uses Minikube to simulate a production-like cluster for local testing. This is essential to test **KubeRay autoscaling with Karpenter on EKS**.

> ✅ Minikube uses a full VM (via Docker driver) and offers maximum reliability despite a slower startup.

```bash
minikube start --driver=docker --cpus=6 --memory=10g
```

> Ensure Docker is running and your user has access to the Docker socket.

---

## 📌 Platform Notes

* The `.devcontainer/devcontainer.json` defines the build environment.
* All required tools, CLIs, and Python packages are installed via `make bootstrap`.
* GitHub login is required via Personal Access Token (PAT); browser logins are deprecated.
* Local cluster provisioning is necessary for end-to-end testing of autoscaling and infra orchestration features.

---

## 🧠 About the Platform

AutoOpsScaler is purpose-built for:

* GenAI engineers working with dynamic, autoscaling Ray clusters.
* Fully automated and declarative K8s infrastructure (Minikube ➝ EKS).
* Zero-handoff between development and staging environments using containers.

---

## ✅ You're Ready

Start building, deploying, and scaling GenAI workloads without worrying about infrastructure plumbing. Everything is **automated**, **reproducible**, and **battle-tested**.

---

## 🔒 troubleshooting

If anything breaks during container startup or Minikube provisioning, always run:

```bash
docker ps -a && docker logs <container-id>
minikube logs
```

Also, clear volumes and images with:

```bash
docker system prune -af --volumes
minikube delete
```

