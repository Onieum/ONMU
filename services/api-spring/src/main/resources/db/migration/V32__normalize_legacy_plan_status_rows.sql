-- 기존 staging/dev 데이터에 남아 있는 legacy plan status가 약속 목록 조회를 깨지 않도록 다시 보정한다.
alter table plans drop constraint if exists plans_status_check;

update plans
set status = case
  when status is null or btrim(status) = '' then 'scheduled'
  when lower(btrim(status)) in ('confirmed') then 'scheduled'
  when lower(btrim(status)) in ('scheduled', 'active', 'completed', 'cancelled') then lower(btrim(status))
  else 'scheduled'
end;

alter table plans alter column status set default 'scheduled';

alter table plans
  add constraint plans_status_check
  check (status in ('scheduled', 'active', 'completed', 'cancelled'));
