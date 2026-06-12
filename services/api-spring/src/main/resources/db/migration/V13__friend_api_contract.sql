-- Friend API contract used by the Flutter my-page.
-- V4/V6 already create friendships, friend_requests, user_codes, and friend_settings.
-- This migration only restores the per-user favorite flag needed by the UI.

alter table friend_settings
  add column if not exists is_favorite boolean not null default false;

create index if not exists idx_friend_settings_user_favorite
  on friend_settings(user_id, is_favorite);
