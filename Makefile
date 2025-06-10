.PHONY: login pull push bootstrap

login:
	chmod +x ./scripts/login.sh
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

bootstrap:
	chmod +x scripts/bootstrap.sh && bash scripts/bootstrap.sh
	python3 -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip
	. .venv/bin/activate && pip install -r requirements.txt

