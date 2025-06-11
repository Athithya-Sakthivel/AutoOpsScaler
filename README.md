
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

````sh
AutoOpsScaler/ 
├── .github⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# GitHub configuration directory.  
│   └── workflows⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# GitHub Actions workflows directory.  
│       ├── build_and_push.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Build & push Docker images.  
│       ├── ci.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# CI workflow configuration (ruff, typecheck, pytest).  
│       ├── data_pipeline.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# CI workflow for data preprocessing pipeline.  
│       ├── inference_pipeline.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# CI workflow for inference pipeline.  
│       └── sync_argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Trigger ArgoCD sync via REST API  
|
├── config⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Configuration files and templates.  
│   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Explains environment-specific config layering for CI/CD.  
│   ├── base_config.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Centralized config shared across environments (defaults).  
│   ├── dev_config.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Development config overriding base, with local endpoints.  
│   ├── prod_config.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Production config overrides (secure endpoints, resources).  
│   └── secrets_template.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Template for CI/CD or vault-managed secrets. 
| 
├── base_infra⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Base infrastructure code (Dev/Prod environments).  
│   ├── dev⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Development environment infrastructure.  
│   │   ├── observability⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Observability stack for dev environment.  
│   │   │   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Modules for metrics and tracing in dev environment.  
│   │   │   │   ├── metrics.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Prometheus metrics definitions for development monitoring.  
│   │   │   │   └── tracing.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tracing instrumentation for development.  
│   │   │   ├── scripts⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validation and linting scripts for manifests.  
│   │   │   │   ├── kubescore.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Runs kubescore on manifests to detect anti-patterns (e.g., no resource limits).  
│   │   │   │   ├── kubeval.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validates k8s YAML manifests against schema via kubeval.  
│   │   │   │   └── manifest_lint.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validates YAML/Helm templates using kube-linter and yamllint.  
│   │   │   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Docker container for development monitoring (Prometheus/Grafana).  
│   │   │   └── ray_dev_monitoring.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Ray monitoring configuration for the dev cluster.  
│   │   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Instructions for setting up the dev environment.  
│   │   └── k3s-dev-start.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Script to start a local k3s cluster for development.  
│   ├── prod⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Production environment configurations.  
│   │   ├── observability⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Observability stack for production environment.  
│   │   │   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Modules for metrics and tracing in production.  
│   │   │   │   ├── metrics.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Prometheus metrics definitions for production monitoring.  
│   │   │   │   └── tracing.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tracing instrumentation for production.  
│   │   │   ├── scripts⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validation and linting scripts for manifests.  
│   │   │   │   ├── kubescore.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Runs kubescore on manifests to detect anti-patterns (e.g., no resource limits).  
│   │   │   │   ├── kubeval.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validates k8s YAML manifests against schema via kubeval.  
│   │   │   │   └── manifest_lint.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validates YAML/Helm templates using kube-linter and yamllint.  
│   │   │   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Docker container for production monitoring (Prometheus/Grafana).  
│   │   │   └── ray_prod_monitoring.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Ray monitoring configuration for the production cluster.  
│   │   ├── pulumi⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi infrastructure code for production (EKS, IAM, etc).  
│   │   │   ├── eks.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi script to provision EKS cluster.  
│   │   │   ├── iam.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi script to configure IAM roles.  
│   │   │   ├── karpenter.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi script to configure Karpenter autoscaling.  
│   │   │   ├── outputs.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi outputs (exported resource information).  
│   │   │   └── vpc.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pulumi script to configure VPC and networking.  
│   │   └── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Instructions for setting up the production environment.  
│   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Overview of infrastructure configuration.  
│   └── s3_boto3.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Python script to initialize S3 buckets/schema using boto3.
|  
├── storage⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Local storage for data, models, and backups.  
│   ├── data⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Data files and backups.
│   │   └── raw⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Raw data files.
│   │   ├── processed⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Processed data files.  
│   │   │   ├── chunked⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Chunked data files.  
│   │   │   └── parsed⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Parsed data files.  
│   │   ├── db_backups⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Database backup files.  
│   │   │   ├── qdrant_backups⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Qdrant database backups.  
│   │   │   └── supabase_backups⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Supabase database backups.  
│   │   ├── observability⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Observability data.  
│   ├── llms⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# LLM and embedding model storage.  
│   │   ├── mistral⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Mistral model files.  
│   │   └── sentence_transformers⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# SentenceTransformers model files.   
|
├── extract_load⠀⠀⠀⠀⠀⠀⠀⠀ # All raw files are stored in s3://<bucket>/data/raw/ to return the original S3 URLs during RAG inference.
│   ├── generated⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated manifests for extract&load pipeline.  
│   │   ├── EL_rayjob_v1.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for extract&load (v1).  
│   │   └── EL_rayjob_v2.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for extract&load (v2).  
│   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Extract/load modules.  
│   │   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Docs for extract-load flow (loaders, scrapers).  
│   │   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Declares extract_load as Python module.  
│   │   ├── file_watcher.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Watches S3/local folders for new input files.  
│   │   ├── llamaindex_loader.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Loads docs via LlamaIndex connectors and dedudplication via xxhash 
│   │   ├── main.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Orchestrates extract pipeline via Ray Workflows.  
│   │   ├── s3_uploader.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Uploads raw docs to S3 (boto3).  
│   │   └── scraper.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Web scraper (Scrapy+Playwright) with error tracing and dedudplication via xxhash
│   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Container spec for extract-load (no GPU).  
│   ├── app-extract-load.argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Argo CD manifest for extract-load pipeline.  
│   └── dynamic_RayJob_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates RayJob manifests dynamically for extract/load.  
|
├── data_preprocessing⠀ # Any file type in s3://<bucket>/storage/data/raw/ will be autodetected via unstructured.io and be parsed
│   ├── generated⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated manifests for data preprocessing.  
│   │   ├── dp_rayjob_v1.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for data preprocessing (v1).  
│   │   └── dp_rayjob_v2.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for data preprocessing (v2).  
│   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Data preprocessing modules.  
│   │   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Docs covering parsing strategies and filtering heuristics.  
│   │   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Declares data_preprocessing as a Python module.  
│   │   ├── chunker_llamaindex.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Splits text into chunks (LlamaIndex); emits latency metrics.  
│   │   ├── doc_parser.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Parses documents (unstructured.io); adds tracing on performance.  
│   │   ├── filters.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Filters out junk/boilerplate; records chunk retention ratio.  
│   │   ├── format_normalizer.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Cleans text/metadata; emits chunk count and clean ratio metrics.  
│   │   ├── html_parser.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Parses HTML (trafilatura); logs malformed doc issues.  
│   │   └── main.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Orchestrates full preprocessing pipeline via Ray Workflows.  
│   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Container for document preprocessing (OCR, chunking, dedup).  
│   ├── app-data-preprocess.argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Argo CD manifest for data preprocessing pipeline.  
│   └── dynamic_RayJob_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates RayJob manifests dynamically for this pipeline.  
|
├── embedding⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Embedding pipeline code.  
│   ├── generated⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated manifests for embedding pipeline.  
│   │   ├── em_rayjob_v1.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for embedding pipeline (v1).  
│   │   └── em_rayjob_v2.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated RayJob manifest for embedding pipeline (v2).  
│   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Embedding pipeline modules.  
│   │   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Marks modules as a Python package.  
│   │   ├── batch_embed.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Orchestrates batch embedding via Ray Workflows (with metrics).  
│   │   ├── main.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Entry-point for embedding tasks; initializes observability.  
│   │   ├── model_loader.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Loads SentenceTransformer models; instrumented for tracing.  
│   │   └── worker.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Embeds text in Ray tasks; emits performance spans.  
│   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Builds container for embedding pipeline using Ray.  
│   ├── app-embedding.argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Argo CD manifest for embedding pipeline.  
│   └── dynamic_RayJob_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates RayJob manifests dynamically for embedding.  
|
├── vector_db⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Qdrant vector database pipeline.  
│   ├── generated⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated Qdrant deployment manifests.  
│   │   ├── qdrant_StatefulSet_pvc_svc_v1.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated Qdrant StatefulSet/PVC/Service manifest (v1).  
│   │   └── qdrant_StatefulSet_pvc_svc_v2.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated Qdrant StatefulSet/PVC/Service manifest (v2).  
│   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Qdrant pipeline modules.  
│   │   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Marks modules as a Python package.  
│   │   ├── embed_to_qdrant.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Pushes embeddings to Qdrant; emits latency metrics.  
│   │   ├── main.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Entry-point for Qdrant interaction; includes metrics/tracing.  
│   │   ├── qdrant_client.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Qdrant client wrapper; monitors search latency.  
│   │   ├── query_qdrant.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Similarity search query logic.  
│   │   └── schema.json⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Qdrant collection schema.  
│   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Builds container for Qdrant ingestion pipeline.  
│   ├── app-vector.argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Argo CD manifest for Qdrant ingestion.  
│   └── dynamic_StatefulSet_pvc_svc_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates StatefulSet/PVC/Service manifests for Qdrant.  
|
├── postgres⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Supabase/Postgres metadata service code.  
│   ├── generated⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated manifests for Supabase service.  
│   │   ├── supabase_StatefulSet_pvc_svc_v1.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated Supabase StatefulSet/PVC/Service manifest (v1).  
│   │   └── supabase_StatefulSet_pvc_svc_v2.yml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generated Supabase StatefulSet/PVC/Service manifest (v2). 
|   | 
│   ├── modules⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Supabase service modules.  
│   │   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# (module marker)  
│   │   ├── insert_metadata.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Inserts document metadata into Supabase.  
│   │   ├── query_metadata.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Fetches metadata from Supabase.  
│   │   └── supabase_client.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Supabase client logic for DB operations.  
|   |
│   ├── Dockerfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Container for Supabase metadata operations.  
│   ├── app-supabase.argocd.yaml⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Argo CD manifest for Supabase service.  
│   └── dynamic_StatefulSet_pvc_svc_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates StatefulSet/PVC/Service manifests for Supabase.  

