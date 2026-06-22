-- 정산을 약속 하위 협업 draft -> finalized -> completed 생명주기로 확장한다.

alter table settlement_drafts add column if not exists version bigint not null default 0;
alter table settlement_drafts add column if not exists finalized_settlement_id uuid references settlements(id);
alter table settlement_drafts add column if not exists updated_by_user_id uuid references users(id);
update settlement_drafts set status = 'draft' where status is null or status not in ('draft', 'finalized');

alter table settlements add column if not exists completed_at timestamptz;
update settlements set status = 'finalized' where status is null or status not in ('finalized', 'completed');
with ranked_finalized_settlements as (
  select
    id,
    row_number() over (partition by plan_id order by created_at desc nulls last, id desc) as row_number
  from settlements
  where status = 'finalized'
)
update settlements settlement
set
  status = 'completed',
  completed_at = coalesce(settlement.completed_at, now())
from ranked_finalized_settlements ranked
where settlement.id = ranked.id
  and ranked.row_number > 1;

create table if not exists settlement_sections (
  id uuid primary key default gen_random_uuid(),
  settlement_draft_id uuid references settlement_drafts(id),
  settlement_id uuid references settlements(id),
  public_id text not null default ('stls_' || replace(gen_random_uuid()::text, '-', '')),
  schedule_place_id uuid references schedule_places(id),
  title text not null,
  payer_user_id uuid references users(id),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (public_id),
  check (
    (settlement_draft_id is not null and settlement_id is null)
      or (settlement_draft_id is null and settlement_id is not null)
  )
);

alter table settlement_items add column if not exists section_id uuid references settlement_sections(id);
alter table settlement_items add column if not exists amount_won bigint;
update settlement_items set amount_won = amount_cents where amount_won is null;
update settlement_items set split_type = 'menu' where split_type = 'custom';
alter table settlement_items alter column amount_won set not null;
alter table settlement_items drop column if exists amount_cents;

alter table settlement_item_targets add column if not exists amount_won bigint;
update settlement_item_targets set amount_won = amount_cents where amount_won is null;
alter table settlement_item_targets drop column if exists amount_cents;

alter table settlement_transfers add column if not exists public_id text;
update settlement_transfers
set public_id = 'stlt_' || replace(id::text, '-', '')
where public_id is null or public_id = '';
alter table settlement_transfers alter column public_id set not null;
create unique index if not exists ux_settlement_transfers_public_id on settlement_transfers(public_id);

alter table settlement_transfers add column if not exists amount_won bigint;
update settlement_transfers set amount_won = amount_cents where amount_won is null;
alter table settlement_transfers alter column amount_won set not null;
alter table settlement_transfers drop column if exists amount_cents;

-- 기존 seed/개발 데이터에는 payer_ack 같은 이전 확인 타입이 남아 있을 수 있다.
-- 새 계약은 송금자 sent, 수취자 received만 허용하므로 constraint 추가 전에 정규화한다.
with normalized_confirmations as (
  select
    confirmation.id,
    confirmation.settlement_transfer_id,
    confirmation.user_id,
    case
      when lower(trim(confirmation.confirmation_type)) in (
        'sent',
        'payer_ack',
        'payer_confirmed',
        'sender_ack',
        'sender_confirmed',
        'paid',
        'transfer_sent'
      ) then 'sent'
      when lower(trim(confirmation.confirmation_type)) in (
        'received',
        'payee_ack',
        'payee_confirmed',
        'receiver_ack',
        'receiver_confirmed',
        'recipient_ack',
        'recipient_confirmed',
        'transfer_received'
      ) then 'received'
      when confirmation.user_id = transfer.to_user_id then 'received'
      else 'sent'
    end as normalized_type
  from settlement_confirmations confirmation
  join settlement_transfers transfer on transfer.id = confirmation.settlement_transfer_id
),
ranked_confirmations as (
  select
    id,
    row_number() over (
      partition by settlement_transfer_id, user_id, normalized_type
      order by id
    ) as duplicate_rank
  from normalized_confirmations
)
delete from settlement_confirmations confirmation
using ranked_confirmations ranked
where confirmation.id = ranked.id
  and ranked.duplicate_rank > 1;

with normalized_confirmations as (
  select
    confirmation.id,
    case
      when lower(trim(confirmation.confirmation_type)) in (
        'sent',
        'payer_ack',
        'payer_confirmed',
        'sender_ack',
        'sender_confirmed',
        'paid',
        'transfer_sent'
      ) then 'sent'
      when lower(trim(confirmation.confirmation_type)) in (
        'received',
        'payee_ack',
        'payee_confirmed',
        'receiver_ack',
        'receiver_confirmed',
        'recipient_ack',
        'recipient_confirmed',
        'transfer_received'
      ) then 'received'
      when confirmation.user_id = transfer.to_user_id then 'received'
      else 'sent'
    end as normalized_type
  from settlement_confirmations confirmation
  join settlement_transfers transfer on transfer.id = confirmation.settlement_transfer_id
)
update settlement_confirmations confirmation
set confirmation_type = normalized.normalized_type
from normalized_confirmations normalized
where confirmation.id = normalized.id
  and confirmation.confirmation_type <> normalized.normalized_type;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'settlement_drafts_status_check') then
    alter table settlement_drafts add constraint settlement_drafts_status_check check (status in ('draft', 'finalized'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlements_status_check') then
    alter table settlements add constraint settlements_status_check check (status in ('finalized', 'completed'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_items_split_type_check') then
    alter table settlement_items add constraint settlement_items_split_type_check check (split_type in ('equal', 'menu'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_items_amount_won_nonnegative_check') then
    alter table settlement_items add constraint settlement_items_amount_won_nonnegative_check check (amount_won >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_transfers_amount_won_nonnegative_check') then
    alter table settlement_transfers add constraint settlement_transfers_amount_won_nonnegative_check check (amount_won >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'settlement_confirmations_type_check') then
    alter table settlement_confirmations add constraint settlement_confirmations_type_check check (confirmation_type in ('sent', 'received'));
  end if;
end $$;

create unique index if not exists ux_settlement_drafts_active_plan
  on settlement_drafts(plan_id)
  where status = 'draft';

create unique index if not exists ux_settlements_active_plan
  on settlements(plan_id)
  where status = 'finalized';

create index if not exists idx_settlement_sections_draft_order on settlement_sections(settlement_draft_id, sort_order);
create index if not exists idx_settlement_sections_settlement_order on settlement_sections(settlement_id, sort_order);
create index if not exists idx_settlement_items_section_id on settlement_items(section_id);
