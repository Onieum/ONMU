-- Deterministic dev seed data for Spring Main API smoke tests.
-- Values are synthetic and contain no real user data or credentials.

alter table groups add column if not exists public_id text;
alter table plans add column if not exists public_id text;
alter table votes add column if not exists public_id text;
alter table votes alter column target_id type text using target_id::text;

update groups set public_id = id::text where public_id is null;
update plans set public_id = id::text where public_id is null;
update votes set public_id = id::text where public_id is null;

create unique index if not exists ux_groups_public_id on groups(public_id);
create unique index if not exists ux_plans_public_id on plans(public_id);
create unique index if not exists ux_votes_public_id on votes(public_id);

alter table groups alter column public_id set not null;
alter table plans alter column public_id set not null;
alter table votes alter column public_id set not null;

insert into users (id, display_name)
values ('00000000-0000-0000-0000-000000000001', 'ONMU Dev User')
on conflict (id) do nothing;

insert into auth_identities (id, user_id, provider, provider_subject)
values (
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000001',
  'NAVER',
  'dev-seed-user'
)
on conflict (provider, provider_subject) do nothing;

insert into groups (id, public_id, name, owner_user_id)
values (
  '00000000-0000-0000-0000-000000000201',
  '1',
  'ONMU 개발 모임',
  '00000000-0000-0000-0000-000000000001'
)
on conflict (public_id) do nothing;

insert into plans (id, public_id, group_id, title, starts_at, status)
values (
  '00000000-0000-0000-0000-000000000301',
  '101',
  '00000000-0000-0000-0000-000000000201',
  'ONMU API 계약 검증',
  '2026-06-12T10:00:00+09:00',
  'confirmed'
)
on conflict (public_id) do nothing;

insert into votes (id, public_id, group_id, target_type, target_id, vote_type, title, status, payload)
values (
  '00000000-0000-0000-0000-000000000401',
  '501',
  '00000000-0000-0000-0000-000000000201',
  'PLAN',
  '101',
  'PLACE',
  '장소 후보 선호 투표',
  'open',
  '{"options":["카페","식당"]}'::jsonb
)
on conflict (public_id) do nothing;
