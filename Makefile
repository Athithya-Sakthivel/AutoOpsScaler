.PHONY: login pull-force push bootstrap lc delete-lc pull tree lc-status clean rebase-continue

# ---- GitOps ----

login:
	bash scripts/login.sh

pull-force:
	git fetch --prune
	git stash push -m "auto-stash" || true
	git pull --rebase --autostash
	git stash drop || true
	git status

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

rebase-continue:
	git add .
	git rebase --continue

rebase-abort:
	git rebase --abort

# ---- Bootstrapping Infra ----

full-bootstrap:
	chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh

lc:
	chmod +x base_infra/cluster_bootstrap.sh && ./base_infra/cluster_bootstrap.sh dev

delete-lc:
	chmod +x base_infra/delete_dev_cluster.sh && ./base_infra/delete_dev_cluster.sh

lc-status:
	@echo "Active kubeconfig: $$(kubectl config current-context)"
	kubectl --context=minikube get nodes

# ---- Dev Env Maintenance ----

tree:
	tree -a --prune -I '.git|.vagrant|__pycache__|.pulumi|.mypy_cache|.pytest_cache|.venv|.vscode' --dirsfirst -L 5

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} + && find . -type f -name '*.py[co]' -delete


.PHONY: validate test lint

validate: lint test infra-check

lint:
	ruff . --output-format=github

test:
	pytest -v tests/

infra-check:
	python -m config.generate_infra.main --env dev
	bash base_infra/regen_all.sh
	git diff --exit-code
