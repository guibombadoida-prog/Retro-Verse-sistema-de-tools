#!/usr/bin/env python3
"""
gerar_poses_gravidade.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto GRAVIDADE.

    python3 FERRAMENTAS/gerar_poses_gravidade.py

DE ONDE SAI O TEMPO

    `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`.

    Aqui a tabela vale quase inteira, e o motivo é o oposto do conjunto GUEST:
    telecinese não é golpe de troca. Ninguém revida uma levitação em 0.3 s. É
    conjuração — e conjuração é o caso que a regra 1 mede bem.

    | Natureza          | Duração | Regra   |
    |-------------------|---------|---------|
    | conjuração rápida | 0.90 s  | regra 1 |
    | conjuração pesada | 1.20 s  | regra 1 |
    | sustentada        | 1.60 s  | regra 7 |
    | ultimate          | 7.20 s  | regra 5 |

QUEM LIDERA (regra 6)

    "Empurrão, avanço e combo saem do TRONCO. Soco, corte e CONJURAÇÃO saem do
    BRAÇO."

    Seis das sete lideram por `RightArm`: telecinese é gesto de mão. As duas
    exceções são declaradas:

      `Terremoto`            HRP — o golpe é o corpo caindo sobre o chão
      `Asas Telecineticas`   HRP — quem bate asa é o tronco, não o braço

O QUADRO SEGURADO NÃO É NEGOCIÁVEL

    Regra 7: estas animações são, em maioria, PARADAS. `TABLE_FLIP` passa 90%
    do tempo imóvel. Telecinese é o caso extremo disso — o gesto é ERGUER e
    SEGURAR, e o que vende é o segurar. Toda sequência daqui tem pelo menos um
    passo repetido, e as de sustentação têm três.

O ULTIMATE DO `Terremoto` TEM 7.20 s, E ISSO PEDE CÂMERA

    A regra 5 mede ultimate em 7–9 s com 64–86% de preparação, e diz que
    ultimate longo SEM enquadramento vira tempo morto. O `COLAPSO` daqui tem
    7.20 s com 71% de preparação — está na faixa, e por isso ele é a única
    sequência do conjunto que marca beat de câmera (`marca = "CAMERA"`).
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
# POSES COMPARTILHADAS — o vocabulário do conjunto
#
# Sete Tools do mesmo tema devem LER como o mesmo poder. Por isso a guarda e o
# gesto de erguer são os mesmos nas sete: o que muda é o que vem depois.
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.46, 0.08, -0.36, 32, 6, 4),
        "LeftArm": J(-1.48, 0.02, -0.16, 14, -4, -5),
        "Head": J(0, 1.5, 0, -4, 6, 0),
        "HRP": J(0, 0, 0, 0, -8, 0),
    },
    # a mão abre para frente: é o gesto que abre toda telecinese daqui
    "ABRE_MAO": {
        "RightArm": J(1.44, 0.46, -1.02, 94, -10, -6),
        "LeftArm": J(-1.42, 0.14, -0.4, 38, 8, 10),
        "Head": J(0, 1.5, 0, -8, -6, 0),
        "HRP": J(0, 0.02, 0, -4, 12, 0),
    },
    # os dois braços erguidos: sustentação
    "SUSTENTA": {
        "RightArm": J(1.4, 0.7, -0.78, 124, -14, -10),
        "LeftArm": J(-1.4, 0.7, -0.78, 124, 14, 10),
        "Head": J(0, 1.5, 0, -22, 0, 0),
        "HRP": J(0, 0.06, 0, -9, 0, 0),
    },
    # fecha o punho: é onde o dano acontece
    "FECHA": {
        "RightArm": J(1.5, 0.2, -0.68, 66, -6, -4),
        "LeftArm": J(-1.5, 0.16, -0.6, 60, 6, 4),
        "Head": J(0, 1.5, 0, 6, 0, 0),
        "HRP": J(0, -0.1, 0, 7, 0, 0),
    },
    # empurra para baixo: o gesto de esmagar
    "ESMAGA": {
        "RightArm": J(1.48, -0.42, -0.62, 16, -6, -10),
        "LeftArm": J(-1.48, -0.4, -0.6, 15, 6, 9),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.36, 0, 22, 0, 0),
        "RightLeg": J(0.56, -1.78, -0.36, -22, 0, 0),
        "LeftLeg": J(-0.56, -1.78, -0.36, -22, 0, 0),
    },
    # puxa para si
    "PUXA": {
        "RightArm": J(1.24, 0.42, -0.34, 84, 26, 34),
        "LeftArm": J(-1.24, 0.4, -0.32, 82, -26, -33),
        "Head": J(0, 1.5, 0, -12, 0, 0),
        "HRP": J(0, 0.04, 0, -6, 0, 0),
    },
    # martelo erguido acima da cabeça
    "ERGUE": {
        "RightArm": J(1.4, 0.92, 0.14, 168, 8, 14),
        "LeftArm": J(-1.4, 0.88, 0.12, 164, -8, -12),
        "Head": J(0, 1.5, 0, -32, 0, 0),
        "HRP": J(0, 0.1, 0, -13, 0, 0),
    },
    # martelo no chão
    "BATE_CHAO": {
        "RightArm": J(1.5, -0.34, -0.9, 24, -5, -9),
        "LeftArm": J(-1.5, -0.32, -0.86, 22, 5, 8),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.38, 0, 24, 0, 0),
        "RightLeg": J(0.6, -1.74, -0.4, -25, 0, 0),
        "LeftLeg": J(-0.5, -1.94, 0.16, 9, 0, 0),
    },
    # asas: braços abertos e para trás
    "ASA_ABRE": {
        "RightArm": J(1.62, 0.34, 0.42, -22, -18, -62),
        "LeftArm": J(-1.62, 0.34, 0.42, -22, 18, 62),
        "Head": J(0, 1.5, 0, -18, 0, 0),
        "HRP": J(0, 0.12, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.84, 0.3, 16, 0, 0),
        "LeftLeg": J(-0.5, -1.84, 0.3, 16, 0, 0),
    },
    "ASA_BATE": {
        "RightArm": J(1.3, -0.28, -0.5, 40, 16, 46),
        "LeftArm": J(-1.3, -0.28, -0.5, 40, -16, -46),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.06, 0, 10, 0, 0),
        "RightLeg": J(0.5, -1.96, -0.14, -8, 0, 0),
        "LeftLeg": J(-0.5, -1.96, -0.14, -8, 0, 0),
    },
    "MERGULHA": {
        "RightArm": J(1.5, 0.5, 0.5, -34, 0, -14),
        "LeftArm": J(-1.5, 0.5, 0.5, -34, 0, 14),
        "Head": J(0, 1.5, 0, 34, 0, 0),
        "HRP": J(0, -0.1, 0, 46, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.34, 20, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.34, 20, 0, 0),
    },
    # a levitação do próprio corpo
    "FLUTUA": {
        "RightArm": J(1.52, 0.18, 0.22, -12, -8, -22),
        "LeftArm": J(-1.52, 0.18, 0.22, -12, 8, 22),
        "Head": J(0, 1.5, 0, -14, 0, 0),
        "HRP": J(0, 0.2, 0, -6, 0, 0),
        "RightLeg": J(0.5, -1.82, 0.22, 14, 0, 0),
        "LeftLeg": J(-0.5, -1.86, 0.1, 8, 0, 0),
    },
}


# alvo -> (lidera, poses extras, sequências)
CONJUNTO = {

    "Tremores da Gravidade": ("RightArm", {}, {
        # conjuração rápida · 0.90 s · impacto a 51% (regra 2)
        "TREMOR": ("conjuração rápida", [
            P("ERGUE", 0.2, "Back", "In", "ERGUE"),
            P("ERGUE", 0.26, "Sine", "InOut", None, 0.03, 21),
            P("BATE_CHAO", 0.1, "Quint", "Out", "BATE"),
            P("BATE_CHAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # sustentada · 1.60 s · 3 segurados (regra 7)
        "SUSTENTO": ("sustentada", [
            P("SUSTENTA", 0.24, "Back", "Out", "ABRE"),
            P("SUSTENTA", 0.34, "Sine", "InOut", "PULSO", 0.04, 18),
            P("SUSTENTA", 0.34, "Sine", "InOut", "PULSO", 0.05, 24),
            P("SUSTENTA", 0.34, "Sine", "InOut", "PULSO", 0.06, 29),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
    }),

    "Controlador da Gravidade": ("RightArm", {}, {
        # conjuração rápida · 0.90 s
        "INVERTE": ("conjuração rápida", [
            P("ABRE_MAO", 0.22, "Back", "Out", "ABRE"),
            P("ABRE_MAO", 0.3, "Sine", "InOut", "SOLTA", 0.02, 16),
            P("SUSTENTA", 0.18, "Quad", "Out"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # conjuração pesada · 1.20 s · impacto a 62%
        "ESMAGAR": ("conjuração pesada", [
            P("SUSTENTA", 0.24, "Back", "In", "ERGUE"),
            P("SUSTENTA", 0.5, "Sine", "InOut", "SEGURA", 0.04, 23),
            P("ESMAGA", 0.12, "Quint", "Out", "ESMAGA"),
            P("ESMAGA", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
    }),

    "Telecinese Levitacao": ("RightArm", {}, {
        # sustentada · 1.60 s · o gesto é erguer e SEGURAR
        "ERGUER": ("sustentada", [
            P("ABRE_MAO", 0.2, "Back", "Out", "ALCANCA"),
            P("SUSTENTA", 0.22, "Quint", "Out", "ERGUE"),
            P("SUSTENTA", 0.36, "Sine", "InOut", None, 0.02, 15),
            P("SUSTENTA", 0.36, "Sine", "InOut", "SEGURA", 0.025, 19),
            P("FECHA", 0.16, "Quad", "Out", "SOLTA"),
            P("IDLE", 0.3, "Quad", "Out"),
        ]),
        # conjuração rápida · 0.90 s — levitar a si mesmo
        "SUBIR": ("conjuração rápida", [
            P("FLUTUA", 0.24, "Back", "Out", "SOBE"),
            P("FLUTUA", 0.42, "Sine", "InOut", None, 0.02, 13),
            P("IDLE", 0.24, "Quad", "Out", "DESCE"),
        ]),
    }),

    "Lancador de Objetos": ("RightArm", {}, {
        # conjuração rápida · 0.90 s · impacto a 53%
        "ARREMESSO": ("conjuração rápida", [
            P("PUXA", 0.2, "Back", "In", "AGARRA"),
            P("PUXA", 0.28, "Sine", "InOut"),
            P("ABRE_MAO", 0.1, "Quint", "Out", "SOLTA"),
            P("ABRE_MAO", 0.12, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # conjuração pesada · 1.20 s — a rajada
        "RAJADA": ("conjuração pesada", [
            P("PUXA", 0.24, "Back", "In", "REUNE"),
            P("PUXA", 0.42, "Sine", "InOut", "SEGURA", 0.035, 22),
            P("ABRE_MAO", 0.12, "Quint", "Out", "SALVA"),
            P("ABRE_MAO", 0.18, "Sine", "InOut", "SALVA"),
            P("IDLE", 0.24, "Quad", "Out"),
        ]),
    }),

    "Asas Telecineticas": ("HRP", {}, {
        # conjuração rápida · 0.90 s
        "BATIDA": ("conjuração rápida", [
            P("ASA_ABRE", 0.22, "Back", "Out", "ABRE"),
            P("ASA_ABRE", 0.2, "Sine", "InOut"),
            P("ASA_BATE", 0.12, "Quint", "Out", "BATE"),
            P("ASA_BATE", 0.16, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # conjuração pesada · 1.20 s · impacto a 58% — o mergulho
        "MERGULHO": ("conjuração pesada", [
            P("ASA_ABRE", 0.22, "Back", "In", "ERGUE"),
            P("ASA_ABRE", 0.28, "Sine", "InOut", "SEGURA"),
            P("MERGULHA", 0.2, "Quint", "In", "DESCE"),
            P("BATE_CHAO", 0.12, "Quint", "Out", "IMPACTO"),
            P("BATE_CHAO", 0.16, "Sine", "InOut"),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
    }),

    "Terremoto": ("HRP", {}, {
        # conjuração pesada · 1.20 s · impacto a 60%
        "RACHADURA": ("conjuração pesada", [
            P("ERGUE", 0.26, "Back", "In", "ERGUE"),
            P("ERGUE", 0.46, "Sine", "InOut", "SEGURA", 0.035, 20),
            P("BATE_CHAO", 0.12, "Quint", "Out", "BATE"),
            P("BATE_CHAO", 0.16, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out"),
        ]),
        # ULTIMATE · 7.20 s · 71% de preparação · 4 segurados (regra 5)
        # É a única sequência do conjunto com beat de câmera: a própria regra 5
        # diz que ultimate longo sem enquadramento vira tempo morto.
        "COLAPSO": ("ultimate", [
            P("ERGUE", 0.5, "Back", "In", "CAMERA", 0.02, 14),
            P("ERGUE", 0.9, "Sine", "InOut", None, 0.03, 18),
            P("SUSTENTA", 0.7, "Quad", "InOut", "CARGA", 0.04, 22),
            P("SUSTENTA", 1.1, "Sine", "InOut", None, 0.05, 26),
            P("SUSTENTA", 1.1, "Sine", "InOut", "SEGURA", 0.07, 31),
            P("ERGUE", 0.8, "Back", "In", "AUGE", 0.09, 36),
            P("BATE_CHAO", 0.2, "Quint", "Out", "COLAPSO"),
            P("BATE_CHAO", 0.9, "Sine", "InOut"),
            P("IDLE", 1.0, "Quad", "Out", "FIM"),
        ]),
    }),

    "Telecinese Gravitacional": ("RightArm", {}, {
        # conjuração pesada · 1.20 s — o puxão
        "PUXAO": ("conjuração pesada", [
            P("ABRE_MAO", 0.2, "Back", "Out", "ALCANCA"),
            P("ABRE_MAO", 0.28, "Sine", "InOut"),
            P("PUXA", 0.18, "Quint", "Out", "PUXA"),
            P("PUXA", 0.32, "Sine", "InOut", "SEGURA", 0.03, 21),
            P("IDLE", 0.22, "Quad", "Out"),
        ]),
        # sustentada · 1.60 s · 3 segurados — a singularidade
        "SINGULARIDADE": ("sustentada", [
            P("SUSTENTA", 0.22, "Back", "Out", "ABRE"),
            P("PUXA", 0.24, "Quad", "InOut", "REUNE"),
            P("PUXA", 0.3, "Sine", "InOut", None, 0.03, 19),
            P("PUXA", 0.3, "Sine", "InOut", "SEGURA", 0.05, 25),
            P("FECHA", 0.12, "Quint", "Out", "COLAPSA"),
            P("FECHA", 0.18, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out"),
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
    """Só as poses que as sequências desta Tool citam entram no arquivo dela."""
    nomes = set()
    for _nat, passos in sequencias.values():
        for p in passos:
            nomes.add(p["pose"])
    return nomes


def escrever(tool, lidera, poses, sequencias):
    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto GRAVIDADE)" % tool)
    L.append("--")
    L.append("-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:")
    L.append("--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·")
    L.append("--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)")
    L.append("--")
    L.append("-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.")
    L.append("--")
    L.append("-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama")
    L.append("-- ReleaseLegs ao fim de toda sequência.")
    L.append("--")
    L.append("-- JUNTA QUE LIDERA: **%s** (regra 6 da gramática)." % lidera)
    L.append("--")
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        segurados = sum(1 for i, p in enumerate(passos)
                        if i > 0 and p["pose"] == passos[i - 1]["pose"])
        L.append("--   %-14s %-18s %.2fs · %d passo(s), %d segurado(s)"
                 % (nome, natureza, total, len(passos), segurados))
    L.append("--")
    L.append("-- O VOCABULÁRIO É COMPARTILHADO. As sete Tools do conjunto dividem as")
    L.append("-- mesmas poses de base (ABRE_MAO, SUSTENTA, FECHA, PUXA, ESMAGA…) porque")
    L.append("-- têm de LER como o mesmo poder. O que muda entre elas é o que vem depois")
    L.append("-- do gesto, e o tempo de cada passo.")
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_gravidade.py.")
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
    for tool, (lidera, extras, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        poses = {}
        nomes = usadas(sequencias)
        for nome in nomes:
            if nome in extras:
                poses[nome] = extras[nome]
            elif nome in BASE:
                poses[nome] = BASE[nome]
            else:
                print("pose %r não existe (Tool %s)" % (nome, tool))
                return 1
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias))
        total = sum(sum(p["time"] for p in passos)
                    for _n, (_nat, passos) in sequencias.items())
        print("%-26s %d pose(s) · %d sequência(s) · %.2fs no total"
              % (tool, len(poses), len(sequencias), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
