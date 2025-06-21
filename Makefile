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

rebase-continue:
	git add .
	git rebase --continue

pull:
	@if [ -d .git/rebase-merge ]; then \
		echo "[!] Rebase already in progress. Run 'make rebase-continue' or 'make rebase-abort'"; \
		exit 1; \
	fi
	git fetch origin
	git rebase origin/main

push:
	git add .
	git commit -m "update"
	git push


install:
	chmod +x scripts/install.sh
	bash scripts/install.sh
	[ -d .venv ] || python3 -m venv .venv
	. .venv/bin/activate && \
	pip install --upgrade pip && \
	pip install -r requirements.txt

tree:
	\tree -a --prune -I '.git|.vagrant|__pycache__|.pulumi|.mypy_cache|.pytest_cache|.venv|.vscode|storage' --dirsfirst -L 5

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} + && find . -type f -name '*.py[co]' -delete
	

lc:
	chmod +x infra/staging/lc.sh && bash infra/staging/lc.sh

delete-lc:
	chmod +x infra/staging/delete-lc.sh && bash infra/staging/delete-lc.sh

lc-status:
	chmod +x infra/staging/lc-status.sh && bash infra/staging/lc-status.sh
	
status:
	k3d cluster list | grep autoopsscaler-staging
	kubectl get nodes --no-headers | grep -v NotReady
	kubectl get pods -A --field-selector=status.phase!=Running
	









terraform-backend-s3:
	python3 infra/terraform_backend_s3.py

