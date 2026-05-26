# Release Checklist

## Mobile

- [ ] Flutter `dev`, `staging`, `prod` flavors configured
- [ ] API base URLs configured per flavor
- [ ] Push notification token registration tested
- [ ] Location/photo/notification permissions tested on real devices
- [ ] Firebase App Distribution or TestFlight build published
- [ ] Crash reporting enabled

## Backend

- [ ] `/healthz` and `/readyz`
- [ ] Database migration Job tested
- [ ] API contract tests passed
- [ ] Realtime reconnect/resync tested
- [ ] Worker retries are idempotent

## Infrastructure

- [ ] ACR image build and push
- [ ] AKS staging deploy
- [ ] Managed PostgreSQL/PostGIS connection
- [ ] Redis connection
- [ ] Object storage upload and signed URL flow
- [ ] Observability dashboard
- [ ] Alert rules

## Project Management

- [ ] Jira epics created
- [ ] Sprint 0 and Sprint 1 backlog ready
- [ ] GitHub repository linked to Jira
- [ ] Notion project hub linked to Jira synced database
