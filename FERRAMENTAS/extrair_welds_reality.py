#!/usr/bin/env python3
"""
extrair_welds_reality.py — Retro-Verse / Studios

Puxa a animação que está ESCRITA NO SCRIPT do `samsung` (leadpipe) e do
`LowOrbitIonCannon`, e escreve `FERRAMENTAS/dados/welds_reality.json`.

    python3 FERRAMENTAS/extrair_welds_reality.py

POR QUE ISTO EXISTE

    A primeira versão do conjunto REALITY GUI inventou pose para estas duas
    Tools. Não precisava: a animação delas está no script, inteira, no mesmo
    idioma que o Guest já tinha ensinado a ler —

        for i = 0,1 , 0.14 do
            weld.C0 = weld.C0:lerp(<ALVO>, i)
            step:wait()
        end

    `i` varre até 1, então **a pose escrita É a pose alcançada**. Dá para ler o
    `<ALVO>` direto, sem simular o laço. (No Xester o alpha era constante — 0.5
    — e aí não dava; ver `extrair_poses_guest.py`.)

    A duração sai do laço: `for i = 0,1,passo` roda `ceil(1/passo)+1` voltas, e
    cada volta é um `RunService.Stepped`, ou seja 1/60 s.

O ALVO SAI VERBATIM, E ISSO É DE PROPÓSITO

    `CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,-math.rad(45))` já é Lua
    válido. Copiar o texto é mais fiel do que avaliar em Python e reimprimir
    float: não há erro de arredondamento, e o que vai para o `Poses.lua` é
    exatamente o que o autor escreveu.

A CONVERSÃO DE C1 — O PULO DO GATO

    Um `Weld` posiciona por `Part1.CFrame = Part0.CFrame * C0 * C1:Inverse()`.
    O `R6CFrameAnimator` canônico solda com **C1 identidade**, então nele o
    `C0` sozinho é a pose.

    O `LowOrbitIonCannon` também solda com C1 identidade — o alvo dele entra
    sem tocar em nada.

    O `samsung` **não**: ele usa `C1 = CFrame.new(0,0.5,0)` nos braços e
    `CFrame.new(0,-0.5,0)` na cabeça. Igualando as duas expressões:

        Torso * A * C1⁻¹  =  Torso * C0_canonico
        C0_canonico = A * C1⁻¹

    É o INVERSO do C1 que entra como sufixo — braço leva `(0,-0.5,0)` e cabeça
    leva `(0,0.5,0)`, e não o contrário.

    A conferência é o repouso: o braço do `samsung` em repouso é
    `CFrame.new(1.5,0.5,0)`, e `(1.5,0.5,0) * (0,-0.5,0)` dá `(1.5,0,0)`, que é
    exatamente a base que o `R6CFrameAnimator` solda. Com o sinal trocado daria
    `(1.5,1,0)` — o braço um stud acima do ombro, o resto da animação inteira
    deslocado junto.
"""

import json
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, "FERRAMENTAS", "dados", "welds_reality.json")

#: um passo de `step:wait()` é um `RunService.Stepped` — 1/60 s
QUADRO = 1.0 / 60.0

FONTES = (
    ("samsung",
     os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools", "reality_tools.rbxmx"),
     "samsung", "LeadpipeServer"),
    ("loic",
     os.path.join(RAIZ, "MODELOS_ENTRADA", "Canhao_Satelite", "Canhao_satelite.rbxmx"),
     "LowOrbitIonCannon", "Script"),
)

#: Por fonte: (pedaço que aparece à esquerda do `.C0`, junta, C1 da origem).
#:
#: A MESMA POSE É ESCRITA DE DUAS MANEIRAS NO MESMO ARQUIVO. O `samsung` cria
#: os welds em `equip()` com nomes locais (`rightarm`, `head`) e depois, em
#: `swing()`, chega neles por `owner.Torso:findFirstChild("RightArmWelde")` —
#: e ainda guarda um alias (`local humweld = ...`). Procurar só o nome do weld
#: perde metade dos quadros; procurar só o local perde a outra.
#:
#: O sufixo é o INVERSO do C1 da origem (ver a conta no topo do arquivo).
#: `None` = C1 identidade, nada a fazer.
#: A lista é varrida do pedaço MAIS LONGO para o mais curto.
JUNTAS = {
    "samsung": (
        ("HumanoidRootPartWelde", "HRP", None),
        ("RightArmWelde", "RightArm", "CFrame.new(0, -0.5, 0)"),
        ("LeftArmWelde", "LeftArm", "CFrame.new(0, -0.5, 0)"),
        ("HeadWelde", "Head", "CFrame.new(0, 0.5, 0)"),
        ("humanoidrootpart", "HRP", None),
        ("humweld", "HRP", None),
        ("rightarm", "RightArm", "CFrame.new(0, -0.5, 0)"),
        ("leftarm", "LeftArm", "CFrame.new(0, -0.5, 0)"),
        ("head", "Head", "CFrame.new(0, 0.5, 0)"),
    ),
    # o LOIC solda com C1 identidade nos dois: o alvo entra sem tocar em nada
    "loic": (
        ("rightarm", "RightArm", None),
        ("head", "Head", None),
    ),
}

