#!/usr/bin/env python3
"""
preparar_xester.py — Retro-Verse / Studios

Prepara a base de assets das 14 Tools do Xester: 7 da Forma 1 (o Mestre das
Cartas) e 7 da Forma 2 (O Despertar), em DOIS conjuntos separados.

    python3 FERRAMENTAS/preparar_xester.py

AS DUAS ORIGENS NÃO SE PARECEM EM NADA

    Forma 1 — 28 instâncias, ZERO BaseParts. É um script de free model
    convertido para FE: `MainModule.load(alvo)` clona um Script de 3477 linhas
    para dentro da `PlayerGui` de um jogador nomeado, e um `replicator` faz
    proxy de UserInputService e SetCore por 24 Remotes. Carta, máscara, orbe,
    onda — tudo nasce de `Instance.new` em tempo de execução.

    Mas o Xester é UM personagem em duas formas, e a Forma 2 traz o baralho
    dele montado: `cards` tem `card1`..`card4`, cada uma Part com dois `Decal`
    e um `PointLight`. É de lá que sai o Handle da Forma 1 e os quatro moldes de
    carta — mesmo personagem, mesmo baralho. **Nada da Forma 1 é desenhado
    aqui.**

    A carta do modelo mede 0.59 × 0.05; o script da Forma 1 usa 2.5 × 0.25 ×
    1.75 (`cardtable`). O molde entra com a geometria e os decais do modelo e o
    TAMANHO do script — fiel nos dois eixos.

    O que continua vindo por id, porque não existe instância dele em origem
    nenhuma: onda 20329976, anel 3270017, tempestade 6512150+55364685 e máscara
    5158270+9543585. São `rbxassetid://` dentro de instância filha da Tool, que
    a Regra nº 1 permite.

    Forma 2 — 402 instâncias, com `staff`, `cards`, `skully`, `energb`,
    `secondhead`, `enemy` e uma pasta `Effects` pronta. Aqui NADA é autoral:
    o Handle sai do próprio modelo (`staff/t` para as Tools de cajado,
    `pickaxe` para a do machado) e os moldes são as subárvores do original.

O QUE SAI

    Todo script da origem. Os dois `MainModule` (clonam script para dentro da
    PlayerGui de terceiro), o `replicator` e o `Handler` da Forma 1 (proxy de
    CoreGui), os `Weld`/`ai`/`core`/`skullscript` da Forma 2. Nenhum entra em
    Tool: a lógica é reescrita conforme as diretrizes.

    `Animation` e `ScreenGui` também saem — proibidos por diretriz.

O QUE ENTRA

    Scripts autorais vazios (o Source vem do `.lua`), `VFXRemote`, `AcaoRemote`
    para quem tem habilidade Extra, e os `Value`s que declaram a Tool.

MOLDE APAGADO, CLONE ACESO

    Tool equipada mora no workspace, então todo BasePart descendente RENDERIZA.
    Molde entra com `Transparency = 1` e `ParticleEmitter.Enabled = false` —
    propriedades, não script, então valem para todo cliente sem nada rodando.
    Quem acende é o `_rv_clone` do VFXModule, restaurando por caminho.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ENTRADA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Xester")

# `PRECISA_MIRA` e o `MiraRemote` saíram.
#
# Eles existiam porque a primária ficava em `Tool.Activated`, que não carrega
# ponto nenhum: cinco Tools precisavam de um terceiro canal só para dizer PARA
# ONDE. Agora o `Client` manda `VFXRemote:FireServer(mira())` — o ponto viaja
# no mesmo tiro que pede a habilidade, e as catorze miram. Um `RemoteEvent`
# que nenhum script lê é asset depositado e mudo, e uma porta a mais para
# validar.

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
PROIBIDAS = ("ScreenGui", "Animation", "BillboardGui", "SurfaceGui",
             "ColorCorrectionEffect", "Sky")

# ═══════════════════════════════════════════════════════════════
# A DISTRIBUIÇÃO — 12 habilidades na Forma 1, 8 na Forma 2
# ═══════════════════════════════════════════════════════════════
#
# Regra: piso 3, teto 7 Tools. Com 8 ou mais habilidades são 7 Tools e o
# excedente vira Extra na Tool de tema mais próximo (REGRA_DISTRIBUICAO §20).
#
# nome, tooltip, sequência primária, sequência Extra, tecla do Extra,
# classe de dano, energia, recarga, chave de recarga

FORMA1 = [
    ("Xester Ato de Desaparecer",
     "Some o alvo dentro de uma carta no chao. Extra: gargalhada.",
     "ATO_DE_DESAPARECER", "GARGALHADA", "Y",
     "ARCANO", 28, 24, "Xester_Desaparecer"),
    ("Xester Full House",
     "Abre um leque de 20 cartas em orbita e atira no clique.",
     "FULL_HOUSE", None, None,
     "ARCANO", 18, 14, "Xester_FullHouse"),
    ("Xester Cardnado",
     "Tempestade de cartas em volta do corpo, 35 pulsos. Extra: bola de fogo.",
     "CARDNADO", "BOLA_DE_FOGO", "Y",
     "ARCANO", 22, 20, "Xester_Cardnado"),
    ("Xester Teleporte",
     "Desaparece em fumaca e reaparece onde o mouse aponta.",
     "TELEPORTE", None, None,
     "ARCANO", 6, 3, "Xester_Teleporte"),
    ("Xester Carta Colossal",
     "Ergue uma carta de 24 studs e derruba. Extra: bola de fogo imensa.",
     "CARTA_COLOSSAL", "BOLA_DE_FOGO_IMENSA", "Y",
     "ARCANO", 30, 28, "Xester_CartaColossal"),
    ("Xester Buraco Negro",
     "Portal de carta que suga e colapsa. Extra: raio continuo.",
     "BURACO_NEGRO", "RAIO", "Y",
     "ARCANO", 45, 50, "Xester_BuracoNegro"),
    ("Xester Escudo de Cartas",
     "Carta na frente que rebate quem toca. Extra: sopro do dragao.",
     "ESCUDO_DE_CARTAS", "SOPRO_DO_DRAGAO", "Y",
     "ARCANO", 20, 16, "Xester_Escudo"),
]

# A Forma 2 leva um 10º campo: QUAIS subárvores da origem entram como molde.
# Mandar as oito em todas as sete daria 524 KB por Tool — e a Tool do machado
# carregaria o `enemy` de 112 peças que ela nunca invoca. Cada uma leva o que
# a habilidade usa, e só.
FORMA2 = [
    ("Xester Carta Ceifeira",
     "Tres cartas que perseguem e estouram no alvo.",
     "CARTA_CEIFEIRA", None, None,
     "CEIFA", 26, 22, "XesterD_Ceifeira", ["cards", "Effects", "staff"]),
    ("Xester Esfera do Fim",
     "Esfera carregada que suga e detona. Segure para carregar.",
     "ESFERA_DO_FIM", None, None,
     "CEIFA", 40, 44, "XesterD_Esfera", ["Effects", "energb", "staff"]),
    ("Xester Baralho Espectral",
     "Baralho de cartas espectrais em volta, 2.5s de conjuracao.",
     "BARALHO_ESPECTRAL", None, None,
     "CEIFA", 24, 20, "XesterD_Baralho", ["cards", "Effects", "staff"]),
    ("Xester Invocacao",
     "Chama um servo e uma cacapa de caveira no ponto do mouse.",
     "INVOCACAO", None, None,
     "CEIFA", 35, 40, "XesterD_Invocacao", ["enemy", "skully", "Effects", "staff"]),
    ("Xester Furia do Machado",
     "Saca o machado e avanca. Extra: gargalhada.",
     "FURIA_DO_MACHADO", "GARGALHADA", "Y",
     "CEIFA", 16, 12, "XesterD_Machado", ["Effects"]),
    ("Xester Procissao de Cartas",
     "Fileira de cartas que sobem do chao ate o ponto do mouse.",
     "PROCISSAO_DE_CARTAS", None, None,
     "CEIFA", 30, 26, "XesterD_Procissao", ["cards", "Effects", "staff"]),
    ("Xester Portal do Cajado",
     "Carta-portal na ponta do cajado que puxa e corta.",
     "PROCISSAO_DE_CARTAS", None, None,
     "CEIFA", 28, 24, "XesterD_Portal", ["cards", "Effects", "energb", "staff"]),
]


# ═══════════════════════════════════════════════════════════════
# XML
# ═══════════════════════════════════════════════════════════════

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
            for filho in list(e):
                e.remove(filho)
            return
    ET.SubElement(props, tag, {"name": nome}).text = valor


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


def achar(no, alvo):
    for item in no.iter("Item"):
        if texto(item, "Name") == alvo:
            return item
    return None


def renomear_referentes(copia, prefixo):
    """
    Renumera os `referent` de uma subárvore E reescreve todo `<Ref>` que
    apontava para eles.

    Renomear o referent sem mexer no `<Ref>` deixa o ponteiro pendurado —
    `Model.PrimaryPart` e `Motor6D.Part0` param de achar a peça, e o Studio
    recusa o arquivo. Já custou um "arquivo corrompido" neste repositório.
    """
    renomeado = {}
    for indice, no in enumerate(copia.iter("Item")):
        antigo = no.get("referent")
        novo = "%s%d" % (prefixo, indice)
        if antigo:
            renomeado[antigo] = novo
        no.set("referent", novo)

    for no in copia.iter("Item"):
        props = no.find("Properties")
        if props is None:
            continue
        for e in props:
            if e.tag != "Ref":
                continue
            alvo = (e.text or "").strip()
            if alvo in renomeado:
                e.text = renomeado[alvo]
            elif alvo and alvo != "null":
                # aponta para fora da subárvore: some com a peça de origem
                e.text = "null"
    return renomeado


def podar(item, removidos):
    """
    Tira script, classe proibida e Sound morto, em profundidade.

    O `enemy` traz o conjunto padrão de sons de personagem — `Died`, `Jumping`,
    `GettingUp` —, todos apontando para `rbxasset://sounds/...`. Quem os dispara
    é o script `Sound`/`LocalSound` do modelo, e esse script sai daqui: rodar
    script de terceiro com vida própria dentro de uma Tool é o oposto de
    autocontenção. Sem o disparador, o que fica é um Sound que nunca toca, com
    um `CharacterSoundEvent` pendurado — peça morta viajando dentro da Tool.
    """
    for filho in list(item.findall("Item")):
        classe = filho.get("class")
        if classe in CLASSES_SCRIPT or classe in PROIBIDAS:
            removidos.append((classe, texto(filho, "Name") or classe))
            item.remove(filho)
            continue
        som = (texto(filho, "SoundId") or "").strip()
        if classe == "Sound" and (not som or som.startswith("rbxasset://sounds/")):
            removidos.append((classe, texto(filho, "Name") or classe))
            item.remove(filho)
            continue
        podar(filho, removidos)
    return item


def apagar(item):
    """
    Molde entra invisível: Transparency = 1 e emissor desligado.

    É PROPRIEDADE, não script — vale para todo cliente sem nada rodando, e
    sobrevive ao `:Clone()` porque o `_rv_clone` restaura pelo caminho.
    """
    contados = 0
    for no in item.iter("Item"):
        classe = no.get("class")
        if classe in ("Part", "MeshPart", "UnionOperation", "WedgePart",
                      "TrussPart", "CornerWedgePart"):
            definir(no, "float", "Transparency", "1")
            definir(no, "bool", "CanCollide", "false")
            definir(no, "bool", "Anchored", "true")
            contados = contados + 1
        elif classe in ("ParticleEmitter", "Trail", "Beam", "Fire", "Smoke",
                        "Sparkles"):
            definir(no, "bool", "Enabled", "false")
            contados = contados + 1
        elif classe == "Decal" or classe == "Texture":
            definir(no, "float", "Transparency", "1")
            contados = contados + 1
        elif classe == "PointLight" or classe == "SpotLight":
            definir(no, "bool", "Enabled", "false")
            contados = contados + 1
    return contados


# ═══════════════════════════════════════════════════════════════
# FORMA 1 — carta do próprio modelo, malha de efeito por id
# ═══════════════════════════════════════════════════════════════

# BrickColor no XML do Roblox é o NÚMERO da cor, não o nome. Escrever
# `<string name="BrickColor">Really black</string>` passa no Studio mas quebra
# a conversão para .rbxm binário, que exige o tipo certo.
CORES = {
    "White": 1,
    "Really black": 1003,
    "Really red": 1004,
    "Bright orange": 106,
}

# Os quatro ases que o original sorteia em `aces`
ASES = ["1880203893", "1881287656", "1881287420", "1881288034"]

# malha, textura — todos vindos do script original
MALHAS = {
    "Onda": ("20329976", None),
    "Anel": ("3270017", None),
    "Tempestade": ("6512150", "55364685"),
    "Mascara": ("5158270", "9543585"),
}

# Sons que o original toca, por habilidade
SONS_F1 = {
    "Cardnado": ["342337569", "1072606965"],
    "FullHouse": ["1882057730", "1499747506"],
    "CartaColossal": ["236989198", "765590102"],
    "BuracoNegro": ["1888686669", "472579737"],
    "Teleporte": ["1894958339"],
    "Desaparecer": ["1888686669", "1898092341", "472214107", "54111471"],
    "Escudo": ["236989198", "288641686", "413682983"],
    "Fogo": ["842332424", "1982011510", "2014087015", "1910988873"],
}


# ═══════════════════════════════════════════════════════════════
# SFX — por PAPEL, e por Tool
# ═══════════════════════════════════════════════════════════════
#
# Antes existia uma pasta `SFX/` com 18 Sound chamados `S<id>` — e nenhuma
# linha que os tocasse. Nome de id não diz nada para quem escreve o beat, então
# nada era chamado. Agora cada Tool leva só os SEUS sons, com o nome do MOMENTO
# em que tocam, e o VFXModule chama por esse nome.
#
# Os ids são os do script original, no papel que ele lhes dava:
#   342337569 arranque do Cardnado · 1072606965 rugido sustentado
#   1882057730 leque abrindo · 1499747506 cartas saindo
#   236989198 carta colossal surgindo · 765590102 carta colossal batendo
#   1888686669 portal abrindo · 472579737 colapso do buraco negro
#   1894958339 teleporte · 1898092341 selo · 472214107 plataforma selando
#   54111471 fim do ato · 288641686 e 413682983 escudo
#   842332424 bola de fogo · 1982011510 bola imensa
#   2014087015 sopro do dragão · 1910988873 o raio

#: ⚠️ COMPLETADO PARA QUATRO POR TOOL — uma por habilidade.
#:
#: As 14 passaram de M1 + uma Extra para M1 + TRÊS, e Tool com quatro
#: habilidades e um som só toca a mesma coisa quatro vezes. Os ids acrescentados
#: já estavam NESTA MESMA TABELA, em outra Tool do conjunto: nenhum foi
#: inventado, e a paleta continua sendo a do `xesterv2`.
SONS_POR_TOOL = {
    "Xester Ato de Desaparecer": [
        ("SELA", "1898092341", 4, 1.0), ("AFUNDA", "472214107", 4, 0.85),
        ("FIM", "54111471", 5, 0.9), ("RISO", "1072606965", 3, 1.25),
    ],
    "Xester Full House": [
        ("ABRE", "1882057730", 4, 1.0), ("ATIRA", "1499747506", 3, 1.1),
        ('SEQUENCIA', '342337569', 4, 1.2),
        ('PUXA', '1888686669', 4, 0.95),
    ],
    "Xester Cardnado": [
        ("ARRANCA", "342337569", 5, 1.0), ("RUGE", "1072606965", 3, 1.0),
        ("FOGO", "842332424", 4, 1.15),
        ('OLHO', '1894958339', 4, 0.8),
    ],
    "Xester Teleporte": [
        ("SOME", "1894958339", 5, 1.0),
        ('MARCA', '1898092341', 4, 1.15),
        ('VOLTA', '1894958339', 5, 1.3),
        ('CORRENTE', '413682983', 4, 1.25),
    ],
    "Xester Carta Colossal": [
        ("ERGUE", "236989198", 4, 0.9), ("BATE", "765590102", 6, 0.85),
        ("FOGO", "1982011510", 5, 0.9),
        ('MURALHA', '236989198', 4, 0.75),
    ],
    "Xester Buraco Negro": [
        ("ABRE", "1888686669", 4, 0.75), ("COLAPSA", "472579737", 6, 0.8),
        ("RAIO", "1910988873", 5, 1.0),
        ('EJETA', '472579737', 5, 1.2),
    ],
    "Xester Escudo de Cartas": [
        ("SOBE", "236989198", 4, 1.05), ("REBATE", "288641686", 4, 1.0),
        ("ESTILHACA", "413682983", 4, 1.1), ("SOPRO", "2014087015", 5, 0.9),
    ],
    # Forma 2 — ids do `xesterv2`, no papel que ele lhes dava
    "Xester Carta Ceifeira": [
        ("SAI", "1544022435", 4, 1.0), ("CRAVA", "1843578719", 5, 0.95),
        ('CEIFA', '342337569', 4, 0.9),
        ('COLHEITA', '1910988873', 5, 0.8),
    ],
    "Xester Esfera do Fim": [
        ("CARREGA", "1845012046", 3, 1.0), ("DETONA", "142070127", 6, 0.85),
        ("ECO", "1040136448", 4, 0.9),
        ('ORBITA', '1845012046', 3, 1.3),
    ],
    "Xester Baralho Espectral": [
        ("CONJURA", "4255432837", 4, 1.0), ("GOLPE", "1301200629", 3, 1.1),
        ('NAIPE', '1499747506', 3, 1.2),
        ('ESPELHO', '288641686', 4, 1.05),
    ],
    "Xester Invocacao": [
        ("CHAMA", "3292075199", 5, 0.95), ("NASCE", "4571960003", 4, 1.0),
        ('COMANDA', '1072606965', 3, 0.9),
        ('LEGIAO', '1888686669', 4, 0.85),
    ],
    "Xester Furia do Machado": [
        ("SACA", "187042245", 4, 1.0), ("RISO", "1072606965", 3, 1.25),
        ('REDEMOINHO', '342337569', 4, 0.85),
        ('DECAPITA', '765590102', 6, 0.8),
    ],
    "Xester Procissao de Cartas": [
        ("SOBE", "3855293277", 4, 1.0),
        ('FORMACAO', '236989198', 4, 1.0),
        ('MARCHA', '933780081', 3, 1.1),
        ('DISSOLVE', '413682983', 4, 1.2),
    ],
    "Xester Portal do Cajado": [
        ("ABRE", "314678645", 4, 0.9), ("CORTA", "821439273", 4, 1.05),
        ('SAIDA', '1888686669', 4, 1.1),
        ('FECHA', '54111471', 5, 0.85),
    ],
}


def pasta_de_sfx(tool, nome, marca):
    """`Tool/SFX/` com os moldes de som, nomeados pelo MOMENTO em que tocam."""
    if nome not in SONS_POR_TOOL:
        return 0
    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_SFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS_POR_TOOL[nome]:
        _s, props = novo_item(sfx, "Sound", rotulo, "RV_SN%s_%s" % (rotulo, marca))
        ET.SubElement(props, "Content", {"name": "SoundId"}).append(ET.Element("url"))
        props[-1][0].text = "rbxassetid://%s" % ident
        ET.SubElement(props, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(props, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(props, "float", {"name": "RollOffMaxDistance"}).text = "220"
    return len(SONS_POR_TOOL[nome])


def parte(pai, nome, referent, tamanho, cor="Really black", material="Neon"):
    item, props = novo_item(pai, "Part", nome, referent)
    ET.SubElement(props, "Vector3", {"name": "size"})
    tam = props[-1]
    for eixo, valor in zip("XYZ", tamanho):
        ET.SubElement(tam, eixo).text = str(valor)
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(props, "float", {"name": "Transparency"}).text = "1"
    ET.SubElement(props, "token", {"name": "Material"}).text = (
        "288" if material == "Neon" else "256")
    ET.SubElement(props, "int", {"name": "BrickColor"}).text = str(CORES[cor])
    return item


TAMANHO_CARTA = (2.5, 0.25, 1.75)


def definir_tamanho(item, tamanho):
    """Reescreve o `size` mantendo o resto da peça como o modelo a entregou."""
    props = item.find("Properties")
    for e in list(props):
        if e.get("name") == "size":
            props.remove(e)
    tam = ET.SubElement(props, "Vector3", {"name": "size"})
    for eixo, valor in zip("XYZ", tamanho):
        ET.SubElement(tam, eixo).text = str(valor)


def cartas_do_modelo(fonte):
    """As quatro cartas reais do Xester, do `cards` da Forma 2."""
    baralho = achar(fonte, "cards")
    if baralho is None:
        return []
    saida = []
    for alvo in ("card1", "card2", "card3", "card4"):
        peca = achar(baralho, alvo)
        if peca is not None:
            saida.append(peca)
    return saida


def moldes_forma1(tool, marca, fonte):
    """
    Cria `Moldes/` e `SFX/` da Forma 1.

    As cartas vêm do baralho do PRÓPRIO Xester (`cards` da Forma 2) — é o mesmo
    personagem, e é o único lugar onde a carta dele existe como instância. Só o
    tamanho é reescrito, para o do `cardtable` do script da Forma 1.
    """
    moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % marca)

    baralho = cartas_do_modelo(fonte)
    if not baralho:
        return None, None
    for indice, peca in enumerate(baralho):
        copia = ET.fromstring(ET.tostring(peca))
        podar(copia, [])
        definir(copia, "string", "Name", "Carta%d" % (indice + 1))
        definir_tamanho(copia, TAMANHO_CARTA)
        apagar(copia)
        renomear_referentes(copia, "RV_CT%d_%s_" % (indice + 1, marca))
        moldes.append(copia)

    # as malhas de efeito
    for nome, (malha, textura) in MALHAS.items():
        base = parte(moldes, nome, "RV_M%s_%s" % (nome[:3], marca), (1, 1, 1),
                     cor="White")
        _m, mp = novo_item(base, "SpecialMesh", "Mesh",
                           "RV_MM%s_%s" % (nome[:3], marca))
        ET.SubElement(mp, "token", {"name": "MeshType"}).text = "5"
        ET.SubElement(mp, "Content", {"name": "MeshId"}).append(ET.Element("url"))
        mp[-1][0].text = "rbxassetid://%s" % malha
        if textura:
            ET.SubElement(mp, "Content", {"name": "TextureId"}).append(
                ET.Element("url"))
            mp[-1][0].text = "rbxassetid://%s" % textura

    # o orbe, bola Neon que o original usa em quantidade
    orbe = parte(moldes, "Orbe", "RV_MOR_%s" % marca, (2, 2, 2), cor="White")
    ET.SubElement(orbe.find("Properties"), "token", {"name": "shape"}).text = "0"

    return len(ASES) + len(MALHAS) + 1, 0


def handle_forma1(tool, marca, fonte):
    """
    O Handle da Forma 1 é a carta do PRÓPRIO Xester.

    A origem da Forma 1 não tem uma única BasePart — carta, máscara e orbe
    nascem de `Instance.new` dentro do script. Mas a Forma 2 é o mesmo
    personagem e traz o baralho montado, então o Handle sai de `cards/card1`,
    com os decais e o `PointLight` que o modelo já lhe deu.

    Do script vem só o tamanho (2.5 × 0.25 × 1.75, do `cardtable`), porque a
    carta do modelo é miniatura de mão e o Handle precisa da escala de jogo.
    """
    baralho = cartas_do_modelo(fonte)
    if not baralho:
        return None

    copia = ET.fromstring(ET.tostring(baralho[0]))
    podar(copia, [])
    definir(copia, "string", "Name", "Handle")
    definir_tamanho(copia, TAMANHO_CARTA)
    definir(copia, "bool", "CanCollide", "false")
    definir(copia, "bool", "Anchored", "false")
    definir(copia, "float", "Transparency", "0")
    for no in copia.iter("Item"):
        if no.get("class") in ("Decal", "Texture"):
            definir(no, "float", "Transparency", "0")
        elif no.get("class") in ("PointLight", "SpotLight"):
            definir(no, "bool", "Enabled", "true")
    renomear_referentes(copia, "RV_HD_%s_" % marca)
    copia.set("referent", "RV_HDL_%s" % marca)
    tool.append(copia)
    return copia


# ═══════════════════════════════════════════════════════════════
# FORMA 2 — tudo vem do próprio modelo
# ═══════════════════════════════════════════════════════════════

def handle_forma2(tool, fonte, marca, usa_machado):
    """
    O Handle sai do PRÓPRIO modelo: `pickaxe` para a Tool do machado, `staff/t`
    para as de cajado. Nenhuma geometria inventada.
    """
    if usa_machado:
        origem = achar(fonte, "pickaxe")
    else:
        staff = achar(fonte, "staff")
        origem = achar(staff, "t") if staff is not None else None
    if origem is None:
        return None

    copia = ET.fromstring(ET.tostring(origem))
    podar(copia, [])
    definir(copia, "string", "Name", "Handle")
    definir(copia, "bool", "CanCollide", "false")
    definir(copia, "bool", "Anchored", "false")
    definir(copia, "float", "Transparency", "0")
    renomear_referentes(copia, "RV_HD_%s_" % marca)
    copia.set("referent", "RV_HDL_%s" % marca)
    tool.append(copia)
    return copia


def moldes_forma2(tool, fonte, marca, quais):
    moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % marca)
    apagados, trazidos = 0, []
    for alvo in quais:
        origem = achar(fonte, alvo)
        if origem is None:
            continue
        copia = ET.fromstring(ET.tostring(origem))
        podar(copia, [])
        apagados = apagados + apagar(copia)
        renomear_referentes(copia, "RV_%s_%s_" % (alvo[:3], marca))
        moldes.append(copia)
        trazidos.append(alvo)
    return apagados, trazidos


# ═══════════════════════════════════════════════════════════════

def equipar(tool, dados, marca, extra):
    (nome, tooltip, _seq, _sqx, tecla, classe_dano, energia, recarga,
     chave) = dados[:9]

    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # Os DOIS remotes, nas catorze. `AcaoRemote` era condicional a `extra`
    # porque a Tool tinha zero ou uma Extra; agora são três em todas, e o
    # `Server` faz `WaitForChild("AcaoRemote")` — sem o RemoteEvent na árvore
    # ele trava no `WaitForChild` e a Tool inteira não liga.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_ACA_%s" % marca)

    valores = [
        ("StringValue", "string", "DamageClass", classe_dano),
        ("StringValue", "string", "ChaveRecarga", chave),
        ("NumberValue", "float", "EnergyCost", str(energia)),
        ("NumberValue", "float", "RecargaGlobal", str(recarga)),
    ]
    # `TeclaExtra` saiu. Ele existia porque cada Tool tinha UMA Extra com tecla
    # própria; agora são três, fixas em R, T e Y, e o cliente as declara. Value
    # que nenhum script lê é asset depositado e mudo.
    for classe, tag, alvo, valor in valores:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:6], marca))
        ET.SubElement(props, tag, {"name": "Value"}).text = valor

    for classe, alvo in (
        ("Script", "%s_Server_V1" % nome.replace(" ", "")),
        ("Script", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ):
        item, props = novo_item(tool, classe, alvo,
                                "RV_%s_%s" % (alvo.replace(" ", "")[:14], marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""
        if alvo == "Client":
            # RunContext = Client (2), NÃO LocalScript. LocalScript dentro de
            # Tool só roda para quem a segura, então o VFX das 14 aparecia só
            # para o portador. Este é o mesmo conserto do `collector`.
            ET.SubElement(props, "token", {"name": "RunContext"}).text = "2"


def montar(conjunto, fonte, forma, relatorio, compartilhadas):
    for dados in conjunto:
        nome = dados[0]
        marca = nome.replace(" ", "")
        extra = dados[3] is not None

        tool = ET.Element("Item", {"class": "Tool", "referent": "RV_T_%s" % marca})
        ET.SubElement(tool, "Properties")
        equipar(tool, dados, marca, extra)

        if forma == 1:
            if handle_forma1(tool, marca, fonte) is None:
                print("  PAREI: não achei `cards/card1` na origem para o Handle")
                return False
            n_moldes, n_sons = moldes_forma1(tool, marca, fonte)
            if n_moldes is None:
                print("  PAREI: não achei o baralho `cards` na origem")
                return False
            detalhe = "%d moldes (4 cartas do modelo), %d sons" % (n_moldes, n_sons)
        else:
            usa_machado = "Machado" in nome
            if handle_forma2(tool, fonte, marca, usa_machado) is None:
                print("  PAREI: não achei o Handle de origem para %s" % nome)
                return False
            apagados, trazidos = moldes_forma2(tool, fonte, marca, dados[9])
            detalhe = "%d moldes apagados, de %s" % (apagados, "/".join(trazidos))

        n_sons = pasta_de_sfx(tool, nome, marca)
        detalhe = detalhe + ", %d som(ns)" % n_sons

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)
        raiz = nova_raiz()
        raiz.append(tool)

        # A tabela de SharedStrings é IRMÃ do <Item>, não descendente. As peças
        # da Forma 2 (UnionOperation, MeshPart) citam md5 que só existe nela;
        # sair sem a tabela deixa o md5 pendurado, e o Studio responde
        # "arquivo corrompido" sem dizer por quê. Já aconteceu neste repositório.
        citadas = sorted({(e.text or "").strip() for e in raiz.iter("SharedString")
                          if e.get("name")})
        citadas = [c for c in citadas if c]
        if citadas:
            bloco = ET.SubElement(raiz, "SharedStrings")
            for md5 in citadas:
                if md5 not in compartilhadas:
                    print("  PAREI: md5 %s citado e ausente da origem" % md5)
                    return False
                ET.SubElement(bloco, "SharedString",
                              {"md5": md5}).text = compartilhadas[md5]

        ET.ElementTree(raiz).write(os.path.join(pasta, "_ORIGEM.rbxmx"),
                                   encoding="utf-8", xml_declaration=False)
        relatorio.append((nome, "Extra" if extra else "—", detalhe))
    return True


# ═══════════════════════════════════════════════════════════════
# SUPERADO COMO SCRIPT — CONTINUA VIVO COMO BIBLIOTECA
#
# As 14 Tools que este arquivo montava saíram do repositório: o desenho novo do
# Xester é UMA Tool com duas formas, e quem a monta é `preparar_xester_v2.py`.
#
# O que ficou é o que tem valor independente das 14: `achar`, `podar`,
# `apagar`, `definir`, `renomear_referentes`, `parte`, `novo_item` e as tabelas
# `MALHAS` e `TAMANHO_CARTA`. O `v2` importa tudo isso daqui.
#
# `main` foi trocado por um aviso. Rodá-lo recriaria catorze pastas de Tool que
# ninguém monta mais, e um `Tools/` com Tool morta é pior do que um a menos.
# ═══════════════════════════════════════════════════════════════

def main():
    print("preparar_xester.py virou BIBLIOTECA — não monta mais nada.")
    print("")
    print("  As 14 Tools que ele montava saíram do repositório. O Xester")
    print("  agora é UMA Tool com duas formas:")
    print("")
    print("      python3 FERRAMENTAS/preparar_xester_v2.py")
    print("")
    print("  Os helpers de extração continuam aqui, e o v2 os importa.")
    return 1


def _antigo_main():
    
    f2 = os.path.join(ENTRADA, "Xester_Forma2_O_Despertar.rbxmx")
    if not os.path.exists(f2):
        print("origem da Forma 2 não encontrada: %s" % f2)
        return 1
    fonte2 = ET.parse(f2).getroot()

    print("PREPARAÇÃO DA BASE — Xester")
    print("")
    print("  A Forma 1 não tem uma única BasePart, mas o Xester é o mesmo")
    print("  personagem nas duas: Handle e cartas saem do baralho `cards` da")
    print("  Forma 2, com o tamanho do `cardtable` da Forma 1. Nada autoral.")
    print("")

    relatorio = []
    # a tabela de SharedStrings da origem, para reemitir só o que for citado
    compartilhadas = {}
    for e in fonte2.iter("SharedString"):
        if e.get("md5"):
            compartilhadas[e.get("md5")] = e.text or ""

    if not montar(FORMA1, fonte2, 1, relatorio, compartilhadas):
        return 1
    if not montar(FORMA2, fonte2, 2, relatorio, compartilhadas):
        return 1

    for nome, extra, detalhe in relatorio:
        print("  %-30s %-6s %s" % (nome, extra, detalhe))
    print("")
    print("%d Tool(s) preparada(s). Nenhum script da origem entrou." % len(relatorio))
    return 0


if __name__ == "__main__":
    sys.exit(main())
