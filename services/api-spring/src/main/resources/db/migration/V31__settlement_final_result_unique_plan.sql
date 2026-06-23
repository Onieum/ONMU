-- 약속별 최종 정산 결과는 하나만 활성 상태로 남긴다.
-- 기존 중복 결과는 삭제하지 않고 superseded로 보존해 마이그레이션을 안전하게 통과시킨다.

alter table settlements drop constraint if exists settlements_status_check;

alter table settlements
  add constraint settlements_status_check
  check (status in ('finalized', 'completed', 'superseded'));

update notifications
set notification_type = 'settlement_requested'
where notification_type = 'settlement_created';

with ranked_final_results as (
  select
    id,
    row_number() over (
      partition by plan_id
      order by created_at desc nulls last, completed_at desc nulls last, id desc
    ) as row_number
  from settlements
  where status in ('finalized', 'completed')
)
update settlements settlement
set status = 'superseded'
from ranked_final_results ranked
where settlement.id = ranked.id
  and ranked.row_number > 1;

drop index if exists ux_settlements_active_plan;

create unique index if not exists ux_settlements_final_result_plan
  on settlements(plan_id)
  where status in ('finalized', 'completed');
