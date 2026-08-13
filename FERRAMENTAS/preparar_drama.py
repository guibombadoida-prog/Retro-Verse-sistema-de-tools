#!/usr/bin/env python3
"""
preparar_drama.py — Retro-Verse / Studios

Monta o modelo de **7 Tools de briga** a partir das 3 do `drama.rbxmx`.

    python3 FERRAMENTAS/preparar_drama.py

TRÊS TOOLS, E SÓ UMA COM HANDLE

    O `drama.rbxmx` traz `Fists` (21 instâncias, e **nenhum Handle**), `dodge`
    (2 instâncias: um Script e mais nada) e `UpperSword`, que é a única com
    geometria de verdade.

    Isso decide o mapa. As Tools de punho e de olho não precisam de arma na
    mão — precisam de um Handle que exista, porque sem ele a Tool não equipa.
    As duas de lâmina herdam o `UpperSword`.

    | Alvo                | Handle vem de | Como                             |
    |---------------------|---------------|----------------------------------|
    | Combate             | Fists         | Handle **invisível**, 0.4 stud   |
    | Desviar e Empurrar  | dodge         | Handle **invisível**             |
    | Corte Frio          | UpperSword    | a espada, inteira · **CUTSCENE** |
    | Impacto Forte       | Fists         | **clone** — Handle invisível     |
    | Aura                | dodge         | **clone** — Handle invisível     |
    | Olhos Laser         | Fists         | **clone** — Handle invisível     |
    | TryHard             | UpperSword    | **clone** · **CUTSCENE**         |

    Handle invisível não substitui mesh de ninguém: supre o que a origem não
    tem. É o mesmo caminho do `Humilhador`, no conjunto GUEST.

AS DUAS COM CUTSCENE GANHAM `CutsceneRemote` E `CutsceneCam`

    `TESTES/verificar_rbxmx.py` cobra o par: `CutsceneCam` sem `CutsceneRemote`
    (ou o contrário) é erro. Quem enquadra é o cliente; o servidor manda beat
    nomeado e nunca toca em `Camera`.

O QUE SAI DE CADA TOOL DE ORIGEM

    Script, LocalScript, Animation, ScreenGui, ClickDetector, BindableEvent e
    RemoteEvent. Fica a geometria — e todo `Sound`, resgatado antes.

    O `Fists` é 2078 linhas e **um único `TakeDamage`** no modelo inteiro,
    contra nove escritas diretas em `Health` e quatro `BreakJoints`. Nada disso
    entra: a habilidade das sete é escrita do zero.
"""

import copy
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Drama", "drama.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Drama", "Drama_7_Tools.rbxmx")

# alvo · Handle de origem · tooltip · DamageClass · energia · recarga · chave ·
# tecla da Extra · tem cutscene
CONJUNTO = [
    ("Combate", "Fists",
     "Combo de tres golpes; a Extra abre com o chute rodado",
     "Melee", 0, 3, "Drama_Combate", "R", False),

    ("Desviar e Empurrar", "dodge",
     "Empurra quem esta na frente; a Extra e a esquiva com invencibilidade",
     "Melee", 0, 4, "Drama_Desviar", "R", False),

    ("Corte Frio", "UpperSword",
     "Corte de lamina; a Extra e a execucao, com cutscene",
     "Melee", 0, 6, "Drama_CorteFrio", "R", True),

    ("Impacto Forte", "Fists",
     "Soco pesado que arremessa; a Extra racha o chao",
     "Melee", 0, 7, "Drama_Impacto", "R", False),

    ("Aura", "dodge",
     "Liga a aura e ela sustenta; a Extra solta o pulso",
     "Suporte", 0, 10, "Drama_Aura", "R", False),

    ("Olhos Laser", "Fists",
     "Feixe pelos olhos; a Extra varre em leque",
     "Ranged", 0, 5, "Drama_Olhos", "R", False),

    ("TryHard", "UpperSword",
     "Combo de quatro golpes; a Extra finaliza, com cutscene",
     "Melee", 0, 22, "Drama_TryHard", "R", True),
]

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
CLASSES_FORA = CLASSES_SCRIPT + ("Animation", "ScreenGui", "Camera",
                                 "RemoteFunction", "RemoteEvent",
                                 "BillboardGui", "ClickDetector",
                                 "BindableEvent", "BindableFunction")
