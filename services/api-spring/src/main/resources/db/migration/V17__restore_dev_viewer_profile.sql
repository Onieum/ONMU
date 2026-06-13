update users
set
  display_name = '나',
  nickname = '나',
  public_id = 'user-me',
  profile_image_url = 'dev/avatars/user-me.png'
where id = '00000000-0000-0000-0000-000000000001';

update auth_identities
set raw_profile = jsonb_set(
  coalesce(raw_profile, '{}'::jsonb),
  '{displayName}',
  to_jsonb('나'::text),
  true
)
where user_id = '00000000-0000-0000-0000-000000000001';
