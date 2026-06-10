-- User character master profile for onboarding.
-- OOTD-specific character changes stay in records.payload.characterSnapshot.

create extension if not exists pgcrypto;

create table if not exists character_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users(id),
  gender varchar(20),
  skin_tone varchar(30),
  hair_style varchar(30),
  hair_color varchar(30),
  eye_style varchar(30),
  eye_color varchar(30),
  clothes varchar(30),
  skipped boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint character_profiles_gender_check
    check (gender is null or gender in ('male', 'female')),
  constraint character_profiles_complete_or_skipped_check
    check (
      skipped = true
      or (
        gender is not null
        and skin_tone is not null
        and hair_style is not null
        and hair_color is not null
        and eye_style is not null
        and eye_color is not null
        and clothes is not null
      )
    )
);
