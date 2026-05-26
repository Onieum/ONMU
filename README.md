# ONMU

ONMU is a Flutter-first meetup curation and lifelog platform. The product helps a group create a meetup, decide where to meet, share live arrival status, and turn the meetup into a memory card with photos and character elements.

## Product Direction

- **Mobile first:** Flutter native app for iOS and Android.
- **Release-level architecture:** AKS, managed data services, observability, CI/CD, and security are part of the baseline plan.
- **Agile delivery:** start with a thin vertical prototype that connects all product domains, then deepen each domain sprint by sprint.
- **Web scope:** brand and project introduction only. Core product workflows stay in the Flutter app.

## Repository Map

```text
apps/
  mobile-flutter/        # Flutter app
  brand-web/             # Static brand/project intro web
services/
  api/                   # Main domain API
  realtime-gateway/      # WebSocket room state and fan-out
  workers/               # Recommendation, place risk, route, memory, notification workers
infra/
  compose/               # Local dependency stack
  k8s/                   # Kubernetes base and overlays
  terraform/azure/       # Azure infrastructure
packages/
  api-contracts/         # OpenAPI and generated contract artifacts
  shared-schemas/        # Shared schema definitions
docs/
  architecture/          # Release architecture and domain boundaries
  development/           # Setup and workflow guides
  integrations/          # Jira, GitHub, Notion automation
  operations/            # Release, observability, runbooks
```

## First Prototype

The first prototype should connect all four team parts in one thin journey:

```text
profile preferences
  -> meetup room
  -> realtime participation
  -> place candidate search/scoring
  -> place decision
  -> photo or memory card
  -> character/sticker result
```

## Workflow

- Default integration branch: `dev`
- Stable release branch: `main`
- Work branch format: `type/SCRUM-123-short-description`
- Commit format: `type(scope): SCRUM-123 short description`
- All merges go through pull requests.
- Jira is the source of delivery planning; GitHub is the source of code review and CI.

See:

- `docs/architecture/release-architecture.md`
- `docs/development/git-workflow.md`
- `docs/development/platform-setup.md`
- `docs/integrations/jira-github-notion.md`
- `docs/operations/windows-backend-server.md`
