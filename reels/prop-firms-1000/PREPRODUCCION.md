# Reel — "1.000 € para prop firms"

## ▶ Versión producida (v1)

Archivo: `out/reel_prop_firms_1000.mp4` · 1080×1920 · 30 fps · H.264 + AAC · **42.8 s** · 21 planos · VO a −14 LUFS.

Cambios respecto a la propuesta de abajo (según las respuestas del usuario):

- **Voz sintética** (Piper `es_ES-davefx-medium`, offline). Anglicismos re-escritos solo para la voz
  (`dráudaun`, `payaut`, `prop férms`); los subtítulos mantienen la grafía real. Verificado con Whisper.
- **Sin comunidad ni promo**: CTA = "Sígueme para más." (P19–P20 de la tabla se funden en un plano).
- **Sin referencia.** En el plano del payout (p5c) se usa la captura real del usuario, con el nombre y
  el avatar de la prop firm pixelados y sin importes, rotulada "CAPTURA REAL".
- Los tiempos de cada plano salen del audio real (`build/timing.json`):

| Plano | Tiempo (s) | Frames | VO |
|---|---|---|---|
| hook | 0.00–1.99 | 0–60 | Tienes 1.000 € para prop firms. |
| burn | 1.99–3.54 | 60–106 | Así no los quemas. |
| p1a | 3.54–5.37 | 106–161 | Uno. Reparte el presupuesto. |
| p1b | 5.37–6.92 | 161–208 | Compra con descuento |
| p1c | 6.92–8.91 | 208–267 | y no lo gastes todo en el mismo mes. |
| p2a | 8.91–10.83 | 267–325 | Dos. Primero, las reglas. |
| p2b | 10.83–13.32 | 325–400 | drawdown, límite diario y consistencia. |
| p2c | 13.32–15.49 | 400–465 | Si no las conoces, la cuenta dura un día. |
| p3a | 15.49–17.63 | 465–529 | Tres. Arriesga para sobrevivir, |
| p3b | 17.63–19.20 | 529–576 | no para pasar en 2 días. |
| p3c | 19.20–20.75 | 576–623 | La prisa sale cara. |
| p3d | 20.75–22.85 | 623–686 | Tamaño pequeño, stop siempre puesto. |
| p4a | 22.85–24.40 | 686–732 | Cuatro. ¿Suspendes? |
| p4b | 24.40–26.93 | 732–808 | Antes del segundo intento, revisa tus errores. |
| p4c | 26.93–29.01 | 808–870 | Y no subas el riesgo para recuperar. |
| p5a | 29.01–30.78 | 870–923 | Cinco. Pasar no es cobrar. |
| p5b | 30.78–32.33 | 923–970 | Protege la cuenta fondeada. |
| p5c | 32.33–35.11 | 970–1053 | Mismo plan, mismo riesgo, hasta el primer payout. |
| follow | 35.11–36.66 | 1053–1100 | Sígueme para más. |
| loop | 36.66–39.25 | 1100–1177 | Porque con 1.000 €, la clave es no quemarlos. |
| disclaimer | 39.25–42.85 | 1177–1285 | (sin VO · disclaimer) |

Reconstruir: `python3 build/voice.py <modelo-piper>` → masterizar a `out/vo.wav` → `node build/render.js video`
(`node build/render.js stills` saca un fotograma por plano con las zonas seguras marcadas).

---

## Propuesta original

Instagram Reel · 9:16 · 1080×1920 · 30 fps · **43,2 s (1.296 frames)** · 22 planos · sin assets externos.

> Los tiempos se han calculado a ~2,9 palabras/s. Cuando exista la locución grabada, se re-sincronizan
> subtítulos y cortes con alineado forzado (palabra a palabra) sobre el audio real.

---

## 1. Voiceover (es-ES, 113 palabras)

