#!/usr/bin/env python3
"""
gerar_poses_reality.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto REALITY GUI.

    python3 FERRAMENTAS/extrair_keyframes_reality.py   # antes
    python3 FERRAMENTAS/gerar_poses_reality.py

DUAS ORIGENS DE POSE NO MESMO CONJUNTO, E É A PRIMEIRA VEZ

    | Tool | De onde vem a pose |
    |---|---|
    | `Trem` | **`KeyframeSequence`** do `a-train` — 40 kf, amostrada em 10 |
    | `Danca Provocadora` | **`KeyframeSequence`** `california gurls` — **361 kf**, amostrada em 14 |
    | as outras cinco | autorais, pela `GRAMATICA_R6.md` |

    As duas primeiras são a estreia do formato: `Keyframe` datado com `Pose`
    por junta, que é o que o Animation Editor do Studio produz. Tudo que entrou
    aqui antes era pose escrita em laço.

    A conversão está no `extrair_keyframes_reality.py`, e o ponto dela é que
    `Pose.CFrame` NÃO é o `C0` que o animator quer — é um delta sobre a junta em
    repouso. `C0 = base * Pose.CFrame`.

QUEM LIDERA (regra 6)

    | Tool | lidera | por quê |
    |---|---|---|
    | `Lapada Seca` | RightArm | tapa |
    | `Canhao Satelite` | RightArm | conjuração — marca o ponto |
    | `Trem` | **HRP** | investida: o corpo inteiro vai |
    | `Arvore Maligna` | RightArm | conjuração |
    | `Gato Ajudante Boss` | RightArm | invocação |
    | `Samsungus` | RightArm | golpe de mão |
    | `Danca Provocadora` | **HRP** | dança é do tronco, e a origem concorda |
"""

import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(RAIZ, "FERRAMENTAS", "dados", "keyframes_reality.json")

ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")


def J(x, y, z, rx=0, ry=0, rz=0):
    return (x, y, z, rx, ry, rz)


