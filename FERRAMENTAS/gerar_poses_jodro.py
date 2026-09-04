#!/usr/bin/env python3
"""
gerar_poses_jodro.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto JODRO.

    python3 FERRAMENTAS/gerar_poses_jodro.py

TRÊS SEQUÊNCIAS POR TOOL — 21 no conjunto

    É o primeiro conjunto com três habilidades por Tool, então é o primeiro com
    três sequências por `Poses.lua`. A regra 6 vale igual: quem lidera a
    primária é a junta que faz o gesto, e a Extra pode liderar por outra.

AUTORAL, PELA `GRAMATICA_R6.md`

    Não há modelo de origem: ninguém mandou animação de meme. Então tudo aqui é
    escrito, e a gramática é o que impede a coisa virar pose aleatória —

      1. golpe rápido entre 0.8 e 1.2 s
      2. o impacto cai na METADE da sequência, não no fim
      3. combo inverte para 35:65
      7. estas animações são 40–90%% PARADAS: o que lê como força é a pausa
         antes do golpe, não a quantidade de quadros

    Meme não é desculpa para animação frouxa. A leitura cômica vem do
    ENQUADRAMENTO da pose (o martelo alto demais, o dedo apontado parado), e
    isso exige a mesma pausa que um golpe sério.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")


def J(x, y, z, rx=0, ry=0, rz=0):
    return (x, y, z, rx, ry, rz)


def P(nome, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=nome, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.05, -0.22, 18, 4, 4),
        "LeftArm": J(-1.48, 0.05, -0.22, 18, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },

    # ── BONK ───────────────────────────────────────────────────────────
    # o martelo sobe reto acima da cabeça e desce a prumo
    "MARTELO_ERGUE": {
        "RightArm": J(1.44, 0.72, -0.1, 168, -8, -18),
        "LeftArm": J(-1.46, 0.1, -0.28, 26, 8, 12),
        "Head": J(0, 1.5, 0, -14, 6, 0),
        "HRP": J(0, 0.05, 0, -9, -8, 0),
    },
    "MARTELO_BATE": {
        "RightArm": J(1.46, -0.12, -0.96, 40, -8, -4),
        "LeftArm": J(-1.4, 0, -0.42, 38, 14, 20),
        "Head": J(0, 1.5, 0, 18, -4, 0),
        "HRP": J(0, -0.14, 0, 20, 6, 0),
        "RightLeg": J(0.5, -1.86, -0.3, -16, 0, 0),
    },
    # o mega bonk é a DUAS mãos, e o corpo inteiro entra
    "MARTELO_MEGA": {
        "RightArm": J(1.4, 0.86, 0.04, 176, -6, -14),
        "LeftArm": J(-1.4, 0.86, 0.04, 176, 6, 14),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.16, 0, -20, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.14, 9, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.14, 9, 0, 0),
    },
    "MARTELO_QUEDA": {
        "RightArm": J(1.42, -0.3, -0.8, 22, -6, -4),
        "LeftArm": J(-1.42, -0.3, -0.8, 22, 6, 4),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.4, 0, 30, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.5, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.6, -0.5, -36, 0, 0),
    },

    # ── APONTAR ─ serve à Cadeia, à Troca e à Encomenda ──────────────────
    "APONTA": {
        "RightArm": J(1.52, 0.36, -1.18, 90, -6, -4),
        "LeftArm": J(-1.44, 0.06, -0.28, 26, 8, 10),
        "Head": J(0, 1.5, 0, -4, -8, 0),
        "HRP": J(0, 0.02, 0, -3, 12, 0),
    },
    "APONTA_CEU": {
        "RightArm": J(1.44, 0.84, -0.04, 168, -8, -14),
        "LeftArm": J(-1.46, 0.08, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -36, 0, 0),
        "HRP": J(0, 0.1, 0, -15, 0, 0),
    },

    # ── CHINELO ────────────────────────────────────────────────────────
    "CHINELO_ERGUE": {
        "RightArm": J(1.4, 0.62, -0.34, 132, -22, -32),
        "LeftArm": J(-1.44, 0.08, -0.3, 28, 10, 14),
        "Head": J(0, 1.5, 0, -10, 24, 0),
        "HRP": J(0, 0.04, 0, -6, -28, 0),
    },
    "CHINELO_BATE": {
        "RightArm": J(1.5, 0.14, -1.02, 62, -36, -12),
        "LeftArm": J(-1.42, 0.02, -0.4, 34, 16, 20),
        "Head": J(0, 1.5, 0, 8, -32, 0),
        "HRP": J(0, -0.05, 0, 6, 42, 0),
        "RightLeg": J(0.5, -1.9, -0.24, -12, 0, 0),
    },
    # mãos na cintura: a mãe brava
    "BRAVA": {
        "RightArm": J(1.34, -0.05, 0.2, 8, -14, -46),
        "LeftArm": J(-1.34, -0.05, 0.2, 8, 14, 46),
        "Head": J(0, 1.5, 0, -12, 0, 0),
        "HRP": J(0, 0.04, 0, -8, 0, 0),
    },

    # ── SUSSY ──────────────────────────────────────────────────────────
    "FACA_GUARDA": {
        "RightArm": J(1.42, 0.24, -0.5, 74, -30, -20),
        "LeftArm": J(-1.44, 0.1, -0.34, 30, 10, 14),
        "Head": J(0, 1.5, 0, -8, 20, 0),
        "HRP": J(0, 0.02, 0, -5, -20, 0),
    },
    "FACA_CRAVA": {
        "RightArm": J(1.5, 0.2, -1.12, 84, -16, -6),
        "LeftArm": J(-1.4, 0.02, -0.42, 34, 14, 18),
        "Head": J(0, 1.5, 0, 6, -14, 0),
        "HRP": J(0, -0.04, 0, 7, 22, 0),
        "RightLeg": J(0.5, -1.88, -0.26, -13, 0, 0),
    },
    "AGACHA": {
        "RightArm": J(1.3, -0.34, -0.34, 26, 12, 26),
        "LeftArm": J(-1.3, -0.34, -0.34, 26, -12, -26),
        "Head": J(0, 1.5, 0, 20, 0, 0),
        "HRP": J(0, -0.62, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.5, -0.6, -44, 0, 0),
        "LeftLeg": J(-0.5, -1.5, -0.6, -44, 0, 0),
    },

    # ── CAIXA DE SOM ───────────────────────────────────────────────────
    "CAIXA_SEGURA": {
        "RightArm": J(1.42, 0.5, -0.6, 104, -18, -22),
        "LeftArm": J(-1.42, 0.5, -0.6, 104, 18, 22),
        "Head": J(0, 1.5, 0, -12, 0, 0),
        "HRP": J(0, 0.05, 0, -8, 0, 0),
    },
    "CAIXA_EMPURRA": {
        "RightArm": J(1.5, 0.42, -1.2, 96, -6, -4),
        "LeftArm": J(-1.5, 0.42, -1.2, 96, 6, 4),
        "Head": J(0, 1.5, 0, -4, 0, 0),
        "HRP": J(0, 0, 0, 4, 0, 0),
        "RightLeg": J(0.5, -1.88, -0.22, -11, 0, 0),
    },

    # ── PRIVADA ────────────────────────────────────────────────────────
    "PRIVADA_MIRA": {
        "RightArm": J(1.48, 0.44, -1.0, 96, -12, -10),
        "LeftArm": J(-1.42, 0.3, -0.6, 70, 16, 20),
        "Head": J(0, 1.5, 0, -6, -6, 0),
        "HRP": J(0, 0.02, 0, -4, 10, 0),
    },
    "PRIVADA_GIRA": {
        "RightArm": J(1.44, 0.3, -0.7, 86, -34, -26),
        "LeftArm": J(-1.44, 0.3, -0.7, 86, 34, 26),
        "Head": J(0, 1.5, 0, 0, 34, 0),
        "HRP": J(0, -0.06, 0, 6, -46, 0),
    },

    # ── POMBO ──────────────────────────────────────────────────────────
    "POMBO_BICA": {
        "RightArm": J(1.5, 0.3, -1.06, 88, -10, -6),
        "LeftArm": J(-1.44, 0.06, -0.28, 26, 8, 10),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.03, 0, 10, 6, 0),
    },
    "POMBO_SOLTA": {
        "RightArm": J(1.4, 0.7, -0.4, 140, -14, -22),
        "LeftArm": J(-1.4, 0.7, -0.4, 140, 14, 22),
        "Head": J(0, 1.5, 0, -26, 0, 0),
        "HRP": J(0, 0.1, 0, -14, 0, 0),
    },

    # ── DEU RUIM ───────────────────────────────────────────────────────
    "STONKS": {
        "RightArm": J(1.42, 0.8, -0.16, 158, -10, -18),
        "LeftArm": J(-1.42, 0.8, -0.16, 158, 10, 18),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.14, 0, -18, 0, 0),
    },
    "NOT_STONKS": {
        "RightArm": J(1.3, -0.42, -0.2, 12, 16, 30),
        "LeftArm": J(-1.3, -0.42, -0.2, 12, -16, -30),
        "Head": J(0, 1.5, 0, 30, 0, 0),
        "HRP": J(0, -0.3, 0, 24, 0, 0),
    },
}


#: Tool -> (junta que lidera, {sequencia: (natureza, passos)})
CONJUNTO = {
    "Bonk": ("RightArm", {
        "BONK": ("golpe rápido", [
            P("MARTELO_ERGUE", 0.24, "Back", "In", "CARGA"),
            P("MARTELO_ERGUE", 0.18, "Sine", "InOut"),
            P("MARTELO_BATE", 0.11, "Quint", "Out", "GOLPE"),
            P("MARTELO_BATE", 0.17, "Sine", "InOut"),
            P("IDLE", 0.26, "Quad", "Out", "FIM"),
        ]),
        "MEGA": ("golpe pesado", [
            P("MARTELO_MEGA", 0.34, "Back", "In", "CARGA"),
            P("MARTELO_MEGA", 0.52, "Sine", "InOut", "SEGURA", 0.05, 26),
            P("MARTELO_QUEDA", 0.14, "Quint", "Out", "GOLPE"),
            P("MARTELO_QUEDA", 0.26, "Sine", "InOut"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
        "CADEIA": ("conjuração", [
            P("APONTA", 0.26, "Back", "In", "CARGA"),
            P("APONTA", 0.40, "Sine", "InOut", None, 0.03, 22),
            P("APONTA", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
    }),
    "Chinelo Voador": ("RightArm", {
        "CHINELADA": ("golpe rápido", [
            P("CHINELO_ERGUE", 0.18, "Back", "In", "CARGA"),
            P("CHINELO_ERGUE", 0.13, "Sine", "InOut"),
            P("CHINELO_BATE", 0.09, "Quint", "Out", "GOLPE"),
            P("CHINELO_BATE", 0.15, "Sine", "InOut"),
            P("IDLE", 0.23, "Quad", "Out", "FIM"),
        ]),
        "TELEGUIADO": ("conjuração", [
            P("CHINELO_ERGUE", 0.22, "Back", "In", "CARGA"),
            P("CHINELO_BATE", 0.12, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
        "BRAVA": ("sustentada", [
            P("BRAVA", 0.30, "Back", "In", "CARGA"),
            P("BRAVA", 0.62, "Sine", "InOut", "SEGURA", 0.04, 20),
            P("BRAVA", 0.24, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
    }),
    "Sussy": ("RightArm", {
        "FACADA": ("golpe rápido", [
            P("FACA_GUARDA", 0.20, "Back", "In", "CARGA"),
            P("FACA_GUARDA", 0.14, "Sine", "InOut"),
            P("FACA_CRAVA", 0.09, "Quint", "Out", "GOLPE"),
            P("FACA_CRAVA", 0.16, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out", "FIM"),
        ]),
        "VENT": ("conjuração", [
            P("AGACHA", 0.26, "Back", "In", "CARGA"),
            P("AGACHA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
        "REUNIAO": ("golpe pesado", [
            P("APONTA_CEU", 0.30, "Back", "In", "CARGA"),
            P("APONTA_CEU", 0.56, "Sine", "InOut", "SEGURA", 0.05, 24),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
    }),
    "Caixa de Som": ("RightArm", {
        "ONDA": ("golpe pesado", [
            P("CAIXA_SEGURA", 0.26, "Back", "In", "CARGA"),
            P("CAIXA_SEGURA", 0.34, "Sine", "InOut", None, 0.03, 24),
            P("CAIXA_EMPURRA", 0.13, "Quint", "Out", "GOLPE"),
            P("CAIXA_EMPURRA", 0.20, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
        ]),
        "NUNCA": ("sustentada", [
            P("CAIXA_SEGURA", 0.30, "Back", "In", "CARGA"),
            P("CAIXA_SEGURA", 0.70, "Sine", "InOut", "SEGURA", 0.045, 21),
            P("CAIXA_EMPURRA", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
        "TROCA": ("conjuração", [
            P("APONTA", 0.24, "Back", "In", "CARGA"),
            P("APONTA", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
        ]),
    }),
    "Privada Sonora": ("RightArm", {
        "JATO": ("golpe pesado", [
            P("PRIVADA_MIRA", 0.24, "Back", "In", "CARGA"),
            P("PRIVADA_MIRA", 0.36, "Sine", "InOut", None, 0.035, 25),
            P("PRIVADA_MIRA", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
        ]),
        "DESCARGA": ("golpe pesado", [
            P("PRIVADA_GIRA", 0.28, "Back", "In", "CARGA"),
            P("PRIVADA_GIRA", 0.44, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("PRIVADA_GIRA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
        "CORO": ("conjuração", [
            P("APONTA_CEU", 0.28, "Back", "In", "CARGA"),
            P("APONTA_CEU", 0.46, "Sine", "InOut", None, 0.04, 23),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
    }),
    "Pombo Correio": ("RightArm", {
        "BICADA": ("golpe rápido", [
            P("POMBO_BICA", 0.16, "Back", "In", "CARGA"),
            P("POMBO_BICA", 0.12, "Sine", "InOut"),
            P("FACA_CRAVA", 0.09, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.24, "Quad", "Out", "FIM"),
        ]),
        "REVOADA": ("conjuração", [
            P("POMBO_SOLTA", 0.28, "Back", "In", "CARGA"),
            P("POMBO_SOLTA", 0.40, "Sine", "InOut", None, 0.035, 26),
            P("POMBO_SOLTA", 0.15, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
        "ENCOMENDA": ("golpe pesado", [
            P("APONTA_CEU", 0.30, "Back", "In", "CARGA"),
            P("APONTA_CEU", 0.52, "Sine", "InOut", "SEGURA", 0.05, 25),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
    }),
    "Deu Ruim": ("RightArm", {
        "DEDO": ("golpe rápido", [
            P("APONTA", 0.20, "Back", "In", "CARGA"),
            P("APONTA", 0.16, "Sine", "InOut"),
            P("APONTA", 0.10, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.26, "Quad", "Out", "FIM"),
        ]),
        "STONKS": ("sustentada", [
            P("STONKS", 0.30, "Back", "In", "CARGA"),
            P("STONKS", 0.66, "Sine", "InOut", "SEGURA", 0.045, 22),
            P("STONKS", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
        "NOT": ("golpe pesado", [
            P("NOT_STONKS", 0.28, "Back", "In", "CARGA"),
            P("NOT_STONKS", 0.48, "Sine", "InOut", "SEGURA", 0.05, 24),
            P("NOT_STONKS", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
    }),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def escrever(tool, lidera, poses, sequencias):
    L = ["-- Poses.lua",
         "-- ModuleScript \"Poses\" — %s  (conjunto JODRO)" % tool,
         "--",
         "-- AUTORAL, pela GRAMATICA_R6.md. Não há modelo de origem: ninguém",
         "-- mandou animação de meme, então tudo aqui é escrito.",
         "--",
         "-- Meme não é desculpa para animação frouxa. A leitura cômica vem do",
         "-- ENQUADRAMENTO da pose — o martelo alto demais, o dedo apontado",
         "-- parado — e isso exige a mesma pausa que um golpe sério. Regra 7:",
         "-- estas sequências são 40–90% PARADAS.",
         "--",
         "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("--   %-12s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))
    L += ["--", "-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.", "",
          "local P = {}", ""]

    for nome in sorted(poses):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in poses[nome]:
                L.append(linha_junta(junta, poses[nome][junta]))
        L.append("}")

    L += ["", "P.SEQUENCIAS = {"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("")
        L.append("\t-- %s · %.2fs · %d passo(s)" % (natureza, total, len(passos)))
        L.append("\t%s = {" % nome)
        for p in passos:
            campos = ['pose = "%s"' % p["pose"], "time = %s" % p["time"],
                      'style = "%s"' % p["style"], 'dir = "%s"' % p["dir"]]
            if p["tremor"]:
                campos.append("tremor = %s" % p["tremor"])
            if p["freq"]:
                campos.append("freq = %s" % p["freq"])
            if p["marca"]:
                campos.append('marca = "%s"' % p["marca"])
            L.append("\t\t{ %s }," % ", ".join(campos))
        L.append("\t},")
    L += ["", "}", "", "return P"]
    return "\n".join(L) + "\n"


def main():
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        os.makedirs(pasta, exist_ok=True)
        poses = {}
        for _n, passos in sequencias.values():
            for p in passos:
                if p["pose"] not in BASE:
                    print("pose %r não existe (%s)" % (p["pose"], tool))
                    return 1
                poses[p["pose"]] = BASE[p["pose"]]
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias))
        duracoes = ["%s %.2fs" % (n, sum(p["time"] for p in ps))
                    for n, (_nat, ps) in sequencias.items()]
        print("%-22s %d pose(s) · %s" % (tool, len(poses), " · ".join(duracoes)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
