#!/usr/bin/env python3
"""
gerar_poses_reality.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto REALITY GUI.

    python3 FERRAMENTAS/extrair_keyframes_reality.py   # antes
    python3 FERRAMENTAS/extrair_welds_reality.py       # antes
    python3 FERRAMENTAS/gerar_poses_reality.py

════════════════════════════════════════════════════════════════════════
A ANIMAÇÃO É A DA ORIGEM, INTEIRA. NADA DE AMOSTRAGEM.
════════════════════════════════════════════════════════════════════════

    A primeira versão deste arquivo amostrou o `a-train` de **40 para 10**
    quadros e o `kick dance` de **361 para 14**. Isso não é "guardar a
    silhueta": é jogar a animação fora e desenhar outra por cima. Foi o erro
    mais grave do conjunto.

    Agora entra tudo:

    | Tool | De onde vem a pose | Quantos |
    |---|---|---|
    | `Trem` | `KeyframeSequence` `a-train` | **40 de 40** |
    | `Danca Provocadora` | `KeyframeSequence` `california gurls` | **361 de 361** |
    | `Samsungus` | `Weld.C0` escrito no `LeadpipeServer` | 4 blocos, 2 golpes |
    | `Canhao Satelite` | `Weld.C0` escrito no Script do LOIC | 6 blocos, 3 tempos |
    | `Lapada Seca` · `Arvore Maligna` · `Gato Ajudante Boss` | autoral | a origem não anima o personagem |

    Os 361 são todos DISTINTOS entre si, e o passo é uniforme em 1/30 s — não
    há quadro repetido para descartar. Amostrar era perda pura.

════════════════════════════════════════════════════════════════════════
`TRACK`, NÃO `SEQUENCE` — E O MOTIVO É DERIVA
════════════════════════════════════════════════════════════════════════

    `PlaySequence` encadeia um Tween por passo e emenda no `Completed`. Com
    passo de 1/30 s isso custa um quadro de emenda por keyframe: 361 emendas
    somariam **~6 s** numa animação de 12 s, e a dança rodaria em câmera lenta.

    `PlayTrack` roda no `Heartbeat` com acumulador `dt` e tempo ABSOLUTO por
    keyframe. Ele não emenda nada — ele pergunta "que horas são" e interpola o
    segmento certo. 361 quadros em 12.00 s saem em 12.00 s.

    Por isso `Trem` e `Danca Provocadora` saem em `P.TRACKS`, e as outras cinco
    — que têm poucos passos e beats nítidos — seguem em `P.SEQUENCIAS`.

════════════════════════════════════════════════════════════════════════
AS DUAS CONVERSÕES
════════════════════════════════════════════════════════════════════════

    `KeyframeSequence`  `Pose.CFrame` é um DELTA sobre a junta em repouso, não
                        o `C0` final. `C0 = base * Pose.CFrame`, com a base
                        sendo RightArm (1.5,0,0) e companhia.

    `Weld.C0` no script O alvo sai VERBATIM — já é Lua válido, e copiar o texto
                        não tem erro de arredondamento. Só o C1 da origem entra
                        como sufixo invertido. Ver `extrair_welds_reality.py`.

QUEM LIDERA (regra 6)

    | Tool | lidera |
    |---|---|
    | `Lapada Seca` | RightArm — tapa |
    | `Canhao Satelite` | RightArm — a origem só anima braço e cabeça |
    | `Trem` | **HRP** — investida: o corpo inteiro vai |
    | `Arvore Maligna` | RightArm — conjuração |
    | `Gato Ajudante Boss` | RightArm — invocação |
    | `Samsungus` | RightArm — golpe de mão |
    | `Danca Provocadora` | **HRP** — dança é do tronco, e a origem concorda |
"""

import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(RAIZ, "FERRAMENTAS", "dados")
KEYFRAMES = os.path.join(DADOS, "keyframes_reality.json")
WELDS = os.path.join(DADOS, "welds_reality.json")

ORDEM = ("RightArm", "LeftArm", "Head", "HRP", "RightLeg", "LeftLeg")


def J(x, y, z, rx=0, ry=0, rz=0):
    return (x, y, z, rx, ry, rz)


def P(nome, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=nome, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


# ═══════════════════════════════════════════════════════════════
# AS TRÊS AUTORAIS — a origem não anima o personagem nelas
#
#   `SLAP`         o `Animation` da Tool tem `AnimationId` **VAZIO**: o
#                  `LoadAnimation` da origem toca nada.
#   `tre`          quem se mexe é a árvore, não quem planta.
#   `gravity cat`  quem se mexe é o gato.
#
# Nestas três não há o que ser fiel a: o gesto é escrito aqui, curto, só para
# a habilidade ter um disparo legível.
# ═══════════════════════════════════════════════════════════════

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
}

