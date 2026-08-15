#!/usr/bin/env python3
"""
gerar_poses_noob.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 7 Tools do conjunto NOOB.

    python3 FERRAMENTAS/gerar_poses_noob.py

A ORIGEM TEM ANIMAÇÃO, E NENHUM QUADRO DELA PODE SER COPIADO

    Este é o primeiro modelo que chega com animação de corpo **densa** e mesmo
    assim não deixa nada para herdar. O `noob_despertado.rbxmx` anima assim:

        RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0)
            * ANGLES(RAD(90), RAD(0), RAD(90)) * RIGHTSHOULDERC0,
            0.5 / Animation_Speed)

    Três coisas o desqualificam de uma vez:

    1. Escreve em **`Motor6D.C0`**, que a `REGRA_ANIMACAO_R6` proíbe — dois
       donos por junta com o `Animate` padrão do Roblox, e a pose treme e volta
       sozinha. Já aconteceu neste repositório.
    2. O alvo do `Clerp` é o valor ESCRITO, não o alcançado: um `lerp` a 0.5
       repetido N quadros nunca chega ao destino. Ler o código dá o alvo, não a
       pose. (Foi por isso que o `extrair_poses_xester.py` teve de simular o
       laço para achar o ponto real.)
    3. O laço é `for i=0, 0.5, 0.22 / Animation_Speed do Swait() ...` — o
       `Swait` é um laço de `wait()`. O tempo de cada quadro depende do FPS do
       servidor, então nem a DURAÇÃO é confiável.

    Extrair daqui daria trabalho de simulação para chegar a poses de um corpo
    que o repositório anima de outro jeito. As sete são autorais.

O VOCABULÁRIO: DUAS MÃOS, PALMA PARA CIMA

    O `Shot` da origem é o único gesto que dá para ler direto — braço direito
    esticado a 90° com o tronco girado 90°, que é pose de **atirar de lado**. É
    o único empréstimo, e vira `APONTA_LADO`.

    O resto sai do tema: o Noob conjura do VAZIO, e vazio se abre com a palma
    para cima. `ABRE_PALMA`, `ERGUE_DUAS`, `PUXA_PEITO` — nenhuma delas soca.
    O único golpe de contato do conjunto é o `Colar das Trevas`, que agarra.

QUEM LIDERA (regra 6)

    | Tool | lidera | por quê |
    |---|---|---|
    | `Tiro do Vazio` | RightArm | conjuração/tiro |
    | `Chuva de Lava` | **HRP** | **exceção declarada** — a laje sobe sob o corpo |
    | `Parada do Tempo` | RightArm | conjuração |
    | `Buraco Negro` | RightArm | conjuração |
    | `Colar das Trevas` | RightArm | agarrão sai do braço |
    | `Explosao Lunar` | Head | **exceção declarada** — quem chama a lua olha para cima |
    | `Super Dominus` | **HRP** | a coroa desce sobre o portador, não sai da mão |

    Duas exceções, as duas pelo mesmo motivo: o efeito nasce no portador e o
    envolve. Conduzir isso pelo braço leria como "ele jogou algo".
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
# O VOCABULÁRIO DO CONJUNTO
# ═══════════════════════════════════════════════════════════════

BASE = {
    "IDLE": {
        "RightArm": J(1.48, 0.05, -0.24, 20, 4, 4),
        "LeftArm": J(-1.48, 0.05, -0.24, 20, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -5, 0),
    },
    # o único empréstimo da origem: braço reto a 90°, tronco de lado
    "APONTA_LADO": {
        "RightArm": J(1.54, 0.42, -1.08, 88, -6, -14),
        "LeftArm": J(-1.34, 0.5, -0.42, 128, 16, 22),
        "Head": J(0, 1.5, 0, -4, -34, 0),
        "HRP": J(0, 0, 0, 0, 52, 0),
        "RightLeg": J(0.5, -1.9, -0.2, -10, 0, 0),
    },
    # palma para cima: é assim que o vazio se abre
    "ABRE_PALMA": {
        "RightArm": J(1.5, 0.16, -0.72, 66, -12, -22),
        "LeftArm": J(-1.44, 0.06, -0.3, 26, 8, 12),
        "Head": J(0, 1.5, 0, -10, -8, 0),
        "HRP": J(0, 0.02, 0, -5, 10, 0),
    },
    "ERGUE_DUAS": {
        "RightArm": J(1.46, 0.76, -0.12, 152, -12, -26),
        "LeftArm": J(-1.46, 0.76, -0.12, 152, 12, 26),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.12, 0, -14, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.14, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.14, 8, 0, 0),
    },
    # as duas mãos recolhidas ao peito — puxar, colapsar, apertar
    "PUXA_PEITO": {
        "RightArm": J(1.28, 0.14, -0.6, 78, 18, 36),
        "LeftArm": J(-1.28, 0.14, -0.6, 78, -18, -36),
        "Head": J(0, 1.5, 0, 14, 0, 0),
        "HRP": J(0, -0.14, 0, 14, 0, 0),
    },
    # as duas mãos para o chão: a laje que sobe
    "BAIXA_DUAS": {
        "RightArm": J(1.36, -0.36, -0.46, 30, 16, 24),
        "LeftArm": J(-1.36, -0.36, -0.46, 30, -16, -24),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.46, 0, 22, 0, 0),
        "RightLeg": J(0.5, -1.62, -0.54, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.62, -0.54, -36, 0, 0),
    },
    # a mão espalmada à frente, parando o tempo
    "PARA_MAO": {
        "RightArm": J(1.52, 0.4, -1.2, 92, -4, -4),
        "LeftArm": J(-1.42, 0.1, -0.34, 32, 10, 14),
        "Head": J(0, 1.5, 0, -6, -6, 0),
        "HRP": J(0, 0.02, 0, -4, 10, 0),
        "RightLeg": J(0.5, -1.88, -0.24, -12, 0, 0),
    },
    # o agarrão: a mão fecha na altura do pescoço do alvo
    "AGARRA": {
        "RightArm": J(1.5, 0.52, -1.06, 104, -8, -10),
        "LeftArm": J(-1.32, 0.2, -0.5, 58, 14, 22),
        "Head": J(0, 1.5, 0, -8, -14, 0),
        "HRP": J(0, 0.04, 0, -6, 18, 0),
        "RightLeg": J(0.5, -1.86, -0.3, -15, 0, 0),
    },
    "PUXA_ALTO": {
        "RightArm": J(1.44, 0.8, -0.44, 146, -14, -18),
        "LeftArm": J(-1.36, 0.24, -0.44, 62, 12, 20),
        "Head": J(0, 1.5, 0, -26, -10, 0),
        "HRP": J(0, 0.08, 0, -12, 14, 0),
    },
    # a cabeça para trás, chamando a lua
    "OLHA_CIMA": {
        "RightArm": J(1.54, 0.3, -0.36, 44, -10, -30),
        "LeftArm": J(-1.54, 0.3, -0.36, 44, 10, 30),
        "Head": J(0, 1.5, 0, -42, 0, 0),
        "HRP": J(0, 0.08, 0, -16, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.16, 9, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.16, 9, 0, 0),
    },
    # a coroa desce: o corpo se abre para receber
    "RECEBE_COROA": {
        "RightArm": J(1.56, 0.2, 0.32, -20, -12, -52),
        "LeftArm": J(-1.56, 0.2, 0.32, -20, 12, 52),
        "Head": J(0, 1.5, 0, -30, 0, 0),
        "HRP": J(0, 0.14, 0, -12, 0, 0),
        "RightLeg": J(0.5, -1.88, 0.2, 11, 0, 0),
        "LeftLeg": J(-0.5, -1.88, 0.2, 11, 0, 0),
    },
    "CAI_JOELHO": {
        "RightArm": J(1.34, -0.2, -0.56, 42, 14, 20),
        "LeftArm": J(-1.34, -0.2, -0.56, 42, -14, -20),
        "Head": J(0, 1.5, 0, 20, 0, 0),
        "HRP": J(0, -0.78, 0, 20, 0, 0),
        "RightLeg": J(0.5, -1.4, -0.72, -62, 0, 0),
        "LeftLeg": J(-0.5, -1.66, 0.36, 24, 0, 0),
    },
}


# alvo -> (lidera, sequências)
CONJUNTO = {

    "Tiro do Vazio": ("RightArm", {
        # golpe rápido: 1.00 s, impacto a 52% (regras 1 e 2)
        "TIRO": ("golpe rápido", [
            P("ABRE_PALMA", 0.2, "Back", "In", "CARGA"),
            P("APONTA_LADO", 0.18, "Quint", "Out"),
            P("APONTA_LADO", 0.14, "Sine", "InOut", "GOLPE"),
            P("APONTA_LADO", 0.2, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
        # golpe pesado: 1.40 s — o disparo que a origem enterrou
        "DISPARO": ("golpe pesado", [
            P("ABRE_PALMA", 0.26, "Back", "In", "CARGA"),
            P("PUXA_PEITO", 0.42, "Sine", "InOut", None, 0.045, 24),
            P("APONTA_LADO", 0.14, "Quint", "Out", "GOLPE"),
            P("APONTA_LADO", 0.28, "Sine", "InOut"),
            P("IDLE", 0.3, "Quad", "Out"),
        ]),
    }),

    "Chuva de Lava": ("HRP", {
        # CUTSCENE · ULTIMATE · 7.10 s · 66% de preparação (regra 5)
        "LAVA": ("ultimate", [
            P("ERGUE_DUAS", 0.5, "Back", "In", "CAMERA", 0.02, 15),
            P("ERGUE_DUAS", 1.05, "Sine", "InOut", "CARGA", 0.03, 20),
            P("ERGUE_DUAS", 1.3, "Sine", "InOut", None, 0.045, 25),
            P("ERGUE_DUAS", 1.4, "Sine", "InOut", "SEGURA", 0.06, 30),
            P("BAIXA_DUAS", 0.45, "Quint", "In", "DESCE"),
            P("BAIXA_DUAS", 0.3, "Sine", "InOut", "GOLPE"),
            P("BAIXA_DUAS", 0.9, "Sine", "InOut", None, 0.07, 33),
            P("IDLE", 1.2, "Quad", "Out", "FIM"),
        ]),
    }),

    "Parada do Tempo": ("RightArm", {
        # conjuração: 1.20 s, impacto a 52%
        "PARAR": ("conjuração", [
            P("ABRE_PALMA", 0.22, "Back", "In", "CARGA"),
            P("ABRE_PALMA", 0.28, "Sine", "InOut", None, 0.03, 21),
            P("PARA_MAO", 0.12, "Quint", "Out", "GOLPE"),
            P("PARA_MAO", 0.26, "Sine", "InOut"),
            P("IDLE", 0.32, "Quad", "Out"),
        ]),
        # golpe pesado: 1.30 s — o relógio que estoura
        "RELOGIO": ("golpe pesado", [
            P("PUXA_PEITO", 0.24, "Back", "In", "CARGA"),
            P("PUXA_PEITO", 0.44, "Sine", "InOut", None, 0.04, 26),
            P("ABRE_PALMA", 0.13, "Quint", "Out", "GOLPE"),
            P("ABRE_PALMA", 0.22, "Sine", "InOut"),
            P("IDLE", 0.27, "Quad", "Out"),
        ]),
    }),

    "Buraco Negro": ("RightArm", {
        # conjuração pesada: 1.50 s, impacto a 61%
        "ABRIR": ("golpe pesado", [
            P("ABRE_PALMA", 0.26, "Back", "In", "CARGA"),
            P("ERGUE_DUAS", 0.5, "Sine", "InOut", None, 0.04, 23),
            P("PUXA_ALTO", 0.16, "Quint", "Out", "GOLPE"),
            P("PUXA_ALTO", 0.3, "Sine", "InOut", "SEGURA", 0.05, 28),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
        # sustentada: 1.70 s — o colapso
        "COLAPSO": ("sustentada", [
            P("ERGUE_DUAS", 0.24, "Back", "In", "CARGA"),
            P("PUXA_PEITO", 0.16, "Quint", "Out"),
            P("PUXA_PEITO", 0.42, "Sine", "InOut", "SEGURA", 0.04, 26),
            P("PUXA_PEITO", 0.34, "Sine", "InOut", "GOLPE", 0.055, 31),
            P("ABRE_PALMA", 0.2, "Quad", "InOut"),
            P("IDLE", 0.34, "Quad", "Out"),
        ]),
    }),

    "Colar das Trevas": ("RightArm", {
        # golpe rápido: 1.10 s, impacto a 53% — o único de contato do conjunto
        "AGARRAR": ("golpe rápido", [
            P("ABRE_PALMA", 0.2, "Back", "In", "CARGA"),
            P("AGARRA", 0.12, "Quint", "Out"),
            P("AGARRA", 0.26, "Sine", "InOut", "GOLPE", 0.035, 24),
            P("PUXA_ALTO", 0.24, "Sine", "InOut", "SEGURA", 0.04, 28),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),

    "Explosao Lunar": ("Head", {
        # conjuração: 1.30 s — lidera pela CABEÇA, exceção declarada
        "LUA": ("conjuração", [
            P("OLHA_CIMA", 0.24, "Back", "In", "CARGA"),
            P("OLHA_CIMA", 0.42, "Sine", "InOut", None, 0.035, 22),
            P("ABRE_PALMA", 0.14, "Quint", "Out", "GOLPE"),
            P("ABRE_PALMA", 0.22, "Sine", "InOut"),
            P("IDLE", 0.28, "Quad", "Out"),
        ]),
    }),

    "Super Dominus": ("HRP", {
        # CUTSCENE · ULTIMATE · 7.85 s · 68% de preparação (regra 5)
        "COROA": ("ultimate", [
            P("PUXA_PEITO", 0.45, "Back", "In", "CAMERA", 0.02, 16),
            P("RECEBE_COROA", 0.9, "Quad", "InOut", "CARGA", 0.03, 20),
            P("RECEBE_COROA", 1.15, "Sine", "InOut", None, 0.045, 25),
            P("RECEBE_COROA", 1.25, "Sine", "InOut", "SEGURA", 0.06, 30),
            P("RECEBE_COROA", 1.2, "Sine", "InOut", None, 0.075, 35),
            P("CAI_JOELHO", 0.35, "Quint", "In", "DESCE"),
            P("CAI_JOELHO", 0.3, "Sine", "InOut", "GOLPE"),
            P("CAI_JOELHO", 0.95, "Sine", "InOut", None, 0.06, 32),
            P("IDLE", 1.3, "Quad", "Out", "FIM"),
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
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def usadas(sequencias):
    nomes = set()
    for _nat, passos in sequencias.values():
        for p in passos:
            nomes.add(p["pose"])
    return nomes


def escrever(tool, lidera, poses, sequencias):
    L = []
    L.append("-- Poses.lua")
    L.append("-- ModuleScript \"Poses\" — %s  (conjunto NOOB)" % tool)
    L.append("--")
    L.append("-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:")
    L.append("--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·")
    L.append("--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)")
    L.append("--")
    L.append("-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.")
    L.append("--")
    L.append("-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama")
    L.append("-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava")
    L.append("-- a caminhada.")
    L.append("--")
    L.append("-- AUTORAL. A origem anima em `Motor6D.C0` com `Clerp` dentro de um laço de")
    L.append("-- `Swait()` — proibido pela REGRA_ANIMACAO_R6, e ainda por cima o alvo do")
    L.append("-- lerp não é a pose alcançada. Nenhum quadro dela foi copiado; o único")
    L.append("-- empréstimo é o GESTO do `Shot`, que virou APONTA_LADO.")
    L.append("--")
    L.append("-- JUNTA QUE LIDERA: **%s** (regra 6 da gramática)." % lidera)
    L.append("--")
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        segurados = sum(1 for i, p in enumerate(passos)
                        if i > 0 and p["pose"] == passos[i - 1]["pose"])
        L.append("--   %-12s %-16s %.2fs · %d passo(s), %d segurado(s)"
                 % (nome, natureza, total, len(passos), segurados))
    L.append("--")
    L.append("-- O vocabulário é de PALMA PARA CIMA: ABRE_PALMA, ERGUE_DUAS, PUXA_PEITO.")
    L.append("-- O Noob conjura do vazio; nenhuma destas poses soca. O único golpe de")
    L.append("-- contato do conjunto é o `Colar das Trevas`, e ele agarra.")
    L.append("--")
    L.append("-- Gerado por FERRAMENTAS/gerar_poses_noob.py.")
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
    for tool, (lidera, sequencias) in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s" % tool)
            return 1
        poses = {}
        for nome in usadas(sequencias):
            if nome not in BASE:
                print("pose %r não existe (Tool %s)" % (nome, tool))
                return 1
            poses[nome] = BASE[nome]
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias))
        total = sum(sum(p["time"] for p in passos)
                    for _n, (_nat, passos) in sequencias.items())
        print("%-20s %d pose(s) · %d sequência(s) · %.2fs no total"
              % (tool, len(poses), len(sequencias), total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
