#!/usr/bin/env python3
"""
preparar_gravidade.py — Retro-Verse / Studios

Monta o modelo de **7 Tools de gravidade telecinética** a partir das 5 do
`calebe_tools.rbxmx`.

    python3 FERRAMENTAS/preparar_gravidade.py

CINCO HANDLES, SETE TOOLS

    O modelo traz 5 Tools; o pedido são 7. Duas nascem CLONANDO o Handle de uma
    irmã — o mesmo caminho do conjunto Astral, onde 5 Tools saíram de um modelo
    só. O que se clona é a GEOMETRIA; a habilidade de cada uma é escrita aqui.

    | Alvo                        | Handle vem de   | Por quê                       |
    |-----------------------------|-----------------|-------------------------------|
    | Tremores da Gravidade       | Quake Hammer    | martelo, e o tema é tremor    |
    | Controlador da Gravidade    | Gravitron 1000  | é literalmente o controlador  |
    | Telecinese Levitacao        | CosmosStaff     | cajado de força, que ergue    |
    | Lancador de Objetos         | detainer        | a garra que pega e arremessa  |
    | Asas Telecineticas          | CosmosStaff     | **clone** — asas são projeção |
    | Terremoto                   | Quake Hammer    | **clone** — o martelo pesado  |
    | Telecinese Gravitacional    | GravityHammer   | o martelo de gravidade        |

A REGRA QUE MANDA NESTE CONJUNTO: **NINGUÉM TOCA EM `workspace.Gravity`**

    O `Gravitron 1000` original ciclava `workspace.Gravity` entre 21.2, 471.2 e
    196.2 — e o `Unequipped` dele NÃO devolvia. Equipar, clicar e guardar
    deixava o servidor inteiro em gravidade 21.2, para sempre. Não havia
    `Tool.Destroying`.

    Gravidade é propriedade GLOBAL do servidor. Uma Tool que a escreve está
    escrevendo no estado de todo mundo, e a Regra nº 1 vale nos dois sentidos:
    a Tool não lê de fora, e não sequestra o que é de fora.

    Aqui a gravidade é sempre POR ALVO, e sempre dentro da Tool: `BodyVelocity`
    e `BodyPosition` com prazo no `Debris`, num alvo por vez. O efeito visual é
    o mesmo; o estrago quando algo dá errado é zero.

O QUE SAI DE CADA TOOL DE ORIGEM

    Script, LocalScript, Animation, ScreenGui, Camera, RemoteFunction e as
    pastas de UI. Fica a GEOMETRIA: Handle, mesh, Attachment, ParticleEmitter,
    Beam, Motor6D, constraint — e todo `Sound`, que é resgatado antes.

    `Sound` e emissor que moravam DENTRO de um script seriam levados junto com
    ele. Os dois são resgatados primeiro: som vai para o `Handle`, emissor para
    uma pasta `Efeitos`.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Calebe_Tools", "calebe_tools.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Calebe_Tools",
                       "Gravidade_7_Tools.rbxmx")

# alvo · Handle de origem · tooltip · DamageClass · energia · recarga · chave ·
# tecla da Extra
CONJUNTO = [
    ("Tremores da Gravidade", "Quake Hammer",
     "Bate o chão e a onda corre; a Extra sustenta o tremor",
     "Gravidade", 0, 4, "Gravidade_Tremores", "R"),

    ("Controlador da Gravidade", "Gravitron 1000",
     "Inverte a gravidade de quem estiver no ponto; a Extra esmaga",
     "Gravidade", 0, 9, "Gravidade_Controlador", "R"),

    ("Telecinese Levitacao", "CosmosStaff",
     "Ergue o alvo e o deixa indefeso; a Extra ergue você",
     "Telecinese", 0, 8, "Gravidade_Levitacao", "R"),

    ("Lancador de Objetos", "detainer",
     "Agarra destroço e arremessa; a Extra dispara a rajada",
     "Telecinese", 0, 3, "Gravidade_Lancador", "R"),

    ("Asas Telecineticas", "CosmosStaff",
     "Bate as asas e sobe empurrando; a Extra mergulha",
     "Telecinese", 0, 5, "Gravidade_Asas", "R"),

    ("Terremoto", "Quake Hammer",
     "Rachadura que corre à frente; a Extra é o colapso",
     "Gravidade", 0, 7, "Gravidade_Terremoto", "R"),

    ("Telecinese Gravitacional", "GravityHammer",
     "Puxa todos para o ponto mirado; a Extra colapsa em singularidade",
     "Telecinese", 0, 12, "Gravidade_Gravitacional", "R"),
]

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
# o que não sobrevive à conversão
CLASSES_FORA = CLASSES_SCRIPT + ("Animation", "ScreenGui", "Camera",
                                 "RemoteFunction", "RemoteEvent",
                                 "BillboardGui")
# resgatados de dentro do que vai ser removido
CLASSES_SOM = ("Sound",)
CLASSES_EFEITO = ("ParticleEmitter", "Beam", "Trail")


def props(item):
    p = item.find("Properties")
    if p is None:
        p = ET.SubElement(item, "Properties")
    return p


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
    e = prop(item, nome)
    if e is None:
        e = ET.SubElement(props(item), tag, {"name": nome})
    e.tag = tag
    e.text = valor
    return e


ID_ANTIGO = re.compile(r"^\s*https?://(?:www\.)?roblox\.com/[Aa]sset/?\?[Ii][Dd]=(\d+)\s*$")


def normalizar_som(som):
    """
    `http://www.roblox.com/asset/?id=N`  ->  `rbxassetid://N`

    A forma antiga ainda toca no Roblox, mas o resto do repositório fala
    `rbxassetid://`, e `TESTES/verificar_rbxmx.py` cobra essa forma — um id
    escrito de outro jeito passa despercebido quando alguém for procurar.

    E o modelo de origem tem TRÊS ids com **espaço no fim**
    (`...48577295 `). Espaço em URL não é erro que apareça: o som só não toca.
    O `strip()` aqui é o conserto.
    """
    campo = prop(som, "SoundId")
    if campo is None:
        return None
    u = campo.find("url")
    bruto = (u.text if u is not None else campo.text) or ""
    limpo = bruto.strip()
    m = ID_ANTIGO.match(limpo)
    if m:
        limpo = "rbxassetid://%s" % m.group(1)
    if limpo == bruto:
        return None
    for filho in list(campo):
        campo.remove(filho)
    campo.text = None
    ET.SubElement(campo, "url").text = limpo
    return limpo


def novo_item(pai, classe, nome, referente):
    item = ET.SubElement(pai, "Item", {"class": classe, "referent": referente})
    p = ET.SubElement(item, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    return item, p


def achar(pai, classe=None, nome=None):
    for f in pai.findall("Item"):
        if classe and f.get("class") != classe:
            continue
        if nome is not None and texto(f, "Name") != nome:
            continue
        return f
    return None


def pares(item):
    """(pai, filho) de toda a subárvore, de baixo para cima."""
    for filho in item.findall("Item"):
        for par in pares(filho):
            yield par
        yield item, filho


def reetiquetar(tool, prefixo):
    """
    Prefixa todo `referent` da Tool e reescreve todo `<Ref>` que o citava.

    Sem isto, as duas Tools clonadas do mesmo Handle entram no arquivo com os
    MESMOS ids, e `Weld.Part0` de uma passa a apontar para peça da outra.
    """
    mapa = {}
    for item in tool.iter("Item"):
        antigo = item.get("referent")
        if antigo:
            novo = prefixo + antigo
            mapa[antigo] = novo
            item.set("referent", novo)
    for ref in tool.iter("Ref"):
        alvo = (ref.text or "").strip()
        if alvo in mapa:
            ref.text = mapa[alvo]
    return len(mapa)


def limpar(tool, marca):
    """
    Tira da Tool tudo que não é geometria, resgatando som e emissor antes.

    Devolve (sons resgatados, emissores resgatados, nós removidos).
    """
    handle = achar(tool, nome="Handle")
    if handle is None:
        for _pai, filho in pares(tool):
            if texto(filho, "Name") == "Handle":
                handle = filho
                break
    if handle is None:
        return 0, 0, 0

    # 1. RESGATE, antes de qualquer remoção: som e emissor que moram dentro de
    #    um script sumiriam junto com ele.
    condenados = set()
    for _pai, filho in pares(tool):
        if filho.get("class") in CLASSES_FORA:
            for dentro in filho.iter("Item"):
                condenados.add(id(dentro))

    sons, efeitos = [], []
    for pai, filho in list(pares(tool)):
        if id(filho) not in condenados:
            continue
        if filho.get("class") in CLASSES_SOM:
            pai.remove(filho)
            sons.append(filho)
        elif filho.get("class") in CLASSES_EFEITO:
            pai.remove(filho)
            efeitos.append(filho)

    # todo Sound da Tool vai para o Handle: é onde `tocar` procura, e é o que
    # mantém o §12.10 simples nas sete
    for pai, filho in list(pares(tool)):
        if filho.get("class") in CLASSES_SOM and pai is not handle:
            pai.remove(filho)
            sons.append(filho)

    # 2. remoção
    removidos = 0
    for pai, filho in list(pares(tool)):
        if filho.get("class") in CLASSES_FORA:
            pai.remove(filho)
            removidos = removidos + 1

    # pastas que só existiam para segurar UI ficam vazias — saem também
    for pai, filho in list(pares(tool)):
        if filho.get("class") == "Folder" and not filho.findall("Item"):
            pai.remove(filho)
            removidos = removidos + 1

    # 3. devolução
    vistos = set()
    for som in sons:
        nome_som = texto(som, "Name") or "Som"
        base, n = nome_som, 2
        while nome_som in vistos:
            nome_som = "%s%d" % (base, n)
            n = n + 1
        vistos.add(nome_som)
        definir(som, "string", "Name", nome_som)
        handle.append(som)

    # id no formato do repositório, e sem o espaço que veio da origem
    for _pai, filho in pares(tool):
        if filho.get("class") in CLASSES_SOM:
            normalizar_som(filho)

    if efeitos:
        pasta, _p = novo_item(tool, "Folder", "Efeitos", "GR_EF_%s" % marca)
        for i, efeito in enumerate(efeitos):
            pasta.append(efeito)

    return len(sons), len(efeitos), removidos


def equipar(tool, dados, marca):
    (nome, _origem, tooltip, classe_dano, energia, recarga, chave, tecla) = dados

    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # Handle como filho DIRETO — exigência do Roblox para RequiresHandle
    if achar(tool, nome="Handle") is None:
        for pai, filho in list(pares(tool)):
            if texto(filho, "Name") == "Handle":
                pai.remove(filho)
                tool.append(filho)
                break

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", str(energia)),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, p = novo_item(tool, classe, alvo, "GR_%s_%s" % (alvo[:6], marca))
        ET.SubElement(p, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "GR_VFXR_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "GR_ACAO_%s" % marca)

    objeto = "%s_Server_V1" % nome.replace(" ", "")
    for classe, alvo in (("Script", objeto),
                         ("Script", "Client"),
                         ("ModuleScript", "R6CFrameAnimator"),
                         ("ModuleScript", "Poses"),
                         ("ModuleScript", "VFXModule")):
        item, p = novo_item(tool, classe, alvo,
                            "GR_%s_%s" % (alvo.replace(" ", "")[:12], marca))
        ET.SubElement(p, "ProtectedString", {"name": "Source"}).text = ""
        if alvo == "Client":
            # RunContext = Client (2), NÃO LocalScript. LocalScript dentro de
            # Tool só roda para quem a segura, e o VFX some para a sala.
            ET.SubElement(p, "token", {"name": "RunContext"}).text = "2"
    return objeto


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
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1

    fonte = ET.parse(ORIGEM).getroot()
    tabela = {}
    for e in fonte.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text or ""

    moldes = {}
    for item in fonte.findall("Item"):
        if item.get("class") == "Tool":
            moldes[texto(item, "Name")] = item

    saida = nova_raiz()
    for indice, dados in enumerate(CONJUNTO, 1):
        nome, origem = dados[0], dados[1]
        if origem not in moldes:
            print("Handle de origem não achado: %s" % origem)
            return 1
        marca = "%02d" % indice

        tool = copy.deepcopy(moldes[origem])
        n_ref = reetiquetar(tool, "G%s_" % marca)
        sons, efeitos, removidos = limpar(tool, marca)
        objeto = equipar(tool, dados, marca)
        saida.append(tool)

        print("%-26s <- %-15s  %d ref · -%d nó(s) · %d som · %d efeito"
              % (nome, origem, n_ref, removidos, sons, efeitos))

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
    print("")
    print("%s  —  %d bytes · 7 Tools · %d SharedString"
          % (os.path.relpath(DESTINO, RAIZ), os.path.getsize(DESTINO), len(citadas)))
    if penduradas:
        print("   ⚠️  %d SharedString PENDURADA" % len(penduradas))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
