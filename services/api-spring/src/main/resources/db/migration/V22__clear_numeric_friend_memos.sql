update friend_settings
set memo = null,
    updated_at = now()
where memo is not null
  and btrim(memo) ~ '^[0-9]+$';
