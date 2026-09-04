#!/usr/bin/env python3
"""
preparar_faker.py — Retro-Verse / Studios

Monta o modelo de **7 Tools** a partir da ÚNICA Tool do `faker_tools.rbxmx`.

    python3 FERRAMENTAS/preparar_faker.py

A REFERÊNCIA É O PRÓPRIO ARQUIVO, E ELE DIZ MAIS DO QUE PARECE

    O `faker_tools.rbxmx` é o **His Cube ORIGINAL** — não a nossa conversão de
    volta. E ele batiza as próprias habilidades, no `Client`:

        Services.Input:SetTitle("Primary",   "Ultra Combo")        -- Q
        Services.Input:SetTitle("Secondary", "An end of an Era")   -- E
        Services.Input:SetTitle("Thirdary",  "Charge Power")       -- R

    **T1 e T2 do pedido são os nomes que o próprio modelo usa.** Não foram
    inventados aqui; foram lidos de lá.

AS SETE MALHAS SÃO O MAPA, E CINCO DELAS NUNCA FORAM USADAS

    O `AbbilityClient` carrega sete `MeshPart`/`UnionOperation`. O código de
    origem usa **duas**: `Sphere` (3 clones) e `Mushroom` (1). As outras cinco
    — `E`, `Erlo`, `Spiral`, `WindSphere`, `Ring` — estão lá, pagas, e nunca
    ligadas.

    Essas cinco são o motivo de este conjunto existir. O tamanho de cada uma
    diz o que ela é, e é assim que o mapa foi derivado:

    | Malha        | Tamanho             | O que é          | Vai para           |
    |--------------|---------------------|------------------|--------------------|
    | `E`          | 9.9 × **1.0** × 9.9 | disco chato      | Ultra Combo · Entity |
    | `Erlo`       | 5 × 5 × 5           | bloco cúbico     | Prisao Cubica      |
    | `Sphere`     | 4 × 4 × 4           | esfera           | Prisao · Entity    |
    | `Spiral`     | 33 × 17 × 40        | espiral grande   | Ilusao · Abismo    |
    | `WindSphere` | 9.9³                | domo             | Sala Do Abismo     |
    | `Ring`       | **500** × 48 × 500  | anel gigante     | Era Do Fim · Abismo |
    | `Mushroom`   | **522 × 543 × 522** | cogumelo nuclear | Era Do Fim         |

    `Ring` e `Mushroom` são as duas maiores por uma ordem de grandeza — 500 e
    522 studs. São o fim de uma era, e é para lá que vão.

O QUE O ORIGINAL FAZIA, E POR QUE ISSO É O PONTO DESTE CONJUNTO

    O `Shoot` de servidor tem **40 linhas** e recebe um aviso, retransmite com
    `FireAllClients`, e nada mais. **Nenhuma linha do modelo aplica dano** — o
    scan não achou um `TakeDamage` nem uma escrita em `Health`.

    E toda a habilidade vive em `Client` (431 linhas) e `AbbilityClient` (365),
    que são **LocalScript**. LocalScript dentro de Tool só roda para o jogador
    cujo Character a contém: o efeito acontecia **só na tela de quem segurava**.

    As duas coisas juntas: era uma casca de VFX privada. Aqui as sete desenham
    por `VFXRemote:FireAllClients` e o `Client` é `Script` com
    `RunContext = Client` — roda em TODO cliente, inclusive dentro da Tool de
    outro jogador. O efeito aparece para a sala inteira, e o dano existe.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Faker_Tools", "faker_tools.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Faker_Tools",
                       "Faker_7_Tools.rbxmx")

# alvo · tooltip · DamageClass · energia · recarga · chave · tecla · cutscene ·
# malhas que esta Tool leva
CONJUNTO = [
    ("Ultra Combo",
     "Combo de quatro golpes; a Extra fecha com o anel",
     "Melee", 0, 0.32, "Faker_UltraCombo", "R", False, ("E",)),

    ("Era Do Fim",
     "O cogumelo. A Extra e o anel que corre 500 studs",
     "Explosivo", 0, 40, "Faker_EraDoFim", "R", True, ("Mushroom", "Ring")),

    ("Sala Do Abismo",
     "Fecha a sala em volta de voce; a Extra a implode",
     "Espectral", 0, 24, "Faker_SalaAbismo", "R", False, ("WindSphere",)),

    ("Ilusao da Alucinacao",
     "Espiral que confunde quem olha; a Extra troca voce de lugar",
     "Espectral", 0, 14, "Faker_Ilusao", "R", False, ("Spiral",)),

    ("Prisao Cubica",
     "Prende o alvo num cubo; a Extra estilhaca a prisao",
     "Espectral", 0, 18, "Faker_Prisao", "R", False, ("Erlo", "Sphere")),

    ("Faker Entity",
     "Invoca a entidade, que ataca sozinha; a Extra a manda para o alvo",
     "Espectral", 0, 30, "Faker_Entity", "R", True, ("Sphere", "E")),

    ("Abismo Profundo",
     "Abre o poco no chao; a Extra puxa tudo para dentro",
     "Espectral", 0, 26, "Faker_Abismo", "R", False, ("Ring", "Spiral")),
]

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
CLASSES_FORA = CLASSES_SCRIPT + ("Animation", "ScreenGui", "Camera",
                                 "RemoteFunction", "RemoteEvent",
                                 "BillboardGui", "ClickDetector",
                                 "BindableEvent", "BindableFunction")
CLASSES_MALHA = ("MeshPart", "UnionOperation")
CLASSES_PECA = CLASSES_MALHA + ("Part", "WedgePart", "TrussPart")

# ═══════════════════════════════════════════════════════════════
# O SOM — o único do modelo, e ele vem com Volume 100
# ═══════════════════════════════════════════════════════════════
#
# O `Client` cria um `Sound` no código com `rbxassetid://2960518660` e
# **`Volume = 100`**. O teto do Roblox é 10; 100 é dez vezes o máximo, e o
# efeito prático é o som saturar e abafar todo o resto do jogo.
#
# É o único timbre que o modelo tem, então ele fica — com volume de gente.
#
# papel -> (id, volume, pitch)
SONS = {
    "DISPARO": ("rbxassetid://2960518660", "1.6", "1"),
    "GRAVE":   ("rbxassetid://2960518660", "2.2", "0.45"),
    "AGUDO":   ("rbxassetid://2960518660", "1.1", "1.9"),
}

SONS_POR_TOOL = {
    "Ultra Combo":          ("DISPARO", "AGUDO"),
    "Era Do Fim":           ("DISPARO", "GRAVE", "AGUDO"),
    "Sala Do Abismo":       ("GRAVE", "AGUDO"),
    "Ilusao da Alucinacao": ("AGUDO", "GRAVE"),
    "Prisao Cubica":        ("AGUDO", "DISPARO"),
    "Faker Entity":         ("GRAVE", "DISPARO", "AGUDO"),
    "Abismo Profundo":      ("GRAVE", "DISPARO"),
}


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
    for filho in item.findall("Item"):
        for par in pares(filho):
            yield par
        yield item, filho


def reetiquetar(tool, prefixo):
    """Prefixa todo `referent` e reescreve todo `<Ref>` que o citava.

    As sete saem da MESMA Tool, então sem isto os sete clones entram no arquivo
    com ids idênticos e o Studio religa propriedade no objeto errado.
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


