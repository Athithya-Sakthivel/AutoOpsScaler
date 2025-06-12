.PHONY: login force-pull push pull full-bootstrap lc delete-lc lc-status clean
login:
	bash scripts/login.sh

full-force:
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
	chmod +x base_infra/cluster_bootstrap.sh && sudo bash base_infra/cluster_bootstrap.sh dev

delete-lc:
	sudo /usr/local/bin/k3s-uninstall.sh

pull:
	@if [ -d .git/rebase-merge ]; then \
		echo "[!] Rebase already in progress. Run 'make rebase-continue' or 'make rebase-abort'"; \
		exit 1; \
	fi
	git fetch origin
	git rebase origin/main

rebase-continue:
	git add .
	git rebase --continue

lc-status:
	k3s kubectl get nodes

tree:
	\tree -a --prune -I '.git|.vagrant|__pycache__|.pulumi|.mypy_cache|.pytest_cache|.venv|.vscode' --dirsfirst -L 5

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} + && find . -type f -name '*.py[co]' -delete

