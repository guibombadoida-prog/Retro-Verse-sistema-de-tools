#!/usr/bin/env python3
"""
gerar_poses_titan.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto TITAN — TRÊS sequências cada,
21 no conjunto.

    python3 FERRAMENTAS/preparar_titan.py     # antes
    python3 FERRAMENTAS/gerar_poses_titan.py

AUTORAL, PORQUE NÃO HÁ ORIGEM

    Este conjunto não sai de modelo nenhum: não há `Animation` de origem a
    converter, nem cadência de terceiro a respeitar. As 21 sequências são
    escritas aqui, pela `GRAMATICA_R6.md`.

A GRAMÁTICA DO CONJUNTO: MÁQUINA

    O Titan é um autômato de dois andares com uma televisão na cabeça, e isso
    manda no ritmo de um jeito bem diferente do JUPITER. Corpo pesado de
    verdade — um planeta — se move devagar em todo o percurso. Máquina não:
    ela fica PARADA e depois SALTA. O peso dela está na inércia de parar, não
    na de começar.

    Por isso os três moldes daqui têm a carga CURTA e o recuo LONGO, ao
    contrário dos do JUPITER:

    `mecanico`    ~0.75 s, carga de 0.12 s — o estalo do relé
    `varredura`   ~1.45 s, sustentada com tremor fino e constante, que é a
                  linha de varredura do tubo, não um esforço muscular
    `servo`       ~1.15 s, para o que move o corpo inteiro: a espada e a
                  turbina

    Cinco Tools lideram por `RightArm`. A `Lamina` e o `Propulsor` lideram por
    `HRP`, porque as duas movem o corpo inteiro.

    O TREMOR É CONSTANTE, NÃO CRESCENTE. Num corpo vivo o tremor cresce com o
    esforço; num tubo de raios catódicos ele é a frequência da varredura, e
    varredura não cansa. As frequências ficam altas (24 a 34) e as amplitudes
    baixas.

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
# O VOCABULÁRIO — 16 poses de autômato
#
# O que separa estas das do JUPITER: os cotovelos ficam TRAVADOS. Onde uma
# pose humana curva o braço, esta gira o ombro inteiro e deixa o antebraço na
# linha. É o que faz o mesmo animator ler como máquina.
# ═══════════════════════════════════════════════════════════════

BASE = {
    # a parada: ombros quadrados, braços rentes, cabeça fixa à frente
    "IDLE": {
        "RightArm": J(1.5, 0.02, -0.06, 6, 0, 3),
        "LeftArm": J(-1.5, 0.02, -0.06, 6, 0, -3),
        "Head": J(0, 1.5, 0, 0, 0, 0),
        "HRP": J(0, 0, 0, 0, 0, 0),
    },
    # as duas mãos erguem o gabinete e viram a tela para a frente
    "TELA_FRENTE": {
        "RightArm": J(1.44, 0.46, -0.76, 100, -14, -8),
        "LeftArm": J(-1.44, 0.46, -0.76, 100, 14, 8),
        "Head": J(0, 1.5, 0, -12, 0, 0),
        "HRP": J(0, 0.06, 0, -6, 0, 0),
    },
    # e descem com ele: a batida de gabinete
    "BATE_TELA": {
        "RightArm": J(1.46, -0.36, -0.5, 12, -6, -6),
        "LeftArm": J(-1.46, -0.36, -0.5, 12, 6, 6),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.34, 0, 24, 0, 0),
        "RightLeg": J(0.5, -1.7, -0.36, -24, 0, 0),
        "LeftLeg": J(-0.5, -1.7, -0.36, -24, 0, 0),
    },
    # o braço reto apontando: o feixe sai daqui
    "APONTA": {
        "RightArm": J(1.5, 0.12, -1.3, 90, 0, 0),
        "LeftArm": J(-1.5, 0.04, -0.1, 8, 0, -4),
        "Head": J(0, 1.5, 0, 0, -6, 0),
        "HRP": J(0, 0, 0, 0, 8, 0),
    },
    # os dois braços abrem retos: o leque, o campo, o cone
    "ABRE_LEQUE": {
        "RightArm": J(1.6, 0.24, -0.5, 62, 0, -54),
        "LeftArm": J(-1.6, 0.24, -0.5, 62, 0, 54),
        "Head": J(0, 1.5, 0, -14, 0, 0),
        "HRP": J(0, 0.04, 0, -8, 0, 0),
    },
    # os braços recolhidos e travados no peito: a blindagem, o espelho
    "TRAVA_PEITO": {
        "RightArm": J(1.24, 0.3, -0.4, 92, -30, -50),
        "LeftArm": J(-1.24, 0.3, -0.4, 92, 30, 50),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.1, 0, 10, 0, 0),
    },
    # a antena erguida na vertical, braço reto para cima
    "ANTENA_ALTA": {
        "RightArm": J(1.5, 0.9, 0.06, -172, 0, 0),
        "LeftArm": J(-1.48, 0.08, -0.14, 12, 0, -6),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.08, 0, -10, 0, 0),
    },
    # e cravada no chão: o mastro
    "CRAVA": {
        "RightArm": J(1.48, -0.42, -0.36, 4, 0, 6),
        "LeftArm": J(-1.44, -0.16, -0.4, 22, 0, -14),
        "Head": J(0, 1.5, 0, 30, 0, 0),
        "HRP": J(0, -0.42, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.64, -0.48, -30, 0, 0),
        "LeftLeg": J(-0.52, -1.86, 0.24, 16, 0, 0),
    },
    # o chicote lateral da antena
    "CHICOTE": {
        "RightArm": J(1.56, 0.34, -0.9, 74, -46, -22),
        "LeftArm": J(-1.46, 0.1, -0.2, 18, 12, -10),
        "Head": J(0, 1.5, 0, 0, 38, 0),
        "HRP": J(0, -0.04, 0, 0, -44, 0),
    },
    # as duas mãos na tela: a interferência
    "MAOS_NA_TELA": {
        "RightArm": J(1.28, 0.72, -0.34, 140, -22, -34),
        "LeftArm": J(-1.28, 0.72, -0.34, 140, 22, 34),
        "Head": J(0, 1.5, 0, -18, 0, 0),
        "HRP": J(0, 0.02, 0, -4, 0, 0),
    },
    # o peito aberto e a cabeça para trás: o grito do alto-falante
    "GRITA": {
        "RightArm": J(1.62, 0.16, 0.3, -22, 0, -62),
        "LeftArm": J(-1.62, 0.16, 0.3, -22, 0, 62),
        "Head": J(0, 1.5, 0, -42, 0, 0),
        "HRP": J(0, 0.12, 0, -20, 0, 0),
        "RightLeg": J(0.5, -1.88, -0.2, -12, 0, 0),
        "LeftLeg": J(-0.5, -1.88, -0.2, -12, 0, 0),
    },
    # a espada nas duas mãos, no alto
    "ESPADA_ALTA": {
        "RightArm": J(1.42, 0.84, -0.04, 174, -8, -14),
        "LeftArm": J(-1.42, 0.84, -0.04, 174, 8, 14),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.12, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.1, 6, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.1, 6, 0, 0),
    },
    # e descendo até o chão
    "ESPADA_DESCE": {
        "RightArm": J(1.44, -0.3, -0.88, 14, -6, -4),
        "LeftArm": J(-1.44, -0.3, -0.88, 14, 6, 4),
        "Head": J(0, 1.5, 0, 32, 0, 0),
        "HRP": J(0, -0.48, 0, 36, 0, 0),
        "RightLeg": J(0.5, -1.54, -0.58, -42, 0, 0),
        "LeftLeg": J(-0.5, -1.54, -0.58, -42, 0, 0),
    },
    # a estocada com o corpo atrás da ponta
    "ESTOCA": {
        "RightArm": J(1.5, 0.16, -1.34, 90, 0, 0),
        "LeftArm": J(-1.42, -0.02, -0.24, 16, 10, -16),
        "Head": J(0, 1.5, 0, 4, -4, 0),
        "HRP": J(0, -0.12, 0, 14, 8, 0),
        "RightLeg": J(0.5, -1.7, 0.56, 26, 0, 0),
        "LeftLeg": J(-0.54, -1.88, -0.48, -20, 0, 0),
    },
    # o corpo inclinado para a frente: a investida da turbina
    "IMPULSO": {
        "RightArm": J(1.5, -0.1, 0.42, -30, 0, 10),
        "LeftArm": J(-1.5, -0.1, 0.42, -30, 0, -10),
        "Head": J(0, 1.5, 0, -8, 0, 0),
        "HRP": J(0, -0.16, 0, -26, 0, 0),
        "RightLeg": J(0.5, -1.8, 0.4, 20, 0, 0),
        "LeftLeg": J(-0.5, -1.72, -0.46, -26, 0, 0),
    },
    # e o pouso, com os dois joelhos dobrados
    "POUSO": {
        "RightArm": J(1.42, -0.34, -0.44, 10, -8, 8),
        "LeftArm": J(-1.42, -0.34, -0.44, 10, 8, -8),
        "Head": J(0, 1.5, 0, 20, 0, 0),
        "HRP": J(0, -0.66, 0, 22, 0, 0),
        "RightLeg": J(0.5, -1.5, -0.5, -46, 0, 0),
        "LeftLeg": J(-0.5, -1.5, -0.5, -46, 0, 0),
    },
    # o núcleo erguido nas duas mãos: a sobrecarga
    "NUCLEO_ERGUE": {
        "RightArm": J(1.38, 0.88, -0.16, 166, -18, -26),
        "LeftArm": J(-1.38, 0.88, -0.16, 166, 18, 26),
        "Head": J(0, 1.5, 0, -36, 0, 0),
        "HRP": J(0, 0.14, 0, -18, 0, 0),
        "RightLeg": J(0.5, -1.92, 0.08, 4, 0, 0),
        "LeftLeg": J(-0.5, -1.92, 0.08, 4, 0, 0),
    },
}


# ── moldes de ritmo ───────────────────────────────────────────────────────
#
# CARGA CURTA, RECUO LONGO. É o oposto do JUPITER, e de propósito: máquina
# fica parada e SALTA. O peso dela está na inércia de PARAR.

def mecanico(nome, a, b):
    """0.75 s, carga de 0.12 s — o estalo do relé."""
    return (nome, ("mecânico", [
        P(a, 0.12, "Back", "In", "CARGA"),
        P(b, 0.09, "Quint", "Out", "GOLPE"),
        P(b, 0.2, "Sine", "InOut"),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ]))


def varredura(nome, a, tremor=0.022, freq=30):
    """1.45 s. O tremor é a linha de varredura do tubo — fino e CONSTANTE."""
    return (nome, ("varredura", [
        P(a, 0.16, "Back", "Out", "CARGA"),
        P(a, 0.42, "Sine", "InOut", "SEGURA", tremor, freq),
        P(a, 0.42, "Sine", "InOut", None, tremor, freq),
        P(a, 0.15, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.3, "Quad", "Out", "FIM"),
    ]))


def servo(nome, a, b, tremor=0.03, freq=26):
    """1.15 s. Para o que move o corpo inteiro: a espada e a turbina."""
    return (nome, ("servo", [
        P(a, 0.18, "Back", "In", "CARGA"),
        P(a, 0.26, "Sine", "InOut", "SEGURA", tremor, freq),
        P(b, 0.11, "Quint", "Out", "GOLPE"),
        P(b, 0.22, "Sine", "InOut"),
        P("IDLE", 0.38, "Quad", "Out", "FIM"),
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
    "Titan Estatica": ("RightArm", tres(
        mecanico("GOLPE_TELA", "TELA_FRENTE", "BATE_TELA"),
        varredura("CHUVISCO", "TELA_FRENTE", 0.026, 32),
        varredura("ESPELHO", "TRAVA_PEITO", 0.018, 34))),

    "Titan Raio Catodico": ("RightArm", tres(
        mecanico("FAISCA", "TRAVA_PEITO", "APONTA"),
        varredura("FEIXE", "APONTA", 0.02, 33),
        servo("LEQUE", "TRAVA_PEITO", "ABRE_LEQUE", 0.028, 29))),

    "Titan Antena": ("RightArm", tres(
        mecanico("CHICOTE", "ANTENA_ALTA", "CHICOTE"),
        servo("TORRE", "ANTENA_ALTA", "CRAVA", 0.032, 25),
        varredura("INTERFERENCIA", "MAOS_NA_TELA", 0.024, 31))),

    "Titan Alto Falante": ("RightArm", tres(
        mecanico("BATIDA", "TRAVA_PEITO", "BATE_TELA"),
        servo("CONE", "TRAVA_PEITO", "ABRE_LEQUE", 0.03, 27),
        servo("GRITO", "TRAVA_PEITO", "GRITA", 0.038, 24))),

    "Titan Lamina": ("HRP", tres(
        mecanico("CORTE", "ESPADA_ALTA", "ESPADA_DESCE"),
        mecanico("ESTOCADA", "TRAVA_PEITO", "ESTOCA"),
        servo("DESCENDENTE", "ESPADA_ALTA", "ESPADA_DESCE", 0.042, 26))),

    "Titan Propulsor": ("HRP", tres(
        mecanico("INVESTIDA", "TRAVA_PEITO", "IMPULSO"),
        servo("VOO", "IMPULSO", "POUSO", 0.034, 28),
        mecanico("DESVIO", "TRAVA_PEITO", "IMPULSO"))),

    "Titan Sobrecarga": ("RightArm", tres(
        mecanico("DESCARGA", "TRAVA_PEITO", "APONTA"),
        servo("SOBRECARGA", "NUCLEO_ERGUE", "ABRE_LEQUE", 0.04, 30),
        varredura("REINICIO", "NUCLEO_ERGUE", 0.05, 34))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Titan_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto TITAN)
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
-- A GRAMÁTICA É DE MÁQUINA, NÃO DE CORPO
--
--   Carga CURTA e recuo LONGO — o oposto do conjunto JUPITER. Corpo pesado se
--   move devagar no percurso inteiro; máquina fica parada e SALTA, e o peso
--   dela está na inércia de PARAR. Os cotovelos ficam travados: onde uma pose
--   humana curva o braço, estas giram o ombro inteiro.
--
--   O tremor é CONSTANTE, não crescente: num tubo de raios catódicos ele é a
--   frequência da varredura, e varredura não cansa.
--
-- Gerado por FERRAMENTAS/gerar_poses_titan.py. Editar aqui à mão faz as sete
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

    L += ["--" + "═" * 63,
          "-- SEQUÊNCIAS",
          "--" + "═" * 63,
          "",
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
            os.makedirs(pasta, exist_ok=True)
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
        print("  %-24s %2d pose(s) · %s" % (tool, len(poses),
                                            " · ".join(duracoes)))
    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T em cada." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