| Bloque | Texto | Palabras |
|---|---|---|
| Gancho | Tienes mil euros para prop firms. Así no los quemas. | 10 |
| 1 | Uno. Reparte el presupuesto. Compra con descuento y no lo gastes todo en el mismo mes. | 16 |
| 2 | Dos. Primero, las reglas: drawdown, límite diario y consistencia. Si no las conoces, la cuenta dura un día. | 18 |
| 3 | Tres. Arriesga para sobrevivir, no para pasar en dos días. La prisa sale cara. Tamaño pequeño, stop siempre puesto. | 19 |
| 4 | Cuatro. ¿Suspendes? Antes del segundo intento, revisa tus errores. Y no subas el riesgo para recuperar. | 16 |
| 5 | Cinco. Pasar no es cobrar. Protege la cuenta fondeada. Mismo plan, mismo riesgo, hasta el primer payout. | 17 |
| CTA + loop | Sígueme para más y entra en la comunidad. Porque con mil euros, la clave es no quemarlos. | 17 |

Dirección de locución: ritmo rápido pero sin atropellar, pausa corta (~0,15 s) tras cada número ("Uno.", "Dos."…).
Tono de colega, sin énfasis de vendedor. La última frase se dice cayendo, para que empalme con "Tienes mil euros…" al reiniciar.

---

## 2. STYLE LOCK (propuesta)

### Paleta (4 hex)

| Token | Hex | Uso | Contraste vs fondo |
|---|---|---|---|
| `bg` | `#0B0F14` | Fondo único de todo el vídeo | — |
| `ink` | `#F4F4EF` | Texto, subtítulos, ejes | 17,4 : 1 |
| `lime` | `#C6FF3D` | Palabra activa del subtítulo, velas alcistas, "correcto", números de punto | 16,3 : 1 |
| `red` | `#FF4D4D` | Velas bajistas, límites/drawdown, tachados, "error" | 5,9 : 1 |

Reglas: nada de degradados de color; solo opacidades de estos 4 tonos (p. ej. rejilla de fondo `ink` al 6 %).
Rojo nunca para texto pequeño (<48 px); en tamaño pequeño, rojo solo en formas/líneas.

### Tipografía: **Archivo** (Google Fonts, OFL)

| Rol | Peso | Tamaño | Notas |
|---|---|---|---|
| Números héroe ("1.000 €" / "01"–"05") | 900 Black | 190 px / 260 px | `font-variant-numeric: tabular-nums` para contadores sin baile |
| Titular de plano | 800 ExtraBold | 84–96 px | Mayúsculas, tracking −1 % |
| Subtítulos | 800 ExtraBold | 76 px, interlineado 1,1 | Frase normal (no mayúsculas), máx. 2 líneas, ≤18 caracteres/línea |
| Etiquetas de gráfico | 600 SemiBold | 40–44 px | Mayúsculas, tracking +4 % |
| Disclaimer | 600 SemiBold | 50 px, interlineado 1,25 | `ink` al 100 %, sin animación de letras |

Formato numérico español: `1.000 €` (punto de millar, espacio antes de €).

### Fotogramas de muestra

`styleframes/hook.png` (frame 0), `styleframes/hook_safezones.png` (el mismo, con las zonas prohibidas en rojo) y `styleframes/disc.png` (P22, que es también el último frame del loop). Medido: todo el texto queda dentro de x 84–897 / y 297–1396.

### Zonas seguras y rejilla (1080×1920)

```
y=0    ┌──────────────────────────────┐
       │  250 px  — NO contenido      │  (solo textura de fondo)
y=250  ├──┬────────────────────┬──────┤
       │80│  ZONA A  y 270–560 │ 180  │  número de punto / titular
       │px│  ZONA B  y 600–1120│  px  │  gráfico / forma principal
       │  │  ZONA C  y1160–1460│      │  subtítulos (2 líneas máx.)
y=1500 ├──┴────────────────────┴──────┤
       │  420 px  — NO contenido      │  (caption, audio, perfil)
y=1920 └──────────────────────────────┘
       Caja útil: x 80–900 (820 px) · y 250–1500 (1.250 px)
       Eje central de composición: x = 490 (no 540)
```

- Todo lo legible y todo elemento clave dentro de la caja útil. Fuera solo textura (rejilla, velas al 8 % de opacidad).
- Subtítulos centrados en x = 490, línea base inferior en y ≈ 1440.

### Subtítulos palabra a palabra

