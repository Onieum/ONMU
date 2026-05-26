# ONMU Release Architecture

## Principle

ONMU is designed for a real service release from day one. The team will still deliver incrementally, but the target architecture is production-shaped: Flutter app, API, realtime gateway, workers, managed data services, AKS, observability, and CI/CD.

## Product Surfaces

| Surface | Role |
| --- | --- |
| Flutter mobile app | Core product for iOS and Android |
| Brand web | Static brand/project introduction |
| Backend API | Domain transactions and contracts |
| Realtime gateway | WebSocket room state and fan-out |
| Workers | Recommendation, place risk, route/departure, photo memory, notification |

## First Connected Flow

```text
profile preferences
  -> meetup room
  -> realtime participant state
  -> place search/scoring
  -> candidate decision
  -> photo or memory card
  -> character/sticker result
```

## Target Platform

```text
Flutter App
  -> API Gateway / Ingress
  -> Main API
  -> Realtime Gateway
  -> PostgreSQL + PostGIS
  -> Redis
  -> Search service
  -> Event bus
  -> Worker services
  -> Object Storage + CDN
  -> Observability
```

## Domain Boundaries

| Domain | Responsibility |
| --- | --- |
| Identity | users, auth providers, device tokens |
| Profile | preference tags, availability, saved places |
| Social | friendship and invitations |
| Meetup | meetups, participants, schedule candidates |
| Place | places, candidates, external API cache, risks |
| Decision | votes, selected place/schedule, decision logs |
| Realtime | presence and participant live status |
| Recommendation | scoring runs, candidate explanations |
| Memory | memory cards, photos, stickers |
| Notification | push requests, delivery results |
| Audit | outbox events, audit logs |

## Delivery Stages

1. Platform foundation.
2. Integrated vertical prototype.
3. Realtime and collaboration hardening.
4. Place/external API hardening.
5. Memory/photo/character hardening.
6. Release hardening.
