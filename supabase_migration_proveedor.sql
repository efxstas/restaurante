-- Migración: añadir campo proveedor a la tabla albaranes
-- Ejecuta esto en el SQL Editor de Supabase (una sola vez)

ALTER TABLE public.albaranes
  ADD COLUMN IF NOT EXISTS proveedor text NOT NULL DEFAULT '';
