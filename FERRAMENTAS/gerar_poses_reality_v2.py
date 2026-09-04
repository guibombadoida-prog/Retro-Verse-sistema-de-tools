#!/usr/bin/env python3
"""
gerar_poses_reality_v2.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto REALITY — UMA sequência cada,
porque este conjunto tem uma habilidade por Tool e ela é no clique.

    python3 FERRAMENTAS/preparar_reality_v2.py      # antes
    python3 FERRAMENTAS/gerar_poses_reality_v2.py

A GRAMÁTICA DO CONJUNTO: TODO GESTO TEM CONTRAGOLPE

    Os outros conjuntos animam a IDA. O corpo acelera até o beat, e o que vem
    depois é só voltar para o `IDLE`.

    Num conjunto de FÍSICA isso mente. Empurrar coisa pesada empurra você de
    volta — é a terceira lei, e é a única coisa que o jogador sente sem
    precisar que alguém explique. Por isso toda sequência daqui tem, DEPOIS do
    beat, um quadro de RECUO ou de ESCORA, e ele é proporcional à força:

      `Lapada Seca`          recuo curto e alto  — o braço passa reto e sobra
      `Canhao Satelite`      escora longa        — o feixe empurra por 1 s
      `Arvore Maligna`       escora agachada     — a raiz puxa o corpo para baixo
      `Gato Ajudante Boss`   quase nenhum        — chamar não custa nada
      `Samsungus`            recuo de arremesso  — o braço continua depois de soltar
      `Arma de Fisica`       NENHUM na ida       — o recuo é contínuo, no `segurar`
      `Indutor de Gravidade` escora com tremor   — o poço puxa quem o abriu também

    Quem apagar o quadro de recuo transforma sete habilidades de física em
    sete golpes comuns. É a diferença entre "eu bati" e "eu movi massa".

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
# O VOCABULÁRIO — as poses de quem move massa
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.06, -0.18, 18, 4, 6),
        "LeftArm": J(-1.49, 0.04, -0.06, 8, -2, -4),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },

    # ── LAPADA: o braço carrega ATRÁS do ombro, não ao lado
    "TAPA_CARREGA": {
        "RightArm": J(1.28, 0.44, 0.62, -46, -62, 36),
        "LeftArm": J(-1.4, 0.06, -0.42, 34, 20, -14),
        "Head": J(0, 1.5, 0, -6, -34, 0),
        "HRP": J(0, 0.04, 0, -4, -38, 0),
    },
    # e passa RETO, com o quadril à frente do braço
    "TAPA_PASSA": {
        "RightArm": J(1.42, 0.1, -0.96, 8, 74, -26),
        "LeftArm": J(-1.36, -0.06, 0.34, -22, -18, 20),
        "Head": J(0, 1.5, 0, 4, 40, 0),
        "HRP": J(0, -0.06, 0, 6, 44, 0),
        "RightLeg": J(0.5, -1.86, -0.34, -20, 0, 0),
        "LeftLeg": J(-0.52, -1.9, 0.24, 16, 0, 0),
    },
    # o contragolpe: o braço sobrou e o tronco desconta
    "RECUO_ALTO": {
        "RightArm": J(1.34, 0.34, -0.7, -34, 52, -18),
        "LeftArm": J(-1.44, 0.14, 0.06, -6, -10, 12),
        "Head": J(0, 1.5, 0, -12, 22, 0),
        "HRP": J(0, 0.04, 0, -8, 26, 0),
    },

    # ── CANHÃO: marca o céu, depois aponta o chão
    "MARCA_CEU": {
        "RightArm": J(1.36, 0.72, 0.06, -166, -12, 24),
        "LeftArm": J(-1.46, 0.16, -0.28, 30, 12, -14),
        "Head": J(0, 1.5, 0, -36, -8, 0),
        "HRP": J(0, 0.08, 0, -12, -10, 0),
    },
    "MARCA_CHAO": {
        "RightArm": J(1.44, -0.06, -0.88, 62, -6, -8),
        "LeftArm": J(-1.44, -0.02, -0.5, 44, 10, 14),
        "Head": J(0, 1.5, 0, 20, 0, 0),
        "HRP": J(0, -0.14, 0, 14, 0, 0),
        "RightLeg": J(0.5, -1.82, -0.28, -16, 0, 0),
        "LeftLeg": J(-0.52, -1.86, 0.18, 12, 0, 0),
    },
    # escora: os dois braços travados, o corpo aguentando o feixe
    "ESCORA_LONGA": {
        "RightArm": J(1.4, -0.18, -0.52, 52, -22, -26),
        "LeftArm": J(-1.4, -0.18, -0.52, 52, 22, 26),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.28, 0, 16, 0, 0),
        "RightLeg": J(0.54, -1.7, -0.42, -30, 0, 0),
        "LeftLeg": J(-0.56, -1.76, 0.3, 22, 0, 0),
    },

    # ── ÁRVORE: a mão entra no chão e o corpo desce com ela
    "PLANTA_MAO": {
        "RightArm": J(1.4, -0.5, -0.42, 78, -14, -14),
        "LeftArm": J(-1.42, -0.3, -0.2, 40, 12, 18),
        "Head": J(0, 1.5, 0, 30, 6, 0),
        "HRP": J(0, -0.62, 0, 28, 8, 0),
        "RightLeg": J(0.5, -1.44, -0.56, -44, 0, 0),
        "LeftLeg": J(-0.52, -1.58, 0.34, 30, 0, 0),
    },
    # a raiz puxa: o corpo não sobe, ele fica preso baixo
    "ESCORA_BAIXA": {
        "RightArm": J(1.38, -0.28, -0.6, 62, -18, -20),
        "LeftArm": J(-1.4, -0.2, -0.4, 48, 14, 16),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.44, 0, 22, 0, 0),
        "RightLeg": J(0.52, -1.56, -0.48, -36, 0, 0),
        "LeftLeg": J(-0.54, -1.66, 0.28, 26, 0, 0),
    },

    # ── GATO: dois dedos na boca, o assobio
    "CHAMA": {
        "RightArm": J(1.3, 0.6, -0.5, -104, -22, 30),
        "LeftArm": J(-1.46, 0.06, -0.1, 12, 0, -6),
        "Head": J(0, 1.5, 0, -14, -10, 0),
        "HRP": J(0, 0.04, 0, -4, -8, 0),
    },
    "APONTA_CURTO": {
        "RightArm": J(1.44, 0.12, -0.86, 4, -8, -6),
        "LeftArm": J(-1.46, 0.04, -0.12, 14, 4, -4),
        "Head": J(0, 1.5, 0, 0, -6, 0),
        "HRP": J(0, 0, 0, 0, -8, 0),
    },

    # ── SAMSUNGUS: arremesso por cima, e o braço continua
    "ARREMESSO_ALTO": {
        "RightArm": J(1.3, 0.66, 0.34, -150, -26, 34),
        "LeftArm": J(-1.42, 0.18, -0.44, 40, 18, -18),
        "Head": J(0, 1.5, 0, -24, -18, 0),
        "HRP": J(0, 0.06, 0, -8, -26, 0),
    },
    "ARREMESSO_SOLTA": {
        "RightArm": J(1.42, -0.1, -0.92, 46, 30, -18),
        "LeftArm": J(-1.38, -0.04, 0.22, -14, -14, 16),
        "Head": J(0, 1.5, 0, 12, 22, 0),
        "HRP": J(0, -0.1, 0, 12, 26, 0),
        "RightLeg": J(0.5, -1.84, -0.32, -18, 0, 0),
        "LeftLeg": J(-0.52, -1.88, 0.22, 14, 0, 0),
    },

    # ── ARMA DE FÍSICA: mira firme, e SEGURA (sem recuo — o recuo é contínuo)
    "MIRA_GARRA": {
        "RightArm": J(1.44, 0.1, -0.9, -2, -6, -4),
        "LeftArm": J(-1.34, 0.04, -0.66, 22, 34, 8),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -10, 0),
    },
    "SEGURA_FIRME": {
        "RightArm": J(1.42, 0.06, -0.94, 6, -4, -6),
        "LeftArm": J(-1.3, 0.02, -0.72, 26, 38, 10),
        "Head": J(0, 1.5, 0, 2, -2, 0),
        "HRP": J(0, -0.04, 0, 4, -12, 0),
    },

    # ── INDUTOR: as duas mãos abrem o poço, e ele puxa de volta
    "ABRE_POCO": {
        "RightArm": J(1.44, 0.06, -0.78, 26, -34, -14),
        "LeftArm": J(-1.44, 0.06, -0.78, 26, 34, 14),
        "Head": J(0, 1.5, 0, -6, 0, 0),
        "HRP": J(0, 0.06, 0, -6, 0, 0),
    },
    "PUXA_DE_VOLTA": {
        "RightArm": J(1.34, -0.08, -0.58, 48, -14, -30),
        "LeftArm": J(-1.34, -0.08, -0.58, 48, 14, 30),
        "Head": J(0, 1.5, 0, 18, 0, 0),
        "HRP": J(0, -0.3, 0, 20, 0, 0),
        "RightLeg": J(0.54, -1.66, -0.44, -32, 0, 0),
        "LeftLeg": J(-0.56, -1.72, 0.3, 24, 0, 0),
    },
}


# ═══════════════════════════════════════════════════════════════
# AS 7 SEQUÊNCIAS — carga · beat · CONTRAGOLPE · volta
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Lapada Seca": ("RightArm", [
        P("TAPA_CARREGA", 0.16, "Back", "Out", marca="CARGA"),
        P("TAPA_PASSA", 0.09, "Quint", "Out", marca="TAPA"),
        P("RECUO_ALTO", 0.20, "Quad", "Out"),
        P("IDLE", 0.24, "Quad", "InOut"),
    ]),

    "Canhao Satelite": ("RightArm", [
        P("MARCA_CEU", 0.34, "Quad", "Out", marca="CHAMA"),
        P("MARCA_CHAO", 0.16, "Quint", "Out", marca="MARCA"),
        P("ESCORA_LONGA", 0.30, "Quad", "Out", marca="FEIXE"),
        # o quadro mais longo do conjunto, e ele é DEPOIS do beat: o corpo fica
        # aguentando enquanto a órbita descarrega. Tremor baixo e lento.
        P("ESCORA_LONGA", 0.90, "Linear", "Out", tremor=0.028, freq=13),
        P("IDLE", 0.36, "Quad", "InOut"),
    ]),

    "Arvore Maligna": ("HRP", [
        P("PLANTA_MAO", 0.30, "Quad", "Out", marca="PLANTA"),
        P("ESCORA_BAIXA", 0.42, "Quad", "Out", marca="RAIZ", tremor=0.034, freq=16),
        P("ESCORA_BAIXA", 0.34, "Linear", "Out"),
        P("IDLE", 0.34, "Quad", "InOut"),
    ]),

    "Gato Ajudante Boss": ("RightArm", [
        P("CHAMA", 0.22, "Quad", "Out", marca="ASSOBIO"),
        P("APONTA_CURTO", 0.18, "Back", "Out", marca="SOLTA"),
        P("IDLE", 0.26, "Quad", "InOut"),
    ]),

    "Samsungus": ("RightArm", [
        P("ARREMESSO_ALTO", 0.20, "Back", "Out", marca="CARGA"),
        P("ARREMESSO_SOLTA", 0.10, "Quint", "Out", marca="ARREMESSA"),
        P("ARREMESSO_SOLTA", 0.16, "Linear", "Out"),
        P("IDLE", 0.26, "Quad", "InOut"),
    ]),

    # A ÚNICA sem contragolpe na ida, e de propósito: a `Arma de Fisica` não
    # solta nada no beat — ela TRAVA. O recuo dela é contínuo, e quem o desenha
    # é a `SEGURA_FIRME` mantida enquanto o botão está apertado.
    "Arma de Fisica": ("RightArm", [
        P("MIRA_GARRA", 0.12, "Quad", "Out", marca="TRAVA"),
        P("SEGURA_FIRME", 0.18, "Quad", "InOut"),
    ]),

    "Indutor de Gravidade": ("HRP", [
        P("ABRE_POCO", 0.26, "Quad", "Out", marca="ABRE"),
        P("PUXA_DE_VOLTA", 0.24, "Quint", "Out", marca="POCO"),
        # quem abriu o poço também é puxado — o tremor é o poço, não o susto
        P("PUXA_DE_VOLTA", 0.60, "Linear", "Out", tremor=0.04, freq=18),
        P("IDLE", 0.34, "Quad", "InOut"),
    ]),
}

#: a sequência de SOLTAR da `Arma de Fisica`: existe porque `Tool.Deactivated`
#: é uma entrada de verdade, e sem ela o braço fica travado na `SEGURA_FIRME`.
SOLTAR = ("Arma de Fisica", "SOLTAR", [
    P("MIRA_GARRA", 0.10, "Quint", "Out", marca="SOLTA"),
    P("RECUO_ALTO", 0.14, "Quad", "Out"),
    P("IDLE", 0.20, "Quad", "InOut"),
])


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto REALITY)
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
-- A GRAMÁTICA: TODO GESTO TEM CONTRAGOLPE
--
--   Empurrar coisa pesada empurra você de volta. Num conjunto de física isso
--   não é enfeite: é a única coisa que o jogador sente sem que ninguém
--   explique. Por isso a sequência não acaba no beat — depois dele vem um
--   quadro de RECUO ou de ESCORA, proporcional à força que saiu.
--
--   {nota}
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {{}}
'''

NOTAS = {
    "Lapada Seca": "Recuo curto e alto: o braço passa reto e SOBRA.",
    "Canhao Satelite": "Escora de 0.90 s — o quadro mais longo do conjunto, e "
                       "ele vem DEPOIS do beat.",
    "Arvore Maligna": "Escora agachada: a raiz puxa o corpo para baixo, e ele "
                      "não volta a subir até o fim.",
    "Gato Ajudante Boss": "Quase nenhum contragolpe — chamar não custa massa.",
    "Samsungus": "Recuo de arremesso: o braço continua depois de o aparelho sair.",
    "Arma de Fisica": "A ÚNICA sem contragolpe na ida. Ela não solta nada no "
                      "beat, ela TRAVA — o recuo é contínuo, na `SEGURA_FIRME`.",
    "Indutor de Gravidade": "Escora com tremor: o poço puxa quem o abriu também.",
}


def escrever(tool, lidera, sequencias):
    poses = {}
    for passos in sequencias.values():
        for p in passos:
            poses[p["pose"]] = BASE[p["pose"]]

    L = [CABECA.format(tool=tool, lidera=lidera, nota=NOTAS[tool])]
    for nome in sorted(poses):
        L.append("P.%s = {" % nome)
        for chave in ORDEM:
            if chave in poses[nome]:
                L.append(linha_junta(chave, poses[nome][chave]))
        L.append("}")
        L.append("")

    L += ["--" + "═" * 63, "-- SEQUÊNCIAS", "--" + "═" * 63, "",
          "P.SEQUENCIAS = {"]
    for nome, passos in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("")
        L.append("\t-- %.2f s" % total)
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
    for tool, (lidera, passos) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s — rode preparar_reality_v2.py antes" % tool)
            return 1
        sequencias = {"PRIMARIA": passos}
        if SOLTAR[0] == tool:
            sequencias[SOLTAR[1]] = SOLTAR[2]
        for p in [q for ps in sequencias.values() for q in ps]:
            if p["pose"] not in BASE:
                print("pose %r não existe (%s)" % (p["pose"], tool))
                return 1
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, sequencias))
        total = total + len(sequencias)
        duracoes = ["%s %.2fs" % (n, sum(p["time"] for p in ps))
                    for n, ps in sequencias.items()]
        print("  %-22s %2d pose(s) · %s"
              % (tool, len({p["pose"] for ps in sequencias.values() for p in ps}),
                 " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — uma habilidade cada, no clique." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
