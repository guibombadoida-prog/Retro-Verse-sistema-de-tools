#!/usr/bin/env python3
"""
fundir_guest.py — Retro-Verse / Studios

Funde os dois arquivos do Guest num modelo único de 7 Tools:

    guest_tools.rbxmx          5 Tools  (Taco, Cano, Abacate, Energetico, Humilhador)
    guest_tools_2_more.rbxmx   2 Tools  (Diamond, A arma)
    →  Guest_Tools_7.rbxmx

POR QUE NÃO DÁ PARA CONCATENAR OS `<Item>` E PRONTO

    `referent` é único POR ARQUIVO, não globalmente. Os dois arquivos foram
    salvos pelo Studio em momentos diferentes, então quase certamente reusam os
    mesmos ids — e `<Ref>` aponta por esse id. Concatenar sem renomear faz um
    `Weld.Part0` da segunda Tool apontar para uma peça da primeira.

    Aqui o segundo arquivo é reetiquetado inteiro antes de entrar: todo
    `referent` ganha prefixo, e todo `<Ref>` que citava o id antigo é reescrito.

    O `<SharedStrings>` é IRMÃO dos `<Item>`, não descendente — o bloco dos dois
    arquivos é somado e reemitido no fim, senão o Studio recusa o arquivo.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRADA = os.path.join(RAIZ, "MODELOS_ENTRADA")

FONTES = [
    (os.path.join(ENTRADA, "Guest_Tools", "guest_tools.rbxmx"), ""),
    (os.path.join(ENTRADA, "Guest_Tools_V2", "guest_tools_2_more.rbxmx"), "V2_"),
]
DESTINO = os.path.join(ENTRADA, "Guest_Tools", "Guest_Tools_7.rbxmx")

# A ordem de entrega. As cinco primeiras são as remasterizadas; as duas últimas
# entram agora. Nome tal como vem da origem — a origem é a verdade.
ORDEM = [
    "Taco de Baseball",
    "Cano De Rua",
    "Abacate (roubado) do mexico",
    "Energetico",
    "Humilhador",
    "Diamond",
    "A arma",
]


def nome_de(item):
    for p in item.findall("./Properties/string"):
        if p.get("name") == "Name":
            return p.text or ""
    return ""


def reetiquetar(raiz, prefixo):
    """Prefixa todo `referent` e reescreve todo `<Ref>` que o citava."""
    if not prefixo:
        return 0
    trocados = 0
    for item in raiz.iter("Item"):
        antigo = item.get("referent")
        if antigo:
            item.set("referent", prefixo + antigo)
            trocados = trocados + 1
    for ref in raiz.iter("Ref"):
        alvo = (ref.text or "").strip()
        if alvo and alvo != "null":
            ref.text = prefixo + alvo
    return trocados


def nova_raiz():
    raiz = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(raiz, "Meta", {"name": "ExplicitAutoJoints"}).text = "true"
    ET.SubElement(raiz, "External").text = "null"
    ET.SubElement(raiz, "External").text = "nil"
    return raiz


def main():
    tabela = {}
    encontradas = {}

    for caminho, prefixo in FONTES:
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
        raiz = ET.parse(caminho).getroot()
        for e in raiz.iter("SharedString"):
            if e.get("md5"):
                tabela[e.get("md5")] = e.text or ""
        n = reetiquetar(raiz, prefixo)
        for item in raiz.findall("./Item"):
            if item.get("class") == "Tool":
                encontradas[nome_de(item)] = item
        print("%-28s %d Tool(s)%s"
              % (os.path.basename(caminho),
                 len([i for i in raiz.findall("./Item") if i.get("class") == "Tool"]),
                 ("  · %d referent reetiquetado" % n) if n else ""))

    faltando = [n for n in ORDEM if n not in encontradas]
    if faltando:
        print("Tool(s) que a ORDEM pede e a origem não tem: %s" % ", ".join(faltando))
        return 1
    sobrando = [n for n in encontradas if n not in ORDEM]
    if sobrando:
        print("Tool(s) na origem fora da ORDEM: %s" % ", ".join(sobrando))
        return 1

    saida = nova_raiz()
    for nome in ORDEM:
        saida.append(encontradas[nome])

    # O <SharedStrings> é irmão dos <Item>. Sem ele o Studio recusa o arquivo.
    citadas = sorted({(e.text or "").strip()
                      for e in saida.iter("SharedString") if e.get("name")})
    citadas = [c for c in citadas if c]
    penduradas = []
    if citadas:
        bloco = ET.SubElement(saida, "SharedStrings")
        for md5 in citadas:
            if md5 in tabela:
                ET.SubElement(bloco, "SharedString", {"md5": md5}).text = tabela[md5]
            else:
                penduradas.append(md5)

    ET.ElementTree(saida).write(DESTINO, encoding="utf-8", xml_declaration=True)
    print("%s  —  %d bytes  ·  %d Tools  ·  %d SharedString"
          % (os.path.relpath(DESTINO, RAIZ), os.path.getsize(DESTINO),
             len(ORDEM), len(citadas)))
    if penduradas:
        print("   ⚠️  %d SharedString PENDURADA: %s"
              % (len(penduradas), ", ".join(penduradas)))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
