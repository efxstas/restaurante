// api/admin.js — Vercel serverless function
// Crea usuarios en Supabase usando la service role key (nunca expuesta al cliente).
// Protegida por ADMIN_SECRET — configúralo en las env vars de Vercel.

import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Método no permitido' });

  const { adminSecret, action, ...data } = req.body;

  if (!adminSecret || adminSecret !== process.env.ADMIN_SECRET) {
    return res.status(403).json({ error: 'No autorizado' });
  }

  const supabaseUrl     = process.env.SUPABASE_URL;
  const serviceRoleKey  = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(500).json({ error: 'Configuración del servidor incompleta' });
  }

  const sb = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  if (action === 'create_user') {
    const { email, password, role, grupoId, restauranteId } = data;
    if (!email || !password) return res.status(400).json({ error: 'Email y contraseña son obligatorios' });

    // 1. Crear usuario en Supabase Auth
    const { data: created, error: createErr } = await sb.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // sin confirmación de email
      user_metadata: {
        role: (role === 'jefe' || role === 'superadmin') ? role : undefined,
      },
    });

    if (createErr) {
      return res.status(400).json({ error: createErr.message });
    }

    const userId = created.user.id;

    // 2. Si es admin o encargado, vincularlo al restaurante
    if ((role === 'admin' || role === 'encargado') && grupoId) {
      const { error: linkErr } = await sb.from('restaurante_usuarios').insert({
        user_id:        userId,
        grupo_id:       grupoId,
        restaurante_id: role === 'encargado' ? (restauranteId || null) : null,
        rol:            role,
      });
      if (linkErr) {
        // Usuario creado pero vinculación falló — avisamos pero no borramos el usuario
        return res.status(200).json({
          success: true,
          userId,
          warning: 'Usuario creado pero no se pudo vincular al restaurante: ' + linkErr.message,
        });
      }
    }

    // 3. Si es jefe, actualizar el grupo para que sea su jefe_user_id
    if (role === 'jefe' && grupoId) {
      await sb.from('grupos').update({ jefe_user_id: userId }).eq('id', grupoId);
    }

    return res.status(200).json({ success: true, userId });
  }

  return res.status(400).json({ error: 'Acción desconocida: ' + action });
}
