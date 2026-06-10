create table if not exists place_candidate_hearts (
  id uuid primary key default gen_random_uuid(),
  place_candidate_id uuid not null references place_candidates(id),
  user_id uuid not null references users(id),
  created_at timestamptz not null default now(),
  unique (place_candidate_id, user_id)
);

create index if not exists idx_place_candidate_hearts_candidate_created_at
  on place_candidate_hearts(place_candidate_id, created_at);

create index if not exists idx_place_candidate_hearts_user_created_at
  on place_candidate_hearts(user_id, created_at);
