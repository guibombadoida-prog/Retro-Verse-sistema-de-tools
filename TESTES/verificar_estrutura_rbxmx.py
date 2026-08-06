#!/usr/bin/env python3
"""
verificar_estrutura_rbxmx.py — Retro-Verse / Studios

O que o STUDIO exige de um `.rbxmx`, e que nenhum outro verificador olhava.

    python3 TESTES/verificar_estrutura_rbxmx.py

POR QUE ESTE ARQUIVO EXISTE

    Uma entrega saiu daqui passando em TODOS os verificadores — autocontenção,
    poses, fonte byte a byte, Núcleo — e o Studio recusou: "arquivo corrompido".

    O motivo: o bloco `<SharedStrings>` é **irmão** dos `<Item>`, não
    descendente. Montando um `.rbxmx` novo a partir dos `Item` de outro, o
    bloco fica para trás. As instâncias continuam citando a md5 em
    `<SharedString name="Tags">`, a tabela que resolve some, e o arquivo vira
    XML perfeitamente válido que o Studio não abre.

    Os verificadores liam CÓDIGO. Ninguém lia o ENVELOPE. Este lê.
"""

import os
import sys
import collections
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VERDE    = "\033[32m%s\033[0m"
VERMELHO = "\033[31m%s\033[0m"
CINZA    = "\033[90m%s\033[0m"


def alvos():
    """Todo .rbxmx que a gente entrega ou usa como insumo de montagem."""
    achados = []
    for base, _dirs, arquivos in os.walk(RAIZ):
        if os.sep + ".git" in base:
            continue
        # MODELOS_ENTRADA é material de terceiro, como chegou — não é entrega
        if "MODELOS_ENTRADA" in base:
            continue
        for a in sorted(arquivos):
            if a.endswith(".rbxmx"):
                achados.append(os.path.join(base, a))
    return sorted(achados)


def verificar(caminho):
    erros = []

    try:
        raiz = ET.parse(caminho).getroot()
    except ET.ParseError as e:
        return ["XML inválido: %s" % e]

    if raiz.tag != "roblox":
        erros.append("raiz é <%s>, esperava <roblox>" % raiz.tag)
    if raiz.get("version") != "4":
        erros.append("version=%r, esperava \"4\"" % raiz.get("version"))

    # 1. SharedStrings — a que derrubou a entrega
    citadas = collections.Counter()
    for e in raiz.iter("SharedString"):
        if e.get("name"):
            v = (e.text or "").strip()
            if v:
                citadas[v] += 1
    tabela = {e.get("md5") for e in raiz.iter("SharedString") if e.get("md5")}

    penduradas = sorted(set(citadas) - tabela)
    if penduradas:
        erros.append("SharedString citada e sem tabela — o Studio recusa o "
                     "arquivo como corrompido: %s" % ", ".join(penduradas))

    orfas = sorted(tabela - set(citadas))
    if orfas:
        erros.append("SharedString na tabela que ninguém cita: %s"
                     % ", ".join(orfas))

    # 2. referent duplicado religa propriedade no objeto errado
    refs = collections.Counter(i.get("referent") for i in raiz.iter("Item"))
    dup = sorted(k for k, v in refs.items() if v > 1 and k)
    if dup:
        erros.append("referent duplicado: %s" % ", ".join(dup[:5]))

    # 3. <Ref> apontando para referent que não existe no arquivo
    existentes = {k for k in refs if k}
    pendurados = []
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in props:
            if e.tag != "Ref":
                continue
            v = (e.text or "").strip()
            if v and v != "null" and v not in existentes:
                pendurados.append("%s.%s" % (item.get("class"), e.get("name")))
    if pendurados:
        erros.append("Ref apontando para fora do arquivo: %s"
                     % ", ".join(sorted(set(pendurados))[:5]))

    # 4. CDATA fechado cedo demais
    #
    # O Source vai dentro de <![CDATA[ ... ]]>. Se o Lua contiver a sequência
    # `]]>`, o CDATA fecha ali e o resto do script vaza como marcação. Lua tem
    # `]]` em todo comentário longo, então isto é a um `>` de distância.
    with open(caminho, encoding="utf-8") as f:
        bruto = f.read()
    for pedaco in bruto.split("<![CDATA[")[1:]:
        corpo = pedaco.split("]]>")[0]
        if "]]>" in (corpo + "]]>") and corpo != pedaco.split("]]>")[0]:
            pass
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in props:
            if e.get("name") == "Source" and "]]>" in (e.text or ""):
                erros.append("Source contém `]]>` e fecharia o CDATA no meio")

    # 5. Tool tem de ser item de RAIZ — dentro de Folder a StarterPack não entrega
    for item in raiz.findall("Item"):
        if item.get("class") == "Folder":
            for filho in item.iter("Item"):
                if filho.get("class") == "Tool":
                    erros.append("Tool dentro de Folder — a StarterPack não "
                                 "entregaria nada ao jogador")
                    break

    return erros


def main():
    print("")
    print("ESTRUTURA DOS .rbxmx — o que o Studio exige do envelope")
    print(CINZA % "SharedStrings, referent, Ref, CDATA, Tool na raiz")
    print("")

    total = 0
    arquivos = alvos()
    for caminho in arquivos:
        rel = os.path.relpath(caminho, RAIZ)
        erros = verificar(caminho)
        if erros:
            total += len(erros)
            print(VERMELHO % ("✗ %s" % rel))
            for e in erros:
                print("    %s" % e)
        else:
            print(VERDE % ("✓ %s" % rel))

    print("")
    if total == 0:
        print(VERDE % ("ESTRUTURA OK — %d arquivo(s)" % len(arquivos)))
        print("")
        return 0
    print(VERMELHO % ("%d PROBLEMA(S) EM %d ARQUIVO(S)" % (total, len(arquivos))))
    print("")
    return 1


if __name__ == "__main__":
    sys.exit(main())
