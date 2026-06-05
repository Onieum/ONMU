-- Spring Boot Flyway owns ONMU core schema.
-- This scaffold is intentionally small and secret-free.
-- FastAPI Alembic must not modify these core domain tables.

create extension if not exists pgcrypto;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists auth_identities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  provider text not null,
  provider_subject text not null,
  created_at timestamptz not null default now(),
  unique (provider, provider_subject)
);

create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_user_id uuid references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists plans (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  title text not null,
  starts_at timestamptz,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists place_candidates (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  plan_id uuid not null references plans(id),
  name text not null,
  category text,
  address text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists schedule_places (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  plan_id uuid not null references plans(id),
  place_candidate_id uuid references place_candidates(id),
  name text not null,
  starts_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists votes (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  target_type text,
  target_id uuid,
  vote_type text not null,
  title text not null,
  status text not null default 'open',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists settlement_drafts (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  plan_id uuid not null references plans(id),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  plan_id uuid not null references plans(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists records (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id),
  plan_id uuid references plans(id),
  author_user_id uuid references users(id),
  title text not null,
  visibility text not null default 'participants',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists consent_privacy_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  analytics_opt_in boolean not null default false,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists outbox_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  aggregate_type text not null,
  aggregate_id uuid,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  published_at timestamptz,
  locked_at timestamptz,
  retry_count integer not null default 0,
  last_error text
);

create index if not exists idx_outbox_events_status_created_at on outbox_events(status, created_at);
create index if not exists idx_plans_group_id on plans(group_id);
create index if not exists idx_votes_group_id on votes(group_id);
