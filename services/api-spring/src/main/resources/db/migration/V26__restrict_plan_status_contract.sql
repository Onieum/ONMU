-- 약속 상태 contract는 scheduled, active, completed, cancelled만 허용한다.
update plans
set status = lower(trim(status))
where status is not null
  and lower(trim(status)) in ('scheduled', 'active', 'completed', 'cancelled')
  and status <> lower(trim(status));

update plans
set status = 'scheduled'
where status is null
  or lower(trim(status)) not in ('scheduled', 'active', 'completed', 'cancelled');

alter table plans alter column status set default 'scheduled';

alter table plans drop constraint if exists plans_status_check;
alter table plans
  add constraint plans_status_check
  check (status in ('scheduled', 'active', 'completed', 'cancelled'));
