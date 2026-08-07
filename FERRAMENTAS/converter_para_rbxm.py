#!/usr/bin/env python3
"""
converter_para_rbxm.py — Retro-Verse / Studios

Converte um `.rbxmx` (XML) em `.rbxm` (BINÁRIO), usando o `rbx-dom` — a
implementação de referência do formato, a mesma que o Rojo usa.

    python3 FERRAMENTAS/converter_para_rbxm.py <entrada.rbxmx> [saida.rbxm]

POR QUE NÃO ESCREVER O SERIALIZADOR AQUI

    `.rbxm` não é `.rbxmx` renomeado. É formato de chunks (META, SSTR, INST,
    PROP, PRNT, END) com as propriedades TRANSPOSTAS por classe e codificação
    intercalada — int32 em zigzag, referente em delta acumulado, float com
    rotação de bit. Escrever isso à mão é arriscar um encoding sutilmente
    errado: o Studio recusa o arquivo, ou pior, aceita e religa propriedade no
    objeto errado sem avisar.

    O binário `xmx2rbxm` é um wrapper de ~15 linhas sobre `rbx_xml` +
    `rbx_binary`. Se ele não estiver compilado, este script diz como compilar
    e sai — nunca inventa um arquivo binário por conta própria.

O AJUSTE DO `Tags`

    O Studio grava `Tags` como `SharedString`; o `rbx-dom` aceita `Tags` como
    String/Content/Tags/Attributes/MaterialColors/BinaryString, e recusa
    SharedString. A conversão troca por `BinaryString`.

    E SÓ TROCA SE O VALOR COMPARTILHADO FOR VAZIO. Tag de CollectionService é
    comportamento de jogo: se alguma vier com conteúdo, este script PARA e
    avisa, em vez de descartar em silêncio.
"""

import base64
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Compilar com:
#   cargo build --release        (num crate com rbx_dom_weak, rbx_xml, rbx_binary)
CONVERSOR = os.environ.get("XMX2RBXM", "")


def achar_conversor():
    if CONVERSOR and os.path.exists(CONVERSOR):
        return CONVERSOR
    for base in (os.path.join(RAIZ, "FERRAMENTAS", "bin", "xmx2rbxm"),
                 "/usr/local/bin/xmx2rbxm"):
        if os.path.exists(base):
            return base
    return None


def preparar(entrada, temporario):
    """Troca SharedString/Tags por BinaryString vazio. Devolve quantas trocou."""
    raiz = ET.parse(entrada).getroot()

    tabela = {}
    for e in raiz.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text or ""

    perigosas = []
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in list(props):
            if e.tag != "SharedString" or e.get("name") != "Tags":
                continue
            md5 = (e.text or "").strip()
            bruto = tabela.get(md5, "")
            try:
                conteudo = base64.b64decode(bruto) if bruto else b""
            except Exception:
                conteudo = b"?"
            if conteudo:
                perigosas.append((item.get("class"), md5, conteudo[:40]))

    if perigosas:
        print("PAREI: há Tags de CollectionService COM CONTEÚDO.")
        print("Descartar tag é mudar comportamento de jogo — não faço isso calado.")
        for classe, md5, amostra in perigosas[:6]:
            print("  %-16s %s  %r" % (classe, md5, amostra))
        return None

    trocadas = 0
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in list(props):
            if e.tag == "SharedString" and e.get("name") == "Tags":
                props.remove(e)
                ET.SubElement(props, "BinaryString", {"name": "Tags"}).text = ""
                trocadas = trocadas + 1

    ET.ElementTree(raiz).write(temporario, encoding="utf-8", xml_declaration=False)

    # o Source volta para CDATA: sem isso o Lua vira entidade XML escapada
    with open(temporario, encoding="utf-8") as f:
        texto = f.read()

    def envolver(m):
        c = m.group(1)
        c = (c.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"')
              .replace("&#10;", "\n").replace("&amp;", "&"))
        return '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % c

    texto = re.sub(r'<ProtectedString name="Source">(.*?)</ProtectedString>',
                   envolver, texto, flags=re.S)
    with open(temporario, "w", encoding="utf-8") as f:
        f.write(texto)

    return trocadas


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    entrada = sys.argv[1]
    saida = sys.argv[2] if len(sys.argv) > 2 else (
        os.path.splitext(entrada)[0] + ".rbxm")

    conversor = achar_conversor()
    if not conversor:
        print("conversor `xmx2rbxm` não encontrado.")
        print("Compile um crate com rbx_dom_weak + rbx_xml + rbx_binary e")
        print("aponte a variável XMX2RBXM para o binário, ou ponha em")
        print("FERRAMENTAS/bin/xmx2rbxm.")
        print("")
        print("NÃO gero .rbxm sem ele: escrever o binário na mão é arriscar um")
        print("encoding errado que o Studio aceita mangled, sem avisar.")
        return 1

    temporario = saida + ".preparado.rbxmx"
    trocadas = preparar(entrada, temporario)
    if trocadas is None:
        if os.path.exists(temporario):
            os.remove(temporario)
        return 1

    resultado = subprocess.run([conversor, temporario, saida],
                               capture_output=True, text=True)
    if os.path.exists(temporario):
        os.remove(temporario)

    if resultado.returncode != 0:
        print("conversão falhou:")
        print(resultado.stdout.strip())
        print(resultado.stderr.strip())
        if os.path.exists(saida):
            # a escrita pode ter deixado um arquivo TRUNCADO. Ele não fica.
            os.remove(saida)
            print("(o .rbxm parcial foi removido — arquivo truncado não é entrega)")
        return 1

    print("%s  —  %d bytes" % (os.path.relpath(saida, RAIZ),
                               os.path.getsize(saida)))
    print("   %d propriedade(s) Tags trocada(s) de SharedString para BinaryString"
          % trocadas)
    return 0


if __name__ == "__main__":
    sys.exit(main())
