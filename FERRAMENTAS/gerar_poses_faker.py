#!/usr/bin/env python3
"""
gerar_poses_faker.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto FAKER.

    python3 FERRAMENTAS/gerar_poses_faker.py

A ORIGEM NÃO DEIXOU UMA ÚNICA POSE PARA HERDAR

    O `faker_tools.rbxmx` tem 796 linhas de habilidade e **nenhuma animação de
    corpo**: nem `Animation`, nem `Motor6D.C0`, nem `Weld` de pose. Toda a
    encenação dele é VFX no mundo — o personagem fica parado enquanto o cubo
    trabalha.

    Então aqui as sete são inteiramente autorais, escritas pela
    `GRAMATICA_R6.md`. É o oposto do conjunto DRAMA, que herdou seis `Weld`
    nomeados do `dodge` e só precisou reescrever o conteúdo.

O VOCABULÁRIO É DE MÃO ABERTA, NÃO DE PUNHO

    O conjunto DRAMA é briga: `GUARDA`, `SOCO_DIR`, `GANCHO`. Este não. O Faker
    **conjura** — quem bate é o cubo, o poço, a entidade. Por isso o vocabulário
    é palma, cubo formado entre as mãos, braços abertos e punhos fechando.

    A única sequência que soca é o `Ultra Combo`, e mesmo ela bate de PALMA:
    `PALMA_DIR`, `PALMA_ESQ`, `COTOVELO`, `ROTACAO`. Um combo de socos aqui
    seria o DRAMA com outro nome.

QUEM LIDERA (regra 6)

    "Empurrão, avanço e combo saem do TRONCO. Soco, corte e conjuração saem do
    BRAÇO."

    | Tool | lidera | por quê |
    |---|---|---|
    | `Ultra Combo` | **HRP** | é combo — a regra 6 mede `CONSECUTIVE_PUNCHES` no HRP |
    | `Era Do Fim` | RightArm | conjuração — o braço ergue e desce |
    | `Sala Do Abismo` | **HRP** | **exceção declarada** — a sala fecha em volta do TRONCO |
    | `Ilusao da Alucinacao` | RightArm | conjuração |
    | `Prisao Cubica` | RightArm | conjuração |
    | `Faker Entity` | RightArm | invocação |
    | `Abismo Profundo` | RightArm | conjuração para baixo |

    `Sala Do Abismo` é a exceção: o efeito nasce centrado no portador e o
    envolve. Conduzir isso pelo braço leria como "ele jogou algo", que é
    exatamente o que a Tool NÃO faz.

AS FAIXAS

    | Regra | O que diz | Onde aparece |
    |---|---|---|
    | 1 | golpe rápido vive entre 0.8 s e 1.2 s | `ESPIRAL`, `PRENDE` (1.20 s) |
    | 2 | o impacto cai na METADE | `ESPIRAL` 52%, `PRENDE` 58% |
    | 3 | combo inverte para 35 : 65 | `COMBO_1` (37%) |
    | 4 | transformação 2 : 98 | `FECHA_SALA` (3%) |
    | 5 | ultimate 7–9 s com 64–86% de preparação | `FIM_DA_ERA` 7.20 s / 74%, `INVOCA` 7.10 s / 72% |
    | 7 | estas animações são, em maioria, PARADAS | quadro segurado em todas as sete |

    `TROCA` (0.70 s) fica abaixo da faixa da regra 1, e é decisão declarada: é
    uma troca de lugar, não um golpe. Vale a mesma exceção que a esquiva do
    conjunto DRAMA — reação lenta não é reação.
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
        "RightArm": J(1.48, 0.04, -0.22, 18, 4, 4),
        "LeftArm": J(-1.48, 0.04, -0.22, 18, -4, -4),
        "Head": J(0, 1.5, 0, -2, 0, 0),
        "HRP": J(0, 0, 0, 0, -4, 0),
    },
    # o cubo formado entre as duas mãos, na altura do peito. É a pose-assinatura
    # do conjunto: toda conjuração passa por ela.
    "CUBO_FORMA": {
        "RightArm": J(1.3, 0.22, -0.88, 78, -14, -34),
        "LeftArm": J(-1.3, 0.22, -0.88, 78, 14, 34),
        "Head": J(0, 1.5, 0, -12, 0, 0),
        "HRP": J(0, -0.04, 0, -5, 0, 0),
    },
    "PALMA_DIR": {
        "RightArm": J(1.52, 0.36, -1.24, 94, -6, -3),
        "LeftArm": J(-1.28, 0.3, -0.6, 84, 16, 28),
        "Head": J(0, 1.5, 0, -2, -12, 0),
        "HRP": J(0, -0.02, 0, 2, 22, 0),
        "RightLeg": J(0.5, -1.9, -0.22, -11, 0, 0),
    },
    "PALMA_ESQ": {
        "RightArm": J(1.28, 0.3, -0.6, 84, -16, -28),
        "LeftArm": J(-1.52, 0.36, -1.24, 94, 6, 3),
        "Head": J(0, 1.5, 0, -2, 12, 0),
        "HRP": J(0, -0.02, 0, 2, -22, 0),
        "LeftLeg": J(-0.5, -1.9, -0.22, -11, 0, 0),
    },
    # cotovelada: o braço dobra e quem gira é o tronco
    "COTOVELO": {
        "RightArm": J(1.22, 0.4, -0.5, 108, -34, -46),
        "LeftArm": J(-1.34, 0.26, -0.5, 70, 18, 26),
        "Head": J(0, 1.5, 0, -6, -20, 0),
        "HRP": J(0, 0.02, 0, -2, 30, 0),
        "RightLeg": J(0.5, -1.88, -0.26, -13, 0, 0),
    },
    # o giro que fecha o combo: braços na horizontal, tronco em 165°
    "ROTACAO": {
        "RightArm": J(1.58, 0.14, 0.2, -8, -16, -62),
        "LeftArm": J(-1.58, 0.14, 0.2, -8, 16, 62),
        "Head": J(0, 1.5, 0, 2, -34, 0),
        "HRP": J(0, -0.02, 0, 4, 165, 0),
        "RightLeg": J(0.56, -1.8, -0.44, -26, 0, -8),
        "LeftLeg": J(-0.5, -1.94, 0.12, 7, 0, 0),
    },
    # braço direito reto para cima — de onde nasce o cogumelo
    "ERGUE_ALTO": {
        "RightArm": J(1.4, 0.86, 0.02, 168, 10, 12),
        "LeftArm": J(-1.44, 0.14, -0.34, 38, -10, -12),
        "Head": J(0, 1.5, 0, -28, 12, 0),
        "HRP": J(0, 0.06, 0, -10, -14, 0),
    },
    # as duas mãos no chão, corpo baixo — de onde abre o poço
    "BAIXA_SOLO": {
        "RightArm": J(1.38, -0.34, -0.5, 34, 14, 22),
        "LeftArm": J(-1.38, -0.34, -0.5, 34, -14, -22),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.5, 0, 24, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.56, -38, 0, 0),
        "LeftLeg": J(-0.5, -1.6, -0.56, -38, 0, 0),
    },
    "APONTA": {
        "RightArm": J(1.5, 0.34, -1.18, 92, -4, -2),
        "LeftArm": J(-1.46, 0.06, -0.26, 24, 6, 8),
        "Head": J(0, 1.5, 0, -4, -4, 0),
        "HRP": J(0, 0.02, 0, -2, 8, 0),
    },
    "ABRE_BRACOS": {
        "RightArm": J(1.58, 0.18, 0.36, -24, -12, -54),
        "LeftArm": J(-1.58, 0.18, 0.36, -24, 12, 54),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.12, 0, -12, 0, 0),
        "RightLeg": J(0.5, -1.88, 0.18, 10, 0, 0),
        "LeftLeg": J(-0.5, -1.88, 0.18, 10, 0, 0),
    },
    # os punhos fechando no peito — implodir, apertar, puxar
    "FECHA_PUNHOS": {
        "RightArm": J(1.26, 0.12, -0.62, 76, 20, 40),
        "LeftArm": J(-1.26, 0.12, -0.62, 76, -20, -40),
        "Head": J(0, 1.5, 0, 18, 0, 0),
        "HRP": J(0, -0.16, 0, 16, 0, 0),
    },
    "ESPIRAL_GIRA": {
        "RightArm": J(1.54, 0.5, -0.36, 118, -30, -28),
        "LeftArm": J(-1.4, -0.06, -0.4, 30, 12, 18),
        "Head": J(0, 1.5, 0, -14, -26, 0),
        "HRP": J(0, 0.04, 0, -4, 22, 0),
    },
    # os dois braços num V, cabeça para trás — a chamada
    "CHAMA_ENTIDADE": {
        "RightArm": J(1.5, 0.72, -0.1, 150, -14, -30),
        "LeftArm": J(-1.5, 0.72, -0.1, 150, 14, 30),
        "Head": J(0, 1.5, 0, -38, 0, 0),
        "HRP": J(0, 0.14, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.14, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.14, 8, 0, 0),
    },
    "ENTIDADE_MANDA": {
        "RightArm": J(1.48, 0.38, -1.2, 92, -6, -6),
        "LeftArm": J(-1.48, 0.38, -1.2, 92, 6, 6),
        "Head": J(0, 1.5, 0, 2, 0, 0),
        "HRP": J(0, -0.06, 0, 8, 0, 0),
        "RightLeg": J(0.5, -1.86, -0.3, -16, 0, 0),
    },
    # agachado com os braços cruzados — o quadro do sumiço
    "SOME": {
        "RightArm": J(1.2, 0.06, -0.66, 84, 28, 52),
        "LeftArm": J(-1.2, 0.06, -0.66, 84, -28, -52),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.72, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.44, -0.66, -54, 0, 0),
        "LeftLeg": J(-0.5, -1.5, 0.4, 30, 0, 0),
    },
}


# alvo -> (lidera, sequências)
CONJUNTO = {

    "Ultra Combo": ("HRP", {
        # COMBO DE QUATRO · 35 : 65 na abertura (regra 3). Bate de PALMA, não de
        # punho — o punho é do conjunto DRAMA.
        "COMBO_1": ("combo", [
            P("CUBO_FORMA", 0.1, "Back", "In", "CARGA"),
            P("CUBO_FORMA", 0.06, "Sine", "InOut"),
            P("PALMA_DIR", 0.07, "Quint", "Out", "BATE"),
            P("PALMA_DIR", 0.13, "Sine", "InOut"),
            P("CUBO_FORMA", 0.26, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_2": ("combo", [
            P("PALMA_ESQ", 0.08, "Quint", "Out", "BATE"),
            P("PALMA_ESQ", 0.12, "Sine", "InOut"),
            P("CUBO_FORMA", 0.22, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_3": ("combo", [
            P("COTOVELO", 0.09, "Quint", "Out", "BATE"),
            P("COTOVELO", 0.13, "Sine", "InOut"),
            P("CUBO_FORMA", 0.22, "Quad", "Out", "ABRE_JANELA"),
        ]),
        "COMBO_4": ("combo", [
            P("CUBO_FORMA", 0.12, "Back", "In"),
            P("ROTACAO", 0.11, "Quint", "Out", "BATE_FORTE"),
            P("ROTACAO", 0.2, "Sine", "InOut"),
            P("IDLE", 0.32, "Quad", "Out", "FIM"),
        ]),
        # golpe pesado: 1.30 s, impacto a 67% — o disco `E` fechando no chão
        "SELO": ("golpe pesado", [
            P("ERGUE_ALTO", 0.24, "Back", "In", "ERGUE"),
            P("ERGUE_ALTO", 0.5, "Sine", "InOut", "SEGURA", 0.04, 23),
            P("BAIXA_SOLO", 0.13, "Quint", "Out", "FECHA"),
            P("BAIXA_SOLO", 0.18, "Sine", "InOut"),
            P("IDLE", 0.25, "Quad", "Out"),
        ]),
    }),

    "Era Do Fim": ("RightArm", {
        # ULTIMATE COM CUTSCENE · 7.20 s · 74% de preparação (regra 5)
        "FIM_DA_ERA": ("ultimate", [
            P("CUBO_FORMA", 0.5, "Back", "In", "CAMERA", 0.02, 15),
            P("ERGUE_ALTO", 0.8, "Quad", "InOut", "ERGUE", 0.03, 19),
            P("ERGUE_ALTO", 1.05, "Sine", "InOut", "CARGA", 0.045, 24),
            P("ERGUE_ALTO", 1.15, "Sine", "InOut", None, 0.06, 29),
            P("ERGUE_ALTO", 1.2, "Sine", "InOut", "SEGURA", 0.08, 34),
            P("BAIXA_SOLO", 0.35, "Quint", "In", "DESCE"),
            P("BAIXA_SOLO", 0.25, "Sine", "InOut", "DETONA"),
            P("BAIXA_SOLO", 0.85, "Sine", "InOut", None, 0.07, 31),
            P("IDLE", 1.05, "Quad", "Out", "FIM"),
        ]),
        # 1.60 s — o anel de 500 studs
        "ONDA": ("golpe pesado", [
            P("ABRE_BRACOS", 0.3, "Back", "In", "ABRE"),
            P("ABRE_BRACOS", 0.42, "Sine", "InOut", None, 0.04, 22),
            P("BAIXA_SOLO", 0.14, "Quint", "Out", "SOLTA"),
            P("BAIXA_SOLO", 0.3, "Sine", "InOut"),
            P("IDLE", 0.44, "Quad", "Out"),
        ]),
    }),

    "Sala Do Abismo": ("HRP", {
        # transformação: 2.00 s, 3 : 97 (regra 4) — a sala fecha no primeiro
        # quadro e o resto é sustentar
        "FECHA_SALA": ("transformação", [
            P("ABRE_BRACOS", 0.06, "Quint", "Out", "FECHA"),
            P("ABRE_BRACOS", 0.72, "Sine", "InOut", None, 0.025, 17),
            P("ABRE_BRACOS", 0.76, "Sine", "InOut", "SUSTENTA", 0.035, 23),
            P("CUBO_FORMA", 0.18, "Back", "Out", "RECOLHE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
        ]),
        # 1.40 s — a sala implodindo
        "IMPLODE": ("golpe pesado", [
            P("ABRE_BRACOS", 0.26, "Back", "In", "ERGUE"),
            P("ABRE_BRACOS", 0.44, "Sine", "InOut", None, 0.045, 25),
            P("FECHA_PUNHOS", 0.12, "Quint", "Out", "IMPLODE"),
            P("FECHA_PUNHOS", 0.3, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),

    "Ilusao da Alucinacao": ("RightArm", {
        # conjuração: 1.20 s, impacto a 52% (regras 1 e 2)
        "ESPIRAL": ("conjuração", [
            P("ESPIRAL_GIRA", 0.2, "Back", "In", "GIRA"),
            P("ESPIRAL_GIRA", 0.3, "Sine", "InOut", None, 0.03, 21),
            P("APONTA", 0.12, "Quint", "Out", "SOLTA"),
            P("APONTA", 0.22, "Sine", "InOut"),
            P("IDLE", 0.36, "Quad", "Out"),
        ]),
        # 0.70 s — abaixo da faixa da regra 1, e de propósito: é troca de lugar,
        # não golpe. Mesma exceção da esquiva do conjunto DRAMA.
        "TROCA": ("reação", [
            P("SOME", 0.14, "Quint", "In", "SOME"),
            P("SOME", 0.22, "Sine", "InOut", "TROCA"),
            P("APONTA", 0.12, "Back", "Out", "VOLTA"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
    }),

    "Prisao Cubica": ("RightArm", {
        # conjuração: 1.20 s, impacto a 58%
        "PRENDE": ("conjuração", [
            P("CUBO_FORMA", 0.24, "Back", "In", "FORMA"),
            P("CUBO_FORMA", 0.34, "Sine", "InOut", None, 0.03, 20),
            P("APONTA", 0.12, "Quint", "Out", "PRENDE"),
            P("APONTA", 0.22, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
        # 1.10 s — o cubo estilhaçando
        "ESTILHACA": ("golpe rápido", [
            P("FECHA_PUNHOS", 0.2, "Back", "In", "APERTA"),
            P("FECHA_PUNHOS", 0.3, "Sine", "InOut", None, 0.05, 26),
            P("ABRE_BRACOS", 0.12, "Quint", "Out", "ESTILHACA"),
            P("ABRE_BRACOS", 0.2, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),

    "Faker Entity": ("RightArm", {
        # ULTIMATE COM CUTSCENE · 7.10 s · 72% de preparação (regra 5)
        "INVOCA": ("ultimate", [
            P("CUBO_FORMA", 0.45, "Back", "In", "CAMERA", 0.02, 16),
            P("CHAMA_ENTIDADE", 0.8, "Quad", "InOut", "CHAMA", 0.03, 20),
            P("CHAMA_ENTIDADE", 1.1, "Sine", "InOut", "CARGA", 0.045, 25),
            P("CHAMA_ENTIDADE", 1.2, "Sine", "InOut", None, 0.06, 30),
            P("CHAMA_ENTIDADE", 1.25, "Sine", "InOut", "SEGURA", 0.075, 35),
            P("ENTIDADE_MANDA", 0.3, "Quint", "Out", "NASCE"),
            P("ENTIDADE_MANDA", 0.85, "Sine", "InOut", None, 0.05, 27),
            P("IDLE", 1.15, "Quad", "Out", "FIM"),
        ]),
        # 1.30 s — mandar a entidade para cima do alvo
        "ENVIA": ("conjuração", [
            P("APONTA", 0.22, "Back", "In", "MIRA"),
            P("APONTA", 0.32, "Sine", "InOut", None, 0.035, 22),
            P("ENTIDADE_MANDA", 0.13, "Quint", "Out", "ENVIA"),
            P("ENTIDADE_MANDA", 0.28, "Sine", "InOut"),
            P("IDLE", 0.35, "Quad", "Out"),
        ]),
    }),

    "Abismo Profundo": ("RightArm", {
        # golpe pesado: 1.50 s, impacto a 61%
        "ABRE_POCO": ("golpe pesado", [
            P("ERGUE_ALTO", 0.26, "Back", "In", "ERGUE"),
            P("ERGUE_ALTO", 0.5, "Sine", "InOut", None, 0.04, 23),
            P("BAIXA_SOLO", 0.16, "Quint", "Out", "ABRE"),
            P("BAIXA_SOLO", 0.3, "Sine", "InOut", "SEGURA", 0.05, 28),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
        # sustentada: 1.80 s — puxar tudo para dentro
        "PUXA": ("sustentada", [
            P("ABRE_BRACOS", 0.24, "Back", "In", "ABRE"),
            P("FECHA_PUNHOS", 0.16, "Quint", "Out", "PUXA"),
            P("FECHA_PUNHOS", 0.44, "Sine", "InOut", "SEGURA", 0.04, 26),
            P("FECHA_PUNHOS", 0.4, "Sine", "InOut", "SEGURA", 0.05, 30),
            P("CUBO_FORMA", 0.2, "Quad", "InOut", "SOLTA"),
            P("IDLE", 0.36, "Quad", "Out"),
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


def usadas(sequencias):
    nomes = set()
    for _nat, passos in sequencias.values():
        for p in passos:
            nomes.add(p["pose"])
    return nomes


def escrever(tool, lidera, poses, sequencias):
    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto FAKER)" % tool)
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
    L.append("-- AUTORAL POR INTEIRO. O `faker_tools.rbxmx` tem 796 linhas de habilidade e")
    L.append("-- NENHUMA animação de corpo — nem Animation, nem Motor6D.C0, nem Weld de")
    L.append("-- pose. O personagem dele fica parado enquanto o cubo trabalha.")
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
    L.append("-- O vocabulário é de MÃO ABERTA, não de punho: CUBO_FORMA, PALMA_DIR,")
    L.append("-- ABRE_BRACOS, FECHA_PUNHOS. Quem bate no conjunto FAKER é o cubo, o poço e")
    L.append("-- a entidade — o portador conjura.")
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_faker.py.")
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
        print("%-22s %d pose(s) · %d sequência(s) · %.2fs no total"
              % (tool, len(poses), len(sequencias), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
