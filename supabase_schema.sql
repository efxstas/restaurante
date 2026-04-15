-- ─── RestaurantOS — Schema Supabase ───────────────────────────
-- Ejecuta este SQL en el SQL Editor de tu proyecto Supabase.
-- Recomendado: desactiva "Confirm email" en Authentication > Providers > Email
-- para que el registro sea inmediato en desarrollo.

-- ─── TABLAS ───────────────────────────────────────────────────

create table public.stock (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  nombre     text not null,
  categoria  text not null default 'Otros',
  cantidad   numeric not null default 0,
  unidad     text not null default 'kg',
  precio_und numeric not null default 0,
  minimo     numeric not null default 0,
  created_at timestamptz default now()
);

create table public.recetas (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  nombre     text not null,
  categoria  text not null default 'Otros',
  pvp        numeric not null default 0,
  created_at timestamptz default now()
);

create table public.receta_ingredientes (
  id        uuid primary key default gen_random_uuid(),
  receta_id uuid references public.recetas(id) on delete cascade not null,
  stock_id  uuid references public.stock(id)   on delete cascade not null,
  cantidad  numeric not null
);

create table public.ventas (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  receta_id  uuid references public.recetas(id) on delete set null,
  unidades   integer not null default 1,
  created_at timestamptz default now()
);

create table public.albaranes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  fecha      text not null,
  created_at timestamptz default now()
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

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────

alter table public.stock               enable row level security;
alter table public.recetas             enable row level security;
alter table public.receta_ingredientes enable row level security;
alter table public.ventas              enable row level security;
alter table public.albaranes           enable row level security;
alter table public.albaran_lineas      enable row level security;

-- stock: el usuario solo accede a sus propios productos
create policy "stock: acceso propio"
  on public.stock for all
  using (auth.uid() = user_id);

-- recetas: el usuario solo accede a sus propias recetas
create policy "recetas: acceso propio"
  on public.recetas for all
  using (auth.uid() = user_id);

-- receta_ingredientes: acceso a través de la receta del usuario
create policy "receta_ingredientes: acceso propio"
  on public.receta_ingredientes for all
  using (
    exists (
      select 1 from public.recetas
      where recetas.id = receta_ingredientes.receta_id
        and recetas.user_id = auth.uid()
    )
  );

-- ventas: el usuario solo accede a sus propias ventas
create policy "ventas: acceso propio"
  on public.ventas for all
  using (auth.uid() = user_id);

-- albaranes: el usuario solo accede a sus propios albaranes
create policy "albaranes: acceso propio"
  on public.albaranes for all
  using (auth.uid() = user_id);

-- albaran_lineas: acceso a través del albarán del usuario
create policy "albaran_lineas: acceso propio"
  on public.albaran_lineas for all
  using (
    exists (
      select 1 from public.albaranes
      where albaranes.id = albaran_lineas.albaran_id
        and albaranes.user_id = auth.uid()
    )
  );
