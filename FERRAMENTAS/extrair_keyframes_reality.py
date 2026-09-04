#!/usr/bin/env python3
"""
extrair_keyframes_reality.py — Retro-Verse / Studios

Converte as `KeyframeSequence` do `reality_tools.rbxmx` em tabela de pose R6,
e escreve `FERRAMENTAS/dados/keyframes_reality.json`.

    python3 FERRAMENTAS/extrair_keyframes_reality.py

A PRIMEIRA `KeyframeSequence` DO REPOSITÓRIO

    Tudo que entrou aqui antes era pose escrita em LAÇO — `Weld.C0` no Guest e
    no Xester, `Motor6D.C0` no Noob. Esta é a coisa de verdade: o formato que o
    Animation Editor do Studio produz, com `Keyframe` datado e `Pose` por junta.

    `kick dance/california gurls` tem **361 Keyframe** e 2527 `Pose`. É a maior
    densidade de animação que já chegou, por uma ordem de grandeza.

A CONVERSÃO: `Pose.CFrame` NÃO É O `C0` QUE O ANIMATOR QUER

    Numa `KeyframeSequence`, o `Pose.CFrame` é o que o Roblox põe em
    `Motor6D.Transform` — um DELTA sobre a junta em repouso, não a posição
    final do membro.

    O `R6CFrameAnimator` V2 solda `Weld` do Torso para o membro e escreve o
    `C0` direto. Então a conversão é

        C0 = <base da junta> * Pose.CFrame

    com a base sendo o repouso R6 que o animator já usa: RightArm (1.5,0,0),
    LeftArm (-1.5,0,0), Head (0,1.5,0), HRP identidade, pernas (±0.5,-2,0).

    Sem multiplicar pela base, o braço nasceria no meio do peito.

NADA DE AMOSTRAGEM. ENTRA TUDO.

    A primeira versão deste extrator cortava o `a-train` de 40 para 10 quadros
    e o `kick dance` de 361 para 14, com a desculpa de "guardar a silhueta".
    Não guarda: joga a animação fora e desenha outra por cima.

    E não havia nem o que descartar — medido: os 361 são todos DISTINTOS entre
    si, e o passo é uniforme em 1/30 s. Não existe quadro repetido. Amostrar
    era perda pura.

    Quem consome é `P.TRACKS` mais `Animator:PlayTrack`, que roda no
    `Heartbeat` com acumulador `dt` e tempo ABSOLUTO — sem a deriva de emenda
    que `PlaySequence` teria com 361 tweens encadeados.
"""

import json
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                      "reality_tools.rbxmx")
DESTINO = os.path.join(RAIZ, "FERRAMENTAS", "dados", "keyframes_reality.json")

#: Tool de origem -> nome da KeyframeSequence. SEM corte: entra tudo.
FONTES = {
    "kick dance": "california gurls",
    "a-train": "a-train",
}

#: o repouso R6 que o R6CFrameAnimator usa como base do Weld
BASES = {
    "Right Arm": (1.5, 0.0, 0.0),
    "Left Arm": (-1.5, 0.0, 0.0),
    "Head": (0.0, 1.5, 0.0),
    "Right Leg": (0.5, -2.0, 0.0),
    "Left Leg": (-0.5, -2.0, 0.0),
    "Torso": (0.0, 0.0, 0.0),
    "HumanoidRootPart": (0.0, 0.0, 0.0),
}

#: nome da junta na KeyframeSequence -> nome no Poses.lua
JUNTAS = {
    "Right Arm": "RightArm",
    "Left Arm": "LeftArm",
    "Head": "Head",
    "Right Leg": "RightLeg",
    "Left Leg": "LeftLeg",
    "Torso": "HRP",
}


def nome(item):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == "Name":
            return e.text
    return None


def campo(item, alvo):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == alvo:
            return e
    return None


