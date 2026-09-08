-- Migração da versão 3 da BORA ASSESSORIA
-- Execute no Supabase SQL Editor antes de usar os novos campos.

alter table public.races
  add column if not exists route_image_url text;

alter table public.strategies
  add column if not exists warmup jsonb not null default '[]'::jsonb;

alter table public.strategies
  add column if not exists hydration jsonb not null default '[]'::jsonb;

alter table public.strategies
  add column if not exists elevation jsonb not null default '[]'::jsonb;

alter table public.strategies
  add column if not exists route_image text;

-- Bucket público para fotos das rotas.
insert into storage.buckets (id, name, public)
values ('race-routes', 'race-routes', true)
on conflict (id) do update set public = true;

drop policy if exists "race routes public read" on storage.objects;
create policy "race routes public read"
on storage.objects for select
to public
using (bucket_id = 'race-routes');

drop policy if exists "race routes coach upload" on storage.objects;
create policy "race routes coach upload"
on storage.objects for insert
to authenticated
with check (bucket_id = 'race-routes');

drop policy if exists "race routes coach update" on storage.objects;
create policy "race routes coach update"
on storage.objects for update
to authenticated
using (bucket_id = 'race-routes')
with check (bucket_id = 'race-routes');

drop policy if exists "race routes coach delete" on storage.objects;
create policy "race routes coach delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'race-routes');

drop function if exists public.get_public_strategy(text);
create or replace function public.get_public_strategy(p_token text)
returns table (
  id uuid,
  athlete_name text,
  race_name text,
  distance numeric,
  city text,
  race_date date,
  target_time text,
  strategy_type text,
  pace_rows jsonb,
  execution_notes jsonb,
  warmup jsonb,
  hydration jsonb,
  elevation jsonb,
  route_image text
)
language sql
security definer
set search_path = public
as $$
  select s.id,
         s.athlete_name_snapshot,
         s.race_name_snapshot,
         s.race_distance_snapshot,
         s.race_city_snapshot,
         s.race_date_snapshot,
         s.target_time,
         s.strategy_type,
         s.pace_rows,
         s.execution_notes,
         s.warmup,
         s.hydration,
         s.elevation,
         s.route_image
  from public.strategies s
  where s.share_token = p_token and s.is_public = true
  limit 1;
$$;

revoke all on function public.get_public_strategy(text) from public;
grant execute on function public.get_public_strategy(text) to anon, authenticated;
