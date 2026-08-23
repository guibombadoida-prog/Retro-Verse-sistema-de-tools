#!/usr/bin/env python3
"""
remontar_tudo.py — Retro-Verse / Studios

Remonta TODOS os conjuntos e reconverte os binários, a partir do registro único
que já existe: o `CONJUNTOS` do `TESTES/verificar_rbxmx.py`.

    python3 FERRAMENTAS/remontar_tudo.py

POR QUE ELE EXISTE

    Cada conjunto tinha o seu caminho de montagem — `clonar_tool.py montar` com o
    modelo de origem, `montar_xester_v3.py`, `montar_collector.py` — e alguns
    modelos de origem já não existem com o nome de quando foram montados. Uma
    mudança que atinge as 94 Tools de uma vez (tirar o Núcleo, ligar o depósito
    de VFX) virava uma caça ao arquivo-base, conjunto por conjunto.

    A base de verdade nunca foi o modelo de entrada: é o `_ORIGEM.rbxmx` que
    cada Tool guarda dentro da própria pasta. `clonar_tool.montar` sempre leu
    de lá. Este script só junta as duas pontas que já existiam.

    O registro de conjuntos vive num lugar só — o verificador — e é ele que
    manda. Duplicar a lista aqui seria criar uma segunda verdade.
"""

import os
import re
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FERR = os.path.join(RAIZ, "FERRAMENTAS")
TOOLS = os.path.join(RAIZ, "Tools")

sys.path.insert(0, FERR)


def conjuntos():
    """(arquivo, modelo, [Tools]) — lidos do registro do verificador."""
    fonte = open(os.path.join(RAIZ, "TESTES", "verificar_rbxmx.py"),
                 encoding="utf-8").read()
    bloco = fonte.split("CONJUNTOS = [", 1)[1].split("\n]", 1)[0]
    saida = []
    for m in re.finditer(r'\("([^"]+\.rbxmx)",\s*"([^"]+)",\s*\[(.*?)\]\)',
                         bloco, re.S):
        nomes = re.findall(r'"([^"]+)"', m.group(3))
        saida.append((m.group(1), m.group(2), nomes))
    return saida


def converter(rbxmx):
    binario = rbxmx[: -len(".rbxmx")] + ".rbxm"
    r = subprocess.run(["python3", os.path.join(FERR, "converter_para_rbxm.py"),
                        rbxmx, binario], capture_output=True, text=True)
    return r.returncode == 0


def main():
    from clonar_tool import montar

    ruins = 0
    for arquivo, modelo, nomes in conjuntos():
        faltando = [n for n in nomes
                    if not os.path.exists(os.path.join(TOOLS, n, "_ORIGEM.rbxmx"))]
        if faltando:
            print("  %-30s SEM _ORIGEM: %s" % (modelo, ", ".join(faltando)))
            ruins = ruins + 1
            continue

        destino = os.path.join(TOOLS, arquivo)
        try:
            montar(nomes, destino)
        except Exception as erro:                                # noqa: BLE001
            print("  %-30s FALHOU: %s" % (modelo, erro))
            ruins = ruins + 1
            continue

        # o conjunto e cada Tool avulsa viram binário — o .rbxm é a entrega
        converter(destino)
        for n in nomes:
            avulso = os.path.join(TOOLS, n, "%s.rbxmx" % n)
            if os.path.exists(avulso):
                converter(avulso)

        print("  %-30s %2d Tool(s)  %8d bytes" % (
            modelo, len(nomes), os.path.getsize(destino)))

    print("")
    if ruins:
        print("%d conjunto(s) não remontados" % ruins)
    else:
        print("todos os conjuntos remontados e convertidos")
    return 1 if ruins else 0


if __name__ == "__main__":
    sys.exit(main())
