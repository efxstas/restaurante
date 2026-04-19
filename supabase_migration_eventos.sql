-- ─── MIGRACIÓN: Eventos / Ventas manuales de stock ──────────────────────────
-- Ejecutar en Supabase SQL Editor

-- 1. Extender tabla ventas con tipo, nombre, importe, fecha
ALTER TABLE public.ventas
  ADD COLUMN IF NOT EXISTS tipo    text    NOT NULL DEFAULT 'receta',
  ADD COLUMN IF NOT EXISTS nombre  text,
  ADD COLUMN IF NOT EXISTS importe numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fecha   text;

-- 2. Nueva tabla para los consumos de stock de un evento
CREATE TABLE IF NOT EXISTS public.evento_consumos (
  id        uuid primary key default gen_random_uuid(),
  venta_id  uuid references public.ventas(id) on delete cascade not null,
  nombre    text    not null,
  cantidad  numeric not null default 1,
  unidad    text    not null default 'kg'
);

ALTER TABLE public.evento_consumos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "evento_consumos: acceso propio"
  ON public.evento_consumos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.ventas v
      WHERE v.id = evento_consumos.venta_id
        AND public.user_has_restaurant_access(v.restaurante_id)
    )
  );
