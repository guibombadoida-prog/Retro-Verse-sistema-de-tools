#!/usr/bin/env python3
"""
montar_xester.py — Retro-Verse / Studios

Monta os DOIS arquivos de entrega do Xester, um por forma, e o `.rbxmx` avulso
de cada uma das 14 Tools.

    python3 FERRAMENTAS/montar_xester.py

O PACK DA STELLA ENTRA — É A REGRA DE REUSO

    O fluxo obrigatório manda ler o `_INDICE.md` antes de criar efeito e reusar
    o que já existe. Existe: os 10 efeitos do `Stella_VFX_Addon`, conformados
    pelo §12.12.2 e já em uso nas 18 Tools anteriores. Onda, nova, explosão,
    corte, anel, rachadura, feixe e espiral do Xester saem de lá.

    O pack é COPIADO para dentro de `VFXModule/Pack` de cada Tool na montagem.
    Nenhuma Tool lê o Acervo em runtime — o Acervo é prateleira de edição, e a
    Regra nº 1 não abre exceção nem para ele.

    Este script existe separado do `clonar_tool.py montar` porque o Xester sai
    em DOIS arquivos, um por forma, e aquele monta um conjunto só.

    O resto do procedimento é o mesmo, inclusive a parte que já quebrou uma
    vez: a tabela de `SharedStrings`. Ela é IRMÃ do `<Item>`, não descendente.
    Copiar só os Items e esquecer a tabela deixa md5 pendurado, e o Studio
    responde "arquivo corrompido" sem dizer por quê.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from clonar_tool import (PACK_VFX, RAIZ, TOOLS, enxertar_pack, escrever,
                         nome_arquivo, nova_raiz, percorrer, prop,
                         tabela_compartilhada)

FORMA1 = [
    "Xester Ato de Desaparecer",
    "Xester Full House",
    "Xester Cardnado",
    "Xester Teleporte",
    "Xester Carta Colossal",
    "Xester Buraco Negro",
    "Xester Escudo de Cartas",
]

FORMA2 = [
    "Xester Carta Ceifeira",
    "Xester Esfera do Fim",
    "Xester Baralho Espectral",
    "Xester Invocacao",
    "Xester Furia do Machado",
    "Xester Procissao de Cartas",
    "Xester Portal do Cajado",
]


def montar(nomes, destino, rotulo):
    raiz = nova_raiz()
    trocados, mantidos, enxertados = 0, 0, 0
    penduradas = []

    fontes = [os.path.join(TOOLS, n, "_ORIGEM.rbxmx") for n in nomes]
    faltando = [f for f in fontes if not os.path.exists(f)]
    if faltando:
        print("  PAREI: sem _ORIGEM.rbxmx em:")
        for f in faltando:
            print("    %s" % os.path.relpath(f, RAIZ))
        print("  rode antes: python3 FERRAMENTAS/preparar_xester.py")
        return None

    # a tabela vem das DUAS fontes: o _ORIGEM de cada Tool e o pack do Acervo
    tabela = tabela_compartilhada(fontes + [PACK_VFX])

    for nome in nomes:
        pasta = os.path.join(TOOLS, nome)
        sub = ET.parse(os.path.join(pasta, "_ORIGEM.rbxmx")).getroot()
        tool = sub.find("Item")

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
    print("    %d Tool(s), %d script(s) vindos do .lua, %d vazios"
          % (len(nomes), trocados, mantidos))
    print("    %d efeito(s) do pack Stella copiados DENTRO das Tools (Regra nº 1)"
          % enxertados)
    if penduradas:
        print("    ⚠️  %d SharedString PENDURADA: %s"
              % (len(set(penduradas)), ", ".join(sorted(set(penduradas)))))
    else:
        print("    %d SharedString na tabela, 0 pendurada" % len(tabela))
    return len(penduradas)


def main():
    print("MONTAGEM — Xester")
    print("")
    total = 0
    for nomes, arquivo, rotulo in (
        (FORMA1, "Xester_Forma1_7_Tools.rbxmx",
         "Forma 1 — Xester, o Mestre das Cartas"),
        (FORMA2, "Xester_Forma2_7_Tools.rbxmx",
         "Forma 2 — Xester, O Despertar"),
    ):
        resultado = montar(nomes, os.path.join(TOOLS, arquivo), rotulo)
        if resultado is None:
            return 1
        total = total + resultado
        print("")
    if total:
        print("%d SharedString pendurada — o Studio recusaria o arquivo." % total)
        return 1
    print("Dois arquivos, um por forma, como pedido.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
