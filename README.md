# **AutoOpsScaler — A LowOps environment to implement the top GenAI scaling statergy**

## KubeRay on EKS + Karpenter is the leading production strategy for highly scalable, cost-effective GenAI clusters.
| **Aspect**                           | **KubeRay on EKS + Karpenter**                                        | **Alternatives (summary)**                                                                         |
| ------------------------------------ | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Node provisioning latency**        | Sub‑minute: just‑in‑time EC2 nodes on unschedulable Ray pods          | 2–5 min boot (Cluster Autoscaler, EC2, Fargate); instant but opaque (serverless)                   |
| **GPU flexibility & fractional use** | Any EC2 GPU (A10G/A100/H100); Ray supports fractional scheduling      | Predefined pools(EKS-Auto), no fractional (EKS CA); limited SKUs (GKE); no GPU (Fargate)                     |
| **Spot + On‑Demand cost mix**        | Optimized Spot usage with fallback; Ray handles preemptions           | Slower rebalancing (CA); extra fees (EKS‑Auto); manual Spot handling (EC2); high cost (serverless) |
| **Observability & debugging**        | Full: Kubernetes events, Ray Dashboard, Prometheus                    | Limited logs (managed Ray services); less verbose (CA); manual scripts (EC2)                       |
| **Operational overhead**             | Minimal: single Karpenter CRD + RayService, fewer IAM policies        | Multiple CRDs/HPA/KEDA/CA rules; custom EC2 scripts; YAML bloat                                    |
| **Self‑healing**                     | Automatic node replacement and Ray task restarts                      | Slower node recovery (CA); manual scripts (EC2); vendor dependent (serverless)                     |
| **Use‑case suitability**             | Top choice: LLM training, fine‑tuning, batch inference, RAG pipelines | Prototype only (serverless); stateless services (ECS); DIY clusters (bare‑metal)                   |

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
│
├── infra/
│   ├── dev/
│   │   ├── delete-lc.sh                # Deletes local K3D cluster and resources
│   │   └── lc.sh                       # Creates local K3D cluster for testing
│   │
│   ├── prod/
│   │   ├── eks/
│   │   │   └── eks.tf                  # EKS cluster provisioning (managed nodegroups)
│   │   ├── iam_bootstrap/
│   │   │   └── iam_bootstrap.tf        # IAM bootstrap roles and policies
│   │   ├── iam_irsa/
│   │   │   └── iam_irsa.tf             # IRSA role for Lambda to call Kubernetes
│   │   ├── vpc/
│   │   │   └── vpc.tf                  # VPC, subnets, IGW, NAT
│   │   ├── main.tf                     # Terraform root module for prod
│   │   ├── outputs.tf                  # Output variables for IRSA/EKS cluster
│   │   ├── outputs.tfvars              # Exported values from Terraform for other tooling
│   │   ├── terraform.tfvars            # Terraform prod input values
│   │   └── variables.tf                # Input variable definitions
│   │
│   └── s3.py                           # Python helper script to create S3 bucket and folders
│
├── lambda_deploy_rayjob/
│   ├── lambda_function.py              # Lambda function to submit RayJob on S3 upload
│   ├── requirements.txt                # Lambda dependencies (boto3, kubernetes, etc.)
│   ├── rayjob_template.yml             # RayJob manifest with dynamic placeholders
│   └── Dockerfile                      # Lambda-compatible container (for ECR-based deployment)
│
├── flux/
│   ├── base/
│   │   ├── apps/
│   │   │   ├── qdrant.yml              # Qdrant StatefulSet, PVC, and Service
│   │   │   ├── ray_job.yml             # RayJob (batch inference workload)
│   │   │   ├── ray_service.yml         # RayService (persistent online service)
│   │   │   ├── prometheus.yml          # Prometheus stack (Prometheus, Grafana, Alertmanager)
│   │   │   └── kustomization.yml       # Groups all app manifests
│   │   │
│   │   ├── config/
│   │   │   ├── configmap.yml           # Global ConfigMap
│   │   │   ├── ingress.yml             # Traefik IngressRoute and Middleware
│   │   │   ├── k8s-secrets.yml         # Kubernetes Secret resources
│   │   │   ├── namespace.yml           # dev/prod Namespace definitions
│   │   │   └── kustomization.yml       # Groups all config resources
│   │   │
│   │   ├── infra/
│   │   │   ├── karpenter.cpu.yml       # Karpenter provisioner for CPU-optimized pods
│   │   │   ├── karpenter.gpu.yml       # Karpenter provisioner for GPU workloads
│   │   │   ├── zalando/
│   │   │   │   ├── operator.yml        # Zalando Postgres Operator Deployment
│   │   │   │   ├── rbac.yml            # ServiceAccount, Role, RoleBinding
│   │   │   │   └── cluster.yml         # PostgresCluster CR (acid.zalan.do/v1)
│   │   │   └── kustomization.yml       # Groups all infra manifests
│   │   │
│   │   └── kustomization.yml           # Flux base root: includes apps/, config/, infra/
│   |
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yml       # Kustomize overlays for dev environment
│       │
│       └── prod/
│           └── kustomization.yml       # Kustomize overlays for prod environment
|
|── utils/                              # Shared utility functions and helpers
|   ├── __init__.py                     # Marks the utils directory as a Python package
|   ├── deduplicator.py                 # Implements hashlib based deduplication
|   ├── logger.py                       # Centralized structured logging setup
|   └── s3_util.py                      # Helper functions for S3 upload/download with boto3
|
├── data_pipeline
│   ├── data_pipeline_config.yml        # central ELT & embedding pipeline settings
│   ├── main.py                         # Ray workflow orchestrator for data pipeline
│   └── modules
│       ├── data_processing
│       │   ├── Dockerfile              # container spec for text preprocessing stage
│       │   ├── README.md               # docs on parsing heuristics and chunking
│       │   ├── __init__.py             # package marker for data_processing module
│       │   ├── chunker_llamaindex.py   # splits text into LlamaIndex‑compatible chunks
│       │   ├── doc_parser.py           # parses documents via unstructured.io with tracing
│       │   ├── filters.py              # filters noise and computes retention stats
│       │   ├── format_normalizer.py    # standardizes metadata and logs normalization
│       │   ├── html_parser.py          # extracts text from HTML via trafilatura
│       │   └── requirements.txt        # Python dependencies for preprocessing container
│       ├── embedding
│       │   ├── Dockerfile              # container spec for batch embedding stage
│       │   ├── __init__.py             # package marker for embedding module
│       │   ├── batch_embed.py          # parallel embedding job runner
│       │   ├── embed_to_qdrant.py      # pushes embeddings into Qdrant DB
│       │   ├── insert_metadata.py      # writes document metadata to Postgres
│       │   ├── main.py                 # entrypoint for embedding worker service
│       │   ├── model_loader.py         # loads and caches embedding models
│       │   ├── requirements.txt        # Python dependencies for embedding container
│       │   └── worker.py               # per‑task embedding logic with telemetry
│       └── extract_load
│           ├── Dockerfile              # container spec for extract & load stage
│           ├── README.md               # docs on extraction and S3 loading workflow
│           ├── __init__.py             # package marker for extract_load module
│           ├── file_watcher.py         # monitors local/S3 and triggers data ingest
│           ├── llamaindex_loader.py    # dedups and indexes docs via LlamaIndex
│           ├── requirements.txt        # Python dependencies for extract/load container
│           ├── s3_uploader.py          # uploads raw files to S3 via boto3
│           └── web_scraper.py          # Scrapy+Playwright scraper with dedupe logic
|
├── docs/                       # documentation for infra & platform
|
├── inference_pipeline
│   ├── api
│   │   ├── backend
│   │   │   ├── Dockerfile              # container spec for FastAPI backend
│   │   │   ├── __init__.py             # package marker for backend module
│   │   │   ├── backend_config.yml      # config for backend orchestration
│   │   │   ├── dependencies
│   │   │   │   ├── __init__.py         # package marker for dependencies
│   │   │   │   ├── auth_postgres.py    # JWT auth via Postgres session store
│   │   │   │   ├── config.py           # loads env vars and DB settings
│   │   │   │   └── tables
│   │   │   │       ├── __init__.py     # package marker for ORM tables
│   │   │   │       ├── feedback.py     # SQLAlchemy model for feedback entries
│   │   │   │       ├── query_log.py    # SQLAlchemy model for query auditing
│   │   │   │       ├── session.py      # SQLAlchemy model for session tokens
│   │   │   │       └── user.py         # SQLAlchemy model for user accounts
│   │   │   ├── main.py                 # FastAPI app entrypoint registering routes
│   │   │   ├── requirements.txt        # Python deps for backend container
│   │   │   └── routes
│   │   │       ├── __init__.py         # package marker for route handlers
│   │   │       ├── embedding.py        # endpoint for embedding generation
│   │   │       ├── generate.py         # endpoint for LLM text generation
│   │   │       ├── health.py           # health and readiness probe endpoints
│   │   │       ├── job.py              # endpoints to trigger background jobs
│   │   │       └── search.py           # endpoint for semantic search queries
│   │   └── frontend
│   │       ├── Dockerfile              # container spec for React/Vite frontend
│   │       ├── index.html              # HTML template mounting React app
│   │       ├── package.json            # frontend dependencies and scripts
│   │       ├── requirements.txt        # any Python deps needed by frontend
│   │       ├── src
│   │       │   ├── App.tsx             # root React component with routing
│   │       │   ├── api.ts              # Axios client setup with JWT auth
│   │       │   ├── components
│   │       │   │   ├── FileUploader.tsx # drag‑and‑drop file uploader UI
│   │       │   │   └── Header.tsx      # top navigation bar component
│   │       │   ├── main.tsx            # React entrypoint mounting App
│   │       │   ├── pages
│   │       │   │   ├── Generate.tsx    # LLM prompt submission UI
│   │       │   │   ├── Login.tsx       # user login page component
│   │       │   │   └── Search.tsx      # semantic search UI component
│   │       │   └── styles
│   │       │       └── main.css        # global CSS styles
│   │       └── vite.config.ts          # Vite build & dev server config
│   └── rag
│       ├── Dockerfile                  # container spec for RAG & eval pipelines
│       ├── main.py                     # Ray workflow entrypoint for RAG & eval
│       ├── modules
│       │   ├── __init__.py             # package marker for RAG modules
│       │   ├── agent.py                # ReAct agent orchestration logic
│       │   ├── eval_pipeline.py        # RAG evaluation pipeline implementation
│       │   ├── generator.py            # LLM invocation and token logging
│       │   ├── ragas_wrapper.py        # adapter for RAGAS/trulens APIs
│       │   └── retriever.py            # vector DB search and retrieval logic
│       ├── rag_config.yml              # configuration for RAG pipeline
│       └── requirements.txt            # Python deps for RAG & eval container
|
├── scripts/                            # Essential bash scripts like login.sh, install.sh,.etc
|
├── tests
│   ├── __init__.py                     # marks tests as pytest package
│   ├── conftest.py                     # shared pytest fixtures and mocks
│   ├── env_check.sh                    # verifies required CLI tools are present
│   ├── test_api.py                     # unit tests for inference API endpoints
│   ├── test_embedding.py               # tests for embedding workflows
│   ├── test_ingestion.py               # tests for extract-load logic
│   ├── test_rag.py                     # tests for RAG retriever & generator
│   └── test_vector.py                  # tests for Qdrant upsert & query ops


