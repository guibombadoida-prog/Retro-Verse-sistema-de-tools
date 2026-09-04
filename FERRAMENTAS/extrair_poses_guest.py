#!/usr/bin/env python3
"""
extrair_poses_guest.py — Retro-Verse / Studios

Extrai as poses ORIGINAIS do `Cano De Rua` e do `Taco de Baseball` do
`guest_tools.rbxmx`, e escreve `FERRAMENTAS/dados/poses_guest.json`.

    python3 FERRAMENTAS/extrair_poses_guest.py

POR QUE ESTAS DUAS PODEM SER EXTRAÍDAS, E AS DO XESTER PRECISARAM DE SIMULAÇÃO

    O `extrair_poses_xester.py` teve de SIMULAR o laço para achar a pose real,
    porque lá o alpha do `lerp` é constante:

        C0 = C0:lerp(alvo, 0.5)      -- repetido N quadros: nunca chega

    Aqui não. O laço do Guest é

        for i = 0, 1, 0.1 do
            C0 = C0:lerp(alvo, i)

    e o `i` VARRE de 0 a 1. No último passo o alpha é 1, e `lerp(alvo, 1)` é o
    próprio alvo. **A pose escrita é a pose alcançada** — dá para ler direto do
    código, sem simular nada.

    É a diferença entre um lerp de amortecimento (Xester, Noob) e um lerp de
    interpolação de verdade (Guest). O `Guest_Tools` já era a fonte de pose mais
    barata do Acervo; isto explica por quê.

A CONVENÇÃO JÁ É A NOSSA

    O original solda `Weld` do **Torso para o membro**, com os nomes
    `RightArmWelde`, `LeftArmWelde`, `HeadWelde`, `HumanoidRootPartWelde` — que
    é exatamente o que o `R6CFrameAnimator` V2 faz. Não há conversão de pivô:
    o `C0` de lá é o `C0` daqui.

    O `Taco de Baseball` usa os mesmos nomes com sufixo `bat`.

O QUE NÃO ATRAVESSA

    `CFrame.fromEulerAnglesXYZ(0, math.rad(swingrand), 0)` no braço direito —
    `swingrand` é `math.random(-50,50)`, sorteado por golpe. O termo sai: a
    variação vira jitter senoidal por contador no Server, que dá a mesma
    dispersão e faz todo cliente ver o mesmo golpe.
"""

import json
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Guest_Tools", "guest_tools.rbxmx")
DESTINO = os.path.join(RAIZ, "FERRAMENTAS", "dados", "poses_guest.json")

#: Tool -> (nome do Script, sufixo do Weld)
FONTES = {
    "Cano De Rua": ("LeadpipeServer", "Welde"),
    "Taco de Baseball": ("Script", "Weldbat"),
}


def texto(item, nome):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == nome:
            return e.text
    return None


def fonte_de(raiz, tool_nome, script_nome):
    for item in raiz.iter("Item"):
        if item.get("class") != "Tool":
            continue
        if texto(item, "Name") != tool_nome:
            continue
        for filho in item.iter("Item"):
            if filho.get("class") in ("Script", "LocalScript") \
                    and texto(filho, "Name") == script_nome:
                return texto(filho, "Source") or ""
    return ""


# ═══════════════════════════════════════════════════════════════
# CFrame em Python — só o que a composição precisa
# ═══════════════════════════════════════════════════════════════

def cf_identidade():
    return [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]


def cf_de(nums):
    """3 números = só posição; 12 = posição + matriz 3x3."""
    if len(nums) == 3:
        return [nums[0], nums[1], nums[2], 1, 0, 0, 0, 1, 0, 0, 0, 1]
    return list(nums[:12])


