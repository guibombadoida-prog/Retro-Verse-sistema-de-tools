#!/usr/bin/env python3
"""
gerar_poses_criacao.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto CRIAÇÃO — TRÊS sequências cada,
21 no conjunto.

    python3 FERRAMENTAS/preparar_criacao.py      # antes
    python3 FERRAMENTAS/gerar_poses_criacao.py

A GRAMÁTICA DO CONJUNTO: O GESTO VEM ANTES DA COISA

    Todos os conjuntos anteriores animam um GOLPE — o corpo acelera até um
    ponto e o dano acontece ali. Criar não é isso. Criar tem dois tempos, e o
    segundo é o que importa:

      1. o gesto  — a mão desce, aperta o chão, risca o ar
      2. a PAUSA  — e a coisa sobe

    Por isso o molde `erguer` tem o quadro mais longo do repositório num lugar
    onde ninguém põe: DEPOIS do beat, não antes. A muralha não aparece no
    instante em que a mão sobe; ela aparece enquanto a mão fica parada lá em
    cima. Quem tira essa pausa transforma a Tool inteira num golpe comum com
    cenário de enfeite.

    Cinco moldes:

    `bater`     ~0.70 s — o martelo e o tijolo. É o único que é golpe
    `plantar`   ~0.90 s — agacha e aperta o chão
    `desenhar`  ~0.90 s — o risco no ar, e ele é LATERAL, não frontal
    `erguer`    ~1.30 s — o gesto, e a pausa em que a coisa sobe
    `epica`     ~1.50 s — a ultimate, com os quatro beats da cutscene

FORMATO V2

    Só as juntas que o `R6CFrameAnimator` solda: RightArm (1.5,0,0),
    LeftArm (-1.5,0,0), Head (0,1.5,0), HRP (), RightLeg (0.5,-2,0),
    LeftLeg (-0.5,-2,0). Sequência usa `time`/`style`/`dir`.
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
# O VOCABULÁRIO — 11 poses de quem constrói
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.08, -0.2, 20, 4, 6),
        "LeftArm": J(-1.49, 0.04, -0.08, 10, -2, -5),
        "Head": J(0, 1.5, 0, -3, -5, 0),
        "HRP": J(0, 0, 0, 0, -7, 0),
    },
    # o martelo alto, com o corpo torcido
    "MARTELO_ALTO": {
        "RightArm": J(1.32, 0.76, 0.2, -158, -18, 30),
        "LeftArm": J(-1.44, 0.2, -0.4, 44, 16, -18),
        "Head": J(0, 1.5, 0, -18, -14, 0),
        "HRP": J(0, 0.06, 0, -10, -24, 0),
    },
    # e descendo na bigorna
    "MARTELO_DESCE": {
        "RightArm": J(1.46, -0.36, -0.66, 16, -8, -6),
        "LeftArm": J(-1.42, -0.1, -0.3, 22, -10, 14),
        "Head": J(0, 1.5, 0, 28, 10, 0),
        "HRP": J(0, -0.36, 0, 26, 18, 0),
        "RightLeg": J(0.5, -1.72, -0.4, -26, 0, 0),
        "LeftLeg": J(-0.52, -1.84, 0.2, 14, 0, 0),
    },
    # as duas palmas viradas para baixo: reunir o material
    "PALMAS_BAIXO": {
        "RightArm": J(1.44, -0.14, -0.62, 46, -16, -22),
        "LeftArm": J(-1.44, -0.14, -0.62, 46, 16, 22),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.26, 0, 18, 0, 0),
        "RightLeg": J(0.5, -1.8, -0.24, -16, 0, 0),
        "LeftLeg": J(-0.5, -1.8, -0.24, -16, 0, 0),
    },
    # e as duas subindo: é AQUI que a coisa sobe, e a pausa é longa
    "ERGUE": {
        "RightArm": J(1.5, 0.7, -0.3, 142, -12, -16),
        "LeftArm": J(-1.5, 0.7, -0.3, 142, 12, 16),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.12, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.1, 6, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.1, 6, 0, 0),
    },
    # o risco no ar. LATERAL, não frontal: desenhar é atravessar o campo de
    # visão, e um risco para a frente some no eixo da câmera
    "DESENHA_COMECA": {
        "RightArm": J(1.44, 0.42, -0.66, 92, -48, -20),
        "LeftArm": J(-1.46, 0.08, -0.18, 18, 12, -10),
        "Head": J(0, 1.5, 0, -6, -34, 0),
        "HRP": J(0, 0.02, 0, 0, -30, 0),
    },
    "DESENHA_TERMINA": {
        "RightArm": J(1.52, 0.38, -0.78, 90, 46, -16),
        "LeftArm": J(-1.42, 0.04, 0.14, -6, -12, 12),
        "Head": J(0, 1.5, 0, -2, 36, 0),
        "HRP": J(0, 0, 0, 0, 34, 0),
    },
    # agachar e apertar o chão: a semente
    "AGACHA": {
        "RightArm": J(1.4, -0.66, -0.44, 6, -8, 12),
        "LeftArm": J(-1.4, -0.66, -0.44, 6, 8, -12),
        "Head": J(0, 1.5, 0, 34, 0, 0),
        "HRP": J(0, -0.82, 0, 28, 0, 0),
        "RightLeg": J(0.5, -1.42, -0.52, -56, 0, 0),
        "LeftLeg": J(-0.52, -1.68, -0.28, -28, 0, 0),
    },
    # apresentar o que foi feito
    "APRESENTA": {
        "RightArm": J(1.52, 0.3, -0.94, 84, -6, -18),
        "LeftArm": J(-1.5, 0.16, -0.5, 52, 10, 14),
        "Head": J(0, 1.5, 0, -10, -6, 0),
        "HRP": J(0, 0.04, 0, -6, 8, 0),
    },
    # o demiurgo: braços abertos, o mundo acima
    "ABRE_MUNDO": {
        "RightArm": J(1.56, 0.84, -0.1, 166, -14, -34),
        "LeftArm": J(-1.56, 0.84, -0.1, 166, 14, 34),
        "Head": J(0, 1.5, 0, -40, 0, 0),
        "HRP": J(0, 0.18, 0, -22, 0, 0),
        "RightLeg": J(0.5, -1.94, 0.06, 4, 0, 0),
        "LeftLeg": J(-0.5, -1.94, 0.06, 4, 0, 0),
    },
    # e o assentar do que foi criado
    "ASSENTA": {
        "RightArm": J(1.46, -0.2, -0.5, 26, -8, 8),
        "LeftArm": J(-1.46, -0.2, -0.5, 26, 8, -8),
        "Head": J(0, 1.5, 0, 18, 0, 0),
        "HRP": J(0, -0.34, 0, 22, 0, 0),
        "RightLeg": J(0.5, -1.66, -0.42, -32, 0, 0),
        "LeftLeg": J(-0.5, -1.66, -0.42, -32, 0, 0),
    },
}


# ── moldes de ritmo ───────────────────────────────────────────────────────

def bater(nome):
    """0.70 s — o martelo e o tijolo. O único molde do conjunto que é GOLPE."""
    return (nome, ("batida", [
        P("MARTELO_ALTO", 0.16, "Back", "In", "CARGA"),
        P("MARTELO_DESCE", 0.09, "Quint", "Out", "GOLPE"),
        P("MARTELO_DESCE", 0.13, "Sine", "InOut"),
        P("IDLE", 0.32, "Quad", "Out", "FIM"),
    ]))


def plantar(nome):
    """0.90 s — agacha e aperta o chão."""
    return (nome, ("plantio", [
        P("AGACHA", 0.22, "Back", "In", "CARGA"),
        P("AGACHA", 0.14, "Quint", "Out", "PLANTA"),
        P("APRESENTA", 0.18, "Quad", "Out"),
        P("IDLE", 0.36, "Quad", "Out", "FIM"),
    ]))


def desenhar(nome):
    """0.90 s — o risco no ar, e ele atravessa o campo de visão."""
    return (nome, ("desenho", [
        P("DESENHA_COMECA", 0.2, "Back", "Out", "CARGA"),
        P("DESENHA_TERMINA", 0.16, "Quad", "InOut", "TRACA"),
        P("APRESENTA", 0.16, "Quint", "Out"),
        P("IDLE", 0.38, "Quad", "Out", "FIM"),
    ]))


def erguer(nome, tremorPausa=0.02, freq=16):
    """1.30 s — o gesto, e A PAUSA em que a coisa sobe.

    O quadro de 0.46 s DEPOIS do beat `ERGUE` é o mais longo do conjunto, e
    está no lugar onde nenhum outro molde do repositório põe um: depois do
    trabalho, não antes. A muralha não aparece no instante em que a mão sobe —
    ela aparece enquanto a mão fica parada lá em cima. Tirar essa pausa
    transforma a Tool num golpe comum com cenário de enfeite.
    """
    return (nome, ("erguimento", [
        P("PALMAS_BAIXO", 0.2, "Back", "In", "CARGA"),
        P("PALMAS_BAIXO", 0.16, "Sine", "InOut", "SEGURA"),
        P("ERGUE", 0.14, "Quint", "Out", "ERGUE"),
        P("ERGUE", 0.46, "Sine", "InOut", None, tremorPausa, freq),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ]))


def epica(nome, tremorPausa=0.04, freq=20):
    """1.50 s — a ultimate.

    Os QUATRO beats são também os quatro enquadramentos da `CutsceneCam`: um
    beat que a câmera não acompanha é um corte que não acontece.
    """
    return (nome, ("épica", [
        P("ABRE_MUNDO", 0.34, "Back", "Out", "CENA"),
        P("ABRE_MUNDO", 0.48, "Sine", "InOut", "CARGA", tremorPausa, freq),
        P("ASSENTA", 0.16, "Quint", "Out", "ESTOURA", tremorPausa * 1.8, freq + 12),
        P("IDLE", 0.52, "Quad", "Out", "FIM"),
    ]))


def tres(m1, r, t):
    return dict([m1, r, t])


# ═══════════════════════════════════════════════════════════════
# AS 21 SEQUÊNCIAS — três por Tool
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Forja": ("RightArm", tres(
        bater("MARTELAR"),
        erguer("BIGORNA", 0.03, 18),
        erguer("TEMPERA", 0.022, 20))),

    "Alvenaria": ("RightArm", tres(
        bater("TIJOLO"),
        erguer("MURALHA", 0.026, 15),
        erguer("TORRE", 0.038, 17))),

    "Semente": ("HRP", tres(
        plantar("BROTO"),
        plantar("CIPO"),
        erguer("ARVORE", 0.03, 14))),

    "Projeto": ("RightArm", tres(
        desenhar("TRACO"),
        desenhar("ESBOCO"),
        erguer("MATERIALIZAR", 0.024, 19))),

    "Prototipo": ("RightArm", tres(
        bater("PECA"),
        desenhar("MOLDE"),
        erguer("SERIE", 0.032, 21))),

    "Genese": ("RightArm", tres(
        desenhar("FAISCA"),
        erguer("MATERIA", 0.028, 22),
        erguer("PRIMEIRO", 0.044, 24))),

    "Demiurgo": ("HRP", tres(
        desenhar("MOLDE_MUNDO"),
        erguer("CONTINENTE", 0.034, 16),
        epica("CRIACAO", 0.05, 20))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Criacao_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto CRIAÇÃO)
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — nenhuma pose daqui deve ser aplicada fora de sequência.
--
-- ESTA TOOL LIDERA POR `{lidera}`.
--
-- A GRAMÁTICA: O GESTO VEM ANTES DA COISA
--
--   Os outros conjuntos animam um GOLPE — o corpo acelera até um ponto e o
--   dano acontece ali. Criar tem dois tempos, e o segundo é o que importa: o
--   gesto, e depois a PAUSA em que a coisa sobe.
--
--   Por isso o molde `erguer` tem o quadro mais longo num lugar onde nenhum
--   outro molde do repositório põe um: DEPOIS do beat. A muralha não aparece
--   no instante em que a mão sobe — ela aparece enquanto a mão fica parada lá
--   em cima.
--
-- Gerado por FERRAMENTAS/gerar_poses_criacao.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local P = {{}}
'''


def escrever(tool, lidera, poses, sequencias):
    L = [CABECA.format(tool=tool, lidera=lidera)]
    for nome, junta in poses.items():
        L.append("P.%s = {" % nome)
        for chave in ORDEM:
            if chave in junta:
                L.append(linha_junta(chave, junta[chave]))
        L.append("}")
        L.append("")

    L += ["--" + "═" * 63, "-- SEQUÊNCIAS", "--" + "═" * 63, "",
          "P.SEQUENCIAS = {"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("")
        L.append("\t-- %s — %.2f s" % (natureza, total))
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
            print("sem pasta Tools/%s — rode preparar_criacao.py antes" % tool)
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
        print("  %-12s %2d pose(s) · %s" % (tool, len(poses),
                                            " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T em cada." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
