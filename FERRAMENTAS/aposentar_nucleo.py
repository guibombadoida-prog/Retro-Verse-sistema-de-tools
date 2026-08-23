#!/usr/bin/env python3
"""
aposentar_nucleo.py — Retro-Verse / Studios

Tira `_G.Combate` do repositório inteiro: dos geradores e dos Servers escritos à mão.

    python3 FERRAMENTAS/aposentar_nucleo.py

POR QUE ISTO É UM SCRIPT E NÃO 94 EDIÇÕES À MÃO

    Toda chamada ao Núcleo neste repositório é `_G.Combate and <coisa> or <fallback>`, e o
    fallback SEMPRE existe — foi escrito e verificado junto. Aposentar o Núcleo é, mecânica
    e literalmente, **apagar o caminho de cima e ficar com o de baixo**.

    São 2 228 ocorrências. À mão isso é uma tarde inteira e um erro de recorte garantido.

AS TRÊS FORMAS, E COMO CADA UMA MORRE

    A) `if _G.Combate and _G.Combate.X then <núcleo> else <fallback> end`
       -> fica só o `<fallback>`, com uma tabulação a menos.

    B) `if _G.Combate and _G.Combate.X then <núcleo> end` seguido do fallback solto
       -> o bloco inteiro some; o que vinha depois já era o caminho único.

    C) `local x = (_G.Combate and _G.Combate.X and _G.Combate.X(...)) or <padrão>`
       -> `local x = <padrão>`.

    O casamento do `end` é por CONTAGEM DE BLOCO, não por regex. Fechar bloco de Lua com
    expressão regular é o defeito que o `verificar_beats.py` e o `verificar_pack_vfx.py` já
    tiveram os dois — e nos dois casos o verificador passou verde sem ter olhado para nada.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ABRE = re.compile(r"^(\s*)if _G\.Combate and _G\.Combate\.\w+ then\s*$")
#: abre bloco de Lua e portanto pede um `end`
RE_ABRE_BLOCO = re.compile(
    r"(?:^|\s)(?:function\b|if\b|for\b|while\b|do\b)|(?:\bfunction\s*\()")
RE_FECHA = re.compile(r"^\s*end\b|^\s*end\)|^\s*end,|^\s*end\}")


def profundidade(linha):
    """Quanto esta linha mexe no nível de bloco. Comentário não conta."""
    corpo = linha.split("--", 1)[0]
    sobe = len(re.findall(r"\bfunction\b|\bif\b|\bfor\b|\bwhile\b", corpo))
    # `do` de for/while já contou no for/while; `do` solto é raro e não aparece aqui
    desce = len(re.findall(r"\bend\b", corpo))
    # `elseif` reabre e fecha no mesmo nível
    sobe = sobe - len(re.findall(r"\belseif\b", corpo))
    return sobe - desce


def limpar_bloco(linhas, i):
    """Come o `if _G.Combate ... end` que começa em `i`.

    Devolve (linhas_de_substituicao, indice_depois_do_end).
    """
    recuo = ABRE.match(linhas[i]).group(1)
    nivel = 1
    j = i + 1
    corpo_nucleo, corpo_fallback = [], None
    while j < len(linhas) and nivel > 0:
        linha = linhas[j]
        if nivel == 1 and re.match(r"^%selse\s*$" % re.escape(recuo), linha):
            corpo_fallback = []
            j = j + 1
            continue
        nivel = nivel + profundidade(linha)
        if nivel <= 0:
            break
        (corpo_fallback if corpo_fallback is not None else corpo_nucleo).append(linha)
        j = j + 1

    if corpo_fallback is None:
        return [], j + 1                       # forma B: o bloco inteiro some
    # forma A: sobra o fallback, uma tabulação a menos
    saida = []
    for linha in corpo_fallback:
        saida.append(linha[1:] if linha.startswith("\t") else linha)
    return saida, j + 1


#: forma C, em uma ou duas linhas
INLINE = re.compile(
    r"\(_G\.Combate and _G\.Combate\.\w+\s*\n?\s*and _G\.Combate\.\w+\([^()]*(?:\([^()]*\)[^()]*)*\)\)\s*or\s*",
    re.S)
INLINE_CURTA = re.compile(
    r"_G\.Combate and _G\.Combate\.\w+\([^()]*(?:\([^()]*\)[^()]*)*\)\s*or\s*")


def limpar(texto):
    # C primeiro: some a expressão, fica o padrão
    texto = INLINE.sub("", texto)
    texto = INLINE_CURTA.sub("", texto)

    linhas = texto.split("\n")
    saida, i = [], 0
    while i < len(linhas):
        if ABRE.match(linhas[i]):
            trecho, i = limpar_bloco(linhas, i)
            saida.extend(trecho)
        else:
            saida.append(linhas[i])
            i = i + 1
    return "\n".join(saida)


def alvos():
    for pasta, _sub, arqs in os.walk(RAIZ):
        if os.sep + ".git" in pasta or "__pycache__" in pasta:
            continue
        for a in sorted(arqs):
            if a.endswith(".py") or a.endswith(".lua"):
                yield os.path.join(pasta, a)


def main():
    tocados, antes_total = 0, 0
    for caminho in alvos():
        if os.path.basename(caminho) == "aposentar_nucleo.py":
            continue
        texto = open(caminho, encoding="utf-8").read()
        antes = texto.count("_G.Combate")
        if antes == 0:
            continue
        novo = limpar(texto)
        depois = novo.count("_G.Combate")
        open(caminho, "w", encoding="utf-8").write(novo)
        tocados = tocados + 1
        antes_total = antes_total + antes
        marca = "ok" if depois == 0 else "SOBROU %d" % depois
        print("  %-58s %4d -> %-3d %s"
              % (os.path.relpath(caminho, RAIZ), antes, depois, marca))
    print("")
    print("%d arquivo(s), %d ocorrência(s) de _G.Combate" % (tocados, antes_total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
