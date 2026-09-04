#!/usr/bin/env python3
"""
gerar_poses_guest_originais.py — Retro-Verse / Studios

Reescreve o `Poses.lua` do `Cano De Rua` e do `Taco de Baseball` com a
animação **ORIGINAL** do `guest_tools.rbxmx`, a pedido.

    python3 FERRAMENTAS/extrair_poses_guest.py       # antes
    python3 FERRAMENTAS/gerar_poses_guest_originais.py

O QUE MUDA, E O QUE NÃO MUDA

    As outras cinco Tools do conjunto GUEST continuam com as poses autorais.
    Só estas duas voltam à animação do modelo, porque foi o que o usuário pediu
    — e porque estas duas são as únicas do repositório inteiro cuja animação
    **pode** voltar sem perda: o laço de origem varre o alpha de 0 a 1, então a
    pose escrita no código é a pose alcançada de verdade.

    Os NOMES das poses e das sequências ficam: `CARGA_A`, `BATE_A`, `CARGA_B`,
    `BATE_B`, `GOLPE_A`, `GOLPE_B`. Os Servers já os usam, e trocar só o
    conteúdo mantém o beat, a trava e o dano exatamente onde estavam.

A ORIGEM É UM COMBO DE DOIS, E SEMPRE FOI

    `attacknumber == 0` e `attacknumber == 1` no `LeadpipeServer`: dois golpes
    que alternam. A conversão anterior já tinha lido isso certo — o que ela
    trocou foi o desenho do gesto, não a estrutura. Por isso a volta é limpa.

O QUE FICA DE FORA

    `CFrame.fromEulerAnglesXYZ(0, math.rad(swingrand), 0)` no braço direito.
    `swingrand` é `math.random(-50,50)` por golpe, e sorteio em gameplay é
    proibido: com todos os clientes desenhando, cada um veria um ângulo. A
    variação volta como jitter senoidal por contador, no Server.
"""

import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(RAIZ, "FERRAMENTAS", "dados", "poses_guest.json")

ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")

#: Tool -> (nome da pose por QUADRO extraído, sequências)
#
# O Cano deu 4 quadros: carga e batida de cada um dos dois golpes.
# O Taco deu 5: os mesmos quatro, mais o quadro erguido do finalizador.
CONJUNTO = {
    "Cano De Rua": {
        "quadros": ["CARGA_A", "BATE_A", "CARGA_B", "BATE_B"],
        "lidera": "RightArm",
        "sequencias": [
            ("GOLPE_A", "golpe rápido", [
                ("CARGA_A", 0.18, "Back", "In", "CARGA"),
                ("CARGA_A", 0.12, "Sine", "InOut", None),
                ("BATE_A", 0.10, "Quint", "Out", "GOLPE"),
                ("BATE_A", 0.14, "Sine", "InOut", None),
                ("IDLE", 0.22, "Quad", "Out", None),
            ]),
            ("GOLPE_B", "golpe rápido", [
                ("CARGA_B", 0.18, "Back", "In", "CARGA"),
                ("CARGA_B", 0.12, "Sine", "InOut", None),
                ("BATE_B", 0.10, "Quint", "Out", "GOLPE"),
                ("BATE_B", 0.16, "Sine", "InOut", None),
                ("IDLE", 0.24, "Quad", "Out", "FIM"),
            ]),
            # a Extra nova: cegar. O gesto é o do segundo golpe, segurado —
            # o cano sobe à altura dos olhos e fica lá.
            ("CEGAR", "golpe pesado", [
                ("CARGA_B", 0.22, "Back", "In", "CARGA"),
                ("CARGA_B", 0.40, "Sine", "InOut", None, 0.035, 22),
                ("BATE_B", 0.12, "Quint", "Out", "GOLPE"),
                ("BATE_B", 0.30, "Sine", "InOut", "SEGURA", 0.045, 26),
                ("IDLE", 0.26, "Quad", "Out", None),
            ]),
        ],
    },
    "Taco de Baseball": {
        "quadros": ["CARGA_A", "BATE_A", "CARGA_B", "BATE_B", "ERGUE"],
        "lidera": "HRP",
        "sequencias": [
            ("GOLPE_A", "golpe rápido", [
                ("CARGA_A", 0.20, "Back", "In", "CARGA"),
                ("CARGA_A", 0.12, "Sine", "InOut", None),
                ("BATE_A", 0.10, "Quint", "Out", "GOLPE"),
                ("BATE_A", 0.14, "Sine", "InOut", None),
                ("IDLE", 0.22, "Quad", "Out", None),
            ]),
            ("GOLPE_B", "golpe rápido", [
                ("CARGA_B", 0.20, "Back", "In", "CARGA"),
                ("CARGA_B", 0.14, "Sine", "InOut", None),
                ("BATE_B", 0.10, "Quint", "Out", "GOLPE"),
                ("BATE_B", 0.16, "Sine", "InOut", None),
                ("IDLE", 0.24, "Quad", "Out", "FIM"),
            ]),
            # a Extra nova: rebater. O taco ergue e fica de prontidão — a
            # janela de rebatida é o quadro SEGURADO, não o instante do golpe.
            ("REBATER", "sustentada", [
                ("ERGUE", 0.18, "Back", "Out", "CARGA"),
                ("ERGUE", 0.44, "Sine", "InOut", "SEGURA", 0.03, 20),
                ("ERGUE", 0.40, "Sine", "InOut", "SEGURA", 0.04, 24),
                ("BATE_B", 0.12, "Quint", "Out", "GOLPE"),
                ("BATE_B", 0.18, "Sine", "InOut", None),
                ("IDLE", 0.24, "Quad", "Out", None),
            ]),
        ],
    },
}

