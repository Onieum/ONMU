-- 정산 section/item id는 draft 또는 settlement 내부에서만 유일하면 된다.
-- 기존 전역 unique 제약은 서로 다른 정산의 "기타 비용(extra)" section과
-- draft -> finalized 복사 과정의 동일 item id를 중복으로 오인해 정산 생성/확정을 막았다.

alter table settlement_sections drop constraint if exists settlement_sections_public_id_key;
drop index if exists ux_settlement_sections_public_id;

alter table settlement_items drop constraint if exists settlement_items_public_id_key;
drop index if exists ux_settlement_items_public_id;

create unique index if not exists ux_settlement_sections_draft_public_id
  on settlement_sections(settlement_draft_id, public_id)
  where settlement_draft_id is not null;

create unique index if not exists ux_settlement_sections_settlement_public_id
  on settlement_sections(settlement_id, public_id)
  where settlement_id is not null;

create unique index if not exists ux_settlement_items_draft_public_id
  on settlement_items(settlement_draft_id, public_id)
  where settlement_draft_id is not null;

create unique index if not exists ux_settlement_items_settlement_public_id
  on settlement_items(settlement_id, public_id)
  where settlement_id is not null;