CLASSES_SOM = ("Sound",)
CLASSES_EFEITO = ("ParticleEmitter", "Beam", "Trail")
CLASSES_PECA = ("Part", "MeshPart", "UnionOperation", "WedgePart", "TrussPart")

# ═══════════════════════════════════════════════════════════════
# OS SONS — todos do PRÓPRIO `drama.rbxmx`
# ═══════════════════════════════════════════════════════════════
#
# O modelo traz **seis**, e todos moram no `UpperSword`. `Fists` e `dodge`
# chegaram mudas. Como no conjunto GUEST, o conjunto tem de soar como ele
# mesmo: nada é puxado de outro modelo.
#
#   93157691    `powerup` — a carga, o "ligou"
#   93107761    o `Sound` do `SlashPart` — o impacto do corte
#   rbxasset://sounds/swordslash.wav   o golpe
#   rbxasset://sounds/unsheath.wav     sacar / preparar
#
# ⚠️ A paleta é FINA: quatro timbres para sete Tools. Está declarado aqui para
#    não parecer descuido — quando entrar um modelo com som de soco, as Tools
#    de punho merecem trocar.
#
# `rbxasset://` NÃO é `rbxassetid://`. É conteúdo que vem **junto com o
# cliente Roblox** — mais "dentro" que qualquer id de catálogo, porque não há
# nada para buscar. `TESTES/verificar_rbxmx.py` foi ensinado a aceitar as duas
# formas por causa deste modelo.
SONS = {
    "GOLPE":   ("rbxasset://sounds/swordslash.wav", "1", "1"),
    "PREPARA": ("rbxasset://sounds/unsheath.wav", "0.8", "1"),
    "CARGA":   ("rbxassetid://93157691", "1.2", "1"),
    "IMPACTO": ("rbxassetid://93107761", "1.4", "1"),
}

