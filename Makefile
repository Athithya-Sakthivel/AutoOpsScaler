.PHONY: login pull push bootstrap setup lc lc-status

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

setup:
	chmod +x scripts/bootstrap.sh
	./scripts/bootstrap.sh
	pip install -r requirements.txt

lc:
	bash scripts/k3s-dev-start.sh

lc-status:
	k3s kubectl get nodes
