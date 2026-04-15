-- ─── RestaurantOS — Migración Multi-tenancy ───────────────────────────────────
-- EJECUTA ESTO EN EL SQL EDITOR DE SUPABASE (UNA SOLA VEZ)
-- ⚠️  Esto REEMPLAZA el esquema anterior. Si tienes datos de prueba se perderán.
-- ─────────────────────────────────────────────────────────────────────────────


-- ─── 1. LIMPIAR ESQUEMA ANTERIOR ─────────────────────────────────────────────
drop table if exists public.albaran_lineas        cascade;
drop table if exists public.albaranes             cascade;
drop table if exists public.ventas                cascade;
drop table if exists public.receta_ingredientes   cascade;
drop table if exists public.recetas               cascade;
drop table if exists public.stock                 cascade;
drop table if exists public.restaurante_usuarios  cascade;
drop table if exists public.restaurantes          cascade;
drop table if exists public.grupos                cascade;
drop function if exists public.user_has_restaurant_access(uuid);
drop function if exists public.user_get_restaurante_id();


-- ─── 2. NUEVAS TABLAS DE ESTRUCTURA ──────────────────────────────────────────

-- Grupos: un jefe puede tener varios restaurantes bajo un mismo grupo
create table public.grupos (
  id           uuid primary key default gen_random_uuid(),
  nombre       text not null,
  jefe_user_id uuid references auth.users(id) on delete cascade not null,
  created_at   timestamptz default now()
);

-- Restaurantes: cada local pertenece a un grupo
create table public.restaurantes (
  id         uuid primary key default gen_random_uuid(),
  grupo_id   uuid references public.grupos(id) on delete cascade not null,
  nombre     text not null,
  created_at timestamptz default now()
);

-- Membresías: admins y encargados vinculados a grupos/restaurantes
-- rol 'admin'     → restaurante_id = NULL → acceso a TODOS los restaurantes del grupo
-- rol 'encargado' → restaurante_id = UUID → acceso solo a ese restaurante
create table public.restaurante_usuarios (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete cascade not null,
  grupo_id       uuid references public.grupos(id) on delete cascade not null,
  restaurante_id uuid references public.restaurantes(id) on delete cascade,
  rol            text not null check (rol in ('admin', 'encargado')),
  created_at     timestamptz default now(),
  unique(user_id, grupo_id)
);


-- ─── 3. TABLAS DE DATOS (usan restaurante_id en vez de user_id) ──────────────

create table public.stock (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  nombre         text not null,
  categoria      text not null default 'Otros',
  cantidad       numeric not null default 0,
  unidad         text not null default 'kg',
  precio_und     numeric not null default 0,
  minimo         numeric not null default 0,
  created_at     timestamptz default now()
);

create table public.recetas (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  nombre         text not null,
  categoria      text not null default 'Otros',
  pvp            numeric not null default 0,
  created_at     timestamptz default now()
);

create table public.receta_ingredientes (
  id        uuid primary key default gen_random_uuid(),
  receta_id uuid references public.recetas(id) on delete cascade not null,
  stock_id  uuid references public.stock(id)   on delete cascade not null,
  cantidad  numeric not null
);

create table public.ventas (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  receta_id      uuid references public.recetas(id) on delete set null,
  unidades       integer not null default 1,
  created_at     timestamptz default now()
);

create table public.albaranes (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  proveedor      text not null default '',
  fecha          text not null,
  created_at     timestamptz default now()
);

create table public.albaran_lineas (
  id          uuid primary key default gen_random_uuid(),
  albaran_id  uuid references public.albaranes(id) on delete cascade not null,
  nombre      text not null,
  categoria   text not null default 'Otros',
  cantidad    numeric not null,
  unidad      text not null default 'kg',
  precio_und  numeric not null default 0
);


-- ─── 4. FUNCIÓN AUXILIAR DE ACCESO ───────────────────────────────────────────

create or replace function public.user_has_restaurant_access(rid uuid)
returns boolean
language plpgsql security definer stable as $$
declare
  v_role text;
