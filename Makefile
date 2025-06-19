.PHONY: install login force-pull pull push lc lc-status delete-lc rebase-continue tree clean s3 iam

SHELL := /bin/bash

login:
	bash scripts/login.sh

force-pull:
	git fetch --prune                       # Sync and clean remote refs
	git stash push -m "auto-stash" || true  # Stash local changes if any
	git pull --rebase --autostash           # Pull with rebase, auto-apply stashed changes
	git stash drop || true                  # Drop auto-stash if it was created
	git status                              # Show current state

pull:
	@if [ -d .git/rebase-merge ]; then \
		echo "[!] Rebase already in progress. Run 'make rebase-continue' or 'make rebase-abort'"; \
		exit 1; \
	fi
	git fetch origin
	git rebase origin/main

install:
	chmod +x scripts/install.sh
	bash scripts/install.sh
	[ -d .venv ] || python3 -m venv .venv
	. .venv/bin/activate && \
	pip install --upgrade pip && \
	pip install -r requirements.txt
	echo ". .venv/bin/activate" >> ~/.bashrc

push:
	git add .
	git commit -m "update"
	git push
	

lc:
	chmod +x base_infra/local_cluster.sh && sudo bash base_infra/local_cluster.sh

lc-status:
	k3s kubectl get nodes

delete-lc:
	chmod +x base_infra/delete_dev_cluster.sh && sudo bash base_infra/delete_dev_cluster.sh

rebase-continue:
	git add .
	git rebase --continue

tree:
	\tree -a --prune -I '.git|.vagrant|__pycache__|.pulumi|.mypy_cache|.pytest_cache|.venv|.vscode|storage' --dirsfirst -L 5

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} + && find . -type f -name '*.py[co]' -delete

s3:
	python3 base_infra/s3.py

iam:
	@echo "[INFO] Running Pulumi up for IAM in base_infra/01_iam/"; \
	[ -f .env ] || { echo "[ERROR] .env not found. Run 'make s3' first.'"; exit 1; }; \
	set -a; source .env; set +a; \
	if [ -z "$$PULUMI_BACKEND_URL" ] || [ -z "$$PULUMI_CONFIG_PASSPHRASE" ]; then \
		echo "[ERROR] .env must export PULUMI_BACKEND_URL and PULUMI_CONFIG_PASSPHRASE"; \
		exit 1; \
	fi; \
	cd base_infra/01_iam && \
	echo "[STEP] Logging in to Pulumi backend and ensuring 'prod' stack..." && \
	PULUMI_CONFIG_PASSPHRASE=$$PULUMI_CONFIG_PASSPHRASE pulumi login "$$PULUMI_BACKEND_URL" && \
	pulumi stack ls | grep -q '^prod' || pulumi stack init prod && \
	echo "[STEP] Cancelling any stale lock..." && \
	pulumi cancel --yes >/dev/null 2>&1 || true && \
	echo "[STEP] Validating IAM config..." && \
	python3 __main__.py && \
	echo "[STEP] Previewing changes..." && \
	PULUMI_CONFIG_PASSPHRASE=$$PULUMI_CONFIG_PASSPHRASE pulumi preview && \
	echo "[STEP] Applying changes..." && \
	PULUMI_CONFIG_PASSPHRASE=$$PULUMI_CONFIG_PASSPHRASE pulumi up --yes --non-interactive && \
	cd "$$(git rev-parse --show-toplevel)"
