#!/usr/bin/env python3
"""
gerar_poses_bombas7.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto PODERES DE BOMBA — DUAS
sequências cada, 14 no conjunto.

    python3 FERRAMENTAS/preparar_bombas7.py      # antes
    python3 FERRAMENTAS/gerar_poses_bombas7.py

A GRAMÁTICA DO CONJUNTO: O PESO SAI DA MÃO

    Todo conjunto anterior tinha uma gramática de ESFORÇO — o braço carrega
    alguma coisa e a solta. Aqui é o contrário, e é o que dá identidade às
    catorze: o corpo **larga** o peso e depois **recua dele**.

    Isso muda onde fica o quadro mais longo. No JUPITER e no TITAN o passo
    demorado é a carga; aqui é o RECUO, porque é ele que diz que o que ficou
    no chão vai explodir. Uma bomba plantada sem recuo lê como objeto largado.

    Quatro moldes:

    `plantar`      ~0.97 s — agacha, deposita, e RECUA, que é o passo de
                   trabalho mais longo (0.34 s de 0.97 s)
    `arremessar`   ~0.70 s — o único rápido: arremesso não tem por que demorar
    `apertar`      ~0.55 s — o êmbolo. Curtíssimo, e o estouro é o que dura
    `epica`        ~1.36 s — ergue, segura, solta. É a das quatro com cutscene,
                   e os quatro beats dela são também os quatro enquadramentos

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
# O VOCABULÁRIO — 10 poses
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.06, -0.18, 18, 4, 5),
        "LeftArm": J(-1.49, 0.02, -0.06, 8, -2, -4),
        "Head": J(0, 1.5, 0, -2, -4, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },
    # agacha e deposita: o braço desce até quase o chão
    "AGACHA": {
        "RightArm": J(1.42, -0.62, -0.5, 8, -6, 10),
        "LeftArm": J(-1.44, -0.3, -0.34, 20, 8, -12),
        "Head": J(0, 1.5, 0, 30, 0, 0),
        "HRP": J(0, -0.78, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.44, -0.5, -54, 0, 0),
        "LeftLeg": J(-0.52, -1.7, -0.26, -26, 0, 0),
    },
    # e RECUA. É o passo que dá identidade ao conjunto: o corpo se afasta do
    # que acabou de deixar no chão, e é isso que diz que aquilo vai explodir.
    "RECUA": {
        "RightArm": J(1.5, 0.24, 0.4, -26, -10, 14),
        "LeftArm": J(-1.5, 0.24, 0.4, -26, 10, -14),
        "Head": J(0, 1.5, 0, -8, 0, 0),
        "HRP": J(0, -0.1, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.82, 0.42, 22, 0, 0),
        "LeftLeg": J(-0.52, -1.78, -0.4, -20, 0, 0),
    },
    # o arremesso: braço atrás da cabeça
    "ARMA": {
        "RightArm": J(1.34, 0.72, 0.36, -152, -16, 26),
        "LeftArm": J(-1.46, 0.18, -0.42, 40, 14, -16),
        "Head": J(0, 1.5, 0, -14, -16, 0),
        "HRP": J(0, 0.04, 0, -8, -26, 0),
    },
    "LANCA": {
        "RightArm": J(1.5, 0.2, -1.24, 88, 8, -10),
        "LeftArm": J(-1.42, -0.08, 0.28, -14, -12, 20),
        "Head": J(0, 1.5, 0, 8, 18, 0),
        "HRP": J(0, -0.06, 0, 6, 30, 0),
        "RightLeg": J(0.5, -1.76, 0.44, 20, 0, 0),
    },
    # o êmbolo: as duas mãos empurram para baixo, à frente do peito
    "PRESSIONA": {
        "RightArm": J(1.36, 0.02, -0.68, 62, -20, -26),
        "LeftArm": J(-1.36, 0.02, -0.68, 62, 20, 26),
        "Head": J(0, 1.5, 0, 16, 0, 0),
        "HRP": J(0, -0.2, 0, 14, 0, 0),
    },
    # apontar o alvo — o farol e o jato
    "APONTA": {
        "RightArm": J(1.52, 0.24, -1.22, 88, -6, -4),
        "LeftArm": J(-1.45, 0.06, -0.24, 22, 10, -12),
        "Head": J(0, 1.5, 0, -4, -8, 0),
        "HRP": J(0, 0, 0, 2, 12, 0),
    },
    # chacoalhar a garrafa: os dois braços tremem juntos
    "CHACOALHA": {
        "RightArm": J(1.4, 0.44, -0.52, 96, -18, -18),
        "LeftArm": J(-1.4, 0.44, -0.52, 96, 18, 18),
        "Head": J(0, 1.5, 0, -8, 0, 0),
        "HRP": J(0, 0.04, 0, -4, 0, 0),
    },
    # as épicas: ergue com as duas mãos, alto
    "ERGUE": {
        "RightArm": J(1.4, 0.92, -0.06, 172, -12, -20),
        "LeftArm": J(-1.4, 0.92, -0.06, 172, 12, 20),
        "Head": J(0, 1.5, 0, -38, 0, 0),
        "HRP": J(0, 0.16, 0, -20, 0, 0),
        "RightLeg": J(0.5, -1.92, 0.1, 5, 0, 0),
        "LeftLeg": J(-0.5, -1.92, 0.1, 5, 0, 0),
    },
    # e solta, o corpo inteiro descendo junto
    "SOLTA": {
        "RightArm": J(1.46, -0.34, -0.9, 16, -8, -4),
        "LeftArm": J(-1.46, -0.34, -0.9, 16, 8, 4),
        "Head": J(0, 1.5, 0, 34, 0, 0),
        "HRP": J(0, -0.56, 0, 38, 0, 0),
        "RightLeg": J(0.5, -1.5, -0.6, -46, 0, 0),
        "LeftLeg": J(-0.5, -1.5, -0.6, -46, 0, 0),
    },
}


# ── moldes de ritmo ───────────────────────────────────────────────────────

def plantar(nome):
    """0.97 s — agacha, deposita, e RECUA.

    O recuo é o passo de TRABALHO mais longo da sequência (0.34 s de 0.97 s).
    É o que separa este conjunto de todos os outros: bomba plantada sem recuo
    lê como objeto largado no chão.
    """
    return (nome, ("plantar", [
        P("AGACHA", 0.2, "Back", "In", "CARGA"),
        P("AGACHA", 0.17, "Sine", "InOut", "PLANTA"),
        P("RECUA", 0.34, "Quint", "Out", "RECUA"),
        P("IDLE", 0.26, "Quad", "Out", "FIM"),
    ]))


def arremessar(nome):
    """0.70 s — o único rápido do conjunto."""
    return (nome, ("arremessar", [
        P("ARMA", 0.16, "Back", "In", "CARGA"),
        P("LANCA", 0.1, "Quint", "Out", "LANCA"),
        P("LANCA", 0.14, "Sine", "InOut"),
        P("IDLE", 0.3, "Quad", "Out", "FIM"),
    ]))


def apertar(nome):
    """0.55 s — o êmbolo. Curtíssimo: o que dura é o estouro, não o gesto."""
    return (nome, ("apertar", [
        P("PRESSIONA", 0.14, "Back", "In", "CARGA"),
        P("PRESSIONA", 0.09, "Quint", "Out", "ESTOURA"),
        P("IDLE", 0.32, "Quad", "Out", "FIM"),
    ]))


def apontar(nome):
    """0.60 s — mirar e mandar."""
    return (nome, ("apontar", [
        P("APONTA", 0.16, "Back", "Out", "CARGA"),
        P("APONTA", 0.12, "Quint", "Out", "MANDA"),
        P("IDLE", 0.32, "Quad", "Out", "FIM"),
    ]))


def chacoalhar(nome):
    """0.75 s — chacoalha e joga. O tremor ALTO é a espuma se formando."""
    return (nome, ("chacoalhar", [
        P("CHACOALHA", 0.3, "Sine", "InOut", "CARGA", 0.07, 34),
        P("LANCA", 0.11, "Quint", "Out", "LANCA"),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ]))


def epica(nome, tremorSegura=0.04, freq=22):
    """1.36 s — ergue, segura, solta.

    Os QUATRO beats desta sequência são também os quatro enquadramentos da
    `CutsceneCam`. É de propósito: um beat que a câmera não acompanha é um
    corte que não acontece, e um enquadramento sem beat é câmera parada
    esperando.
    """
    return (nome, ("épica", [
        P("ERGUE", 0.34, "Back", "Out", "CENA"),
        P("ERGUE", 0.44, "Sine", "InOut", "CARGA", tremorSegura, freq),
        P("SOLTA", 0.14, "Quint", "Out", "ESTOURA", tremorSegura * 1.8, freq + 12),
        P("IDLE", 0.44, "Quad", "Out", "FIM"),
    ]))


def duas(m1, r):
    return dict([m1, r])


# ═══════════════════════════════════════════════════════════════
# AS 14 SEQUÊNCIAS — duas por Tool
#
# O nome bate com o `rig:PlaySequence(...)` do Server, e o beat de cada passo
# bate com a tabela do `despachar`. É o par que o `verificar_beats.py` confere.
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {
    "Fila de Bombas": ("RightArm", duas(
        plantar("PLANTAR"),
        apertar("DETONAR"))),

    "Explosao Nuclear": ("RightArm", duas(
        arremessar("OGIVA"),
        epica("COGUMELO", 0.05, 24))),

    "Coca Explosiva": ("RightArm", duas(
        chacoalhar("GARRAFA"),
        apontar("JATO"))),

    "Bomba Orbital": ("RightArm", duas(
        apontar("MARCAR"),
        epica("ORBITA", 0.035, 20))),

    "Bomba de Implosao": ("RightArm", duas(
        plantar("SEMEAR"),
        epica("COLAPSO", 0.045, 26))),

    "Bomba em Corrente": ("RightArm", duas(
        arremessar("ESTOPIM"),
        epica("REACAO", 0.05, 28))),

    "Bomba do Juizo": ("HRP", duas(
        apertar("CONTAGEM"),
        epica("JUIZO", 0.06, 30))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


CABECA = '''-- Poses_Bomba_V1.lua
-- ModuleScript "Poses" — {tool}  (conjunto PODERES DE BOMBA)
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
-- A GRAMÁTICA: O PESO SAI DA MÃO
--
--   Nos conjuntos anteriores o braço CARREGA alguma coisa e a solta. Aqui o
--   corpo larga o peso e depois RECUA dele — e por isso o quadro mais longo
--   não é a carga, é o recuo. Bomba plantada sem recuo lê como objeto
--   largado.
--
-- Gerado por FERRAMENTAS/gerar_poses_bombas7.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

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
            print("sem pasta Tools/%s — rode preparar_bombas7.py antes" % tool)
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
    print("7 Tool(s), %d sequência(s) — M1 + R em cada." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