begin
  -- Obtener rol del usuario desde user_metadata
  select raw_user_meta_data->>'role'
    into v_role
    from auth.users
   where id = auth.uid();

  -- superadmin: acceso total
  if v_role = 'superadmin' then return true; end if;

  -- jefe: acceso si el restaurante pertenece a su grupo
  if v_role = 'jefe' then
    return exists (
      select 1 from public.restaurantes r
      join public.grupos g on g.id = r.grupo_id
      where r.id = rid and g.jefe_user_id = auth.uid()
    );
  end if;

  -- admin: acceso a todos los restaurantes del grupo al que pertenece
  if exists (
    select 1 from public.restaurante_usuarios ru
    join public.restaurantes r on r.grupo_id = ru.grupo_id
    where ru.user_id = auth.uid()
      and ru.rol = 'admin'
      and r.id = rid
  ) then return true; end if;

  -- encargado: acceso solo al restaurante asignado
  return exists (
    select 1 from public.restaurante_usuarios
    where user_id = auth.uid()
      and restaurante_id = rid
      and rol = 'encargado'
  );
end;
$$;


-- ─── 5. ROW LEVEL SECURITY ───────────────────────────────────────────────────

alter table public.grupos                enable row level security;
alter table public.restaurantes          enable row level security;
alter table public.restaurante_usuarios  enable row level security;
alter table public.stock                 enable row level security;
alter table public.recetas               enable row level security;
alter table public.receta_ingredientes   enable row level security;
alter table public.ventas                enable row level security;
alter table public.albaranes             enable row level security;
alter table public.albaran_lineas        enable row level security;

-- grupos: jefe ve sus grupos; superadmin ve todos
create policy "grupos: acceso propio"
  on public.grupos for all
  using (
    jefe_user_id = auth.uid()
    or (select raw_user_meta_data->>'role' from auth.users where id = auth.uid()) = 'superadmin'
  );

-- restaurantes: acceso si tiene acceso al restaurante
create policy "restaurantes: acceso propio"
  on public.restaurantes for all
  using ( public.user_has_restaurant_access(id) );

-- restaurante_usuarios: solo el propio usuario y superadmin/jefe
create policy "restaurante_usuarios: acceso propio"
  on public.restaurante_usuarios for all
  using (
    user_id = auth.uid()
    or (select raw_user_meta_data->>'role' from auth.users where id = auth.uid()) in ('superadmin', 'jefe')
  );

-- stock
create policy "stock: acceso por restaurante"
  on public.stock for all
  using ( public.user_has_restaurant_access(restaurante_id) );

-- recetas
create policy "recetas: acceso por restaurante"
  on public.recetas for all
  using ( public.user_has_restaurant_access(restaurante_id) );

-- receta_ingredientes: acceso a través de la receta
create policy "receta_ingredientes: acceso propio"
  on public.receta_ingredientes for all
  using (
    exists (
      select 1 from public.recetas r
      where r.id = receta_ingredientes.receta_id
        and public.user_has_restaurant_access(r.restaurante_id)
    )
  );

-- ventas
create policy "ventas: acceso por restaurante"
  on public.ventas for all
  using ( public.user_has_restaurant_access(restaurante_id) );

-- albaranes
create policy "albaranes: acceso por restaurante"
  on public.albaranes for all
  using ( public.user_has_restaurant_access(restaurante_id) );

-- albaran_lineas: acceso a través del albarán
create policy "albaran_lineas: acceso propio"
  on public.albaran_lineas for all
  using (
    exists (
      select 1 from public.albaranes a
      where a.id = albaran_lineas.albaran_id
        and public.user_has_restaurant_access(a.restaurante_id)
    )
  );


-- ─── FIN ─────────────────────────────────────────────────────────────────────
-- Recuerda configurar tu usuario superadmin:
-- UPDATE auth.users SET raw_user_meta_data = raw_user_meta_data || '{"role":"superadmin"}'
-- WHERE email = 'bordeniucstass@gmail.com';
