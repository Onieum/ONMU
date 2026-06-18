update users
set nickname = nullif(trim(nickname), '')
where nickname is not null;

update users
set nickname = nullif(trim(display_name), '')
where (nickname is null or nickname = '')
  and display_name is not null
  and trim(display_name) <> '';

update users
set nickname = '사용자'
where nickname is null or trim(nickname) = '';

alter table users alter column nickname set not null;
alter table users drop column if exists display_name;

update auth_identities
set provider_profile = jsonb_set(
  provider_profile - 'displayName',
  '{providerProfileName}',
  provider_profile -> 'displayName',
  true
)
where provider_profile ? 'displayName';

alter table group_members
  rename column display_name_override to name_override;
