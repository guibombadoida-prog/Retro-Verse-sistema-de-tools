#!/usr/bin/env python3
"""
preparar_cosmic.py — Retro-Verse / Studios

Escreve `Tools/Cosmic Sword Revamp/_ORIGEM.rbxmx`, a base da Tool depois da
cirurgia. O Lua vem depois, de `gerar_cosmic_sword.py`.

    python3 FERRAMENTAS/preparar_cosmic.py

════════════════════════════════════════════════════════════════════════
POR QUE ESTA TOOL PRECISOU DE CIRURGIA, E NÃO DE CONSERTO
════════════════════════════════════════════════════════════════════════

    `Cosmic Sword Revamp` nunca passou pelo pipeline. Ela é o modelo de
    terceiro `Sword of Cosmic Entity (Revamped)` com a habilidade Hawking
    enxertada por cima, e por isso acumulava os 24 problemas do
    `verificar_rbxmx` — o único vermelho que sobrou no repositório.

    O que estava lá dentro:

    ⛔ `Server` linha 10:  `require(125275839196878)`

       Um asset remoto, buscado por id e EXECUTADO NO SERVIDOR. É a mesma
       família do que apareceu no `reality_tools`: quem controla aquele asset
       controla o servidor de quem usar a Tool. Servia só para o rastro do
       corte do M1 — três `FireAllClients` de `Slash_Trail`. O rastro é
       desenhado aqui dentro agora, e o require sai.

    ✗ `remove` + 4 leituras de `ServerStorage` no `Server`

       O script `remove` mandava a pasta `CosmicVFX2` da Tool para o
       `ServerStorage` e, se já houvesse uma lá, `:Destroy()` na sua e no
       próprio script. É o ANTEPASSADO da Regra nº 2 — mesma ideia, destino
       errado: `ServerStorage` não replica, então o cliente NUNCA enxergava
       molde nenhum. Era por isso que a Tool não desenhava.

       O `DepositoVFX` faz o mesmo trabalho para `ReplicatedStorage`, cria ou
       reutiliza, e mantém as duas portas.

    ✗ Dois Servers e dois Clients

       O enxerto deixou `Server` + `Client` originais convivendo com
       `HawkingCosmicShurikenRadiation_Server_V1` + `_Client_V1`. Viram um de
       cada.

    ✗ O Client do Hawking era `LocalScript`

       Ele IMPLEMENTA os quatro efeitos `HAWKING_*` e o `PARAR` — bem escritos,
       com acumulador de dt e câmera devolvida. Mas `LocalScript` dentro de
       Tool só roda para quem segura: os outros jogadores não viam nada. Os
       efeitos viram `VFXModule` (ModuleScript) e o ouvinte vira `Script` com
       `RunContext = Client`.

    ✗ Seis `Animation` em `Animations/R6`

       `Animation`/`LoadAnimation` é proibido. As seis viram sequências de pose
       R6 CFrame no `Poses.lua`.

════════════════════════════════════════════════════════════════════════
O QUE A CIRURGIA NÃO TOCA
════════════════════════════════════════════════════════════════════════

    Handle, o `Model` Sword com as quatro Union, a pasta `CosmicVFX2` inteira
    com as suas malhas e emissores, os `Sound`, o `NormalGrip`, a
    `ThumbnailCamera`. O material é a verdade; só a LÓGICA foi refeita.

    Os `Sound` e emissores que moravam DENTRO do `Server` são RESGATADOS antes
    de o `Server` sair: som e emissor são asset, e apagar o script não pode
    apagar o asset junto. Os `Sound` vão para `Tool/SFX/`, os emissores e o
    `Trail` para `CosmicVFX2/`.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA = os.path.join(RAIZ, "Tools", "Cosmic Sword Revamp")
ENTRADA = os.path.join(PASTA, "Cosmic Sword Revamp.rbxmx")
SAIDA = os.path.join(PASTA, "_ORIGEM.rbxmx")

NOME_NOVO = "Cosmic Sword Revamp"

#: o que sai da Tool. `Server` leva os 8 scripts de tween junto — eles
#: animavam clone NO SERVIDOR, que replica a ~20 Hz sem interpolação; a
#: mesma coisa é feita por tween no cliente, no `VFXModule`.
FORA = (
    "remove",
    "Server",
    "Client",
    "Remote",
    "DirectionInvoker",
    "StartHeadCamera",
    "Animations",
    "HawkingCosmicShurikenRadiation_Server_V1",
    "HawkingCosmicShurikenRadiation_Client_V1",
)

#: os scripts que a Tool passa a ter. `clonar_tool.py` escreve o `Source` de
#: cada um a partir do `.lua` de mesmo nome na pasta.
NOVOS = (
    ("CosmicSwordRevamp_Server_V1", "Script"),
    ("Client", "LocalScript"),          # clonar_tool converte para RunContext=Client
    ("VFXModule", "ModuleScript"),
    ("Poses", "ModuleScript"),
    ("R6CFrameAnimator", "ModuleScript"),
)


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


def por_nome(item, nome):
    for filho in item.findall("Item"):
        if texto(filho, "Name") == nome:
            return filho
    return None


def novo_item(classe, nome, referent):
    it = ET.Element("Item", {"class": classe, "referent": referent})
    props = ET.SubElement(it, "Properties")
    s = ET.SubElement(props, "string", {"name": "Name"})
    s.text = nome
    return it


def resgatar(origem, sons, moldes):
    """Tira os assets de dentro de um script antes de o script sair.

    Som e emissor são ASSET; o script é lógica. Apagar a lógica não pode
    apagar o asset junto — foi o que quase aconteceu com os dez `Sound` que
    moravam dentro do `Server`.
    """
    for filho in list(origem.findall("Item")):
        classe = filho.get("class")
        if classe == "Sound":
            origem.remove(filho)
            sons.append(filho)
        elif classe in ("ParticleEmitter", "Trail", "Beam"):
            origem.remove(filho)
            moldes.append(filho)
        elif classe in ("Script", "LocalScript", "ModuleScript"):
            resgatar(filho, sons, moldes)


def main():
    if not os.path.exists(ENTRADA):
        print("faltando: %s" % ENTRADA)
        return 1

    ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    arvore = ET.parse(ENTRADA)
    raiz = arvore.getroot()
    tool = raiz.find("Item")
    if tool is None or tool.get("class") != "Tool":
        print("a raiz não traz uma Tool")
        return 1

    # 1. o nome
    antes = texto(tool, "Name")
    prop(tool, "Name").text = NOME_NOVO

    # 2. resgatar os assets de dentro dos scripts que vão sair
    sons, moldes = [], []
    for nome in FORA:
        alvo = por_nome(tool, nome)
        if alvo is not None and alvo.get("class") in (
                "Script", "LocalScript", "ModuleScript"):
            resgatar(alvo, sons, moldes)

    # 3. tirar os scripts mortos
    saiu = []
    for nome in FORA:
        alvo = por_nome(tool, nome)
        if alvo is not None:
            tool.remove(alvo)
            saiu.append(nome)

    # 4. os Sound resgatados vão para Tool/SFX/
    if sons:
        sfx = por_nome(tool, "SFX")
        if sfx is None:
            sfx = novo_item("Folder", "SFX", "RBXCOSMICSFXFOLDER0000000000000000")
            tool.append(sfx)
        vistos = set()
        for som in sons:
            nome = texto(som, "Name")
            if nome in vistos:
                continue
            vistos.add(nome)
            sfx.append(som)

    # 5. os emissores resgatados vão para CosmicVFX2/
    pack = por_nome(tool, "CosmicVFX2")
    if pack is not None:
        for molde in moldes:
            pack.append(molde)

    # 6. HawkingVFXRemote vira VFXRemote, e nasce o AcaoRemote
    hawking = por_nome(tool, "HawkingVFXRemote")
    if hawking is not None:
        prop(hawking, "Name").text = "VFXRemote"
    if por_nome(tool, "AcaoRemote") is None:
        tool.append(novo_item("RemoteEvent", "AcaoRemote",
                              "RBXCOSMICACAOREMOTE00000000000000"))

    # 7. os cinco scripts do pipeline
    for i, (nome, classe) in enumerate(NOVOS):
        if por_nome(tool, nome) is not None:
            continue
        it = novo_item(classe, nome, "RBXCOSMICSCRIPT%017d" % i)
        fonte = ET.SubElement(it.find("Properties"), "ProtectedString",
                              {"name": "Source"})
        fonte.text = "-- escrito por clonar_tool.py\n"
        tool.append(it)

    arvore.write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("Tool  %r -> %r" % (antes, NOME_NOVO))
    print("saiu  %s" % ", ".join(saiu))
    print("SFX   %d Sound resgatados de dentro dos scripts" % len(sons))
    print("pack  %d emissor/Trail resgatados para CosmicVFX2" % len(moldes))
    print("novos %s" % ", ".join(n for n, _ in NOVOS))
    print("")
    print("_ORIGEM.rbxmx escrito: %s" % SAIDA)
    return 0


if __name__ == "__main__":
    sys.exit(main())