def novo_som(pai, nome, ident, volume, pitch, referente):
    item, p = novo_item(pai, "Sound", nome, referente)
    conteudo = ET.SubElement(p, "Content", {"name": "SoundId"})
    ET.SubElement(conteudo, "url").text = ident
    ET.SubElement(p, "float", {"name": "Volume"}).text = volume
    ET.SubElement(p, "float", {"name": "PlaybackSpeed"}).text = pitch
    ET.SubElement(p, "float", {"name": "RollOffMaxDistance"}).text = "160"
    ET.SubElement(p, "bool", {"name": "Looped"}).text = "false"
    return item


def colher_malhas(tool):
    """Tira as malhas de dentro dos scripts ANTES de removê-los.

    Elas moram em `AbbilityClient`, que é LocalScript e vai sair. Sem o resgate,
    as sete malhas iriam junto — e são elas o motivo do conjunto existir.
    """
    colhidas = {}
    for pai, filho in list(pares(tool)):
        if filho.get("class") in CLASSES_MALHA:
            nome = texto(filho, "Name") or ""
            if nome and nome not in colhidas:
                colhidas[nome] = copy.deepcopy(filho)
    return colhidas


def limpar(tool):
    removidos = 0
    for pai, filho in list(pares(tool)):
        if filho.get("class") in CLASSES_FORA:
            pai.remove(filho)
            removidos = removidos + 1
    for pai, filho in list(pares(tool)):
        if filho.get("class") == "Sound":
            pai.remove(filho)
            removidos = removidos + 1
    for pai, filho in list(pares(tool)):
        if filho.get("class") in ("Folder", "Model") and not filho.findall("Item"):
            pai.remove(filho)
            removidos = removidos + 1
    return removidos


