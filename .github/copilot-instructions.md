# ONMU Repository Guidelines

## Source Of Truth

- Product and release architecture: `docs/architecture/release-architecture.md`
- Platform setup: `docs/development/platform-setup.md`
- Git workflow: `docs/development/git-workflow.md`
- Jira/GitHub/Notion automation: `docs/integrations/jira-github-notion.md`
- Shared Windows backend server: `docs/operations/windows-backend-server.md`

## Product Context

ONMU is a Flutter-first mobile product. The web app is only for brand and project introduction. Core workflows must be designed for the Flutter app and backend APIs.

## Architecture Direction

- Design for release-level architecture from day one.
- Use AKS, managed PostgreSQL/PostGIS, Redis, object storage, event bus, observability, and CI/CD as the target platform.
- Use Docker Compose only for local dependency parity.
- Build the first vertical prototype across profile, meetup/realtime, place/external API, and memory/character domains.

## Repository Workflow

- Default integration branch is `dev`.
- Do not push directly to `dev` or `main`.
- Create a Jira issue first, then create a branch.
- Branch format: `type/short-description`.
- Allowed branch types: `feat`, `fix`, `hotfix`, `chore`, `refactor`, `docs`, `set`, `test`.
- Open a pull request for every merge.

## Commit And PR Conventions

- Commit format: `type(scope): short description`.
- Allowed commit types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `ci`, `build`, `perf`.
- Suggested scopes: `mobile`, `brand-web`, `api`, `realtime`, `worker`, `place`, `memory`, `profile`, `infra`, `ci`, `docs`.
- PR title format: `[Type] Korean summary`.
- PR body must include Summary, Changes, Test, and Related sections.

## Security Rules

- Never commit secrets, API keys, signing keys, Firebase files, or real credentials.
- Commit `.env.example`, never `.env`.
- Store production credentials in Azure Key Vault or platform secrets.
- Do not commit real user data, exported photos, CSV files, DB dumps, or location datasets.

## Flutter Rules

- Use flavors: `dev`, `staging`, `prod`.
- Keep domain state outside widgets.
- Prefer OpenAPI-generated clients when backend contracts exist.
- Realtime flows need reconnect and room-state resync behavior.
