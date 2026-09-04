#!/usr/bin/env python3
"""
gerar_poses_magnetismo.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto MAGNETISMO — TRÊS sequências
cada, 21 no conjunto.

    python3 FERRAMENTAS/preparar_magnetismo.py      # antes
    python3 FERRAMENTAS/gerar_poses_magnetismo.py

════════════════════════════════════════════════════════════════════════
A GRAMÁTICA: A MÃO NÃO TOCA EM NADA
════════════════════════════════════════════════════════════════════════

    Todos os conjuntos anteriores animam CONTATO. O braço vai até o alvo — o
    martelo desce na bigorna, o tapa passa reto, a mão entra no chão.

    Magnetismo é a única força deste repositório que age À DISTÂNCIA, e a
    animação tem de dizer isso ou a Tool vira um soco com brilho. Três regras
    saem daí, e elas valem para as 21 sequências:

      1. A MÃO PARA ANTES. Nenhuma pose daqui estende o braço até o fim; o
         cotovelo fica dobrado e a palma vira para o alvo. O gesto é de
         COMANDO, não de alcance.

      2. O CORPO RESISTE AO PRÓPRIO CAMPO. Puxar um caminhão puxa você para o
         caminhão. Toda sequência de atração tem o tronco INCLINADO PARA TRÁS
         e o pé de trás travado; toda sequência de repulsão tem o tronco
         empurrado para trás pelo recuo. É a mesma terceira lei do conjunto
         REALITY, e aqui ela é ainda mais visível porque não há impacto para
         justificar o movimento — só a força.

      3. AS DUAS MÃOS TÊM PÓLOS DIFERENTES. Onde a habilidade é de campo (a
         cúpula, o escudo, a inversão), as palmas ficam OPOSTAS — uma para
         cima e outra para baixo, ou uma para dentro e outra para fora. É
         como se desenha um dipolo com um corpo humano.

════════════════════════════════════════════════════════════════════════
`when` — O BEAT QUE CAI NO MEIO DO PASSO
════════════════════════════════════════════════════════════════════════

    Achado nº 4 da triagem (`TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md`): até aqui
    o beat só podia cair na BORDA de um passo, porque a `marca` é do passo. Um
    som que devia tocar no meio de um quadro de 0.9 s não tinha onde ser
    escrito — virava um passo extra só para pendurar a marca.

    Agora o passo aceita `quando`: uma FRAÇÃO de 0 a 1 do próprio passo. O
    despachante dispara a marca em `time * quando` em vez de no fim.

    E a vantagem não é só poder pôr a marca no meio: mudou a duração do passo,
    o beat ANDA JUNTO, sozinho. Com número absoluto ele ficaria para trás.

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


def P(nome, t, estilo="Quad", direcao="Out", marca=None, quando=None,
      tremor=None, freq=None):
    return dict(pose=nome, time=t, style=estilo, dir=direcao, marca=marca,
                quando=quando, tremor=tremor, freq=freq)


# ═══════════════════════════════════════════════════════════════
# O VOCABULÁRIO — 18 poses de quem move metal sem tocar nele
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.06, -0.2, 16, 4, 6),
        "LeftArm": J(-1.49, 0.04, -0.08, 8, -2, -4),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },

    # ── ATRAIR: a palma vira para CIMA e o tronco cai para trás
    "CHAMA_PALMA": {
        "RightArm": J(1.42, 0.04, -0.62, 44, -22, -34),
        "LeftArm": J(-1.46, 0.02, -0.2, 20, 8, -10),
        "Head": J(0, 1.5, 0, -4, -14, 0),
        "HRP": J(0, 0.02, 0, -4, -16, 0),
    },
    # e PUXA: o cotovelo desce colado ao corpo, o tronco recua
    "PUXA_COTOVELO": {
        "RightArm": J(1.3, -0.12, -0.32, 70, -34, -52),
        "LeftArm": J(-1.42, -0.06, -0.14, 28, 12, -6),
        "Head": J(0, 1.5, 0, -14, -8, 0),
        "HRP": J(0, 0.06, 0, -20, -8, 0),
        "RightLeg": J(0.5, -1.92, 0.24, 14, 0, 0),
        "LeftLeg": J(-0.52, -1.8, -0.36, -22, 0, 0),
    },

    # ── REPELIR: a palma vira para FORA, e o recuo é para trás
    "EMPURRA_PALMA": {
        "RightArm": J(1.4, 0.06, -0.74, 24, -14, -24),
        "LeftArm": J(-1.4, 0.06, -0.74, 24, 14, 24),
        "Head": J(0, 1.5, 0, -6, 0, 0),
        "HRP": J(0, 0.04, 0, -8, 0, 0),
    },
    "EMPURRA_SOLTA": {
        "RightArm": J(1.44, 0.02, -0.98, 6, -6, -8),
        "LeftArm": J(-1.44, 0.02, -0.98, 6, 6, 8),
        "Head": J(0, 1.5, 0, 6, 0, 0),
        "HRP": J(0, -0.08, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.88, 0.28, 18, 0, 0),
        "LeftLeg": J(-0.52, -1.84, -0.3, -20, 0, 0),
    },

    # ── DIPOLO: as duas palmas OPOSTAS, uma acima e outra abaixo
    "DIPOLO_ABRE": {
        "RightArm": J(1.4, 0.5, -0.3, -66, -20, 28),
        "LeftArm": J(-1.4, -0.4, -0.3, 62, 20, -28),
        "Head": J(0, 1.5, 0, -10, 0, 0),
        "HRP": J(0, 0.06, 0, -6, 0, 0),
    },
    "DIPOLO_GIRA": {
        "RightArm": J(1.34, 0.44, -0.5, -54, -46, 34),
        "LeftArm": J(-1.34, -0.34, -0.5, 52, 46, -34),
        "Head": J(0, 1.5, 0, -4, -18, 0),
        "HRP": J(0, 0.04, 0, -4, -22, 0),
    },
    # e FECHA: as palmas se encontram, o campo colapsa
    "DIPOLO_FECHA": {
        "RightArm": J(1.28, 0.06, -0.66, 46, -40, -50),
        "LeftArm": J(-1.28, 0.06, -0.66, 46, 40, 50),
        "Head": J(0, 1.5, 0, 16, 0, 0),
        "HRP": J(0, -0.24, 0, 18, 0, 0),
        "RightLeg": J(0.52, -1.72, -0.34, -26, 0, 0),
        "LeftLeg": J(-0.54, -1.76, 0.26, 20, 0, 0),
    },

    # ── TRILHO: a mão risca o chão de lado
    "RISCA_CHAO": {
        "RightArm": J(1.36, -0.42, -0.5, 72, -30, -22),
        "LeftArm": J(-1.44, -0.16, -0.24, 34, 12, 14),
        "Head": J(0, 1.5, 0, 26, 12, 0),
        "HRP": J(0, -0.5, 0, 24, 16, 0),
        "RightLeg": J(0.5, -1.5, -0.5, -40, 0, 0),
        "LeftLeg": J(-0.52, -1.62, 0.32, 28, 0, 0),
    },
    "RISCA_PASSA": {
        "RightArm": J(1.34, -0.36, -0.44, 66, 40, -18),
        "LeftArm": J(-1.42, -0.1, -0.3, 28, -14, 16),
        "Head": J(0, 1.5, 0, 22, -20, 0),
        "HRP": J(0, -0.42, 0, 20, -26, 0),
        "RightLeg": J(0.5, -1.58, -0.42, -32, 0, 0),
        "LeftLeg": J(-0.52, -1.68, 0.26, 22, 0, 0),
    },
    # e MONTA: o corpo se joga para a frente, agachado
    "MONTA_TRILHO": {
        "RightArm": J(1.36, 0.12, -0.78, -14, -18, -14),
        "LeftArm": J(-1.36, 0.12, -0.78, -14, 18, 14),
        "Head": J(0, 1.5, 0, 14, 0, 0),
        "HRP": J(0, -0.34, 0, 34, 0, 0),
        "RightLeg": J(0.5, -1.66, -0.5, -38, 0, 0),
        "LeftLeg": J(-0.52, -1.6, 0.44, 34, 0, 0),
    },

    # ── SUCATA: as duas mãos juntam, e o corpo carrega o peso
    "JUNTA_BOLA": {
        "RightArm": J(1.3, -0.02, -0.6, 40, -44, -40),
        "LeftArm": J(-1.3, -0.02, -0.6, 40, 44, 40),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.12, 0, 10, 0, 0),
    },
    "ARREMESSA_BOLA": {
        "RightArm": J(1.32, 0.6, 0.3, -142, -28, 32),
        "LeftArm": J(-1.4, 0.2, -0.4, 38, 18, -16),
        "Head": J(0, 1.5, 0, -22, -16, 0),
        "HRP": J(0, 0.06, 0, -10, -24, 0),
    },
    "ARREMESSA_SOLTA": {
        "RightArm": J(1.42, -0.08, -0.9, 44, 32, -16),
        "LeftArm": J(-1.38, -0.02, 0.2, -12, -16, 14),
        "Head": J(0, 1.5, 0, 14, 24, 0),
        "HRP": J(0, -0.1, 0, 14, 28, 0),
        "RightLeg": J(0.5, -1.84, -0.32, -18, 0, 0),
        "LeftLeg": J(-0.52, -1.88, 0.24, 16, 0, 0),
    },

    # ── BOBINA: o dedo aponta e a corrente salta
    "APONTA_ARCO": {
        "RightArm": J(1.44, 0.16, -0.84, -12, -8, -6),
        "LeftArm": J(-1.44, 0.02, -0.3, 30, 16, -8),
        "Head": J(0, 1.5, 0, -4, -6, 0),
        "HRP": J(0, 0.02, 0, 0, -10, 0),
    },
    "DESCARGA_ALTO": {
        "RightArm": J(1.3, 0.74, 0.1, -172, -14, 26),
        "LeftArm": J(-1.3, 0.74, 0.1, -172, 14, -26),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.1, 0, -16, 0, 0),
    },

    # ── LEVITAR: a palma sobe devagar, e o corpo sobe junto
    "ERGUE_PALMA": {
        "RightArm": J(1.4, 0.3, -0.52, -34, -20, -18),
        "LeftArm": J(-1.44, 0.06, -0.24, 22, 10, -8),
        "Head": J(0, 1.5, 0, -22, -6, 0),
        "HRP": J(0, 0.12, 0, -10, -8, 0),
    },
    # ── e a inversão: as duas palmas viradas para BAIXO, empurrando o mundo
    "INVERTE_MUNDO": {
        "RightArm": J(1.38, -0.34, -0.46, 66, -26, -26),
        "LeftArm": J(-1.38, -0.34, -0.46, 66, 26, 26),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.38, 0, 22, 0, 0),
        "RightLeg": J(0.52, -1.64, -0.42, -30, 0, 0),
        "LeftLeg": J(-0.54, -1.7, 0.3, 24, 0, 0),
    },
}


# ═══════════════════════════════════════════════════════════════
# AS 21 SEQUÊNCIAS
#
# `quando` é a fração DO PASSO em que a marca dispara. Sem ele, a marca cai
# no fim do passo, como sempre foi.
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Polo Norte": ("RightArm", {
        "PRIMARIA": [
            P("CHAMA_PALMA", 0.20, "Quad", "Out"),
            # o beat cai a 55% do puxão, não no fim: o som do imã tem de
            # começar enquanto o cotovelo ainda está descendo
            P("PUXA_COTOVELO", 0.26, "Quint", "Out", marca="PUXAR", quando=0.55),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("DIPOLO_ABRE", 0.26, "Quad", "Out", marca="ABRE", quando=0.7),
            P("DIPOLO_GIRA", 0.34, "Sine", "InOut", marca="CUPULA"),
            P("DIPOLO_GIRA", 0.50, "Linear", "Out", tremor=0.024, freq=12),
            P("IDLE", 0.32, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("DIPOLO_ABRE", 0.30, "Back", "Out", marca="CARREGA", quando=0.6),
            P("DIPOLO_FECHA", 0.20, "Quint", "In", marca="IMPLOSAO", quando=0.85),
            P("DIPOLO_FECHA", 0.44, "Linear", "Out", tremor=0.042, freq=19),
            P("IDLE", 0.34, "Quad", "InOut"),
        ],
    }),

    "Polo Sul": ("RightArm", {
        "PRIMARIA": [
            P("EMPURRA_PALMA", 0.16, "Back", "Out"),
            P("EMPURRA_SOLTA", 0.12, "Quint", "Out", marca="EMPURRAR", quando=0.3),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("DIPOLO_ABRE", 0.22, "Quad", "Out", marca="ESCUDO", quando=0.8),
            P("DIPOLO_ABRE", 0.46, "Linear", "Out", tremor=0.018, freq=15),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("EMPURRA_PALMA", 0.28, "Back", "Out", marca="CARREGA", quando=0.65),
            P("EMPURRA_SOLTA", 0.14, "Quint", "Out", marca="ONDA", quando=0.4),
            P("EMPURRA_SOLTA", 0.36, "Linear", "Out", tremor=0.05, freq=17),
            P("IDLE", 0.32, "Quad", "InOut"),
        ],
    }),

    "Ferrovia Magnetica": ("HRP", {
        "PRIMARIA": [
            P("RISCA_CHAO", 0.22, "Quad", "Out", marca="TRILHO", quando=0.75),
            P("RISCA_PASSA", 0.24, "Quint", "Out"),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("MONTA_TRILHO", 0.18, "Back", "Out", marca="MONTAR", quando=0.6),
            P("MONTA_TRILHO", 0.40, "Linear", "Out", tremor=0.03, freq=22),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("RISCA_CHAO", 0.24, "Quad", "Out", marca="CARREGA", quando=0.5),
            P("RISCA_PASSA", 0.18, "Quint", "Out", marca="MALHA", quando=0.35),
            P("DIPOLO_ABRE", 0.34, "Sine", "Out"),
            P("IDLE", 0.32, "Quad", "InOut"),
        ],
    }),

    "Sucata": ("RightArm", {
        "PRIMARIA": [
            P("JUNTA_BOLA", 0.26, "Quad", "Out", marca="COLETAR", quando=0.45),
            P("JUNTA_BOLA", 0.22, "Linear", "Out", tremor=0.022, freq=20),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("ARREMESSA_BOLA", 0.20, "Back", "Out"),
            P("ARREMESSA_SOLTA", 0.10, "Quint", "Out", marca="ARREMESSAR",
              quando=0.25),
            P("ARREMESSA_SOLTA", 0.16, "Linear", "Out"),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("ARREMESSA_BOLA", 0.28, "Quad", "Out", marca="CARREGA", quando=0.7),
            P("DESCARGA_ALTO", 0.22, "Quint", "Out", marca="CHUVA", quando=0.5),
            P("DESCARGA_ALTO", 0.38, "Linear", "Out", tremor=0.036, freq=16),
            P("IDLE", 0.32, "Quad", "InOut"),
        ],
    }),

    "Bobina de Tesla": ("RightArm", {
        "PRIMARIA": [
            # a marca a 30% do apontar: o raio sai ANTES de o braço parar,
            # que é o que faz eletricidade parecer eletricidade
            P("APONTA_ARCO", 0.18, "Quint", "Out", marca="ARCO", quando=0.3),
            P("APONTA_ARCO", 0.14, "Linear", "Out"),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("RISCA_CHAO", 0.24, "Quad", "Out", marca="BOBINA", quando=0.8),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("DESCARGA_ALTO", 0.30, "Back", "Out", marca="CARREGA", quando=0.6),
            P("DESCARGA_ALTO", 0.44, "Linear", "Out", marca="DESCARGA",
              quando=0.2, tremor=0.048, freq=24),
            P("IDLE", 0.34, "Quad", "InOut"),
        ],
    }),

    "Levitacao": ("RightArm", {
        "PRIMARIA": [
            P("CHAMA_PALMA", 0.18, "Quad", "Out"),
            P("ERGUE_PALMA", 0.32, "Sine", "InOut", marca="SUSPENDER",
              quando=0.35),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("DIPOLO_ABRE", 0.24, "Quad", "Out", marca="FLUTUAR", quando=0.7),
            P("DIPOLO_ABRE", 0.42, "Linear", "Out", tremor=0.016, freq=9),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
        "EXTRA_T": [
            P("ERGUE_PALMA", 0.26, "Quad", "Out", marca="CARREGA", quando=0.6),
            P("INVERTE_MUNDO", 0.22, "Quint", "Out", marca="INVERTER",
              quando=0.4),
            P("INVERTE_MUNDO", 0.46, "Linear", "Out", tremor=0.038, freq=13),
            P("IDLE", 0.34, "Quad", "InOut"),
        ],
    }),

    "Colapso Magnetico": ("HRP", {
        "PRIMARIA": [
            P("APONTA_ARCO", 0.16, "Quint", "Out", marca="CARGA", quando=0.4),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("DIPOLO_ABRE", 0.22, "Quad", "Out"),
            P("DIPOLO_FECHA", 0.20, "Quint", "In", marca="ATRAIR_CARGAS",
              quando=0.6),
            P("DIPOLO_FECHA", 0.32, "Linear", "Out", tremor=0.034, freq=18),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
        # a ultimate, com CENA: quatro beats, e três deles no meio do passo
        "EXTRA_T": [
            P("DIPOLO_ABRE", 0.40, "Quad", "Out", marca="CENA_ABRE", quando=0.25),
            P("DIPOLO_GIRA", 0.60, "Sine", "InOut", marca="CENA_CARGA",
              quando=0.5, tremor=0.02, freq=11),
            P("DIPOLO_FECHA", 0.26, "Quint", "In", marca="SINGULARIDADE",
              quando=0.8),
            P("DIPOLO_FECHA", 0.70, "Linear", "Out", marca="CENA_FIM",
              quando=0.85, tremor=0.055, freq=21),
            P("IDLE", 0.40, "Quad", "InOut"),
        ],
    }),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Magnetismo_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto MAGNETISMO)
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
--═══════════════════════════════════════════════════════════════
-- A GRAMÁTICA: A MÃO NÃO TOCA EM NADA
--═══════════════════════════════════════════════════════════════
--
--   Magnetismo é a única força deste repositório que age À DISTÂNCIA, e a
--   animação tem de dizer isso — senão a Tool vira um soco com brilho.
--
--     1. A MÃO PARA ANTES. Nenhuma pose estende o braço até o fim: o cotovelo
--        fica dobrado e a palma vira para o alvo. É gesto de COMANDO.
--     2. O CORPO RESISTE AO PRÓPRIO CAMPO. Puxar um caminhão puxa você para o
--        caminhão. Atração inclina o tronco PARA TRÁS e trava o pé de trás.
--     3. AS DUAS MÃOS TÊM PÓLOS DIFERENTES. Nas habilidades de campo as
--        palmas ficam OPOSTAS — é como se desenha um dipolo com um corpo.
--
--   {nota}
--
--═══════════════════════════════════════════════════════════════
-- `quando` — O BEAT NO MEIO DO PASSO
--═══════════════════════════════════════════════════════════════
--
--   `quando` é a FRAÇÃO do passo em que a marca dispara (0 a 1). Sem ele, a
--   marca cai no fim, como em todos os conjuntos anteriores.
--
--   Isso resolve o achado nº 4 da triagem: até aqui um som que devia tocar no
--   meio de um quadro de 0.9 s não tinha onde ser escrito, e virava um passo
--   extra só para pendurar a marca.
--
--   E o beat ANDA JUNTO com a duração: mudou o passo, a marca acompanha. Com
--   número absoluto ela ficaria para trás.
--
-- Gerado por FERRAMENTAS/gerar_poses_magnetismo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {{}}
'''

NOTAS = {
    "Polo Norte": "A atração é o caso puro da regra 2: o `PUXA_COTOVELO` tem o "
                  "tronco a -20° e o pé esquerdo cravado atrás.",
    "Polo Sul": "A repulsão empurra QUEM EMPURRA: o `EMPURRA_SOLTA` recua o "
                "tronco e joga o pé direito à frente para segurar.",
    "Ferrovia Magnetica": "A única que rasga o chão — e mesmo aqui a mão passa "
                          "RENTE, nunca encosta.",
    "Sucata": "As duas mãos juntam sem se tocar: o `JUNTA_BOLA` deixa um vão "
              "entre as palmas, e é nele que a bola nasce.",
    "Bobina de Tesla": "O `ARCO` dispara a 30% do passo — o raio sai ANTES de o "
                       "braço parar, que é o que faz eletricidade parecer "
                       "eletricidade em vez de tiro.",
    "Levitacao": "O único gesto LENTO do conjunto: `Sine InOut` de 0.32 s. "
                 "Levitação com pressa lê como arremesso.",
    "Colapso Magnetico": "A ultimate tem QUATRO beats, e três caem no meio do "
                         "passo. Sem `quando` ela precisaria de nove passos "
                         "para o mesmo desenho.",
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
            if p["quando"] is not None:
                campos.append("quando = %s" % p["quando"])
            L.append("\t\t{ %s }," % ", ".join(campos))
        L.append("\t},")
    L += ["", "}", "", "return P"]
    return "\n".join(L) + "\n"


def main():
    total, com_quando = 0, 0
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s — rode preparar_magnetismo.py antes" % tool)
            return 1
        for p in [q for ps in sequencias.values() for q in ps]:
            if p["pose"] not in BASE:
                print("pose %r não existe (%s)" % (p["pose"], tool))
                return 1
            if p["quando"] is not None:
                if not (0 <= p["quando"] <= 1):
                    print("quando fora de [0,1] em %s: %r" % (tool, p["quando"]))
                    return 1
                com_quando = com_quando + 1
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, sequencias))
        total = total + len(sequencias)
        duracoes = ["%s %.2fs" % (n, sum(p["time"] for p in ps))
                    for n, ps in sequencias.items()]
        print("  %-20s %2d pose(s) · %s"
              % (tool, len({p["pose"] for ps in sequencias.values() for p in ps}),
                 " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T em cada." % total)
    print("%d beat(s) com `quando` — caem no MEIO do passo, não na borda."
          % com_quando)
    return 0


if __name__ == "__main__":
    sys.exit(main())
