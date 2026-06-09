-- SCRUM-39 synthetic dev seed for the data-dictionary core app schema.
-- All values are reserved/test data. Do not place real user data, credentials, phone numbers, or precise locations here.

insert into users (
  id,
  public_id,
  display_name,
  nickname,
  profile_image_url,
  status_message,
  email,
  default_locale,
  time_zone,
  status,
  last_login_at
)
values
  ('00000000-0000-0000-0000-000000000001', 'user-001', '테스트 사용자 1', 'seed-one', 'dev/avatars/user-001.png', 'Spring core seed user', 'user1@example.test', 'ko-KR', 'Asia/Seoul', 'active', '2026-06-09T09:00:00+09:00'),
  ('00000000-0000-0000-0000-000000000002', 'user-002', '테스트 사용자 2', 'seed-two', 'dev/avatars/user-002.png', 'Synthetic teammate', 'user2@example.test', 'ko-KR', 'Asia/Seoul', 'active', '2026-06-09T09:05:00+09:00'),
  ('00000000-0000-0000-0000-000000000003', 'user-003', '테스트 사용자 3', 'seed-three', 'dev/avatars/user-003.png', 'Synthetic planner', 'user3@example.test', 'ko-KR', 'Asia/Seoul', 'active', '2026-06-09T09:10:00+09:00'),
  ('00000000-0000-0000-0000-000000000004', 'user-004', '테스트 사용자 4', 'seed-four', 'dev/avatars/user-004.png', 'Synthetic viewer', 'user4@example.test', 'ko-KR', 'Asia/Seoul', 'active', '2026-06-09T09:15:00+09:00')
on conflict (id) do update set
  public_id = excluded.public_id,
  display_name = excluded.display_name,
  nickname = excluded.nickname,
  profile_image_url = excluded.profile_image_url,
  status_message = excluded.status_message,
  email = excluded.email,
  default_locale = excluded.default_locale,
  time_zone = excluded.time_zone,
  status = excluded.status,
  last_login_at = excluded.last_login_at;

insert into auth_identities (
  id,
  user_id,
  provider,
  provider_subject,
  provider_email,
  provider_profile,
  linked_at,
  last_verified_at
)
values
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'NAVER', 'naver-test-user-001', 'user1@example.test', '{"displayName":"테스트 사용자 1"}', '2026-06-09T09:00:00+09:00', '2026-06-09T09:00:00+09:00'),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000002', 'NAVER', 'naver-test-user-002', 'user2@example.test', '{"displayName":"테스트 사용자 2"}', '2026-06-09T09:05:00+09:00', '2026-06-09T09:05:00+09:00'),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000003', 'NAVER', 'naver-test-user-003', 'user3@example.test', '{"displayName":"테스트 사용자 3"}', '2026-06-09T09:10:00+09:00', '2026-06-09T09:10:00+09:00'),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000004', 'NAVER', 'naver-test-user-004', 'user4@example.test', '{"displayName":"테스트 사용자 4"}', '2026-06-09T09:15:00+09:00', '2026-06-09T09:15:00+09:00')
on conflict (id) do update set
  user_id = excluded.user_id,
  provider = excluded.provider,
  provider_subject = excluded.provider_subject,
  provider_email = excluded.provider_email,
  provider_profile = excluded.provider_profile,
  linked_at = excluded.linked_at,
  last_verified_at = excluded.last_verified_at;

insert into user_codes (id, user_id, code, code_format, status, created_at)
values
  ('00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000001', 'NMU2ABCD', 'ALNUM_8', 'active', '2026-06-09T09:00:00+09:00'),
  ('00000000-0000-0000-0000-000000000112', '00000000-0000-0000-0000-000000000002', 'NMU3EFGH', 'ALNUM_8', 'active', '2026-06-09T09:05:00+09:00'),
  ('00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000003', 'NMU4JKLM', 'ALNUM_8', 'active', '2026-06-09T09:10:00+09:00'),
  ('00000000-0000-0000-0000-000000000114', '00000000-0000-0000-0000-000000000004', 'NMU5NPQR', 'ALNUM_8', 'active', '2026-06-09T09:15:00+09:00')
