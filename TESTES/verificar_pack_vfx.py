#!/usr/bin/env python3
"""
verificar_pack_vfx.py — Retro-Verse / Studios

Confere o TIPO de cada argumento que as Tools passam para os efeitos do pack.

    python3 TESTES/verificar_pack_vfx.py

POR QUE ESTE VERIFICADOR EXISTE

    Cinco dos dez efeitos do `Stella_VFX_Addon` recebem tamanho como NÚMERO;
    dois recebem como `Vector3`. Os nomes dos parâmetros não dizem qual é qual —
    `Size_A` é número no `Small_Nova` e `Vector_Size_A` é Vector3 no
    `Shockwave`. Eu li o nome e adivinhei, e passei Vector3 em cinco deles.

    O erro não aparecia: a chamada mora dentro de `pcall`, então metade dos
    efeitos falhava em silêncio e a Tool continuava "passando" nos outros
    verificadores. Só apareceu quando o Developer Console do jogo mostrou
    `invalid argument #1 to 'new' (number expected, got Vector3)`.

    Nenhum lint pega isso lendo Lua estaticamente sem tipos. O que dá para
    fazer é o que este script faz: ler a ASSINATURA REAL de cada módulo do
    pack, no Acervo, e conferir contra o que as Tools passam.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Stella_VFX_Addon", "VFX")
TOOLS = os.path.join(RAIZ, "Tools")

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

RE_ASSINATURA = re.compile(r"^return function\(([^)]*)\)", re.M)
# `X = X or <default>` é o que revela o tipo esperado de cada parâmetro
RE_PADRAO = re.compile(r"^\s*(\w+)\s*=\s*\1\s+or\s+(.+?);?\s*$", re.M)


def tipo_do_padrao(texto):
    texto = texto.strip()
    if texto.startswith("Vector3.new"):
        return "Vector3"
    if texto.startswith("CFrame.new"):
        return "CFrame"
    if texto.startswith("Color3."):
        return "Color3"
    if texto.startswith("Enum."):
        return "Enum"
    if re.fullmatch(r"-?[0-9.]+", texto):
        return "number"
    return None


def assinatura(caminho):
    """Nome dos parâmetros na ordem + o tipo que o corpo revela para cada um."""
    texto = open(caminho, encoding="utf-8").read()
    m = RE_ASSINATURA.search(texto)
    if not m:
        return None, {}
    nomes = [p.strip() for p in m.group(1).split(",")]
    tipos = {}
    for param, padrao in RE_PADRAO.findall(texto):
        achado = tipo_do_padrao(padrao)
        if achado and param in nomes:
            tipos.setdefault(param, achado)
    return nomes, tipos


def partes(txt):
    """Quebra 'a, b, c' respeitando parênteses."""
    saida, nivel, atual = [], 0, ""
    for ch in txt:
        if ch in "([":
            nivel = nivel + 1
        elif ch in ")]":
            nivel = nivel - 1
        if ch == "," and nivel == 0:
            saida.append(atual.strip())
            atual = ""
        else:
            atual = atual + ch
    if atual.strip():
        saida.append(atual.strip())
    return saida


def tipo_do_argumento(txt):
    txt = txt.strip()
    if txt.startswith("Vector3.new") or ".Size" in txt:
        return "Vector3"
    if txt.startswith("CFrame.new") or txt.endswith(".CFrame"):
        return "CFrame"
    if txt.startswith("COR.") or txt.startswith("Color3."):
        return "Color3"
    if txt.startswith("Enum."):
        return "Enum"
    if re.match(r"^\(?[a-z_]+ or [-0-9.]+\)?( \* [0-9.]+)?$", txt):
        return "number"
    if re.fullmatch(r"[-0-9.]+", txt):
        return "number"
    if re.match(r"^[a-z]\w*( \* [0-9.]+)?$", txt):
        return "number?"
    return None


def main():
    if not os.path.isdir(PACK):
        print("pack não encontrado: %s" % PACK)
        return 1

    esperado = {}
    for arquivo in sorted(os.listdir(PACK)):
        if not arquivo.endswith(".lua"):
            continue
        nomes, tipos = assinatura(os.path.join(PACK, arquivo))
        if nomes:
            esperado[arquivo[:-4]] = (nomes, tipos)

    print("VERIFICAÇÃO DE TIPOS — chamadas ao pack de VFX")
    print("")
    print(CINZA % "  assinaturas lidas do Acervo:")
    for efeito, (nomes, tipos) in sorted(esperado.items()):
        marcas = ", ".join("%s:%s" % (n, tipos.get(n, "?")) for n in nomes)
        print(CINZA % ("    %-22s %s" % (efeito, marcas[:88])))
    print("")

    # ⚠️ ESTE PADRÃO JÁ FOI `pk\(\s*"(\w+)"\s*,(.*?)\)\s*then`.
    #
    #     Ele só enxergava a chamada quando ela morava dentro de um
    #     `if not pk(...) then <fallback> end`. Chamada SOLTA — `pk(...)` como
    #     comando, que é a forma quando o pack é camada EXTRA por cima de um
    #     desenho que sempre acontece — não casava com o `) then`, e o `.*?`
    #     com `re.S` varria o arquivo para a frente até achar um `) then` de
    #     outra função, quilômetros abaixo.
    #
    #     O resultado não era "não confere": era conferir LIXO. A lista de
    #     argumentos virava tudo que houvesse no caminho, e o verificador
    #     acusava "arg 7 espera Enum, recebe Vector3" numa chamada de seis
    #     argumentos perfeitamente correta.
    #
    # Agora o corpo é lido com CONTADOR DE PARÊNTESES, do `pk(` até o fecha que
    # é dele. Não depende de o que vem depois, e pega as duas formas.
    def chamadas(texto):
        for m in re.finditer(r'pk\(\s*"(\w+)"\s*,', texto):
            nivel, i = 1, m.end()
            while i < len(texto) and nivel > 0:
                if texto[i] in "([":
                    nivel = nivel + 1
                elif texto[i] in ")]":
                    nivel = nivel - 1
                    if nivel == 0:
                        break
                i = i + 1
            if nivel == 0:
                yield m.group(1), texto[m.end():i]
    problemas = 0
    conferidas = 0
    for pasta in sorted(os.listdir(TOOLS)):
        caminho = os.path.join(TOOLS, pasta, "VFXModule.lua")
        if not os.path.exists(caminho):
            continue
        texto = open(caminho, encoding="utf-8").read()
        achados = []
        for efeito, corpo in chamadas(texto):
            if efeito not in esperado:
                achados.append("chama %r, que não existe no pack" % efeito)
                continue
            nomes, tipos = esperado[efeito]
            args = partes(corpo)
            conferidas = conferidas + 1
            for indice, arg in enumerate(args):
                if indice >= len(nomes):
                    break
                quer = tipos.get(nomes[indice])
                tem = tipo_do_argumento(arg)
                if not quer or not tem or tem.endswith("?"):
                    continue
                if quer != tem:
                    achados.append(
                        "%s(arg %d = %s): espera %s, recebe %s"
                        % (efeito, indice + 1, nomes[indice], quer, tem))
        if achados:
            problemas = problemas + len(achados)
            print(VERMELHO % ("✗ %s" % pasta))
            for linha in achados:
                print("    %s" % linha)

    print("")
    if problemas:
        print(VERMELHO % ("%d chamada(s) com tipo errado" % problemas))
        print(CINZA % "Elas falham dentro do pcall e o efeito some sem avisar.")
        return 1
    print(VERDE % ("TIPOS OK — %d chamada(s) ao pack conferidas" % conferidas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
