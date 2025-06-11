
# AutoOpsScaler (Vagrant Dev Environment)

> ⚠️ Native Linux is strongly recommended for full Kubernetes compatibility.  
> If you're using **WSL** or a **Dev Container**, follow these steps exactly to avoid issues.

## Install the required tools in this order and restart your system

Windows:
- https://git-scm.com/downloads/win
- https://aka.ms/vs/17/release/vc_redist.x64.exe
- https://download.virtualbox.org/virtualbox/7.0.14/VirtualBox-7.0.14-161095-Win.exe
- https://releases.hashicorp.com/vagrant/2.4.3/vagrant_2.4.3_windows_amd64.msi  
  
  
macOS 
- https://download.virtualbox.org/virtualbox/7.0.14/
- https://developer.hashicorp.com/vagrant/downloads   # Install vagrant 2.4.3 only

##  Git Config (Before Cloning) to prevent dos2unix conversions

```
git config --global core.autocrlf false  
git config --global core.fileMode false  
git config --global core.eol lf
```

## Setup Instructions

```
git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler.git && cd AutoOpsScaler 
 
```

### (Optional) Adjust RAM/CPU in Vagrantfile — default is 11GB RAM and 6 CPUs  
```
vagrant up  
vagrant reload   # Apply Docker group permissions  
vagrant ssh  
```


# Blueprint