- Cada palabra aparece en el frame exacto en que empieza en el audio (pop 0→100 % en 3 frames, escala 0,92→1).
- Palabra activa en `lime`; las ya dichas en `ink`. Bloques de 2–4 palabras; el bloque se limpia al cambiar de frase.
- "mil euros" se muestra como **1.000 €**, "dos días" como **2 días**, números de punto como **1.**, **2.**…
- Sin caja de fondo (el fondo ya es oscuro); contorno `bg` de 6 px para cuando pasen sobre gráficos.

### Movimiento

- Entradas: slide 40 px + fade, 6 frames, easing `cubic-bezier(.2,.8,.2,1)`.
- Cortes secos entre planos (sin transiciones largas); cambio visual cada 1,6–2,2 s.
- Contadores: interpolación en 12–18 frames, siempre con `tabular-nums`.
- Velas: generadas por código (paseo aleatorio con semilla fija → reproducible), sin eje de precios ni tickers reales.

### Prohibido

Lambos, billetes, monedas, "dinero fácil", cifras de ganancias o de payout, logos o nombres de prop firms, stock, logo propio al inicio.

---

## 3. Tabla de planos

Frames a 30 fps. "Texto en pantalla" = rótulo gráfico (además de los subtítulos, que van siempre en Zona C salvo en P22).

