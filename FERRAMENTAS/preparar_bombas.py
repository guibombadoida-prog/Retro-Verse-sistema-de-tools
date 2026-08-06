#!/usr/bin/env python3
"""
preparar_bombas.py — Retro-Verse / Studios

Prepara a base de assets do `bomba_v4.rbxmx` para as 6 Tools do conjunto BOMBAS.

    python3 FERRAMENTAS/preparar_bombas.py

O modelo é pequeno e limpo: Handle (MeshPart) com `Explode` e `Throw`, cada um
com seu `DistortionSoundEffect`. Não há nada a resgatar de dentro de script —
diferente do AstralPeriastron, aqui o visual já está no lugar certo.

O que sai: os 3 scripts do original (o Server dele tem `require(8199013483)`,
id numérico, que é execução de código remoto).

O que entra: scripts autorais vazios (o Source vem do .lua), `VFXRemote`, e os
Values que a Tool usa para DECLARAR o que é.

NENHUMA das 6 tem habilidade Extra — por isso **não** existe `AcaoRemote` aqui.
`Tool.Activated` já dispara no toque do ícone da Tool, em qualquer plataforma,
então o celular está coberto sem botão nenhum.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Bomba_V4", "bomba_v4.rbxmx")

# nome, tooltip, DamageClass, energia, recarga global, chave de recarga
CONJUNTO = [
    ("Multiplas Bombas",
     "Lanca uma bomba que estoura em 3 mini bombas.",
     "EXPLOSIVO", 0, 0, "Bomba_Multipla"),
    ("Bomba Nuclear",
     "Uma nuke. Cogumelo, clarao e onda de choque em tres aneis.",
     "EXPLOSIVO", 30, 45, "Bomba_Nuclear"),
    ("Bomba Meteorica",
     "Chama um meteoro que cai na diagonal e espalha 10 mini bombas.",
     "EXPLOSIVO", 22, 26, "Bomba_Meteorica"),
    ("Bomba Basquete",
     "Arremessa e quica 3 vezes antes de estourar.",
     "EXPLOSIVO", 8, 6, "Bomba_Basquete"),
    ("Bomba Doida",
     "Solta 2 bombas-NPC kamikaze. Sem alvo, ficam bravas e aceleram.",
     "EXPLOSIVO", 25, 30, "Bomba_Doida"),
    ("Bomba Gelada",
     "Congela quem pega e deixa um chao de gelo escorregadio.",
     "GELO", 14, 14, "Bomba_Gelada"),
]

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
PROIBIDAS = ("ScreenGui", "Animation")


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


def definir(item, tag, nome, valor):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    for e in props:
        if e.get("name") == nome:
            e.text = valor
            return
    ET.SubElement(props, tag, {"name": nome}).text = valor


def podar(item, removidos):
    for filho in list(item.findall("Item")):
        classe = filho.get("class")
        if classe in CLASSES_SCRIPT or classe in PROIBIDAS:
            removidos.append((classe, texto(filho, "Name") or classe))
            item.remove(filho)
            continue
        podar(filho, removidos)
    return item


def novo_item(pai, classe, nome, referent):
    item = ET.SubElement(pai, "Item", {"class": classe, "referent": referent})
    props = ET.SubElement(item, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = nome
    return item, props


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


def equipar(tool, nome, tooltip, classe_dano, energia, recarga, chave):
    marca = nome.replace(" ", "")

    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # O RemoteEvent do original vira o VFXRemote: o servidor transmite o tipo
    # de efeito, quem desenha é o cliente (§12.11).
    for filho in list(tool.findall("Item")):
        if filho.get("class") == "RemoteEvent":
            tool.remove(filho)
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFX_%s" % marca)

    # SEM AcaoRemote: nenhuma das 6 tem habilidade Extra.

    _i, props = novo_item(tool, "StringValue", "DamageClass", "RV_DC_%s" % marca)
    ET.SubElement(props, "string", {"name": "Value"}).text = classe_dano
    _i, props = novo_item(tool, "StringValue", "ChaveRecarga", "RV_CR_%s" % marca)
    ET.SubElement(props, "string", {"name": "Value"}).text = chave
    _i, props = novo_item(tool, "NumberValue", "EnergyCost", "RV_EC_%s" % marca)
    ET.SubElement(props, "float", {"name": "Value"}).text = str(energia)
    _i, props = novo_item(tool, "NumberValue", "RecargaGlobal", "RV_RG_%s" % marca)
    ET.SubElement(props, "float", {"name": "Value"}).text = str(recarga)

    criados = []
    for classe, alvo in (
        ("Script", "%s_Server_V1" % nome),
        ("LocalScript", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ):
        item, props = novo_item(tool, classe, alvo,
                                "RV_%s_%s" % (alvo.replace(" ", ""), marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""
        criados.append(alvo)
    return criados


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1

    fonte = ET.parse(ORIGEM).getroot()
    tools = [i for i in fonte.findall("Item") if i.get("class") == "Tool"]
    if len(tools) != 1:
        print("esperava 1 Tool na origem, achei %d" % len(tools))
        return 1
    base = tools[0]

    tabela = {}
    for e in fonte.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text or ""

    print("PREPARAÇÃO DA BASE — bomba_v4")
    print("")

    for indice, dados in enumerate(CONJUNTO):
        nome, tooltip, classe_dano, energia, recarga, chave = dados
        copia = ET.fromstring(ET.tostring(base))

        removidos = []
        podar(copia, removidos)
        definir(copia, "string", "Name", nome)
        equipar(copia, nome, tooltip, classe_dano, energia, recarga, chave)

        marca = nome.replace(" ", "")
        renomeado = {}
        for no in copia.iter("Item"):
            ref = no.get("referent")
            if ref:
                novo = "%s_%s" % (ref, marca)
                renomeado[ref] = novo
                no.set("referent", novo)
        for no in copia.iter("Item"):
            props = no.find("Properties")
            if props is None:
                continue
            for e in props:
                if e.tag == "Ref" and (e.text or "").strip() in renomeado:
                    e.text = renomeado[(e.text or "").strip()]

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)

        raiz = nova_raiz()
        raiz.append(copia)

        citadas = [t for t in sorted({(e.text or "").strip()
                                      for e in raiz.iter("SharedString")
                                      if e.get("name")}) if t]
        if citadas:
            bloco = ET.SubElement(raiz, "SharedStrings")
            for md5 in citadas:
                ET.SubElement(bloco, "SharedString",
                              {"md5": md5}).text = tabela.get(md5, "")

        ET.ElementTree(raiz).write(os.path.join(pasta, "_ORIGEM.rbxmx"),
                                   encoding="utf-8", xml_declaration=False)

        if indice == 0:
            print("  Removido da origem:")
            for classe, alvo in removidos:
                print("    %-14s %s" % (classe, alvo))
            print("")

        print("  %-22s → Tools/%s/" % (nome, nome))

    print("")
    print("%d Tool(s) preparada(s). Nenhum script da origem entrou." % len(CONJUNTO))
    print("Sem AcaoRemote: nenhuma tem habilidade Extra.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
