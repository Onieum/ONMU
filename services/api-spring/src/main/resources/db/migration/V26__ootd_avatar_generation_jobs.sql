create table if not exists ootd_avatar_generation_jobs (
  id uuid primary key default gen_random_uuid(),
  public_id varchar(80) not null unique,
  record_id uuid not null references records(id),
  user_id uuid not null references users(id),
  input_type varchar(40) not null,
  outfit_photo_media_id uuid references record_media(id),
  outfit_description text,
  status varchar(40) not null,
  result_storage_key text,
  result_public_url text,
  error_code varchar(120),
  retryable boolean not null default false,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ootd_avatar_generation_jobs_record
  on ootd_avatar_generation_jobs(record_id);

create index if not exists idx_ootd_avatar_generation_jobs_user
  on ootd_avatar_generation_jobs(user_id);

create index if not exists idx_ootd_avatar_generation_jobs_status
  on ootd_avatar_generation_jobs(status);
