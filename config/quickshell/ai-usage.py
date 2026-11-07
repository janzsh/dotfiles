#!/usr/bin/env python3
"""Colector de consumo de tokens para AiUsage.qml. Imprime un JSON por stdout.

Claude Code: suma el campo `usage` de cada mensaje del asistente en
~/.claude/projects/**/*.jsonl (deduplicado por id de mensaje).
Antigravity (agy): ~/.gemini/antigravity-cli/conversations/*.db (sqlite). Esas
bases no guardan un contador de tokens en claro; se reporta actividad
(conversaciones y pasos) y tokens solo si `gen_metadata` trae filas legibles.
"""
import glob, json, os, sqlite3, sys
from collections import defaultdict
from datetime import datetime, timedelta

HOME = os.path.expanduser("~")
DAYS = 14
now = datetime.now()
since = (now - timedelta(days=DAYS - 1)).replace(hour=0, minute=0, second=0, microsecond=0)


def day_key(dt):
    return dt.strftime("%Y-%m-%d")


def empty():
    return {"in": 0, "out": 0, "cr": 0, "cw": 0, "msgs": 0}


def add(acc, u):
    acc["in"] += u.get("input_tokens", 0) or 0
    acc["out"] += u.get("output_tokens", 0) or 0
    acc["cr"] += u.get("cache_read_input_tokens", 0) or 0
    acc["cw"] += u.get("cache_creation_input_tokens", 0) or 0
    acc["msgs"] += 1


def claude():
    days = defaultdict(empty)
    hours = defaultdict(empty)      # solo hoy
    models = defaultdict(empty)
    projects = defaultdict(empty)
    window = empty()                # últimas 5 h (ventana de límite de uso)
    seen = set()
    t5 = now - timedelta(hours=5)
    for f in glob.glob(HOME + "/.claude/projects/*/**/*.jsonl", recursive=True):
        try:
            if datetime.fromtimestamp(os.path.getmtime(f)) < since:
                continue
            proj = f.split("/.claude/projects/")[1].split("/")[0]
            proj = proj.replace("-home-janz-", "~/").replace("-", "/") if proj.startswith("-home-janz-") else proj
            with open(f, errors="replace") as fh:
                for line in fh:
                    if '"usage"' not in line:
                        continue
                    try:
                        o = json.loads(line)
                    except ValueError:
                        continue
                    m = o.get("message") or {}
                    u = m.get("usage")
                    ts = o.get("timestamp")
                    if not u or not ts or o.get("type") != "assistant":
                        continue
                    key = (m.get("id"), o.get("requestId"))
                    if key in seen:
                        continue
                    seen.add(key)
                    dt = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().replace(tzinfo=None)
                    if dt < since:
                        continue
                    add(days[day_key(dt)], u)
                    add(models[m.get("model") or "?"], u)
                    add(projects[proj], u)
                    if dt.date() == now.date():
                        add(hours[dt.hour], u)
                    if dt >= t5:
                        add(window, u)
        except OSError:
            continue
    series = []
    for i in range(DAYS):
        k = day_key(since + timedelta(days=i))
        series.append(dict(day=k, **days.get(k, empty())))
    return {
        "days": series,
        "hours": [dict(hour=h, **hours.get(h, empty())) for h in range(24)],
        "models": sorted(({"name": k, **v} for k, v in models.items()), key=lambda x: -(x["in"] + x["out"] + x["cr"] + x["cw"])),
        "projects": sorted(({"name": k, **v} for k, v in projects.items()), key=lambda x: -(x["in"] + x["out"] + x["cr"] + x["cw"]))[:6],
        "window5h": window,
    }


def agy():
    days = defaultdict(lambda: {"convs": 0, "steps": 0, "tokens": 0})
    total_tokens = 0
    convs = 0
    base = HOME + "/.gemini/antigravity-cli/conversations/*.db"
    for f in glob.glob(base):
        try:
            mt = datetime.fromtimestamp(os.path.getmtime(f))
            c = sqlite3.connect("file:%s?mode=ro" % f, uri=True)
            steps = c.execute("select count(*) from steps").fetchone()[0]
            gen = c.execute("select count(*) from gen_metadata").fetchone()[0]
            c.close()
        except (sqlite3.Error, OSError):
            continue
        convs += 1
        if mt >= since:
            d = days[day_key(mt)]
            d["convs"] += 1
            d["steps"] += steps
        # gen_metadata: formato protobuf sin documentar; con 0 filas no hay nada que leer.
        _ = gen
    series = []
    for i in range(DAYS):
        k = day_key(since + timedelta(days=i))
        series.append(dict(day=k, **days.get(k, {"convs": 0, "steps": 0, "tokens": 0})))
    # Sesión: el último log manda. "not logged in" al arrancar es transitorio;
    # cuenta "authenticated successfully" posterior (auth vía keyring).
    logged = False
    try:
        txt = open(sorted(glob.glob(HOME + "/.gemini/antigravity-cli/log/cli-*.log"))[-1], errors="replace").read()
        logged = txt.rfind("authenticated successfully") > txt.rfind("not logged in")
    except (IndexError, OSError):
        pass
    return {"days": series, "conversations": convs, "tokensAvailable": total_tokens > 0, "loggedIn": logged}


json.dump({"updated": now.isoformat(timespec="seconds"), "claude": claude(), "agy": agy()}, sys.stdout)
