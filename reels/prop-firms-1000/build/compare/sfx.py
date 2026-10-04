"""Efectos de sonido del clip gurú vs trader (generados por código). Escribe out/compare_sfx.wav."""
import json, sys
from pathlib import Path
import numpy as np, soundfile as sf
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "intro"))
ROOT = Path(__file__).resolve().parents[2]
TL = json.load(open(ROOT / "build/compare/timeline.json"))
SR = 48000; N = int(TL["duration"] * SR); out = np.zeros(N, np.float32); rng = np.random.default_rng(5)
def add(t, x, g=1.0):
    i = int(max(0, t) * SR); x = x[: max(0, N - i)]; out[i:i + len(x)] += g * x
def env(n, a=.003, d=.06):
    t = np.arange(n) / SR; return np.minimum(1, t / a) * np.exp(-t / d)
def tone(f0, f1, dur, d=.06):
    n = int(dur * SR); ph = 2 * np.pi * np.cumsum(np.linspace(f0, f1, n)) / SR; return np.sin(ph) * env(n, .003, d)
def thud(dur=.3):
    n = int(dur * SR); t = np.arange(n) / SR
    return np.sin(2*np.pi*np.linspace(150, 50, n)*t) * np.exp(-t/.08) + .25*rng.standard_normal(n)*np.exp(-t/.015)
def whoosh(dur):
    n = int(dur * SR); x = rng.standard_normal(n); y = np.zeros(n); a = 0.0
    for i, c in enumerate(np.linspace(.02, .3, n)): a += c * (x[i] - a); y[i] = a
    return y * np.sin(np.linspace(0, np.pi, n)) ** 1.5
g, s, f = TL["guru"], TL["trader"], TL["final"]
for sec in (g, s): add(sec["start"], thud(), .6)
for k in range(10):
    add(g["tiles"] + k*.05, tone(700, 760, .05, .02), .08); add(s["tiles"] + k*.05, tone(700, 760, .05, .02), .08)
for k in range(9): add(g["burn"] + k*.2, tone(300, 150, .12, .05) + .3*rng.standard_normal(int(.12*SR))*env(int(.12*SR), .001, .02), .18)
add(g["burn"] + 1.9, tone(880, 1320, .15, .08), .2)
add(g["payout"], tone(660, 990, .12, .06), .22)
for sec in (g, s):
    for i in range(4): add(sec["ledger"] + .35 + i*.32, tone(520 + 80*i, 520 + 80*i, .08, .04), .14)
add(g["ledger"] + .35 + 3*.32, tone(300, 200, .3, .15), .25)
add(s["trade"] - .15, whoosh(.4), .3); add(s["certs"] + .2, tone(990, 990, .12, .06), .2); add(s["certs"] + .8, tone(1180, 1180, .12, .06), .2)
add(s["ledger"] + .35 + 3*.32, tone(660, 1320, .25, .12), .25)
add(f["start"] - .2, whoosh(.45), .3); add(f["start"] + 1.6, tone(660, 1320, .25, .12), .22)
out /= max(1e-6, np.abs(out).max()) / .7
sf.write(ROOT / "out/compare_sfx.wav", np.stack([out, out], 1), SR); print("ok")
