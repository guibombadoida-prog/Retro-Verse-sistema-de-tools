#!/usr/bin/env python3
"""
gerar_poses_gravidade_v2.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto GRAVIDADE — agora com **QUATRO
sequências cada**, 28 no conjunto.

    python3 FERRAMENTAS/gerar_poses_gravidade_v2.py

O QUE ELE ACRESCENTA

    O `gerar_poses_gravidade.py` escrevia DUAS sequências por Tool: a da M1 e
    a da única Extra. As sete ganharam mais duas Extras cada, e são essas
    catorze sequências que nascem aqui.

    As catorze antigas não foram reescritas — elas são importadas do v1 e
    entram intactas. Reescrever pose que já estava conformada e verificada é
    convite a introduzir um erro num lugar que não tinha nenhum.

    O vocabulário de pose também é o mesmo: as doze de `BASE`. Nenhuma pose
    nova foi inventada — o conjunto inteiro é braço e tronco de quem levanta
    peso, e as doze cobrem isso.

A GRAMÁTICA, IGUAL À DO V1

    `conjuração rápida`  ~0.90 s, impacto por volta da metade
    `conjuração pesada`  ~1.20 s, impacto a ~62% — o peso pede o atraso
    `sustentada`         ~1.60 s, com os segurados marcados

    Quem lidera é `RightArm` em cinco Tools e `HRP` nas duas de corpo inteiro
    (`Asas Telecineticas` e `Terremoto`), como no v1.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gerar_poses_gravidade import (BASE, CONJUNTO, P, TOOLS, escrever,  # noqa
                                   usadas)

# ═══════════════════════════════════════════════════════════════
# AS CATORZE SEQUÊNCIAS NOVAS — duas por Tool
#
# Uma por Extra nova. O nome bate com o `rig:PlaySequence(...)` do Server, e o
# beat de cada passo bate com a tabela do `despachar` — é o par que o
# `TESTES/verificar_beats.py` confere, e que já custou 14 Tools sem dano
# quando ninguém conferia.
# ═══════════════════════════════════════════════════════════════

NOVAS = {
    "Tremores da Gravidade": {
        # conjuração rápida · 0.90 s — a falha corre à frente
        "FALHA": ("conjuração rápida", [
            P("ERGUE", 0.2, "Back", "In", "ABRE"),
            P("ERGUE", 0.24, "Sine", "InOut", None, 0.03, 22),
            P("BATE_CHAO", 0.12, "Quint", "Out", "CORTE"),
            P("BATE_CHAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
        # sustentada · 1.60 s — três anéis, um por segurado
        "REPLICA": ("sustentada", [
            P("SUSTENTA", 0.24, "Back", "Out", "ABRE"),
            P("SUSTENTA", 0.34, "Sine", "InOut", "ANEL", 0.04, 19),
            P("SUSTENTA", 0.34, "Sine", "InOut", "ANEL", 0.05, 25),
            P("BATE_CHAO", 0.34, "Sine", "InOut", "ANEL", 0.06, 30),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
    },

    "Controlador da Gravidade": {
        # sustentada · 1.60 s — o campo leve fica de pé enquanto o braço segura
        "CAMPO_LEVE": ("sustentada", [
            P("ABRE_MAO", 0.26, "Back", "Out", "ABRE"),
            P("ABRE_MAO", 0.4, "Sine", "InOut", "SEGURA", 0.03, 17),
            P("SUSTENTA", 0.36, "Sine", "InOut", None, 0.02, 21),
            P("SUSTENTA", 0.3, "Quad", "Out"),
            P("IDLE", 0.28, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — o pulso empurra para FORA
        "PULSO_RADIAL": ("conjuração pesada", [
            P("SUSTENTA", 0.24, "Back", "In", "ERGUE"),
            P("SUSTENTA", 0.5, "Sine", "InOut", "SEGURA", 0.04, 24),
            P("ABRE_MAO", 0.12, "Quint", "Out", "SOLTA"),
            P("ABRE_MAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },

    "Telecinese Levitacao": {
        # sustentada · 1.60 s — prender quem já está no ar
        "CORRENTE": ("sustentada", [
            P("ERGUE", 0.26, "Back", "Out", "ABRE"),
            P("SUSTENTA", 0.38, "Sine", "InOut", "PRENDE", 0.03, 18),
            P("SUSTENTA", 0.36, "Sine", "InOut", None, 0.02, 23),
            P("SUSTENTA", 0.3, "Quad", "Out"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — largar tudo de uma vez
        "QUEDA": ("conjuração pesada", [
            P("SUSTENTA", 0.24, "Back", "In", "ERGUE"),
            P("SUSTENTA", 0.5, "Sine", "InOut", "SEGURA", 0.05, 26),
            P("ESMAGA", 0.12, "Quint", "Out", "LARGA"),
            P("ESMAGA", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },

    "Lancador de Objetos": {
        # conjuração rápida · 0.90 s — a garra fecha no ALVO, não no destroço
        "PRENDER": ("conjuração rápida", [
            P("ABRE_MAO", 0.22, "Back", "Out", "ABRE"),
            P("ABRE_MAO", 0.24, "Sine", "InOut", None, 0.02, 20),
            P("FECHA", 0.12, "Quint", "Out", "PEGA"),
            P("FECHA", 0.12, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — despeja tudo
        "DESPEJO": ("conjuração pesada", [
            P("SUSTENTA", 0.24, "Back", "In", "ERGUE"),
            P("SUSTENTA", 0.5, "Sine", "InOut", "SEGURA", 0.05, 25),
            P("ABRE_MAO", 0.12, "Quint", "Out", "SOLTA"),
            P("ABRE_MAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },

    "Asas Telecineticas": {
        # sustentada · 1.60 s — planar é a asa ABERTA e parada
        "PLANAR": ("sustentada", [
            P("ASA_ABRE", 0.26, "Back", "Out", "ABRE"),
            P("ASA_ABRE", 0.38, "Sine", "InOut", "PLANA", 0.02, 15),
            P("FLUTUA", 0.36, "Sine", "InOut", None, 0.02, 19),
            P("FLUTUA", 0.3, "Quad", "Out"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — a batida que vira vendaval
        "VENDAVAL": ("conjuração pesada", [
            P("ASA_ABRE", 0.24, "Back", "In", "ERGUE"),
            P("ASA_ABRE", 0.5, "Sine", "InOut", "SEGURA", 0.04, 22),
            P("ASA_BATE", 0.12, "Quint", "Out", "SOPRA"),
            P("ASA_BATE", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },

    "Terremoto": {
        # conjuração rápida · 0.90 s — as estacas sobem em linha
        "ESTACA": ("conjuração rápida", [
            P("ERGUE", 0.2, "Back", "In", "ERGUE"),
            P("ERGUE", 0.24, "Sine", "InOut", None, 0.03, 23),
            P("BATE_CHAO", 0.12, "Quint", "Out", "CRAVA"),
            P("BATE_CHAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — a ruína, com o atraso do peso
        "RUINA": ("conjuração pesada", [
            P("ERGUE", 0.24, "Back", "In", "ERGUE"),
            P("ERGUE", 0.5, "Sine", "InOut", "SEGURA", 0.06, 28),
            P("BATE_CHAO", 0.12, "Quint", "Out", "DESABA"),
            P("BATE_CHAO", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },

    "Telecinese Gravitacional": {
        # sustentada · 1.60 s — os alvos giram enquanto o braço gira
        "ORBITA": ("sustentada", [
            P("PUXA", 0.26, "Back", "Out", "ABRE"),
            P("PUXA", 0.38, "Sine", "InOut", "GIRA", 0.03, 20),
            P("SUSTENTA", 0.36, "Sine", "InOut", None, 0.03, 24),
            P("SUSTENTA", 0.3, "Quad", "Out"),
            P("IDLE", 0.3, "Quad", "Out", "FIM"),
        ]),
        # conjuração pesada · 1.20 s — o contrário do puxão
        "EXPULSAR": ("conjuração pesada", [
            P("PUXA", 0.24, "Back", "In", "ERGUE"),
            P("PUXA", 0.5, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("ESMAGA", 0.12, "Quint", "Out", "EXPULSA"),
            P("ESMAGA", 0.14, "Sine", "InOut"),
            P("IDLE", 0.2, "Quad", "Out", "FIM"),
        ]),
    },
}


def main():
    faltando = sorted(set(NOVAS) - set(CONJUNTO))
    if faltando:
        print("Tool nova sem lugar no conjunto: %s" % ", ".join(faltando))
        return 1

    total_seq = 0
    for tool, (lidera, extras, sequencias) in CONJUNTO.items():
        # as antigas entram intactas; as novas são acrescentadas
        completas = dict(sequencias)
        completas.update(NOVAS.get(tool, {}))

        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1

        poses = {}
        for nome in usadas(completas):
            if nome in extras:
                poses[nome] = extras[nome]
            elif nome in BASE:
                poses[nome] = BASE[nome]
            else:
                print("pose %r não existe (Tool %s)" % (nome, tool))
                return 1

        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, completas))

        total = sum(sum(p["time"] for p in passos)
                    for _n, (_nat, passos) in completas.items())
        total_seq = total_seq + len(completas)
        print("  %-26s %2d pose(s) · %d sequência(s) · %.2fs"
              % (tool, len(poses), len(completas), total))

    print("")
    print("7 Tool(s), %d sequência(s) — M1 + R + T + Y em cada." % total_seq)
    return 0


if __name__ == "__main__":
    sys.exit(main())
