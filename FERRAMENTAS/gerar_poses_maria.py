#!/usr/bin/env python3
"""
gerar_poses_maria.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto MARIA — QUATRO sequências cada,
28 no conjunto.

    python3 FERRAMENTAS/gerar_poses_maria.py

POR QUE ESTAS POSES SÃO ESCRITAS, E NÃO EXTRAÍDAS

    A origem TEM animação: cada cajado traz `Animation/R6/Main` e `.../Idle`.
    Mas são instâncias `Animation` com `AnimationId`, tocadas por
    `Humanoid:LoadAnimation` — e o `CLAUDE.md` proíbe as duas coisas em Tool.
    Não há `KeyframeSequence` para converter: o conteúdo mora no servidor da
    Roblox, atrás do id. Não há o que extrair.

    Então a pose é escrita, pela `GRAMATICA_R6.md`.

UM VOCABULÁRIO DE CAJADO, SETE DIALETOS

    Os sete são o MESMO objeto: um bastão longo numa mão. Isso não é limitação,
    é o que dá unidade — quem vê de longe sabe que é um cajado da Maria antes de
    saber qual.

    DUAS SÃO "CANALIZADA", NÃO "ULTIMATE". A `CHUVA` do Meteoro e a
    `TEMPESTADE` do Relâmpago passam de 3.5 s, o que é longo demais para golpe
    pesado — mas a regra 5 reserva "ultimate" para 7–9 s, e chamá-las assim
    seria afirmar conformidade que elas não têm. São canalizadas: preparação
    longa, disparo único.

    As poses base são o vocabulário (`APONTA`, `ERGUE`, `BATE_CHAO`, `VARRE`,
    `DUAS_MAOS`, `RECOLHE`), e cada Tool as combina no próprio ritmo. O que
    diferencia `Meteoro` de `Estrelas` não é o braço: é o TEMPO — 1.6 s de
    preparação contra 1.1 s.
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


BASE = {
    # o cajado descansa inclinado, ponta para cima
    "IDLE": {
        "RightArm": J(1.46, 0.16, -0.34, 34, -6, -10),
        "LeftArm": J(-1.48, 0.05, -0.22, 16, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -5, 0),
    },
    # apontar: o gesto de todo feixe e de todo alvo escolhido
    "APONTA": {
        "RightArm": J(1.52, 0.36, -1.18, 90, -6, -4),
        "LeftArm": J(-1.44, 0.08, -0.3, 26, 8, 10),
        "Head": J(0, 1.5, 0, -5, -8, 0),
        "HRP": J(0, 0.02, 0, -3, 12, 0),
        "RightLeg": J(0.5, -1.88, -0.22, -10, 0, 0),
    },
    # erguer: o cajado sobe reto, ponta ao céu
    "ERGUE": {
        "RightArm": J(1.44, 0.84, -0.04, 168, -8, -14),
        "LeftArm": J(-1.46, 0.1, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.1, 0, -16, 0, 0),
    },
    # as duas mãos no bastão, o corpo recuado: conjuração grande
    "DUAS_MAOS": {
        "RightArm": J(1.4, 0.66, -0.3, 140, -12, -20),
        "LeftArm": J(-1.4, 0.66, -0.3, 140, 12, 20),
        "Head": J(0, 1.5, 0, -26, 0, 0),
        "HRP": J(0, 0.08, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.12, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.12, 8, 0, 0),
    },
    # bater o cajado no chão: o que faz coisa nascer do solo
    "BATE_CHAO": {
        "RightArm": J(1.42, -0.34, -0.4, 26, 10, 22),
        "LeftArm": J(-1.4, -0.2, -0.44, 34, -10, -18),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.44, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.52, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.66, -0.44, -30, 0, 0),
    },
    # varrer de lado: área rasa em volta
    "VARRE": {
        "RightArm": J(1.5, 0.28, -0.9, 76, -40, -14),
        "LeftArm": J(-1.42, 0.06, -0.36, 30, 16, 20),
        "Head": J(0, 1.5, 0, 2, -34, 0),
        "HRP": J(0, -0.04, 0, 4, 44, 0),
        "RightLeg": J(0.5, -1.9, -0.2, -10, 0, 0),
    },
    # recolher contra o peito: o gesto do que volta para si
    "RECOLHE": {
        "RightArm": J(1.32, 0.3, -0.36, 86, -34, -40),
        "LeftArm": J(-1.32, 0.3, -0.36, 86, 34, 40),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.12, 0, 12, 0, 0),
    },
}


def S(nome, natureza, passos):
    return (nome, (natureza, passos))


#: as quatro de cada Tool. `M1` é a habilidade da origem; R/T/Y são as Extras.
def quatro(m1, r, t, y):
    return dict([m1, r, t, y])


CONJUNTO = {
    "Cajado Curador": ("RightArm", quatro(
        S("CURAR", "conjuração", [
            P("APONTA", 0.26, "Back", "In", "CARGA"),
            P("APONTA", 0.46, "Sine", "InOut", "SEGURA", 0.025, 20),
            P("APONTA", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]),
        S("ROUBAR", "conjuração", [
            P("APONTA", 0.24, "Back", "In", "CARGA"),
            P("RECOLHE", 0.44, "Sine", "InOut", "SEGURA", 0.03, 22),
            P("RECOLHE", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]),
        S("BENCAO", "sustentada", [
            P("ERGUE", 0.30, "Back", "In", "CARGA"),
            P("ERGUE", 0.64, "Sine", "InOut", "SEGURA", 0.03, 19),
            P("ERGUE", 0.20, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM")]),
        S("RESSURGIR", "golpe pesado", [
            P("DUAS_MAOS", 0.34, "Back", "In", "CARGA"),
            P("DUAS_MAOS", 0.72, "Sine", "InOut", "SEGURA", 0.045, 24),
            P("BATE_CHAO", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.36, "Quad", "Out", "FIM")]))),

    "Cajado da Escuridao": ("RightArm", quatro(
        S("ORBE", "conjuração", [
            P("APONTA", 0.22, "Back", "In", "CARGA"),
            P("APONTA", 0.34, "Sine", "InOut", None, 0.03, 23),
            P("APONTA", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM")]),
        S("ENXAME", "conjuração", [
            P("DUAS_MAOS", 0.28, "Back", "In", "CARGA"),
            P("DUAS_MAOS", 0.42, "Sine", "InOut", None, 0.035, 25),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]),
        S("CEGUEIRA", "golpe pesado", [
            P("VARRE", 0.26, "Back", "In", "CARGA"),
            P("VARRE", 0.48, "Sine", "InOut", "SEGURA", 0.04, 26),
            P("VARRE", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("MANTO", "sustentada", [
            P("RECOLHE", 0.30, "Back", "In", "CARGA"),
            P("RECOLHE", 0.68, "Sine", "InOut", "SEGURA", 0.03, 18),
            P("RECOLHE", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM")]))),

    "Cajado da Ilusao": ("RightArm", quatro(
        S("ISCA", "conjuração", [
            P("APONTA", 0.28, "Back", "In", "CARGA"),
            P("APONTA", 0.52, "Sine", "InOut", "SEGURA", 0.03, 21),
            P("APONTA", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("TROCAR", "conjuração", [
            P("RECOLHE", 0.24, "Back", "In", "CARGA"),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
            P("IDLE", 0.10, "Sine", "InOut")]),
        S("MULTIPLICAR", "golpe pesado", [
            P("ERGUE", 0.30, "Back", "In", "CARGA"),
            P("ERGUE", 0.54, "Sine", "InOut", "SEGURA", 0.04, 24),
            P("VARRE", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("DISPERSAR", "golpe rápido", [
            P("VARRE", 0.22, "Back", "In", "CARGA"),
            P("VARRE", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
            P("IDLE", 0.10, "Sine", "InOut")]))),

    "Cajado das Estrelas": ("RightArm", quatro(
        S("ESTRELA", "conjuração", [
            P("ERGUE", 0.26, "Back", "In", "CARGA"),
            P("ERGUE", 0.38, "Sine", "InOut", None, 0.035, 24),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]),
        S("CHUVA", "golpe pesado", [
            P("DUAS_MAOS", 0.32, "Back", "In", "CARGA"),
            P("DUAS_MAOS", 0.58, "Sine", "InOut", "SEGURA", 0.045, 26),
            P("ERGUE", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM")]),
        S("CONSTELACAO", "sustentada", [
            P("ERGUE", 0.30, "Back", "In", "CARGA"),
            P("ERGUE", 0.70, "Sine", "InOut", "SEGURA", 0.03, 20),
            P("APONTA", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("GUIA", "conjuração", [
            P("APONTA", 0.26, "Back", "In", "CARGA"),
            P("APONTA", 0.40, "Sine", "InOut", None, 0.03, 22),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]))),

    "Cajado de Gelo": ("RightArm", quatro(
        S("CONGELA", "conjuração", [
            P("APONTA", 0.28, "Back", "In", "CARGA"),
            P("APONTA", 0.48, "Sine", "InOut", "SEGURA", 0.025, 19),
            P("APONTA", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("PRISAO", "golpe pesado", [
            P("BATE_CHAO", 0.30, "Back", "In", "CARGA"),
            P("BATE_CHAO", 0.50, "Sine", "InOut", "SEGURA", 0.04, 25),
            P("BATE_CHAO", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("TRILHA", "conjuração", [
            P("VARRE", 0.24, "Back", "In", "CARGA"),
            P("VARRE", 0.36, "Sine", "InOut", None, 0.03, 23),
            P("VARRE", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]),
        S("ESTILHACAR", "golpe rápido", [
            P("ERGUE", 0.24, "Back", "In", "CARGA"),
            P("BATE_CHAO", 0.13, "Quint", "Out", "GOLPE"),
            P("BATE_CHAO", 0.16, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out", "FIM")]))),

    "Cajado do Meteoro": ("RightArm", quatro(
        S("METEORO", "golpe pesado", [
            P("DUAS_MAOS", 0.36, "Back", "In", "CARGA"),
            P("DUAS_MAOS", 0.74, "Sine", "InOut", "SEGURA", 0.055, 28),
            P("APONTA", 0.20, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.36, "Quad", "Out", "FIM")]),
        S("CHUVA", "canalizada", [
            P("ERGUE", 0.50, "Back", "In", "CARGA", 0.03, 18),
            P("DUAS_MAOS", 0.90, "Sine", "InOut", None, 0.05, 24),
            P("DUAS_MAOS", 1.30, "Sine", "InOut", "SEGURA", 0.07, 30),
            P("BATE_CHAO", 0.26, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.60, "Quad", "Out", "FIM")]),
        S("CRATERA", "golpe pesado", [
            P("BATE_CHAO", 0.32, "Back", "In", "CARGA"),
            P("BATE_CHAO", 0.54, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("BATE_CHAO", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.34, "Quad", "Out", "FIM")]),
        S("IMPACTO", "golpe pesado", [
            P("RECOLHE", 0.30, "Back", "In", "CARGA"),
            P("RECOLHE", 0.46, "Sine", "InOut", "SEGURA", 0.045, 26),
            P("VARRE", 0.18, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]))),

    "Cajado Relampago": ("RightArm", quatro(
        S("RAIOS", "golpe pesado", [
            P("ERGUE", 0.28, "Back", "In", "CARGA"),
            P("ERGUE", 0.52, "Sine", "InOut", "SEGURA", 0.05, 30),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.32, "Quad", "Out", "FIM")]),
        S("TEMPESTADE", "canalizada", [
            P("ERGUE", 0.55, "Back", "In", "CARGA", 0.035, 20),
            P("ERGUE", 1.00, "Sine", "InOut", None, 0.055, 26),
            P("DUAS_MAOS", 1.20, "Sine", "InOut", "SEGURA", 0.075, 32),
            P("ERGUE", 0.24, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.60, "Quad", "Out", "FIM")]),
        S("CORRENTE", "golpe rápido", [
            P("APONTA", 0.22, "Back", "In", "CARGA"),
            P("APONTA", 0.12, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
            P("IDLE", 0.10, "Sine", "InOut")]),
        S("PARARAIOS", "conjuração", [
            P("APONTA", 0.26, "Back", "In", "CARGA"),
            P("APONTA", 0.42, "Sine", "InOut", None, 0.03, 22),
            P("APONTA", 0.16, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out", "FIM")]))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def escrever(tool, lidera, poses, sequencias):
    L = ["-- Poses.lua",
         "-- ModuleScript \"Poses\" — %s  (conjunto MARIA)" % tool,
         "--",
         "-- ESCRITA, e não extraída — e o motivo importa.",
         "--",
         "-- A origem TEM animação: cada cajado traz `Animation/R6/Main` e",
         "-- `.../Idle`. Mas são instâncias `Animation` com `AnimationId`,",
         "-- tocadas por `LoadAnimation` — proibidas em Tool aqui. E não há",
         "-- `KeyframeSequence` para converter: o conteúdo mora no servidor da",
         "-- Roblox, atrás do id. Não havia o que extrair.",
         "--",
         "-- QUATRO SEQUÊNCIAS: a da origem mais as três Extras.",
         "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("--   %-12s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))
    L += ["--", "-- Gerado por FERRAMENTAS/gerar_poses_maria.py.", "",
          "local P = {}", ""]

    for nome in sorted(poses):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in poses[nome]:
                L.append(linha_junta(junta, poses[nome][junta]))
        L.append("}")

    L += ["", "P.SEQUENCIAS = {"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("")
        L.append("\t-- %s · %.2fs · %d passo(s)" % (natureza, total, len(passos)))
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
    total_seq = 0
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
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
        total_seq = total_seq + len(sequencias)
        tempos = " · ".join("%s %.2fs" % (n, sum(p["time"] for p in ps))
                            for n, (_x, ps) in sequencias.items())
        print("%-22s %d pose(s) · %s" % (tool, len(poses), tempos))
    print("")
    print("%d sequências no conjunto" % total_seq)
    return 0


if __name__ == "__main__":
    sys.exit(main())
