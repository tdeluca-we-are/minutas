-- =====================================================================
-- Minutas de reuniones — esquema
-- Correr una sola vez en el SQL editor de Supabase (proyecto ojzcxwhoinmljospgmfp)
-- =====================================================================
--
-- Misma forma que seg_estado (seguimiento semanal): la app es personal, un
-- solo dueño por fila y un solo escritor, así que el estado entero viaja como
-- un documento JSON en vez de una tabla de minutas y otra de pendientes. Los
-- datos son chicos (una minuta larga son un par de KB) y la app ya trabaja con
-- un único objeto en memoria. Si algún día las minutas se comparten con el
-- equipo y otro escribe, ahí sí conviene normalizar.

create table if not exists public.min_estado (
  user_id     uuid        primary key references auth.users(id) on delete cascade,
  datos       jsonb       not null default '{}'::jsonb,
  version     integer     not null default 1,
  actualizado timestamptz not null default now()
);

comment on table  public.min_estado is 'Minutas de reuniones, un documento por usuario';
comment on column public.min_estado.version is
  'Se incrementa en cada guardado. La app actualiza con WHERE version = <la que leyó>: si no afecta ninguna fila es porque otra pestaña o dispositivo guardó primero, y en vez de pisar avisa.';

alter table public.min_estado enable row level security;

-- Cada uno ve y escribe únicamente su propia fila. Sin política de DELETE a
-- propósito: desde la app no se puede borrar el documento, solo vaciarlo.
drop policy if exists min_estado_select on public.min_estado;
create policy min_estado_select on public.min_estado
  for select using (auth.uid() = user_id);

drop policy if exists min_estado_insert on public.min_estado;
create policy min_estado_insert on public.min_estado
  for insert with check (auth.uid() = user_id);

drop policy if exists min_estado_update on public.min_estado;
create policy min_estado_update on public.min_estado
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =====================================================================
-- Verificación: después de correr esto, logueado como vos, esta consulta
-- tiene que devolver 0 filas sin error (todavía no cargaste nada).
--   select user_id, version, actualizado from public.min_estado;
-- Si devuelve "permission denied", la RLS quedó mal.
-- Si devuelve 0 filas y ningún error, está listo: la app crea la fila sola
-- en el primer login.
-- =====================================================================
