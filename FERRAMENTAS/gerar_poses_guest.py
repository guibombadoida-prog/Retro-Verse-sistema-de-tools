#!/usr/bin/env python3
"""
gerar_poses_guest.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto GUEST.

    python3 FERRAMENTAS/gerar_poses_guest.py

DE ONDE SAI O TEMPO — e onde ele foge da tabela, de propósito

    A base é `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`.
    Mas a medição do próprio Guest, em `ACERVO_RETROVERSE/Guest_Tools/
    R6_CFRAME/NOTAS.md`, achou uma coisa que a gramática não previa:

      o combo do `Cano De Rua` sai em 0.317 s, proporção 42 : 58

    A proporção CONFIRMA a regra 3 (combo bate cedo). A duração CONTRARIA a
    regra 1, que mede golpe rápido em 0.8–1.2 s. A leitura registrada é que a
    regra 1 foi medida em bake de anime, onde o golpe é ENCENADO; aqui é
    porrada de rua, onde o golpe é RESPONSIVO.

    Então este conjunto não obedece a regra 1 ao pé da letra, e a decisão é
    declarada: **golpe de troca fica em 0.50–0.62 s**. É mais lento que os
    0.317 s do original — porque o original tinha ZERO quadro segurado, e a
    regra 7 é a que mais muda a leitura — e mais rápido que os 0.8 s da tabela,
    porque a 0.8 s uma briga de rua vira coreografia.

    O que NÃO é negociado é a regra 7: toda sequência daqui tem pelo menos um
    passo segurado. Movimento contínuo lê como flutuação; movimento em rajada
    lê como força.

    Ultimate e transformação seguem a tabela sem desconto:
      finalizador   1.50 s, 64% de preparação, 2 segurados  (regra 5)
      virar pedra   2.00 s, 2 : 98                          (regra 4)

QUEM LIDERA (regra 6)

    empurrão, avanço e combo saem do TRONCO (HRP)
    soco, corte e conjuração saem do BRAÇO (RightArm)

    Por isso os combos do Taco e do Cano lideram por HRP, e o tiro, o gole e a
    provocação lideram por RightArm.

NENHUMA POSE FOI COPIADA

    O `Cano` e o `Taco` originais têm 78 escritas em `Weld.C0` na convenção
    deste animator — dava para copiar e passaria em todo verificador. O que foi
    aproveitado deles é PROPORÇÃO e DURAÇÃO. A silhueta abaixo é escrita aqui.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")


def rad(g):
    return "math.rad(%s)" % g


def pose(**juntas):
    return juntas


def J(x, y, z, rx=0, ry=0, rz=0):
    """Uma junta: posição + ângulos em graus."""
    return (x, y, z, rx, ry, rz)


def P(nome, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=nome, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


BASE = {
    "RightArm": (1.5, 0, 0),
    "LeftArm": (-1.5, 0, 0),
    "Head": (0, 1.5, 0),
    "HRP": (0, 0, 0),
    "RightLeg": (0.5, -2, 0),
    "LeftLeg": (-0.5, -2, 0),
}
ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")


# ═══════════════════════════════════════════════════════════════
# AS 7 TOOLS
#
# formato: nome -> (lidera, poses, sequências)
#   poses:      NOME -> { junta: J(x,y,z, rx,ry,rz) }
#   sequências: NOME -> (natureza, [P(...), ...])
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {

    # ─────────────────────────────────────────── Taco de Baseball
    "Taco de Baseball": ("HRP", {
        "IDLE": {
            "RightArm": J(1.46, 0.06, -0.34, 28, 6, 4),
            "LeftArm": J(-1.44, 0.02, -0.26, 20, -6, -6),
            "Head": J(0, 1.5, 0, -3, 8, 0),
            "HRP": J(0, 0, 0, 0, -14, 0),
        },
        "CARGA_A": {
            "RightArm": J(1.34, 0.62, -0.72, 118, 26, 30),
            "LeftArm": J(-1.28, 0.48, -0.66, 104, -22, -26),
            "Head": J(0, 1.5, 0, -8, 34, 0),
            "HRP": J(0, 0.04, 0, -4, -46, 0),
        },
        "BATE_A": {
            "RightArm": J(1.52, 0.24, -1.12, 74, -34, -12),
            "LeftArm": J(-1.34, 0.18, -0.92, 66, 30, 16),
            "Head": J(0, 1.5, 0, 6, -26, 0),
            "HRP": J(0, -0.06, 0, 6, 40, 0),
            "RightLeg": J(0.5, -1.88, -0.3, -16, 0, 0),
        },
        "CARGA_B": {
            "RightArm": J(1.3, 0.5, -0.4, 96, -30, -34),
            "LeftArm": J(-1.36, 0.56, -0.5, 108, 24, 22),
            "Head": J(0, 1.5, 0, -6, -30, 0),
            "HRP": J(0, 0.02, 0, -3, 42, 0),
        },
        "BATE_B": {
            "RightArm": J(1.48, 0.1, -1.06, 82, 38, 20),
            "LeftArm": J(-1.42, 0.06, -0.88, 70, -32, -18),
            "Head": J(0, 1.5, 0, 8, 30, 0),
            "HRP": J(0, -0.08, 0, 7, -44, 0),
            "LeftLeg": J(-0.5, -1.88, -0.3, -15, 0, 0),
        },
        "ERGUE": {
            "RightArm": J(1.4, 0.9, 0.12, 166, 8, 16),
            "LeftArm": J(-1.4, 0.86, 0.1, 162, -8, -14),
            "Head": J(0, 1.5, 0, -30, 0, 0),
            "HRP": J(0, 0.1, 0, -12, 0, 0),
        },
        "DESCE": {
            "RightArm": J(1.5, -0.3, -0.96, 30, -6, -10),
            "LeftArm": J(-1.5, -0.28, -0.9, 28, 6, 9),
            "Head": J(0, 1.5, 0, 22, 0, 0),
            "HRP": J(0, -0.34, 0, 22, 0, 0),
            "RightLeg": J(0.62, -1.72, -0.42, -26, 0, 0),
            "LeftLeg": J(-0.5, -1.94, 0.16, 9, 0, 0),
        },
    }, {
        # combo: 35 : 65 (regra 3) · 0.52 s
        "GOLPE_A": ("combo", [
            P("CARGA_A", 0.1, "Back", "In", "CARGA"),
            P("CARGA_A", 0.08, "Sine", "InOut"),
            P("BATE_A", 0.07, "Quint", "Out", "BATE"),
            P("BATE_A", 0.11, "Sine", "InOut"),
            P("IDLE", 0.16, "Quad", "Out"),
        ]),
        "GOLPE_B": ("combo", [
            P("CARGA_B", 0.1, "Back", "In", "CARGA"),
            P("CARGA_B", 0.08, "Sine", "InOut"),
            P("BATE_B", 0.07, "Quint", "Out", "BATE"),
            P("BATE_B", 0.11, "Sine", "InOut"),
            P("IDLE", 0.16, "Quad", "Out"),
        ]),
        # ultimate curto: 1.50 s, 64% de preparação, 2 segurados (regra 5)
        "FINALIZADOR": ("ultimate", [
            P("ERGUE", 0.3, "Back", "In", "ERGUE", 0.02, 18),
            P("ERGUE", 0.36, "Sine", "InOut", None, 0.035, 22),
            P("ERGUE", 0.3, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("DESCE", 0.12, "Quint", "Out", "IMPACTO"),
            P("DESCE", 0.18, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out", "SOLTA"),
        ]),
    }),

    # ─────────────────────────────────────────── Cano De Rua
    "Cano De Rua": ("HRP", {
        "IDLE": {
            "RightArm": J(1.48, 0.02, -0.2, 18, 4, 6),
            "LeftArm": J(-1.5, 0, -0.08, 8, 0, -4),
            "Head": J(0, 1.5, 0, -2, 6, 0),
            "HRP": J(0, 0, 0, 0, -10, 0),
        },
        "CARGA_A": {
            "RightArm": J(1.26, 0.7, -0.3, 132, 34, 26),
            "LeftArm": J(-1.44, 0.2, -0.44, 52, -14, -18),
            "Head": J(0, 1.5, 0, -10, 30, 0),
            "HRP": J(0, 0.04, 0, -5, -40, 0),
        },
        "BATE_A": {
            "RightArm": J(1.54, 0.06, -1.14, 88, -30, -16),
            "LeftArm": J(-1.4, 0.02, -0.72, 44, 22, 14),
            "Head": J(0, 1.5, 0, 8, -22, 0),
            "HRP": J(0, -0.05, 0, 6, 36, 0),
            "RightLeg": J(0.5, -1.9, -0.26, -13, 0, 0),
        },
        "CARGA_B": {
            "RightArm": J(1.44, 0.74, -0.16, 148, -22, -18),
            "LeftArm": J(-1.3, 0.3, -0.4, 62, 18, 20),
            "Head": J(0, 1.5, 0, -14, -24, 0),
            "HRP": J(0, 0.05, 0, -6, 36, 0),
        },
        "BATE_B": {
            "RightArm": J(1.5, -0.16, -1.02, 44, 12, 8),
            "LeftArm": J(-1.46, -0.1, -0.66, 34, -16, -12),
            "Head": J(0, 1.5, 0, 16, 12, 0),
            "HRP": J(0, -0.18, 0, 14, -20, 0),
            "LeftLeg": J(-0.5, -1.86, -0.32, -17, 0, 0),
        },
        "CONC_CARGA": {
            "RightArm": J(1.38, 0.86, 0.06, 158, 14, 20),
            "LeftArm": J(-1.38, 0.82, 0.04, 154, -12, -18),
            "Head": J(0, 1.5, 0, -26, 0, 0),
            "HRP": J(0, 0.08, 0, -10, 0, 0),
        },
        "CONC_BATE": {
            "RightArm": J(1.5, -0.36, -0.88, 22, -4, -8),
            "LeftArm": J(-1.5, -0.34, -0.84, 20, 4, 7),
            "Head": J(0, 1.5, 0, 24, 0, 0),
            "HRP": J(0, -0.4, 0, 24, 0, 0),
            "RightLeg": J(0.58, -1.76, -0.38, -22, 0, 0),
            "LeftLeg": J(-0.5, -1.92, 0.14, 8, 0, 0),
        },
    }, {
        "GOLPE_A": ("combo", [
            P("CARGA_A", 0.09, "Back", "In", "CARGA"),
            P("CARGA_A", 0.08, "Sine", "InOut"),
            P("BATE_A", 0.07, "Quint", "Out", "BATE"),
            P("BATE_A", 0.1, "Sine", "InOut"),
            P("IDLE", 0.16, "Quad", "Out"),
        ]),
        "GOLPE_B": ("combo", [
            P("CARGA_B", 0.09, "Back", "In", "CARGA"),
            P("CARGA_B", 0.08, "Sine", "InOut"),
            P("BATE_B", 0.07, "Quint", "Out", "BATE"),
            P("BATE_B", 0.1, "Sine", "InOut"),
            P("IDLE", 0.16, "Quad", "Out"),
        ]),
        # golpe pesado: 1.10 s, impacto a 59% (regra 2), 1 segurado
        "CONCUSSAO": ("golpe pesado", [
            P("CONC_CARGA", 0.26, "Back", "In", "ERGUE", 0.025, 19),
            P("CONC_CARGA", 0.39, "Sine", "InOut", "SEGURA", 0.04, 25),
            P("CONC_BATE", 0.11, "Quint", "Out", "IMPACTO"),
            P("CONC_BATE", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
    }),

    # ─────────────────────────────────────────── Abacate
    "Abacate (roubado) do mexico": ("RightArm", {
        "IDLE": {
            "RightArm": J(1.48, 0.04, -0.22, 22, 4, 5),
            "LeftArm": J(-1.5, 0, 0, 4, 0, -3),
            "Head": J(0, 1.5, 0, -2, 4, 0),
            "HRP": J(0, 0, 0, 0, -6, 0),
        },
        "LEVA_BOCA": {
            "RightArm": J(1.16, 0.66, -0.62, 116, 30, 42),
            "LeftArm": J(-1.5, 0.02, -0.06, 8, 0, -4),
            "Head": J(0, 1.5, 0, -14, -8, 0),
            "HRP": J(0, 0.02, 0, -3, 8, 0),
        },
        "MASTIGA": {
            "RightArm": J(1.14, 0.6, -0.58, 110, 28, 40),
            "LeftArm": J(-1.5, 0.02, -0.06, 8, 0, -4),
            "Head": J(0, 1.5, 0, -6, -10, 0),
            "HRP": J(0, -0.02, 0, 2, 8, 0),
        },
        "ARREMESSO_CARGA": {
            "RightArm": J(1.3, 0.72, 0.26, 154, 18, 24),
            "LeftArm": J(-1.44, 0.12, -0.34, 38, -10, -14),
            "Head": J(0, 1.5, 0, -18, 12, 0),
            "HRP": J(0, 0.04, 0, -7, -20, 0),
        },
        "ARREMESSO_SOLTA": {
            "RightArm": J(1.46, 0.16, -1.02, 56, -14, -10),
            "LeftArm": J(-1.48, 0.04, -0.5, 26, 10, 8),
            "Head": J(0, 1.5, 0, 8, -8, 0),
            "HRP": J(0, -0.06, 0, 8, 18, 0),
        },
    }, {
        # consumo: 1.20 s, 2 segurados — a mastigada É o quadro segurado
        "COMER": ("consumo", [
            P("LEVA_BOCA", 0.24, "Back", "Out", "LEVA"),
            P("MASTIGA", 0.18, "Sine", "InOut", "MORDE"),
            P("LEVA_BOCA", 0.16, "Sine", "InOut"),
            P("MASTIGA", 0.18, "Sine", "InOut"),
            P("MASTIGA", 0.2, "Sine", "InOut", "ENGOLE"),
            P("IDLE", 0.24, "Quad", "Out", "CURA"),
        ]),
        # golpe rápido: 0.62 s, impacto a 50% (regra 2)
        "ARREMESSO": ("golpe rápido", [
            P("ARREMESSO_CARGA", 0.14, "Back", "In", "CARGA"),
            P("ARREMESSO_CARGA", 0.17, "Sine", "InOut"),
            P("ARREMESSO_SOLTA", 0.09, "Quint", "Out", "SOLTA"),
            P("ARREMESSO_SOLTA", 0.08, "Sine", "InOut"),
            P("IDLE", 0.14, "Quad", "Out"),
        ]),
    }),

    # ─────────────────────────────────────────── Energetico
    "Energetico": ("RightArm", {
        "IDLE": {
            "RightArm": J(1.48, 0.04, -0.2, 20, 4, 5),
            "LeftArm": J(-1.5, 0, 0, 4, 0, -3),
            "Head": J(0, 1.5, 0, -2, 4, 0),
            "HRP": J(0, 0, 0, 0, -6, 0),
        },
        "ERGUE_LATA": {
            "RightArm": J(1.1, 0.78, -0.44, 138, 26, 46),
            "LeftArm": J(-1.5, 0.02, -0.04, 6, 0, -4),
            "Head": J(0, 1.5, 0, -32, -6, 0),
            "HRP": J(0, 0.03, 0, -8, 6, 0),
        },
        "VIRA": {
            "RightArm": J(1.04, 0.86, -0.36, 152, 22, 52),
            "LeftArm": J(-1.5, 0.02, -0.04, 6, 0, -4),
            "Head": J(0, 1.5, 0, -44, -4, 0),
            "HRP": J(0, 0.05, 0, -13, 4, 0),
        },
        "AMASSA": {
            "RightArm": J(1.32, 0.3, -0.6, 74, 18, 26),
            "LeftArm": J(-1.34, 0.28, -0.56, 70, -16, -24),
            "Head": J(0, 1.5, 0, 6, 0, 0),
            "HRP": J(0, -0.1, 0, 8, 0, 0),
        },
        "JOGA": {
            "RightArm": J(1.48, 0.12, -1.04, 52, -16, -12),
            "LeftArm": J(-1.46, 0.06, -0.46, 24, 12, 9),
            "Head": J(0, 1.5, 0, 8, -10, 0),
            "HRP": J(0, -0.04, 0, 7, 20, 0),
        },
    }, {
        # consumo: 1.30 s, 2 segurados
        "BEBER": ("consumo", [
            P("ERGUE_LATA", 0.26, "Back", "Out", "ERGUE"),
            P("VIRA", 0.18, "Quad", "InOut", "VIRA"),
            P("VIRA", 0.34, "Sine", "InOut"),
            P("VIRA", 0.26, "Sine", "InOut", "ULTIMO_GOLE"),
            P("IDLE", 0.26, "Quad", "Out", "CURA"),
        ]),
        # golpe rápido: 0.70 s, impacto a 54%
        "LATA": ("golpe rápido", [
            P("AMASSA", 0.16, "Back", "In", "AMASSA"),
            P("AMASSA", 0.22, "Sine", "InOut"),
            P("JOGA", 0.09, "Quint", "Out", "JOGA"),
            P("JOGA", 0.09, "Sine", "InOut"),
            P("IDLE", 0.14, "Quad", "Out"),
        ]),
    }),

    # ─────────────────────────────────────────── Humilhador
    "Humilhador": ("RightArm", {
        "IDLE": {
            "RightArm": J(1.5, 0, 0, 4, 0, 3),
            "LeftArm": J(-1.5, 0, 0, 4, 0, -3),
            "Head": J(0, 1.5, 0, 0, 0, 0),
            "HRP": J(0, 0, 0, 0, 0, 0),
        },
        "APONTA": {
            "RightArm": J(1.46, 0.34, -0.94, 88, -12, -6),
            "LeftArm": J(-1.42, -0.06, 0.22, -16, 8, -14),
            "Head": J(0, 1.5, 0, -6, -10, 0),
            "HRP": J(0, 0.02, 0, -4, 14, 0),
        },
        "RI": {
            "RightArm": J(1.4, 0.5, -0.72, 106, -16, -12),
            "LeftArm": J(-1.36, 0.24, -0.3, 54, 12, 18),
            "Head": J(0, 1.5, 0, -34, -6, 0),
            "HRP": J(0, 0.06, 0, -13, 10, 0),
        },
        "RODA_ABRE": {
            "RightArm": J(1.42, 0.66, 0.3, 150, -20, -22),
            "LeftArm": J(-1.42, 0.66, 0.3, 150, 20, 22),
            "Head": J(0, 1.5, 0, -30, 0, 0),
            "HRP": J(0, 0.07, 0, -12, 0, 0),
        },
        "RODA_GIRA": {
            "RightArm": J(1.44, 0.58, 0.16, 138, -26, -28),
            "LeftArm": J(-1.44, 0.58, 0.16, 138, 26, 28),
            "Head": J(0, 1.5, 0, -22, 0, 0),
            "HRP": J(0, 0.05, 0, -9, 180, 0),
        },
    }, {
        # provocação: 1.25 s — o tempo do sprite original, mantido de propósito
        "PROVOCA": ("provocação", [
            P("APONTA", 0.2, "Back", "Out", "APONTA"),
            P("RI", 0.16, "Quad", "Out", "SPRITE"),
            P("APONTA", 0.14, "Sine", "InOut"),
            P("RI", 0.14, "Sine", "InOut"),
            P("RI", 0.35, "Sine", "InOut"),
            P("IDLE", 0.26, "Quad", "Out", "FIM"),
        ]),
        # transformação de postura: 1.60 s, com o giro sustentado
        "RODA": ("provocação", [
            P("RODA_ABRE", 0.22, "Back", "Out", "ABRE"),
            P("RODA_GIRA", 0.34, "Sine", "InOut", "GIRA"),
            P("RODA_GIRA", 0.44, "Sine", "InOut"),
            P("RODA_ABRE", 0.3, "Sine", "InOut", "PULSO"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
    }),

    # ─────────────────────────────────────────── Diamond
    "Diamond": ("RightArm", {
        "IDLE": {
            "RightArm": J(1.48, 0.04, -0.24, 24, 4, 5),
            "LeftArm": J(-1.5, 0, -0.04, 6, 0, -4),
            "Head": J(0, 1.5, 0, -2, 5, 0),
            "HRP": J(0, 0, 0, 0, -8, 0),
        },
        "TAPA_CARGA": {
            "RightArm": J(1.24, 0.68, 0.18, 146, 30, 34),
            "LeftArm": J(-1.44, 0.1, -0.3, 34, -10, -12),
            "Head": J(0, 1.5, 0, -12, 26, 0),
            "HRP": J(0, 0.04, 0, -5, -34, 0),
        },
        "TAPA_BATE": {
            "RightArm": J(1.52, 0.12, -1.16, 78, -36, -18),
            "LeftArm": J(-1.42, 0.04, -0.6, 30, 20, 12),
            "Head": J(0, 1.5, 0, 8, -28, 0),
            "HRP": J(0, -0.06, 0, 7, 38, 0),
            "RightLeg": J(0.5, -1.9, -0.24, -12, 0, 0),
        },
        "PEDRA_FECHA": {
            "RightArm": J(1.36, -0.2, -0.5, 42, 0, 26),
            "LeftArm": J(-1.36, -0.2, -0.5, 42, 0, -26),
            "Head": J(0, 1.5, 0, 18, 0, 0),
            "HRP": J(0, -0.12, 0, 12, 0, 0),
            "RightLeg": J(0.5, -1.94, -0.1, -5, 0, 0),
            "LeftLeg": J(-0.5, -1.94, -0.1, -5, 0, 0),
        },
        "PEDRA_ABRE": {
            "RightArm": J(1.46, 0.4, -0.62, 96, -14, -14),
            "LeftArm": J(-1.46, 0.4, -0.62, 96, 14, 14),
            "Head": J(0, 1.5, 0, -22, 0, 0),
            "HRP": J(0, 0.06, 0, -10, 0, 0),
        },
    }, {
        # golpe rápido: 0.62 s, impacto a 50%
        "TAPA": ("golpe rápido", [
            P("TAPA_CARGA", 0.13, "Back", "In", "CARGA"),
            P("TAPA_CARGA", 0.18, "Sine", "InOut"),
            P("TAPA_BATE", 0.08, "Quint", "Out", "BATE"),
            P("TAPA_BATE", 0.09, "Sine", "InOut"),
            P("IDLE", 0.14, "Quad", "Out"),
        ]),
        # transformação: 2.00 s, 2 : 98 (regra 4) — abre no primeiro quadro e
        # passa o resto do tempo sustentando
        "PEDRA": ("transformação", [
            P("PEDRA_FECHA", 0.05, "Quint", "Out", "FECHA"),
            P("PEDRA_FECHA", 0.7, "Sine", "InOut", None, 0.02, 15),
            P("PEDRA_FECHA", 0.75, "Sine", "InOut", "SUSTENTA", 0.03, 19),
            P("PEDRA_ABRE", 0.2, "Back", "Out", "ABRE"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
    }),

    # ─────────────────────────────────────────── A arma
    "A arma": ("RightArm", {
        "IDLE": {
            "RightArm": J(1.48, 0.06, -0.3, 30, 4, 5),
            "LeftArm": J(-1.5, 0, -0.02, 5, 0, -4),
            "Head": J(0, 1.5, 0, -2, 4, 0),
            "HRP": J(0, 0, 0, 0, -6, 0),
        },
        "MIRA": {
            "RightArm": J(1.44, 0.44, -1.0, 92, -8, -4),
            "LeftArm": J(-1.14, 0.4, -0.96, 88, 22, 26),
            "Head": J(0, 1.5, 0, -4, -6, 0),
            "HRP": J(0, 0.01, 0, -2, 16, 0),
        },
        "COICE": {
            "RightArm": J(1.42, 0.62, -0.8, 112, -10, -6),
            "LeftArm": J(-1.16, 0.54, -0.8, 104, 20, 24),
            "Head": J(0, 1.5, 0, -12, -6, 0),
            "HRP": J(0, 0.03, 0, -6, 14, 0),
        },
        "ABRE_TAMBOR": {
            "RightArm": J(1.3, 0.3, -0.86, 78, 14, 22),
            "LeftArm": J(-1.24, 0.34, -0.82, 84, -12, -20),
            "Head": J(0, 1.5, 0, -20, 8, 0),
            "HRP": J(0, -0.02, 0, -5, 8, 0),
        },
        "FECHA_TAMBOR": {
            "RightArm": J(1.4, 0.42, -0.9, 88, 4, 10),
            "LeftArm": J(-1.4, 0.1, -0.34, 34, -8, -10),
            "Head": J(0, 1.5, 0, -8, 4, 0),
            "HRP": J(0, 0, 0, -2, 6, 0),
        },
    }, {
        # tiro: 0.34 s. É o único do conjunto abaixo de 0.5 s, e de propósito —
        # coice de revólver não é golpe de troca, é reação: sobe e volta.
        "TIRO": ("reação", [
            P("COICE", 0.05, "Quint", "Out", "DISPARA"),
            P("COICE", 0.08, "Sine", "InOut"),
            P("MIRA", 0.21, "Quad", "Out"),
        ]),
        "APONTAR": ("guarda", [
            P("MIRA", 0.22, "Quad", "Out", "APONTA"),
        ]),
        # recarga: 1.40 s, 2 segurados
        "RECARGA": ("manejo", [
            P("ABRE_TAMBOR", 0.22, "Back", "Out", "ABRE"),
            P("ABRE_TAMBOR", 0.3, "Sine", "InOut", "EJETA"),
            P("ABRE_TAMBOR", 0.38, "Sine", "InOut", "ENCHE"),
            P("FECHA_TAMBOR", 0.16, "Quint", "Out", "FECHA"),
            P("MIRA", 0.16, "Quad", "Out"),
            P("IDLE", 0.18, "Quad", "Out", "PRONTO"),
        ]),
    }),
}


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rz and rad(rz) or "0"))


def escrever(tool, lidera, poses, sequencias):
    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto GUEST)" % tool)
    L.append("--")
    L.append("-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:")
    L.append("--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·")
    L.append("--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)")
    L.append("--")
    L.append("-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.")
    L.append("--")
    L.append("-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama")
    L.append("-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava")
    L.append("-- a caminhada — e é exatamente o bug que o `Taco de Baseball` original tinha:")
    L.append("-- ele soldava as duas pernas no finalizador e o `Unequipped` não as soltava.")
    L.append("--")
    L.append("-- JUNTA QUE LIDERA: **%s** (regra 6 da gramática)." % lidera)
    L.append("--")
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        segurados = sum(1 for i, p in enumerate(passos)
                        if i > 0 and p["pose"] == passos[i - 1]["pose"])
        L.append("--   %-12s %-14s %.2fs · %d passo(s), %d segurado(s)"
                 % (nome, natureza, total, len(passos), segurados))
    L.append("--")
    L.append("-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e")
    L.append("-- duração; a silhueta é escrita aqui.")
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_guest.py.")
    L.append("")
    L.append("local P = {}")
    L.append("")

    for nome in sorted(poses):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in poses[nome]:
                L.append(linha_junta(junta, poses[nome][junta]))
        L.append("}")

    L.append("")
    L.append("P.SEQUENCIAS = {")
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        segurados = sum(1 for i, p in enumerate(passos)
                        if i > 0 and p["pose"] == passos[i - 1]["pose"])
        L.append("")
        L.append("\t-- %s · %.2fs · %d passo(s), %d segurado(s)"
                 % (natureza, total, len(passos), segurados))
        L.append("\t%s = {" % nome)
        for p in passos:
            campos = ["pose = %r" % p["pose"], "time = %s" % p["time"],
                      "style = %r" % p["style"], "dir = %r" % p["dir"]]
            if p["tremor"]:
                campos.append("tremor = %s" % p["tremor"])
            if p["freq"]:
                campos.append("freq = %s" % p["freq"])
            if p["marca"]:
                campos.append("marca = %r" % p["marca"])
            L.append("\t\t{ %s }," % ", ".join(campos).replace("'", '"'))
        L.append("\t},")
    L.append("")
    L.append("}")
    L.append("")
    L.append("return P")
    return "\n".join(L) + "\n"


def main():
    for tool, (lidera, poses, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        texto = escrever(tool, lidera, poses, sequencias)
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(texto)
        total = sum(sum(p["time"] for p in passos)
                    for _n, (_nat, passos) in sequencias.items())
        print("%-28s %d pose(s) · %d sequência(s) · %.2fs no total"
              % (tool, len(poses), len(sequencias), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
