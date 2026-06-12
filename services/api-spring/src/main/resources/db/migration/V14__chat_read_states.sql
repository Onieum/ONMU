create table if not exists chat_read_states (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  last_read_event_id uuid references chat_activity_events(id) on delete set null,
  last_read_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create index if not exists idx_chat_read_states_user_group on chat_read_states(user_id, group_id);
