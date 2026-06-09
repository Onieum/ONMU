-- SCRUM-39 data dictionary based core app schema expansion.
-- Spring Boot Flyway owns only the public core app schema.
-- Do not create worker_ai, analytics/lakehouse, or Prometheus/Grafana metric tables here.

create extension if not exists pgcrypto;

alter table users add column if not exists public_id text;
alter table users add column if not exists nickname text;
alter table users add column if not exists profile_image_url text;
alter table users add column if not exists status_message text;
alter table users add column if not exists phone_hash text;
alter table users add column if not exists email text;
alter table users add column if not exists default_locale varchar(10) not null default 'ko-KR';
alter table users add column if not exists time_zone text not null default 'Asia/Seoul';
alter table users add column if not exists status varchar(30) not null default 'active';
alter table users add column if not exists last_login_at timestamptz;
alter table users add column if not exists deleted_at timestamptz;

update users
set public_id = 'usr_' || replace(id::text, '-', '')
where public_id is null;

alter table users alter column public_id set default ('usr_' || replace(gen_random_uuid()::text, '-', ''));
alter table users alter column public_id set not null;
create unique index if not exists ux_users_public_id on users(public_id);
create unique index if not exists ux_users_phone_hash on users(phone_hash) where phone_hash is not null;
create index if not exists idx_users_status_created_at on users(status, created_at);

alter table auth_identities add column if not exists provider_email text;
alter table auth_identities add column if not exists provider_profile jsonb not null default '{}'::jsonb;
alter table auth_identities add column if not exists linked_at timestamptz not null default now();
alter table auth_identities add column if not exists last_verified_at timestamptz;
create index if not exists idx_auth_identities_user_id on auth_identities(user_id);

alter table groups add column if not exists description text;
alter table groups add column if not exists status varchar(30) not null default 'active';
alter table groups add column if not exists visibility varchar(30) not null default 'members';
alter table groups add column if not exists updated_by_user_id uuid references users(id);
create index if not exists idx_groups_owner_user_id on groups(owner_user_id);
create index if not exists idx_groups_status_created_at on groups(status, created_at);

alter table plans add column if not exists description text;
alter table plans add column if not exists ends_at timestamptz;
alter table plans add column if not exists time_zone text not null default 'Asia/Seoul';
alter table plans add column if not exists location_note text;
alter table plans add column if not exists updated_by_user_id uuid references users(id);
create index if not exists idx_plans_group_id_starts_at on plans(group_id, starts_at);
create index if not exists idx_plans_status_starts_at on plans(status, starts_at);

alter table place_candidates add column if not exists external_place_id uuid;
alter table place_candidates add column if not exists suggested_by_user_id uuid references users(id);
alter table place_candidates add column if not exists status varchar(30) not null default 'candidate';
alter table place_candidates add column if not exists note text;
create index if not exists idx_place_candidates_group_plan_status on place_candidates(group_id, plan_id, status);

alter table schedule_places add column if not exists external_place_id uuid;
alter table schedule_places add column if not exists scheduled_by_user_id uuid references users(id);
alter table schedule_places add column if not exists ends_at timestamptz;
alter table schedule_places add column if not exists note text;

alter table votes add column if not exists closes_at timestamptz;
alter table votes add column if not exists created_by_user_id uuid references users(id);
alter table votes add column if not exists visibility varchar(30) not null default 'group';
create index if not exists idx_votes_group_status_created_at on votes(group_id, status, created_at);

alter table settlement_drafts add column if not exists created_by_user_id uuid references users(id);
alter table settlement_drafts add column if not exists status varchar(30) not null default 'draft';
alter table settlement_drafts add column if not exists created_at timestamptz not null default now();

alter table settlements add column if not exists created_by_user_id uuid references users(id);
alter table settlements add column if not exists status varchar(30) not null default 'created';
create index if not exists idx_settlements_group_plan_status on settlements(group_id, plan_id, status);

alter table records add column if not exists public_id text;
alter table records add column if not exists summary text;
alter table records add column if not exists mood_tags jsonb not null default '[]'::jsonb;
alter table records add column if not exists updated_at timestamptz not null default now();
alter table records add column if not exists deleted_at timestamptz;
update records
set public_id = 'rec_' || replace(id::text, '-', '')
where public_id is null;
alter table records alter column public_id set default ('rec_' || replace(gen_random_uuid()::text, '-', ''));
alter table records alter column public_id set not null;
create unique index if not exists ux_records_public_id on records(public_id);
create index if not exists idx_records_group_created_at on records(group_id, created_at);
create index if not exists idx_records_author_created_at on records(author_user_id, created_at);

