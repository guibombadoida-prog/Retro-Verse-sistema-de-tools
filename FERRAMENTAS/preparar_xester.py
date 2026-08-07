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

    Consequência honesta: **o Handle e os moldes da Forma 1 são AUTORAIS**. Não
    havia o que reaproveitar. O que foi preservado do original são os números:
    tamanho da carta (2.5 × 0.25 × 1.75), os quatro ases do `aces`, a malha de
    onda 20329976, o anel 3270017, a tempestade 6512150+55364685 e a máscara
    5158270+9543585. A geometria é a mesma; quem a instancia é que mudou.

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


def podar(item, removidos):
    """Tira script e classe proibida, em profundidade."""
    for filho in list(item.findall("Item")):
        classe = filho.get("class")
        if classe in CLASSES_SCRIPT or classe in PROIBIDAS:
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
# FORMA 1 — moldes autorais, porque a origem não tem BasePart
# ═══════════════════════════════════════════════════════════════

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
    ET.SubElement(props, "string", {"name": "BrickColor"}).text = cor
    return item


def moldes_forma1(tool, marca):
    """Cria `Moldes/` e `SFX/` da Forma 1 — geometria autoral, números do original."""
    moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % marca)

    # as quatro cartas do baralho, com o tamanho exato do original
    for indice, ace in enumerate(ASES):
        carta = parte(moldes, "Carta%d" % (indice + 1),
                      "RV_CT%d_%s" % (indice + 1, marca), (2.5, 0.25, 1.75))
        for face in ("Top", "Bottom"):
            _d, dp = novo_item(carta, "Decal", "Face%s" % face,
                               "RV_CD%d%s_%s" % (indice + 1, face[0], marca))
            ET.SubElement(dp, "Content", {"name": "Texture"}).append(
                ET.Element("url"))
            dp[-1][0].text = "rbxassetid://%s" % ace
            ET.SubElement(dp, "token", {"name": "Face"}).text = (
                "1" if face == "Top" else "4")
            ET.SubElement(dp, "float", {"name": "Transparency"}).text = "1"

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

    # sons
    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_SFX_%s" % marca)
    vistos = []
    for lista in SONS_F1.values():
        for ident in lista:
            if ident in vistos:
                continue
            vistos.append(ident)
            _s, sp = novo_item(sfx, "Sound", "S%s" % ident,
                               "RV_SN%s_%s" % (ident, marca))
            ET.SubElement(sp, "Content", {"name": "SoundId"}).append(
                ET.Element("url"))
            sp[-1][0].text = "rbxassetid://%s" % ident
            ET.SubElement(sp, "float", {"name": "Volume"}).text = "3"
    return len(ASES) + len(MALHAS) + 1, len(vistos)


def handle_forma1(tool, marca):
    """
    O Handle da Forma 1 é AUTORAL — a origem não tem uma única BasePart.

    É a carta do baralho, com o tamanho que o original usa em `cardtable`
    (2.5 × 0.25 × 1.75) e o ás de espadas do `aces`. Fica declarado no
    relatório: não foi extraído, foi desenhado a partir dos números do script.
    """
    item, props = novo_item(tool, "Part", "Handle", "RV_HDL_%s" % marca)
    tam = ET.SubElement(props, "Vector3", {"name": "size"})
    for eixo, valor in zip("XYZ", (2.5, 0.25, 1.75)):
        ET.SubElement(tam, eixo).text = str(valor)
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(props, "token", {"name": "Material"}).text = "288"
    ET.SubElement(props, "string", {"name": "BrickColor"}).text = "Really black"
    for face, token in (("Top", "1"), ("Bottom", "4")):
        _d, dp = novo_item(item, "Decal", "Ace%s" % face,
                           "RV_HD%s_%s" % (face[0], marca))
        ET.SubElement(dp, "Content", {"name": "Texture"}).append(ET.Element("url"))
        dp[-1][0].text = "rbxassetid://%s" % ASES[0]
        ET.SubElement(dp, "token", {"name": "Face"}).text = token
    return item


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
    copia.set("referent", "RV_HDL_%s" % marca)
    for indice, no in enumerate(copia.iter("Item")):
        if no is not copia:
            no.set("referent", "RV_HD%d_%s" % (indice, marca))
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
        for indice, no in enumerate(copia.iter("Item")):
            no.set("referent", "RV_%s%d_%s" % (alvo[:3], indice, marca))
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

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFX_%s" % marca)
    if extra:
        novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_ACA_%s" % marca)

    valores = [
        ("StringValue", "string", "DamageClass", classe_dano),
        ("StringValue", "string", "ChaveRecarga", chave),
        ("NumberValue", "float", "EnergyCost", str(energia)),
        ("NumberValue", "float", "RecargaGlobal", str(recarga)),
    ]
    if extra:
        valores.append(("StringValue", "string", "TeclaExtra", tecla))
    for classe, tag, alvo, valor in valores:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:6], marca))
        ET.SubElement(props, tag, {"name": "Value"}).text = valor

    for classe, alvo in (
        ("Script", "%s_Server_V1" % nome.replace(" ", "")),
        ("LocalScript", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ):
        item, props = novo_item(tool, classe, alvo,
                                "RV_%s_%s" % (alvo.replace(" ", "")[:14], marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""


def montar(conjunto, fonte, forma, relatorio):
    for dados in conjunto:
        nome = dados[0]
        marca = nome.replace(" ", "")
        extra = dados[3] is not None

        tool = ET.Element("Item", {"class": "Tool", "referent": "RV_T_%s" % marca})
        ET.SubElement(tool, "Properties")
        equipar(tool, dados, marca, extra)

        if forma == 1:
            handle_forma1(tool, marca)
            n_moldes, n_sons = moldes_forma1(tool, marca)
            detalhe = "%d moldes autorais, %d sons" % (n_moldes, n_sons)
        else:
            usa_machado = "Machado" in nome
            if handle_forma2(tool, fonte, marca, usa_machado) is None:
                print("  PAREI: não achei o Handle de origem para %s" % nome)
                return False
            apagados, trazidos = moldes_forma2(tool, fonte, marca, dados[9])
            detalhe = "%d moldes apagados, de %s" % (apagados, "/".join(trazidos))

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)
        raiz = nova_raiz()
        raiz.append(tool)
        ET.ElementTree(raiz).write(os.path.join(pasta, "_ORIGEM.rbxmx"),
                                   encoding="utf-8", xml_declaration=False)
        relatorio.append((nome, "Extra" if extra else "—", detalhe))
    return True


def main():
    f2 = os.path.join(ENTRADA, "Xester_Forma2_O_Despertar.rbxmx")
    if not os.path.exists(f2):
        print("origem da Forma 2 não encontrada: %s" % f2)
        return 1
    fonte2 = ET.parse(f2).getroot()

    print("PREPARAÇÃO DA BASE — Xester")
    print("")
    print("  Forma 1 tem ZERO BaseParts na origem: Handle e moldes são")
    print("  AUTORAIS, com os números do script (carta 2.5x0.25x1.75, ases")
    print("  1880203893.., onda 20329976, anel 3270017, máscara 5158270).")
    print("")

    relatorio = []
    if not montar(FORMA1, None, 1, relatorio):
        return 1
    if not montar(FORMA2, fonte2, 2, relatorio):
        return 1

    for nome, extra, detalhe in relatorio:
        print("  %-30s %-6s %s" % (nome, extra, detalhe))
    print("")
    print("%d Tool(s) preparada(s). Nenhum script da origem entrou." % len(relatorio))
    return 0


if __name__ == "__main__":
    sys.exit(main())
