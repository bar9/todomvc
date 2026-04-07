# TodoMVC — Dioxus + TrailBase

A full-stack TodoMVC built with **zero JavaScript in application code**. Rust compiles to WebAssembly for the frontend, and the entire backend is defined declaratively through SQL migrations and a 10-line config file.

## Background

This repository is a **stack blueprint** distilled from an actual B2B workflow platform being built. Rather than a toy demo, it captures the architecture, tooling, and patterns used in production — stripped down to the essentials so you can evaluate the stack and get productive fast.

The key idea: **migrations are the backend**. There are no API handlers, no controllers, no ORM. You define your schema in SQL, declare which tables to expose in a config file, and TrailBase generates a full REST API with filtering, pagination, and row-level access control. The entire application is ~320 lines of Rust and 10 lines of backend configuration.

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend framework | [Dioxus 0.7](https://dioxuslabs.com/) (Rust &rarr; WebAssembly) |
| Styling | [Tailwind CSS v4](https://tailwindcss.com/) + [daisyUI v5](https://daisyui.com/) |
| Backend | [TrailBase](https://trailbase.io/) (single binary, SQLite, auto-generated REST API) |
| API tests | [Hurl](https://hurl.dev/) |
| Build | Make, Cargo, npm |

## Architecture

```
┌──────────────────────────────────────┐
│           Browser (WASM)             │
│                                      │
│  Dioxus 0.7        Tailwind/daisyUI  │
│  Rust components    Utility CSS      │
│  Signals + RSX      Autumn theme     │
│  gloo HTTP client                    │
└──────────────┬───────────────────────┘
               │ REST
               ▼
┌──────────────────────────────────────┐
│         TrailBase (:4000)            │
│                                      │
│  config.textproto    SQLite          │
│  Record API          UUID v7 PKs     │
│  ACL rules           Auto-timestamps │
└──────────────────────────────────────┘
```

## Getting Started

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| **Rust** (stable) | Compile frontend to WASM | [rustup.rs](https://rustup.rs/) |
| **Dioxus CLI** (`dx`) | Dev server & build | `cargo install dioxus-cli` |
| **Node.js + npm** | Tailwind CSS compilation | [nodejs.org](https://nodejs.org/) |
| **TrailBase** (`trail`) | Backend server | [trailbase.io/getting-started](https://trailbase.io/getting-started/) |
| **Hurl** *(optional)* | API integration tests | [hurl.dev](https://hurl.dev/) |

### 1. Clone and install dependencies

```bash
git clone <repo-url> && cd todomvc
make setup        # installs Tailwind + daisyUI via npm
```

### 2. Start the backend

```bash
make migrate      # starts TrailBase on :4000, applies SQL migrations
```

This creates the SQLite database, applies all migrations (schema, seed data), and keeps TrailBase running. The API is immediately available at `http://localhost:4000`.

### 3. Start the frontend dev server

In a new terminal:

```bash
make dev          # starts Tailwind watcher + Dioxus dev server on :8080
```

### 4. Open the app

Browse to **http://localhost:8080** — you should see the TodoMVC UI. Add, complete, and delete todos. The data persists in SQLite via the TrailBase REST API.

## Project Structure

```
.
├── Makefile                        # Build targets (setup, dev, build, migrate, test)
├── dioxus/
│   ├── Cargo.toml                  # Rust dependencies (dioxus, serde, gloo)
│   ├── Dioxus.toml                 # Dioxus project config
│   ├── package.json                # NPM deps (tailwindcss, daisyui)
│   ├── input.css                   # Tailwind entry point (5 lines)
│   ├── assets/main.css             # Compiled CSS output
│   └── src/
│       ├── main.rs                 # App component — UI, state, handlers
│       ├── api.rs                  # HTTP layer (fetch, post, patch, delete)
│       └── types.rs                # Data models (Todo, NewTodo, UpdateTodo)
├── traildepot/
│   ├── config.textproto            # Backend config — exposes tables as REST APIs
│   └── migrations/main/
│       ├── U1000000001__todos.sql          # Schema: todos table + update trigger
│       ├── U1000000002__add_admin_user.sql # Seed: admin user
│       └── U1000000003__seed_todos.sql.tpl # Seed: test data (200k rows)
├── scripts/
│   ├── migrate.sh                  # Start TrailBase + apply migrations
│   └── test-api.sh                 # Run Hurl integration tests
└── tests/api/                      # Hurl test files (smoke, CRUD, error cases)
```

## Make Targets

| Target | Description |
|--------|-------------|
| `make setup` | Install npm dependencies (Tailwind, daisyUI) |
| `make dev` | Start Tailwind watcher + Dioxus dev server |
| `make build` | Production build (CSS + WASM) |
| `make migrate` | Apply TrailBase migrations and start server |
| `make check` | Compile check + clippy |
| `make clean` | Clean build artifacts |
| `make reset-db` | Delete database and re-apply migrations |
| `make test-api` | Run Hurl API integration tests |
| `make help` | Show all targets |

## How It Works

The backend is entirely declarative. Two files define the full API:

**`traildepot/config.textproto`** — expose the `todos` table as a public REST API:

```textproto
record_apis: [{
  name: "todos"
  table_name: "todos"
  acl_world: [CREATE, READ, UPDATE, DELETE]
}]
```

**`traildepot/migrations/main/U1000000001__todos.sql`** — define the schema:

```sql
CREATE TABLE IF NOT EXISTS todos (
  id        BLOB PRIMARY KEY NOT NULL CHECK(is_uuid_v7(id)) DEFAULT (uuid_v7()),
  title     TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  created   INTEGER NOT NULL DEFAULT (UNIXEPOCH()),
  updated   INTEGER NOT NULL DEFAULT (UNIXEPOCH())
) STRICT;
```

TrailBase auto-generates these endpoints:

- `POST   /api/records/v1/todos` — create
- `GET    /api/records/v1/todos` — list (with cursor pagination)
- `GET    /api/records/v1/todos/:id` — read
- `PATCH  /api/records/v1/todos/:id` — update
- `DELETE /api/records/v1/todos/:id` — delete

## Running Tests

```bash
make test-api     # resets DB, starts TrailBase, runs Hurl tests
```

Tests cover smoke checks, full CRUD operations, and error cases. Results are output as JUnit XML in `test-results/`.
