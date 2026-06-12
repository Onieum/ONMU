insert into plan_participants (id, plan_id, user_id, status, response, joined_at)
select
  gen_random_uuid(),
  plan_row.id,
  group_row.owner_user_id,
  'joined',
  'accepted',
  coalesce(plan_row.created_at, now())
from plans plan_row
join groups group_row on group_row.id = plan_row.group_id
where group_row.owner_user_id is not null
  and not exists (
    select 1
    from plan_participants participant
    where participant.plan_id = plan_row.id
  )
  and not exists (
    select 1
    from plan_participants participant
    where participant.plan_id = plan_row.id
      and participant.user_id = group_row.owner_user_id
  );
