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

O AJUSTE DO `Content` VAZIO

    `<Content name="LinkedSource"></Content>` sem filho é aceito pelo Studio e
    recusado pelo `rbx-dom`. O conversor fecha com `<null></null>` antes de
    entregar. Foi o que impediu o conjunto dos Escudos de virar `.rbxm`.

O AJUSTE DO `Tags`

    O Studio grava `Tags` como `SharedString`; o `rbx-dom` aceita `Tags` como
    String/Content/Tags/Attributes/MaterialColors/BinaryString, e recusa
    SharedString. A conversão troca por `BinaryString`.

    A CARGA VAI JUNTO. A `SharedString` guarda base64, e o `BinaryString`
    também: copiar o texto de um para o outro troca o invólucro e preserva a
    tag. Tag de CollectionService é comportamento de jogo, e agora ela
    atravessa em vez de derrubar a conversão.

    O que ainda PARA tudo é md5 citada sem entrada na tabela `<SharedStrings>`:
    aí não existe valor para carregar, e escrever vazio seria justamente a
    perda silenciosa que este guarda existe para impedir.
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

    # Tag COM conteúdo não para mais a conversão: ela ATRAVESSA.
    #
    # Antes este bloco abortava, porque descartar tag de CollectionService é
    # mudar comportamento de jogo. Só que descartar nunca foi a única saída — o
    # `rbx-dom` aceita `Tags` como `BinaryString`, e a carga de uma
    # `SharedString` é o mesmo base64 que um `BinaryString` guarda. Copiar o
    # texto de um para o outro é troca de INVÓLUCRO, não de valor.
    #
    # O que continua parando a conversão é md5 citada sem entrada na tabela:
    # aí não há valor para carregar, e escrever vazio seria a perda silenciosa
    # que este guarda existe para impedir.
    orfas = []
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in list(props):
            if e.tag != "SharedString" or e.get("name") != "Tags":
                continue
            md5 = (e.text or "").strip()
            if md5 and md5 not in tabela:
                orfas.append((item.get("class"), md5))

    if orfas:
        print("PAREI: Tags citando SharedString que a tabela não resolve.")
        print("Sem valor para carregar, escrever vazio seria perder a tag calado.")
        for classe, md5 in orfas[:6]:
            print("  %-16s %s" % (classe, md5))
        return None

    # `<Content name="X"></Content>` SEM filho derruba o rbx_xml em
    # UnexpectedXmlEvent(EndElement(Content)). O Studio aceita e grava assim —
    # 35 `LinkedSource` vazios no conjunto dos Escudos — mas o formato pede
    # `<null></null>` dentro. Sem isto o conjunto nunca converte para binário.
    remendados = 0
    for elemento in raiz.iter("Content"):
        if len(elemento) == 0:
            ET.SubElement(elemento, "null")
            elemento.text = None
            remendados = remendados + 1
    if remendados:
        print("   %d Content vazio(s) fechado(s) com <null/>" % remendados)

    trocadas, com_carga = 0, 0
    for item in raiz.iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        for e in list(props):
            if e.tag == "SharedString" and e.get("name") == "Tags":
                md5 = (e.text or "").strip()
                carga = tabela.get(md5, "") if md5 else ""
                props.remove(e)
                ET.SubElement(props, "BinaryString",
                              {"name": "Tags"}).text = carga
                trocadas = trocadas + 1
                if carga:
                    com_carga = com_carga + 1

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

    return (trocadas, com_carga)


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
    contagem = preparar(entrada, temporario)
    if contagem is None:
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
    trocadas, com_carga = contagem
    if com_carga:
        print("   %d Tags de CollectionService COM conteúdo, carregada(s) "
              "inteira(s)" % com_carga)
    print("   %d propriedade(s) Tags trocada(s) de SharedString para BinaryString"
          % trocadas)
    return 0


if __name__ == "__main__":
    sys.exit(main())
