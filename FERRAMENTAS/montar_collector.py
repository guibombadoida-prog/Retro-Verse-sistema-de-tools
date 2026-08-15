#!/usr/bin/env python3
"""
montar_collector.py — Retro-Verse / Studios

Monta o arquivo de entrega do conjunto COLLECTOR e o `.rbxmx` avulso de cada uma
das 6 Tools, com o pack de VFX do Acervo copiado para dentro.

    python3 FERRAMENTAS/montar_collector.py
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from clonar_tool import (PACK_VFX, RAIZ, TOOLS, enxertar_pack, escrever,
                         tirar_sandbox,
                         nome_arquivo, nova_raiz, percorrer, prop,
                         tabela_compartilhada)

CONJUNTO = [
    "Pilar das Lamentacoes",
    "Julgamento Final",
    "Atraso Mortal",
    "Perturbacao",
    "Portal do Submundo",
    "Olho do Vigia",
]


def main():
    destino = os.path.join(TOOLS, "collector.rbxmx")
    raiz = nova_raiz()
    trocados, mantidos, enxertados = 0, 0, 0
    penduradas = []

    fontes = [os.path.join(TOOLS, n, "_ORIGEM.rbxmx") for n in CONJUNTO]
    faltando = [f for f in fontes if not os.path.exists(f)]
    if faltando:
        print("PAREI: sem _ORIGEM.rbxmx em:")
        for f in faltando:
            print("  %s" % os.path.relpath(f, RAIZ))
        return 1

    tabela = tabela_compartilhada(fontes + [PACK_VFX])

    print("MONTAGEM — conjunto COLLECTOR")
    print("")
    for nome in CONJUNTO:
        pasta = os.path.join(TOOLS, nome)
        tool = ET.parse(os.path.join(pasta, "_ORIGEM.rbxmx")).getroot().find("Item")

        for item, caminho in percorrer(tool):
            campo = prop(item, "Source")
            if campo is None:
                continue
            relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
            arquivo = os.path.join(pasta, nome_arquivo(relativo))
            if os.path.exists(arquivo):
                with open(arquivo, encoding="utf-8") as f:
                    campo.text = f.read()
                trocados = trocados + 1
            else:
                mantidos = mantidos + 1

        enxertados = enxertados + enxertar_pack(tool)
        tirar_sandbox(tool)

        sozinha = nova_raiz()
        sozinha.append(tool)
        penduradas.extend(escrever(
            sozinha, os.path.join(pasta, "%s.rbxmx" % nome), tabela))
        raiz.append(tool)

    penduradas.extend(escrever(raiz, destino, tabela))

    print("  %s  —  %d bytes" % (os.path.relpath(destino, RAIZ),
                                 os.path.getsize(destino)))
    print("  %d Tool(s), %d script(s) vindos do .lua, %d vazios"
          % (len(CONJUNTO), trocados, mantidos))
    print("  %d efeito(s) do pack Stella copiados DENTRO das Tools (Regra nº 1)"
          % enxertados)
    if penduradas:
        print("  ⚠️  %d SharedString PENDURADA: %s"
              % (len(set(penduradas)), ", ".join(sorted(set(penduradas)))))
        return 1
    print("  %d SharedString na tabela, 0 pendurada" % len(tabela))
    return 0


if __name__ == "__main__":
    sys.exit(main())
