#!/usr/bin/env python3
"""
montar_xester_v3.py — Retro-Verse / Studios

Monta os DOIS arquivos de entrega do Xester e o `.rbxmx` avulso de cada uma das
13 Tools.

    python3 FERRAMENTAS/montar_xester_v3.py

    Tools/Xester_Forma1_7_Tools.rbxmx   as 7 do Mestre do Baralho
    Tools/Xester_Forma2_6_Tools.rbxmx   as 6 do Heavenbreaker

DOIS ARQUIVOS, PORQUE SÃO DUAS FORMAS

    `clonar_tool.py montar` monta um conjunto só. O Xester sai em dois, um por
    forma, e é por isso que este script existe separado.

    O resto do procedimento é o mesmo, inclusive a parte que já quebrou duas
    vezes: a tabela de `SharedStrings`. Ela é IRMÃ do `<Item>`, não descendente.
    Copiar só os Items e esquecer a tabela deixa md5 pendurado, e o Studio
    responde "arquivo corrompido" sem dizer por quê.

O PACK DA STELLA ENTRA — É A REGRA DE REUSO

    O fluxo obrigatório manda ler o `_INDICE.md` antes de criar efeito e reusar
    o que já existe. Onda, nova, explosão, corte, anel e espiral do Xester saem
    do `Stella_VFX_Addon`, conformado pelo §12.12.2.

    O pack é COPIADO para dentro de `VFXModule/Pack` de cada Tool na montagem.
    Nenhuma Tool lê o Acervo em runtime — o Acervo é prateleira de edição, e a
    Regra nº 1 não abre exceção nem para ele.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from clonar_tool import (enxertar_deposito, PACK_VFX, RAIZ, TOOLS, enxertar_pack, escrever,
                         nome_arquivo, nova_raiz, percorrer, prop,
                         tabela_compartilhada, tirar_sandbox)

FORMA1 = [
    "Xester Curtain Call",
    "Xester Four Suits Arsenal",
    "Xester Jokers Labyrinth",
    "Xester Ace Gate",
    "Xester House Collapse",
    "Xester Eclipse Deck",
    "Xester Royal Guard",
]

FORMA2 = [
    "Xester Wyrm Sparks",
    "Xester Crown of Cinders",
    "Xester Dragons Requiem",
    "Xester Prism",
    "Xester Final Page",
    "Xester Curtain Reversal",
]


def montar(nomes, destino, rotulo):
    raiz = nova_raiz()
    trocados, mantidos, enxertados, dessandbox, depositos = 0, 0, 0, 0, 0
    penduradas = []

    fontes = [os.path.join(TOOLS, n, "_ORIGEM.rbxmx") for n in nomes]
    faltando = [f for f in fontes if not os.path.exists(f)]
    if faltando:
        print("  PAREI: sem _ORIGEM.rbxmx em:")
        for f in faltando:
            print("    %s" % os.path.relpath(f, RAIZ))
        return None
    tabela = tabela_compartilhada(fontes + [PACK_VFX])

    for nome in nomes:
        pasta = os.path.join(TOOLS, nome)
        sub = ET.parse(os.path.join(pasta, "_ORIGEM.rbxmx")).getroot()
        tool = sub.find("Item")

        dessandbox = dessandbox + tirar_sandbox(tool)

        for item, caminho in percorrer(tool):
            relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
            arquivo = os.path.join(pasta, nome_arquivo(relativo))
            campo = prop(item, "Source")
            if campo is None:
                continue
            if os.path.exists(arquivo):
                with open(arquivo, encoding="utf-8") as f:
                    campo.text = f.read()
                trocados = trocados + 1
            else:
                mantidos = mantidos + 1

        enxertados = enxertados + enxertar_pack(tool)

        depositos = depositos + enxertar_deposito(tool, nome)

        # Uma Tool, um arquivo — é assim que ela chega no Studio.
        sozinha = nova_raiz()
        sozinha.append(tool)
        penduradas.extend(escrever(
            sozinha, os.path.join(pasta, "%s.rbxmx" % nome), tabela))

        raiz.append(tool)

    penduradas.extend(escrever(raiz, destino, tabela))

    print("  %s" % rotulo)
    print("    %s  —  %d bytes" % (os.path.relpath(destino, RAIZ),
                                   os.path.getsize(destino)))
    print("    %d Tool(s), %d script(s) vindos do .lua, %d mantidos"
          % (len(nomes), trocados, mantidos))
    print("    %d efeito(s) do pack copiados DENTRO das Tools (Regra nº 1)"
          % enxertados)
    if dessandbox:
        print("    %d script(s) sem a fronteira de sandbox" % dessandbox)
    if penduradas:
        print("    ⚠️  %d SharedString PENDURADA: %s"
              % (len(set(penduradas)), ", ".join(sorted(set(penduradas)))))
    else:
        print("    %d SharedString na tabela, 0 pendurada" % len(tabela))
    return len(penduradas)


def main():
    print("MONTAGEM — Xester")
    print("")
    ruins = 0
    for nomes, arquivo, rotulo in (
            (FORMA1, "Xester_Forma1_7_Tools.rbxmx",
             "Forma 1 — Mestre do Baralho (7 Tools)"),
            (FORMA2, "Xester_Forma2_6_Tools.rbxmx",
             "Forma 2 — Heavenbreaker (6 Tools)")):
        saida = montar(nomes, os.path.join(TOOLS, arquivo), rotulo)
        if saida is None:
            return 1
        ruins = ruins + saida
        print("")
    print("Dois arquivos, um por forma, com as Tools dentro.")
    return 1 if ruins else 0


if __name__ == "__main__":
    sys.exit(main())
