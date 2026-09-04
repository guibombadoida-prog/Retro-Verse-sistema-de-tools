#!/usr/bin/env python3
"""
gerar_poses_escudos.py — Retro-Verse / Studios

Dá a cada um dos 7 escudos a SUA animação, cronometrada pela gramática medida
em `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`.

    python3 FERRAMENTAS/gerar_poses_escudos.py

O QUE ESTAVA ERRADO

    Os sete dividiam o MESMO `Poses.lua`, byte a byte — 440 linhas com as poses
    de todos, e cada Tool tocando um pedaço. Pior:

      Bumerangue e Skate  não tocavam sequência NENHUMA. Carregavam as 440
                          linhas e ficavam parados.
      BARREIRA            0.30 s com o impacto em 100%: sem recuo. A gramática
                          (regra 2) diz que sem recuo não há peso.
      DOMINIO             cronometrado como golpe (impacto em 63%), sendo uma
                          TRANSFORMAÇÃO — que pela regra 4 abre em ~2% e
                          sustenta o resto.
      EXECUCAO            ultimate de 2.22 s. A regra 5 mede ultimate em 7–9 s
                          com 64–86% de preparação.
      TODAS as dez        zero passos SEGURADOS. A regra 7 é a mais violada:
                          as animações de referência ficam entre 40% e 90% dos
                          quadros praticamente imóveis, e movimento contínuo lê
                          como flutuação em vez de força.

O QUE ESTE SCRIPT FAZ

    Lê as poses do arquivo compartilhado — as SILHUETAS ficam, são boas e são
    da remasterização — e emite, por Tool, um `Poses.lua` só com o que aquela
    Tool usa, com sequências re-cronometradas.

    Isto é REMASTERIZAÇÃO (ver `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`): mesma
    estrutura, mesma habilidade, mesma silhueta. O que melhora é o tempo.

    A câmera da EXECUCAO é reescalada junto com a sequência. Esticar a animação
    e deixar a câmera no tempo antigo dessincroniza os dois.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
BASE = os.path.join(TOOLS, "Escudo Bloqueador", "Poses.lua")

# ═══════════════════════════════════════════════════════════════
# AS SEQUÊNCIAS, RE-CRONOMETRADAS
# ═══════════════════════════════════════════════════════════════
#
# Cada passo: (pose, time, style, dir, marca, tremor, freq)
# `marca = None` e pose repetida = QUADRO SEGURADO (regra 7).
#
# O arquétipo de cada uma está no comentário, com a proporção alvo.

def P(pose, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=pose, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


SEQUENCIAS = {
    # ── golpe rápido · 0.95 s · impacto em 50% (regra 1 e 2)
    "PROTEGER": [
        P("GUARDA_FIRME", 0.20, "Back", "In", "SAIDA"),
        P("GUARDA_FIRME", 0.28, "Sine", "InOut"),          # SEGURADO
        P("CONTRA_GOLPE", 0.10, "Quint", "Out", "CHEGADA", 0.04, 24),
        P("CORTE_F", 0.09, "Quint", "Out", "REPULSAO"),
        P("ARREMESSO_RECUO", 0.14),
        P("IDLE", 0.14),
    ],

    # ── arremesso simples · 0.90 s · impacto em 52%
    "ARREMESSO": [
        P("ARREMESSO_CARGA", 0.20, "Back", "In", "CARGA"),
        P("ARREMESSO_CARGA", 0.25, "Sine", "InOut"),       # SEGURADO
        P("ARREMESSO_SOLTA", 0.08, "Quint", "Out", "SOLTA"),
        P("ARREMESSO_RECUO", 0.16),
        P("IDLE", 0.21),
    ],

    # ── arremesso carregado · 1.10 s · impacto em 57%
    "ARREMESSO_CARREGADO": [
        P("ARREMESSO_CARGA", 0.24, "Back", "In", "CARGA", 0.035, 26),
        P("ARREMESSO_CARGA", 0.31, "Sine", "InOut", None, 0.035, 26),  # SEGURADO
        P("ARREMESSO_SOLTA", 0.08, "Quint", "Out", "SOLTA"),
        P("ARREMESSO_RECUO", 0.20),
        P("IDLE", 0.27),
    ],

    # ── sacrifício · 0.95 s · impacto em 60%
    "SACRIFICIO": [
        P("SACRIFICIO_CARGA", 0.22, "Back", "In", "CARGA"),
        P("SACRIFICIO_CARGA", 0.25, "Sine", "InOut", None, 0.03, 20),  # SEGURADO
        P("SACRIFICIO_ALTO", 0.10, "Quint", "Out", "VINCULO", 0.03, 20),
        P("GUARDA_FIRME", 0.16),
        P("IDLE", 0.22),
    ],

    # ── barreira · 0.85 s · AGORA TEM RECUO (antes: 0.30 s, impacto em 100%)
    "BARREIRA": [
        P("GUARDA", 0.20, "Back", "In", "CARGA"),
        P("GUARDA", 0.22, "Sine", "InOut"),                # SEGURADO
        P("GUARDA_FIRME", 0.10, "Quint", "Out", "ABRIR"),
        P("GUARDA_FIRME", 0.18, "Sine", "InOut"),          # sustenta a barreira
        P("IDLE", 0.15),
    ],

    # ── SKATE · estado, não golpe · abre em 7% e sustenta (regra 4)
    "SKATE_IMPULSO": [
        P("SKATE", 0.06, "Quint", "Out", "IMPULSO"),
        P("SKATE", 0.60, "Sine", "InOut", "DESLIZA"),      # SEGURADO longo
        P("IDLE", 0.24),
    ],

    # ── invocação · 1.05 s · impacto em 59%
    "CICLONE_INVOCA": [
        P("CICLONE_CARGA", 0.22, "Back", "In", "CARGA"),
        P("CICLONE_CARGA", 0.28, "Sine", "InOut"),         # SEGURADO
        P("INVOCAR", 0.12, "Quint", "Out", "INVOCAR", 0.045, 28),
        P("CICLONE_ABERTO", 0.16, "Quad", "Out", "ABRIR"),
        P("CICLONE_GIRO", 0.27, "Sine", "InOut"),
    ],

    # ── tração · 0.85 s · impacto em 59%
    "CICLONE_PUXA": [
        P("PUXAO_CARGA", 0.18, "Back", "In"),
        P("PUXAO_CARGA", 0.24, "Sine", "InOut"),           # SEGURADO
        P("PUXAO_SOLTA", 0.08, "Quint", "Out", "PUXAR"),
        P("CICLONE_GIRO", 0.35),
    ],

    # ── DOMÍNIO · TRANSFORMAÇÃO · abre em 5% e sustenta 95% (regra 4)
    #    Antes era cronometrado como golpe, com o impacto em 63%.
    "DOMINIO": [
        P("DOMINIO_ABERTO", 0.08, "Quint", "Out", "EXPANDIR"),
        P("DOMINIO_SUSTENTA", 0.60, "Sine", "InOut", "SUSTENTAR", 0.03, 18),
        P("DOMINIO_SUSTENTA", 0.50, "Sine", "InOut"),      # SEGURADO
        P("CICLONE_GIRO", 0.40, "Sine", "InOut"),
    ],

    # ── combo · 1.12 s · primeiro impacto em 41% (regra 3: combo bate cedo)
    "CORTE_COMBO": [
        P("CORTE_A", 0.16, "Back", "In"),
        P("CORTE_A", 0.22, "Sine", "InOut"),               # SEGURADO
        P("CORTE_B", 0.08, "Quint", "Out", "CORTE1"),
        P("CORTE_C", 0.11, "Back", "In"),
        P("CORTE_D", 0.08, "Quint", "Out", "CORTE2"),
        P("CORTE_E", 0.11, "Back", "In"),
        P("CORTE_F", 0.08, "Quint", "Out", "CORTE3"),
        P("IDLE", 0.28),
    ],

    # ── ULTIMATE · 6.24 s · golpe mortal em 78% (regra 5: 64–86%)
    #    Antes: 2.22 s. Os dois segurados longos são o que dá o clímax.
    #    O rabo longo do IDLE é o que traz o golpe mortal para dentro da faixa.
    "EXECUCAO": [
        P("EXEC_POSTURA", 0.60, "Back", "In", "POSTURA", 0.02, 18),
        P("EXEC_POSTURA", 1.80, "Sine", "InOut", None, 0.02, 18),   # SEGURADO
        P("EXEC_AVANCO", 0.35, "Quint", "Out", "TEMPO"),
        P("EXEC_AVANCO", 1.40, "Sine", "InOut"),                    # SEGURADO
        P("EXEC_CORTE1", 0.20, "Quint", "Out", "GRADE", 0.05, 30),
        P("EXEC_CORTE2", 0.12, "Quint", "Out", "CORTE"),
        P("EXEC_CORTE1", 0.11, "Quint", "Out", "CORTE"),
        P("EXEC_CORTE2", 0.11, "Quint", "Out", "CORTE"),
        P("EXEC_CORTE1", 0.10, "Quint", "Out", "CORTE"),
        P("EXEC_CORTE2", 0.10, "Quint", "Out", "CORTE"),
        P("EXEC_FINAL", 0.40, "Back", "Out", "MORTAL"),
        P("IDLE", 0.95, "Quad", "Out", "FIM"),
    ],
}

# Tool -> sequências que ela toca
ESCUDOS = {
    "Escudo Bloqueador": ["PROTEGER"],
    "Escudo Bumerangue": ["ARREMESSO", "ARREMESSO_CARREGADO"],
    "Escudo Cyclone": ["CICLONE_INVOCA", "CICLONE_PUXA", "DOMINIO"],
    "Escudo Partido": ["ARREMESSO_CARREGADO", "CORTE_COMBO", "EXECUCAO"],
    "Escudo Skate": ["SKATE_IMPULSO"],
    "Proteção": ["BARREIRA"],
    "Salvador": ["SACRIFICIO"],
}

# Qual `marca` é o IMPACTO de cada sequência. Adivinhar isso pelo nome do beat
# dá errado: em EXECUCAO o "TEMPO" é preparação, e em SKATE_IMPULSO o "DESLIZA"
# é sustentação. O golpe é declarado, não inferido.
IMPACTO = {
    "PROTEGER": "CHEGADA", "ARREMESSO": "SOLTA",
    "ARREMESSO_CARREGADO": "SOLTA", "SACRIFICIO": "VINCULO",
    "BARREIRA": "ABRIR", "SKATE_IMPULSO": "IMPULSO",
    "CICLONE_INVOCA": "INVOCAR", "CICLONE_PUXA": "PUXAR",
    "DOMINIO": "EXPANDIR", "CORTE_COMBO": "CORTE1", "EXECUCAO": "MORTAL",
}

ARQUETIPO = {
    "PROTEGER": "golpe rápido", "ARREMESSO": "golpe rápido",
    "ARREMESSO_CARREGADO": "golpe rápido carregado",
    "SACRIFICIO": "golpe rápido", "BARREIRA": "defensiva",
    "SKATE_IMPULSO": "estado (2:98)", "CICLONE_INVOCA": "invocação",
    "CICLONE_PUXA": "golpe rápido", "DOMINIO": "transformação (2:98)",
    "CORTE_COMBO": "combo (35:65)", "EXECUCAO": "ultimate (64–86%)",
}

RE_POSE = re.compile(r"^P\.(\w+) = \{[^\n]*\n((?:\t[^\n]*\n)+)\}", re.M)
RE_CAM = re.compile(r"^P\.CAMERA_EXECUCAO = \{[^\n]*\n((?:\t[^\n]*\n)+)\}", re.M)


def duracao(passos):
    return sum(p["time"] for p in passos)


def impacto(nome, passos):
    """Quando cai o beat de impacto declarado em IMPACTO."""
    alvo = IMPACTO.get(nome)
    acumulado = 0.0
    for passo in passos:
        acumulado = acumulado + passo["time"]
        if alvo and passo["marca"] == alvo:
            return acumulado
    return duracao(passos)


def segurados(passos):
    """Passos que repetem a pose anterior — os quadros imóveis da regra 7."""
    total = 0
    for i in range(1, len(passos)):
        if passos[i]["pose"] == passos[i - 1]["pose"]:
            total = total + 1
    return total


def escrever_passo(passo):
    campos = ['pose = "%s"' % passo["pose"], "time = %g" % passo["time"],
              'style = "%s"' % passo["style"], 'dir = "%s"' % passo["dir"]]
    if passo["tremor"]:
        campos.append("tremor = %g" % passo["tremor"])
        campos.append("freq = %d" % (passo["freq"] or 20))
    if passo["marca"]:
        campos.append('marca = "%s"' % passo["marca"])
    return "\t\t{ " + ", ".join(campos) + " },"


def reescalar_camera(corpo, fator):
    """Estica a trilha de câmera junto com a sequência, para não dessincronizar."""
    def trocar(m):
        return "{ t = %.2f," % (float(m.group(1)) * fator)
    return re.sub(r"\{ t = ([0-9.]+),", trocar, corpo)


CABECALHO = '''-- Poses.lua
-- ModuleScript "Poses" — %(titulo)s
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama ReleaseLegs
-- ao fim de toda sequência. Perna soldada permanentemente trava a caminhada.
--
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, os sete escudos dividiam o mesmo
-- arquivo de 440 linhas — este traz só o que esta Tool usa.
--
-- As SILHUETAS são as da remasterização e não mudaram: é a mesma habilidade,
-- do mesmo modelo. O que mudou foi o TEMPO, re-cronometrado pela gramática
-- medida no pack de referência (ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md).
--
-- O que a gramática impôs aqui:
%(auditoria)s--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}

'''


def main():
    if not os.path.exists(BASE):
        print("base de poses não encontrada: %s" % BASE)
        return 1
    texto = open(BASE, encoding="utf-8").read()

    poses = dict((m.group(1), m.group(0)) for m in RE_POSE.finditer(texto))
    if not poses:
        print("nenhuma pose reconhecida em %s" % BASE)
        return 1
    camera = RE_CAM.search(texto)

    # a EXECUCAO esticou: a câmera estica junto, pelo mesmo fator
    fator = duracao(SEQUENCIAS["EXECUCAO"]) / 2.22

    print("ANIMAÇÃO PERSONALIZADA — 7 escudos")
    print("")
    print("  %-22s %-24s %7s %8s %s"
          % ("SEQUÊNCIA", "arquétipo", "duração", "impacto", "segurados"))
    for nome, passos in sorted(SEQUENCIAS.items()):
        d = duracao(passos)
        print("  %-22s %-24s %6.2fs %7d%% %d"
              % (nome, ARQUETIPO[nome], d, round(impacto(nome, passos) / d * 100),
                 segurados(passos)))
    print("")

    for tool, quais in sorted(ESCUDOS.items()):
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("  PAREI: falta Tools/%s" % tool)
            return 1

        usadas = []
        for seq in quais:
            for passo in SEQUENCIAS[seq]:
                if passo["pose"] not in usadas:
                    usadas.append(passo["pose"])
        faltando = [p for p in usadas if p not in poses]
        if faltando:
            print("  PAREI: %s pede pose(s) que não existem: %s"
                  % (tool, ", ".join(faltando)))
            return 1

        auditoria = []
        for seq in quais:
            passos = SEQUENCIAS[seq]
            d = duracao(passos)
            auditoria.append(
                "--   %-20s %-22s %.2fs · impacto %d%% · %d segurado(s)\n"
                % (seq, ARQUETIPO[seq], d,
                   round(impacto(seq, passos) / d * 100), segurados(passos)))

        corpo = [CABECALHO % {"titulo": tool, "auditoria": "".join(auditoria)}]
        for nome in usadas:
            corpo.append(poses[nome])
            corpo.append("")

        corpo.append("P.SEQUENCIAS = {")
        corpo.append("")
        for seq in quais:
            corpo.append("\t-- %s · %.2fs · %d passo(s), %d segurado(s)"
                         % (ARQUETIPO[seq], duracao(SEQUENCIAS[seq]),
                            len(SEQUENCIAS[seq]), segurados(SEQUENCIAS[seq])))
            corpo.append("\t%s = {" % seq)
            for passo in SEQUENCIAS[seq]:
                corpo.append(escrever_passo(passo))
            corpo.append("\t},")
            corpo.append("")
        corpo.append("}")
        corpo.append("")

        if "EXECUCAO" in quais and camera:
            corpo.append("--" + "═" * 62)
            corpo.append("-- CÂMERA DA CUTSCENE — reescalada por %.2fx junto com a" % fator)
            corpo.append("-- sequência. Esticar a animação e deixar a câmera no tempo")
            corpo.append("-- antigo dessincroniza os dois.")
            corpo.append("--" + "═" * 62)
            corpo.append("")
            corpo.append("P.CAMERA_EXECUCAO = {")
            corpo.append(reescalar_camera(camera.group(1), fator).rstrip())
            corpo.append("}")
            corpo.append("")

        corpo.append("return P")
        corpo.append("")

        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write("\n".join(corpo))
        print("  %-20s %d pose(s), %d sequência(s): %s"
              % (tool, len(usadas), len(quais), ", ".join(quais)))

    print("")
    print("Câmera da EXECUCAO reescalada por %.2fx." % fator)
    return 0


if __name__ == "__main__":
    sys.exit(main())
