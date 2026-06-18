update friend_settings fs
set hidden = false,
    updated_at = now()
from friendships f
where fs.friendship_id = f.id
  and f.status = 'active'
  and f.deleted_at is null
  and fs.hidden = true;
