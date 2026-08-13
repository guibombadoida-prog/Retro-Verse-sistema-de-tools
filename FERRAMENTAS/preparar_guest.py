#!/usr/bin/env python3
"""
preparar_guest.py — Retro-Verse / Studios

Conforma o `_ORIGEM.rbxmx` das 7 Tools do conjunto GUEST ao contrato do §12.10,
**sem remontar nada**.

    python3 FERRAMENTAS/preparar_guest.py

ISTO É REMASTER, NÃO TOOL NOVA

    `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem que
    mandaram converter, então **a estrutura é lei**. Handle, mesh, Sound, Weld,
    Motor6D e hierarquia saem daqui intactos. O que esta ferramenta faz é só:

      1. propriedade obrigatória — ToolTip, CanBeDropped, RequiresHandle
      2. os Values de §12.4 — DamageClass, EnergyCost, RecargaGlobal, ChaveRecarga
      3. os RemoteEvents — VFXRemote sempre; AcaoRemote onde há Extra
      4. renomear o Script de servidor para `<Nome>_Server_V1`
      5. acrescentar Client (RunContext=Client), R6CFrameAnimator, Poses, VFXModule
      6. **retirar** o que é proibido dentro de Tool

O QUE É RETIRADO, E POR QUÊ

    `Animation` "Swing" (Diamond)   proibida — pose CFrame sob R6CFrameAnimator
    `ScreenGui` "judgegui" (A arma) proibida — efeito só no mundo 3D.
                                    A mira volta como BillboardGui no ponto
                                    visado, que é mundo 3D e vale para todos.
    `LocalScript` originais         viram o `Client` único, com RunContext

DUAS EXCEÇÕES DE GEOMETRIA, DECLARADAS

    `A arma`     o Handle dela mora em `model/Handle`, e Tool com
                 RequiresHandle = true exige Handle como **filho direto** — é
                 exigência do Roblox, não deste repositório. Ele SOBE de nível.
                 Weld e Motor6D apontam por `referent`, não por caminho, então
                 nada se desfaz. Nenhuma peça é criada, movida no espaço, nem
                 trocada.

    `Humilhador` não tem Handle nenhum: é provocação pura, e a origem traz só
                 um Script. Sem Handle a Tool não equipa. Entra um Handle
                 **invisível de 0.4 stud**, sem colisão. Não substitui mesh de
                 ninguém — supre o que não existe.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

# nome · tooltip · DamageClass · ARQUETIPO · energia · recarga · chave ·
# nome do Script de servidor na origem · Extra (tecla, rótulo)
CONJUNTO = [
    ("Taco de Baseball",
     "Dois golpes que revezam; segure a Extra para o vibe check",
     "Melee", 0, 9, "Guest_Taco",
     "Script", ("R", "Vibe Check")),

    ("Cano De Rua",
     "Cano de chumbo — o segundo golpe vem mais forte",
     "Melee", 0, 11, "Guest_Cano",
     "LeadpipeServer", ("R", "Concussao")),

    ("Abacate (roubado) do mexico",
     "Come e recupera; a Extra arremessa o caroço",
     "Suporte", 0, 5, "Guest_Abacate",
     "avocados from mexico", ("R", "Caroco")),

    ("Energetico",
     "Bebe, cura e acelera; a Extra amassa a lata e joga",
     "Suporte", 0, 6, "Guest_Energetico",
     "BloxyColaScript", ("R", "Lata")),

    ("Humilhador",
     "Provoca. A Extra provoca a roda inteira",
     "Suporte", 0, 4, "Guest_Humilhador",
     "Server", ("R", "Roda")),

    ("Diamond",
     "Tapa que arremessa; a Extra vira pedra e devolve o dano",
     "Melee", 0, 8, "Guest_Diamond",
     "SERVER", ("E", "Pedra")),

    ("A arma",
     "Revólver de seis tiros; a Extra recarrega o tambor",
     "Ranged", 0, 3, "Guest_Arma",
     "Script", ("R", "Recarregar")),
]

# scripts da origem que NÃO viram Server e por isso saem da árvore
SCRIPTS_A_TIRAR = {
    "Taco de Baseball": ["LocalScript"],
    "Humilhador": ["mainz"],
    "Diamond": ["CLIENT"],
    "A arma": ["LocalScript"],
}

CLASSES_PROIBIDAS = ("Animation", "ScreenGui")

# ═══════════════════════════════════════════════════════════════
# SFX QUE FALTAM — três Tools chegaram mudas
# ═══════════════════════════════════════════════════════════════
#
#   Humilhador  criava o `Sound` no código, com id `7995127481` e
#               `PlayOnRemove`. O id é dele; o que muda é que ele vira
#               instância DENTRO da Tool, como manda a Regra nº 1.
#
#   A arma      chegou com ZERO `Sound`. Revólver mudo não é entrega.
#
#   Abacate     tem `OpenSound`, e o `SoundId` dele veio **em branco** — o
#               `Tool.Equipped` chama `:Play()` e não sai nada. Mesma família
#               do `rbxassetid://200` das bombas.
#
# DE ONDE VÊM OS IDS QUE NÃO SÃO NATIVOS
#
#   Do `Xester_Forma1`, que é a única entrada de SFX deste repositório com a
#   ficha fechada nos quatro campos de §12.12.3 — é o mesmo critério que o
#   `preparar_collector.py` já usa, e pelo mesmo motivo. O papel de cada id
#   segue o uso que o script de origem dava a ele:
#
#     1910988873  o raio, a sentença descendo   -> o tiro
#     472214107   tique do contador             -> o tambor girando
#     54111471    fechamento                    -> o tambor fechando
#
#   São ESCOLHA POR PAPEL, não por audição: não dá para ouvir os arquivos
#   daqui. Quando entrar um som de tiro com ficha fechada, troque estes três —
#   está aqui para que a troca seja de uma linha.
#
# nome -> (id, volume, pitch)
SONS_QUE_FALTAM = {
    "Humilhador": [
        ("Provoca", "7995127481", "2", "1"),
    ],
    "A arma": [
        ("Tiro", "1910988873", "1.6", "1.35"),
        ("Tambor", "472214107", "0.8", "1.5"),
        ("Fecha", "54111471", "0.9", "1.2"),
    ],
}

# Sound que existe mas está com o id vazio: nome -> (id, volume, pitch)
SONS_A_CONSERTAR = {
    "Abacate (roubado) do mexico": {
        # o `OpenSound` do Energetico, que é do mesmo modelo e do mesmo gesto
        "OpenSound": ("7244308623", "0.7", "1.1"),
    },
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


def varrer(item):
    """(pai, filho) de toda a subárvore, de baixo para cima."""
    for filho in item.findall("Item"):
        for par in varrer(filho):
            yield par
        yield item, filho


def cframe_identidade(item, nome="CFrame"):
    e = ET.SubElement(props(item), "CoordinateFrame", {"name": nome})
    for tag, valor in (("X", "0"), ("Y", "0"), ("Z", "0"),
                       ("R00", "1"), ("R01", "0"), ("R02", "0"),
                       ("R10", "0"), ("R11", "1"), ("R12", "0"),
                       ("R20", "0"), ("R21", "0"), ("R22", "1")):
        ET.SubElement(e, tag).text = valor


def handle_invisivel(tool, marca):
    """Handle mínimo para Tool que a origem entregou sem nenhum."""
    item, p = novo_item(tool, "Part", "Handle", "GU_HANDLE_%s" % marca)
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


def novo_som(pai, nome, id_som, volume, pitch, referente):
    item, p = novo_item(pai, "Sound", nome, referente)
    conteudo = ET.SubElement(p, "Content", {"name": "SoundId"})
    ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % id_som
    ET.SubElement(p, "float", {"name": "Volume"}).text = volume
    ET.SubElement(p, "float", {"name": "PlaybackSpeed"}).text = pitch
    ET.SubElement(p, "float", {"name": "RollOffMaxDistance"}).text = "120"
    ET.SubElement(p, "bool", {"name": "Looped"}).text = "false"
    return item


def id_de_som(item):
    e = prop(item, "SoundId")
    if e is None:
        return None
    u = e.find("url")
    return (u.text if u is not None else e.text) or ""


def sonorizar(tool, nome, marca):
    """Acrescenta o que falta e conserta `SoundId` em branco. Devolve o relato."""
    relato = []
    handle = achar(tool, nome="Handle")
    if handle is None:
        return relato

    existentes = {}
    for _pai, filho in varrer(tool):
        if filho.get("class") == "Sound":
            existentes[texto(filho, "Name")] = filho

    for i, (som, ident, vol, pitch) in enumerate(SONS_QUE_FALTAM.get(nome, [])):
        if som in existentes:
            continue
        novo_som(handle, som, ident, vol, pitch, "GU_SFX_%s_%d" % (marca, i))
        relato.append("+Sound %s" % som)

    for som, (ident, vol, pitch) in SONS_A_CONSERTAR.get(nome, {}).items():
        alvo = existentes.get(som)
        if alvo is None:
            novo_som(handle, som, ident, vol, pitch, "GU_SFXC_%s" % marca)
            relato.append("+Sound %s" % som)
            continue
        if (id_de_som(alvo) or "").strip():
            continue
        e = prop(alvo, "SoundId")
        if e is None:
            e = ET.SubElement(props(alvo), "Content", {"name": "SoundId"})
        for filho in list(e):
            e.remove(filho)
        e.text = None
        ET.SubElement(e, "url").text = "rbxassetid://%s" % ident
        definir(alvo, "float", "Volume", vol)
        definir(alvo, "float", "PlaybackSpeed", pitch)
        relato.append("%s: SoundId vazio -> %s" % (som, ident))

    return relato


def preparar(dados, indice):
    (nome, tooltip, classe_dano, energia, recarga, chave,
     nome_servidor, extra) = dados
    marca = "%02d" % indice
    pasta = os.path.join(TOOLS, nome)
    caminho = os.path.join(pasta, "_ORIGEM.rbxmx")
    if not os.path.exists(caminho):
        print("sem _ORIGEM.rbxmx em Tools/%s — rode clonar_tool.py extrair" % nome)
        return None

    raiz = ET.parse(caminho).getroot()
    tool = raiz.find("Item")
    relato = []

    # 1. propriedade obrigatória
    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # 2. o que é proibido dentro de Tool sai da árvore
    for pai, filho in list(varrer(tool)):
        if filho.get("class") in CLASSES_PROIBIDAS:
            relato.append("-%s %s" % (filho.get("class"), texto(filho, "Name")))
            pai.remove(filho)

    for alvo in SCRIPTS_A_TIRAR.get(nome, []):
        for pai, filho in list(varrer(tool)):
            if texto(filho, "Name") == alvo and filho.get("class") in (
                    "Script", "LocalScript", "ModuleScript"):
                relato.append("-%s" % alvo)
                pai.remove(filho)

    # 3. Handle como filho direto — exigência do Roblox para RequiresHandle
    if achar(tool, nome="Handle") is None:
        fundo = None
        for pai, filho in varrer(tool):
            if texto(filho, "Name") == "Handle" and pai is not tool:
                fundo = (pai, filho)
                break
        if fundo:
            pai, filho = fundo
            pai.remove(filho)
            tool.append(filho)
            relato.append("Handle subiu de nível")
        else:
            handle_invisivel(tool, marca)
            relato.append("+Handle invisível")

    # 3b. Tool muda não é entrega
    relato.extend(sonorizar(tool, nome, marca))

    # 4. o Script de servidor ganha o nome da convenção
    objeto_servidor = "%s_Server_V1" % nome.replace(" ", "").replace(
        "(", "").replace(")", "")
    alvo = None
    for pai, filho in varrer(tool):
        if filho.get("class") == "Script" and texto(filho, "Name") == nome_servidor:
            alvo = filho
            break
    if alvo is None:
        alvo, _ = novo_item(tool, "Script", objeto_servidor, "GU_SRV_%s" % marca)
        ET.SubElement(props(alvo), "ProtectedString", {"name": "Source"}).text = ""
        relato.append("+Server")
    else:
        definir(alvo, "string", "Name", objeto_servidor)
        relato.append("%s -> %s" % (nome_servidor, objeto_servidor))

    # 5. Values de §12.4
    for classe, tag, alvo_nome, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", str(energia)),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        if achar(tool, classe, alvo_nome) is None:
            item, p = novo_item(tool, classe, alvo_nome,
                                "GU_%s_%s" % (alvo_nome[:6], marca))
            ET.SubElement(p, tag, {"name": "Value"}).text = valor

    # 6. remotes
    if achar(tool, "RemoteEvent", "VFXRemote") is None:
        novo_item(tool, "RemoteEvent", "VFXRemote", "GU_VFXR_%s" % marca)
    if extra and achar(tool, "RemoteEvent", "AcaoRemote") is None:
        novo_item(tool, "RemoteEvent", "AcaoRemote", "GU_ACAO_%s" % marca)

    # 7. os scripts do §12.10 que faltam
    for classe, alvo_nome in (("Script", "Client"),
                              ("ModuleScript", "R6CFrameAnimator"),
                              ("ModuleScript", "Poses"),
                              ("ModuleScript", "VFXModule")):
        if achar(tool, classe, alvo_nome) is not None:
            continue
        item, p = novo_item(tool, classe, alvo_nome,
                            "GU_%s_%s" % (alvo_nome[:10], marca))
        ET.SubElement(p, "ProtectedString", {"name": "Source"}).text = ""
        if alvo_nome == "Client":
            # RunContext = Client (2), NÃO LocalScript.
            #
            # LocalScript dentro de Tool só roda para o jogador cujo Character
            # a contém. O servidor manda o beat com FireAllClients e ele CHEGA
            # em todo mundo — mas o único ouvinte é o de quem está segurando.
            # Era por isso que o efeito aparecia só para o portador.
            ET.SubElement(p, "token", {"name": "RunContext"}).text = "2"
        relato.append("+%s" % alvo_nome)

    ET.ElementTree(raiz).write(caminho, encoding="utf-8", xml_declaration=True)
    return objeto_servidor, relato


def main():
    servidores = {}
    for indice, dados in enumerate(CONJUNTO, 1):
        saida = preparar(dados, indice)
        if saida is None:
            return 1
        objeto, relato = saida
        servidores[dados[0]] = objeto
        print("%-28s %s" % (dados[0], " · ".join(relato) or "nada a mudar"))

    # os .lua que a extração gravou e que não existem mais na árvore viram
    # código morto — o verificador cobra isso por nome
    print()
    for nome, _t, _c, _e, _r, _ch, nome_servidor, _x in CONJUNTO:
        pasta = os.path.join(TOOLS, nome)
        antigo = os.path.join(pasta, "%s.lua" % nome_servidor.replace(" ", "_"))
        novo = os.path.join(pasta, "%s.lua" % servidores[nome])
        if os.path.exists(antigo) and not os.path.exists(novo):
            os.rename(antigo, novo)
            print("%-28s %s.lua -> %s.lua"
                  % (nome, nome_servidor.replace(" ", "_"), servidores[nome]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
