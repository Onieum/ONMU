alter table user_devices add column if not exists push_provider varchar(30);
alter table user_devices add column if not exists push_token text;
alter table user_devices add column if not exists push_token_hash text;
alter table user_devices add column if not exists push_token_last4 varchar(8);
alter table user_devices add column if not exists push_token_updated_at timestamptz;
alter table user_devices add column if not exists push_token_disabled_at timestamptz;

create index if not exists idx_user_devices_user_push_status
  on user_devices(user_id, push_provider, status);

create index if not exists idx_user_devices_push_token_hash
  on user_devices(push_provider, push_token_hash)
  where push_token_hash is not null;