alter table consent_privacy_settings add column if not exists marketing_opt_in boolean not null default false;
alter table consent_privacy_settings add column if not exists contact_sync_opt_in boolean not null default false;
alter table consent_privacy_settings add column if not exists retention_policy_key text not null default 'default-dev';
create unique index if not exists ux_consent_privacy_settings_user_id on consent_privacy_settings(user_id);

create table if not exists refresh_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  token_hash text not null,
  device_id uuid,
  device_label text,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  rotated_at timestamptz,
  revoked_at timestamptz,
  revoked_reason text,
  created_at timestamptz not null default now(),
  unique (token_hash)
);

create table if not exists user_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  code varchar(20) not null,
  code_format varchar(20) not null,
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  disabled_at timestamptz,
  unique (code)
);

create table if not exists user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  device_fingerprint_hash text,
  platform varchar(20) not null default 'unknown',
  app_version text,
  os_version text,
  device_label text,
  last_ip_hash text,
  last_user_agent text,
  trusted boolean not null default false,
  status varchar(20) not null default 'active',
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists login_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  auth_identity_id uuid references auth_identities(id),
  device_id uuid references user_devices(id),
  provider varchar(30) not null,
  attempt_type varchar(30) not null,
  status varchar(20) not null,
  failure_reason text,
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  preference_type varchar(40) not null,
  preference_key text not null,
  preference_value jsonb not null default '{}'::jsonb,
  source varchar(30) not null default 'profile',
  confidence numeric(5,4),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, preference_type, preference_key)
);

create table if not exists user_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_user_id uuid not null references users(id),
  blocked_user_id uuid not null references users(id),
  reason text,
  source varchar(30) not null default 'settings',
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists ux_user_blocks_active_pair
  on user_blocks(blocker_user_id, blocked_user_id)
  where deleted_at is null;

create table if not exists friendships (
  id uuid primary key default gen_random_uuid(),
  user_low_id uuid not null references users(id),
  user_high_id uuid not null references users(id),
  status varchar(20) not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_low_id, user_high_id),
  check (user_low_id < user_high_id)
);

create table if not exists friend_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  friend_user_id uuid not null references users(id),
  alias text,
  favorite boolean not null default false,
  muted boolean not null default false,
  visibility_scope varchar(30) not null default 'friends',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, friend_user_id)
);

create table if not exists friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_user_id uuid not null references users(id),
  target_user_id uuid not null references users(id),
  request_channel varchar(30) not null default 'user_code',
  user_code_id uuid references user_codes(id),
  status varchar(20) not null default 'pending',
  message text,
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

create table if not exists group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  user_id uuid not null references users(id),
  role varchar(30) not null default 'member',
  display_name_override text,
  status varchar(30) not null default 'active',
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create table if not exists group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id),
  inviter_user_id uuid references users(id),
  target_user_id uuid references users(id),
  invite_channel varchar(30) not null default 'friend',
  invite_code text,
  status varchar(30) not null default 'pending',
  expires_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists external_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id),
  plan_id uuid references plans(id),
  inviter_user_id uuid references users(id),
  invite_channel varchar(30) not null,
  external_target_ref text,
  invite_payload jsonb not null default '{}'::jsonb,
  status varchar(30) not null default 'created',
  expires_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists plan_participants (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id),
  user_id uuid not null references users(id),
  status varchar(30) not null default 'invited',
  response varchar(30),
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (plan_id, user_id)
);

create table if not exists external_places (
  id uuid primary key default gen_random_uuid(),
  public_id text not null default ('place_' || replace(gen_random_uuid()::text, '-', '')),
  provider varchar(30) not null,
  provider_place_id text not null,
  name text not null,
  category text,
  address text,
  road_address text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  phone_label text,
  homepage_url text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (public_id),
  unique (provider, provider_place_id)
);

create table if not exists place_search_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  group_id uuid references groups(id),
  plan_id uuid references plans(id),
  query text not null,
  bounds jsonb,
  filters jsonb,
  provider varchar(30) not null,
  result_count integer not null default 0,
  latency_ms integer,
  created_at timestamptz not null default now()
);

alter table place_candidates
  add constraint fk_place_candidates_external_place
  foreign key (external_place_id) references external_places(id) not valid;

alter table schedule_places
  add constraint fk_schedule_places_external_place
  foreign key (external_place_id) references external_places(id) not valid;

create table if not exists vote_options (
  id uuid primary key default gen_random_uuid(),
  vote_id uuid not null references votes(id),
  public_id text not null default ('vopt_' || replace(gen_random_uuid()::text, '-', '')),
  label text not null,
  target_type varchar(30),
  target_id text,
  sort_order integer not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (public_id),
  unique (vote_id, sort_order)
);