#: A guarda: o quadro de repouso, comum às duas. Sai do primeiro quadro
#: extraído com os braços baixados — é o que o original chama de `equip()`.
IDLE = {
    "RightArm": "CFrame.new(1.5, 0, 0)",
    "LeftArm": "CFrame.new(-1.5, 0, 0)",
    "Head": "CFrame.new(0, 1.5, 0)",
    "HRP": "CFrame.new(0, 0, 0)",
}


def escrever(tool, dados, quadros):
    poses = {"IDLE": dict(IDLE)}
    for indice, nome in enumerate(dados["quadros"]):
        if indice < len(quadros):
            poses[nome] = quadros[indice]

    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto GUEST)" % tool)
    L.append("--")
    L.append("-- ⚠️ ESTAS POSES SÃO DO MODELO DE ORIGEM, NÃO AUTORAIS.")
    L.append("--")
    L.append("-- Foram extraídas do `guest_tools.rbxmx` pelo")
    L.append("-- FERRAMENTAS/extrair_poses_guest.py, a pedido: a animação original")
    L.append("-- destas duas Tools volta, e as outras cinco do conjunto seguem autorais.")
    L.append("--")
    L.append("-- Elas PODEM voltar sem perda porque o laço de origem varre o alpha de 0")
    L.append("-- a 1 — `lerp(alvo, 1)` é o próprio alvo, então a pose escrita no código é")
    L.append("-- a pose alcançada. No Xester o alpha era constante e foi preciso simular.")
    L.append("--")
    L.append("-- A convenção já era a nossa: o original solda Weld do Torso para o")
    L.append("-- membro, com os nomes RightArmWelde/LeftArmWelde/HeadWelde. Zero conversão.")
    L.append("--")
    L.append("-- FORA: `CFrame.fromEulerAnglesXYZ(0, math.rad(swingrand), 0)` no braço")
    L.append("-- direito. `swingrand` é math.random(-50,50) por golpe, e sorteio em")
    L.append("-- gameplay é proibido — a variação volta como jitter no Server.")
    L.append("--")
    L.append("-- JUNTA QUE LIDERA: **%s**." % dados["lidera"])
    L.append("--")
    for nome, natureza, passos in dados["sequencias"]:
        total = sum(p[1] for p in passos)
        L.append("--   %-12s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_guest_originais.py.")
    L.append("")
    L.append("local P = {}")
    L.append("")

    for nome in sorted(poses):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in poses[nome]:
                L.append("\t%s = %s," % (junta, poses[nome][junta]))
        L.append("}")

    L.append("")
    L.append("P.SEQUENCIAS = {")
    for nome, natureza, passos in dados["sequencias"]:
        total = sum(p[1] for p in passos)
        L.append("")
        L.append("\t-- %s · %.2fs · %d passo(s)" % (natureza, total, len(passos)))
        L.append("\t%s = {" % nome)
        for passo in passos:
            pose, t, estilo, direcao, marca = passo[:5]
            campos = ['pose = "%s"' % pose, "time = %s" % t,
                      'style = "%s"' % estilo, 'dir = "%s"' % direcao]
            if len(passo) > 5 and passo[5]:
                campos.append("tremor = %s" % passo[5])
            if len(passo) > 6 and passo[6]:
                campos.append("freq = %s" % passo[6])
            if marca:
                campos.append('marca = "%s"' % marca)
            L.append("\t\t{ %s }," % ", ".join(campos))
        L.append("\t},")
    L.append("")
    L.append("}")
    L.append("")
    L.append("return P")
    return "\n".join(L) + "\n"


def main():
    if not os.path.exists(DADOS):
        print("sem %s — rode FERRAMENTAS/extrair_poses_guest.py antes" % DADOS)
        return 1
    with open(DADOS, encoding="utf-8") as f:
        tabela = json.load(f)

    for tool, dados in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        quadros = tabela.get(tool, [])
        if len(quadros) < len(dados["quadros"]):
            print("%s: extraí %d quadro(s), preciso de %d"
                  % (tool, len(quadros), len(dados["quadros"])))
            return 1
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, dados, quadros))
        print("%-20s %d pose(s) da ORIGEM · %d sequência(s)"
              % (tool, len(dados["quadros"]), len(dados["sequencias"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
