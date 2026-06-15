-- SCRUM-7 numeric user invite/friend codes.
-- New automatically generated user codes use a fixed 10-digit numeric format.

update user_codes
set code = case user_id
    when '00000000-0000-0000-0000-000000000001' then '1000000001'
    when '00000000-0000-0000-0000-000000000002' then '1000000002'
    when '00000000-0000-0000-0000-000000000003' then '1000000003'
    when '00000000-0000-0000-0000-000000000004' then '1000000004'
    else code
  end,
  code_format = 'NUMERIC_10'
where user_id in (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000004'
)
  and status = 'active';

create unique index if not exists ux_user_codes_active_user_id
  on user_codes(user_id)
  where status = 'active';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'user_codes_numeric_10_format_check') then
    alter table user_codes
      add constraint user_codes_numeric_10_format_check
      check (code_format <> 'NUMERIC_10' or code ~ '^[0-9]{10}$')
      not valid;
  end if;
end $$;
