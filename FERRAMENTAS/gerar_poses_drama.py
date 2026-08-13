#!/usr/bin/env python3
"""
gerar_poses_drama.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto DRAMA.

    python3 FERRAMENTAS/gerar_poses_drama.py

ESTE CONJUNTO É O QUE MAIS USA A GRAMÁTICA, E O QUE MAIS A TESTA

    `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md` foi medida
    em nove sequências do Saitama — **soco, empurrão, uppercut e combo**. É
    exatamente o repertório deste conjunto. Aqui não há desconto a pedir: as
    regras 1, 2, 3, 5 e 7 valem ao pé da letra.

    | Regra | O que diz | Onde aparece |
    |---|---|---|
    | 1 | golpe rápido vive entre 0.8 s e 1.2 s | `SOCO_A/B/C`, `CORTE` |
    | 2 | o impacto cai na METADE, não no fim | os mesmos, ~50% |
    | 3 | combo inverte para 35 : 65 | `COMBO_1..4` do TryHard |
    | 5 | ultimate 7–9 s com 64–86% de preparação | `FINALIZADOR` (7.60 s, 76%) |
    | 7 | estas animações são, em maioria, PARADAS | quadro segurado em todas |

    A ressalva que o conjunto GUEST levantou — golpe de troca de rua vive em
    0.3–0.6 s, não em 0.8–1.2 s — **não se aplica aqui**, e é decisão declarada:
    o `Combate` e o `TryHard` são briga ENCENADA, com combo e finalizador, que é
    o caso que o Saitama mede. O `Desviar e Empurrar` é o único que corre: a
    esquiva sai em 0.62 s, porque esquiva lenta não é esquiva.

QUEM LIDERA (regra 6)

    "Empurrão, avanço e combo saem do TRONCO. Soco, corte e conjuração saem do
    BRAÇO."

    | Tool | lidera | por quê |
    |---|---|---|
    | `Combate` | **HRP** | é combo — a regra 6 mede `CONSECUTIVE_PUNCHES` no HRP |
    | `Desviar e Empurrar` | **HRP** | empurrão e avanço, os dois do tronco |
    | `Corte Frio` | RightArm | corte |
    | `Impacto Forte` | RightArm | soco |
    | `Aura` | RightArm | conjuração |
    | `Olhos Laser` | Head | **exceção declarada** — quem mira é a cabeça |
    | `TryHard` | **HRP** | combo de quatro |

    `Olhos Laser` é a única junta líder que a gramática não prevê. Está aqui
    porque a alternativa era pior: um feixe que sai dos olhos conduzido pelo
    braço lê como se a mão estivesse atirando.
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
# O VOCABULÁRIO DO CONJUNTO
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.46, 0.06, -0.3, 26, 5, 5),
        "LeftArm": J(-1.46, 0.06, -0.3, 26, -5, -5),
        "Head": J(0, 1.5, 0, -3, 4, 0),
        "HRP": J(0, 0, 0, 0, -8, 0),
    },
    # guarda de briga: as duas mãos acima da linha do queixo
    "GUARDA": {
        "RightArm": J(1.34, 0.46, -0.66, 96, -12, -24),
        "LeftArm": J(-1.3, 0.52, -0.7, 102, 14, 26),
        "Head": J(0, 1.5, 0, -6, 10, 0),
        "HRP": J(0, 0.02, 0, -3, -18, 0),
    },
    "SOCO_DIR": {
        "RightArm": J(1.5, 0.4, -1.16, 92, -8, -4),
        "LeftArm": J(-1.28, 0.5, -0.6, 104, 18, 30),
        "Head": J(0, 1.5, 0, -2, -14, 0),
        "HRP": J(0, -0.02, 0, 3, 26, 0),
        "RightLeg": J(0.5, -1.9, -0.24, -12, 0, 0),
    },
    "SOCO_ESQ": {
        "RightArm": J(1.28, 0.5, -0.6, 104, -18, -30),
        "LeftArm": J(-1.5, 0.4, -1.16, 92, 8, 4),
        "Head": J(0, 1.5, 0, -2, 14, 0),
        "HRP": J(0, -0.02, 0, 3, -26, 0),
        "LeftLeg": J(-0.5, -1.9, -0.24, -12, 0, 0),
    },
    # gancho: vem de baixo, e o tronco gira junto
    "GANCHO": {
        "RightArm": J(1.44, -0.08, -0.96, 54, -26, -16),
        "LeftArm": J(-1.32, 0.44, -0.5, 92, 16, 24),
        "Head": J(0, 1.5, 0, -12, -18, 0),
        "HRP": J(0, 0.06, 0, -8, 34, 0),
        "RightLeg": J(0.52, -1.86, -0.3, -16, 0, 0),
    },
    "CHUTE_CARGA": {
        "RightArm": J(1.5, 0.3, -0.4, 62, -14, -12),
        "LeftArm": J(-1.5, 0.3, -0.4, 62, 14, 12),
        "Head": J(0, 1.5, 0, -6, 24, 0),
        "HRP": J(0, 0.04, 0, -4, -40, 0),
        "RightLeg": J(0.5, -1.7, -0.5, -34, 0, 0),
    },
    "CHUTE_GIRA": {
        "RightArm": J(1.56, 0.2, 0.3, -14, -20, -46),
        "LeftArm": J(-1.56, 0.2, 0.3, -14, 20, 46),
        "Head": J(0, 1.5, 0, 4, -30, 0),
        "HRP": J(0, -0.04, 0, 5, 150, 0),
        "RightLeg": J(0.66, -1.5, -0.9, -78, 0, -14),
        "LeftLeg": J(-0.5, -1.94, 0.1, 6, 0, 0),
    },
    "EMPURRA_CARGA": {
        "RightArm": J(1.36, 0.34, -0.44, 76, -16, -22),
        "LeftArm": J(-1.36, 0.34, -0.44, 76, 16, 22),
        "Head": J(0, 1.5, 0, -8, 0, 0),
        "HRP": J(0, 0.04, 0, -10, 0, 0),
    },
    "EMPURRA_SOLTA": {
        "RightArm": J(1.5, 0.36, -1.2, 90, -4, -2),
        "LeftArm": J(-1.5, 0.36, -1.2, 90, 4, 2),
        "Head": J(0, 1.5, 0, 4, 0, 0),
        "HRP": J(0, -0.06, 0, 10, 0, 0),
        "RightLeg": J(0.5, -1.88, -0.3, -14, 0, 0),
    },
    # esquiva: corpo baixo e torcido, braços recolhidos
    "ESQUIVA": {
        "RightArm": J(1.3, -0.16, -0.36, 44, -20, -34),
        "LeftArm": J(-1.3, -0.16, -0.36, 44, 20, 34),
        "Head": J(0, 1.5, 0, 16, -28, 0),
        "HRP": J(0, -0.66, 0, 34, 34, 0),
        "RightLeg": J(0.5, -1.5, -0.7, -50, 0, 0),
        "LeftLeg": J(-0.5, -1.62, 0.4, 26, 0, 0),
    },
    # espada
    "LAMINA_ERGUE": {
        "RightArm": J(1.36, 0.78, -0.2, 142, 16, 18),
        "LeftArm": J(-1.44, 0.2, -0.42, 46, -12, -14),
        "Head": J(0, 1.5, 0, -18, 22, 0),
        "HRP": J(0, 0.06, 0, -8, -32, 0),
    },
    "LAMINA_CORTA": {
        "RightArm": J(1.52, 0.02, -1.14, 74, -34, -18),
        "LeftArm": J(-1.42, -0.02, -0.66, 38, 24, 16),
        "Head": J(0, 1.5, 0, 8, -26, 0),
        "HRP": J(0, -0.06, 0, 7, 38, 0),
        "RightLeg": J(0.5, -1.9, -0.26, -13, 0, 0),
    },
    # a estocada da execução: braço reto, corpo à frente
    "ESTOCADA": {
        "RightArm": J(1.5, 0.42, -1.3, 96, -4, -2),
        "LeftArm": J(-1.5, 0.1, -0.3, 30, 8, 10),
        "Head": J(0, 1.5, 0, -2, -6, 0),
        "HRP": J(0, -0.12, 0, 16, 12, 0),
        "RightLeg": J(0.5, -1.82, -0.44, -22, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.28, 16, 0, 0),
    },
    # aura: braços abertos, cabeça para trás
    "AURA_ABRE": {
        "RightArm": J(1.56, 0.16, 0.42, -28, -14, -50),
        "LeftArm": J(-1.56, 0.16, 0.42, -28, 14, 50),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.1, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.88, 0.2, 12, 0, 0),
        "LeftLeg": J(-0.5, -1.88, 0.2, 12, 0, 0),
    },
    "AURA_FECHA": {
        "RightArm": J(1.4, -0.1, -0.5, 44, 12, 22),
        "LeftArm": J(-1.4, -0.1, -0.5, 44, -12, -22),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.08, 0, 8, 0, 0),
    },
    # olhos: a cabeça é quem conduz
    "MIRA_OLHOS": {
        "RightArm": J(1.5, 0.06, -0.24, 22, -4, -6),
        "LeftArm": J(-1.5, 0.06, -0.24, 22, 4, 6),
        "Head": J(0, 1.5, 0, -14, 0, 0),
        "HRP": J(0, 0.02, 0, -4, 0, 0),
    },
    "FEIXE_OLHOS": {
        "RightArm": J(1.54, -0.06, 0.16, -12, -6, -18),
        "LeftArm": J(-1.54, -0.06, 0.16, -12, 6, 18),
        "Head": J(0, 1.5, 0, -26, 0, 0),
        "HRP": J(0, 0.06, 0, -12, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.16, 9, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.16, 9, 0, 0),
    },
    "VARRE_OLHOS": {
        "RightArm": J(1.54, -0.06, 0.16, -12, -6, -18),
        "LeftArm": J(-1.54, -0.06, 0.16, -12, 6, 18),
        "Head": J(0, 1.5, 0, -22, 44, 0),
        "HRP": J(0, 0.06, 0, -10, 12, 0),
        "RightLeg": J(0.5, -1.9, 0.16, 9, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.16, 9, 0, 0),
    },
}


# alvo -> (lidera, sequências)
CONJUNTO = {

    "Combate": ("HRP", {
        # combo: 35 : 65 (regra 3) · 1.00 s cada, dentro da regra 1
        "SOCO_A": ("combo", [
            P("GUARDA", 0.2, "Back", "In", "CARGA"),
            P("GUARDA", 0.15, "Sine", "InOut"),
            P("SOCO_DIR", 0.1, "Quint", "Out", "BATE"),
            P("SOCO_DIR", 0.2, "Sine", "InOut"),
            P("GUARDA", 0.35, "Quad", "Out"),
        ]),
        "SOCO_B": ("combo", [
            P("GUARDA", 0.2, "Back", "In", "CARGA"),
            P("GUARDA", 0.15, "Sine", "InOut"),
            P("SOCO_ESQ", 0.1, "Quint", "Out", "BATE"),
            P("SOCO_ESQ", 0.2, "Sine", "InOut"),
            P("GUARDA", 0.35, "Quad", "Out"),
        ]),
        "SOCO_C": ("combo", [
            P("GUARDA", 0.22, "Back", "In", "CARGA"),
            P("GUARDA", 0.16, "Sine", "InOut"),
            P("GANCHO", 0.12, "Quint", "Out", "BATE"),
            P("GANCHO", 0.22, "Sine", "InOut"),
            P("IDLE", 0.38, "Quad", "Out", "FIM"),
        ]),
        # golpe rápido pesado: 1.20 s, impacto a 55%
        "CHUTE": ("golpe rápido", [
            P("CHUTE_CARGA", 0.24, "Back", "In", "GIRA"),
            P("CHUTE_CARGA", 0.42, "Sine", "InOut", "SEGURA", 0.03, 20),
            P("CHUTE_GIRA", 0.12, "Quint", "Out", "CHUTA"),
            P("CHUTE_GIRA", 0.18, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out"),
        ]),
    }),

    "Desviar e Empurrar": ("HRP", {
        # golpe rápido: 0.90 s, impacto a 51%
        "EMPURRAO": ("golpe rápido", [
            P("EMPURRA_CARGA", 0.2, "Back", "In", "CARGA"),
            P("EMPURRA_CARGA", 0.26, "Sine", "InOut"),
            P("EMPURRA_SOLTA", 0.1, "Quint", "Out", "EMPURRA"),
            P("EMPURRA_SOLTA", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # 0.62 s — o único do conjunto abaixo da faixa da regra 1, e de
        # propósito: esquiva lenta não é esquiva. O `dodge` de origem media
        # `dhtime = 0.65`, e este número é dele.
        "ESQUIVA": ("reação", [
            P("ESQUIVA", 0.12, "Quint", "Out", "ENTRA"),
            P("ESQUIVA", 0.26, "Sine", "InOut", "IMUNE"),
            P("IDLE", 0.24, "Quad", "Out", "SAI"),
        ]),
    }),

    "Corte Frio": ("RightArm", {
        # golpe rápido: 1.00 s, impacto a 52%
        "CORTE": ("golpe rápido", [
            P("LAMINA_ERGUE", 0.22, "Back", "In", "ERGUE"),
            P("LAMINA_ERGUE", 0.3, "Sine", "InOut"),
            P("LAMINA_CORTA", 0.1, "Quint", "Out", "CORTA"),
            P("LAMINA_CORTA", 0.16, "Sine", "InOut"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
        # CUTSCENE · 4.60 s · 70% de preparação · 3 segurados
        # Abaixo dos 7 s da regra 5 de propósito: é execução de UM alvo, não
        # ultimate de área. A regra 5 mede ultimate de arena; cena de execução
        # longa demais vira punição para quem está esperando.
        "EXECUCAO": ("cutscene", [
            P("LAMINA_ERGUE", 0.35, "Back", "In", "CAMERA", 0.02, 16),
            P("LAMINA_ERGUE", 0.6, "Sine", "InOut", "ENCARA", 0.03, 20),
            P("ESTOCADA", 0.25, "Quint", "In", "AVANCA"),
            P("ESTOCADA", 0.7, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("ESTOCADA", 0.75, "Sine", "InOut", None, 0.06, 31),
            P("LAMINA_CORTA", 0.15, "Quint", "Out", "CORTA"),
            P("LAMINA_CORTA", 0.7, "Sine", "InOut"),
            P("IDLE", 1.1, "Quad", "Out", "FIM"),
        ]),
    }),

    "Impacto Forte": ("RightArm", {
        # golpe rápido pesado: 1.20 s, impacto a 58%
        "SOCO": ("golpe rápido", [
            P("GUARDA", 0.24, "Back", "In", "CARGA"),
            P("GUARDA", 0.46, "Sine", "InOut", "SEGURA", 0.035, 22),
            P("SOCO_DIR", 0.12, "Quint", "Out", "BATE"),
            P("SOCO_DIR", 0.16, "Sine", "InOut"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
        # conjuração pesada: 1.40 s
        "RACHA": ("golpe pesado", [
            P("CHUTE_CARGA", 0.26, "Back", "In", "ERGUE"),
            P("CHUTE_CARGA", 0.54, "Sine", "InOut", "SEGURA", 0.045, 24),
            P("EMPURRA_SOLTA", 0.14, "Quint", "Out", "RACHA"),
            P("EMPURRA_SOLTA", 0.2, "Sine", "InOut"),
            P("IDLE", 0.26, "Quad", "Out"),
        ]),
    }),

    "Aura": ("RightArm", {
        # transformação: 2.00 s, 2 : 98 (regra 4) — abre no primeiro quadro e
        # passa o resto sustentando
        "LIGAR": ("transformação", [
            P("AURA_ABRE", 0.05, "Quint", "Out", "LIGA"),
            P("AURA_ABRE", 0.7, "Sine", "InOut", None, 0.025, 17),
            P("AURA_ABRE", 0.75, "Sine", "InOut", "SUSTENTA", 0.035, 23),
            P("AURA_FECHA", 0.2, "Back", "Out", "FECHA"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
        # golpe rápido: 1.00 s
        "PULSO": ("golpe rápido", [
            P("AURA_FECHA", 0.22, "Back", "In", "RECOLHE"),
            P("AURA_FECHA", 0.28, "Sine", "InOut", None, 0.04, 25),
            P("AURA_ABRE", 0.12, "Quint", "Out", "SOLTA"),
            P("AURA_ABRE", 0.16, "Sine", "InOut"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
    }),

    "Olhos Laser": ("Head", {
        # conjuração: 1.00 s. Lidera pela CABEÇA — exceção declarada à regra 6.
        "FEIXE": ("conjuração", [
            P("MIRA_OLHOS", 0.2, "Quad", "Out", "MIRA"),
            P("FEIXE_OLHOS", 0.12, "Back", "Out", "ATIRA"),
            P("FEIXE_OLHOS", 0.3, "Sine", "InOut", None, 0.02, 26),
            P("MIRA_OLHOS", 0.16, "Quad", "Out"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
        # sustentada: 1.60 s — a varredura em leque
        "VARREDURA": ("sustentada", [
            P("MIRA_OLHOS", 0.2, "Back", "Out", "MIRA"),
            P("FEIXE_OLHOS", 0.14, "Quint", "Out", "ABRE"),
            P("VARRE_OLHOS", 0.42, "Sine", "InOut", "VARRE", 0.03, 28),
            P("VARRE_OLHOS", 0.36, "Sine", "InOut", "VARRE", 0.03, 28),
            P("FEIXE_OLHOS", 0.22, "Quad", "InOut", "FECHA"),
            P("IDLE", 0.26, "Quad", "Out"),
        ]),
    }),

    "TryHard": ("HRP", {
        # COMBO DE QUATRO · 35 : 65 na abertura (regra 3): o primeiro impacto
        # cai cedo porque o resto do tempo são os golpes seguintes.
        "COMBO_1": ("combo", [
            P("GUARDA", 0.14, "Back", "In", "CARGA"),
            P("GUARDA", 0.1, "Sine", "InOut"),
            P("SOCO_DIR", 0.08, "Quint", "Out", "BATE"),
            P("SOCO_DIR", 0.12, "Sine", "InOut"),
            P("GUARDA", 0.16, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_2": ("combo", [
            P("SOCO_ESQ", 0.1, "Quint", "Out", "BATE"),
            P("SOCO_ESQ", 0.14, "Sine", "InOut"),
            P("GUARDA", 0.16, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_3": ("combo", [
            P("GANCHO", 0.11, "Quint", "Out", "BATE"),
            P("GANCHO", 0.15, "Sine", "InOut"),
            P("GUARDA", 0.16, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_4": ("combo", [
            P("CHUTE_CARGA", 0.14, "Back", "In"),
            P("CHUTE_GIRA", 0.12, "Quint", "Out", "BATE_FORTE"),
            P("CHUTE_GIRA", 0.2, "Sine", "InOut"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
        # ULTIMATE COM CUTSCENE · 7.60 s · 76% de preparação (regra 5)
        "FINALIZADOR": ("ultimate", [
            P("GUARDA", 0.45, "Back", "In", "CAMERA", 0.02, 15),
            P("LAMINA_ERGUE", 0.75, "Quad", "InOut", "ERGUE", 0.03, 19),
            P("LAMINA_ERGUE", 1.0, "Sine", "InOut", "CARGA", 0.04, 23),
            P("LAMINA_ERGUE", 1.1, "Sine", "InOut", None, 0.055, 28),
            P("ESTOCADA", 0.4, "Quint", "In", "AVANCA"),
            P("ESTOCADA", 1.0, "Sine", "InOut", "SEGURA", 0.075, 33),
            P("ESTOCADA", 1.05, "Sine", "InOut", None, 0.09, 37),
            P("LAMINA_CORTA", 0.2, "Quint", "Out", "EXECUTA"),
            P("LAMINA_CORTA", 0.75, "Sine", "InOut"),
            P("IDLE", 0.9, "Quad", "Out", "FIM"),
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
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz) if rz else "0"))


def usadas(sequencias):
    nomes = set()
    for _nat, passos in sequencias.values():
        for p in passos:
            nomes.add(p["pose"])
    return nomes


def escrever(tool, lidera, poses, sequencias):
    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto DRAMA)" % tool)
    L.append("--")
    L.append("-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:")
    L.append("--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·")
    L.append("--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)")
    L.append("--")
    L.append("-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.")
    L.append("--")
    L.append("-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama")
    L.append("-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava")
    L.append("-- a caminhada.")
    L.append("--")
    L.append("-- JUNTA QUE LIDERA: **%s** (regra 6 da gramática)." % lidera)
    L.append("--")
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        segurados = sum(1 for i, p in enumerate(passos)
                        if i > 0 and p["pose"] == passos[i - 1]["pose"])
        L.append("--   %-14s %-16s %.2fs · %d passo(s), %d segurado(s)"
                 % (nome, natureza, total, len(passos), segurados))
    L.append("--")
    L.append("-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,")
    L.append("-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.")
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_drama.py.")
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
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        poses = {}
        for nome in usadas(sequencias):
            if nome not in BASE:
                print("pose %r não existe (Tool %s)" % (nome, tool))
                return 1
            poses[nome] = BASE[nome]
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias))
        total = sum(sum(p["time"] for p in passos)
                    for _n, (_nat, passos) in sequencias.items())
        print("%-20s %d pose(s) · %d sequência(s) · %.2fs no total"
              % (tool, len(poses), len(sequencias), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
