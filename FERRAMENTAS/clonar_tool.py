#!/usr/bin/env python3
"""
clonar_tool.py — Retro-Verse / Studios

Clona Tools de um `.rbxmx` de origem **sem remontar nada**.

    python3 FERRAMENTAS/clonar_tool.py extrair <origem.rbxmx>
    python3 FERRAMENTAS/clonar_tool.py montar  <origem.rbxmx> <destino.rbxmx>

POR QUE ESTA FERRAMENTA EXISTE, E POR QUE ELA NÃO É O montar_rbxmx.py

    O `montar_rbxmx.py` CONSTRÓI a Tool: Handle com primitivas, Values, SFX,
    emissores. Serve para Tool autoral, nascida aqui.

    Não serve para Tool que CHEGA pronta. Usá-lo para isso foi o erro da leva
    anterior: o modelo vinha com `SpecialMesh` próprio e eu remontei um escudo
    em código. Passava em todo verificador e entregava outra coisa.

    Aqui a regra é outra: **o `.rbxmx` de origem é a verdade**. Handle, Mesh,
    Model, Sound, Value, hierarquia — nada disso é tocado. A única coisa que
    esta ferramenta escreve de volta é o `Source` dos scripts, e só dos que
    existirem como `.lua` na pasta da Tool.

    extrair  origem .rbxmx  →  Tools/<Nome>/*.lua   (para revisar e versionar)
    montar   os .lua        →  .rbxmx, com TUDO O MAIS vindo da origem intacto
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")


def prop(item, nome):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == nome:
            return e
    return None


def texto(item, nome):
    e = prop(item, nome)
    if e is None:
        return None
    u = e.find("url")
    return u.text if u is not None else e.text


def nome_arquivo(caminho):
    """Nome de arquivo estável a partir do caminho do script dentro da Tool."""
    limpo = re.sub(r"[^\w/]", "_", caminho)
    return limpo.replace("/", "__") + ".lua"


def percorrer(item, caminho=""):
    """Emite (item, caminho) de todo script descendente."""
    nome = texto(item, "Name") or item.get("class")
    atual = (caminho + "/" + nome) if caminho else nome
    if item.get("class") in CLASSES_SCRIPT:
        yield item, atual
    for filho in item.findall("Item"):
        for par in percorrer(filho, atual):
            yield par


def tools_de(caminho):
    raiz = ET.parse(caminho).getroot()
    return raiz, [i for i in raiz.findall("Item") if i.get("class") == "Tool"]


def extrair(origem):
    raiz, tools = tools_de(origem)
    if not tools:
        print("nenhuma Tool na raiz de %s" % origem)
        return 1

    for tool in tools:
        nome = texto(tool, "Name")
        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)

        n = 0
        for item, caminho in percorrer(tool):
            fonte = texto(item, "Source")
            if fonte is None:
                continue
            # o caminho relativo à Tool, para o arquivo bater na volta
            relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
            destino = os.path.join(pasta, nome_arquivo(relativo))
            with open(destino, "w", encoding="utf-8") as f:
                f.write(fonte)
            n = n + 1

        # a origem fica guardada: é ela que o `montar` usa como base
        base = os.path.join(pasta, "_ORIGEM.rbxmx")
        sub = ET.Element("roblox", {
            "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
            "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
            "version": "4",
        })
        ET.SubElement(sub, "External").text = "null"
        ET.SubElement(sub, "External").text = "nil"
        sub.append(tool)
        ET.ElementTree(sub).write(base, encoding="utf-8", xml_declaration=False)

        print("%-22s %2d scripts  →  Tools/%s/" % (nome, n, nome))
    return 0


def envolver_cdata(texto_xml):
    def trocar(m):
        corpo = m.group(1)
        corpo = (corpo.replace("&lt;", "<").replace("&gt;", ">")
                      .replace("&quot;", '"').replace("&#10;", "\n")
                      .replace("&amp;", "&"))
        return '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % corpo

    return re.sub(r'<ProtectedString name="Source">(.*?)</ProtectedString>',
                  trocar, texto_xml, flags=re.S)


def nova_raiz():
    raiz = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(raiz, "External").text = "null"
    ET.SubElement(raiz, "External").text = "nil"
    return raiz


def escrever(raiz, destino):
    ET.ElementTree(raiz).write(destino, encoding="utf-8", xml_declaration=False)
    with open(destino, encoding="utf-8") as f:
        conteudo = f.read()
    with open(destino, "w", encoding="utf-8") as f:
        f.write(envolver_cdata(conteudo))


PACK_VFX = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Stella_VFX_Addon",
                        "VFX", "PACK_VFX.rbxmx")


def enxertar_pack(tool):
    """
    Copia o pack de VFX do Acervo PARA DENTRO do VFXModule da Tool.

    Regra nº 1: o efeito é filho da Tool, ponto. O Acervo é prateleira de
    edição — o material sai de lá e entra na Tool na montagem, nunca é lido
    de lá em runtime.

    Devolve quantos efeitos entraram.
    """
    if not os.path.exists(PACK_VFX):
        return 0

    modulo = None
    for item, _caminho in percorrer(tool):
        if texto(item, "Name") == "VFXModule":
            modulo = item
            break
    if modulo is None:
        return 0

    # Enxerto é idempotente: montar duas vezes não empilha dois packs.
    for filho in list(modulo.findall("Item")):
        if texto(filho, "Name") == "Pack":
            modulo.remove(filho)

    pack = ET.parse(PACK_VFX).getroot().find("Item")
    if pack is None:
        return 0

    # referent tem de ser único dentro do arquivo montado: dois iguais fazem o
    # Studio religar propriedade no objeto errado. Como o mesmo pack entra em
    # 7 Tools, cada cópia ganha um sufixo.
    enxerto = ET.fromstring(ET.tostring(pack))
    marca = texto(tool, "Name").replace(" ", "")
    for no in enxerto.iter("Item"):
        ref = no.get("referent")
        if ref:
            no.set("referent", "%s_%s" % (ref, marca))

    modulo.append(enxerto)
    return len([i for i in enxerto.findall("Item")
                if i.get("class") == "ModuleScript"])


def montar(nomes, destino):
    """
    Monta o .rbxmx de entrega a partir dos _ORIGEM.rbxmx de cada Tool,
    reescrevendo SÓ o Source dos scripts que existem como .lua na pasta, e
    enxertando o pack de VFX do Acervo dentro do VFXModule.

    Sai um arquivo por Tool (REGRA_ENTREGA_RBXMX: uma Tool, um arquivo, pronto
    para arrastar) e mais o conjunto com as Tools do modelo todo.
    """
    raiz = nova_raiz()
    trocados, mantidos, enxertados = 0, 0, 0
    for nome in nomes:
        pasta = os.path.join(TOOLS, nome)
        base = os.path.join(pasta, "_ORIGEM.rbxmx")
        if not os.path.exists(base):
            print("sem _ORIGEM.rbxmx em Tools/%s — rode `extrair` antes" % nome)
            return 1

        sub = ET.parse(base).getroot()
        tool = sub.find("Item")

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

        # Uma Tool, um arquivo — é assim que ela chega no Studio.
        sozinha = nova_raiz()
        sozinha.append(tool)
        individual = os.path.join(pasta, "%s.rbxmx" % nome)
        escrever(sozinha, individual)

        raiz.append(tool)

    escrever(raiz, destino)

    print("%s  —  %d bytes" % (os.path.relpath(destino, RAIZ),
                               os.path.getsize(destino)))
    print("   %d arquivo(s) individual(is) em Tools/<Nome>/<Nome>.rbxmx" % len(nomes))
    print("   %d script(s) vindos do .lua, %d mantidos como na origem"
          % (trocados, mantidos))
    print("   %d efeito(s) do pack enxertados DENTRO das Tools (Regra nº 1)"
          % enxertados)
    print("   Handle, Mesh, Model, Sound e Value: intactos, da origem")
    return 0


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    acao = sys.argv[1]
    if acao == "extrair":
        return extrair(sys.argv[2])
    if acao == "montar":
        origem = sys.argv[2]
        destino = sys.argv[3] if len(sys.argv) > 3 else None
        _, tools = tools_de(origem)
        nomes = [texto(t, "Name") for t in tools]
        return montar(nomes, destino or os.path.join(TOOLS, "Conjunto.rbxmx"))
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