def cf_mul(a, b):
    """a * b, na convenção do Roblox (linha-maior, como o construtor aceita)."""
    ax, ay, az = a[0], a[1], a[2]
    A = a[3:12]
    bx, by, bz = b[0], b[1], b[2]
    B = b[3:12]

    # posição = a.pos + a.rot * b.pos
    px = ax + A[0] * bx + A[1] * by + A[2] * bz
    py = ay + A[3] * bx + A[4] * by + A[5] * bz
    pz = az + A[6] * bx + A[7] * by + A[8] * bz

    R = [0.0] * 9
    for i in range(3):
        for j in range(3):
            R[i * 3 + j] = sum(A[i * 3 + k] * B[k * 3 + j] for k in range(3))
    return [px, py, pz] + R


NUM = re.compile(r"-?\d+\.?\d*(?:e-?\d+)?")


def cframes_da_expressao(expr):
    """Compõe a cadeia `CFrame.new(...) * CFrame.new(...)` da expressão.

    O `CFrame.fromEulerAnglesXYZ(0, math.rad(swingrand), 0)` é DESCARTADO:
    `swingrand` é `math.random(-50,50)`, e sorteio em gameplay é proibido.
    """
    partes = re.findall(r"CFrame\.new\(([^)]*)\)", expr)
    total = cf_identidade()
    for parte in partes:
        nums = [float(x) for x in NUM.findall(parte)]
        if len(nums) not in (3, 12):
            continue
        total = cf_mul(total, cf_de(nums))
    return total


#: nome no código de origem -> junta do R6CFrameAnimator
APELIDOS = {
    "rightarm": "RightArm", "leftarm": "LeftArm", "head": "Head",
    "root": "HRP", "humanoidrootpart": "HRP", "hum": "HRP",
    "rightleg": "RightLeg", "leftleg": "LeftLeg",
}


def junta_de(bruto):
    chave = bruto.lower().replace("weld", "").replace("e", "") \
        if bruto.lower().endswith("welde") else bruto.lower().replace("weld", "")
    chave = bruto.lower()
    for sufixo in ("weldbat", "welde", "weld"):
        if chave.endswith(sufixo):
            chave = chave[:-len(sufixo)]
            break
    return APELIDOS.get(chave)


def extrair(fonte, sufixo):
    """Devolve [{junta: cframe}] — um dicionário por QUADRO da animação.

    As duas Tools escrevem o mesmo `C0`, de dois jeitos:

        Cano   findFirstChild("RightArmWelde").C0 = ...:lerp(alvo, i)
        Taco   rightarmweld.C0 = rightarmweld.C0:lerp(alvo, i)

    O segundo passa por uma variável local, e por isso a primeira versão deste
    extrator devolveu ZERO quadro para o Taco. Os dois padrões entram aqui.
    """
    padroes = (
        re.compile(r'findFirstChild\("(\w+)"\)\.C0[^\n]*?:lerp\((.*?),\s*i\)'),
        re.compile(r'\b(\w+)\.C0\s*=\s*\1\.C0:lerp\((.*?),\s*i\)'),
    )
    achados = []
    for padrao in padroes:
        for m in padrao.finditer(fonte):
            junta = junta_de(m.group(1))
            if junta:
                achados.append((m.start(), junta, m.group(2)))
    achados.sort()

    quadros, atual, vistas = [], {}, set()
    for _pos, junta, expr in achados:
        if junta in vistas:
            quadros.append(atual)
            atual, vistas = {}, set()
        vistas.add(junta)
        atual[junta] = cframes_da_expressao(expr)
    if atual:
        quadros.append(atual)
    return quadros


def lua_cframe(c):
    return "CFrame.new(%s)" % ", ".join(
        ("%g" % v) if abs(v) > 1e-9 else "0" for v in c)


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1
    raiz = ET.parse(ORIGEM).getroot()

    saida = {}
    for tool, (script, sufixo) in FONTES.items():
        fonte = fonte_de(raiz, tool, script)
        if not fonte:
            print("não achei %s/%s" % (tool, script))
            return 1
        quadros = extrair(fonte, sufixo)
        saida[tool] = [{j: lua_cframe(c) for j, c in q.items()} for q in quadros]
        print("%-20s %d quadro(s) · juntas: %s"
              % (tool, len(quadros),
                 ", ".join(sorted({j for q in quadros for j in q}))))

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