def P(nome, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=nome, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.05, -0.22, 18, 4, 4),
        "LeftArm": J(-1.48, 0.05, -0.22, 18, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },
    # o tapa: a mão sobe aberta e desce em arco
    "TAPA_ERGUE": {
        "RightArm": J(1.42, 0.66, -0.3, 138, -20, -30),
        "LeftArm": J(-1.44, 0.1, -0.3, 30, 10, 14),
        "Head": J(0, 1.5, 0, -12, 22, 0),
        "HRP": J(0, 0.04, 0, -6, -26, 0),
    },
    "TAPA_BATE": {
        "RightArm": J(1.5, 0.16, -1.0, 66, -34, -14),
        "LeftArm": J(-1.42, 0.02, -0.4, 34, 16, 20),
        "Head": J(0, 1.5, 0, 6, -30, 0),
        "HRP": J(0, -0.04, 0, 5, 40, 0),
        "RightLeg": J(0.5, -1.9, -0.24, -12, 0, 0),
    },
    # marcar o ponto: braço reto para o alvo, palma para baixo
    "MARCA": {
        "RightArm": J(1.52, 0.38, -1.2, 92, -4, -3),
        "LeftArm": J(-1.44, 0.08, -0.28, 26, 8, 10),
        "Head": J(0, 1.5, 0, -6, -4, 0),
        "HRP": J(0, 0.02, 0, -4, 8, 0),
        "RightLeg": J(0.5, -1.88, -0.22, -11, 0, 0),
    },
    "CHAMA_CEU": {
        "RightArm": J(1.42, 0.84, -0.06, 164, -10, -16),
        "LeftArm": J(-1.42, 0.84, -0.06, 164, 10, 16),
        "Head": J(0, 1.5, 0, -38, 0, 0),
        "HRP": J(0, 0.12, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.14, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.14, 8, 0, 0),
    },
    "RECUA": {
        "RightArm": J(1.3, 0.16, -0.6, 74, 16, 32),
        "LeftArm": J(-1.3, 0.16, -0.6, 74, -16, -32),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.16, 0, 14, 0, 0),
    },
    # a árvore sobe: as duas mãos abrem do chão para cima
    "PLANTA": {
        "RightArm": J(1.38, -0.3, -0.5, 34, 14, 22),
        "LeftArm": J(-1.38, -0.3, -0.5, 34, -14, -22),
        "Head": J(0, 1.5, 0, 22, 0, 0),
        "HRP": J(0, -0.42, 0, 20, 0, 0),
        "RightLeg": J(0.5, -1.64, -0.52, -34, 0, 0),
        "LeftLeg": J(-0.5, -1.64, -0.52, -34, 0, 0),
    },
    "CRESCE": {
        "RightArm": J(1.5, 0.6, -0.34, 122, -16, -26),
        "LeftArm": J(-1.5, 0.6, -0.34, 122, 16, 26),
        "Head": J(0, 1.5, 0, -28, 0, 0),
        "HRP": J(0, 0.1, 0, -12, 0, 0),
    },
    # o assobio que chama o gato
    "ASSOBIA": {
        "RightArm": J(1.36, 0.5, -0.7, 112, -22, -26),
        "LeftArm": J(-1.46, 0.06, -0.26, 24, 8, 10),
        "Head": J(0, 1.5, 0, -14, 10, 0),
        "HRP": J(0, 0.04, 0, -6, -12, 0),
    },
    "APONTA_ALVO": {
        "RightArm": J(1.52, 0.36, -1.18, 90, -6, -4),
        "LeftArm": J(-1.44, 0.06, -0.28, 26, 8, 10),
        "Head": J(0, 1.5, 0, -4, -8, 0),
        "HRP": J(0, 0.02, 0, -3, 12, 0),
    },
    # o celular: gira na mão e bate de lado
    "GIRA_MAO": {
        "RightArm": J(1.44, 0.34, -0.56, 88, -26, -22),
        "LeftArm": J(-1.46, 0.06, -0.26, 24, 8, 10),
        "Head": J(0, 1.5, 0, -6, 16, 0),
        "HRP": J(0, 0.02, 0, -4, -18, 0),
    },
    "BATE_LADO": {
        "RightArm": J(1.5, 0.28, -1.06, 78, -30, -8),
        "LeftArm": J(-1.4, 0.02, -0.38, 32, 14, 18),
        "Head": J(0, 1.5, 0, 4, -26, 0),
        "HRP": J(0, -0.04, 0, 5, 34, 0),
        "RightLeg": J(0.5, -1.9, -0.24, -12, 0, 0),
    },
    # a SEGUNDA batida do leadpipe: vem de cima, braço aberto, corpo para trás
    "ERGUE_ALTO": {
        "RightArm": J(1.4, 0.72, -0.18, 152, -14, -22),
        "LeftArm": J(-1.44, 0.14, -0.34, 36, 12, 16),
        "Head": J(0, 1.5, 0, -18, 8, 0),
        "HRP": J(0, 0.06, 0, -10, -12, 0),
    },
    "DESCE_ALTO": {
        "RightArm": J(1.46, -0.1, -0.92, 44, -10, -6),
        "LeftArm": J(-1.38, -0.02, -0.44, 40, 16, 22),
        "Head": J(0, 1.5, 0, 16, -8, 0),
        "HRP": J(0, -0.12, 0, 18, 12, 0),
        "RightLeg": J(0.5, -1.86, -0.3, -16, 0, 0),
        "LeftLeg": J(-0.5, -1.92, 0.16, 9, 0, 0),
    },
    # a mão aberta e parada, palma para a frente: a "mão quente" da lapada
    "MAO_ABERTA": {
        "RightArm": J(1.52, 0.3, -0.86, 84, -18, -6),
        "LeftArm": J(-1.46, 0.08, -0.3, 26, 8, 12),
        "Head": J(0, 1.5, 0, -8, -10, 0),
        "HRP": J(0, 0.02, 0, -5, 14, 0),
    },
}