#: `swingrand` é `math.random(-50,50)` — sorteio em gameplay, que é proibido.
#: Vira 0: a pose fica na variante central do leque que a origem sorteava.
SUBSTITUICOES = (
    (re.compile(r"math\.rad\(\s*swingrand\s*\)"), "0"),
    (re.compile(r"\bswingrand\b"), "0"),
)

RE_LACO = re.compile(r"for\s+i\s*=\s*0\s*,\s*1\s*,?\s*,?\s*([0-9.]+)\s+do")

#: `<lado esquerdo>.C0 = <qualquer coisa>:lerp(`, dentro de UMA linha.
#:
#: O lado esquerdo pode ser `rightarm`, `humweld` ou
#: `owner.Torso:findFirstChild("RightArmWelde")` — por isso ele é `[^\n=]+`, e
#: quem decide a junta é `junta_de`, procurando pedaço conhecido.
RE_LERP = re.compile(r"^[ \t]*([^\n=]+?)\.C0\s*=[^\n]*?:lerp\(", re.M)


def nome(item):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == "Name":
            return e.text
    return None


def fonte_de(item):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == "Source":
            return e.text
    return None


def achar_script(caminho, tool, script):
    raiz = ET.parse(caminho).getroot()
    for t in raiz.iter("Item"):
        if t.get("class") != "Tool" or nome(t) != tool:
            continue
        for s in t.iter("Item"):
            if s.get("class") in ("Script", "LocalScript") and nome(s) == script:
                return fonte_de(s) or ""
    return None


def fechar_parenteses(texto, inicio):
    """Índice logo após o `)` que fecha o `(` aberto em `inicio - 1`."""
    nivel = 1
    i = inicio
    while i < len(texto) and nivel > 0:
        c = texto[i]
        if c == "(":
            nivel = nivel + 1
        elif c == ")":
            nivel = nivel - 1
        i = i + 1
    return i - 1


def alvo_do_lerp(texto, apos_lerp):
    """O primeiro argumento de `:lerp(<ALVO>, i)`, como texto cru."""
    fim = fechar_parenteses(texto, apos_lerp)
    dentro = texto[apos_lerp:fim]
    # o último vírgula de nível zero separa o alvo do alpha
    nivel, corte = 0, None
    for indice, c in enumerate(dentro):
        if c == "(":
            nivel = nivel + 1
        elif c == ")":
            nivel = nivel - 1
        elif c == "," and nivel == 0:
            corte = indice
    if corte is None:
        return None
    return " ".join(dentro[:corte].split())


def junta_de(esquerda, chave):
    """Descobre a junta a partir do lado esquerdo do `X.C0 =`.

    `RightGrip` e outros que não estejam na lista voltam `None` de propósito: o
    grip da Tool não é junta de corpo, e o animator canônico já cuida dele.
    """
    for pedaco, junta, c1 in JUNTAS[chave]:
        if pedaco in esquerda:
            return junta, c1
    return None, None


def blocos(fonte, chave):
    """Cada laço `for i = 0,1,passo`, com os alvos que ele escreve."""
    saida = []
    for m in RE_LACO.finditer(fonte):
        passo = float(m.group(1))
        # o corpo vai até o `end` que fecha — aproximado pelo próximo laço, que
        # é suficiente porque estes scripts nunca aninham dois `for i = 0,1`
        seguinte = RE_LACO.search(fonte, m.end())
        corpo = fonte[m.end():seguinte.start() if seguinte else len(fonte)]

        juntas = {}
        for lm in RE_LERP.finditer(corpo):
            junta, c1 = junta_de(lm.group(1), chave)
            if not junta or junta in juntas:
                continue
            alvo = alvo_do_lerp(corpo, lm.end())
            if not alvo:
                continue
            for padrao, troca in SUBSTITUICOES:
                alvo = padrao.sub(troca, alvo)
            if c1:
                alvo = "%s * %s" % (alvo, c1)
            juntas[junta] = alvo

        if juntas:
            voltas = int(math.ceil(1.0 / passo)) + 1
            saida.append({
                "passo": passo,
                "voltas": voltas,
                "duracao": round(voltas * QUADRO, 4),
                "juntas": juntas,
                "posicao": m.start(),
            })
    return saida


def main():
    tabela = {}
    for chave, caminho, tool, script in FONTES:
        if not os.path.exists(caminho):
            print("origem não encontrada: %s" % caminho)
            return 1
        fonte = achar_script(caminho, tool, script)
        if fonte is None:
            print("%s: não achei %s/%s" % (chave, tool, script))
            return 1

        achados = blocos(fonte, chave)
        if not achados:
            print("%s: nenhum laço `for i = 0,1` com lerp de C0" % chave)
            return 1

        tabela[chave] = achados
        total = sum(b["duracao"] for b in achados)
        print("%-8s %2d bloco(s) · %.2fs somados · juntas %s"
              % (chave, len(achados), total,
                 sorted({j for b in achados for j in b["juntas"]})))
        for indice, b in enumerate(achados):
            print("   %2d  passo %-6s %2d voltas  %.3fs  %s"
                  % (indice, b["passo"], b["voltas"], b["duracao"],
                     ", ".join(sorted(b["juntas"]))))

    os.makedirs(os.path.dirname(DESTINO), exist_ok=True)
    with open(DESTINO, "w", encoding="utf-8") as f:
        json.dump(tabela, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("")
    print("%s — %d bytes" % (os.path.relpath(DESTINO, RAIZ),
                             os.path.getsize(DESTINO)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
