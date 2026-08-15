#!/usr/bin/env python3
"""
preparar_reality.py — Retro-Verse / Studios

Monta o modelo de **7 Tools** do conjunto REALITY GUI, a partir de DUAS fontes.

    python3 FERRAMENTAS/preparar_reality.py

⛔ A FONTE PRINCIPAL ESTÁ EM QUARENTENA

    O `reality_tools.rbxmx` carrega um BACKDOOR — `Pistol/…/qPerfectionWeld`
    busca um número em `https://assetimport.org/` e o passa para `require()`,
    que é execução remota de código com permissão de servidor.

    Nenhuma das seis Tools que este conjunto usa é a `Pistol`. Ainda assim, a
    regra aqui é absoluta e não depende disso:

        **NENHUM script da origem atravessa.** Nem um.

    `CLASSES_FORA` remove `Script`, `LocalScript` e `ModuleScript` de tudo que
    é copiado, antes de qualquer outra coisa. O que entra é geometria, som,
    malha e `KeyframeSequence` — dado, não código. O `main()` termina varrendo
    a saída atrás de `assetimport`, `require(<id>)` e `HttpService`, e falha se
    achar qualquer um.

DUAS FONTES

    seis do `reality_tools.rbxmx`  e  uma do `Canhao_satelite.rbxmx`, que já
    estava no repositório como CRU desde o lote de 2026-08-13.

    | Tool | Vem de | Handle | O que a origem deu |
    |---|---|---|---|
    | `Lapada Seca` | `SLAP` | Part 1.76 × 0.1 × 0.1 | a malha `Hand` e 3 sons |
    | `Canhao Satelite` | `LowOrbitIonCannon` | Part 0.8 × 2.3 × 0.4 | **21 sons** |
    | `Trem` | `a-train` | **invisível** | `KeyframeSequence` de 40 kf |
    | `Arvore Maligna` | `tre` | Part 4 × 1 × 2 | **5 `UnionOperation`** — a árvore |
    | `Gato Ajudante Boss` | `gravity cat not amused` | Part 4 × 1 × 2 | o `Model` do gato |
    | `Samsungus` | `samsung` | **MeshPart** id 430345282 | o celular e 6 sons |
    | `Danca Provocadora` | `kick dance` | **invisível** | `KeyframeSequence` de **361 kf** |

    `a-train` e `kick dance` declaram `RequiresHandle = false` e não têm Handle
    nenhum: são emotes. Ganham um invisível de 0.4 stud, como o `Fists` e o
    `dodge` do conjunto DRAMA.

O GATO É INVOCAÇÃO, NÃO NPC

    O `CLAUDE.md` põe NPC fora de escopo, e a origem do `gravity cat` é um
    spawner com `Humanoid` e seis `Motor6D`. O `Humanoid` NÃO entra: o que vai
    para `Tool/Moldes/` é o corpo do gato como geometria, e quem o invoca, move
    e dispensa é a Tool — com prazo, e solto no `desmontar()`.

    É o mesmo desenho do `Xester Invocacao` e do `Faker Entity`, que já fazem
    isso. Invocar é habilidade de Tool; manter sistema de NPC é que não é.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
REALITY = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                       "reality_tools.rbxmx")
CANHAO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Canhao_Satelite",
                      "Canhao_satelite.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                       "Reality_Gui_7_Tools.rbxmx")

# alvo · fonte · Tool de origem · tooltip · DamageClass · recarga · chave ·
# cutscene · moldes a colher da origem
CONJUNTO = [
    ("Lapada Seca", "reality", "SLAP",
     "Tapa seco que gira o alvo; a Extra e a sequencia de tres",
     "Melee", 0.5, "Reality_Lapada", False, ("Hand",)),

    ("Canhao Satelite", "canhao", "LowOrbitIonCannon",
     "Marca o ponto e chama o feixe de orbita — ultimate com cutscene",
     "Explosivo", 38, "Reality_Canhao", True, ()),

    ("Trem", "reality", "a-train",
     "Investida que atropela em linha reta",
     "Melee", 16, "Reality_Trem", False, ()),

    ("Arvore Maligna", "reality", "tre",
     "Ergue a arvore que prende quem chega perto",
     "Espectral", 24, "Reality_Arvore", False, ("tree",)),

    ("Gato Ajudante Boss", "reality", "gravity cat not amused",
     "Invoca o gato, que briga por voce ate o prazo acabar",
     "Espectral", 30, "Reality_Gato", False, ("Gravity Cat Not Amused",)),

    ("Samsungus", "reality", "samsung",
     "Bate com o aparelho; a Extra e a chamada que atordoa",
     "Melee", 0.6, "Reality_Samsungus", False, ()),

    ("Danca Provocadora", "reality", "kick dance",
     "A danca de 12 s que puxa a atencao de quem esta perto",
     "Suporte", 20, "Reality_Danca", False, ()),
]

#: Tool de origem -> quais Sound trazer, e com que nome de papel
SONS = {
    "SLAP": {"Smack": "TAPA", "Boom": "ESTOURO", "slaps": "SEQUENCIA"},
    "LowOrbitIonCannon": {"Call": "CHAMADA", "Big Explosion": "FEIXE",
                          "Electric Explosion": "CARGA",
                          "Explosion SFX": "ECO"},
    "a-train": {"blood": "ATROPELA"},
    "tre": {"Kill": "GALHO"},
    "gravity cat not amused": {"theme": "MIADO"},
    "samsung": {"MetalHit": "BATE", "Swoosh": "GIRO", "Hit": "IMPACTO",
                "unequip": "GUARDA"},
    "kick dance": {},
}

#: a Dança não tem som próprio utilizável (o `music` veio vazio). Empresta do
#: Canhão, que trouxe 21 — declarado, não escondido.
SONS_EMPRESTADOS = {
    "Danca Provocadora": [("LowOrbitIonCannon", "Call", "PROVOCA"),
                          ("LowOrbitIonCannon", "Explosion SFX", "BATIDA")],
    "Trem": [("LowOrbitIonCannon", "Electric Explosion", "APITO")],
}

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
CLASSES_FORA = CLASSES_SCRIPT + ("Animation", "ScreenGui", "TextLabel",
                                 "Frame", "ImageLabel", "Camera",
                                 "BillboardGui", "ClickDetector",
                                 "RemoteFunction", "RemoteEvent",
                                 "BindableEvent", "BindableFunction",
                                 "Humanoid", "HumanoidController",
                                 "BodyGyro", "BodyVelocity", "BodyPosition")
CLASSES_PECA = ("Part", "MeshPart", "UnionOperation", "WedgePart")


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
    if u is not None:
        return u.text
    return e.text


def definir(item, tag, nome, valor):
    e = prop(item, nome)
    if e is None:
        e = ET.SubElement(props(item), tag, {"name": nome})
    e.tag = tag
    for filho in list(e):
        e.remove(filho)
    e.text = valor
    return e


def novo_item(pai, classe, nome, referente):
    item = ET.SubElement(pai, "Item", {"class": classe, "referent": referente})
    p = ET.SubElement(item, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    return item, p


def pares(item):
    for filho in item.findall("Item"):
        for par in pares(filho):
            yield par
        yield item, filho


def reetiquetar(no, prefixo):
    mapa = {}
    for item in no.iter("Item"):
        antigo = item.get("referent")
        if antigo:
            novo = prefixo + antigo
            mapa[antigo] = novo
            item.set("referent", novo)
    for ref in no.iter("Ref"):
        alvo = (ref.text or "").strip()
        if alvo in mapa:
            ref.text = mapa[alvo]
    return len(mapa)


RE_ID = re.compile(r"(\d{4,})")


def normalizar_som(som):
    """`http://www.roblox.com/asset/?id=N` -> `rbxassetid://N`. Devolve False
    se o `SoundId` estiver vazio — som sem id é asset morto, e ele não entra.

    A origem mistura os dois formatos e ainda traz `Sound` com o campo em
    branco (`Slide` e `Sound` na árvore). O verificador cobra `rbxassetid://`,
    e cobra com razão: o formato legado depende de redirecionamento do site.
    """
    e = prop(som, "SoundId")
    if e is None:
        return False
    u = e.find("url")
    bruto = (u.text if u is not None else e.text) or ""
    achado = RE_ID.search(bruto)
    if not achado:
        return False
    limpo = "rbxassetid://%s" % achado.group(1)
    if u is not None:
        u.text = limpo
    else:
        e.text = limpo
    return True


def descodificar(no):
    """Tira TODO script e toda instância de runtime de dentro do nó.

    ⛔ É a barreira de quarentena. A fonte principal tem backdoor, e a resposta
    não é "achar o backdoor e tirar" — é não deixar código nenhum atravessar.
    O que entra é geometria, som, malha e dado.
    """
    n = 0
    for pai, filho in list(pares(no)):
        # `Sound` também sai: os que ficam são os renomeados por papel, postos
        # no Handle depois. Os da origem vêm com id vazio ou em formato legado.
        if filho.get("class") in CLASSES_FORA or filho.get("class") == "Sound":
            pai.remove(filho)
            n = n + 1
    return n


def assentar(peca, invisivel=True):
    definir(peca, "bool", "Anchored", "true")
    definir(peca, "bool", "CanCollide", "false")
    definir(peca, "bool", "CanTouch", "false")
    definir(peca, "bool", "CanQuery", "false")
    definir(peca, "bool", "Massless", "true")
    definir(peca, "bool", "CastShadow", "false")
    if invisivel:
        definir(peca, "float", "Transparency", "1")
    return peca


def achar_tool(raiz, nome):
    for item in raiz.findall("Item"):
        if item.get("class") == "Tool" and texto(item, "Name") == nome:
            return item
    return None


def colher(tool, quais):
    """Os moldes pedidos, por nome, de dentro da Tool de origem."""
    achados = {}
    for _pai, filho in pares(tool):
        nome = texto(filho, "Name")
        if nome in quais and nome not in achados:
            if filho.get("class") in CLASSES_PECA or filho.get("class") == "Model":
                achados[nome] = copy.deepcopy(filho)
    return achados


def sons_de(tool):
    saida = {}
    for _pai, filho in pares(tool):
        if filho.get("class") != "Sound":
            continue
        nome = texto(filho, "Name")
        if nome and nome not in saida:
            saida[nome] = copy.deepcopy(filho)
    return saida


def novo_handle(tool, marca, origem):
    if origem is not None:
        handle = copy.deepcopy(origem)
        reetiquetar(handle, "RGH%s_" % marca)
        descodificar(handle)
        # o Handle da origem traz `Sound` próprio: eles saem, porque os que
        # ficam são os renomeados por papel, logo abaixo. Dois conjuntos do
        # mesmo som no mesmo pai é asset mudo com nome errado.
        for pai2, filho2 in list(pares(handle)):
            if filho2.get("class") == "Sound":
                pai2.remove(filho2)
        definir(handle, "string", "Name", "Handle")
        definir(handle, "bool", "Anchored", "false")
        definir(handle, "bool", "CanCollide", "false")
        definir(handle, "bool", "Massless", "true")
        tool.append(handle)
        return True

    _handle, p = novo_item(tool, "Part", "Handle", "RG_HANDLE_%s" % marca)
    tamanho = ET.SubElement(p, "Vector3", {"name": "size"})
    for eixo in ("X", "Y", "Z"):
        ET.SubElement(tamanho, eixo).text = "0.4"
    ET.SubElement(p, "float", {"name": "Transparency"}).text = "1"
    ET.SubElement(p, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(p, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(p, "bool", {"name": "CastShadow"}).text = "false"
    return False


def montar(dados, marca, fontes):
    (nome, fonte, origem_nome, tooltip, classe_dano, recarga, chave,
     cutscene, quais) = dados

    raiz_fonte = fontes[fonte]
    origem = achar_tool(raiz_fonte, origem_nome)
    if origem is None:
        return None, "não achei a Tool %r em %s" % (origem_nome, fonte)

    tool = ET.Element("Item", {"class": "Tool",
                               "referent": "RG_TOOL_%s" % marca})
    p = ET.SubElement(tool, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    ET.SubElement(p, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(p, "bool", {"name": "CanBeDropped"}).text = "false"
    ET.SubElement(p, "bool", {"name": "RequiresHandle"}).text = "true"

    # Handle
    handle_origem = None
    for _pai, filho in pares(origem):
        if texto(filho, "Name") == "Handle" and filho.get("class") in CLASSES_PECA:
            handle_origem = filho
            break
    proprio = novo_handle(tool, marca, handle_origem)
    handle = None
    for filho in tool.findall("Item"):
        if texto(filho, "Name") == "Handle":
            handle = filho
            break

    # moldes
    pasta, _pp = novo_item(tool, "Folder", "Moldes", "RG_MOLDES_%s" % marca)
    colhidos = colher(origem, set(quais))
    postos = []
    for i, alvo in enumerate(quais):
        molde = colhidos.get(alvo)
        if molde is None:
            continue
        copia = copy.deepcopy(molde)
        reetiquetar(copia, "RGM%s_%d_" % (marca, i))
        descodificar(copia)
        if copia.get("class") == "Model":
            for _pai2, filho2 in pares(copia):
                if filho2.get("class") in CLASSES_PECA:
                    assentar(filho2)
        else:
            assentar(copia)
        pasta.append(copia)
        postos.append(alvo)

    # sons: os da própria origem, mais os declaradamente emprestados
    disponiveis = sons_de(origem)
    n_som = 0
    for bruto, papel in SONS.get(origem_nome, {}).items():
        som = disponiveis.get(bruto)
        if som is None:
            continue
        copia = copy.deepcopy(som)
        reetiquetar(copia, "RGS%s_%d_" % (marca, n_som))
        descodificar(copia)
        if not normalizar_som(copia):
            continue
        definir(copia, "string", "Name", papel)
        definir(copia, "bool", "Looped", "false")
        handle.append(copia)
        n_som = n_som + 1

    for de_tool, bruto, papel in SONS_EMPRESTADOS.get(nome, []):
        doadora = achar_tool(fontes["canhao"], de_tool) \
            or achar_tool(fontes["reality"], de_tool)
        if doadora is None:
            continue
        som = sons_de(doadora).get(bruto)
        if som is None:
            continue
        copia = copy.deepcopy(som)
        reetiquetar(copia, "RGE%s_%d_" % (marca, n_som))
        descodificar(copia)
        if not normalizar_som(copia):
            continue
        definir(copia, "string", "Name", papel)
        definir(copia, "bool", "Looped", "false")
        handle.append(copia)
        n_som = n_som + 1

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, pv = novo_item(tool, classe, alvo, "RG_%s_%s" % (alvo[:6], marca))
        ET.SubElement(pv, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RG_VFXR_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RG_ACAO_%s" % marca)
    if cutscene:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RG_CUTR_%s" % marca)

    objeto = "%s_Server_V1" % re.sub(r"[^\w]", "", nome)
    scripts = [("Script", objeto), ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"), ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]
    if cutscene:
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        item, pv = novo_item(tool, classe, alvo,
                             "RG_%s_%s" % (re.sub(r"[^\w]", "", alvo)[:12], marca))
        ET.SubElement(pv, "ProtectedString", {"name": "Source"}).text = ""
        if alvo in ("Client", "CutsceneCam"):
            ET.SubElement(pv, "token", {"name": "RunContext"}).text = "2"

    return (tool, postos, n_som, proprio), None


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


#: o que NÃO pode existir na saída, de jeito nenhum
VENENO = ("assetimport", "loadstring", "getfenv", "setfenv", "HttpService",
          "GetAsync", "PostAsync")
RE_REQUIRE_ID = re.compile(r"require\s*\(\s*[0-9]")


def main():
    for caminho in (REALITY, CANHAO):
        if not os.path.exists(caminho):
            print("fonte não encontrada: %s" % caminho)
            return 1

    fontes = {"reality": ET.parse(REALITY).getroot(),
              "canhao": ET.parse(CANHAO).getroot()}
    tabela = {}
    for raiz in fontes.values():
        for e in raiz.iter("SharedString"):
            if e.get("md5"):
                tabela[e.get("md5")] = e.text or ""

    print("⛔ a fonte principal está em QUARENTENA — nenhum script atravessa")
    print("")

    saida = nova_raiz()
    for indice, dados in enumerate(CONJUNTO, 1):
        marca = "%02d" % indice
        feito, erro = montar(dados, marca, fontes)
        if erro:
            print("PAREI: %s" % erro)
            return 1
        tool, postos, n_som, proprio = feito
        saida.append(tool)
        print("%-20s %-8s handle:%-9s %d som(ns) · moldes: %s"
              % (dados[0], dados[1], "origem" if proprio else "invisível",
                 n_som, ", ".join(postos) or "—"))

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

    # ── a barreira, conferida no arquivo escrito
    with open(DESTINO, encoding="utf-8", errors="replace") as f:
        corpo = f.read()
    achados = [v for v in VENENO if v.lower() in corpo.lower()]
    if RE_REQUIRE_ID.search(corpo):
        achados.append("require(<id>)")
    n_script = sum(1 for i in saida.iter("Item")
                   if i.get("class") in CLASSES_SCRIPT
                   and (texto(i, "Source") or "").strip())

    print("")
    print("%s  —  %d bytes · 7 Tools · %d SharedString"
          % (os.path.relpath(DESTINO, RAIZ), os.path.getsize(DESTINO),
             len(citadas)))
    print("QUARENTENA: %d script(s) com código da origem · veneno: %s"
          % (n_script, ", ".join(achados) if achados else "nenhum"))
    if achados or n_script:
        print("   ⛔ FALHOU — não entregue este arquivo")
        return 1
    if penduradas:
        print("   ⚠️  %d SharedString PENDURADA" % len(penduradas))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
