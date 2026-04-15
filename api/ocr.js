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
- cantidad: número total en la unidad base del producto. Lee el texto del producto con atención:
  si describe una multiplicación (ej: "4 ud x 3 kg", "3 cajas de 5kg", "2 × 6 l"), calcula el total (12 kg, 15 kg, 12 l).
  Si no hay multiplicación, usa el número de la columna de cantidad directamente.
- unidad: unidad de medida del total calculado (usa solo: kg, g, l, ml, ud, cl, lata, bote)
- precio_und: precio por unidad CON IVA. Cálculo: coge el valor de la columna "Importe" o "Total" (ese valor ya incluye IVA, no toques nada) y divídelo entre la cantidad total que has calculado. Si no aparece importe, devuelve 0.
- categoria: clasifica el producto en UNA de estas categorías exactas: "Carnes a la brasa", "Comida italiana", "Bebidas", "Otros"
  (Carnes a la brasa = carnes, parrilla, charcutería; Comida italiana = pasta, pizza, salsas italianas, quesos italianos; Bebidas = refrescos, agua, vino, cerveza, alcohol; Otros = el resto)

Devuelve ÚNICAMENTE JSON válido sin ningún texto adicional:
{"lineas": [{"nombre": "string", "cantidad": 0.0, "unidad": "string", "precio_und": 0.0, "categoria": "string"}]}`,
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