def assentar_malha(malha):
    """Molde de VFX: ancorado, invisível ao equipar, e sem colisão.

    A regra que o usuário fixou: *"deixar os vfx invisível dentro da tool, e
    visível na execução da habilidade"*. Quem acende é o `VFXModule`, no
    clone — o molde nunca aparece.
    """
    definir(malha, "bool", "Anchored", "true")
    definir(malha, "bool", "CanCollide", "false")
    definir(malha, "bool", "CanTouch", "false")
    definir(malha, "bool", "CanQuery", "false")
    definir(malha, "bool", "Massless", "true")
    definir(malha, "bool", "CastShadow", "false")
    definir(malha, "float", "Transparency", "1")
    return malha


def equipar(tool, dados, marca, colhidas):
    (nome, tooltip, classe_dano, energia, recarga, chave,
     _tecla, cutscene, quais) = dados

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

    # as malhas que ESTA Tool usa, e só elas
    pasta, _p = novo_item(tool, "Folder", "Moldes", "FK_MOLDES_%s" % marca)
    postas = []
    for i, alvo in enumerate(quais):
        molde = colhidas.get(alvo)
        if molde is None:
            continue
        copia = copy.deepcopy(molde)
        reetiquetar(copia, "FKM%s_%d_" % (marca, i))
        assentar_malha(copia)
        pasta.append(copia)
        postas.append(alvo)

    # o som
    handle = achar(tool, nome="Handle")
    for i, papel in enumerate(SONS_POR_TOOL.get(nome, ())):
        ident, volume, pitch = SONS[papel]
        novo_som(handle, papel, ident, volume, pitch, "FK_SFX_%s_%d" % (marca, i))

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", str(energia)),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, p = novo_item(tool, classe, alvo, "FK_%s_%s" % (alvo[:6], marca))
        ET.SubElement(p, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "FK_VFXR_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "FK_ACAO_%s" % marca)
    if cutscene:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "FK_CUTR_%s" % marca)

    objeto = "%s_Server_V1" % re.sub(r"[^\w]", "", nome)
    scripts = [("Script", objeto),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]
    if cutscene:
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        item, p = novo_item(tool, classe, alvo,
                            "FK_%s_%s" % (re.sub(r"[^\w]", "", alvo)[:12], marca))
        ET.SubElement(p, "ProtectedString", {"name": "Source"}).text = ""
        if alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript.
            #
            # É O PONTO DESTE CONJUNTO. O modelo de origem punha 796 linhas de
            # VFX em dois LocalScript, e LocalScript dentro de Tool só roda para
            # quem a segura: o efeito acontecia SÓ na tela do portador.
            ET.SubElement(p, "token", {"name": "RunContext"}).text = "2"
    return postas


def aliviar_massa(tool):
    n = 0
    handle = achar(tool, nome="Handle")
    for _pai, filho in pares(tool):
        if filho.get("class") not in CLASSES_PECA or filho is handle:
            continue
        if texto(filho, "Massless") == "true":
            continue
        definir(filho, "bool", "Massless", "true")
        n = n + 1
    return n


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

    molde = None
    for item in fonte.findall("Item"):
        if item.get("class") == "Tool":
            molde = item
            break
    if molde is None:
        print("nenhuma Tool na raiz de %s" % ORIGEM)
        return 1

    colhidas = colher_malhas(molde)
    print("malhas colhidas do `AbbilityClient`: %s" % ", ".join(sorted(colhidas)))
    print("")

    saida = nova_raiz()
    for indice, dados in enumerate(CONJUNTO, 1):
        nome = dados[0]
        marca = "%02d" % indice

        tool = copy.deepcopy(molde)
        n_ref = reetiquetar(tool, "F%s_" % marca)
        removidos = limpar(tool)
        postas = equipar(tool, dados, marca, colhidas)
        n_massa = aliviar_massa(tool)
        saida.append(tool)

        print("%-22s %d ref · -%d nó(s) · moldes: %-22s · %d Massless%s"
              % (nome, n_ref, removidos, ", ".join(postas) or "—", n_massa,
                 " · CUTSCENE" if dados[7] else ""))

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
