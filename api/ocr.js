// api/ocr.js — Vercel serverless function
// Recibe una imagen en base64 y devuelve las líneas del albarán extraídas por Claude Vision.
// La ANTHROPIC_API_KEY se configura como variable de entorno en Vercel (nunca en el cliente).

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido' });
  }

  const { image, mediaType } = req.body;
  if (!image) {
    return res.status(400).json({ error: 'No se recibió imagen' });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'API key de Anthropic no configurada en el servidor' });
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 1024,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: mediaType || 'image/jpeg',
                data: image,
              },
            },
            {
              type: 'text',
              text: `Analiza este albarán de proveedor y extrae cada producto listado.
Por cada línea de producto devuelve:
- nombre: nombre del producto
- cantidad: número (la cantidad recibida)
- unidad: unidad de medida (usa solo: kg, g, l, ml, ud, cl, lata, bote)
- precio_und: precio por unidad en euros (0 si no aparece)

Devuelve ÚNICAMENTE JSON válido sin ningún texto adicional:
{"lineas": [{"nombre": "string", "cantidad": 0.0, "unidad": "string", "precio_und": 0.0}]}`,
            },
          ],
        }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Anthropic API error:', errText);
      return res.status(500).json({ error: 'Error de la API de Claude', details: errText });
    }

    const data = await response.json();
    const text = data.content[0].text.trim();

    // Parsear JSON de la respuesta
    try {
      return res.status(200).json(JSON.parse(text));
    } catch {
      // Si hay texto extra alrededor del JSON, extraerlo
      const match = text.match(/\{[\s\S]*\}/);
      if (match) {
        return res.status(200).json(JSON.parse(match[0]));
      }
      console.error('No se pudo parsear:', text);
      return res.status(500).json({ error: 'Respuesta inesperada de Claude', raw: text });
    }
  } catch (err) {
    console.error('OCR handler error:', err);
    return res.status(500).json({ error: err.message });
  }
}
