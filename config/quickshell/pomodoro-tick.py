#!/usr/bin/env python3
# Genera el "tic-tac" del pomodoro: 60 s de wav con un tic (agudo) y un tac
# (grave) alternados cada segundo, suaves. Lo llama Pomodoro.qml si falta.
# Uso: pomodoro-tick.py <salida.wav>
import array, math, os, sys, wave

out = sys.argv[1]
sr, secs = 22050, 60
buf = array.array("h", [0] * (sr * secs))
for s in range(secs):
    freq = 1700 if s % 2 == 0 else 1150
    n = int(sr * 0.035)
    for i in range(n):
        v = math.sin(2 * math.pi * freq * i / sr) * math.exp(-i / (sr * 0.008))
        buf[s * sr + i] = int(v * 0.35 * 32767)
os.makedirs(os.path.dirname(out), exist_ok=True)
with wave.open(out, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sr)
    w.writeframes(buf.tobytes())
