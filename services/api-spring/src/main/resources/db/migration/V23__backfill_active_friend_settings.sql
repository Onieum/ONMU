insert into friend_settings (friendship_id, user_id, friend_user_id, display_alias, memo, hidden, is_favorite)
select
  f.id,
  pair.user_id,
  pair.friend_user_id,
  null,
  null,
  false,
  false
from friendships f
cross join lateral (
  values
    (f.user_low_id, f.user_high_id),
    (f.user_high_id, f.user_low_id)
) as pair(user_id, friend_user_id)
where f.status = 'active'
  and f.deleted_at is null
  and not exists (
    select 1
    from friend_settings fs
    where fs.friendship_id = f.id
      and fs.user_id = pair.user_id
  );
