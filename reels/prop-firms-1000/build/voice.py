"""Genera la locución sintética (Piper es_ES vía sherpa-onnx) y los tiempos palabra a palabra.

Cada frase (= un plano) se sintetiza por separado, se recorta el silencio y se concatena.
Los tiempos de palabra se reparten por sílabas dentro de cada grupo entre pausas detectadas
en el audio. Salida: out/vo.wav y build/timing.json.

Uso: python3 build/voice.py /ruta/al/modelo-piper
"""
import glob, json, re, sys
from pathlib import Path

import numpy as np
import sherpa_onnx
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
SPEED = 1.12          # >1 = más rápido
GAP = 0.14            # silencio entre frases (s)
MIN_SHOT = 1.55       # duración mínima de plano (s)
LEAD_IN = 0.05        # el gancho empieza casi en el frame 0
DISCLAIMER = 3.6      # último plano, sin voz

# Palabras: "texto en pantalla|texto para la voz" cuando difieren.
SHOTS = [
    ("hook",   "Tienes {1.000 €|mil euros} para {prop|prop} {firms.|férms.}"),
    ("burn",   "Así no los quemas."),
    ("p1a",    "{Uno.|Uno:} {Reparte|reparte} el presupuesto."),
    ("p1b",    "{Compra|Compra,} con {descuento|descuento.}"),
    ("p1c",    "y no lo gastes todo en el mismo mes."),
    ("p2a",    "{Dos.|Dos:} {Primero,|primero,} las reglas."),
    ("p2b",    "{drawdown,|dráudaun,} límite diario y consistencia."),
    ("p2c",    "Si no las conoces, la cuenta dura un día."),
    ("p3a",    "{Tres.|Tres:} {Arriesga|arriesga} para sobrevivir,"),
    ("p3b",    "no para pasar en {2|dos} días."),
    ("p3c",    "La prisa sale cara."),
    ("p3d",    "Tamaño pequeño, {stop|stop,} siempre puesto."),
    ("p4a",    "Cuatro. ¿Suspendes?"),
    ("p4b",    "Antes del segundo intento, revisa tus errores."),
    ("p4c",    "Y no subas el riesgo para recuperar."),
    ("p5a",    "Cinco. Pasar no es cobrar."),
    ("p5b",    "Protege la cuenta fondeada."),
    ("p5c",    "Mismo plan, mismo riesgo, hasta el primer {payout.|payaut.}"),
    ("follow", "Sígueme para más."),
    ("loop",   "Porque con {1.000 €,|mil euros,} la clave es no quemarlos."),
]


def tokens(spec):
    """[(display, tts)] respetando los grupos {display|tts}."""
    out = []
    for m in re.finditer(r"\{([^|}]*)\|([^}]*)\}|(\S+)", spec):
        out.append((m.group(1), m.group(2)) if m.group(3) is None else (m.group(3), m.group(3)))
    return out


def syllables(word):
    w = re.sub(r"[^a-záéíóúüñ]", "", word.lower())
    return max(1, len(re.findall(r"[aeiouáéíóúü]+", w)))


def trim(x, sr, thr=0.006):
    idx = np.where(np.abs(x) > thr)[0]
    if not len(idx):
        return x
    return x[max(0, idx[0] - int(0.03 * sr)): idx[-1] + int(0.05 * sr)]


def pauses(x, sr, min_len=0.07, thr=0.015):
    """Centros (s) y duración de silencios internos."""
    hop = int(0.01 * sr)
    env = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2)) for i in range(0, len(x) - hop, hop)])
    quiet = env < thr
    res, start = [], None
    for i, q in enumerate(quiet):
        if q and start is None:
            start = i
        if not q and start is not None:
            if (i - start) * 0.01 >= min_len and start > 3:
                res.append(((start + i) / 2 * 0.01, (i - start) * 0.01, start * 0.01, i * 0.01))
            start = None
    return res


def word_times(toks, x, sr):
    dur = len(x) / sr
    # grupos separados por puntuación
    groups, cur = [], []
    for i, (d, _) in enumerate(toks):
        cur.append(i)
        if re.search(r"[,.:;?!]$", d) and i < len(toks) - 1:
            groups.append(cur); cur = []
    groups.append(cur)
    ps = sorted(pauses(x, sr), key=lambda p: -p[1])[: len(groups) - 1]
    ps = sorted(ps)
    if len(ps) != len(groups) - 1:   # sin pausas fiables: un solo bloque
        groups, ps = [list(range(len(toks)))], []
    bounds = [0.0] + [v for p in ps for v in (p[2], p[3])] + [dur]
    times = [None] * len(toks)
    for g, grp in enumerate(groups):
        a, b = bounds[2 * g], bounds[2 * g + 1]
        w = [syllables(toks[i][1]) + 0.6 for i in grp]
        tot, acc = sum(w), a
        for i, wi in zip(grp, w):
            seg = (b - a) * wi / tot
            times[i] = (acc, acc + seg)
            acc += seg
    return times


def main():
    mdir = sys.argv[1]
    onnx = glob.glob(f"{mdir}/*.onnx")[0]
    tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(
            vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                model=onnx, tokens=f"{mdir}/tokens.txt", data_dir=f"{mdir}/espeak-ng-data"),
            num_threads=4)))
    sr = tts.sample_rate
    audio, shots, t = [np.zeros(int(LEAD_IN * sr), np.float32)], [], LEAD_IN
    for sid, spec in SHOTS:
        toks = tokens(spec)
        a = tts.generate(" ".join(v for _, v in toks), sid=0, speed=SPEED)
        x = trim(np.array(a.samples, np.float32), sr)
        wt = word_times(toks, x, sr)
        vo = len(x) / sr
        length = max(vo + GAP, MIN_SHOT)
        start = 0.0 if not shots else t
        shots.append({
            "id": sid, "start": round(start, 3), "end": round(t + length, 3), "voEnd": round(t + vo, 3),
            "words": [{"text": d, "start": round(t + s, 3), "end": round(t + e, 3)}
                      for (d, _), (s, e) in zip(toks, wt)],
        })
        audio += [x, np.zeros(int(round((length - vo) * sr)), np.float32)]
        t += length
    shots.append({"id": "disclaimer", "start": round(t, 3), "end": round(t + DISCLAIMER, 3), "words": []})
    audio.append(np.zeros(int(DISCLAIMER * sr), np.float32))
    y = np.concatenate(audio)
    (ROOT / "out").mkdir(exist_ok=True)
    sf.write(ROOT / "out" / "vo_raw.wav", y, sr)
    total = round(t + DISCLAIMER, 3)
    json.dump({"fps": 30, "duration": total, "shots": shots},
              open(ROOT / "build" / "timing.json", "w"), ensure_ascii=False, indent=1)
    print(f"total {total}s, palabras {sum(len(s['words']) for s in shots)}")
    for s in shots:
        print(f"{s['id']:10s} {s['start']:6.2f}-{s['end']:6.2f} ({s['end']-s['start']:.2f}s)")


if __name__ == "__main__":
    main()