# quais papéis cada Tool precisa ter no Handle
SONS_POR_TOOL = {
    "Combate":            ("GOLPE", "IMPACTO", "PREPARA"),
    "Desviar e Empurrar": ("GOLPE", "IMPACTO", "PREPARA"),
    "Corte Frio":         ("GOLPE", "IMPACTO", "PREPARA", "CARGA"),
    "Impacto Forte":      ("GOLPE", "IMPACTO", "CARGA"),
    "Aura":               ("CARGA", "IMPACTO", "PREPARA"),
    "Olhos Laser":        ("CARGA", "IMPACTO", "GOLPE"),
    "TryHard":            ("GOLPE", "IMPACTO", "PREPARA", "CARGA"),
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

    Sem isto, as Tools clonadas do mesmo Handle entram no arquivo com os MESMOS
    ids, e `Weld.Part0` de uma passa a apontar para peça da outra.
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


def cframe_identidade(item):
    e = ET.SubElement(props(item), "CoordinateFrame", {"name": "CFrame"})
    for tag, valor in (("X", "0"), ("Y", "0"), ("Z", "0"),
                       ("R00", "1"), ("R01", "0"), ("R02", "0"),
                       ("R10", "0"), ("R11", "1"), ("R12", "0"),
                       ("R20", "0"), ("R21", "0"), ("R22", "1")):
        ET.SubElement(e, tag).text = valor


def handle_invisivel(tool, marca):
    """Handle mínimo para Tool que a origem entregou sem nenhum."""
    item, p = novo_item(tool, "Part", "Handle", "DR_HANDLE_%s" % marca)
    ET.SubElement(p, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanTouch"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanQuery"}).text = "false"
    ET.SubElement(p, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(p, "float", {"name": "Transparency"}).text = "1"
    tam = ET.SubElement(p, "Vector3", {"name": "size"})
    for eixo in ("X", "Y", "Z"):
        ET.SubElement(tam, eixo).text = "0.4"
    cframe_identidade(item)
    return item


def novo_som(pai, nome, ident, volume, pitch, referente):
    item, p = novo_item(pai, "Sound", nome, referente)
    conteudo = ET.SubElement(p, "Content", {"name": "SoundId"})
    ET.SubElement(conteudo, "url").text = ident
    ET.SubElement(p, "float", {"name": "Volume"}).text = volume
    ET.SubElement(p, "float", {"name": "PlaybackSpeed"}).text = pitch
    ET.SubElement(p, "float", {"name": "RollOffMaxDistance"}).text = "120"
    ET.SubElement(p, "bool", {"name": "Looped"}).text = "false"
    return item


def limpar(tool):
    """Tira o que não é geometria, resgatando som e emissor antes."""
    condenados = set()
    for _pai, filho in pares(tool):
        if filho.get("class") in CLASSES_FORA:
            for dentro in filho.iter("Item"):
                condenados.add(id(dentro))

    resgatados = []
    for pai, filho in list(pares(tool)):
        if id(filho) in condenados and filho.get("class") in (
                CLASSES_SOM + CLASSES_EFEITO):
            pai.remove(filho)
            resgatados.append(filho)

    removidos = 0
    for pai, filho in list(pares(tool)):
        if filho.get("class") in CLASSES_FORA:
            pai.remove(filho)
            removidos = removidos + 1

    for pai, filho in list(pares(tool)):
        if filho.get("class") in ("Folder", "Model") and not filho.findall("Item"):
            pai.remove(filho)
            removidos = removidos + 1

    return resgatados, removidos


def sonorizar(tool, nome, marca):
    """Põe no Handle exatamente os papéis que esta Tool usa, com nome de papel.

    A origem chama dois sons diferentes de `Sound` e repete `swordslash` duas
    vezes. Nome repetido dentro do mesmo pai faz `FindFirstChild` devolver o
    primeiro que achar — o Server ficaria pedindo um som e recebendo outro.
    Aqui cada papel entra uma vez, com o nome do papel.
    """
    handle = achar(tool, nome="Handle")
    if handle is None:
        return []
    # TODO `Sound` da Tool sai, não só os do Handle. O `UpperSword` tem um
    # `Sound` chamado literalmente "Sound" dentro do `SlashPart`, com id no
    # formato antigo — sobrava, e o verificador acusava.
    for pai, filho in list(pares(tool)):
        if filho.get("class") == "Sound":
            pai.remove(filho)
    postos = []
    for i, papel in enumerate(SONS_POR_TOOL.get(nome, ())):
        ident, volume, pitch = SONS[papel]
        novo_som(handle, papel, ident, volume, pitch, "DR_SFX_%s_%d" % (marca, i))
        postos.append(papel)
    return ["%d som(ns): %s" % (len(postos), ", ".join(postos))] if postos else []


def aliviar_massa(tool):
    """`Massless = true` em toda peça que não é o Handle."""
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


def equipar(tool, dados, marca):
    (nome, _origem, tooltip, classe_dano, energia, recarga, chave,
     _tecla, cutscene) = dados

    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    if achar(tool, nome="Handle") is None:
        subiu = False
        for pai, filho in list(pares(tool)):
            if texto(filho, "Name") == "Handle":
                pai.remove(filho)
                tool.append(filho)
                subiu = True
                break
        if not subiu:
            handle_invisivel(tool, marca)

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", str(energia)),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, p = novo_item(tool, classe, alvo, "DR_%s_%s" % (alvo[:6], marca))
        ET.SubElement(p, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "DR_VFXR_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "DR_ACAO_%s" % marca)
    if cutscene:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "DR_CUTR_%s" % marca)

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
                            "DR_%s_%s" % (re.sub(r"[^\w]", "", alvo)[:12], marca))
        ET.SubElement(p, "ProtectedString", {"name": "Source"}).text = ""
        if alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript.
            #
            # No `Client` é o que faz o VFX aparecer para a sala inteira.
            #
            # No `CutsceneCam` é o que torna possível a regra 2 da
            # GRAMATICA_CUTSCENE — enquadramento POR ESPECTADOR. LocalScript só
            # roda para quem segura a Tool; o ALVO da cena nunca a executaria, e
            # a cena que mostra a vítima sendo alcançada não existiria para ela.
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
        n_ref = reetiquetar(tool, "D%s_" % marca)
        _resgatados, removidos = limpar(tool)
        equipar(tool, dados, marca)
        relato = sonorizar(tool, nome, marca)
        n_massa = aliviar_massa(tool)
        if n_massa:
            relato.append("%d peça(s) Massless" % n_massa)
        if dados[8]:
            relato.append("CUTSCENE")
        saida.append(tool)

        print("%-20s <- %-11s  %d ref · -%d nó(s) · %s"
              % (nome, origem, n_ref, removidos, " · ".join(relato)))

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
