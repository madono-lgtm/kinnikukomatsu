-- Supabase SQL Editor で実行するエクスポートクエリ
-- 実行結果は1行1列のJSONです。セルの内容を全部コピーして
-- migration/export.json という名前で保存してください。
select json_build_object(
  'auth_users', (
    select coalesce(json_agg(json_build_object(
      'id', u.id,
      'email', u.email,
      'hash', u.encrypted_password
    )), '[]'::json)
    from auth.users u
  ),
  'profiles',                 (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.profiles t),
  'settings',                 (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.settings t),
  'reservations',             (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.reservations t),
  'reservation_participants', (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.reservation_participants t),
  'groups',                   (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.groups t),
  'group_members',            (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.group_members t),
  'ticket_history',           (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.ticket_history t),
  'intake_sheets',            (select coalesce(json_agg(row_to_json(t)), '[]'::json) from public.intake_sheets t)
) as export_json;
