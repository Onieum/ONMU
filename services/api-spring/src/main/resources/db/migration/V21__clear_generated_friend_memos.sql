update friend_settings fs
set memo = null,
    updated_at = now()
from users friend_user
left join lateral (
  select code
  from user_codes
  where user_id = friend_user.id
    and status = 'active'
  order by created_at desc
  limit 1
) active_code on true
where fs.friend_user_id = friend_user.id
  and fs.memo is not null
  and (
    fs.memo = friend_user.public_id
    or fs.memo = active_code.code
    or fs.memo ~ '^[0-9]{8,12}$'
  );
