#!/usr/bin/env python3
"""
gerar_poses_xester_v2.py — Retro-Verse / Studios

Escreve o `Poses.lua` da Tool **Xester** — 13 habilidades e 3 cutscenes,
16 sequências numa Tool só.

    python3 FERRAMENTAS/gerar_poses_xester_v2.py

UMA TOOL, DOIS VOCABULÁRIOS DE CORPO

    A Tool troca de forma em jogo, então as duas gramáticas convivem no mesmo
    `Poses.lua`. Quem escolhe é o `Server`, pelo nome da sequência.

    Forma 1, o BARALHO: gesto de mão, carta e leque. O braço direito lidera
    quase tudo e o corpo quase não sai do lugar — mágico de salão não se
    debate.

    Forma 2, o DRAGÃO: o corpo entra inteiro, o HRP lidera o que é peso, e as
    pausas são mais longas. O cajado puxa o braço para fora do eixo.

AS CUTSCENES TÊM POSE PRÓPRIA, E BEAT PRÓPRIO

    `TRANSFORMAR` tem os seis beats do roteiro — MAO, NAIPES, CORINGA,
    CONGELA, RASGA, TITULO — e 3.0 s no total. `REVERTER` tem três e 1.8 s.
    `PAGINA_FINAL` tem quatro, para a ultimate `L`.

    O beat é o que o `Server` repassa para a câmera. A duração da sequência e a
    da cutscene são a MESMA coisa: quem manda o `FIM` é o fim da animação, não
    um `task.wait` paralelo que poderia dessincronizar.

REPARO REUSADO, NÃO REESCRITO

    O vocabulário de pose e os quatro moldes de ritmo (`rapido`, `conjura`,
    `pesado`, `sustentada`) vieram do gerador das 14 Tools, já conformados e
    verificados — o arquivo saiu do repositório junto com elas, e o conteúdo
    mora aqui agora. Só o que o desenho novo pede foi acrescentado: as poses de
    invisibilidade, anel de naipes, castelo, guarda real, sopro dracônico,
    prisma e as cinco da cutscene.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")

TOOL = "Xester"


# ═══════════════════════════════════════════════════════════════
# O VOCABULÁRIO DE POSE E OS MOLDES DE RITMO
#
# Vieram do gerador das 14 Tools, que saiu do repositório junto com elas. O
# conteúdo é o mesmo, verificado, e agora mora aqui — importar de um arquivo
# cujo único motivo de existir eram as 14 seria manter um morto de pé.
# ═══════════════════════════════════════════════════════════════

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

    # ── FORMA 1 — o baralho. Gesto de mão, corpo parado.
    "LEQUE": {
        "RightArm": J(1.44, 0.34, -0.62, 96, -22, -18),
        "LeftArm": J(-1.4, 0.28, -0.5, 82, 20, 22),
        "Head": J(0, 1.5, 0, -8, 6, 0),
        "HRP": J(0, 0.02, 0, -4, -6, 0),
    },
    "ATIRA_CARTA": {
        "RightArm": J(1.52, 0.3, -1.16, 92, -12, -6),
        "LeftArm": J(-1.42, 0.14, -0.4, 44, 16, 18),
        "Head": J(0, 1.5, 0, -2, -14, 0),
        "HRP": J(0, 0, 0, 2, 18, 0),
    },
    "CARTOLA": {
        "RightArm": J(1.4, 0.72, -0.24, 146, -14, -22),
        "LeftArm": J(-1.46, 0.08, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -18, 8, 0),
        "HRP": J(0, 0.05, 0, -10, -8, 0),
    },
    "SOME": {
        "RightArm": J(1.3, 0.2, -0.2, 60, -30, -44),
        "LeftArm": J(-1.3, 0.2, -0.2, 60, 30, 44),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.2, 0, 14, 0, 0),
    },
    "VENIA": {
        "RightArm": J(1.36, 0.12, -0.42, 58, -18, -30),
        "LeftArm": J(-1.34, -0.04, 0.16, 10, 14, 42),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.26, 0, 24, 0, 0),
    },
    "PALMA_ABERTA": {
        "RightArm": J(1.5, 0.32, -1.08, 88, -16, -8),
        "LeftArm": J(-1.5, 0.32, -1.08, 88, 16, 8),
        "Head": J(0, 1.5, 0, -4, 0, 0),
        "HRP": J(0, 0.02, 0, -2, 0, 0),
    },

    # ── FORMA 2 — o despertar. Cajado, machado, corpo inteiro.
    "CAJADO_ERGUE": {
        "RightArm": J(1.44, 0.84, -0.04, 168, -8, -14),
        "LeftArm": J(-1.46, 0.1, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.1, 0, -16, 0, 0),
    },
    "CAJADO_APONTA": {
        "RightArm": J(1.52, 0.36, -1.18, 90, -6, -4),
        "LeftArm": J(-1.44, 0.08, -0.3, 26, 8, 10),
        "Head": J(0, 1.5, 0, -5, -8, 0),
        "HRP": J(0, 0.02, 0, -3, 12, 0),
        "RightLeg": J(0.5, -1.88, -0.22, -10, 0, 0),
    },
    "CAJADO_CHAO": {
        "RightArm": J(1.42, -0.34, -0.4, 26, 10, 22),
        "LeftArm": J(-1.4, -0.2, -0.44, 34, -10, -18),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.44, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.52, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.66, -0.44, -30, 0, 0),
    },
    "MACHADO_ALTO": {
        "RightArm": J(1.4, 0.8, -0.1, 172, -10, -18),
        "LeftArm": J(-1.4, 0.8, -0.1, 172, 10, 18),
        "Head": J(0, 1.5, 0, -32, 0, 0),
        "HRP": J(0, 0.14, 0, -19, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.12, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.12, 8, 0, 0),
    },
    "MACHADO_DESCE": {
        "RightArm": J(1.44, -0.3, -0.82, 20, -8, -4),
        "LeftArm": J(-1.44, -0.3, -0.82, 20, 8, 4),
        "Head": J(0, 1.5, 0, 28, 0, 0),
        "HRP": J(0, -0.42, 0, 32, 0, 0),
        "RightLeg": J(0.5, -1.58, -0.54, -38, 0, 0),
        "LeftLeg": J(-0.5, -1.58, -0.54, -38, 0, 0),
    },
    "GIRO": {
        "RightArm": J(1.5, 0.3, -0.94, 80, -44, -16),
        "LeftArm": J(-1.5, 0.3, -0.94, 80, 44, 16),
        "Head": J(0, 1.5, 0, 0, 40, 0),
        "HRP": J(0, -0.06, 0, 5, -52, 0),
    },
    "CONVOCA": {
        "RightArm": J(1.38, 0.62, -0.42, 128, -18, -26),
        "LeftArm": J(-1.38, 0.62, -0.42, 128, 18, 26),
        "Head": J(0, 1.5, 0, -24, 0, 0),
        "HRP": J(0, 0.08, 0, -13, 0, 0),
    },
    "RECOLHE": {
        "RightArm": J(1.32, 0.3, -0.36, 86, -34, -40),
        "LeftArm": J(-1.32, 0.3, -0.36, 86, 34, 40),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.12, 0, 12, 0, 0),
    },
}


def S(nome, natureza, passos):
    return (nome, (natureza, passos))


# ── moldes de ritmo, para não repetir a mesma lista catorze vezes ──────────

def rapido(nome, a, b, sfx=None):
    """Golpe rápido: 0.7–0.9 s, impacto na metade (regras 1 e 2)."""
    return S(nome, "golpe rápido", [
        P(a, 0.20, "Back", "In", "CARGA"),
        P(a, 0.14, "Sine", "InOut"),
        P(b, 0.10, "Quint", "Out", "GOLPE"),
        P(b, 0.15, "Sine", "InOut"),
        P("IDLE", 0.24, "Quad", "Out", "FIM"),
    ])


def conjura(nome, a, b, tremor=0.03, freq=22):
    return S(nome, "conjuração", [
        P(a, 0.26, "Back", "In", "CARGA"),
        P(a, 0.40, "Sine", "InOut", None, tremor, freq),
        P(b, 0.15, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.30, "Quad", "Out", "FIM"),
    ])


def pesado(nome, a, b, tremor=0.045, freq=26):
    return S(nome, "golpe pesado", [
        P(a, 0.30, "Back", "In", "CARGA"),
        P(a, 0.54, "Sine", "InOut", "SEGURA", tremor, freq),
        P(b, 0.17, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.33, "Quad", "Out", "FIM"),
    ])


def sustentada(nome, a, tremor=0.03, freq=19):
    return S(nome, "sustentada", [
        P(a, 0.30, "Back", "In", "CARGA"),
        P(a, 0.70, "Sine", "InOut", "SEGURA", tremor, freq),
        P(a, 0.18, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ])


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))



# ═══════════════════════════════════════════════════════════════
# POSES NOVAS — só o que o desenho novo pede
#
# `J(x, y, z, rx, ry, rz)` é posição em studs mais rotação em GRAUS. A base de
# cada junta é o repouso R6 que o animator solda: RightArm (1.5,0,0),
# LeftArm (-1.5,0,0), Head (0,1.5,0), HRP identidade, pernas (±0.5,-2,0).
# ═══════════════════════════════════════════════════════════════


NOVAS = {
    # ── Forma 1 ───────────────────────────────────────────────────────
    # Curtain Call: os braços cruzam na frente do peito, como quem fecha a
    # cortina. É a pose que antecede o sumiço.
    "CORTINA": {
        "RightArm": J(1.24, 0.18, -0.66, 74, -52, -58),
        "LeftArm": J(-1.24, 0.18, -0.66, 74, 52, 58),
        "Head": J(0, 1.5, 0, 8, 0, 0),
        "HRP": J(0, -0.1, 0, 6, 0, 0),
    },
    # o reaparecimento: braços abertos, peito para fora, cabeça erguida
    "REVELA": {
        "RightArm": J(1.54, 0.26, 0.28, 30, -28, -62),
        "LeftArm": J(-1.54, 0.26, 0.28, 30, 28, 62),
        "Head": J(0, 1.5, 0, -20, 0, 0),
        "HRP": J(0, 0.1, 0, -14, 0, 0),
    },
    # Four Suits Arsenal: a mão gira em volta de si, invocando o anel de oito
    "ANEL_MAO": {
        "RightArm": J(1.46, 0.46, -0.86, 108, -30, -14),
        "LeftArm": J(-1.44, 0.1, -0.34, 30, 12, 14),
        "Head": J(0, 1.5, 0, -12, -6, 0),
        "HRP": J(0, 0.04, 0, -6, -4, 0),
    },
    # Joker's Labyrinth: os dois braços descem juntos, cercando o chão
    "CERCA": {
        "RightArm": J(1.46, -0.2, -0.76, 44, -22, -12),
        "LeftArm": J(-1.46, -0.2, -0.76, 44, 22, 12),
        "Head": J(0, 1.5, 0, 14, 0, 0),
        "HRP": J(0, -0.22, 0, 16, 0, 0),
    },
    # Ace Gate: o braço vai para trás e chicoteia — arremesso de faca
    "ARREMESSA_AS": {
        "RightArm": J(1.4, 0.5, 0.4, 148, -18, -8),
        "LeftArm": J(-1.46, 0.16, -0.42, 38, 14, 16),
        "Head": J(0, 1.5, 0, -8, -12, 0),
        "HRP": J(0, 0.04, 0, -4, -20, 0),
    },
    # House Collapse: as duas mãos empilham no ar, construindo o castelo
    "EMPILHA": {
        "RightArm": J(1.42, 0.66, -0.5, 126, -16, -20),
        "LeftArm": J(-1.42, 0.34, -0.7, 92, 18, 22),
        "Head": J(0, 1.5, 0, -22, 0, 0),
        "HRP": J(0, 0.08, 0, -12, 0, 0),
    },
    # e o empurrão que derruba as paredes na direção do mouse
    "EMPURRA": {
        "RightArm": J(1.52, 0.22, -1.22, 88, -8, -4),
        "LeftArm": J(-1.52, 0.22, -1.22, 88, 8, 4),
        "Head": J(0, 1.5, 0, -4, 0, 0),
        "HRP": J(0, -0.04, 0, 6, 0, 0),
        "RightLeg": J(0.5, -1.84, -0.3, -14, 0, 0),
    },
    # Eclipse Deck: a mão aponta para o CÉU, e a cabeça acompanha
    "APONTA_CEU": {
        "RightArm": J(1.44, 0.88, 0.06, 176, -6, -10),
        "LeftArm": J(-1.46, 0.12, -0.3, 26, 10, 12),
        "Head": J(0, 1.5, 0, -42, 0, 0),
        "HRP": J(0, 0.12, 0, -18, 0, 0),
    },
    # e o punho que fecha, chamando tudo de volta ao centro
    "PUNHO_FECHA": {
        "RightArm": J(1.3, 0.44, -0.5, 104, -40, -46),
        "LeftArm": J(-1.42, 0.2, -0.44, 46, 18, 22),
        "Head": J(0, 1.5, 0, 16, 0, 0),
        "HRP": J(0, -0.16, 0, 18, 0, 0),
    },
    # Royal Guard: postura de sentinela, braços firmes ao lado
    "SENTINELA": {
        "RightArm": J(1.5, 0.06, -0.5, 46, -10, -6),
        "LeftArm": J(-1.5, 0.06, -0.5, 46, 10, 6),
        "Head": J(0, 1.5, 0, -8, 0, 0),
        "HRP": J(0, 0.04, 0, -4, 0, 0),
        "RightLeg": J(0.5, -1.94, -0.14, -6, 0, 0),
        "LeftLeg": J(-0.5, -1.94, 0.14, 6, 0, 0),
    },

    # ── Forma 2 ───────────────────────────────────────────────────────
    # Wyrm Sparks: três estocadas curtas do cajado, a mão à frente do peito
    "ESTOCA": {
        "RightArm": J(1.5, 0.24, -1.04, 84, -14, -6),
        "LeftArm": J(-1.42, 0.06, -0.3, 24, 10, 14),
        "Head": J(0, 1.5, 0, -4, -10, 0),
        "HRP": J(0, 0, 0, 2, 14, 0),
    },
    # Crown of Cinders: os dois braços sobem em coroa acima da cabeça
    "COROA": {
        "RightArm": J(1.34, 0.86, -0.16, 164, -22, -34),
        "LeftArm": J(-1.34, 0.86, -0.16, 164, 22, 34),
        "Head": J(0, 1.5, 0, -38, 0, 0),
        "HRP": J(0, 0.14, 0, -20, 0, 0),
    },
    # Dragon's Requiem: o corpo recua e o peito enche — carga do sopro
    "ENCHE_PEITO": {
        "RightArm": J(1.36, 0.3, -0.28, 78, -36, -40),
        "LeftArm": J(-1.36, 0.3, -0.28, 78, 36, 40),
        "Head": J(0, 1.5, 0, -26, 0, 0),
        "HRP": J(0, -0.06, 0, -20, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.2, 12, 0, 0),
        "LeftLeg": J(-0.5, -1.86, -0.24, -14, 0, 0),
    },
    # e o sopro: tudo vai para a frente de uma vez
    "SOPRA": {
        "RightArm": J(1.5, 0.16, -1.18, 84, -10, -6),
        "LeftArm": J(-1.5, 0.16, -1.18, 84, 10, 6),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.14, 0, 22, 0, 0),
        "RightLeg": J(0.5, -1.78, -0.38, -22, 0, 0),
    },
    # Xester Prism: as três máscaras nascem — a mão desenha o triângulo
    "TRIANGULO": {
        "RightArm": J(1.48, 0.58, -0.74, 122, -26, -16),
        "LeftArm": J(-1.48, 0.58, -0.74, 122, 26, 16),
        "Head": J(0, 1.5, 0, -18, 0, 0),
        "HRP": J(0, 0.06, 0, -10, 0, 0),
    },
    # The Final Page: o braço rasga o ar na diagonal, virando a página
    "VIRA_PAGINA": {
        "RightArm": J(1.38, 0.5, -0.34, 122, -44, -52),
        "LeftArm": J(-1.44, -0.06, -0.24, 18, 12, 20),
        "Head": J(0, 1.5, 0, -10, 22, 0),
        "HRP": J(0, 0.02, 0, -6, -26, 0),
    },

    # ── Cutscene ──────────────────────────────────────────────────────
    # 1. a câmera aproxima-se da MÃO segurando uma carta vazia
    "CENA_MAO": {
        "RightArm": J(1.46, 0.42, -0.98, 112, -18, -10),
        "LeftArm": J(-1.46, 0.1, -0.32, 26, 10, 12),
        "Head": J(0, 1.5, 0, -14, 10, 0),
        "HRP": J(0, 0.02, 0, -6, -8, 0),
    },
    # 3-4. a carta queima e as cartas congelam no ar: o corpo trava, tenso
    "CENA_QUEIMA": {
        "RightArm": J(1.44, 0.56, -0.9, 126, -14, -12),
        "LeftArm": J(-1.4, 0.24, -0.46, 52, 16, 18),
        "Head": J(0, 1.5, 0, -24, 6, 0),
        "HRP": J(0, 0.06, 0, -12, -4, 0),
    },
    # 5. Xester RASGA a carta: as mãos se afastam com violência
    "CENA_RASGA": {
        "RightArm": J(1.56, 0.44, -0.42, 96, -38, -44),
        "LeftArm": J(-1.56, 0.44, -0.42, 96, 38, 44),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.08, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.88, -0.24, -12, 0, 0),
        "LeftLeg": J(-0.5, -1.88, 0.24, 12, 0, 0),
    },
    # 6. o título: pose de heroísmo, corpo aberto e cabeça alta
    "CENA_TITULO": {
        "RightArm": J(1.58, 0.34, 0.36, 24, -34, -68),
        "LeftArm": J(-1.58, 0.34, 0.36, 24, 34, 68),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.16, 0, -22, 0, 0),
    },
    # a volta: o baralho fecha, o corpo recolhe, a cabeça baixa
    "CENA_FECHA": {
        "RightArm": J(1.3, 0.1, -0.44, 62, -40, -48),
        "LeftArm": J(-1.3, 0.1, -0.44, 62, 40, 48),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.18, 0, 16, 0, 0),
    },
}

POSES = dict(BASE)
POSES.update(NOVAS)


# ═══════════════════════════════════════════════════════════════
# MOLDE DE CUTSCENE
#
# Uma cutscene é uma sequência como as outras — o que muda é que cada passo
# carrega um BEAT NOMEADO, e é esse nome que a câmera recebe. Escrever o nome
# do beat duas vezes (aqui e num `if` do Server) é o defeito que já custou 14
# Tools sem dano; por isso o `despachar` do Server lê o nome DAQUI.
# ═══════════════════════════════════════════════════════════════

def cena(nome, passos):
    """passos = [(pose, duração, beat), ...] — sempre com FIM no último."""
    fora = []
    for indice, (pose, t, beat) in enumerate(passos):
        ultimo = indice == len(passos) - 1
        fora.append(P(pose, t, "Sine" if not ultimo else "Quad",
                      "InOut" if not ultimo else "Out", beat,
                      0.02 if beat in ("CONGELA", "RELOGIO") else None,
                      21 if beat in ("CONGELA", "RELOGIO") else None))
    return S(nome, "cutscene", fora)


# ═══════════════════════════════════════════════════════════════
# AS 16 SEQUÊNCIAS
# ═══════════════════════════════════════════════════════════════

SEQUENCIAS = dict([
    # ═════ FORMA 1 — Mestre do Baralho ═════
    #  Q  Curtain Call — desfaz-se em cartas, cópia falsa, reaparece atrás
    conjura("CURTAIN_CALL", "CORTINA", "REVELA", 0.02, 24),
    #  E  Four Suits Arsenal — oito cartas orbitando; o clique dispara o naipe
    conjura("ARSENAL", "ANEL_MAO", "ANEL_MAO"),
    #  M1 da Forma 1 quando o Arsenal está de pé: o naipe sai
    rapido("DISPARA_NAIPE", "LEQUE", "ATIRA_CARTA"),
    #  R  Joker's Labyrinth — cartas gigantes cercam, embaralham, fecham
    pesado("LABIRINTO", "CERCA", "PUNHO_FECHA", 0.05, 26),
    #  T  Ace Gate — arremessa o Ás; T de novo teleporta até ele
    rapido("ACE_GATE", "ARREMESSA_AS", "ATIRA_CARTA"),
    conjura("ACE_PORTAO", "SOME", "SOME", 0.02, 26),
    #  Y  House Collapse — constrói o castelo; o clique derruba
    pesado("CASTELO", "EMPILHA", "EMPILHA", 0.045, 24),
    pesado("DESABA", "EMPILHA", "EMPURRA", 0.06, 29),
    #  U  Eclipse Deck — carta negra no céu, marca, e tudo volta ao centro
    pesado("ECLIPSE", "APONTA_CEU", "PUNHO_FECHA", 0.055, 27),
    #  P  Royal Guard — quatro Reis de guarda; clique lança, P de novo baixa
    conjura("GUARDA_REAL", "SENTINELA", "SENTINELA"),
    rapido("REI_LANCA", "LEQUE", "ATIRA_CARTA"),
    pesado("REI_BAQUE", "EMPILHA", "EMPURRA", 0.065, 30),
    #  M1 padrão da Forma 1, sem nada armado: uma carta jogada
    rapido("CARTA_SIMPLES", "LEQUE", "ATIRA_CARTA"),

    # ═════ FORMA 2 — Heavenbreaker ═════
    #  G  Wyrm Sparks — três cabeças de fogo que perseguem
    rapido("WYRM", "ESTOCA", "ESTOCA"),
    #  H  Crown of Cinders — sol de Coringa; o clique estilhaça
    conjura("COROA_BRASAS", "COROA", "COROA"),
    pesado("BRASAS_CAEM", "COROA", "EMPURRA", 0.05, 26),
    #  J  Dragon's Requiem — segurar carrega, soltar dispara o sopro curvado
    sustentada("REQUIEM_CARGA", "ENCHE_PEITO", 0.05, 23),
    pesado("REQUIEM_SOPRO", "ENCHE_PEITO", "SOPRA", 0.06, 28),
    #  K  Xester Prism — três máscaras e os feixes que se cruzam
    sustentada("PRISMA", "TRIANGULO", 0.035, 20),
    #  L  The Final Page of Heaven — a ultimate
    pesado("PAGINA_FINAL", "VIRA_PAGINA", "CAJADO_CHAO", 0.07, 31),
    #  M1 padrão da Forma 2: um corte de chama
    rapido("CHAMA_SIMPLES", "ESTOCA", "GIRO"),

    # ═════ CUTSCENES ═════
    #  F  The Final Deal — 3.0 s, os seis beats do roteiro
    cena("TRANSFORMAR", [
        ("CENA_MAO",     0.55, "MAO"),      # 1. a mão com a carta vazia
        ("CENA_MAO",     0.45, "NAIPES"),   # 2. os quatro naipes aparecem
        ("CENA_QUEIMA",  0.50, "CORINGA"),  # 3. vira Coringa e queima
        ("CENA_QUEIMA",  0.50, "CONGELA"),  # 4. cartas congelam, dragão circula
        ("CENA_RASGA",   0.45, "RASGA"),    # 5. rasga: máscara e aura
        ("CENA_TITULO",  0.55, "TITULO"),   # 6. o título
    ]),
    #  F  Curtain Reversal — 1.8 s, três beats
    cena("REVERTER", [
        ("CENA_RASGA",   0.60, "ABSORVE"),  # o dragão é absorvido pela carta
        ("CENA_FECHA",   0.60, "APAGA"),    # as chamas somem
        ("IDLE",         0.60, "FECHA"),    # Xester fecha o baralho
    ]),
    #  a cutscene curta da ultimate L
    cena("CENA_PAGINA", [
        ("VIRA_PAGINA",  0.45, "PARA"),     # o mundo perde as cores
        ("APONTA_CEU",   0.45, "RELOGIO"),  # o relógio de naipes no céu
        ("PUNHO_FECHA",  0.40, "QUEBRA"),   # a carta final se quebra
        ("CENA_TITULO",  0.50, "VOLTA"),    # o tempo volta de uma vez
    ]),
])


CABECALHO = '''-- Poses.lua
-- ModuleScript "Poses" — Xester  (UMA Tool, DUAS formas)
--
-- 13 habilidades e 3 cutscenes: %d sequências num arquivo só, porque a Tool
-- troca de forma em jogo e as duas gramáticas de corpo convivem nela.
--
-- FORMA 1, o BARALHO — gesto de mão, carta e leque. O braço direito lidera e
-- o corpo quase não sai do lugar: mágico de salão não se debate.
--
-- FORMA 2, o DRAGÃO — o corpo entra inteiro, o HRP lidera o que é peso, e as
-- pausas são mais longas.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada trava a caminhada.
--
-- AS CUTSCENES SÃO SEQUÊNCIAS COMO AS OUTRAS
--
--   O que muda é que cada passo carrega um BEAT NOMEADO, e é esse nome que
--   chega à câmera. A duração da cutscene É a duração da sequência: quem manda
--   o `FIM` é o fim da animação, não um `task.wait` paralelo que poderia
--   dessincronizar com ela.
--
'''


def escrever():
    L = [CABECALHO % len(SEQUENCIAS)]
    L.append("-- AS SEQUÊNCIAS")
    L.append("--")
    for nome, (natureza, passos) in SEQUENCIAS.items():
        total = sum(p["time"] for p in passos)
        marcas = [p["marca"] for p in passos if p["marca"]]
        L.append("--   %-16s %-11s %.2fs · %s"
                 % (nome, natureza, total, " ".join(marcas)))
    L += ["--",
          "-- Gerado por FERRAMENTAS/gerar_poses_xester_v2.py.",
          "", "local P = {}", ""]

    usadas = {}
    for _n, passos in SEQUENCIAS.values():
        for p in passos:
            usadas[p["pose"]] = POSES[p["pose"]]

    for nome in sorted(usadas):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in usadas[nome]:
                L.append(linha_junta(junta, usadas[nome][junta]))
        L.append("}")

    L += ["", "P.SEQUENCIAS = {"]
    for nome, (natureza, passos) in SEQUENCIAS.items():
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
    pasta = os.path.join(TOOLS, TOOL)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s — rode preparar_xester_v2.py antes" % TOOL)
        return 1

    faltando = sorted({p["pose"] for _n, passos in SEQUENCIAS.values()
                       for p in passos} - set(POSES))
    if faltando:
        print("pose(s) citada(s) e não definida(s): %s" % ", ".join(faltando))
        return 1

    with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
        f.write(escrever())

    usadas = {p["pose"] for _n, passos in SEQUENCIAS.values() for p in passos}
    cutscenes = [n for n, (nat, _p) in SEQUENCIAS.items() if nat == "cutscene"]
    print("Tools/%s/Poses.lua" % TOOL)
    print("  %d sequência(s), %d pose(s)" % (len(SEQUENCIAS), len(usadas)))
    print("  %d cutscene(s): %s" % (len(cutscenes), ", ".join(cutscenes)))
    for nome in cutscenes:
        passos = SEQUENCIAS[nome][1]
        print("     %-13s %.2fs · %s"
              % (nome, sum(p["time"] for p in passos),
                 " ".join(p["marca"] for p in passos if p["marca"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
