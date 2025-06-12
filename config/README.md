# 🔧 AutoOpsScaler Configuration System

This directory acts as the **declarative source-of-truth** for infrastructure, workloads, and observability generation. All infrastructure is defined via version-controlled schemas, layered by environment, and rendered into Pulumi + Kubernetes manifests.

---

## 📁 Directory Structure

```

config/
├── base_config.yaml           # Global defaults applied to all environments
├── dev_config.yaml            # Overrides for the dev environment
├── prod_config.yaml           # Overrides for the prod environment
├── secrets_template.py        # Blueprint for required secrets (no real values)
├── infra_schema/              # Typed, validated schema definitions (via Pydantic)
├── environments/              # Python overrides per environment
└── generate_infra/            # CLI and codegen to render Pulumi/K8s from config

```

---

## ⚙️ Layered Config Rules

1. ✅ **Base Config** (`base_config.yaml`)  
   - Default values that apply across environments.
   - Should be safe, sane defaults that make dev bootstrap easy.

2. ✅ **Environment Overrides** (`dev_config.yaml`, `prod_config.yaml`)  
   - Explicitly override fields defined in base.
   - Should only override what's absolutely necessary (e.g., node sizes, IAM trust domains).

3. ✅ **Python Overrides** (`environments/dev.py`)  
   - Logic-based dynamic overrides (e.g., conditional Karpenter zones, computed resource limits).
   - These are fully type-checked via Pydantic and merged during render time.

---

## 🧠 Schema Hierarchy

All config files map to strict Pydantic schemas under `infra_schema/`:

```

infra_schema/
├── base_types.py       # Shared enums like instance class, arch, region
├── vpc.py              # VPC, subnet, NAT config
├── eks.py              # EKS cluster and nodegroups
├── karpenter.py        # CPU/GPU/Spot provisioners
├── observability.py    # Prometheus/Grafana config
└── root_schema.py      # Merged InfraConfig that glues everything together

````

Usage:

```python
from config.infra_schema import InfraConfig
cfg = InfraConfig(**merged_dict)
````

---

## 🔐 Secrets Handling

* All secrets must be injected via environment variables or Vault.
* The file `secrets_template.py` defines required secret *keys* per env, with `"REQUIRED"` placeholders.
* Actual secrets are never stored in Git.

Usage pattern in CI or runtime:

```python
from config.secrets_template import SECRETS_TEMPLATE

for key in SECRETS_TEMPLATE["dev"]:
    assert key in os.environ, f"Missing secret: {key}"
```

---

## 🚀 Generating Infra

All infrastructure is rendered using the CLI module:

```bash
# Validate + render infrastructure
python -m config.generate_infra.cli validate --env dev
python -m config.generate_infra.cli render --env prod
```

This pipeline performs:

* ✅ Deep merging of `base + env` YAML + Python
* ✅ Strict schema validation (`InfraConfig`)
* ✅ Pulumi+K8s manifest generation into `/base_infra/`

---

## 👩‍💻 Extend This System

To add new infra components:

1. Add a schema file under `infra_schema/`
2. Add its sub-schema to `root_schema.py`
3. Add any env-specific overrides in `environments/dev.py` or `prod.py`
4. Add rendering logic inside `generate_infra/renderer.py`

---

