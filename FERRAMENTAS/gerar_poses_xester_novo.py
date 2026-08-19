#!/usr/bin/env python3
"""
gerar_poses_xester_novo.py — Retro-Verse / Studios

Escreve o `Poses.lua` das 14 Tools do Xester — Forma 1 e Forma 2.
QUATRO sequências cada, 56 no conjunto.

    python3 FERRAMENTAS/gerar_poses_xester_novo.py

RECRIADAS DO ZERO

    As 14 já existiam, com M1 mais uma Extra e no pipeline antigo. Isto aqui é
    reconstrução: quatro habilidades por Tool, e a pose de cada uma escrita
    junto com ela.

    O `extrair_poses_xester.py` continua no repositório e continua sendo a
    fonte da pose de ORIGEM — ele lê os laços `Weld.C0:lerp(alvo, 0.5)` do
    `xesterv2`, que têm alpha CONSTANTE e por isso precisam ser simulados, não
    lidos. Este gerador não o substitui: ele escreve as sequências das TRÊS
    EXTRAS novas, que não existem em origem nenhuma.

DUAS FORMAS, DOIS VOCABULÁRIOS

    Forma 1 é o BARALHO: o gesto é de mão, carta e leque. O braço direito
    lidera quase tudo, e o corpo quase não sai do lugar — regra 7 levada a
    sério, porque mágico de salão não se debate.

    Forma 2 é O DESPERTAR: cajado, machado e invocação. O corpo entra inteiro,
    o HRP lidera o que é peso, e as pausas são mais longas.
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
    "IDLE": {
        "RightArm": J(1.48, 0.05, -0.22, 18, 4, 4),
        "LeftArm": J(-1.48, 0.05, -0.22, 18, -4, -4),
        "Head": J(0, 1.5, 0, -3, 0, 0),
        "HRP": J(0, 0, 0, 0, -6, 0),
    },

    # ── FORMA 1 — o baralho. Gesto de mão, corpo parado.
    "LEQUE": {
        "RightArm": J(1.44, 0.34, -0.62, 96, -22, -18),
        "LeftArm": J(-1.4, 0.28, -0.5, 82, 20, 22),
        "Head": J(0, 1.5, 0, -8, 6, 0),
        "HRP": J(0, 0.02, 0, -4, -6, 0),
    },
    "ATIRA_CARTA": {
        "RightArm": J(1.52, 0.3, -1.16, 92, -12, -6),
        "LeftArm": J(-1.42, 0.14, -0.4, 44, 16, 18),
        "Head": J(0, 1.5, 0, -2, -14, 0),
        "HRP": J(0, 0, 0, 2, 18, 0),
    },
    "CARTOLA": {
        "RightArm": J(1.4, 0.72, -0.24, 146, -14, -22),
        "LeftArm": J(-1.46, 0.08, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -18, 8, 0),
        "HRP": J(0, 0.05, 0, -10, -8, 0),
    },
    "SOME": {
        "RightArm": J(1.3, 0.2, -0.2, 60, -30, -44),
        "LeftArm": J(-1.3, 0.2, -0.2, 60, 30, 44),
        "Head": J(0, 1.5, 0, 10, 0, 0),
        "HRP": J(0, -0.2, 0, 14, 0, 0),
    },
    "VENIA": {
        "RightArm": J(1.36, 0.12, -0.42, 58, -18, -30),
        "LeftArm": J(-1.34, -0.04, 0.16, 10, 14, 42),
        "Head": J(0, 1.5, 0, 26, 0, 0),
        "HRP": J(0, -0.26, 0, 24, 0, 0),
    },
    "PALMA_ABERTA": {
        "RightArm": J(1.5, 0.32, -1.08, 88, -16, -8),
        "LeftArm": J(-1.5, 0.32, -1.08, 88, 16, 8),
        "Head": J(0, 1.5, 0, -4, 0, 0),
        "HRP": J(0, 0.02, 0, -2, 0, 0),
    },

    # ── FORMA 2 — o despertar. Cajado, machado, corpo inteiro.
    "CAJADO_ERGUE": {
        "RightArm": J(1.44, 0.84, -0.04, 168, -8, -14),
        "LeftArm": J(-1.46, 0.1, -0.28, 24, 8, 10),
        "Head": J(0, 1.5, 0, -34, 0, 0),
        "HRP": J(0, 0.1, 0, -16, 0, 0),
    },
    "CAJADO_APONTA": {
        "RightArm": J(1.52, 0.36, -1.18, 90, -6, -4),
        "LeftArm": J(-1.44, 0.08, -0.3, 26, 8, 10),
        "Head": J(0, 1.5, 0, -5, -8, 0),
        "HRP": J(0, 0.02, 0, -3, 12, 0),
        "RightLeg": J(0.5, -1.88, -0.22, -10, 0, 0),
    },
    "CAJADO_CHAO": {
        "RightArm": J(1.42, -0.34, -0.4, 26, 10, 22),
        "LeftArm": J(-1.4, -0.2, -0.44, 34, -10, -18),
        "Head": J(0, 1.5, 0, 24, 0, 0),
        "HRP": J(0, -0.44, 0, 26, 0, 0),
        "RightLeg": J(0.5, -1.6, -0.52, -36, 0, 0),
        "LeftLeg": J(-0.5, -1.66, -0.44, -30, 0, 0),
    },
    "MACHADO_ALTO": {
        "RightArm": J(1.4, 0.8, -0.1, 172, -10, -18),
        "LeftArm": J(-1.4, 0.8, -0.1, 172, 10, 18),
        "Head": J(0, 1.5, 0, -32, 0, 0),
        "HRP": J(0, 0.14, 0, -19, 0, 0),
        "RightLeg": J(0.5, -1.9, 0.12, 8, 0, 0),
        "LeftLeg": J(-0.5, -1.9, 0.12, 8, 0, 0),
    },
    "MACHADO_DESCE": {
        "RightArm": J(1.44, -0.3, -0.82, 20, -8, -4),
        "LeftArm": J(-1.44, -0.3, -0.82, 20, 8, 4),
        "Head": J(0, 1.5, 0, 28, 0, 0),
        "HRP": J(0, -0.42, 0, 32, 0, 0),
        "RightLeg": J(0.5, -1.58, -0.54, -38, 0, 0),
        "LeftLeg": J(-0.5, -1.58, -0.54, -38, 0, 0),
    },
    "GIRO": {
        "RightArm": J(1.5, 0.3, -0.94, 80, -44, -16),
        "LeftArm": J(-1.5, 0.3, -0.94, 80, 44, 16),
        "Head": J(0, 1.5, 0, 0, 40, 0),
        "HRP": J(0, -0.06, 0, 5, -52, 0),
    },
    "CONVOCA": {
        "RightArm": J(1.38, 0.62, -0.42, 128, -18, -26),
        "LeftArm": J(-1.38, 0.62, -0.42, 128, 18, 26),
        "Head": J(0, 1.5, 0, -24, 0, 0),
        "HRP": J(0, 0.08, 0, -13, 0, 0),
    },
    "RECOLHE": {
        "RightArm": J(1.32, 0.3, -0.36, 86, -34, -40),
        "LeftArm": J(-1.32, 0.3, -0.36, 86, 34, 40),
        "Head": J(0, 1.5, 0, 12, 0, 0),
        "HRP": J(0, -0.12, 0, 12, 0, 0),
    },
}


def S(nome, natureza, passos):
    return (nome, (natureza, passos))


def quatro(m1, r, t, y):
    return dict([m1, r, t, y])


# ── moldes de ritmo, para não repetir a mesma lista catorze vezes ──────────

def rapido(nome, a, b, sfx=None):
    """Golpe rápido: 0.7–0.9 s, impacto na metade (regras 1 e 2)."""
    return S(nome, "golpe rápido", [
        P(a, 0.20, "Back", "In", "CARGA"),
        P(a, 0.14, "Sine", "InOut"),
        P(b, 0.10, "Quint", "Out", "GOLPE"),
        P(b, 0.15, "Sine", "InOut"),
        P("IDLE", 0.24, "Quad", "Out", "FIM"),
    ])


def conjura(nome, a, b, tremor=0.03, freq=22):
    return S(nome, "conjuração", [
        P(a, 0.26, "Back", "In", "CARGA"),
        P(a, 0.40, "Sine", "InOut", None, tremor, freq),
        P(b, 0.15, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.30, "Quad", "Out", "FIM"),
    ])


def pesado(nome, a, b, tremor=0.045, freq=26):
    return S(nome, "golpe pesado", [
        P(a, 0.30, "Back", "In", "CARGA"),
        P(a, 0.54, "Sine", "InOut", "SEGURA", tremor, freq),
        P(b, 0.17, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.33, "Quad", "Out", "FIM"),
    ])


def sustentada(nome, a, tremor=0.03, freq=19):
    return S(nome, "sustentada", [
        P(a, 0.30, "Back", "In", "CARGA"),
        P(a, 0.70, "Sine", "InOut", "SEGURA", tremor, freq),
        P(a, 0.18, "Quint", "Out", "GOLPE"),
        P("IDLE", 0.34, "Quad", "Out", "FIM"),
    ])


CONJUNTO = {
    # ═════ FORMA 1 — o baralho ═════
    "Xester Ato de Desaparecer": ("RightArm", quatro(
        conjura("SUMIR", "SOME", "SOME"),
        conjura("BARALHAR", "CARTOLA", "PALMA_ABERTA"),
        conjura("BLEFE", "LEQUE", "ATIRA_CARTA"),
        pesado("FINAL", "VENIA", "PALMA_ABERTA"))),

    "Xester Full House": ("RightArm", quatro(
        rapido("LEQUE", "LEQUE", "ATIRA_CARTA"),
        conjura("SEQUENCIA", "LEQUE", "ATIRA_CARTA"),
        rapido("TRINCA", "LEQUE", "ATIRA_CARTA"),
        pesado("MAO_FECHADA", "RECOLHE", "PALMA_ABERTA"))),

    "Xester Cardnado": ("RightArm", quatro(
        pesado("CARDNADO", "CARTOLA", "PALMA_ABERTA"),
        conjura("SOPRO", "PALMA_ABERTA", "ATIRA_CARTA"),
        sustentada("OLHO", "LEQUE"),
        pesado("DISPERSAR", "CARTOLA", "PALMA_ABERTA"))),

    "Xester Teleporte": ("RightArm", quatro(
        conjura("TELEPORTE", "SOME", "SOME", 0.02, 24),
        conjura("MARCAR", "CARTOLA", "PALMA_ABERTA"),
        conjura("VOLTAR", "SOME", "SOME", 0.02, 26),
        pesado("CORRENTE", "SOME", "ATIRA_CARTA"))),

    "Xester Carta Colossal": ("RightArm", quatro(
        pesado("COLOSSAL", "CARTOLA", "PALMA_ABERTA", 0.055, 28),
        conjura("MURALHA", "PALMA_ABERTA", "PALMA_ABERTA"),
        rapido("GUILHOTINA", "LEQUE", "ATIRA_CARTA"),
        pesado("BARALHO", "CARTOLA", "PALMA_ABERTA", 0.05, 27))),

    "Xester Buraco Negro": ("RightArm", quatro(
        pesado("BURACO", "PALMA_ABERTA", "PALMA_ABERTA", 0.05, 25),
        pesado("COLAPSO", "RECOLHE", "PALMA_ABERTA"),
        sustentada("HORIZONTE", "PALMA_ABERTA"),
        pesado("EJECAO", "RECOLHE", "PALMA_ABERTA"))),

    "Xester Escudo de Cartas": ("RightArm", quatro(
        conjura("ESCUDO", "PALMA_ABERTA", "PALMA_ABERTA"),
        rapido("REBATER", "LEQUE", "PALMA_ABERTA"),
        pesado("ESTILHACAR", "RECOLHE", "PALMA_ABERTA"),
        sustentada("BLINDADO", "PALMA_ABERTA"))),

    # ═════ FORMA 2 — o despertar ═════
    "Xester Carta Ceifeira": ("RightArm", quatro(
        rapido("CEIFEIRA", "CAJADO_APONTA", "GIRO"),
        pesado("CEIFAR", "GIRO", "GIRO"),
        conjura("MARCA", "CAJADO_APONTA", "CAJADO_APONTA"),
        pesado("COLHEITA", "CAJADO_ERGUE", "CAJADO_CHAO", 0.06, 29))),

    "Xester Esfera do Fim": ("RightArm", quatro(
        pesado("ESFERA", "CONVOCA", "CAJADO_APONTA", 0.05, 26),
        conjura("ORBITA", "CONVOCA", "CONVOCA"),
        sustentada("COMPRESSAO", "RECOLHE"),
        pesado("FIM", "CAJADO_ERGUE", "CAJADO_CHAO", 0.07, 31))),

    "Xester Baralho Espectral": ("RightArm", quatro(
        conjura("ESPECTRAL", "CONVOCA", "CAJADO_APONTA"),
        conjura("NAIPE", "CONVOCA", "CAJADO_APONTA"),
        sustentada("ESPELHO", "PALMA_ABERTA"),
        pesado("COMPLETO", "CAJADO_ERGUE", "CONVOCA", 0.055, 28))),

    "Xester Invocacao": ("RightArm", quatro(
        conjura("INVOCAR", "CONVOCA", "CAJADO_CHAO"),
        conjura("COMANDAR", "CAJADO_APONTA", "CAJADO_APONTA"),
        pesado("LEGIAO", "CONVOCA", "CAJADO_CHAO", 0.05, 25),
        pesado("DISPENSAR", "CAJADO_ERGUE", "CAJADO_CHAO"))),

    "Xester Furia do Machado": ("HRP", quatro(
        rapido("MACHADO", "MACHADO_ALTO", "MACHADO_DESCE"),
        conjura("ARREMESSO", "MACHADO_ALTO", "CAJADO_APONTA"),
        pesado("REDEMOINHO", "GIRO", "GIRO", 0.055, 27),
        pesado("DECAPITAR", "MACHADO_ALTO", "MACHADO_DESCE", 0.065, 30))),

    "Xester Procissao de Cartas": ("HRP", quatro(
        pesado("PROCISSAO", "CONVOCA", "CAJADO_APONTA"),
        conjura("FORMACAO", "PALMA_ABERTA", "PALMA_ABERTA"),
        sustentada("MARCHA", "CAJADO_APONTA"),
        pesado("DISSOLVER", "CAJADO_ERGUE", "CAJADO_CHAO"))),

    "Xester Portal do Cajado": ("RightArm", quatro(
        pesado("PORTAL", "CAJADO_ERGUE", "CAJADO_APONTA", 0.05, 24),
        conjura("SAIDA", "CAJADO_APONTA", "CAJADO_APONTA"),
        conjura("ATRAVESSAR", "SOME", "SOME", 0.02, 25),
        pesado("FECHAR", "RECOLHE", "CAJADO_CHAO"))),
}


def rad(g):
    return "math.rad(%s)" % g


def linha_junta(nome, j):
    x, y, z, rx, ry, rz = j
    if rx == 0 and ry == 0 and rz == 0:
        return "\t%s = CFrame.new(%s, %s, %s)," % (nome, x, y, z)
    return ("\t%s = CFrame.new(%s, %s, %s) * CFrame.Angles(%s, %s, %s),"
            % (nome, x, y, z, rad(rx), rad(ry), rad(rz)))


def escrever(tool, lidera, poses, sequencias, forma):
    L = ["-- Poses.lua",
         "-- ModuleScript \"Poses\" — %s  (Xester %s)" % (tool, forma),
         "--",
         "-- RECRIADA DO ZERO. A Tool já existia com M1 mais uma Extra; agora",
         "-- são QUATRO habilidades, e cada uma tem a própria sequência.",
         "--",
         "-- %s" % ("Forma 1 é o BARALHO: gesto de mão, carta e leque, corpo"
                    " quase parado" if forma == "Forma 1" else
                    "Forma 2 é O DESPERTAR: cajado, machado e invocação, corpo"
                    " inteiro"),
         "-- — regra 7, e mágico de salão não se debate.",
         "--",
         "-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.",
         "-- JUNTA QUE LIDERA: **%s** (regra 6)." % lidera, "--"]
    for nome, (natureza, passos) in sequencias.items():
        total = sum(p["time"] for p in passos)
        L.append("--   %-14s %-16s %.2fs · %d passo(s)"
                 % (nome, natureza, total, len(passos)))
    L += ["--", "-- Gerado por FERRAMENTAS/gerar_poses_xester_novo.py.", "",
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


FORMA1 = ("Xester Ato de Desaparecer", "Xester Full House", "Xester Cardnado",
          "Xester Teleporte", "Xester Carta Colossal", "Xester Buraco Negro",
          "Xester Escudo de Cartas")


def main():
    total = 0
    for tool, (lidera, sequencias) in CONJUNTO.items():
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
        forma = "Forma 1" if tool in FORMA1 else "Forma 2"
        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write(escrever(tool, lidera, poses, sequencias, forma))
        total = total + len(sequencias)
        print("%-30s %-8s %d pose(s) · %d sequência(s)"
              % (tool, forma, len(poses), len(sequencias)))
    print("")
    print("%d sequências no conjunto" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