create table if not exists vote_responses (
  id uuid primary key default gen_random_uuid(),
  vote_id uuid not null references votes(id),
  vote_option_id uuid references vote_options(id),
  user_id uuid not null references users(id),
  response_value jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (vote_id, vote_option_id, user_id)
);

create table if not exists settlement_items (
  id uuid primary key default gen_random_uuid(),
  settlement_draft_id uuid references settlement_drafts(id),
  settlement_id uuid references settlements(id),
  public_id text not null default ('stli_' || replace(gen_random_uuid()::text, '-', '')),
  title text not null,
  amount_cents bigint not null,
  currency varchar(10) not null default 'KRW',
  split_type varchar(30) not null default 'equal',
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (public_id)
);

create table if not exists settlement_item_targets (
  id uuid primary key default gen_random_uuid(),
  settlement_item_id uuid not null references settlement_items(id),
  user_id uuid not null references users(id),
  amount_cents bigint,
  status varchar(30) not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (settlement_item_id, user_id)
);

create table if not exists settlement_transfers (
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null references settlements(id),
  from_user_id uuid not null references users(id),
  to_user_id uuid not null references users(id),
  amount_cents bigint not null,
  currency varchar(10) not null default 'KRW',
  status varchar(30) not null default 'pending',
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists settlement_confirmations (
  id uuid primary key default gen_random_uuid(),
  settlement_transfer_id uuid not null references settlement_transfers(id),
  user_id uuid not null references users(id),
  confirmation_type varchar(30) not null,
  status varchar(30) not null default 'confirmed',
  confirmed_at timestamptz not null default now(),
  memo text,
  unique (settlement_transfer_id, user_id, confirmation_type)
);

create table if not exists record_media (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references records(id),
  media_type varchar(30) not null,
  storage_key text not null,
  public_url text,
  width integer,
  height integer,
  duration_seconds numeric(10,3),
  sort_order integer not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists record_tags (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references records(id),
  tag_type varchar(30) not null default 'user',
  tag_value text not null,
  created_at timestamptz not null default now(),
  unique (record_id, tag_type, tag_value)
);

create table if not exists ootd_features (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references records(id),
  user_id uuid references users(id),
  feature_source varchar(30) not null default 'user',
  features jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists share_cards (
  id uuid primary key default gen_random_uuid(),
  record_id uuid references records(id),
  plan_id uuid references plans(id),
  group_id uuid references groups(id),
  public_id text not null default ('share_' || replace(gen_random_uuid()::text, '-', '')),
  card_type varchar(30) not null default 'image_export',
  storage_key text,
  share_url text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  unique (public_id)
);

create table if not exists chat_activity_events (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id),
  plan_id uuid references plans(id),
  actor_user_id uuid references users(id),
  event_type varchar(60) not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  group_id uuid references groups(id),
  plan_id uuid references plans(id),
  notification_type varchar(60) not null,
  title text not null,
  body text,
  payload jsonb not null default '{}'::jsonb,
  status varchar(30) not null default 'queued',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  channel varchar(30) not null,
  notification_type varchar(60) not null,
  enabled boolean not null default true,
  quiet_hours jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, channel, notification_type)
);

create table if not exists notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references notifications(id),
  channel varchar(30) not null,
  provider varchar(30),
  status varchar(30) not null default 'pending',
  provider_message_id text,
  error_message text,
  attempted_at timestamptz not null default now(),
  delivered_at timestamptz
);

create table if not exists privacy_policy_snapshots (
  id uuid primary key default gen_random_uuid(),
  policy_key text not null,
  version text not null,
  title text not null,
  content_hash text not null,
  effective_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (policy_key, version)
);

create table if not exists user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  policy_snapshot_id uuid not null references privacy_policy_snapshots(id),
  consent_type varchar(50) not null,
  consented boolean not null,
  source varchar(30) not null default 'app',
  created_at timestamptz not null default now()
);

create table if not exists data_subject_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  request_type varchar(30) not null,
  status varchar(30) not null default 'received',
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  payload jsonb not null default '{}'::jsonb
);

create table if not exists data_retention_policies (
  id uuid primary key default gen_random_uuid(),
  policy_key text not null,
  target_table text not null,
  retention_days integer not null,
  action varchar(30) not null default 'delete',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (policy_key, target_table)
);

create table if not exists outbox_publish_attempts (
  id uuid primary key default gen_random_uuid(),
  outbox_event_id uuid not null references outbox_events(id),
  attempt_no integer not null,
  status varchar(30) not null,
  error_message text,
  attempted_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (outbox_event_id, attempt_no)
);