on conflict (code) do update set status = excluded.status;

insert into user_devices (id, user_id, device_fingerprint_hash, platform, app_version, os_version, device_label, trusted, status, last_seen_at)
values
  ('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000001', 'hash-dev-device-001', 'ios', '0.1.0-dev', 'ios-test', 'Seed iOS 1', true, 'active', '2026-06-09T09:00:00+09:00'),
  ('00000000-0000-0000-0000-000000000122', '00000000-0000-0000-0000-000000000002', 'hash-dev-device-002', 'android', '0.1.0-dev', 'android-test', 'Seed Android 2', true, 'active', '2026-06-09T09:05:00+09:00')
on conflict (id) do update set last_seen_at = excluded.last_seen_at;

insert into refresh_tokens (id, user_id, token_hash, device_id, device_label, issued_at, expires_at)
values
  ('00000000-0000-0000-0000-000000000131', '00000000-0000-0000-0000-000000000001', 'sha256:dev-refresh-hash-001', '00000000-0000-0000-0000-000000000121', 'Seed iOS 1', '2026-06-09T09:00:00+09:00', '2026-07-09T09:00:00+09:00'),
  ('00000000-0000-0000-0000-000000000132', '00000000-0000-0000-0000-000000000002', 'sha256:dev-refresh-hash-002', '00000000-0000-0000-0000-000000000122', 'Seed Android 2', '2026-06-09T09:05:00+09:00', '2026-07-09T09:05:00+09:00')
on conflict (token_hash) do nothing;