| # | Tiempo (s) | Frames | VO | Visual (todo generado en código) | Texto en pantalla (Zona A/B) |
|---|---|---|---|---|---|
| P01 | 0,0–1,8 | 0–54 | Tienes mil euros para prop firms. | **Frame 0 ya cargado** (sin fade): "1.000 €" gigante en `ink` centrado en Zona B, velas de fondo al 8 %. En 1,0 s el contador empieza a bajar y tiembla. | TIENES 1.000 € PARA PROP FIRMS |
| P02 | 1,8–3,6 | 54–108 | Así no los quemas. | Vela roja enorme cae; contador se desploma 1.000 → 0 € en `red`… y rebobina de golpe a 1.000 € (efecto rewind 8 frames). | ASÍ NO LOS QUEMAS |
| P03 | 3,6–5,4 | 108–162 | Uno. Reparte el presupuesto. | "01" en `lime` entra en Zona A. El bloque "1.000 €" se parte en 4 barras iguales. | REPARTE EL PRESUPUESTO |
| P04 | 5,4–7,4 | 162–222 | Compra con descuento | Etiqueta de precio genérica: "PRECIO" tachado en `red`, aparece "−%" en `lime` (sin cifra concreta). | COMPRA CON DESCUENTO |
| P05 | 7,4–9,4 | 222–282 | y no lo gastes todo en el mismo mes. | Calendario de 4 columnas (MES 1–4): una barra alta solo en MES 1 se tacha en `red`; se redistribuye en 4 barras bajas `lime`. | NO TODO EN UN MES |
| P06 | 9,4–11,2 | 282–336 | Dos. Primero, las reglas: | "02" en Zona A. Portapapeles/checklist de 3 casillas vacías dibujado con líneas. | PRIMERO, LAS REGLAS |
| P07 | 11,2–13,6 | 336–408 | drawdown, límite diario y consistencia. | Tres tarjetas entran una por palabra (≈0,7 s cada una, cada entrada es un cambio visual): ① curva de equity con suelo discontinuo rojo, ② barras diarias con techo rojo, ③ barras regulares con una barra pico marcada. | DRAWDOWN · LÍMITE DIARIO · CONSISTENCIA |
| P08 | 13,6–15,6 | 408–468 | Si no las conoces, la cuenta dura un día. | Velas rápidas caen hasta tocar la línea de drawdown; la tarjeta "CUENTA" se pone en `red` y recibe sello "CERRADA". | 1 DÍA |
| P09 | 15,6–17,4 | 468–522 | Tres. Arriesga para sobrevivir, | "03" en Zona A. Dial de riesgo semicircular, aguja en zona baja `lime`. | RIESGO PARA SOBREVIVIR |
| P10 | 17,4–19,2 | 522–576 | no para pasar en dos días. | Pantalla dividida: izquierda "2 DÍAS" con aguja al máximo, tachado `red`; derecha línea de equity suave y larga avanzando. | ~~PASAR EN 2 DÍAS~~ |
| P11 | 19,2–20,8 | 576–624 | La prisa sale cara. | 5 fichas cuadradas = intentos del presupuesto; una se vuelve `red` y se desintegra en píxeles. | LA PRISA SALE CARA |
| P12 | 20,8–22,4 | 624–672 | Tamaño pequeño, stop siempre puesto. | Vela con línea de stop horizontal `red` fija bajo ella; icono de "contrato" pequeño (1 bloque) en `lime`. | TAMAÑO PEQUEÑO · STOP PUESTO |
| P13 | 22,4–24,2 | 672–726 | Cuatro. ¿Suspendes? | "04" en Zona A. Tarjeta "EVALUACIÓN" con banda `red` "NO SUPERADA"; se gira y aparece "INTENTO 2". | INTENTO 2 |
| P14 | 24,2–26,4 | 726–792 | Antes del segundo intento, revisa tus errores. | Diario de trading: 3 líneas aparecen y se marcan con ✓ `lime`: "Operar tras pérdida", "Saltarme el límite diario", "Sobreoperar". | REVISA TUS ERRORES |
| P15 | 26,4–28,2 | 792–846 | Y no subas el riesgo para recuperar. | Slider de riesgo empujado hacia arriba (se pone `red`) y rebota a su sitio en `lime`. | MISMO RIESGO |
| P16 | 28,2–30,0 | 846–900 | Cinco. Pasar no es cobrar. | "05" en Zona A. "PASAR" y "COBRAR" con el signo "≠" que se dibuja entre ambos. | PASAR ≠ COBRAR |
| P17 | 30,0–31,8 | 900–954 | Protege la cuenta fondeada. | Escudo de líneas alrededor de la tarjeta "CUENTA FONDEADA"; velas rojas rebotan en el escudo. | PROTEGE LA FONDEADA |
| P18 | 31,8–34,0 | 954–1020 | Mismo plan, mismo riesgo, hasta el primer payout. | Barra de progreso hacia "1.er PAYOUT" (sin importes) con dos checks "MISMO PLAN" / "MISMO RIESGO". | HASTA EL 1.er PAYOUT |
| P19 | 34,0–36,0 | 1020–1080 | Sígueme para más | Recap: rejilla 5 iconos de los puntos (barras, checklist, dial, diario, escudo) se encienden en secuencia. | SÍGUEME PARA MÁS |
| P20 | 36,0–37,6 | 1080–1128 | y entra en la comunidad. | Los 5 iconos se convierten en nodos conectados (red de puntos = comunidad). | ÚNETE A LA COMUNIDAD |
| P21 | 37,6–39,6 | 1128–1188 | Porque con mil euros, la clave es no quemarlos. | Los nodos se funden de vuelta en "1.000 €", **misma posición, tamaño y color que en P01**. | LA CLAVE: NO QUEMARLOS |
| P22 | 39,6–43,2 | 1188–1296 | (sin VO) | **Disclaimer.** "1.000 €" se mantiene arriba (Zona B superior, igual que frame 0) y abajo, en Zona C, el disclaimer fijo. A los 41,4 s las velas de fondo se redibujan (cambio visual sin tocar el texto). Último frame ≈ frame 0 → loop limpio. | Contenido educativo. No es asesoramiento financiero. La mayoría de traders no supera las evaluaciones. |

**Loop:** el VO termina en "…la clave es no quemarlos" y al reiniciar arranca "Tienes mil euros para prop firms. Así no los quemas". El "1.000 €" ocupa el mismo sitio en P21–P22 y en P01, así que el salto al principio no se nota.

**Disclaimer:** 3,6 s (más de los 2 s mínimos, porque 17 palabras a 50 px necesitan ~3 s para leerse), 50 px SemiBold, `ink` sobre `bg`, dentro de la caja útil, sin animación de letras.

---

## 4. Pendiente de confirmar

1. **Aprobar** la paleta, la fuente y la tabla de planos.
2. **Referencia:** el adjunto no llegó; si debe marcar el estilo, reenvíalo y ajusto el STYLE LOCK antes de producir.
3. **Locución:** ¿la grabas tú o se usa TTS temporal para el montaje? Con el audio real se ajustan los tiempos palabra a palabra.
4. **Música:** el render sale con la VO sola; la música se añade en Instagram (audio en tendencia), con la VO por encima.
5. **Comunidad:** ¿nombre o @ de la comunidad para P20? Si no hay, se queda en "Únete a la comunidad" + "link en bio".