├── fine_tuning⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Fine-tuning pipeline code.  
│   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Documentation for fine-tuning procedures.  
│   ├── dynamic_RayJob_generator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Generates RayJob manifests dynamically for fine-tuning.  
│   └── fine_tune.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Script to fine-tune a model via  Qlora/DeepSpeed and saved in s3://<bucket>/storage/data/raw/
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
|   |
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
|   |   |     
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
├── scripts⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Project scripts.  
│   ├── benchmark_pipeline.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# End-to-end pipeline benchmark (latency, throughput).  
│   ├── bootstrap.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Initial setup and bootstrap script for environment.  
│   ├── login.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Script to authenticate to required services or registries.  
│   ├── manifest_lint.sh⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Validates YAML/Helm templates using kube-linter and yamllint.  
│   ├── seed_data.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# One-time data seeder for metadata/embedding population.  
│   └── stress_test.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Load tester to push high volume through the pipeline.  
|
├── tests⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Test suite.  
│   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Makes tests a Python module.  
│   ├── conftest.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Shared pytest fixtures (mock clients, Ray).  
│   ├── test_api.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Unit tests for API endpoints.  
│   ├── test_embedding.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tests for embedding workers and model loading.  
│   ├── test_ingestion.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tests for ingestion (parsing and upload logic).  
│   ├── test_rag.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tests for RAG retriever and generator.  
│   └── test_vector.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Tests for Qdrant vector upsert/query logic.
|  
├── utils⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Utility functions and helpers.  
│   ├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Documentation for utility functions.  
│   ├── __init__.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Marks the utils package as a Python module.  
│   ├── config_loader.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Loads layered config from `config/` directory.  
│   ├── deduplicator.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Uses xxhash to deduplicate documents.  
│   ├── logger.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Centralized structured logging utility.  
│   └── s3_utils.py⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# S3 upload/download helper (boto3).  
|
├── .dockerignore⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Docker exclusion file to prevent building unnecessary files.  
├── .gitignore⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Git exclusion file to prevent committing irrelevant files.  
├── Makefile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# LowOps commands for development (cluster setup, deployment, etc).  
├── README.md⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# High-level documentation describing architecture and usage.  
├── Vagrantfile⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Vagrant configuration for local development environment.  
└── requirements.txt⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀# Python dependencies (Ray, FastAPI, etc).  



````





