#!/usr/bin/env python3
"""
gerar_poses_tempo.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto TEMPO — TRÊS sequências cada,
21 no conjunto.

    python3 FERRAMENTAS/preparar_tempo.py      # antes
    python3 FERRAMENTAS/gerar_poses_tempo.py

AUTORAL, PORQUE OS SEIS `Animation` DA ORIGEM NÃO SERVEM

    O `Celestial Staff` trazia seis `Animation` (`Summon`, `RightSlash`,
    `Wave`, em R6 e R15) e oito `LoadAnimation`. `Animation` é proibida pela
    REGRA_ANIMACAO_R6 — é asset de fora, some se o id sair do ar, e briga com
    o `Animate` padrão do personagem. E não há CFrame a extrair de um id.

    O que veio da origem foi a CADÊNCIA que os nomes declaram: `Summon` é
    lento e vertical, `RightSlash` é curto e diagonal, `Wave` é sustentado.

A GRAMÁTICA DO CONJUNTO: O TEMPO É O QUE PARA E O QUE CORRE

    Nenhum conjunto anterior tinha uma gramática de VELOCIDADE. Aqui ela é o
    eixo, e por isso os cinco moldes são separados pela DURAÇÃO antes de
    qualquer outra coisa:

    `estala`   ~0.60 s — o estalo. É o mais curto do repositório inteiro, e é
               de propósito: parar o tempo tem de ser mais rápido do que
               qualquer coisa que se possa fazer para impedir
    `varre`    ~0.90 s — o ponteiro atravessando o mostrador
    `volta`    ~1.10 s — a reversão, e ela roda a silhueta AO CONTRÁRIO
    `segura`   ~1.50 s — o campo aberto e mantido
    `epica`    ~1.52 s — a ultimate, com os quatro beats da cutscene

    `volta` é o único molde do repositório em que o passo de RECUO vem antes
    do passo de ação. Não é um detalhe de ritmo: é a habilidade. Uma reversão
    que carrega e depois solta lê como qualquer outro golpe.

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
# O VOCABULÁRIO — 12 poses
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.06, -0.16, 16, 4, 5),
        "LeftArm": J(-1.49, 0.02, -0.06, 8, -2, -4),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },
    # o estalo: a mão sobe até a altura do ombro e ESTALA à frente
    "ESTALA_ARMA": {
        "RightArm": J(1.34, 0.42, -0.28, 78, -22, -34),
        "LeftArm": J(-1.48, 0.06, -0.1, 12, 4, -6),
        "Head": J(0, 1.5, 0, -6, -12, 0),
        "HRP": J(0, 0.02, 0, -2, -10, 0),
    },
    "ESTALA_SOLTA": {
        "RightArm": J(1.54, 0.2, -1.06, 86, 6, -12),
        "LeftArm": J(-1.47, 0.0, 0.06, 4, -4, 8),
        "Head": J(0, 1.5, 0, 2, 10, 0),
        "HRP": J(0, 0, 0, 0, 14, 0),
    },
    # a palma aberta para cima: segurar o campo
    "ERGUE_MAO": {
        "RightArm": J(1.5, 0.62, -0.24, 128, -10, -14),
        "LeftArm": J(-1.5, 0.62, -0.24, 128, 10, 14),
        "Head": J(0, 1.5, 0, -18, 0, 0),
        "HRP": J(0, 0.06, 0, -8, 0, 0),
    },
    # e mantida no alto — o `Wave` da origem, que era o sustentado
    "SEGURA_ALTO": {
        "RightArm": J(1.44, 0.92, -0.04, 174, -10, -18),
        "LeftArm": J(-1.44, 0.92, -0.04, 174, 10, 18),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.14, 0, -18, 0, 0),
        "RightLeg": J(0.5, -1.92, 0.08, 5, 0, 0),
        "LeftLeg": J(-0.5, -1.92, 0.08, 5, 0, 0),
    },
    # o campo aberto: os dois braços para os lados
    "ABRE_CAMPO": {
        "RightArm": J(1.6, 0.26, -0.42, 58, 0, -58),
        "LeftArm": J(-1.6, 0.26, -0.42, 58, 0, 58),
        "Head": J(0, 1.5, 0, -14, 0, 0),
        "HRP": J(0, 0.04, 0, -8, 0, 0),
    },
    # a reversão: o corpo INCLINA PARA TRÁS, e a mão puxa
    "VOLTA_INCLINA": {
        "RightArm": J(1.46, 0.16, 0.62, -46, -12, 16),
        "LeftArm": J(-1.46, 0.16, 0.62, -46, 12, -16),
        "Head": J(0, 1.5, 0, -26, 0, 0),
        "HRP": J(0, 0.08, 0, -24, 0, 0),
        "RightLeg": J(0.5, -1.86, 0.38, 18, 0, 0),
        "LeftLeg": J(-0.52, -1.8, -0.34, -16, 0, 0),
    },
    "VOLTA_PUXA": {
        "RightArm": J(1.3, 0.3, -0.24, 92, -34, -40),
        "LeftArm": J(-1.3, 0.3, -0.24, 92, 34, 40),
        "Head": J(0, 1.5, 0, 8, 0, 0),
        "HRP": J(0, -0.14, 0, 12, 0, 0),
    },
    # a varredura: o braço atravessa o corpo na horizontal — o ponteiro
    "VARRE_ARMA": {
        "RightArm": J(1.4, 0.28, -0.5, 82, -52, -18),
        "LeftArm": J(-1.44, 0.1, -0.2, 20, 14, -12),
        "Head": J(0, 1.5, 0, -4, -44, 0),
        "HRP": J(0, 0, 0, 0, -48, 0),
    },
    "VARRE_PASSA": {
        "RightArm": J(1.52, 0.24, -0.86, 84, 48, -14),
        "LeftArm": J(-1.4, 0.02, 0.2, -8, -14, 14),
        "Head": J(0, 1.5, 0, 2, 44, 0),
        "HRP": J(0, -0.04, 0, 0, 52, 0),
    },
    # correr: o corpo inteiro à frente, para a aceleração
    "CORRE": {
        "RightArm": J(1.5, -0.12, 0.46, -34, 0, 12),
        "LeftArm": J(-1.5, 0.18, -0.6, 74, 0, -12),
        "Head": J(0, 1.5, 0, -10, 0, 0),
        "HRP": J(0, -0.12, 0, -28, 0, 0),
        "RightLeg": J(0.5, -1.78, 0.44, 22, 0, 0),
        "LeftLeg": J(-0.5, -1.74, -0.44, -24, 0, 0),
    },
    # e o peso: agachado, como quem carrega o tempo nas costas
    "PESADO": {
        "RightArm": J(1.42, -0.24, -0.44, 20, -10, 12),
        "LeftArm": J(-1.42, -0.24, -0.44, 20, 10, -12),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.52, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.44, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.6, -0.44, -36, 0, 0),
    },
}


# ── moldes de ritmo ───────────────────────────────────────────────────────

def estala(nome):
    """0.60 s — o estalo. O mais curto do repositório inteiro.

    E é de propósito: parar o tempo tem de ser mais rápido do que qualquer
    coisa que se possa fazer para impedir.
    """
    return (nome, ("estalo", [
        P("ESTALA_ARMA", 0.1, "Back", "In", "CARGA"),
        P("ESTALA_SOLTA", 0.08, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.42, "Quad", "Out", "FIM"),
    ]))


def varre(nome):
    """0.90 s — o ponteiro atravessando o mostrador."""
    return (nome, ("varredura", [
        P("VARRE_ARMA", 0.18, "Back", "In", "CARGA"),
        P("VARRE_PASSA", 0.12, "Quint", "Out", "VARRE"),
        P("VARRE_PASSA", 0.2, "Sine", "InOut"),
        P("IDLE", 0.4, "Quad", "Out", "FIM"),
    ]))


def volta(nome, tremorPuxa=0.03, freq=22):
    """1.10 s — a reversão, e ela roda AO CONTRÁRIO.

    O único molde do repositório em que o passo de RECUO vem antes do passo de
    ação: o corpo inclina para trás PRIMEIRO e só depois puxa. Uma reversão
    que carrega e depois solta lê como qualquer outro golpe.
    """
    return (nome, ("reversão", [
        P("VOLTA_INCLINA", 0.3, "Quint", "Out", "CARGA"),
        P("VOLTA_INCLINA", 0.24, "Sine", "InOut", None, tremorPuxa, freq),
        P("VOLTA_PUXA", 0.14, "Back", "In", "VOLTA"),
        P("IDLE", 0.42, "Quad", "Out", "FIM"),
    ]))


def segura(nome, tremorSegura=0.025, freq=18):
    """1.50 s — o campo aberto e mantido."""
    return (nome, ("sustentada", [
        P("ERGUE_MAO", 0.24, "Back", "Out", "CARGA"),
        P("SEGURA_ALTO", 0.42, "Sine", "InOut", "SEGURA", tremorSegura, freq),
        P("ABRE_CAMPO", 0.36, "Sine", "InOut", None, tremorSegura, freq + 4),
        P("ABRE_CAMPO", 0.14, "Quint", "Out", "SOLTA"),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ]))


def epica(nome, tremorSegura=0.05, freq=26):
    """1.52 s — a ultimate.

    Os QUATRO beats são também os quatro enquadramentos da `CutsceneCam`: um
    beat que a câmera não acompanha é um corte que não acontece.
    """
    return (nome, ("épica", [
        P("SEGURA_ALTO", 0.4, "Back", "Out", "CENA"),
        P("SEGURA_ALTO", 0.52, "Sine", "InOut", "CARGA", tremorSegura, freq),
        P("PESADO", 0.16, "Quint", "Out", "ESTOURA", tremorSegura * 1.7, freq + 12),
        P("IDLE", 0.44, "Quad", "Out", "FIM"),
    ]))


def tres(m1, r, t):
    return dict([m1, r, t])


# ═══════════════════════════════════════════════════════════════
# AS 21 SEQUÊNCIAS — três por Tool
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Instante Parado": ("RightArm", tres(
        estala("TRAVAR"),
        segura("ZONA", 0.02, 16),
        estala("RETOMAR"))),

    "Reversao": ("HRP", tres(
        estala("MARCAR"),
        volta("REVERTER", 0.03, 22),
        volta("REVERTER_EU", 0.045, 26))),

    "Cajado Celeste": ("RightArm", tres(
        varre("CAJADO"),
        segura("HOLOFOTE", 0.022, 20),
        estala("ECO"))),

    "Aceleracao": ("HRP", tres(
        estala("ACELERADO"),
        estala("PASSO"),
        varre("ENVELHECER"))),

    "Lentidao": ("RightArm", tres(
        varre("PESO"),
        segura("CAMPO", 0.018, 14),
        segura("SEGUNDO", 0.03, 12))),

    "Paradoxo": ("RightArm", tres(
        estala("ECO_P"),
        segura("DUPLO", 0.028, 24),
        varre("COLAPSO"))),

    "Fim do Relogio": ("HRP", tres(
        varre("PONTEIRO"),
        segura("AMPULHETA", 0.035, 20),
        epica("FIM_RELOGIO", 0.055, 28))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Tempo_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto TEMPO)
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
-- DE ONDE VIERAM AS SILHUETAS (§12.12)
--
--   O `Celestial Staff` da origem trazia SEIS `Animation` — `Summon`,
--   `RightSlash` e `Wave`, em R6 e R15 — e oito `LoadAnimation`. `Animation`
--   é proibida: é asset de fora, some se o id sair do ar, e briga com o
--   `Animate` padrão. E não há CFrame a extrair de um id.
--
--   O que veio foi a CADÊNCIA que os nomes declaram: `Summon` lento e
--   vertical, `RightSlash` curto e diagonal, `Wave` sustentado.
--
-- A GRAMÁTICA: O TEMPO É O QUE PARA E O QUE CORRE
--
--   Os moldes são separados pela DURAÇÃO antes de qualquer outra coisa. O
--   `estalo` tem 0.60 s e é o mais curto do repositório inteiro — parar o
--   tempo tem de ser mais rápido do que qualquer coisa que se possa fazer
--   para impedir.
--
-- Gerado por FERRAMENTAS/gerar_poses_tempo.py. Editar aqui à mão faz as sete
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
            print("sem pasta Tools/%s — rode preparar_tempo.py antes" % tool)
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
        print("  %-20s %2d pose(s) · %s" % (tool, len(poses),
                                            " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T em cada." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
