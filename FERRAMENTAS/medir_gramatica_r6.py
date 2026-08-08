#!/usr/bin/env python3
"""
medir_gramatica_r6.py — Retro-Verse / Studios

Mede a LÓGICA DE CONSTRUÇÃO das animações de referência e refaz a tabela do
`GRAMATICA_R6.md`.

    python3 FERRAMENTAS/medir_gramatica_r6.py

POR QUE MEDIR EM VEZ DE COPIAR

    O pack do Saitama tem 2417 keyframes. Copiá-los dá uma animação que já
    existe; medi-los dá a REGRA para autorar animações que ainda não existem.

    O que se mede aqui:
      · onde cai o quadro de impacto (maior velocidade angular somada)
      · a proporção antecipação : recuo
      · qual junta CONDUZ o movimento (maior deslocamento acumulado)
      · quantos quadros ficam praticamente parados
      · na trilha de câmera: quanto tempo parada, e quantos cortes

    A dobra de ângulo é tratada: -179° -> +179° é 2° de movimento, não 358°.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTE = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Saitama_Animacoes_Referencia",
                     "R6_CFRAME", "SaitamaAnimacoes_Originais_V1.lua")

JUNTAS = ("HRP", "RightArm", "LeftArm", "Head", "RightLeg", "LeftLeg")

RE_SEQ = re.compile(r"^\t(\w+) = \{$", re.M)
RE_JUNTA = re.compile(
    r"(\w+) = CFrame\.new\([-0-9., ]*\)"
    r"(?:\s*\*\s*CFrame\.Angles\(math\.rad\((-?[0-9.]+)\), "
    r"math\.rad\((-?[0-9.]+)\), math\.rad\((-?[0-9.]+)\)\))?")
RE_CAM = re.compile(
    r"\{ t = ([0-9.]+), cf = CFrame\.new\((-?[0-9.]+), (-?[0-9.]+), (-?[0-9.]+)\)")


def dobrar(graus):
    """-179 -> +179 é 2° de movimento, não 358. Sem isto o pico é lixo."""
    while graus > 180:
        graus = graus - 360
    while graus < -180:
        graus = graus + 360
    return graus


def keyframes(bloco):
    saida = []
    for pedaco in re.split(r"\{ t = ", bloco)[1:]:
        tempo = float(pedaco.split(",")[0])
        corpo = pedaco[:pedaco.find("},")] if "}," in pedaco else pedaco
        juntas = {}
        for nome, a, b, c in RE_JUNTA.findall(corpo):
            if nome in JUNTAS:
                juntas[nome] = (float(a or 0), float(b or 0), float(c or 0))
        saida.append((tempo, juntas))
    return saida


def medir(nome, kfs):
    if len(kfs) < 5:
        return None
    duracao = kfs[-1][0]
    if duracao <= 0:
        return None

    velocidades, acumulado = [], {}
    for k in range(1, len(kfs)):
        t0, j0 = kfs[k - 1]
        t1, j1 = kfs[k]
        passo = max(t1 - t0, 1e-4)
        soma = 0.0
        for junta in j1:
            if junta not in j0:
                continue
            delta = sum(abs(dobrar(j1[junta][i] - j0[junta][i])) for i in range(3))
            soma = soma + delta
            acumulado[junta] = acumulado.get(junta, 0.0) + delta
        velocidades.append(soma / passo)

    if not velocidades or not acumulado:
        return None

    pico = max(range(len(velocidades)), key=lambda k: velocidades[k])
    quando = kfs[pico + 1][0]
    limiar = velocidades[pico] * 0.05
    parados = sum(1 for v in velocidades if v < limiar)
    lider = max(acumulado, key=acumulado.get)
    total = sum(acumulado.values()) or 1

    return {
        "kf": len(kfs),
        "duracao": duracao,
        "impacto": round(quando / duracao * 100),
        "recuo": round((duracao - quando) / duracao * 100),
        "lider": lider,
        "peso": round(acumulado[lider] / total * 100),
        "parados": round(parados / len(velocidades) * 100),
    }


def medir_camera(bloco):
    pontos = [(float(t), (float(x), float(y), float(z)))
              for t, x, y, z in RE_CAM.findall(bloco)]
    if len(pontos) < 5:
        return None
    parada, movimentos, cortes = 0, [], []
    for i in range(1, len(pontos)):
        salto = sum(abs(pontos[i][1][n] - pontos[i - 1][1][n]) for n in range(3))
        if salto < 0.001:
            parada = parada + 1
        else:
            movimentos.append(pontos[i][0])
        if salto > 1.5:
            cortes.append(round(pontos[i][0], 2))
    return {
        "kf": len(pontos),
        "duracao": pontos[-1][0],
        "parada": round(parada / len(pontos) * 100),
        "primeiro": movimentos[0] if movimentos else None,
        "ultimo": movimentos[-1] if movimentos else None,
        "cortes": cortes,
    }


def main():
    if not os.path.exists(FONTE):
        print("referência não encontrada: %s" % FONTE)
        return 1
    texto = open(FONTE, encoding="utf-8").read()

    marcas = [(m.group(1), m.start()) for m in RE_SEQ.finditer(texto)]
    if not marcas:
        print("nenhuma sequência reconhecida em %s" % os.path.basename(FONTE))
        return 1

    print("GRAMÁTICA R6 — medida em %s" % os.path.basename(FONTE))
    print("")
    print("  %-22s %4s %8s %9s %-22s %s"
          % ("SEQUÊNCIA", "kf", "duração", "impacto", "antecipação : recuo",
             "lidera / parados"))

    for indice, (nome, ini) in enumerate(marcas):
        fim = marcas[indice + 1][1] if indice + 1 < len(marcas) else len(texto)
        bloco = texto[ini:fim]

        if "cf = CFrame" in bloco:
            camera = medir_camera(bloco)
            if camera:
                print("")
                print("  CÂMERA — %s" % nome)
                print("    %d keyframes, %.2fs, parada em %d%% dos quadros"
                      % (camera["kf"], camera["duracao"], camera["parada"]))
                if camera["primeiro"] is not None:
                    print("    move de t=%.2fs a t=%.2fs; %d corte(s): %s"
                          % (camera["primeiro"], camera["ultimo"],
                             len(camera["cortes"]), camera["cortes"][:6]))
            continue

        dados = medir(nome, keyframes(bloco))
        if not dados:
            continue
        print("  %-22s %4d %7.2fs %8d%% %2d%% : %2d%%%9s %s (%d%%) · %d%% parado"
              % (nome, dados["kf"], dados["duracao"], dados["impacto"],
                 dados["impacto"], dados["recuo"], "",
                 dados["lider"], dados["peso"], dados["parados"]))

    print("")
    print("As regras que saem destes números estão em")
    print("ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
