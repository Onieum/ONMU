-- SCRUM-41 vertical slice contract support.
-- Adds stable public IDs and synthetic seed data for place/settlement flows.

alter table place_candidates add column if not exists public_id text;
alter table schedule_places add column if not exists public_id text;
alter table settlement_drafts add column if not exists public_id text;
alter table settlements add column if not exists public_id text;

update place_candidates set public_id = id::text where public_id is null;
update schedule_places set public_id = id::text where public_id is null;
update settlement_drafts set public_id = id::text where public_id is null;
update settlements set public_id = id::text where public_id is null;

create unique index if not exists ux_place_candidates_public_id on place_candidates(public_id);
create unique index if not exists ux_schedule_places_public_id on schedule_places(public_id);
create unique index if not exists ux_settlement_drafts_public_id on settlement_drafts(public_id);
create unique index if not exists ux_settlements_public_id on settlements(public_id);

alter table place_candidates alter column public_id set not null;
alter table schedule_places alter column public_id set not null;
alter table settlement_drafts alter column public_id set not null;
alter table settlements alter column public_id set not null;

insert into place_candidates (
  id,
  public_id,
  group_id,
  plan_id,
  name,
  category,
  address,
  payload
)
values
(
  '00000000-0000-0000-0000-000000000501',
  '201',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000301',
  '온무식당',
  '한식',
  '서울 마포구 와우산로 24',
  '{"summary":"후보 추가와 투표 생성을 검증하는 Spring seed 장소입니다.","tags":["한식","단체"],"favoriteCount":3}'::jsonb
),
(
  '00000000-0000-0000-0000-000000000502',
  '202',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000301',
  '무드카페',
  '카페',
  '서울 마포구 독막로 17',
  '{"summary":"지도 검색 결과를 후보로 전환하는 smoke용 장소입니다.","tags":["카페","디저트"],"favoriteCount":2}'::jsonb
)
on conflict (public_id) do nothing;

insert into settlement_drafts (
  id,
  public_id,
  group_id,
  plan_id,
  payload
)
values (
  '00000000-0000-0000-0000-000000000601',
  '301',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000301',
  '{"items":[{"id":"401","title":"저녁","amount":124000,"payerName":"지민","splitType":"equal","targetNames":["지민","민수","소연","현우"]}],"memo":"Spring settlement draft seed"}'::jsonb
)
on conflict (public_id) do nothing;

insert into settlements (
  id,
  public_id,
  group_id,
  plan_id,
  payload
)
values (
  '00000000-0000-0000-0000-000000000701',
  '301',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000301',
  '{"items":[{"id":"401","title":"저녁","amount":124000,"payerName":"지민","splitType":"equal","targetNames":["지민","민수","소연","현우"]}],"shareMessage":"ONMU API 계약 검증 약속 정산입니다."}'::jsonb
)
on conflict (public_id) do nothing;

create index if not exists idx_place_candidates_plan_id on place_candidates(plan_id);
create index if not exists idx_schedule_places_plan_id on schedule_places(plan_id);
create index if not exists idx_settlement_drafts_plan_id on settlement_drafts(plan_id);
create index if not exists idx_settlements_plan_id on settlements(plan_id);
