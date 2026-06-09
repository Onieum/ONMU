-- 데이터사전의 친구 관계 결정사항에 맞춰 V4/V5 schema를 보정한다.
-- V4/V5는 이미 dev DB에 적용됐으므로 기존 migration을 수정하지 않고 V6에서 정렬한다.

alter table friendships
  add column if not exists source varchar(30) not null default 'user_code';

alter table friendships
  add column if not exists accepted_request_id uuid;

alter table friendships
  add column if not exists deleted_at timestamptz;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'friendships_source_check') then
    alter table friendships
      add constraint friendships_source_check
      check (source in ('user_code', 'contact', 'kakao', 'group_invite'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'friendships_status_check') then
    alter table friendships
      add constraint friendships_status_check
      check (status in ('active', 'deleted'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'fk_friendships_accepted_request') then
    alter table friendships
      add constraint fk_friendships_accepted_request
      foreign key (accepted_request_id) references friend_requests(id);
  end if;
end $$;

alter table friend_settings
  add column if not exists friendship_id uuid;

alter table friend_settings
  add column if not exists display_alias text;

alter table friend_settings
  add column if not exists memo text;

alter table friend_settings
  add column if not exists hidden boolean;

update friend_settings
set display_alias = alias
where display_alias is null
  and alias is not null;

update friend_settings fs
set friendship_id = f.id
from friendships f
where fs.friendship_id is null
  and f.user_low_id = least(fs.user_id, fs.friend_user_id)
  and f.user_high_id = greatest(fs.user_id, fs.friend_user_id);

insert into friend_settings (friendship_id, user_id, friend_user_id, display_alias, memo, hidden)
select
  f.id,
  pair.user_id,
  pair.friend_user_id,
  null,
  null,
  false
from friendships f
cross join lateral (
  values
    (f.user_low_id, f.user_high_id),
    (f.user_high_id, f.user_low_id)
) as pair(user_id, friend_user_id)
where not exists (
  select 1
  from friend_settings fs
  where fs.friendship_id = f.id
    and fs.user_id = pair.user_id
);

update friend_settings
set hidden = false
where hidden is null;

alter table friend_settings
  alter column hidden set default false,
  alter column hidden set not null,
  alter column friendship_id set not null;

alter table friend_settings
  drop constraint if exists friend_settings_user_id_friend_user_id_key;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fk_friend_settings_friendship') then
    alter table friend_settings
      add constraint fk_friend_settings_friendship
      foreign key (friendship_id) references friendships(id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'friend_settings_friendship_user_unique') then
    alter table friend_settings
      add constraint friend_settings_friendship_user_unique
      unique (friendship_id, user_id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'friend_settings_distinct_users_check') then
    alter table friend_settings
      add constraint friend_settings_distinct_users_check
      check (user_id <> friend_user_id);
  end if;
end $$;

alter table friend_settings
  drop column if exists alias,
  drop column if exists favorite,
  drop column if exists muted,
  drop column if exists visibility_scope;

create index if not exists idx_friendships_source_created_at
  on friendships(source, created_at);

create index if not exists idx_friendships_accepted_request_id
  on friendships(accepted_request_id);

create index if not exists idx_friend_settings_user_id
  on friend_settings(user_id);

create index if not exists idx_friend_settings_friend_user_id
  on friend_settings(friend_user_id);
