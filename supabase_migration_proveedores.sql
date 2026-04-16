-- ─── RestaurantOS — Migración: Proveedores por restaurante ───────────────────
-- Ejecuta esto en el SQL Editor de Supabase (una sola vez)

create table if not exists public.proveedores (
  id             uuid primary key default gen_random_uuid(),
  restaurante_id uuid references public.restaurantes(id) on delete cascade not null,
  nombre         text not null,
  created_at     timestamptz default now(),
  unique(restaurante_id, nombre)
);

alter table public.proveedores enable row level security;

create policy "proveedores: acceso por restaurante"
  on public.proveedores for all
  using ( public.user_has_restaurant_access(restaurante_id) );
