-- Auth/User/Profile additions after the core data-dictionary migrations.
-- V4 already creates refresh_tokens and user_codes, so this migration only adds
-- the columns needed by the authentication implementation.

create extension if not exists pgcrypto;

alter table users add column if not exists pixel_character jsonb not null default '{}'::jsonb;
alter table users add column if not exists preference_profile jsonb not null default '{}'::jsonb;
alter table users add column if not exists onboarding_status text not null default 'PENDING';

alter table auth_identities add column if not exists public_id text;
alter table auth_identities add column if not exists updated_at timestamptz not null default now();
alter table auth_identities add column if not exists deleted_at timestamptz;

update auth_identities
set public_id = 'aid_' || replace(id::text, '-', '')
where public_id is null;

alter table auth_identities alter column public_id set not null;
create unique index if not exists ux_auth_identities_public_id on auth_identities(public_id);
create index if not exists idx_auth_identities_deleted_at on auth_identities(deleted_at);

alter table refresh_tokens add column if not exists public_id text;
alter table refresh_tokens add column if not exists token_family_id uuid;
alter table refresh_tokens add column if not exists previous_token_hash text;
alter table refresh_tokens add column if not exists created_by_ip text;
alter table refresh_tokens add column if not exists created_by_user_agent text;
alter table refresh_tokens add column if not exists updated_at timestamptz not null default now();

update refresh_tokens
set public_id = 'rt_' || replace(id::text, '-', '')
where public_id is null;

update refresh_tokens
set token_family_id = id
where token_family_id is null;

alter table refresh_tokens alter column public_id set not null;
alter table refresh_tokens alter column token_family_id set not null;

create unique index if not exists ux_refresh_tokens_public_id on refresh_tokens(public_id);
create index if not exists idx_refresh_tokens_user_active on refresh_tokens(user_id, expires_at)
  where revoked_at is null;
create index if not exists idx_refresh_tokens_family on refresh_tokens(token_family_id, issued_at);

insert into user_preferences (user_id, preference_type, preference_key, preference_value, source)
select id, 'profile', 'preference_profile', '{}'::jsonb, 'auth_profile'
from users
on conflict (user_id, preference_type, preference_key) do nothing;
