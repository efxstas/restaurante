// api/admin.js — Vercel serverless function
// Crea usuarios en Supabase usando la service role key (nunca expuesta al cliente).
// Usa fetch nativo — sin dependencias npm.

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Método no permitido' });

  const { adminSecret, action, ...data } = req.body;

  if (!adminSecret || adminSecret !== process.env.ADMIN_SECRET) {
    return res.status(403).json({ error: 'No autorizado' });
  }

  const SUPA_URL  = process.env.SUPABASE_URL;
  const SUPA_KEY  = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!SUPA_URL || !SUPA_KEY) {
    return res.status(500).json({ error: 'Variables de entorno no configuradas en Vercel (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)' });
  }

  const headers = {
    'Content-Type': 'application/json',
    'apikey': SUPA_KEY,
    'Authorization': `Bearer ${SUPA_KEY}`,
  };

  if (action === 'create_user') {
    const { email, password, role, grupoId, restauranteId } = data;
    if (!email || !password) return res.status(400).json({ error: 'Email y contraseña son obligatorios' });

    // 1. Crear usuario en Supabase Auth (admin API)
    const authRes = await fetch(`${SUPA_URL}/auth/v1/admin/users`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: (role === 'jefe' || role === 'superadmin') ? { role } : {},
      }),
    });

    const authData = await authRes.json();
    if (!authRes.ok) {
      return res.status(400).json({ error: authData.msg || authData.message || 'Error al crear usuario' });
    }

    const userId = authData.id;

    // 2. Si es admin o encargado, insertarlo en restaurante_usuarios
    if ((role === 'admin' || role === 'encargado') && grupoId) {
      const linkRes = await fetch(`${SUPA_URL}/rest/v1/restaurante_usuarios`, {
        method: 'POST',
        headers: { ...headers, 'Prefer': 'return=minimal' },
        body: JSON.stringify({
          user_id:        userId,
          grupo_id:       grupoId,
          restaurante_id: role === 'encargado' ? (restauranteId || null) : null,
          rol:            role,
        }),
      });
      if (!linkRes.ok) {
        const linkErr = await linkRes.text();
        return res.status(200).json({
          success: true,
          userId,
          warning: 'Usuario creado pero no vinculado al restaurante: ' + linkErr,
        });
      }
    }

    // 3. Si es jefe, actualizar el grupo con su user_id
    if (role === 'jefe' && grupoId) {
      await fetch(`${SUPA_URL}/rest/v1/grupos?id=eq.${grupoId}`, {
        method: 'PATCH',
        headers: { ...headers, 'Prefer': 'return=minimal' },
        body: JSON.stringify({ jefe_user_id: userId }),
      });
    }

    return res.status(200).json({ success: true, userId });
  }

  return res.status(400).json({ error: 'Acción desconocida: ' + action });
}
