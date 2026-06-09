-- 장소 외부 링크 구조를 보강한다.
-- V1~V6는 이미 dev DB에 적용됐으므로 기존 migration을 수정하지 않고 V7로 추가한다.
-- external_places.link_summary는 앱/API 표시용 캐시이고, external_place_links는 canonical 링크 원장이다.

alter table external_places
  add column if not exists link_summary jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'external_places_link_summary_array_check') then
    alter table external_places
      add constraint external_places_link_summary_array_check
      check (jsonb_typeof(link_summary) = 'array');
  end if;
end $$;

create table if not exists external_place_links (
  id uuid primary key default gen_random_uuid(),
  external_place_id uuid not null references external_places(id) on delete cascade,
  link_type varchar(40) not null,
  url text not null,
  normalized_url text,
  label text,
  provider varchar(30),
  source_type varchar(30) not null,
  status varchar(20) not null default 'active',
  display_order integer not null default 0,
  confidence numeric(5,4),
  fetched_at timestamptz,
  verified_at timestamptz,
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table external_place_links is
  '장소별 외부 링크 canonical 원장. 앱 표시용 요약은 external_places.link_summary에 캐시한다.';
comment on column external_places.link_summary is
  '앱/API 응답에서 빠르게 사용할 링크 요약 캐시. 원장은 external_place_links이며 secret/token/개인정보를 저장하지 않는다.';
comment on column external_place_links.metadata is
  'provider별 동적 링크 세부 정보만 저장한다. secret/token/개인정보 저장 금지.';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'external_place_links_type_check') then
    alter table external_place_links
      add constraint external_place_links_type_check
      check (link_type in (
        'homepage',
        'instagram',
        'baemin',
        'catchtable',
        'menu',
        'blog',
        'naver_place',
        'kakao_place',
        'reservation',
        'other'
      ));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'external_place_links_source_type_check') then
    alter table external_place_links
      add constraint external_place_links_source_type_check
      check (source_type in ('provider', 'manual', 'crawler', 'ai_extract'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'external_place_links_status_check') then
    alter table external_place_links
      add constraint external_place_links_status_check
      check (status in ('active', 'inactive', 'broken', 'hidden'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'external_place_links_confidence_check') then
    alter table external_place_links
      add constraint external_place_links_confidence_check
      check (confidence is null or (confidence >= 0 and confidence <= 1));
  end if;
end $$;

create unique index if not exists ux_external_place_links_place_normalized_url
  on external_place_links(external_place_id, normalized_url)
  where normalized_url is not null;

create unique index if not exists ux_external_place_links_place_type_url
  on external_place_links(external_place_id, link_type, url);

create index if not exists idx_external_place_links_place_status_order
  on external_place_links(external_place_id, status, display_order);

create index if not exists idx_external_place_links_type_status
  on external_place_links(link_type, status);

create index if not exists idx_external_place_links_provider_source
  on external_place_links(provider, source_type);

insert into external_place_links (
  id,
  external_place_id,
  link_type,
  url,
  normalized_url,
  label,
  provider,
  source_type,
  status,
  display_order,
  confidence,
  fetched_at,
  verified_at,
  metadata
)
values
  (
    '00000000-0000-0000-0000-000000000821',
    '00000000-0000-0000-0000-000000000801',
    'instagram',
    'https://example.test/onmu-place-instagram',
    'https://example.test/onmu-place-instagram',
    '인스타그램',
    'MANUAL',
    'manual',
    'active',
    10,
    0.9600,
    '2026-06-09T12:00:00+09:00',
    '2026-06-09T12:00:00+09:00',
    '{"handle":"onmu_place_seed"}'
  ),
  (
    '00000000-0000-0000-0000-000000000822',
    '00000000-0000-0000-0000-000000000802',
    'reservation',
    'https://example.test/onmu-place-reservation',
    'https://example.test/onmu-place-reservation',
    '예약',
    'MANUAL',
    'provider',
    'active',
    10,
    0.9400,
    '2026-06-09T12:05:00+09:00',
    '2026-06-09T12:05:00+09:00',
    '{"reservationProvider":"catchtable"}'
  ),
  (
    '00000000-0000-0000-0000-000000000823',
    '00000000-0000-0000-0000-000000000803',
    'menu',
    'https://example.test/onmu-place-menu',
    'https://example.test/onmu-place-menu',
    '메뉴',
    'MANUAL',
    'manual',
    'active',
    10,
    0.9000,
    '2026-06-09T12:10:00+09:00',
    '2026-06-09T12:10:00+09:00',
    '{"displayHint":"menu"}'
  ),
  (
    '00000000-0000-0000-0000-000000000824',
    '00000000-0000-0000-0000-000000000803',
    'blog',
    'https://example.test/onmu-place-blog',
    'https://example.test/onmu-place-blog',
    '블로그',
    'CRAWLER',
    'crawler',
    'active',
    20,
    0.8200,
    '2026-06-09T12:10:00+09:00',
    null,
    '{"summary":"synthetic blog link"}'
  )
on conflict (id) do update set
  link_type = excluded.link_type,
  url = excluded.url,
  normalized_url = excluded.normalized_url,
  label = excluded.label,
  provider = excluded.provider,
  source_type = excluded.source_type,
  status = excluded.status,
  display_order = excluded.display_order,
  confidence = excluded.confidence,
  fetched_at = excluded.fetched_at,
  verified_at = excluded.verified_at,
  metadata = excluded.metadata,
  updated_at = now();

update external_places
set link_summary = '[
  {
    "type": "instagram",
    "url": "https://example.test/onmu-place-instagram",
    "label": "인스타그램",
    "status": "active",
    "source": "manual"
  }
]'::jsonb
where id = '00000000-0000-0000-0000-000000000801';

update external_places
set link_summary = '[
  {
    "type": "reservation",
    "provider": "catchtable",
    "url": "https://example.test/onmu-place-reservation",
    "label": "예약",
    "status": "active",
    "source": "provider"
  }
]'::jsonb
where id = '00000000-0000-0000-0000-000000000802';

update external_places
set link_summary = '[
  {
    "type": "menu",
    "url": "https://example.test/onmu-place-menu",
    "label": "메뉴",
    "status": "active",
    "source": "manual"
  },
  {
    "type": "blog",
    "url": "https://example.test/onmu-place-blog",
    "label": "블로그",
    "status": "active",
    "source": "crawler"
  }
]'::jsonb
where id = '00000000-0000-0000-0000-000000000803';