```
```py
AutoOpsScaler/
│
├── core/                                    # 🔁 Reusable core agent framework
│   ├── agents/                              # Multi‑agent planning & execution logic
│   ├── tools/                               # Tool interface wrappers (APIs, DBs, etc.)
│   ├── memory/                              # Memory stores & summarization helpers
│   ├── prompts/                             # Versioned prompt templates
│   ├── retrieval/                           # RAG pipelines: loaders, chunkers, retrievers
│   └── orchestration/                       # LangGraph / CrewAI orchestration engines
│
├── infra/                                   # 🚀 Cloud‑native infra, policy & observability
│   ├── dev/
│   │   ├── delete-lc.sh                     # Deletes local K3D cluster and resources
│   │   └── lc.sh                            # Creates local K3D cluster for testing
│   │
│   ├── prod/
│   │   ├── eks/                             # EKS cluster provisioning (managed nodegroups)
│   │   │   └── eks.tf                       # EKS Terraform module
│   │   ├── iam_bootstrap/                   # IAM bootstrap roles and policies
│   │   │   └── iam_bootstrap.tf             # IAM bootstrap Terraform
│   │   ├── iam_irsa/                        # IRSA role for Lambda to call Kubernetes
│   │   │   └── iam_irsa.tf                  # IRSA Terraform
│   │   ├── vpc/                             # VPC, subnets, IGW, NAT
│   │   │   └── vpc.tf                       # VPC Terraform
│   │   ├── policy/                          # Open Policy Agent and Gatekeeper constraints
│   │   │   ├── opa_policies.rego            # OPA rules
│   │   │   └── gatekeeper_constraints.yaml  # Gatekeeper constraints
│   │   ├── observability/                   # OTEL + Loki/Grafana for logs & traces
│   │   │   ├── opentelemetry-collector.yml  # OTEL collector config
│   │   │   └── loki-stack.yml               # Loki/Grafana stack manifests
│   │   ├── main.tf                          # Terraform root module for prod
│   │   ├── outputs.tf                       # Output variables for IRSA/EKS cluster
│   │   ├── outputs.tfvars                   # Exported values for other tooling
│   │   ├── terraform.tfvars                 # Terraform prod input values
│   │   └── variables.tf                     # Input variable definitions
│   │
│   └── s3.py                                # Python helper script to create S3 bucket and folders
│
├── lambda_deploy_rayjob/                    # RayJob submission via Lambda
│   ├── lambda_function.py                   # Lambda function to submit RayJob on S3 upload
│   ├── validator.py                         # Validates S3 trigger event schema
│   ├── logger.py                            # Centralized Lambda logging setup
│   ├── metrics.py                           # CloudWatch metrics for monitoring job invocations
│   ├── rayjob_template.yml                  # RayJob manifest with dynamic placeholders
│   ├── requirements.txt                     # Lambda dependencies (boto3, kubernetes, etc.)
│   └── Dockerfile                           # Lambda-compatible container (for ECR-based deployment)
│
├── flux/                                    # GitOps manifests (Flux + Kustomize)
│   ├── base/
│   │   ├── apps/
│   │   │   ├── qdrant.yml                  # Qdrant StatefulSet, PVC, and Service
│   │   │   ├── ray_job.yml                 # RayJob (batch inference workload)
│   │   │   ├── ray_service.yml             # RayService (persistent online service)
│   │   │   ├── prometheus.yml              # Prometheus stack (Prometheus, Grafana, Alertmanager)
│   │   │   └── kustomization.yml           # Groups all app manifests
│   │   ├── config/
│   │   │   ├── configmap.yml               # Global ConfigMap
│   │   │   ├── ingress.yml                 # Traefik IngressRoute and Middleware
│   │   │   ├── k8s-secrets.yml             # Kubernetes Secret resources
│   │   │   ├── namespace.yml               # dev/prod Namespace definitions
│   │   │   └── kustomization.yml           # Groups all config resources
│   │   ├── infra/
│   │   │   ├── karpenter.cpu.yml           # Karpenter provisioner for CPU-optimized pods
│   │   │   ├── karpenter.gpu.yml           # Karpenter provisioner for GPU workloads
│   │   │   ├── zalando/
│   │   │   │   ├── operator.yml            # Zalando Postgres Operator Deployment
│   │   │   │   ├── rbac.yml                # ServiceAccount, Role, RoleBinding
│   │   │   │   └── cluster.yml             # PostgresCluster CR (acid.zalan.do/v1)
│   │   │   └── kustomization.yml           # Groups all infra manifests
│   │   ├── rbac/                           # Kubernetes security & audit
│   │   │   ├── read_only_roles.yml        # Least-privilege roles
│   │   │   └── audit_policies.yml         # K8s audit policies (logs API access, execs)
│   │   └── kustomization.yml              # Flux base root: includes apps/, config/, infra/, rbac/
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yml           # Kustomize overlay for dev environment
│       └── prod/
│           └── kustomization.yml           # Kustomize overlay for prod environment
│
├── data_pipeline/                           # ELT & embedding workflows (Ray)
│   ├── data_pipeline_config.yml            # central ELT & embedding pipeline settings
│   ├── main.py                             # Ray workflow orchestrator for data pipeline
│   └── modules/
│       ├── data_processing/
│       │   ├── Dockerfile                   # container spec for text preprocessing stage
│       │   ├── README.md                    # docs on parsing heuristics and chunking
│       │   ├── chunker_llamaindex.py        # splits text into LlamaIndex‑compatible chunks
│       │   ├── doc_parser.py                # parses documents via unstructured.io with tracing
│       │   ├── filters.py                   # filters noise and computes retention stats
│       │   ├── format_normalizer.py         # standardizes metadata and logs normalization
│       │   ├── html_parser.py               # extracts text from HTML via trafilatura
│       │   └── requirements.txt             # Python dependencies for preprocessing container
│       ├── embedding/
│       │   ├── Dockerfile                   # container spec for batch embedding stage
│       │   ├── batch_embed.py               # parallel embedding job runner
│       │   ├── embed_to_qdrant.py           # pushes embeddings into Qdrant DB
│       │   ├── insert_metadata.py           # writes document metadata to Postgres
│       │   ├── main.py                      # entrypoint for embedding worker service
│       │   ├── model_loader.py              # loads and caches embedding models
│       │   ├── worker.py                    # per‑task embedding logic with telemetry
│       │   └── requirements.txt             # Python dependencies for embedding container
│       └── extract_load/
│           ├── Dockerfile                   # container spec for extract & load stage
│           ├── README.md                    # docs on extraction and S3 loading workflow
│           ├── file_watcher.py              # monitors local/S3 and triggers data ingest
│           ├── llamaindex_loader.py         # dedups and indexes docs via LlamaIndex
│           ├── s3_uploader.py               # uploads raw files to S3 via boto3
│           ├── web_scraper.py               # Scrapy+Playwright scraper with dedupe logic
│           └── requirements.txt             # Python dependencies for extract/load container
│
├── inference_pipeline/                      # Serving & RAG + eval
│   ├── api/
│   │   ├── backend/
│   │   │   ├── Dockerfile                   # container spec for FastAPI backend
│   │   │   ├── backend_config.yml           # config for backend orchestration
│   │   │   ├── dependencies/
│   │   │   │   ├── __init__.py              # package marker for dependencies
│   │   │   │   ├── auth_postgres.py         # JWT auth via Postgres session store
│   │   │   │   ├── config.py                # loads env vars and DB settings
│   │   │   │   └── tables/
│   │   │   │       ├── feedback.py          # SQLAlchemy model for feedback entries
│   │   │   │       ├── query_log.py         # SQLAlchemy model for query auditing
│   │   │   │       ├── session.py           # SQLAlchemy model for session tokens
│   │   │   │       └── user.py              # SQLAlchemy model for user accounts
│   │   │   ├── main.py                      # FastAPI app entrypoint registering routes
│   │   │   ├── monitoring/                  # Realtime metrics & tracing
│   │   │   │   ├── metrics.py               # Prometheus metrics export via FastAPI
│   │   │   │   ├── trace.py                 # OpenTelemetry span & trace decorators
│   │   │   │   └── feedback_loop.py         # Logs user feedback to improve model prompts
│   │   │   ├── requirements.txt             # Python deps for backend container
│   │   │   └── routes/
│   │   │       ├── embedding.py             # endpoint for embedding generation
│   │   │       ├── generate.py              # endpoint for LLM text generation
│   │   │       ├── health.py                # health and readiness probe endpoints
│   │   │       ├── job.py                   # endpoints to trigger background jobs
│   │   │       └── search.py                # endpoint for semantic search queries
│   │   └── frontend/
│   │       ├── Dockerfile                   # container spec for React/Vite frontend
│   │       ├── index.html                   # HTML template mounting React app
│   │       ├── package.json                 # frontend dependencies and scripts
│   │       └── src/
│   │           ├── App.tsx                  # root React component with routing
│   │           ├── api.ts                   # Axios client setup with JWT auth
│   │           ├── components/
│   │           │   ├── FileUploader.tsx     # drag‑and‑drop file uploader UI
│   │           │   └── Header.tsx           # top navigation bar component
│   │           ├── pages/
│   │           │   ├── Generate.tsx         # LLM prompt submission UI
│   │           │   ├── Login.tsx            # user login page component
│   │           │   └── Search.tsx           # semantic search UI component
│   │           └── styles/
│   │               └── main.css            # global CSS styles
│   └── rag/
│       ├── Dockerfile                       # container spec for RAG & eval pipelines
│       ├── main.py                          # Ray workflow entrypoint for RAG & eval
│       ├── modules/
│       │   ├── agent.py                     # ReAct agent orchestration logic
│       │   ├── hybrid_retriever.py          # Combines BM25 + dense search (rerankers)
│       │   ├── eval_pipeline.py             # RAG evaluation pipeline implementation
│       │   ├── generator.py                 # LLM invocation and token logging
│       │   ├── ragas_wrapper.py             # adapter for RAGAS/trulens APIs
│       │   ├── multi_agent_router.py        # Multi-agent orchestration based on use case
│       │   └── rate_limiter.py              # Enforces rate limits per API key/user
│       ├── rag_config.yml                  # configuration for RAG pipeline
│       └── requirements.txt                # Python deps for RAG & eval container
│
├── utils/                                   # Shared utilities
│   ├── __init__.py                          # Marks the utils directory as a Python package
│   ├── deduplicator.py                      # Implements hashlib based deduplication
│   ├── logger.py                            # Centralized structured logging setup
│   ├── s3_util.py                           # Helper functions for S3 upload/download with boto3
│   ├── otel_setup.py                        # One-liner setup for OpenTelemetry tracing
│   ├── jwt_util.py                          # JWT generation, validation helpers
│   └── cache.py                             # Simple LRU or Redis-based caching wrapper
│
├── docs/                                    # Documentation & diagrams
│   ├── architecture/
│   │   ├── component_diagram.md            # Visual of system components and data flow
│   │   ├── dev_onboarding.md               # How to extend or reuse parts of the system
│   │   └── scaling_strategies.md           # Strategies for autoscaling Ray, RAG, API layers
│   └── README.md                           # High-level project overview and setup
│
├── scripts/                                 # Utility scripts (install, login, etc.)
│   ├── install.sh                          # Project installation steps
│   └── login.sh                            # AWS & K8s cluster login helper
│
├── tests/                                   # Automated tests
│   ├── __init__.py                          # marks tests as pytest package
│   ├── conftest.py                          # shared pytest fixtures and mocks
│   ├── env_check.sh                         # verifies required CLI tools are present
│   ├── test_api.py                          # unit tests for inference API endpoints
│   ├── test_embedding.py                    # tests for embedding workflows
│   ├── test_ingestion.py                    # tests for extract-load logic
│   ├── test_rag.py                          # tests for RAG retriever & generator
│   └── test_vector.py                       # tests for Qdrant upsert & query ops
│
└── README.md                               # Project README with high-level description
```

```
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
> The default configs are RAM = 11GB, vcpus=8, no gpu override it in the Vagrantfile if needed 
---

## **Important: VM Lifecycle**

 ### **After a system reboot**, the VM will be shut down. Always start it manually before connecting from VS Code:

  * Open VirtualBox → Right-click the VM → **Start → Headless Start and wait atleast 30-60 seconds before opening vscode**

  ![Start the VM](.vscode/Start_the_VM.png)

### **Optionally, you can save the VM state before shutting down your system for faster resumption:**

  * Open VirtualBox → Right-click the VM → **Close → Save State**

  ![Save VM state](.vscode/Save_VM_state.png)