```
AutoOpsScaler/ 
├── .github/
│   └── workflows/
│       ├── ci.yaml                                  # ruff, typecheck, pytest
│       ├── build_and_push.yaml                     # Build & push Docker images
│       └── sync_argocd.yaml                        # Trigger ArgoCD sync via REST API
|
├── .gitignore                           # Git exclusion file to prevent committing sensitive or irrelevant files.
├── .dockerignore                        # Docker exclusion file to prevent building unnecessary files into images.
├── Makefile                             # LowOps commands for devs like make create-prod-cluster, make deploy-indexing-pipeline, etc.
├── README.md                            # High-level documentation describing architecture, domains, and usage instructions.
├── requirements.txt                     # List of runtime dependencies for Python including Ray, FastAPI, Pathlib, and parsing tools.

├── dev/
│   ├── k3s-cluster.yaml                 # k3s cluster config for local testing of multi-node clusters with PVCs.
│   ├── s3_schema.py                     # Uses boto3 to create bucket with the right schema like data/raw/, data/parsed/, data/chunked/, etc.
│   └── README.md                        # Describes how to set up local dev environment using k3s, and simulate S3 schema.
|
├── config/
│   ├── base_config.yaml                 # Centralized config shared across environments (e.g., default paths, timeouts).
│   ├── dev_config.yaml                  # Local development config that overrides base, includes local endpoint URIs (e.g., S3).
│   ├── prod_config.yaml                 # Production-specific overrides, including secure endpoints and resource constraints.
│   ├── secrets_template.yaml            # Template for secret keys/envs to be filled in CI/CD or secure vault integrations.
│   └── README.md                        # Explains environment-specific config layering and secure secrets injection for CI/CD.
|
├── utils/
│   ├── __init__.py                      # Marks the utils package for internal Python module resolution.
│   ├── config_loader.py                 # Utility to load layered config from `config/` directory with environment awareness.
│   ├── logger.py                        # Centralized structured logging utility using standard `logging`, integrates with observability.
│   ├── s3_utils.py                      # Wrapper around `boto3` for uploading/downloading docs to S3.
│   ├── deduplicator.py                  # Uses `xxhash` to deduplicate file extraction, parsing, chunking, etc.
│   └── README.md                        # Documents utility functions for config management, logging, S3 I/O, and deduplication logic.
|
├── extract_load/                        # All raw files are stored in s3://<bucket>/data/raw/ to return original S3 URLs during RAG inference.
│   ├── Dockerfile                       # Container spec for document loaders/scrapers; no GPU required.
│   ├── dynamic_RayJob_generator.py      # Generates RayJob manifests dynamically based on environment
│   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   ├── app-extract-load.argocd.yaml     # Argo CD Application manifest for GitOps sync of extract-load pipeline.
│   └── modules/
│       ├── __init__.py                  # Declares extract_load as Python module.
│       ├── file_watcher.py              # Watches S3/local folders for new input files; add logging, but no external observability needed.
│       ├── llamaindex_loader.py         # Loads documents via LlamaIndex connectors; add Langfuse tracing for large or slow docs.
│       ├── scraper.py                   # Web scraper using Scrapy + Playwright; should log errors and emit trace spans due to failure-prone
│       ├── s3_uploader.py               # Uploads raw docs to S3 with boto3; latency metrics via Prometheus can help detect bottlenecks.
│       ├── main.py      # Orchestrates entire extract pipeline using Ray Workflows; wrap stages with Langfuse spans for visibility.
│       └── README.md                    # Docs for extract-load flow covering loaders, scrapers, and S3 uploader.
|
├── data_preprocessing/
│   ├── Dockerfile                       # Container for document preprocessing: parsing, OCR, chunking, dedup.
│   ├── dynamic_RayJob_generator.py      # Generates RayJob manifests dynamically based on environment
│   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   ├── app-data-preprocess.argocd.yaml  # Argo CD Application manifest for GitOps sync of data preprocessing pipeline.
│   └── modules/
│       ├── __init__.py                  # Declares data_preprocessing as a Python module.
│       ├── chunker_llamaindex.py        # Splits text into chunks using LlamaIndex splitters; lightweight, but should emit latency metrics.
│       ├── doc_parser.py                # Parses files via unstructured.io; add Langfuse spans to trace parser perf/errors.
│       ├── html_parser.py               # Parses HTML with trafilatura; may benefit from logging for malformed docs.
│       ├── format_normalizer.py         # Cleans text and metadata; emit chunk count and cleaning ratio as Prometheus metrics.
│       ├── filters.py                   # Filters out junk/boilerplate; should record chunk retention ratio for tuning.
│       ├── main.py       # Orchestrates full preprocessing pipeline using Ray Workflows; wrap with Langfuse/OpenLLMetry for full traceability.
│       └── README.md                    # Docs covering parsing strategies, chunking configs, and filtering heuristics.
|
├── embedding/
│   ├── Dockerfile                       # Builds container for embedding pipeline using Ray Serve workers.
│   ├── dynamic_RayJob_generator.py      # Generates RayJob manifests dynamically based on environment
│   ├── dynamic_RayService_generator.py  # Generates RayService manifests for API deployments
│   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   ├── app-embedding.argocd.yaml        # Argo CD Application manifest for GitOps sync of embedding pipeline.
│   └── modules/
│       ├── __init__.py                  # Marks modules as a Python package.
│       ├── batch_embed.py               # Orchestrates batch embedding flow using Ray Workflows; should include Prometheus metrics.
│       ├── model_loader.py              # Loads SentenceTransformer models; ideal point for Langfuse tracing.
│       ├── worker.py                    # Embedding logic in Ray tasks; should emit Langfuse/OpenLLMetry spans.
│       └── main.py                      # Entry-point script; should init observability and start Ray tasks.
|
├── vector_db/
│   ├── Dockerfile                       # Builds container for vector storage pipelines to Qdrant.
│   ├── dynamic_RayJob_generator.py      # Generates RayJob manifests dynamically based on environment
│   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   ├── app-vector.argocd.yaml           # Argo CD Application manifest for GitOps sync of Qdrant vector ingestion.
│   └── modules/
│       ├── __init__.py                  # Marks modules as a Python package.
│       ├── embed_to_qdrant.py           # Pushes embeddings to Qdrant; should emit latency metrics.
│       ├── qdrant_client.py             # Qdrant client wrapper; key place to monitor search latency.
│       ├── query_qdrant.py              # Query logic for similarity search; candidate for Prometheus + Langfuse.
│       ├── schema.json                  # Qdrant collection schema; static config file for schema enforcement.
│       └── main.py                      # Entry-point for Qdrant interaction; should include metrics and tracing.
|
├── meta_store/
│   ├── Dockerfile                       # Builds container for Supabase-backed metadata ops.
│   ├── dynamic_RayJob_generator.py      # Generates RayJob manifests dynamically based on environment
│   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   ├── app-supabase.argocd.yaml         # Argo CD Application manifest for GitOps sync of Supabase metadata tasks.
│   └── modules/
│       ├── __init__.py                  # Marks modules as a Python package.
│       ├── insert_metadata.py           # Inserts doc metadata; should log structured data for traceability.
│       ├── query_metadata.py            # Fetches metadata via Supabase; should expose latency metrics.
│       └── supabase_client.py           # Supabase client logic; a hook point for error tracking and metrics.
|
├── inference_pipeline/
│   ├── rag/
│   │   ├── Dockerfile                   # Container to serve full RAG pipeline with Haystack + FastAPI.
│   │   ├── dynamic_RayJob_generator.py  # Generates RayJob manifests dynamically based on environment
│   │   ├── dynamic_RayService_generator.py # Generates RayService manifests for API deployments
│   │   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   │   ├── app-rag.argocd.yaml          # Argo CD Application manifest for GitOps sync of RAG orchestration.
│   │   └── modules/
│   │       ├── __init__.py              # Marks modules as a Python package.
│   │       ├── generator.py             # Calls LLM for response; must log Langfuse spans and token usage.
│   │       ├── pipeline.py              # End-to-end orchestration logic for RAG using Ray Workflows; should be traced and metered.
│   │       └── retriever.py             # Vector + metadata search; should emit QPS and latency metrics.
│   ├── evaluation/
│   │   ├── Dockerfile                   # Container for RAG evaluation service using RAGAS.
│   │   ├── dynamic_RayJob_generator.py  # Generates RayJob manifests dynamically based on environment
│   │   ├── dynamic_StatefulSet_generator.py # Generates StatefulSet manifests for persistent services
│   │   └── modules/
│   │       ├── __init__.py              # Marks modules as a Python package.
│   │       ├── eval_pipeline.py         # Coordinates scoring of RAG outputs; log success/failure stats.
│   │       └── ragas_wrapper.py         # Integrates with RAGAS metrics; ideal point for OpenLLMetry tracing.
│   ├── api/                             # API moved inside inference_pipeline for better encapsulation
│   │   ├── frontend/                    # React frontend for user interaction, served separately from backend
│   │   │   ├── Dockerfile               # Builds React app using multi-stage build; outputs static assets for production
│   │   │   ├── vite.config.ts           # Vite config for fast local dev and optimized build
│   │   │   ├── index.html               # Main HTML template for React root
│   │   │   ├── package.json             # Frontend dependencies and build scripts
│   │   │   └── src/
│   │   │       ├── main.tsx             # React app entry point, renders root component
│   │   │       ├── App.tsx              # Root component housing all routes and layout
│   │   │       ├── api.ts               # Axios wrapper with Supabase token injection
│   │   │       ├── components/
│   │   │       │   ├── Header.tsx       # Header/navigation bar
│   │   │       │   └── FileUploader.tsx # UI component for file ingestion trigger
│   │   │       ├── pages/
│   │   │       │   ├── Search.tsx       # Page for semantic search interaction
│   │   │       │   ├── Generate.tsx     # Page for LLM generation via prompt
│   │   │       │   └── Login.tsx        # Login page using Supabase OAuth/JWT
│   │   │       └── styles/
│   │   │           └── main.css         # Tailwind or custom CSS
│   │   ├── backend/                     # Ray Serve backend API handling search, embedding, generation, health, etc.
│   │   │   ├── Dockerfile               # Backend Dockerfile, installs Ray, FastAPI, Supabase, etc.
│   │   │   ├── dynamic_RayService_generator.py # Generates RayService manifests for API deployments
│   │   │   ├── app-api.argo.yml         # Argo CD Application manifest for GitOps sync of backend API.
│   │   │   ├── __init__.py              # Marks backend directory as Python module.
│   │   │   ├── main.py                  # Entrypoint for Ray Serve app with FastAPI integration.
│   │   │   ├── dependencies/            # Common logic for config, Supabase auth, DB models.
│   │   │   │   ├── __init__.py
│   │   │   │   ├── config.py            # Loads env vars and runtime settings using `os.getenv` or `pydantic.BaseSettings`.
│   │   │   │   ├── auth_supabase.py     # Supabase JWT verification and user extraction from header.
│   │   │   │   └── tables/              # Defines Supabase table schema references (for validation/types), RPC/mapping utils.
│   │   │   │       ├── __init__.py      # Binds engine, Base metadata, and optionally runs `create_all()`.
│   │   │   │       ├── user.py          # User table with id, email, role, supabase_id.
│   │   │   │       ├── session.py       # Session tokens, expiry tracking, device info.
│   │   │   │       ├── feedback.py      # RAG/LLM feedback table (thumbs, corrections, etc).
│   │   │   │       └── query_log.py     # Stores queries and usage data for analytics.
│   │   │   └── routes/                  # FastAPI route handlers split by domain.
│   │   │       ├── __init__.py
│   │   │       ├── embedding.py         # Accepts text/file, returns vector embedding using configured model.
│   │   │       ├── generate.py          # Accepts prompt, returns LLM output (with streaming optionally).
│   │   │       ├── health.py            # `/health` and `/readiness` endpoints for K8s probes and monitoring.
│   │   │       ├── job.py               # Handles background tasks: chunking, ingestion, Ray task submission.
│   │   │       └── search.py            # Accepts query, performs vector search, returns chunk + original S3 URL.
│   └── README.md                        # Documentation for inference pipeline, API endpoints, and frontend usage.
|
├── orchestrator/
│   ├── Dockerfile                       # Container spec for long-running Ray Serve orchestrator API handling jobs across modules.
│   ├── dynamic_RayService_generator.py  # Generates RayService manifests for API deployments
│   ├── app-orchestrator.argocd.yaml     # Argo CD Application manifest for GitOps sync of orchestrator service.
│   └── modules/
│       ├── __init__.py                  # Declares orchestrator as a Python module.
│       ├── deployment_utils.py          # Utilities for launching/stopping RayJobs, RayServices; indirectly relies on cluster observability.
│       ├── ray_job_manager.py           # Manages lifecycle of RayJobs via Ray client API; emits metrics/traces for job status.
│       └── ray_serve_manager.py         # Controls Ray Serve deployments (for API microservices); traced by Langfuse or Ray metrics endpoints.
|
├── monitoring/
│   ├── Dockerfile                       # Container for observability stack: exposes Prometheus/Grafana/Langfuse dashboards.
│   ├── dynamic_RayService_generator.py  # Generates RayService manifests for API deployments
│   └── modules/
│       ├── __init__.py                  # Declares monitoring as a Python package.
│       ├── metrics.py                   # Prometheus metrics collection, pushing app-level and infra-level counters to central scraper.
│       ├── tracing.py                   # Langfuse or OpenLLMetry tracer logic to capture spans across ingestion/embedding/pipeline stages.
│       └── dashboard_configs/
│           ├── grafana_dashboard.json   # Prebuilt Grafana dashboard config to visualize Prometheus metrics (LLM latency, load, S3 IO etc).
│           └── ray_dashboard.yaml       # Ray dashboard custom panels and overrides (actor memory, job health, etc).
|
├── infra/
│   └── terraform/                      # Terraform for cloud provisioning (Carvel removed)
│       ├── eks.tf                      # EKS cluster with Karpenter for node autoscaler, node groups, IAM roles for S3/Qdrant 
│       ├── karpenter.tf                # Adds Karpenter CRDs, controller, provisioners with taints/labels for Ray workloads.
│       ├── main.tf                      # Terraform entrypoint stitching together all cloud resources needed for this stack.
│       ├── outputs.tf                   # Outputs all relevant EKS, S3, Ray, and Supabase endpoints.
│       ├── ray.tf                       # Provisions Ray head + worker nodegroups with tagging and observability enabled.
│       ├── s3.tf                        # Creates versioned S3 buckets for raw docs, embeddings, and parsed chunks.
│       └── variables.tf                 # Declares env vars (e.g., cluster_name, region, GPU flag) used throughout terraform modules.
|
├── scripts/
│   ├── benchmark_pipeline.py            # End-to-end benchmark of pipeline performance (latency, throughput); uses Prometheus + logs.
│   ├── kubeval.sh                       # Shell script to validate all k8s YAML manifests against openapi schema via kubeval.
│   ├── kubescore.sh                     # Runs kubescore on manifests to detect anti-patterns (e.g., no resource limits).
│   ├── manifest_lint.sh                 # Validates YAML/Helm (now Carvel) templates using kube-linter and yamllint.
│   ├── seed_data.py                     # One-time data seeder for initial metadata/embedding DB population; logs batch status.
│   └── stress_test.py                   # Load tester to push high volume through RAG/inference; tracked by Grafana + Langfuse.
|
├── tests/
│   ├── __init__.py                      # Makes tests a discoverable Python module for pytest discovery.
│   ├── conftest.py                      # Shared fixtures for pytest (e.g. mock clients, temp S3 paths, Ray mocks).
│   ├── test_api.py                      # Unit tests and integration checks for orchestrator API (Ray Serve endpoints).
│   ├── test_embedding.py                # Tests embedding workers, batch encoding, model loading correctness.
│   ├── test_ingestion.py                # Tests parsing/upload logic across ingestion module (mock file types + edge cases).
│   ├── test_rag.py                      # Verifies retriever + generator correctness across RAG pipeline module.
│   └── test_vector.py                   # Tests for Qdrant vector upsert/query logic, schema conformity.
|
├── models/                              # Store embedding models, LLMs, and other large files here
│   ├── sentence_transformers/           # SentenceTransformers models for embedding
│   └── llms/                            # LLMs for generation (e.g., mistral, llama, etc)
|   
└── temp/                                # Temporary files for local dev, not committed to git
```