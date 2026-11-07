#!/usr/bin/env python3
"""Colector de consumo de tokens para AiUsage.qml. Imprime un JSON por stdout.

Claude Code: suma el campo `usage` de cada mensaje del asistente en
~/.claude/projects/**/*.jsonl (deduplicado por id de mensaje).
Antigravity (agy): ~/.gemini/antigravity-cli/conversations/*.db (sqlite). Esas
bases no guardan contadores de tokens legibles; se reporta actividad
(conversaciones y pasos, agrupados por última modificación de la conversación).
Codex: diferencias entre contadores acumulados en ~/.codex/sessions/**/*.jsonl
y ~/.codex/archived_sessions/**/*.jsonl; se muestra el último límite registrado.
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
    window = empty()                # actividad durante las últimas 5 h
    seen = set()
    t5 = now - timedelta(hours=5)
    for f in glob.glob(HOME + "/.claude/projects/*/**/*.jsonl", recursive=True):
        try:
            if datetime.fromtimestamp(os.path.getmtime(f)) < since:
                continue
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
        "window5h": window,
    }


def codex():
    days = defaultdict(empty)
    limits, limits_ts = None, None
    files = glob.glob(HOME + "/.codex/sessions/**/*.jsonl", recursive=True)
    files += glob.glob(HOME + "/.codex/archived_sessions/**/*.jsonl", recursive=True)
    for f in files:
        previous = {"input_tokens": 0, "cached_input_tokens": 0, "output_tokens": 0}
        try:
            if datetime.fromtimestamp(os.path.getmtime(f)) < since:
                continue
            with open(f, errors="replace") as fh:
                for line in fh:
                    if '"token_count"' not in line:
                        continue
                    try:
                        o = json.loads(line)
                        p = o.get("payload") or {}
                        if p.get("type") != "token_count":
                            continue
                        dt = datetime.fromisoformat(o["timestamp"].replace("Z", "+00:00")).astimezone().replace(tzinfo=None)
                        rate = p.get("rate_limits")
                        if rate and (limits_ts is None or dt > limits_ts):
                            limits, limits_ts = rate, dt
                        usage = (p.get("info") or {}).get("total_token_usage")
                        if not usage:
                            continue
                        current = {k: max(0, int(usage.get(k, 0) or 0)) for k in previous}
                        # Un contador reiniciado inicia una nueva secuencia.
                        if any(current[k] < previous[k] for k in current):
                            previous = {k: 0 for k in previous}
                        delta = {k: current[k] - previous[k] for k in current}
                        previous = current
                        if dt < since or not any(delta.values()):
                            continue
                        u = {"input_tokens": max(0, delta["input_tokens"] - delta["cached_input_tokens"]),
                             "cache_read_input_tokens": delta["cached_input_tokens"],
                             "output_tokens": delta["output_tokens"]}
                        add(days[day_key(dt)], u)
                    except (ValueError, TypeError, KeyError, OverflowError):
                        continue
        except OSError:
            continue
    return {
        "days": [dict(day=day_key(since + timedelta(days=i)), **days.get(day_key(since + timedelta(days=i)), empty())) for i in range(DAYS)],
        "limits": limits,
        "limitsUpdated": limits_ts.isoformat(timespec="seconds") if limits_ts else None,
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


json.dump({"updated": now.isoformat(timespec="seconds"), "claude": claude(), "agy": agy(), "codex": codex()}, sys.stdout)
