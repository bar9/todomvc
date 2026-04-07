DIOXUS_DIR := dioxus

.PHONY: dev build migrate check clean setup css test-api help

setup:
	cd $(DIOXUS_DIR) && npm install

css:
	cd $(DIOXUS_DIR) && npx @tailwindcss/cli -i ./input.css -o ./assets/main.css

dev: css
	@echo "Frontend: http://localhost:8080  |  TrailBase: http://localhost:4000"
	cd $(DIOXUS_DIR) && npx @tailwindcss/cli -i ./input.css -o ./assets/main.css --watch &
	cd $(DIOXUS_DIR) && dx serve

build: css
	cd $(DIOXUS_DIR) && dx build --release

migrate:
	./scripts/migrate.sh

check: css
	cd $(DIOXUS_DIR) && cargo check
	cd $(DIOXUS_DIR) && cargo clippy -- -D warnings

clean:
	cd $(DIOXUS_DIR) && cargo clean

reset-db:
	rm -f traildepot/data/main.db traildepot/data/main.db-wal traildepot/data/main.db-shm
	./scripts/migrate.sh

test-api:
	./scripts/test-api.sh

help:
	@echo "make setup    Install npm dependencies (Tailwind, daisyUI)"
	@echo "make css      Compile Tailwind CSS"
	@echo "make dev      Start Tailwind watcher + Dioxus dev server"
	@echo "make build    Production build (CSS + WASM)"
	@echo "make migrate  Apply TrailBase migrations (starts TrailBase)"
	@echo "make check    Compile check + clippy"
	@echo "make clean    Clean build artifacts"
	@echo "make reset-db Reset DB and re-apply migrations"
	@echo "make test-api Run Hurl API integration tests"
