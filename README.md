![CI/CD](https://github.com/sinanozel/headless-joplin/actions/workflows/ci.yaml/badge.svg?branch=main)
![Docker Hub](https://img.shields.io/docker/v/sinanozel/headless-joplin?label=Docker%20Hub)

# headless-joplin

A Docker image that runs the [Joplin](https://joplinapp.org) terminal app headless and exposes the **Data API** (Web Clipper service) on port `41184`, syncing over WebDAV. Everything runs through Docker — no local Node or Python needed.

The image tag is the Joplin version it contains (`headless-joplin:3.7.1`). The version is pinned in one place, `ARG JOPLIN_VERSION` in the [Dockerfile](Dockerfile).

See [docs/architecture.md](docs/architecture.md) for how it works.

## Configuration

Everything is set through environment variables — full reference, including `JOPLIN_E2EE_PASSWORD`, in [docs/configuration.md](docs/configuration.md).

| Variable | Default |
|---|---|
| `JOPLIN_WEBDAV_SYNC_URL` | unset (sync disabled); bare host → `https://` |
| `JOPLIN_WEBDAV_SYNC_USERNAME` / `_PASSWORD` | `''` |
| `JOPLIN_WEBDAV_SYNC_PATH` | `/` |
| `JOPLIN_WEBDAV_SYNC_INTERVAL_MINUTES` | `5` (`0` = off) |
| `JOPLIN_WEBDAV_SYNC_ON_START` | `true` |
| `JOPLIN_API_TOKEN` | required |
| `JOPLIN_API_PORT` / `JOPLIN_INTERNAL_PORT` | `41184` / `41185` |
| `JOPLIN_PROFILE_DIR` | `/data/profile` |
| `JOPLIN_E2EE_PASSWORD` | unset |
| `PUID`, `PGID`, `TZ`, `JOPLIN_LOG_LEVEL` | `1000`, `1000`, `UTC`, `info` |

## Development

The only requirement is **Docker**. Also available as VS Code tasks (`.vscode/tasks.json`).

```bash
# Tests (health check: the API answers /ping)
docker compose -f tests/docker-compose.yaml up --build --abort-on-container-exit --exit-code-from test

# Lint / reformat (tests/ only for now)
docker compose -f lint/docker-compose.yaml up --build --abort-on-container-exit
docker compose -f reformat/docker-compose.yaml up --build --abort-on-container-exit

# Validate docs
docker compose -f docs-validate/docker-compose.yaml up --build --abort-on-container-exit
```

## CI/CD

[.github/workflows/ci.yaml](.github/workflows/ci.yaml), based on the MCP server template:

- **test** and **validate-docs** run on every push.
- **reformat** and **lint** are wired up but skipped (`if: false`) for now.
- **publish** (main only, when the Dockerfile/`src/`/README changed): pushes to Docker Hub as `<user>/headless-joplin:<joplin-version>` plus `:latest`, tags git `v<joplin-version>`, creates a GitHub Release. If the Joplin version hasn't changed since the last tag, it publishes `<joplin-version>-dev<timestamp>` instead.

Required GitHub secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.

## Project structure

```
.
├── Dockerfile               # node + socat + pinned joplin
├── src/entrypoint.sh        # env-driven config, socat forwarder, sync loop
├── mkdocs.yml, docs/        # documentation
├── tests/                   # health-check test (docker compose)
├── lint/, reformat/         # ruff / black+isort+docformatter containers
├── docs-validate/           # mkdocs build --strict container
├── scripts/semver_compare.py
└── .github/workflows/ci.yaml
```