def cframe_de(item):
    """O `CFrame` de um `Pose`, como lista de 12 (posição + matriz)."""
    e = campo(item, "CFrame")
    if e is None:
        return None
    valores = {}
    for filho in e:
        try:
            valores[filho.tag] = float(filho.text)
        except (TypeError, ValueError):
            return None
    ordem = ("X", "Y", "Z", "R00", "R01", "R02",
             "R10", "R11", "R12", "R20", "R21", "R22")
    if not all(k in valores for k in ordem):
        return None
    return [valores[k] for k in ordem]


def tempo_de(item):
    e = campo(item, "Time")
    try:
        return float(e.text)
    except (TypeError, ValueError, AttributeError):
        return None


def cf_mul(a, b):
    ax, ay, az = a[0], a[1], a[2]
    A = a[3:12]
    bx, by, bz = b[0], b[1], b[2]
    B = b[3:12]
    px = ax + A[0] * bx + A[1] * by + A[2] * bz
    py = ay + A[3] * bx + A[4] * by + A[5] * bz
    pz = az + A[6] * bx + A[7] * by + A[8] * bz
    R = [0.0] * 9
    for i in range(3):
        for j in range(3):
            R[i * 3 + j] = sum(A[i * 3 + k] * B[k * 3 + j] for k in range(3))
    return [px, py, pz] + R


def base_cf(junta):
    x, y, z = BASES[junta]
    return [x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1]


def poses_do_keyframe(kf):
    """{junta do Poses.lua: CFrame de 12} — já multiplicado pela base."""
    saida = {}
    for pose in kf.iter("Item"):
        if pose.get("class") != "Pose":
            continue
        bruto = nome(pose)
        if bruto not in JUNTAS:
            continue
        delta = cframe_de(pose)
        if delta is None:
            continue
        # C0 = base * Pose.CFrame — sem isto o braço nasce no meio do peito
        saida[JUNTAS[bruto]] = cf_mul(base_cf(bruto), delta)
    return saida




def lua_cframe(c):
    return "CFrame.new(%s)" % ", ".join(
        ("%.5g" % v) if abs(v) > 1e-6 else "0" for v in c)


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1
    raiz = ET.parse(ORIGEM).getroot()

    saida = {}
    for item in raiz.findall("Item"):
        if item.get("class") != "Tool":
            continue
        tool = nome(item)
        if tool not in FONTES:
            continue
        alvo = FONTES[tool]

        seq = None
        for x in item.iter("Item"):
            if x.get("class") == "KeyframeSequence" and nome(x) == alvo:
                seq = x
                break
        if seq is None:
            print("%s: não achei a KeyframeSequence %r" % (tool, alvo))
            return 1

        quadros = []
        for kf in seq.iter("Item"):
            if kf.get("class") != "Keyframe":
                continue
            t = tempo_de(kf)
            p = poses_do_keyframe(kf)
            if t is not None and p:
                quadros.append((t, p))
        quadros.sort(key=lambda par: par[0])

        duracao = quadros[-1][0] - quadros[0][0] if quadros else 0.0
        t0 = quadros[0][0] if quadros else 0.0

        saida[tool] = {
            "sequencia": alvo,
            "keyframes_na_origem": len(quadros),
            "duracao": round(duracao, 3),
            "quadros": [
                {"t": round(t - t0, 4),
                 "juntas": {j: lua_cframe(c) for j, c in p.items()}}
                for t, p in quadros
            ],
        }
        print("%-16s %-18s %4d keyframes · %.2fs -> %d gravados (INTEIRA)"
              % (tool, alvo, len(quadros), duracao, len(quadros)))

    if not saida:
        print("nenhuma KeyframeSequence encontrada")
        return 1

    os.makedirs(os.path.dirname(DESTINO), exist_ok=True)
    with open(DESTINO, "w", encoding="utf-8") as f:
        json.dump(saida, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("")
    print("%s — %d bytes" % (os.path.relpath(DESTINO, RAIZ),
                             os.path.getsize(DESTINO)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
