-- ─── RestaurantOS — Migración: Menú Compuesto ─────────────────
-- Ejecuta en: Supabase → SQL Editor

-- 1. Columna es_menu en recetas
alter table public.recetas
  add column if not exists es_menu boolean not null default false;

-- 2. Tabla de opciones del menú
create table if not exists public.receta_opciones (
  id        uuid primary key default gen_random_uuid(),
  receta_id uuid references public.recetas(id) on delete cascade not null,
  opcion_id uuid references public.recetas(id) on delete cascade not null
);

-- 3. RLS
alter table public.receta_opciones enable row level security;

create policy "receta_opciones: acceso propio"
  on public.receta_opciones for all
  using (
    exists (
      select 1 from public.recetas r
      where r.id = receta_opciones.receta_id
        and public.user_has_restaurant_access(r.restaurante_id)
    )
  );