create table if not exists worker_dead_letters (
  id uuid primary key default gen_random_uuid(),
  source_event_id uuid references outbox_events(id),
  worker_name text not null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  error_message text,
  status varchar(30) not null default 'open',
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  idempotency_key text not null,
  request_hash text not null,
  response_status integer,
  response_body jsonb,
  status varchar(30) not null default 'in_progress',
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (idempotency_key)
);

create table if not exists api_access_logs (
  id uuid primary key default gen_random_uuid(),
  request_id text,
  user_id uuid references users(id),
  method varchar(10) not null,
  path text not null,
  status_code integer,
  duration_ms integer,
  client_marker text,
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references users(id),
  action varchar(80) not null,
  target_type varchar(60) not null,
  target_id text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  event_type varchar(80) not null,
  severity varchar(20) not null default 'info',
  ip_hash text,
  user_agent text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists rate_limit_counters (
  id uuid primary key default gen_random_uuid(),
  bucket_key text not null,
  subject_key text not null,
  window_start timestamptz not null,
  window_seconds integer not null,
  request_count integer not null default 0,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now(),
  unique (bucket_key, subject_key, window_start)
);

create table if not exists feature_flags (
  id uuid primary key default gen_random_uuid(),
  flag_key text not null,
  enabled boolean not null default false,
  rollout_rule jsonb not null default '{}'::jsonb,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (flag_key)
);

create table if not exists admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references users(id),
  action varchar(80) not null,
  target_type varchar(60) not null,
  target_id text,
  reason text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'users_status_check') then
    alter table users add constraint users_status_check check (status in ('active', 'disabled', 'deleted'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'records_visibility_check') then
    alter table records add constraint records_visibility_check check (visibility in ('private', 'participants', 'group'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'groups_status_check') then
    alter table groups add constraint groups_status_check check (status in ('active', 'archived', 'deleted'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_items_amount_nonnegative_check') then
    alter table settlement_items add constraint settlement_items_amount_nonnegative_check check (amount_cents >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_transfers_amount_nonnegative_check') then
    alter table settlement_transfers add constraint settlement_transfers_amount_nonnegative_check check (amount_cents >= 0);
  end if;
end $$;

create index if not exists idx_refresh_tokens_user_id on refresh_tokens(user_id);
create index if not exists idx_user_codes_user_status on user_codes(user_id, status);
create index if not exists idx_user_devices_user_status on user_devices(user_id, status);
create index if not exists idx_login_attempts_user_created_at on login_attempts(user_id, created_at);
create index if not exists idx_friend_requests_target_status_created_at on friend_requests(target_user_id, status, created_at);
create index if not exists idx_group_members_user_id on group_members(user_id);
create index if not exists idx_group_invites_group_status on group_invites(group_id, status);
create index if not exists idx_plan_participants_user_id on plan_participants(user_id);
create index if not exists idx_external_places_category on external_places(category);
create index if not exists idx_place_search_logs_plan_created_at on place_search_logs(plan_id, created_at);
create index if not exists idx_place_search_logs_user_created_at on place_search_logs(user_id, created_at);
create index if not exists idx_vote_options_vote_id on vote_options(vote_id);
create index if not exists idx_vote_responses_vote_id on vote_responses(vote_id);
create index if not exists idx_settlement_items_draft_id on settlement_items(settlement_draft_id);
create index if not exists idx_settlement_item_targets_user_id on settlement_item_targets(user_id);
create index if not exists idx_settlement_transfers_settlement_id on settlement_transfers(settlement_id);
create index if not exists idx_record_media_record_id on record_media(record_id);
create index if not exists idx_share_cards_record_id on share_cards(record_id);
create index if not exists idx_chat_activity_events_group_created_at on chat_activity_events(group_id, created_at);
create index if not exists idx_notifications_user_created_at on notifications(user_id, created_at);
create index if not exists idx_notifications_user_status_created_at on notifications(user_id, status, created_at);
create index if not exists idx_user_consents_user_created_at on user_consents(user_id, created_at);
create index if not exists idx_data_subject_requests_user_status on data_subject_requests(user_id, status);
create index if not exists idx_outbox_publish_attempts_event_id on outbox_publish_attempts(outbox_event_id);
create index if not exists idx_worker_dead_letters_status_created_at on worker_dead_letters(status, created_at);
create index if not exists idx_api_access_logs_created_at on api_access_logs(created_at);
create index if not exists idx_audit_logs_target_created_at on audit_logs(target_type, target_id, created_at);
create index if not exists idx_security_events_user_created_at on security_events(user_id, created_at);
create index if not exists idx_rate_limit_counters_bucket_window on rate_limit_counters(bucket_key, window_start);