insert into friendships (id, user_low_id, user_high_id, status, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000211', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'active', '2026-06-09T09:20:00+09:00', '2026-06-09T09:20:00+09:00'),
  ('00000000-0000-0000-0000-000000000212', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'active', '2026-06-09T09:21:00+09:00', '2026-06-09T09:21:00+09:00'),
  ('00000000-0000-0000-0000-000000000213', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', 'active', '2026-06-09T09:22:00+09:00', '2026-06-09T09:22:00+09:00')
on conflict (user_low_id, user_high_id) do update set status = excluded.status;

insert into friend_settings (id, user_id, friend_user_id, alias, favorite, muted, visibility_scope)
values
  ('00000000-0000-0000-0000-000000000221', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '테스트 친구 2', true, false, 'friends'),
  ('00000000-0000-0000-0000-000000000222', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '테스트 친구 1', false, false, 'friends'),
  ('00000000-0000-0000-0000-000000000223', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', '테스트 친구 3', false, true, 'friends')
on conflict (user_id, friend_user_id) do update set alias = excluded.alias, favorite = excluded.favorite, muted = excluded.muted;

insert into friend_requests (id, requester_user_id, target_user_id, request_channel, user_code_id, status, message, created_at, responded_at)
values
  ('00000000-0000-0000-0000-000000000231', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', 'user_code', '00000000-0000-0000-0000-000000000114', 'pending', '테스트 친구 요청입니다.', '2026-06-09T09:25:00+09:00', null)
on conflict (id) do update set status = excluded.status;

insert into groups (id, public_id, name, owner_user_id, description, status, visibility)
values
  ('00000000-0000-0000-0000-000000000201', '1', 'ONMU 개발 모임', '00000000-0000-0000-0000-000000000001', 'Spring core schema smoke용 기본 모임', 'active', 'members'),
  ('00000000-0000-0000-0000-000000000202', '2', 'ONMU 회의 모임', '00000000-0000-0000-0000-000000000002', '데이터사전 seed 검증용 보조 모임', 'active', 'members')
on conflict (id) do update set
  public_id = excluded.public_id,
  name = excluded.name,
  owner_user_id = excluded.owner_user_id,
  description = excluded.description,
  status = excluded.status,
  visibility = excluded.visibility;

insert into group_members (id, group_id, user_id, role, status, joined_at)
values
  ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 'owner', 'active', '2026-06-09T09:30:00+09:00'),
  ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000002', 'member', 'active', '2026-06-09T09:31:00+09:00'),
  ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000003', 'member', 'active', '2026-06-09T09:32:00+09:00'),
  ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000004', 'member', 'active', '2026-06-09T09:33:00+09:00'),
  ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000002', 'owner', 'active', '2026-06-09T09:34:00+09:00'),
  ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000004', 'member', 'active', '2026-06-09T09:35:00+09:00')
on conflict (group_id, user_id) do update set role = excluded.role, status = excluded.status;

insert into plans (id, public_id, group_id, title, starts_at, status, description, ends_at, location_note)
values
  ('00000000-0000-0000-0000-000000000301', '101', '00000000-0000-0000-0000-000000000201', 'ONMU API 계약 검증', '2026-06-12T10:00:00+09:00', 'confirmed', '기존 Flutter contract seed 약속', '2026-06-12T13:00:00+09:00', '테스트 지역'),
  ('00000000-0000-0000-0000-000000000302', '102', '00000000-0000-0000-0000-000000000201', '장소 후보 검증', '2026-06-14T14:00:00+09:00', 'draft', '장소 후보와 일정 등록 seed', '2026-06-14T17:00:00+09:00', '테스트 카페'),
  ('00000000-0000-0000-0000-000000000303', '103', '00000000-0000-0000-0000-000000000202', '정산 플로우 검증', '2026-06-16T19:00:00+09:00', 'confirmed', '정산 draft/transfer seed', '2026-06-16T21:00:00+09:00', '테스트 식당'),
  ('00000000-0000-0000-0000-000000000304', '104', '00000000-0000-0000-0000-000000000202', '기록 공개 범위 검증', '2026-06-20T11:00:00+09:00', 'draft', 'records visibility seed', '2026-06-20T12:30:00+09:00', '테스트 장소')
on conflict (id) do update set
  public_id = excluded.public_id,
  title = excluded.title,
  starts_at = excluded.starts_at,
  status = excluded.status,
  description = excluded.description,
  ends_at = excluded.ends_at,
  location_note = excluded.location_note;

insert into plan_participants (id, plan_id, user_id, status, response, joined_at)
values
  ('00000000-0000-0000-0000-000000000321', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', 'joined', 'accepted', '2026-06-09T09:40:00+09:00'),
  ('00000000-0000-0000-0000-000000000322', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000002', 'joined', 'accepted', '2026-06-09T09:41:00+09:00'),
  ('00000000-0000-0000-0000-000000000323', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000003', 'invited', 'maybe', null),
  ('00000000-0000-0000-0000-000000000324', '00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000001', 'joined', 'accepted', '2026-06-09T09:42:00+09:00'),
  ('00000000-0000-0000-0000-000000000325', '00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000002', 'joined', 'accepted', '2026-06-09T09:43:00+09:00'),
  ('00000000-0000-0000-0000-000000000326', '00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000004', 'joined', 'accepted', '2026-06-09T09:44:00+09:00')
on conflict (plan_id, user_id) do update set status = excluded.status, response = excluded.response;

insert into external_places (id, public_id, provider, provider_place_id, name, category, address, road_address, provider_payload)
values
  ('00000000-0000-0000-0000-000000000801', 'place-001', 'NAVER', 'naver-test-place-001', '테스트 플레이스 카페', '카페', '테스트시 예시구 1', '테스트로 1', '{"source":"synthetic"}'),
  ('00000000-0000-0000-0000-000000000802', 'place-002', 'NAVER', 'naver-test-place-002', '테스트 플레이스 식당', '식당', '테스트시 예시구 2', '테스트로 2', '{"source":"synthetic"}'),
  ('00000000-0000-0000-0000-000000000803', 'place-003', 'MANUAL', 'manual-test-place-003', '테스트 수동 장소', '전시', '테스트시 예시구 3', '테스트로 3', '{"source":"synthetic"}')
on conflict (provider, provider_place_id) do update set name = excluded.name, category = excluded.category;

insert into place_search_logs (id, user_id, group_id, plan_id, query, bounds, filters, provider, result_count, latency_ms, created_at)
values
  ('00000000-0000-0000-0000-000000000811', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '카페', '{"center":"synthetic","zoom":14}', '{"category":"cafe"}', 'NAVER', 2, 42, '2026-06-09T10:00:00+09:00')
on conflict (id) do update set result_count = excluded.result_count, latency_ms = excluded.latency_ms;

update place_candidates
set external_place_id = '00000000-0000-0000-0000-000000000802',
    suggested_by_user_id = '00000000-0000-0000-0000-000000000001',
    status = 'candidate',
    note = '기존 장소 후보 seed'
where id = '00000000-0000-0000-0000-000000000501';

update place_candidates
set external_place_id = '00000000-0000-0000-0000-000000000801',
    suggested_by_user_id = '00000000-0000-0000-0000-000000000002',
    status = 'candidate',
    note = '기존 카페 후보 seed'
where id = '00000000-0000-0000-0000-000000000502';

insert into place_candidates (id, public_id, group_id, plan_id, external_place_id, suggested_by_user_id, name, category, address, payload, status, note)
values
  ('00000000-0000-0000-0000-000000000503', '203', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000801', '00000000-0000-0000-0000-000000000003', '테스트 후보 카페', '카페', '테스트시 예시구 1', '{"tags":["카페","회의"],"favoriteCount":1}', 'candidate', '후보 추가 smoke seed'),
  ('00000000-0000-0000-0000-000000000504', '204', '00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000803', '00000000-0000-0000-0000-000000000004', '테스트 후보 전시', '전시', '테스트시 예시구 3', '{"tags":["전시","실내"],"favoriteCount":2}', 'candidate', '정산 모임 보조 후보')
on conflict (id) do update set name = excluded.name, payload = excluded.payload, status = excluded.status;

insert into schedule_places (id, public_id, group_id, plan_id, place_candidate_id, external_place_id, scheduled_by_user_id, name, starts_at, ends_at, sort_order, note)
values
  ('00000000-0000-0000-0000-000000000901', '701', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000802', '00000000-0000-0000-0000-000000000001', '온무식당', '2026-06-12T10:30:00+09:00', '2026-06-12T12:00:00+09:00', 1, '기존 seed 장소를 일정에 등록'),
  ('00000000-0000-0000-0000-000000000902', '702', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000503', '00000000-0000-0000-0000-000000000801', '00000000-0000-0000-0000-000000000003', '테스트 후보 카페', '2026-06-14T14:30:00+09:00', '2026-06-14T16:00:00+09:00', 1, '장소 후보 검증 일정')
on conflict (id) do update set starts_at = excluded.starts_at, sort_order = excluded.sort_order;

insert into votes (id, public_id, group_id, target_type, target_id, vote_type, title, status, payload, closes_at, created_by_user_id)
values
  ('00000000-0000-0000-0000-000000000402', '502', '00000000-0000-0000-0000-000000000201', 'PLAN', '102', 'PLACE', '테스트 장소 후보 투표', 'open', '{"options":["테스트 후보 카페","테스트 수동 장소"]}', '2026-06-13T23:59:00+09:00', '00000000-0000-0000-0000-000000000001')
on conflict (id) do update set title = excluded.title, payload = excluded.payload, closes_at = excluded.closes_at;

insert into vote_options (id, vote_id, public_id, label, target_type, target_id, sort_order, payload)
values
  ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000401', 'vopt-501-1', '카페', 'TEXT', 'cafe', 1, '{"seed":true}'),
  ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000401', 'vopt-501-2', '식당', 'TEXT', 'restaurant', 2, '{"seed":true}'),
  ('00000000-0000-0000-0000-000000000421', '00000000-0000-0000-0000-000000000402', 'vopt-502-1', '테스트 후보 카페', 'PLACE_CANDIDATE', '203', 1, '{"seed":true}'),
  ('00000000-0000-0000-0000-000000000422', '00000000-0000-0000-0000-000000000402', 'vopt-502-2', '테스트 수동 장소', 'PLACE_CANDIDATE', '204', 2, '{"seed":true}')
on conflict (public_id) do update set label = excluded.label, target_type = excluded.target_type, target_id = excluded.target_id;

insert into vote_responses (id, vote_id, vote_option_id, user_id, response_value)
values
  ('00000000-0000-0000-0000-000000000431', '00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000001', '{"selected":true}'),
  ('00000000-0000-0000-0000-000000000432', '00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000002', '{"selected":true}'),
  ('00000000-0000-0000-0000-000000000433', '00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000421', '00000000-0000-0000-0000-000000000003', '{"selected":true}')
on conflict (vote_id, vote_option_id, user_id) do update set response_value = excluded.response_value;

insert into settlement_items (id, settlement_draft_id, settlement_id, public_id, title, amount_cents, currency, split_type, memo)
values
  ('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000701', '401', '테스트 저녁', 124000, 'KRW', 'equal', '기존 settlement draft seed와 연결'),
  ('00000000-0000-0000-0000-000000001002', '00000000-0000-0000-0000-000000000601', null, '402', '테스트 카페', 36000, 'KRW', 'equal', 'draft 전용 항목')
on conflict (public_id) do update set amount_cents = excluded.amount_cents, memo = excluded.memo;

insert into settlement_item_targets (id, settlement_item_id, user_id, amount_cents, status)
values
  ('00000000-0000-0000-0000-000000001011', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000001', 31000, 'pending'),
  ('00000000-0000-0000-0000-000000001012', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000002', 31000, 'pending'),
  ('00000000-0000-0000-0000-000000001013', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000003', 31000, 'pending'),
  ('00000000-0000-0000-0000-000000001014', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000004', 31000, 'pending')
on conflict (settlement_item_id, user_id) do update set amount_cents = excluded.amount_cents, status = excluded.status;

insert into settlement_transfers (id, settlement_id, from_user_id, to_user_id, amount_cents, currency, status, memo)
values
  ('00000000-0000-0000-0000-000000001021', '00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 31000, 'KRW', 'pending', '테스트 사용자 2 -> 테스트 사용자 1'),
  ('00000000-0000-0000-0000-000000001022', '00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 31000, 'KRW', 'pending', '테스트 사용자 3 -> 테스트 사용자 1')
on conflict (id) do update set amount_cents = excluded.amount_cents, status = excluded.status;

insert into settlement_confirmations (id, settlement_transfer_id, user_id, confirmation_type, status, confirmed_at, memo)
values
  ('00000000-0000-0000-0000-000000001031', '00000000-0000-0000-0000-000000001021', '00000000-0000-0000-0000-000000000002', 'payer_ack', 'confirmed', '2026-06-09T10:30:00+09:00', 'synthetic confirmation')
on conflict (settlement_transfer_id, user_id, confirmation_type) do update set status = excluded.status;

insert into records (id, public_id, group_id, plan_id, author_user_id, title, visibility, summary, payload, mood_tags)
values
  ('00000000-0000-0000-0000-000000001101', 'record-001', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', '그룹 공개 테스트 기록', 'group', '모임 전체 공개 기록 seed', '{"body":"synthetic group record"}', '["group","seed"]'),
  ('00000000-0000-0000-0000-000000001102', 'record-002', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000002', '참여자 공개 테스트 기록', 'participants', '약속 참여자 공개 기록 seed', '{"body":"synthetic participants record"}', '["participants","seed"]'),
  ('00000000-0000-0000-0000-000000001103', 'record-003', null, null, '00000000-0000-0000-0000-000000000003', '비공개 테스트 기록', 'private', '개인 비공개 기록 seed', '{"body":"synthetic private record"}', '["private","seed"]')
on conflict (id) do update set visibility = excluded.visibility, summary = excluded.summary, payload = excluded.payload;

insert into record_media (id, record_id, media_type, storage_key, public_url, width, height, sort_order, payload)
values
  ('00000000-0000-0000-0000-000000001111', '00000000-0000-0000-0000-000000001101', 'image', 'dev/records/record-001/image-1.jpg', null, 1200, 900, 1, '{"placeholder":true}'),
  ('00000000-0000-0000-0000-000000001112', '00000000-0000-0000-0000-000000001102', 'image', 'dev/records/record-002/image-1.jpg', null, 1200, 900, 1, '{"placeholder":true}')
on conflict (id) do update set storage_key = excluded.storage_key;

insert into record_tags (id, record_id, tag_type, tag_value)
values
  ('00000000-0000-0000-0000-000000001121', '00000000-0000-0000-0000-000000001101', 'user', '회의'),
  ('00000000-0000-0000-0000-000000001122', '00000000-0000-0000-0000-000000001102', 'user', '카페')
on conflict (record_id, tag_type, tag_value) do nothing;

insert into ootd_features (id, record_id, user_id, feature_source, features)
values
  ('00000000-0000-0000-0000-000000001131', '00000000-0000-0000-0000-000000001102', '00000000-0000-0000-0000-000000000002', 'user', '{"styleTags":["casual"],"colors":["neutral"]}')
on conflict (id) do update set features = excluded.features;

insert into share_cards (id, record_id, plan_id, group_id, public_id, card_type, storage_key, share_url, payload)
values
  ('00000000-0000-0000-0000-000000001141', '00000000-0000-0000-0000-000000001101', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000201', 'share-001', 'image_export', 'dev/share-cards/share-001.png', null, '{"placeholder":true}')
on conflict (public_id) do update set storage_key = excluded.storage_key;

insert into chat_activity_events (id, group_id, plan_id, actor_user_id, event_type, payload, created_at)
values
  ('00000000-0000-0000-0000-000000001201', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', 'plan.created', '{"planId":"101"}', '2026-06-09T10:40:00+09:00'),
  ('00000000-0000-0000-0000-000000001202', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000002', 'record.created', '{"recordId":"record-002"}', '2026-06-09T10:45:00+09:00')
on conflict (id) do update set payload = excluded.payload;

insert into notifications (id, user_id, group_id, plan_id, notification_type, title, body, payload, status, created_at)
values
  ('00000000-0000-0000-0000-000000001211', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', 'plan_reminder', '테스트 약속 알림', 'ONMU seed 약속 알림입니다.', '{"planId":"101"}', 'queued', '2026-06-09T10:50:00+09:00'),
  ('00000000-0000-0000-0000-000000001212', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', 'settlement_requested', '테스트 정산 알림', '정산 확인 요청입니다.', '{"settlementId":"301"}', 'queued', '2026-06-09T10:51:00+09:00')
on conflict (id) do update set status = excluded.status;

insert into notification_preferences (id, user_id, channel, notification_type, enabled, quiet_hours)
values
  ('00000000-0000-0000-0000-000000001221', '00000000-0000-0000-0000-000000000001', 'push', 'plan_reminder', true, '{"start":"22:00","end":"08:00"}'),
  ('00000000-0000-0000-0000-000000001222', '00000000-0000-0000-0000-000000000002', 'push', 'settlement_requested', true, '{"start":"22:00","end":"08:00"}')
on conflict (user_id, channel, notification_type) do update set enabled = excluded.enabled;

insert into notification_deliveries (id, notification_id, channel, provider, status, attempted_at)
values
  ('00000000-0000-0000-0000-000000001231', '00000000-0000-0000-0000-000000001211', 'push', 'dev', 'pending', '2026-06-09T10:52:00+09:00')
on conflict (id) do update set status = excluded.status;

insert into consent_privacy_settings (id, user_id, analytics_opt_in, marketing_opt_in, contact_sync_opt_in, retention_policy_key, payload)
values
  ('00000000-0000-0000-0000-000000001301', '00000000-0000-0000-0000-000000000001', true, false, false, 'default-dev', '{"source":"seed"}'),
  ('00000000-0000-0000-0000-000000001302', '00000000-0000-0000-0000-000000000002', true, true, false, 'default-dev', '{"source":"seed"}'),
  ('00000000-0000-0000-0000-000000001303', '00000000-0000-0000-0000-000000000003', false, false, false, 'default-dev', '{"source":"seed"}')
on conflict (user_id) do update set
  analytics_opt_in = excluded.analytics_opt_in,
  marketing_opt_in = excluded.marketing_opt_in,
  contact_sync_opt_in = excluded.contact_sync_opt_in,
  payload = excluded.payload;

insert into privacy_policy_snapshots (id, policy_key, version, title, content_hash, effective_at)
values
  ('00000000-0000-0000-0000-000000001311', 'privacy-policy', 'dev-2026-06', 'ONMU dev privacy policy', 'sha256:dev-policy-hash', '2026-06-09T00:00:00+09:00'),
  ('00000000-0000-0000-0000-000000001312', 'terms-of-service', 'dev-2026-06', 'ONMU dev terms', 'sha256:dev-terms-hash', '2026-06-09T00:00:00+09:00')
on conflict (policy_key, version) do update set content_hash = excluded.content_hash;

insert into user_consents (id, user_id, policy_snapshot_id, consent_type, consented, source, created_at)
values
  ('00000000-0000-0000-0000-000000001321', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000001311', 'privacy', true, 'seed', '2026-06-09T11:00:00+09:00'),
  ('00000000-0000-0000-0000-000000001322', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000001312', 'terms', true, 'seed', '2026-06-09T11:00:00+09:00')
on conflict (id) do update set consented = excluded.consented;

insert into data_subject_requests (id, user_id, request_type, status, requested_at, payload)
values
  ('00000000-0000-0000-0000-000000001331', '00000000-0000-0000-0000-000000000004', 'export', 'received', '2026-06-09T11:05:00+09:00', '{"source":"seed"}')
on conflict (id) do update set status = excluded.status;

insert into data_retention_policies (id, policy_key, target_table, retention_days, action, active)
values
  ('00000000-0000-0000-0000-000000001341', 'default-dev', 'api_access_logs', 30, 'delete', true),
  ('00000000-0000-0000-0000-000000001342', 'default-dev', 'login_attempts', 90, 'delete', true)
on conflict (policy_key, target_table) do update set retention_days = excluded.retention_days, active = excluded.active;

insert into outbox_events (id, event_type, aggregate_type, aggregate_id, payload, status, created_at)
values
  ('00000000-0000-0000-0000-000000001401', 'plan.created', 'plan', '00000000-0000-0000-0000-000000000301', '{"groupId":"1","planId":"101"}', 'no_consumer', '2026-06-09T11:10:00+09:00'),
  ('00000000-0000-0000-0000-000000001402', 'place_candidate.created', 'place_candidate', '00000000-0000-0000-0000-000000000503', '{"groupId":"1","planId":"102","candidateId":"203"}', 'no_consumer', '2026-06-09T11:11:00+09:00'),
  ('00000000-0000-0000-0000-000000001403', 'record.created', 'record', '00000000-0000-0000-0000-000000001101', '{"recordId":"record-001","visibility":"group"}', 'no_consumer', '2026-06-09T11:12:00+09:00')
on conflict (id) do update set status = excluded.status, payload = excluded.payload;

insert into outbox_publish_attempts (id, outbox_event_id, attempt_no, status, attempted_at)
values
  ('00000000-0000-0000-0000-000000001411', '00000000-0000-0000-0000-000000001401', 1, 'skipped_dev', '2026-06-09T11:13:00+09:00')
on conflict (outbox_event_id, attempt_no) do update set status = excluded.status;

insert into worker_dead_letters (id, source_event_id, worker_name, event_type, payload, error_message, status)
values
  ('00000000-0000-0000-0000-000000001421', '00000000-0000-0000-0000-000000001402', 'ai-data-worker', 'place_candidate.created', '{"reason":"dev seed only"}', 'No consumer in dev seed', 'open')
on conflict (id) do update set status = excluded.status;

insert into idempotency_keys (id, idempotency_key, request_hash, response_status, response_body, status, expires_at)
values
  ('00000000-0000-0000-0000-000000001501', 'dev-seed-create-plan-101', 'sha256:dev-idempotency-hash', 201, '{"id":"101"}', 'completed', '2026-06-10T00:00:00+09:00')
on conflict (idempotency_key) do update set status = excluded.status;

insert into api_access_logs (id, request_id, user_id, method, path, status_code, duration_ms, client_marker, ip_hash, user_agent, created_at)
values
  ('00000000-0000-0000-0000-000000001511', 'dev-seed-request-001', '00000000-0000-0000-0000-000000000001', 'GET', '/api/v1/home/summary', 200, 12, 'dev-seed', 'hash-dev-ip', 'seed-agent', '2026-06-09T11:15:00+09:00')
on conflict (id) do update set status_code = excluded.status_code;

insert into audit_logs (id, actor_user_id, action, target_type, target_id, payload, created_at)
values
  ('00000000-0000-0000-0000-000000001521', '00000000-0000-0000-0000-000000000001', 'seed.schema.loaded', 'migration', 'V5__core_seed_data_dictionary', '{"source":"SCRUM-39"}', '2026-06-09T11:16:00+09:00')
on conflict (id) do update set payload = excluded.payload;

insert into security_events (id, user_id, event_type, severity, ip_hash, user_agent, payload, created_at)
values
  ('00000000-0000-0000-0000-000000001531', '00000000-0000-0000-0000-000000000001', 'dev.session_check', 'info', 'hash-dev-ip', 'seed-agent', '{"source":"seed"}', '2026-06-09T11:17:00+09:00')
on conflict (id) do update set severity = excluded.severity;

insert into rate_limit_counters (id, bucket_key, subject_key, window_start, window_seconds, request_count, expires_at)
values
  ('00000000-0000-0000-0000-000000001541', 'friend_code_lookup', 'user-001', '2026-06-09T11:00:00+09:00', 60, 1, '2026-06-09T11:01:00+09:00')
on conflict (bucket_key, subject_key, window_start) do update set request_count = excluded.request_count;

insert into feature_flags (id, flag_key, enabled, rollout_rule, description)
values
  ('00000000-0000-0000-0000-000000001551', 'spring-core-schema-seed', true, '{"environment":"dev"}', 'SCRUM-39 core schema seed smoke flag')
on conflict (flag_key) do update set enabled = excluded.enabled, rollout_rule = excluded.rollout_rule;

insert into admin_actions (id, admin_user_id, action, target_type, target_id, reason, payload, created_at)
values
  ('00000000-0000-0000-0000-000000001561', '00000000-0000-0000-0000-000000000001', 'seed.loaded', 'migration', 'V5__core_seed_data_dictionary', 'dev synthetic seed', '{"source":"SCRUM-39"}', '2026-06-09T11:18:00+09:00')
on conflict (id) do update set reason = excluded.reason;
