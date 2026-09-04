#!/usr/bin/env python3
"""
gerar_poses_fogo.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto PODER DE FOGO — DUAS sequências
cada, 14 no conjunto.

    python3 FERRAMENTAS/preparar_fogo.py      # antes
    python3 FERRAMENTAS/gerar_poses_fogo.py

════════════════════════════════════════════════════════════════════════
A GRAMÁTICA: O CORPO SE AFASTA DO QUE ELE MESMO ACENDE
════════════════════════════════════════════════════════════════════════

    O MAGNETISMO tinha "a mão não toca em nada", porque campo age à distância.
    Fogo é o oposto: ele TOCA, e queima quem o segura. A animação tem de dizer
    isso, e são três regras:

      1. A CABEÇA VIRA. Em toda pose de fogo aceso a cabeça está inclinada
         PARA LONGE da chama — 12° a 26°. É o reflexo que todo mundo tem
         diante de calor, e é o detalhe que faz a chama parecer quente em vez
         de parecer luz.

      2. O BRAÇO ESTENDE MAIS QUE NOS OUTROS CONJUNTOS. Quem segura fogo
         afasta o braço do corpo. Onde o MAGNETISMO deixava o cotovelo
         dobrado, aqui ele abre.

      3. O RECUO É PARA TRÁS E PARA BAIXO. Fogo não empurra como um soco:
         ele ESTOURA, e o corpo encolhe. O contragolpe do REALITY era alto e
         sobrado; o daqui é agachado.

    A `Fenix` é a única exceção às três, e de propósito: o `RENASCER` é a
    única pose do conjunto em que o corpo ABRE em direção ao fogo, porque ali
    o fogo é dele.

FORMATO V2 — juntas que o R6CFrameAnimator solda, e `quando` no keyframe.
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
        "RightArm": J(1.48, 0.06, -0.18, 16, 4, 6),
        "LeftArm": J(-1.49, 0.04, -0.08, 8, -2, -4),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },

    # ── BRASA: o punho carrega baixo e sobe reto
    "PUNHO_CARREGA": {
        "RightArm": J(1.32, -0.24, 0.34, -34, -44, 30),
        "LeftArm": J(-1.42, 0.06, -0.36, 30, 18, -12),
        "Head": J(0, 1.5, 0, -8, -26, 0),
        "HRP": J(0, -0.06, 0, -6, -30, 0),
    },
    "PUNHO_SOBE": {
        "RightArm": J(1.4, 0.34, -0.82, -52, 34, -18),
        "LeftArm": J(-1.38, -0.04, 0.2, -14, -16, 14),
        # regra 1: a cabeça VIRA para longe da chama
        "Head": J(0, 1.5, 0, -14, 22, 0),
        "HRP": J(0, 0.04, 0, 4, 30, 0),
        "RightLeg": J(0.5, -1.86, -0.3, -18, 0, 0),
        "LeftLeg": J(-0.52, -1.9, 0.22, 15, 0, 0),
    },

    # ── JATO: o braço ESTENDE (regra 2), e a esquerda segura o cano
    "JATO_MIRA": {
        "RightArm": J(1.5, 0.02, -1.02, 4, -10, -4),
        "LeftArm": J(-1.3, -0.06, -0.8, 30, 40, 10),
        "Head": J(0, 1.5, 0, -6, -14, 0),
        "HRP": J(0, -0.04, 0, 2, -14, 0),
    },
    "JATO_SEGURA": {
        "RightArm": J(1.52, -0.02, -1.06, 8, -8, -6),
        "LeftArm": J(-1.28, -0.1, -0.84, 34, 44, 12),
        "Head": J(0, 1.5, 0, -12, -18, 0),
        "HRP": J(0, -0.12, 0, 6, -16, 0),
        "RightLeg": J(0.52, -1.78, -0.34, -22, 0, 0),
        "LeftLeg": J(-0.54, -1.82, 0.26, 18, 0, 0),
    },

    # ── ARREMESSO: por cima, com a esquerda de contrapeso
    "ARREMESSO_ALTO": {
        "RightArm": J(1.3, 0.66, 0.32, -148, -26, 34),
        "LeftArm": J(-1.42, 0.2, -0.44, 40, 18, -18),
        "Head": J(0, 1.5, 0, -20, -18, 0),
        "HRP": J(0, 0.06, 0, -8, -26, 0),
    },
    "ARREMESSO_SOLTA": {
        "RightArm": J(1.46, -0.08, -1.0, 44, 32, -16),
        "LeftArm": J(-1.36, -0.02, 0.24, -14, -16, 16),
        "Head": J(0, 1.5, 0, 10, 26, 0),
        "HRP": J(0, -0.12, 0, 14, 30, 0),
        "RightLeg": J(0.5, -1.84, -0.32, -18, 0, 0),
        "LeftLeg": J(-0.52, -1.88, 0.24, 16, 0, 0),
    },

    # ── RISCO: o archote raspa o chão de lado
    "RISCA_CHAO": {
        "RightArm": J(1.44, -0.5, -0.5, 76, -20, -16),
        "LeftArm": J(-1.42, -0.2, -0.24, 34, 14, 16),
        "Head": J(0, 1.5, 0, 22, 18, 0),
        "HRP": J(0, -0.54, 0, 26, 14, 0),
        "RightLeg": J(0.5, -1.46, -0.54, -42, 0, 0),
        "LeftLeg": J(-0.52, -1.6, 0.32, 30, 0, 0),
    },
    "ERGUE_ARCHOTE": {
        "RightArm": J(1.38, 0.6, -0.4, -120, -18, 26),
        "LeftArm": J(-1.44, 0.1, -0.3, 26, 12, -10),
        "Head": J(0, 1.5, 0, -22, 16, 0),
        "HRP": J(0, 0.08, 0, -10, 12, 0),
    },

    # ── METEORO: a mão aponta o CÉU, depois o chão
    "APONTA_CEU": {
        "RightArm": J(1.36, 0.72, 0.04, -168, -12, 24),
        "LeftArm": J(-1.46, 0.16, -0.28, 30, 12, -14),
        "Head": J(0, 1.5, 0, -34, 14, 0),
        "HRP": J(0, 0.08, 0, -12, 10, 0),
    },
    "APONTA_CHAO": {
        "RightArm": J(1.46, -0.06, -0.9, 62, -6, -8),
        "LeftArm": J(-1.44, -0.02, -0.5, 44, 10, 14),
        "Head": J(0, 1.5, 0, 18, 20, 0),
        "HRP": J(0, -0.16, 0, 14, 0, 0),
        "RightLeg": J(0.5, -1.82, -0.28, -16, 0, 0),
        "LeftLeg": J(-0.52, -1.86, 0.18, 12, 0, 0),
    },

    # ── FÊNIX: a asa corta de fora para dentro
    "ASA_ABRE": {
        "RightArm": J(1.36, 0.4, 0.5, -60, -58, 32),
        "LeftArm": J(-1.36, 0.4, 0.5, -60, 58, -32),
        "Head": J(0, 1.5, 0, -16, 0, 0),
        "HRP": J(0, 0.06, 0, -8, 0, 0),
    },
    "ASA_CORTA": {
        "RightArm": J(1.44, -0.02, -0.94, 22, 40, -22),
        "LeftArm": J(-1.44, -0.02, -0.94, 22, -40, 22),
        "Head": J(0, 1.5, 0, 8, 0, 0),
        "HRP": J(0, -0.12, 0, 12, 0, 0),
        "RightLeg": J(0.5, -1.86, -0.28, -16, 0, 0),
        "LeftLeg": J(-0.52, -1.86, 0.28, 16, 0, 0),
    },
    # ⭐ A EXCEÇÃO DAS TRÊS REGRAS: aqui o corpo ABRE para o fogo, e a cabeça
    #    vai PARA TRÁS em vez de para o lado. É o único momento do conjunto em
    #    que o fogo é do personagem, não uma coisa que ele segura.
    "RENASCER": {
        "RightArm": J(1.3, 0.7, 0.16, -160, -34, 40),
        "LeftArm": J(-1.3, 0.7, 0.16, -160, 34, -40),
        "Head": J(0, 1.5, 0, -40, 0, 0),
        "HRP": J(0, 0.16, 0, -18, 0, 0),
        "RightLeg": J(0.5, -2.06, 0.16, 10, 0, 0),
        "LeftLeg": J(-0.52, -2.06, 0.16, 10, 0, 0),
    },

    # ── INFERNO: o chicote sai de baixo, e o campo abre com as duas mãos
    "CHICOTE_CARREGA": {
        "RightArm": J(1.28, -0.3, 0.5, -20, -60, 34),
        "LeftArm": J(-1.4, 0.04, -0.4, 32, 20, -14),
        "Head": J(0, 1.5, 0, -6, -32, 0),
        "HRP": J(0, -0.08, 0, -4, -36, 0),
    },
    "CHICOTE_PASSA": {
        "RightArm": J(1.46, 0.08, -1.0, 12, 70, -24),
        "LeftArm": J(-1.36, -0.06, 0.3, -20, -18, 18),
        "Head": J(0, 1.5, 0, 6, 34, 0),
        "HRP": J(0, -0.08, 0, 8, 42, 0),
        "RightLeg": J(0.5, -1.86, -0.32, -18, 0, 0),
        "LeftLeg": J(-0.52, -1.9, 0.22, 15, 0, 0),
    },
    "CAMPO_ABRE": {
        "RightArm": J(1.46, 0.04, -0.86, 30, -30, -16),
        "LeftArm": J(-1.46, 0.04, -0.86, 30, 30, 16),
        "Head": J(0, 1.5, 0, -10, 0, 0),
        "HRP": J(0, 0.06, 0, -8, 0, 0),
    },

    # ── O RECUO DO CONJUNTO: para trás E PARA BAIXO (regra 3)
    "RECUO_BAIXO": {
        "RightArm": J(1.34, -0.2, -0.44, 46, -18, -28),
        "LeftArm": J(-1.36, -0.16, -0.36, 40, 16, 24),
        "Head": J(0, 1.5, 0, 20, 12, 0),
        "HRP": J(0, -0.34, 0, 22, 0, 0),
        "RightLeg": J(0.52, -1.68, -0.4, -30, 0, 0),
        "LeftLeg": J(-0.54, -1.74, 0.28, 22, 0, 0),
    },
}


# ═══════════════════════════════════════════════════════════════
# AS 21 SEQUÊNCIAS
#
# `quando` é a fração DO PASSO em que a marca dispara. Sem ele, a marca cai
# no fim do passo, como sempre foi.
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Brasa": ("RightArm", {
        "PRIMARIA": [
            P("PUNHO_CARREGA", 0.14, "Back", "Out"),
            P("PUNHO_SOBE", 0.10, "Quint", "Out", marca="GOLPE", quando=0.4),
            P("RECUO_BAIXO", 0.16, "Quad", "Out"),
            P("IDLE", 0.22, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("PUNHO_CARREGA", 0.22, "Quad", "Out", marca="CARREGA", quando=0.7),
            P("PUNHO_SOBE", 0.12, "Quint", "Out", marca="ESTOURO", quando=0.3),
            P("RECUO_BAIXO", 0.26, "Quad", "Out", tremor=0.03, freq=17),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
    }),

    "Lanca Chamas": ("RightArm", {
        "PRIMARIA": [
            P("JATO_MIRA", 0.16, "Quad", "Out", marca="JATO", quando=0.6),
            # o quadro longo É o jato: ele dura enquanto o corpo segura
            P("JATO_SEGURA", 0.54, "Linear", "Out", tremor=0.022, freq=24),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("JATO_MIRA", 0.24, "Quad", "Out", marca="CARREGA", quando=0.65),
            P("JATO_SEGURA", 0.14, "Quint", "Out", marca="COMBUSTAO", quando=0.3),
            P("RECUO_BAIXO", 0.30, "Quad", "Out", tremor=0.042, freq=18),
            P("IDLE", 0.28, "Quad", "InOut"),
        ],
    }),

    "Bola de Fogo": ("RightArm", {
        "PRIMARIA": [
            P("ARREMESSO_ALTO", 0.18, "Back", "Out"),
            P("ARREMESSO_SOLTA", 0.10, "Quint", "Out", marca="LANCA", quando=0.25),
            P("ARREMESSO_SOLTA", 0.14, "Linear", "Out"),
            P("IDLE", 0.24, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("ARREMESSO_ALTO", 0.26, "Quad", "Out", marca="CARREGA", quando=0.7),
            P("ARREMESSO_SOLTA", 0.12, "Quint", "Out", marca="ESTILHACO",
              quando=0.3),
            P("RECUO_BAIXO", 0.24, "Quad", "Out"),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
    }),

    "Muralha de Fogo": ("HRP", {
        "PRIMARIA": [
            P("RISCA_CHAO", 0.22, "Quad", "Out", marca="RISCO", quando=0.7),
            P("RECUO_BAIXO", 0.18, "Quint", "Out"),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("RISCA_CHAO", 0.24, "Quad", "Out", marca="CARREGA", quando=0.6),
            P("ERGUE_ARCHOTE", 0.26, "Back", "Out", marca="MURALHA", quando=0.55),
            P("ERGUE_ARCHOTE", 0.34, "Linear", "Out", tremor=0.026, freq=14),
            P("IDLE", 0.30, "Quad", "InOut"),
        ],
    }),

    "Meteoro": ("RightArm", {
        "PRIMARIA": [
            P("APONTA_CHAO", 0.16, "Back", "Out", marca="PEDRA", quando=0.5),
            P("RECUO_BAIXO", 0.18, "Quad", "Out"),
            P("IDLE", 0.24, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("APONTA_CEU", 0.30, "Quad", "Out", marca="CARREGA", quando=0.7),
            P("APONTA_CHAO", 0.16, "Quint", "Out", marca="QUEDA", quando=0.4),
            # a escora longa: o meteoro leva tempo para chegar, e o corpo
            # aguenta enquanto ele vem
            P("APONTA_CHAO", 0.62, "Linear", "Out", tremor=0.036, freq=13),
            P("IDLE", 0.32, "Quad", "InOut"),
        ],
    }),

    "Fenix": ("RightArm", {
        "PRIMARIA": [
            P("ASA_ABRE", 0.18, "Back", "Out"),
            P("ASA_CORTA", 0.10, "Quint", "Out", marca="ASA", quando=0.3),
            P("IDLE", 0.26, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("ASA_ABRE", 0.24, "Quad", "Out", marca="CARREGA", quando=0.6),
            P("RENASCER", 0.36, "Back", "Out", marca="RENASCER", quando=0.45),
            P("RENASCER", 0.44, "Linear", "Out", tremor=0.02, freq=10),
            P("IDLE", 0.34, "Quad", "InOut"),
        ],
    }),

    "Inferno": ("HRP", {
        "PRIMARIA": [
            P("CHICOTE_CARREGA", 0.16, "Back", "Out"),
            P("CHICOTE_PASSA", 0.10, "Quint", "Out", marca="CHICOTE", quando=0.35),
            P("RECUO_BAIXO", 0.18, "Quad", "Out"),
            P("IDLE", 0.24, "Quad", "InOut"),
        ],
        "EXTRA_R": [
            P("CAMPO_ABRE", 0.30, "Quad", "Out", marca="CARREGA", quando=0.65),
            P("CAMPO_ABRE", 0.20, "Quint", "Out", marca="INFERNO", quando=0.3),
            P("RECUO_BAIXO", 0.52, "Linear", "Out", tremor=0.05, freq=20),
            P("IDLE", 0.34, "Quad", "InOut"),
        ],
    }),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Fogo_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto PODER DE FOGO)
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
-- Gerado por FERRAMENTAS/gerar_poses_fogo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {{}}
'''

NOTAS = {
    "Brasa": "O mais curto do conjunto: 0.62 s. Ele é o M1 do jogo inteiro, e "
             "M1 lento cansa antes de o combate começar.",
    "Lanca Chamas": "O quadro de 0.54 s É o jato — ele dura enquanto o corpo "
                    "segura, e o tremor rápido (24 Hz) é o do bico.",
    "Bola de Fogo": "Arremesso por cima, com a esquerda de contrapeso. O braço "
                    "continua depois de a bola sair.",
    "Muralha de Fogo": "A única que risca o chão E ergue: o `RISCA_CHAO` desce "
                       "a 26° e o `ERGUE_ARCHOTE` sobe a -22°.",
    "Meteoro": "A escora de 0.62 s é o tempo de o meteoro chegar. Sem ela, o "
               "corpo já voltou ao IDLE quando a pedra cai.",
    "Fenix": "O `RENASCER` é a ÚNICA pose do conjunto que abre para o fogo e "
             "joga a cabeça para trás — ali o fogo é do personagem.",
    "Inferno": "O chicote sai de BAIXO (-60° no ombro), que é o oposto do "
               "arremesso da Bola. Dois golpes de fogo não podem ter o mesmo "
               "arco.",
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
            print("sem pasta Tools/%s — rode preparar_fogo.py antes" % tool)
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
    print("7 Tool(s), %d sequência(s) — M1 + R em cada." % total)
    print("%d beat(s) com `quando` — caem no MEIO do passo, não na borda."
          % com_quando)
    return 0


if __name__ == "__main__":
    sys.exit(main())