AUTORAIS = {
    "Lapada Seca": ("RightArm", {
        "TAPA": ("golpe rápido", [
            P("TAPA_ERGUE", 0.18, "Back", "In", "CARGA"),
            P("TAPA_ERGUE", 0.14, "Sine", "InOut"),
            P("TAPA_BATE", 0.10, "Quint", "Out", "GOLPE"),
            P("TAPA_BATE", 0.16, "Sine", "InOut"),
            P("IDLE", 0.24, "Quad", "Out", "FIM"),
        ]),
    }),
    "Arvore Maligna": ("RightArm", {
        "PLANTAR": ("golpe pesado", [
            P("PLANTA", 0.26, "Back", "In", "CARGA"),
            P("PLANTA", 0.44, "Sine", "InOut", None, 0.04, 23),
            P("CRESCE", 0.16, "Quint", "Out", "GOLPE"),
            P("CRESCE", 0.34, "Sine", "InOut", None, 0.05, 27),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
    }),
    "Gato Ajudante Boss": ("RightArm", {
        "CHAMAR": ("conjuração", [
            P("ASSOBIA", 0.24, "Back", "In", "CARGA"),
            P("ASSOBIA", 0.40, "Sine", "InOut", None, 0.03, 22),
            P("APONTA_ALVO", 0.14, "Quint", "Out", "GOLPE"),
            P("APONTA_ALVO", 0.22, "Sine", "InOut"),
            P("IDLE", 0.30, "Quad", "Out", "FIM"),
        ]),
    }),
}


# ═══════════════════════════════════════════════════════════════
# AS DUAS DE `KeyframeSequence` — track inteira
# ═══════════════════════════════════════════════════════════════

#: Tool -> (chave no keyframes_reality.json, lidera, nome da track,
#:          marcas por índice de quadro)
DE_KEYFRAME = {
    "Trem": ("a-train", "HRP", "INVESTIDA", {0: "CARGA", 16: "GOLPE"}),
    "Danca Provocadora": ("kick dance", "HRP", "DANCA",
                          {0: "CARGA", 90: "BATIDA", 180: "BATIDA",
                           270: "BATIDA"}),
}


# ═══════════════════════════════════════════════════════════════
# AS DUAS DE `Weld.C0` — os blocos do laço, na ordem em que a origem roda
# ═══════════════════════════════════════════════════════════════

#: A pose de repouso do `samsung`, tirada do `checkanim` com os termos de
#: `math.sin(sine/60)` zerados — é o centro do balanço que a origem faz.
#: Já vem com o C1 invertido aplicado, igual ao que o extrator faz.
IDLE_SAMSUNG = {
    "RightArm": ("CFrame.new(1.5,0.5,0)"
                 " * CFrame.fromEulerAnglesXYZ(math.rad(45), math.rad(-2.5),"
                 " math.rad(-10)) * CFrame.new(0, -0.5, 0)"),
    "LeftArm": ("CFrame.new(-1.5,0.5,0)"
                " * CFrame.fromEulerAnglesXYZ(math.rad(55), 0, math.rad(10))"
                " * CFrame.new(0, -0.5, 0)"),
    "Head": "CFrame.new(0,1,0) * CFrame.new(0, 0.5, 0)",
    "HRP": "CFrame.new(0,0,0)",
}

#: O repouso do LOIC: `rightarm.C0` e `head.C0` como nascem, antes do primeiro
#: laço. C1 identidade nos dois, então entram como estão.
IDLE_LOIC = {
    "RightArm": ("CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,0)"
                 " * CFrame.new(0,-0.5,0)"),
    "Head": "CFrame.new(0,1.5,0)",
}

#: Tool -> (chave no welds_reality.json, lidera, repouso, sequências)
#:
#: Cada sequência é (nome, natureza, [(bloco ou None, tempo, estilo, dir,
#: marca)]). `None` no bloco = usar o repouso.
DE_WELD = {
    "Samsungus": ("samsung", "RightArm", IDLE_SAMSUNG, [
        # `attacknumber == 0`: ergue (0.150s) · bate (0.183s) · dano
        ("BATIDA_A", "golpe rápido", [
            (0, 0.150, "Back", "In", "CARGA"),
            (1, 0.183, "Quint", "Out", "SOPRO"),
            (None, 0.220, "Quad", "Out", "GOLPE"),
        ]),
        # `attacknumber == 1`: o segundo golpe, com outro alvo de C0
        ("BATIDA_B", "golpe rápido", [
            (2, 0.150, "Back", "In", "CARGA"),
            (3, 0.183, "Quint", "Out", "SOPRO"),
            (None, 0.220, "Quad", "Out", "GOLPE"),
        ]),
    ]),
    # No LOIC braço e cabeça rodam em duas corrotinas PARALELAS com o mesmo
    # tempo: bloco 0+3 juntos, `wait(2.5)`, bloco 1+4, `wait(1.5)`, bloco 2+5.
    # Os pares são fundidos, e as esperas viram a duração do passo.
    "Canhao Satelite": ("loic", "RightArm", IDLE_LOIC, [
        ("ORBITA", "ultimate", [
            ((0, 3), 0.683, "Sine", "InOut", "CAMERA"),
            ((0, 3), 2.500, "Sine", "InOut", "CARGA"),
            ((1, 4), 0.683, "Sine", "InOut", "SEGURA"),
            ((1, 4), 1.500, "Sine", "InOut", "DESCE"),
            ((2, 5), 0.683, "Quint", "Out", "GOLPE"),
            (None, 0.900, "Quad", "Out", "FIM"),
        ]),
    ]),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def cabecalho(tool, extra):
    return ["-- Poses.lua",
            "-- ModuleScript \"Poses\" — %s  (conjunto REALITY GUI)" % tool,
            "--"] + extra + [
            "-- Gerado por FERRAMENTAS/gerar_poses_reality.py.", "",
            "local P = {}", ""]


def escrever_autoral(tool, lidera, poses, sequencias):
    L = cabecalho(tool, [
        "-- AUTORAL — e aqui isso não é escolha, é falta de original.",
        "--",
        "-- A origem NÃO ANIMA O PERSONAGEM nesta Tool. Ver o topo do gerador:",
        "-- o `Animation` da `SLAP` tem `AnimationId` vazio, e na `tre` e no",
        "-- `gravity cat` quem se mexe é o modelo invocado, não quem invoca.",
        "--",
        "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.",
        "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"])
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.insert(-3, "--   %-12s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))

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


def escrever_track(tool, dados, info, lidera, nome_track, marcas):
    quadros = dados["quadros"]
    L = cabecalho(tool, [
        "-- ⚠️ A `KeyframeSequence` DA ORIGEM, INTEIRA. SEM AMOSTRAGEM.",
        "--",
        "-- Origem: `%s/%s` — **%d Keyframe** em %.2f s, e os %d estão aqui."
        % (info, dados["sequencia"], dados["keyframes_na_origem"],
           dados["duracao"], len(quadros)),
        "--",
        "-- A primeira versão deste arquivo entregou 10 e 14 quadros. Isso não",
        "-- guarda a silhueta: joga a animação fora e desenha outra por cima.",
        "-- Os quadros são todos DISTINTOS e o passo é uniforme — não havia",
        "-- repetido para descartar, e amostrar era perda pura.",
        "--",
        "-- `P.TRACKS`, NÃO `P.SEQUENCIAS`, E O MOTIVO É DERIVA",
        "--",
        "--   `PlaySequence` emenda um Tween por passo no `Completed`, e cada",
        "--   emenda custa um quadro. Com passo de 1/30 s, %d emendas somariam"
        % len(quadros),
        "--   segundos de atraso e a animação rodaria em câmera lenta.",
        "--   `PlayTrack` roda no `Heartbeat` com acumulador `dt` e tempo",
        "--   ABSOLUTO: ele não emenda, ele pergunta que horas são.",
        "--",
        "-- A CONVERSÃO: `Pose.CFrame` não é o `C0` que o animator quer — é um",
        "-- DELTA sobre a junta em repouso. Por isso `C0 = base * Pose.CFrame`.",
        "-- Sem multiplicar, o braço nasceria no meio do peito.",
        "--",
        "-- `KeyframeSequence` é DADO, não código: nenhum script da origem",
        "-- atravessou a quarentena do `reality_tools.rbxmx`.",
        "--",
        "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"])

    L += ["P.TRACKS = {", "",
          "\t-- %d quadro(s) · %.2fs · tempo ABSOLUTO por keyframe"
          % (len(quadros), dados["duracao"]),
          "\t%s = {" % nome_track]
    for indice, q in enumerate(quadros):
        campos = ["t = %s" % round(q["t"], 4),
                  'style = "Sine"', 'dir = "InOut"']
        if indice in marcas:
            campos.append('event = "%s"' % marcas[indice])
        for junta in ORDEM:
            if junta in q["juntas"]:
                campos.append("%s = %s" % (junta, q["juntas"][junta]))
        L.append("\t\t{ %s }," % ", ".join(campos))
    L += ["\t},", "", "}", "", "return P"]
    return "\n".join(L) + "\n"


def escrever_weld(tool, dados, chave, lidera, repouso, sequencias):
    """Poses de `Weld.C0` lidas do script da origem — alvo verbatim."""
    blocos = dados[chave]

    #: nome da pose -> {junta: expressão Lua}
    poses = {"REPOUSO": dict(repouso)}
    for nome_seq, _natureza, passos in sequencias:
        for ordem, (qual, _t, _e, _d, _m) in enumerate(passos):
            if qual is None:
                continue
            indices = qual if isinstance(qual, tuple) else (qual,)
            juntas = {}
            for i in indices:
                juntas.update(blocos[i]["juntas"])
            poses["%s_%d" % (nome_seq, ordem)] = juntas

    L = cabecalho(tool, [
        "-- ⚠️ A ANIMAÇÃO DA ORIGEM, LIDA DO SCRIPT DELA.",
        "--",
        "-- Ela está escrita em laço, no idioma que o Guest já tinha ensinado:",
        "--",
        "--     for i = 0,1 , 0.14 do",
        "--         weld.C0 = weld.C0:lerp(<ALVO>, i)",
        "--         step:wait()",
        "--     end",
        "--",
        "-- `i` varre até 1, então a pose ESCRITA é a pose ALCANÇADA — dá para",
        "-- ler o alvo direto. A duração sai do laço: `ceil(1/passo)+1` voltas",
        "-- de `Stepped`, a 1/60 s cada.",
        "--",
        "-- O alvo entra VERBATIM: já é Lua válido, e copiar o texto não tem",
        "-- erro de arredondamento. Só o C1 da origem entra como sufixo",
        "-- INVERTIDO — ver a conta em `extrair_welds_reality.py`.",
        "--",
        "-- A primeira versão desta Tool inventou pose. Não precisava.",
        "--",
        "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"])

    for nome in sorted(poses):
        L.append("")
        L.append("P.%s = {" % nome)
        for junta in ORDEM:
            if junta in poses[nome]:
                L.append("\t%s = %s," % (junta, poses[nome][junta]))
        L.append("}")

    L += ["", "P.SEQUENCIAS = {"]
    for nome_seq, natureza, passos in sequencias:
        total = sum(p[1] for p in passos)
        L.append("")
        L.append("\t-- %s · %.2fs · %d passo(s), da origem"
                 % (natureza, total, len(passos)))
        L.append("\t%s = {" % nome_seq)
        for ordem, (qual, t, estilo, direcao, marca) in enumerate(passos):
            alvo = "REPOUSO" if qual is None else "%s_%d" % (nome_seq, ordem)
            campos = ['pose = "%s"' % alvo, "time = %s" % t,
                      'style = "%s"' % estilo, 'dir = "%s"' % direcao]
            if marca:
                campos.append('marca = "%s"' % marca)
            L.append("\t\t{ %s }," % ", ".join(campos))
        L.append("\t},")
    L += ["", "}", "", "return P"]
    return "\n".join(L) + "\n"


def gravar(tool, texto):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False
    with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
        f.write(texto)
    return True


def main():
    for caminho in (KEYFRAMES, WELDS):
        if not os.path.exists(caminho):
            print("faltando %s — rode os extratores antes" % caminho)
            return 1
    with open(KEYFRAMES, encoding="utf-8") as f:
        tabela_kf = json.load(f)
    with open(WELDS, encoding="utf-8") as f:
        tabela_weld = json.load(f)

    for tool, (lidera, sequencias) in AUTORAIS.items():
        poses = {}
        for _n, passos in sequencias.values():
            for p in passos:
                if p["pose"] not in BASE:
                    print("pose %r não existe (%s)" % (p["pose"], tool))
                    return 1
                poses[p["pose"]] = BASE[p["pose"]]
        if not gravar(tool, escrever_autoral(tool, lidera, poses, sequencias)):
            return 1
        print("%-20s AUTORAL   %d pose(s) · %d sequência(s)  (origem não anima)"
              % (tool, len(poses), len(sequencias)))

    for tool, (chave, lidera, track, marcas) in DE_KEYFRAME.items():
        dados = tabela_kf.get(chave)
        if not dados:
            print("%s: sem dados de %r" % (tool, chave))
            return 1
        if len(dados["quadros"]) != dados["keyframes_na_origem"]:
            print("%s: %d quadros para %d keyframes — o extrator ainda amostra"
                  % (tool, len(dados["quadros"]), dados["keyframes_na_origem"]))
            return 1
        if not gravar(tool, escrever_track(tool, dados, chave, lidera, track,
                                           marcas)):
            return 1
        print("%-20s TRACK     %d de %d keyframes · %.2fs  (INTEIRA)"
              % (tool, len(dados["quadros"]), dados["keyframes_na_origem"],
                 dados["duracao"]))

    for tool, (chave, lidera, repouso, sequencias) in DE_WELD.items():
        if chave not in tabela_weld:
            print("%s: sem dados de %r" % (tool, chave))
            return 1
        if not gravar(tool, escrever_weld(tool, tabela_weld, chave, lidera,
                                          repouso, sequencias)):
            return 1
        print("%-20s WELD      %d bloco(s) da origem · %d sequência(s)"
              % (tool, len(tabela_weld[chave]), len(sequencias)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
