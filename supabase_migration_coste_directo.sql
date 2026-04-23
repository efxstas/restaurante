-- Añade campo coste_directo a recetas
-- Ejecutar en: Supabase → SQL Editor

alter table public.recetas
  add column if not exists coste_directo numeric default null;
