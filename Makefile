.PHONY: login pull push full-bootstrap setup lc lc-status all help regen regen-dev regen-prod lint build observe-dev observe-prod clean

login:
	bash scripts/login.sh

pull:
	git fetch --prune                    # Sync and clean remote refs
	git stash push -m "auto-stash" || true  # Stash local changes if any
	git pull --rebase --autostash        # Pull with rebase, auto-apply stashed changes
	git stash drop || true               # Drop auto-stash if it was created
	git status                           # Show current state

push:
	git add .
	git commit -m "update"
	git push
	
full-bootstrap:
	chmod +x scripts/bootstrap.sh
	./scripts/bootstrap.sh
	pip install -r requirements.txt --upgrade

lc:
	bash scripts/k3s-dev-start.sh

lc-status:
	k3s kubectl get nodes

tree:
	\tree -a --prune -I '.git|.vagrant|__pycache__|.pulumi|.mypy_cache|.pytest_cache|.venv|.vscode' --dirsfirst -L 5



# -------------------------------------------------------------------
# AutoOpsScaler Makefile — Idempotent, local-first CI/CD runner
# -------------------------------------------------------------------



# === Default: show all available commands ===
all: help
help:  ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

help:
	@echo ""
	@echo "Available targets:"
	@echo "  regen         Generate all infra artifacts for both dev and prod"
	@echo "  regen-dev     Generate infra artifacts for dev only"
	@echo "  regen-prod    Generate infra artifacts for prod only"
	@echo "  lint          Run kube-linter against base_infra/"
	@echo "  build         Build all Docker images"
	@echo "  observe-dev   Launch dev observability stack locally"
	@echo "  observe-prod  Launch prod observability container locally"
	@echo "  clean         Remove generated files"
	@echo ""

# === Regeneration Targets ===
regen:
	@echo "🔁 Generating full infra (dev + prod)..."
	@python -m config.generate_infra.cli --env dev
	@python -m config.generate_infra.cli --env prod

regen-dev:
	@echo "🔁 Generating infra for DEV only..."
	@python -m config.generate_infra.cli --env dev

regen-prod:
	@echo "🔁 Generating infra for PROD only..."
	@python -m config.generate_infra.cli --env prod

# === Linting (manifests only) ===
lint:
	@echo "🔍 Running kube-linter..."
	@./base_infra/observability/kube-linter.sh

# === Docker builds ===
build:
	@echo "🐳 Building all images..."
	@docker build -t autoopsscaler/pulumi-runner:latest ./base_infra/pulumi
	@docker build -t autoopsscaler/observability-dev:latest -f ./base_infra/observability/Dockerfile.dev .
	@docker build -t autoopsscaler/observability-prod:latest -f ./base_infra/observability/Dockerfile.prod .

# === Observability test runs ===
observe-dev:
	@echo "📊 Running dev observability stack locally..."
	@docker run --rm -p 3000:3000 -p 9090:9090 autoopsscaler/observability-dev:latest

observe-prod:
	@echo "📊 Running prod observability stack locally..."
	@docker run --rm -p 3000:3000 -p 9090:9090 autoopsscaler/observability-prod:latest

# === Cleanup ===
clean:
	@echo "🧹 Cleaning up generated artifacts..."
	@rm -rf base_infra/observability/dashboards
	@rm -f base_infra/observability/scrape_configs.yaml
	@rm -f base_infra/pulumi/pulumi_config.json
