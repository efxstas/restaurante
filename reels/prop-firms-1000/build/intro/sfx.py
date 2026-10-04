"""Efectos de sonido del intro generados por código (sin assets): teclado, envío, mensaje y whoosh.
Lee build/intro/timeline.json y escribe out/intro_sfx.wav (48 kHz, estéreo)."""
import json
from pathlib import Path
import numpy as np, soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
TL = json.load(open(ROOT / "build/intro/timeline.json"))
SR = 48000
N = int(TL["duration"] * SR)
out = np.zeros(N, np.float32)
rng = np.random.default_rng(3)

def add(t, x, gain=1.0):
    i = int(max(0, t) * SR); x = x[: max(0, N - i)]; out[i:i + len(x)] += gain * x

def env(n, a=0.002, d=0.05):
    t = np.arange(n) / SR
    return np.minimum(1, t / a) * np.exp(-t / d)

def click():
    n = int(0.035 * SR); noise = rng.standard_normal(n)
    hp = np.diff(noise, prepend=0)                       # agudo, "tecla"
    body = np.sin(2 * np.pi * rng.uniform(1800, 2600) * np.arange(n) / SR)
    return (0.6 * hp + 0.4 * body) * env(n, 0.0008, 0.008)

def tone(f0, f1, dur, d=0.06):
    n = int(dur * SR); t = np.arange(n) / SR
    f = np.linspace(f0, f1, n); ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env(n, 0.003, d)

def whoosh(dur):
    n = int(dur * SR); noise = rng.standard_normal(n); y = np.zeros(n); a = 0.0
    cut = np.linspace(0.02, 0.35, n)                     # filtro paso bajo que se abre
    for i in range(n):
        a += cut[i] * (noise[i] - a); y[i] = a
    shape = np.sin(np.linspace(0, np.pi, n)) ** 1.5
    return y * shape

q = TL["question"]
for k, ch in enumerate(q["text"]):
    t = q["start"] + k / q["cps"]
    if ch != " ": add(t, click(), rng.uniform(.25, .4))
add(TL["send"], tone(520, 980, .09, .05), .35)                       # enviar
add(TL["answer"][0]["start"], tone(880, 880, .14, .07) + .6 * tone(1320, 1320, .14, .06), .16)  # mensaje recibido
hz = TL.get("hate")
if hz:
    n = int(.35 * SR); tt = np.arange(n) / SR
    add(hz["stamp"], np.sin(2*np.pi*np.linspace(140, 45, n)*tt) * np.exp(-tt/.09) + .3*rng.standard_normal(n)*np.exp(-tt/.02), .7)  # sello
    add(hz["photo"], tone(660, 990, .12, .06), .2)
    add(hz["flip"] - .1, whoosh(.45), .35)                                       # giro de la foto
    add(hz["flip"] + .25, tone(330, 220, .3, .15), .25)                          # "realidad"
    add(hz["final"], tone(880, 880, .14, .07) + .6 * tone(1320, 1320, .14, .06), .18)
st = next(a for a in TL["answer"] if a["type"] == "stacks")
for k in range(10):
    add(st["start"] + .15 + k * st["dur"] * .75 / 10, tone(700 + 60 * k, 760 + 60 * k, .05, .025), .12)
roi = TL["answer"][-1]
add(roi["start"] + roi["text"].split(" ").index("2x") / roi["wps"], tone(660, 1320, .18, .1), .22)
w0, w1 = TL["wipe"]
add(w0 - .25, whoosh(w1 - w0 + .45), .5)

out /= max(1e-6, np.abs(out).max()) / 0.7
sf.write(ROOT / "out/intro_sfx.wav", np.stack([out, out], 1), SR)
print("ok", round(N / SR, 2), "s")
