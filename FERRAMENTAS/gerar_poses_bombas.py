#!/usr/bin/env python3
"""
gerar_poses_bombas.py — Retro-Verse / Studios

Dá a cada uma das 6 bombas a SUA animação, cronometrada pela gramática medida
em `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`.

    python3 FERRAMENTAS/gerar_poses_bombas.py

O QUE ESTAVA ERRADO — o mesmo dos Escudos

    As seis dividiam o MESMO `Poses.lua` (md5 cb903f62), com três sequências:

      ARREMESSO  0.56 s   ABAIXO da faixa de golpe rápido (0.8–1.2 s)
      CHAMADO    0.86 s   dentro da faixa, mas sem quadro segurado
      SOLTAR     0.40 s   menos da metade do piso

    E as três com ZERO passos segurados, que é a regra 7 — a mais violada e a
    que mais muda a leitura: movimento contínuo lê como flutuação, movimento em
    rajada lê como força.

O NOME DA SEQUÊNCIA NÃO MUDA

    Cada Tool recebe um `Poses.lua` próprio, mas as sequências mantêm os nomes
    (`ARREMESSO`, `CHAMADO`, `SOLTAR`) — assim nenhum Server precisa ser tocado.
    O que muda é o TEMPO, por Tool.

POR QUE A NUCLEAR NÃO TEM 7 SEGUNDOS

    A regra 5 mede ultimate em 7–9 s, mas mede em `DEATH_COUNTER`, `TABLE_FLIP`
    e `SERIOUS_PUNCH` — as três com CÂMERA. A própria regra diz que ultimate
    longo pede enquadramento, senão vira tempo morto.

    A Nuclear não tem cutscene. Então ela não é ultimate de cutscene: é
    conjuração pesada, e sai a 1.60 s com dois segurados. Isto é escolha
    declarada, não descuido — está aqui para quem discordar saber onde mexer.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
BASE = os.path.join(TOOLS, "Bomba Nuclear", "Poses.lua")


def P(pose, t, estilo="Quad", direcao="Out", marca=None, tremor=None, freq=None):
    return dict(pose=pose, time=t, style=estilo, dir=direcao, marca=marca,
                tremor=tremor, freq=freq)


# Tool -> { sequência: (arquétipo, marca de impacto, passos) }
BOMBAS = {
    "Multiplas Bombas": {
        "ARREMESSO": ("golpe rápido", "SOLTA", [
            P("ARREMESSO_CARGA", 0.18, "Back", "In", "CARGA"),
            P("ARREMESSO_CARGA", 0.24, "Sine", "InOut"),          # SEGURADO
            P("ARREMESSO_SOLTA", 0.08, "Quint", "Out", "SOLTA"),
            P("ARREMESSO_RECUO", 0.16),
            P("IDLE", 0.24),
        ]),
    },
    "Bomba Basquete": {
        # quica: o arremesso é de baixo, mais solto, com recuo maior
        "ARREMESSO": ("golpe rápido", "SOLTA", [
            P("ARREMESSO_CARGA", 0.16, "Back", "In", "CARGA"),
            P("ARREMESSO_CARGA", 0.20, "Sine", "InOut"),          # SEGURADO
            P("ARREMESSO_SOLTA", 0.07, "Quint", "Out", "SOLTA"),
            P("ARREMESSO_RECUO", 0.19),
            P("IDLE", 0.28),
        ]),
    },
    "Bomba Gelada": {
        # gelo: carga mais longa e recuo curto — o gesto trava no fim
        "ARREMESSO": ("golpe rápido", "SOLTA", [
            P("ARREMESSO_CARGA", 0.22, "Back", "In", "CARGA"),
            P("ARREMESSO_CARGA", 0.28, "Sine", "InOut"),          # SEGURADO
            P("ARREMESSO_SOLTA", 0.08, "Quint", "Out", "SOLTA"),
            P("ARREMESSO_RECUO", 0.14),
            P("IDLE", 0.20),
        ]),
    },
    "Bomba Nuclear": {
        # conjuração pesada, não ultimate de cutscene (ver cabeçalho)
        "CHAMADO": ("conjuração pesada", "SOLTA", [
            P("CHAMA_ERGUE", 0.40, "Back", "In", "ERGUE", 0.03, 20),
            P("CHAMA_ERGUE", 0.60, "Sine", "InOut", None, 0.04, 24),   # SEGURADO
            P("CHAMA_BAIXA", 0.12, "Quint", "Out", "SOLTA"),
            P("CHAMA_BAIXA", 0.20, "Sine", "InOut"),                   # SEGURADO
            P("IDLE", 0.28),
        ]),
    },
    "Bomba Meteorica": {
        "CHAMADO": ("conjuração", "SOLTA", [
            P("CHAMA_ERGUE", 0.34, "Back", "In", "ERGUE", 0.03, 20),
            P("CHAMA_ERGUE", 0.42, "Sine", "InOut", None, 0.03, 20),   # SEGURADO
            P("CHAMA_BAIXA", 0.12, "Quint", "Out", "SOLTA"),
            P("IDLE", 0.32),
        ]),
    },
    "Bomba Doida": {
        # soltar dois NPCs: gesto curto, mas com o segurado que dá intenção
        "SOLTAR": ("golpe rápido", "SOLTA", [
            P("SOLTAR", 0.16, "Back", "In"),
            P("SOLTAR", 0.26, "Sine", "InOut", None, 0.025, 22),        # SEGURADO
            P("SOLTAR", 0.08, "Quint", "Out", "SOLTA"),
            P("IDLE", 0.35),
        ]),
    },
}

RE_POSE = re.compile(r"^P\.(\w+) = \{[^\n]*\n((?:\t[^\n]*\n)+)\}", re.M)


def duracao(passos):
    return sum(p["time"] for p in passos)


def impacto(marca, passos):
    acumulado = 0.0
    for passo in passos:
        acumulado = acumulado + passo["time"]
        if passo["marca"] == marca:
            return acumulado
    return duracao(passos)


def segurados(passos):
    return sum(1 for i in range(1, len(passos))
               if passos[i]["pose"] == passos[i - 1]["pose"])


def escrever_passo(passo):
    campos = ['pose = "%s"' % passo["pose"], "time = %g" % passo["time"],
              'style = "%s"' % passo["style"], 'dir = "%s"' % passo["dir"]]
    if passo["tremor"]:
        campos.append("tremor = %g" % passo["tremor"])
        campos.append("freq = %d" % (passo["freq"] or 20))
    if passo["marca"]:
        campos.append('marca = "%s"' % passo["marca"])
    return "\t\t{ " + ", ".join(campos) + " },"


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
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, as seis bombas dividiam o mesmo
-- arquivo — este traz só o que esta Tool usa, com o tempo dela.
--
-- As SILHUETAS não mudaram: é a mesma habilidade do mesmo modelo. O que mudou
-- foi o TEMPO, pela gramática medida em ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md.
--
%(auditoria)s--
-- Gerado por FERRAMENTAS/gerar_poses_bombas.py.

local P = {}

'''


def main():
    if not os.path.exists(BASE):
        print("base de poses não encontrada: %s" % BASE)
        return 1
    poses = dict((m.group(1), m.group(0))
                 for m in RE_POSE.finditer(open(BASE, encoding="utf-8").read()))
    if not poses:
        print("nenhuma pose reconhecida em %s" % BASE)
        return 1

    print("ANIMAÇÃO PERSONALIZADA — 6 bombas")
    print("")
    print("  %-18s %-12s %-20s %7s %8s %s"
          % ("TOOL", "SEQUÊNCIA", "arquétipo", "duração", "impacto", "segurados"))

    for tool in sorted(BOMBAS):
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("  PAREI: falta Tools/%s" % tool)
            return 1

        usadas, auditoria = [], []
        for seq, (arquetipo, marca, passos) in BOMBAS[tool].items():
            for passo in passos:
                if passo["pose"] not in usadas:
                    usadas.append(passo["pose"])
            d = duracao(passos)
            auditoria.append(
                "--   %-11s %-20s %.2fs · impacto %d%% · %d segurado(s)\n"
                % (seq, arquetipo, d, round(impacto(marca, passos) / d * 100),
                   segurados(passos)))
            print("  %-18s %-12s %-20s %6.2fs %7d%% %d"
                  % (tool, seq, arquetipo, d,
                     round(impacto(marca, passos) / d * 100), segurados(passos)))

        faltando = [p for p in usadas if p not in poses]
        if faltando:
            print("  PAREI: %s pede pose(s) inexistente(s): %s"
                  % (tool, ", ".join(faltando)))
            return 1

        corpo = [CABECALHO % {"titulo": tool, "auditoria": "".join(auditoria)}]
        for nome in usadas:
            corpo.append(poses[nome])
            corpo.append("")

        corpo.append("P.SEQUENCIAS = {")
        corpo.append("")
        for seq, (arquetipo, _marca, passos) in BOMBAS[tool].items():
            corpo.append("\t-- %s · %.2fs · %d passo(s), %d segurado(s)"
                         % (arquetipo, duracao(passos), len(passos),
                            segurados(passos)))
            corpo.append("\t%s = {" % seq)
            for passo in passos:
                corpo.append(escrever_passo(passo))
            corpo.append("\t},")
            corpo.append("")
        corpo.append("}")
        corpo.append("")
        corpo.append("return P")
        corpo.append("")

        with open(os.path.join(pasta, "Poses.lua"), "w", encoding="utf-8") as f:
            f.write("\n".join(corpo))

    print("")
    print("%d Tool(s) com Poses próprio." % len(BOMBAS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
