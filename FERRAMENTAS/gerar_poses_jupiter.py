#!/usr/bin/env python3
"""
gerar_poses_jupiter.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto JUPITER — TRÊS sequências cada,
21 no conjunto.

    python3 FERRAMENTAS/gerar_poses_jupiter.py

AUTORAL, E POR UM MOTIVO

    O modelo de origem tem 6 `Animation` e 6 `LoadAnimation` — asset de
    animação é proibido (§10), e o que a ficha registra são ids, não CFrame.
    Não há pose de origem a extrair: as 21 são escritas aqui, pela
    `GRAMATICA_R6.md`.

A GRAMÁTICA DO CONJUNTO: PESO

    Júpiter é o corpo mais pesado do sistema, e o conjunto inteiro é sobre
    pressão. Isso manda no ritmo:

    `conjuração pesada`  ~1.20 s, impacto a ~62% — o atraso É o peso
    `conjuração rápida`  ~0.90 s, para o raio e a espada, que são os dois
                         rápidos do conjunto
    `sustentada`         ~1.60 s, com os segurados marcados

    Cinco Tools lideram por `RightArm`; a `Espada de Pressao` e a `Queda do
    Gigante` lideram por `HRP`, porque as duas movem o corpo inteiro.

FORMATO V2

    Só as juntas que o `R6CFrameAnimator` solda: RightArm (1.5,0,0),
    LeftArm (-1.5,0,0), Head (0,1.5,0), HRP (), RightLeg (0.5,-2,0),
    LeftLeg (-0.5,-2,0). Sequência usa `time`/`style`/`dir`, nunca
    `duracao`/`easing`.
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


# ═══════════════════════════════════════════════════════════════
# O VOCABULÁRIO — 14 poses, todas de quem carrega peso
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.04, -0.2, 16, 4, 4),
        "LeftArm": J(-1.48, 0.04, -0.2, 16, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -5, 0),
    },
    # a mão aberta para o alto, chamando o que vem do céu
    "CHAMA_CEU": {
        "RightArm": J(1.44, 0.86, 0.02, 172, -8, -14),
        "LeftArm": J(-1.46, 0.1, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -38, 0, 0),
        "HRP": J(0, 0.1, 0, -17, 0, 0),
    },
    # a palma virada para o chão: o gesto de PRESSIONAR
    "PRESSIONA": {
        "RightArm": J(1.5, 0.18, -1.0, 82, -12, -6),
        "LeftArm": J(-1.5, 0.18, -1.0, 82, 12, 6),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.12, 0, 14, 0, 0),
    },
    # o punho que fecha e desce — a prensa
    "PRENSA": {
        "RightArm": J(1.36, -0.3, -0.66, 34, -22, -28),
        "LeftArm": J(-1.36, -0.3, -0.66, 34, 22, 28),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.4, 0, 28, 0, 0),
        "RightLeg": J(0.5, -1.66, -0.44, -30, 0, 0),
        "LeftLeg": J(-0.5, -1.66, -0.44, -30, 0, 0),
    },
    # os dois braços abertos: o campo, a órbita, a dispersão
    "ABRE_CAMPO": {
        "RightArm": J(1.56, 0.3, 0.24, 28, -30, -64),
        "LeftArm": J(-1.56, 0.3, 0.24, 28, 30, 64),
        "Head": J(0, 1.5, 0, -22, 0, 0),
        "HRP": J(0, 0.1, 0, -15, 0, 0),
    },
    # os braços recolhidos no peito: o vácuo, a blindagem
    "RECOLHE": {
        "RightArm": J(1.3, 0.28, -0.34, 84, -36, -44),
        "LeftArm": J(-1.3, 0.28, -0.34, 84, 36, 44),
        "Head": J(0, 1.5, 0, 14, 0, 0),
        "HRP": J(0, -0.14, 0, 13, 0, 0),
    },
    # o braço estendido apontando o alvo
    "APONTA": {
        "RightArm": J(1.52, 0.28, -1.2, 88, -8, -4),
        "LeftArm": J(-1.44, 0.08, -0.3, 26, 10, 12),
        "Head": J(0, 1.5, 0, -4, -10, 0),
        "HRP": J(0, 0, 0, 2, 14, 0),
    },
    # a estocada: braço à frente e perna avançada
    "ESTOCA": {
        "RightArm": J(1.5, 0.2, -1.26, 90, -6, -2),
        "LeftArm": J(-1.4, -0.02, -0.2, 14, 12, 18),
        "Head": J(0, 1.5, 0, 4, -6, 0),
        "HRP": J(0, -0.1, 0, 12, 10, 0),
        "RightLeg": J(0.5, -1.72, -0.5, -30, 0, 0),
    },
    # a espada alta, com as duas mãos
    "ESPADA_ALTA": {
        "RightArm": J(1.4, 0.82, -0.08, 170, -10, -18),
        "LeftArm": J(-1.4, 0.82, -0.08, 170, 10, 18),
        "Head": J(0, 1.5, 0, -32, 0, 0),
        "HRP": J(0, 0.14, 0, -18, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.12, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.12, 8, 0, 0),
    },
    # e a espada descendo
    "ESPADA_DESCE": {
        "RightArm": J(1.44, -0.28, -0.84, 18, -8, -4),
        "LeftArm": J(-1.44, -0.28, -0.84, 18, 8, 4),
        "Head": J(0, 1.5, 0, 30, 0, 0),
        "HRP": J(0, -0.44, 0, 34, 0, 0),
        "RightLeg": J(0.5, -1.56, -0.56, -40, 0, 0),
        "LeftLeg": J(-0.5, -1.56, -0.56, -40, 0, 0),
    },
    # o corte largo, na horizontal
    "CORTE_LARGO": {
        "RightArm": J(1.52, 0.32, -0.92, 80, -48, -14),
        "LeftArm": J(-1.5, 0.3, -0.9, 78, 46, 14),
        "Head": J(0, 1.5, 0, 0, 42, 0),
        "HRP": J(0, -0.06, 0, 4, -50, 0),
    },
    # segurar o planeta acima da cabeça
    "SEGURA_PLANETA": {
        "RightArm": J(1.36, 0.9, -0.12, 168, -20, -30),
        "LeftArm": J(-1.36, 0.9, -0.12, 168, 20, 30),
        "Head": J(0, 1.5, 0, -40, 0, 0),
        "HRP": J(0, 0.16, 0, -22, 0, 0),
        "RightLeg": J(0.5, -1.92, 0.1, 6, 0, 0),
        "LeftLeg": J(-0.5, -1.92, 0.1, 6, 0, 0),
    },
    # e derrubá-lo
    "DERRUBA": {
        "RightArm": J(1.5, -0.24, -0.9, 24, -14, -8),
        "LeftArm": J(-1.5, -0.24, -0.9, 24, 14, 8),
        "Head": J(0, 1.5, 0, 32, 0, 0),
        "HRP": J(0, -0.5, 0, 36, 0, 0),
        "RightLeg": J(0.5, -1.52, -0.6, -44, 0, 0),
        "LeftLeg": J(-0.5, -1.52, -0.6, -44, 0, 0),
    },
    # o giro do braço: a tempestade, a órbita
    "GIRA": {
        "RightArm": J(1.46, 0.5, -0.82, 116, -30, -18),
        "LeftArm": J(-1.42, 0.16, -0.4, 42, 16, 18),
        "Head": J(0, 1.5, 0, -14, 12, 0),
        "HRP": J(0, 0.04, 0, -8, -14, 0),
    },
}


# ── moldes de ritmo ───────────────────────────────────────────────────────

def rapido(nome, a, b):
    """0.90 s, impacto na metade. Para o raio e a espada."""
    return (nome, ("conjuração rápida", [
        P(a, 0.2, "Back", "In", "CARGA"),
        P(a, 0.14, "Sine", "InOut"),
        P(b, 0.1, "Quint", "Out", "GOLPE"),
        P(b, 0.14, "Sine", "InOut"),
        P("IDLE", 0.2, "Quad", "Out", "FIM"),
    ]))


def pesado(nome, a, b, tremor=0.05, freq=25):
    """1.20 s, impacto a ~62%. O atraso É o peso."""
    return (nome, ("conjuração pesada", [
        P(a, 0.24, "Back", "In", "CARGA"),
        P(a, 0.5, "Sine", "InOut", "SEGURA", tremor, freq),
        P(b, 0.12, "Quint", "Out", "GOLPE"),
        P(b, 0.14, "Sine", "InOut"),
        P("IDLE", 0.2, "Quad", "Out", "FIM"),
    ]))


def sustentada(nome, a, tremor=0.03, freq=19):
    """1.60 s, com os segurados marcados."""
    return (nome, ("sustentada", [
        P(a, 0.28, "Back", "Out", "CARGA"),
        P(a, 0.4, "Sine", "InOut", "SEGURA", tremor, freq),
        P(a, 0.34, "Sine", "InOut", None, tremor, freq + 4),
        P(a, 0.28, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.3, "Quad", "Out", "FIM"),
    ]))


def tres(m1, r, t):
    return dict([m1, r, t])


# ═══════════════════════════════════════════════════════════════
# AS 21 SEQUÊNCIAS — três por Tool
#
# O nome bate com o `rig:PlaySequence(...)` do Server, e o beat de cada passo
# bate com a tabela do `despachar`. É o par que o `verificar_beats.py` confere.
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Jupiter Grande Mancha": ("RightArm", tres(
        pesado("MANCHA", "GIRA", "PRESSIONA"),
        sustentada("OLHO", "ABRE_CAMPO"),
        pesado("DISPERSAR", "RECOLHE", "ABRE_CAMPO", 0.06, 28))),

    "Jupiter Pressao Esmagadora": ("RightArm", tres(
        pesado("COLUNA", "CHAMA_CEU", "PRESSIONA", 0.055, 26),
        pesado("PRENSAR", "ABRE_CAMPO", "PRENSA", 0.065, 29),
        sustentada("VACUO", "RECOLHE", 0.04, 21))),

    "Jupiter Raio Joviano": ("RightArm", tres(
        rapido("RAIO", "CHAMA_CEU", "APONTA"),
        rapido("CADEIA", "APONTA", "GIRA"),
        pesado("TORMENTA", "CHAMA_CEU", "ABRE_CAMPO", 0.06, 30))),

    "Jupiter Luas Galileanas": ("RightArm", tres(
        sustentada("LUAS", "GIRA", 0.035, 20),
        rapido("LANCA_IO", "RECOLHE", "APONTA"),
        pesado("ECLIPSE", "SEGURA_PLANETA", "DERRUBA", 0.07, 31))),

    "Jupiter Cinturao de Radiacao": ("RightArm", tres(
        sustentada("CINTURAO", "ABRE_CAMPO", 0.03, 18),
        pesado("PULSO", "RECOLHE", "ABRE_CAMPO", 0.05, 27),
        sustentada("BLINDAGEM", "RECOLHE", 0.025, 16))),

    "Jupiter Espada de Pressao": ("HRP", tres(
        rapido("GOLPE", "ESPADA_ALTA", "ESPADA_DESCE"),
        rapido("ESTOCADA", "RECOLHE", "ESTOCA"),
        pesado("CORTE_GIGANTE", "ESPADA_ALTA", "CORTE_LARGO", 0.06, 28))),

    "Jupiter Queda do Gigante": ("HRP", tres(
        pesado("INVOCAR", "CHAMA_CEU", "SEGURA_PLANETA", 0.05, 24),
        sustentada("PRESENCA", "SEGURA_PLANETA", 0.045, 22),
        pesado("IMPACTO", "SEGURA_PLANETA", "DERRUBA", 0.08, 33))),
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
         "-- ModuleScript \"Poses\" — %s  (conjunto JUPITER)" % tool,
         "--",
         "-- AUTORAL. O modelo de origem tem 6 `Animation` e 6",
         "-- `LoadAnimation` — asset de animação é proibido (§10), e o que a",
         "-- ficha registra são ids, não CFrame. Não havia pose a extrair.",
         "--",
         "-- A GRAMÁTICA DO CONJUNTO É PESO. Júpiter é o corpo mais pesado do",
         "-- sistema, e as sete são sobre pressão: a `conjuração pesada` leva",
         "-- 1.20 s com o impacto a ~62%, e o atraso É o peso. Só o raio e a",
         "-- espada usam o ritmo rápido.",
         "--",
         "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:",
         "--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) ·",
         "--   HRP () · RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)",
         "--",
         "-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama",
         "-- `ReleaseLegs` ao fim. Perna soldada trava a caminhada.",
         "--",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera,
         "--"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        marcas = [p["marca"] for p in passos if p["marca"]]
        L.append("--   %-16s %-19s %.2fs · %s"
                 % (nome, natureza, total, " ".join(marcas)))
    L += ["--", "-- Gerado por FERRAMENTAS/gerar_poses_jupiter.py.", "",
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
        L.append("\t-- %s · %.2fs · %d passo(s)"
                 % (natureza, total, len(passos)))
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
    total = 0
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s — rode preparar_jupiter.py antes" % tool)
            return 1
        poses = {}
        for _n, passos in sequencias.values():
            for p in passos:
                if p["pose"] not in BASE:
                    print("pose %r não existe (%s)" % (p["pose"], tool))
                    return 1
                poses[p["pose"]] = BASE[p["pose"]]
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias))
        total = total + len(sequencias)
        duracoes = ["%s %.2fs" % (n, sum(p["time"] for p in ps))
                    for n, (_nat, ps) in sequencias.items()]
        print("  %-30s %2d pose(s) · %s" % (tool, len(poses),
                                            " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T em cada." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