#: as cinco autorais. As duas de KeyframeSequence entram por `DA_ORIGEM`.
AUTORAIS = {
    "Lapada Seca": ("RightArm", {
        "TAPA": ("golpe rápido", [
            P("TAPA_ERGUE", 0.18, "Back", "In", "CARGA"),
            P("TAPA_ERGUE", 0.14, "Sine", "InOut"),
            P("TAPA_BATE", 0.10, "Quint", "Out", "GOLPE"),
            P("TAPA_BATE", 0.16, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out"),
        ]),
        # A MÃO QUENTE — sustentada, não combo.
        #
        # A origem não tem três tapas: tem a mão ligada no `Touched` enquanto a
        # Tool estiver equipada. A pose acompanha isso — ergue, ABRE, e fica
        # parada com a palma para a frente pelos 5 s da janela.
        "MAO_QUENTE": ("sustentada", [
            P("TAPA_ERGUE", 0.26, "Back", "In", "CARGA"),
            P("MAO_ABERTA", 0.30, "Quint", "Out", "SEGURA"),
            P("MAO_ABERTA", 2.40, "Sine", "InOut", None, 0.03, 19),
            P("MAO_ABERTA", 2.30, "Sine", "InOut", None, 0.045, 24),
            P("IDLE", 0.34, "Quad", "Out", "FIM"),
        ]),
    }),
    "Canhao Satelite": ("RightArm", {
        # ULTIMATE COM CUTSCENE · 7.30 s · 71% de preparação (regra 5)
        "ORBITA": ("ultimate", [
            P("MARCA", 0.45, "Back", "In", "CAMERA", 0.02, 15),
            P("MARCA", 0.90, "Sine", "InOut", "MARCA", 0.03, 20),
            P("CHAMA_CEU", 0.85, "Quad", "InOut", "CARGA", 0.04, 24),
            P("CHAMA_CEU", 1.20, "Sine", "InOut", None, 0.055, 29),
            P("CHAMA_CEU", 1.25, "Sine", "InOut", "SEGURA", 0.07, 34),
            P("RECUA", 0.30, "Quint", "In", "DESCE"),
            P("RECUA", 0.30, "Sine", "InOut", "GOLPE"),
            P("RECUA", 0.85, "Sine", "InOut", None, 0.06, 31),
            P("IDLE", 1.20, "Quad", "Out", "FIM"),
        ]),
        "MIRA": ("conjuração", [
            P("MARCA", 0.22, "Back", "In", "CARGA"),
            P("MARCA", 0.34, "Sine", "InOut", None, 0.03, 21),
            P("MARCA", 0.14, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.30, "Quad", "Out"),
        ]),
    }),
    "Arvore Maligna": ("RightArm", {
        "PLANTAR": ("golpe pesado", [
            P("PLANTA", 0.26, "Back", "In", "CARGA"),
            P("PLANTA", 0.44, "Sine", "InOut", None, 0.04, 23),
            P("CRESCE", 0.16, "Quint", "Out", "GOLPE"),
            P("CRESCE", 0.34, "Sine", "InOut", "SEGURA", 0.05, 27),
            P("IDLE", 0.30, "Quad", "Out"),
        ]),
        "GALHADA": ("sustentada", [
            P("CRESCE", 0.22, "Back", "In", "CARGA"),
            P("CRESCE", 0.42, "Sine", "InOut", "SEGURA", 0.04, 25),
            P("PLANTA", 0.14, "Quint", "Out", "GOLPE"),
            P("PLANTA", 0.24, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),
    "Gato Ajudante Boss": ("RightArm", {
        "CHAMAR": ("conjuração", [
            P("ASSOBIA", 0.24, "Back", "In", "CARGA"),
            P("ASSOBIA", 0.40, "Sine", "InOut", None, 0.03, 22),
            P("APONTA_ALVO", 0.14, "Quint", "Out", "GOLPE"),
            P("APONTA_ALVO", 0.22, "Sine", "InOut"),
            P("IDLE", 0.30, "Quad", "Out"),
        ]),
        "MANDAR": ("conjuração", [
            P("APONTA_ALVO", 0.20, "Back", "In", "CARGA"),
            P("APONTA_ALVO", 0.28, "Sine", "InOut"),
            P("APONTA_ALVO", 0.12, "Quint", "Out", "GOLPE"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),
    "Samsungus": ("RightArm", {
        # O COMBO DE DUAS. `attacknumber` da origem alterna as batidas: a A vem
        # de lado com o corpo torcido, a B vem de cima com o braço aberto. São
        # duas animações diferentes, e a versão anterior tinha uma só.
        "BATIDA": ("golpe rápido", [
            P("GIRA_MAO", 0.20, "Back", "In", "CARGA"),
            P("GIRA_MAO", 0.14, "Sine", "InOut"),
            P("BATE_LADO", 0.10, "Quint", "Out", "GOLPE"),
            P("BATE_LADO", 0.16, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out"),
        ]),
        "BATIDA_B": ("golpe rápido", [
            P("ERGUE_ALTO", 0.22, "Back", "In", "CARGA"),
            P("ERGUE_ALTO", 0.16, "Sine", "InOut"),
            P("DESCE_ALTO", 0.11, "Quint", "Out", "GOLPE"),
            P("DESCE_ALTO", 0.17, "Sine", "InOut"),
            P("IDLE", 0.26, "Quad", "Out"),
        ]),
        "CHAMADA": ("golpe pesado", [
            P("GIRA_MAO", 0.24, "Back", "In", "CARGA"),
            P("GIRA_MAO", 0.46, "Sine", "InOut", "SEGURA", 0.04, 26),
            P("BATE_LADO", 0.12, "Quint", "Out", "GOLPE"),
            P("BATE_LADO", 0.20, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),
}

#: Tool -> (chave no keyframes_reality.json, lidera, nome da sequência,
#:          natureza, marcas por índice de quadro)
DA_ORIGEM = {
    "Trem": ("a-train", "HRP", "INVESTIDA", "golpe pesado",
             {0: "CARGA", 4: "GOLPE", 9: "FIM"}),
    "Danca Provocadora": ("kick dance", "HRP", "DANCA", "sustentada",
                          {0: "CARGA", 3: "GOLPE", 7: "GOLPE", 11: "GOLPE",
                           13: "FIM"}),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def escrever_autoral(tool, lidera, poses, sequencias):
    L = ["-- Poses.lua",
         "-- ModuleScript \"Poses\" — %s  (conjunto REALITY GUI)" % tool,
         "--",
         "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.",
         "-- Sequência usa `time` / `style` / `dir` (V2).",
         "--",
         "-- AUTORAL, pela GRAMATICA_R6.md. Nenhum script da origem atravessou a",
         "-- quarentena do `reality_tools.rbxmx` — só geometria, som e malha.",
         "--",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("--   %-12s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))
    L += ["--", "-- Gerado por FERRAMENTAS/gerar_poses_reality.py.", "",
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


def escrever_da_origem(tool, dados, info, seq_nome, natureza, marcas, lidera):
    quadros = dados["quadros"]
    L = ["-- Poses.lua",
         "-- ModuleScript \"Poses\" — %s  (conjunto REALITY GUI)" % tool,
         "--",
         "-- ⚠️ ESTAS POSES VÊM DE UMA `KeyframeSequence` DE VERDADE.",
         "--",
         "-- Origem: `%s/%s` — **%d Keyframe** em %.2f s, amostrados em %d."
         % (info, dados["sequencia"], dados["keyframes_na_origem"],
            dados["duracao"], len(quadros)),
         "--",
         "-- É a estreia do formato no repositório: tudo que entrou antes era",
         "-- pose escrita em laço (`Weld.C0` no Guest e no Xester, `Motor6D.C0`",
         "-- no Noob). Esta é a coisa que o Animation Editor do Studio produz.",
         "--",
         "-- A CONVERSÃO: `Pose.CFrame` não é o `C0` que o animator quer — é um",
         "-- DELTA sobre a junta em repouso. Por isso `C0 = base * Pose.CFrame`,",
         "-- com a base sendo o repouso R6 (RightArm 1.5,0,0 e companhia). Sem",
         "-- multiplicar, o braço nasceria no meio do peito.",
         "--",
         "-- A AMOSTRAGEM é por TEMPO, não por índice: o Animation Editor grava",
         "-- quadro denso onde o movimento é rápido, e amostrar por índice",
         "-- espremeria a parte lenta. Perde-se o detalhe fino do gesto; guarda-se",
         "-- a silhueta, o ritmo e a duração.",
         "--",
         "-- Nenhum script da origem atravessou a quarentena. `KeyframeSequence`",
         "-- é DADO, não código.",
         "--",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera,
         "--", "-- Gerado por FERRAMENTAS/gerar_poses_reality.py.", "",
         "local P = {}", ""]

    for indice, q in enumerate(quadros):
        L.append("")
        L.append("P.Q%02d = {" % (indice + 1))
        for junta in ORDEM:
            if junta in q["juntas"]:
                L.append("\t%s = %s," % (junta, q["juntas"][junta]))
        L.append("}")

    L += ["", "P.SEQUENCIAS = {", "",
          "\t-- %s · %.2fs · %d passo(s), da KeyframeSequence"
          % (natureza, dados["duracao"], len(quadros)),
          "\t%s = {" % seq_nome]
    for indice, q in enumerate(quadros):
        if indice == 0:
            dt = 0.12
        else:
            dt = max(round(q["t"] - quadros[indice - 1]["t"], 3), 0.04)
        campos = ['pose = "Q%02d"' % (indice + 1), "time = %s" % dt,
                  'style = "Sine"', 'dir = "InOut"']
        if indice in marcas:
            campos.append('marca = "%s"' % marcas[indice])
        L.append("\t\t{ %s }," % ", ".join(campos))
    L += ["\t},", "", "}", "", "return P"]
    return "\n".join(L) + "\n"


def main():
    if not os.path.exists(DADOS):
        print("sem %s — rode extrair_keyframes_reality.py antes" % DADOS)
        return 1
    with open(DADOS, encoding="utf-8") as f:
        tabela = json.load(f)

    for tool, (lidera, sequencias) in AUTORAIS.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        poses = {}
        for _n, passos in sequencias.values():
            for p in passos:
                if p["pose"] not in BASE:
                    print("pose %r não existe (%s)" % (p["pose"], tool))
                    return 1
                poses[p["pose"]] = BASE[p["pose"]]
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever_autoral(tool, lidera, poses, sequencias))
        print("%-20s AUTORAL   %d pose(s) · %d sequência(s)"
              % (tool, len(poses), len(sequencias)))

    for tool, (chave, lidera, seq, natureza, marcas) in DA_ORIGEM.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        dados = tabela.get(chave)
        if not dados:
            print("%s: sem dados de %r" % (tool, chave))
            return 1
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever_da_origem(tool, dados, chave, seq, natureza,
                                       marcas, lidera))
        print("%-20s ORIGEM    %d quadro(s) de %d keyframes · %.2fs"
              % (tool, len(dados["quadros"]), dados["keyframes_na_origem"],
                 dados["duracao"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
