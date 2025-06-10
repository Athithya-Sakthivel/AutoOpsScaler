.PHONY: login pull push bootstrap

login:
	chmod +x scripts/login.sh
	./scripts/login.sh

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
	chmod +x scripts/bootstrap.sh && sudo bash scripts/bootstrap.sh
	PIP_ROOT_USER_ACTION=ignore pip install -r requirements.txt

lc:
	chmod +x scripts/k3s-dev-start.sh && sudo bash scripts/k3s-dev-start.sh

lc-status:
	sudo k3s kubectl get nodes
	