-- ─── RestaurantOS — Migración: Categorías custom por restaurante ──────────────
-- Ejecuta esto en el SQL Editor de Supabase (una sola vez, sobre el esquema actual)

create table if not exists public.categorias (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  nombre         text not null,
  created_at     timestamptz default now(),
  unique(restaurante_id, nombre)
);

alter table public.categorias enable row level security;

create policy "categorias: acceso por restaurante"
  on public.categorias for all
  using ( public.user_has_restaurant_access(restaurante_id) );
