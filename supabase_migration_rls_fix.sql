-- ─── RestaurantOS — Fix RLS para receta_ingredientes ─────────────────────────
-- Ejecuta si el encargado no puede editar ingredientes de recetas.
-- Añade WITH CHECK explícito para INSERT/UPDATE.

drop policy if exists "receta_ingredientes: acceso propio" on public.receta_ingredientes;

create policy "receta_ingredientes: acceso propio"
  on public.receta_ingredientes for all
  using (
    exists (
      select 1 from public.recetas r
      where r.id = receta_ingredientes.receta_id
        and public.user_has_restaurant_access(r.restaurante_id)
    )
  )
  with check (
    exists (
      select 1 from public.recetas r
      where r.id = receta_ingredientes.receta_id
        and public.user_has_restaurant_access(r.restaurante_id)
    )
  );
