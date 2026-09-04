#!/usr/bin/env python3
"""
preparar_tempo.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto TEMPO, a partir do `timetools.rbxmx`.

    python3 FERRAMENTAS/preparar_tempo.py

Escreve `MODELOS_ENTRADA/Time_Tools/Tempo_7_Tools.rbxmx`.

════════════════════════════════════════════════════════════════════════
DUAS TOOLS HERDAM O HANDLE DA ORIGEM. AS OUTRAS CINCO, NÃO.
════════════════════════════════════════════════════════════════════════

    `Cajado Celeste` recebe o `CelestialStaffModel` INTEIRO — as 33 peças
    soldadas, as duas `MeshPart` (`ARC` e `Meshes/C`) e os quatro `Sound` do
    Handle. `Reversao` recebe o Handle do `reverter!!` com os dois `Sound`
    dele.

    Isso não é economia: é a regra que já custou uma leva inteira. Quando o
    modelo TRAZ geometria, remontá-la em código entrega outra coisa — passa em
    todo verificador e não é a Tool que o autor mandou.

    `Para o tempo` não tem Handle nenhum (`RequiresHandle = false`), então a
    `Instante Parado` ganha um autoral. E as outras quatro são Tools que a
    origem não tinha: elas nascem aqui.

════════════════════════════════════════════════════════════════════════
O QUE É PODADO DA SUBÁRVORE COPIADA
════════════════════════════════════════════════════════════════════════

    Da origem vem GEOMETRIA e SOM. Não vem:

      Script / LocalScript / ModuleScript   a lógica é reescrita (§12.12.1)
      ScreenGui                             proibido dentro de Tool
      ColorCorrectionEffect / BlurEffect    estado global do place
      Animation                             asset de animação, proibido
      Sky                                   proibido

    A poda é por CLASSE e recursiva. Um `ScreenGui` escondido três níveis
    abaixo de um Handle entraria junto sem ninguém ver.

════════════════════════════════════════════════════════════════════════
TRÊS HABILIDADES POR TOOL — M1 + `R` + `T`
════════════════════════════════════════════════════════════════════════

    21 habilidades. O `AcaoRemote` é UM só: quem diferencia é o nome da tecla
    no payload, conferido no servidor antes de agir.

    Só o `Fim do Relogio` tem `CutsceneRemote`: é a ultimate do conjunto.
"""

import copy
import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item, renomear_referentes  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Time_Tools", "timetools.rbxmx")
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Time_Tools",
                     "Tempo_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568, "ForceField": 1584}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

#: classes que NÃO atravessam a poda
PODAR = ("Script", "LocalScript", "ModuleScript", "ScreenGui",
         "ColorCorrectionEffect", "BlurEffect", "Animation", "Sky",
         "SunRaysEffect", "BloomEffect", "DepthOfFieldEffect")

#: quem herda Handle da origem: Tool nova -> Tool da origem
HERDA_HANDLE = {
    "Cajado Celeste": "Celestial Staff",
    "Reversao": "reverter!!",
}

#: só a ultimate tem cena
COM_CUTSCENE = ("Fim do Relogio",)


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — os 14 ids do `SFX/ids.md` da ficha, nenhum inventado
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Instante Parado": [
        ("TRAVA", "12221967", 4, 1.1),         # Press
        ("PARA", "5326246476", 6, 1.0),        # Timestop
        ("RETOMA", "3101648169", 5, 1.0),      # Resume
    ],
    "Reversao": [
        ("MARCA", "3373995015", 4, 1.0),       # Epitaph
        ("VOLTA", "3373991228", 5, 1.0),       # Erase
        ("EU", "3101648169", 5, 1.15),         # Resume
    ],
    "Cajado Celeste": [
        ("LANCA", "4750661969", 4, 1.0),       # Cast
        ("HOLOFOTE", "4953086953", 5, 0.9),    # Effect
        ("LAMINA", "4953084421", 5, 1.05),     # Aura
    ],
    "Aceleracao": [
        ("GOLPE", "127416781", 4, 1.25),       # ChargeReady
        ("PASSO", "4750661969", 4, 1.3),       # Cast
        ("ENVELHECE", "116049255", 5, 0.85),   # TimeSound
    ],
    "Lentidao": [
        ("PESO", "65068518", 4, 0.8),          # Break
        ("CAMPO", "5326246476", 5, 0.75),      # Timestop
        ("SEGUNDO", "116049255", 5, 0.7),      # TimeSound
    ],
    "Paradoxo": [
        ("ECO", "3748210376", 4, 1.1),         # Pulse
        ("DUPLO", "3373995015", 4, 1.2),       # Epitaph
        ("COLAPSO", "163064102", 6, 0.85),     # Explosion
    ],
    "Fim do Relogio": [
        ("PONTEIRO", "116049255", 4, 1.0),     # TimeSound
        ("AMPULHETA", "127416781", 5, 0.9),    # ChargeReady
        ("FIM", "5642129054", 6, 0.75),        # ExplosionSound
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES AUTORAIS — as cinco que a origem não trazia
#
# (nome, tamanho, forma, cor, material, deslocamento)
# ═══════════════════════════════════════════════════════════════

BRONZE = cor(186, 148, 84)
VIDRO = cor(206, 224, 255)
AZUL_GELO = cor(167, 184, 255)      # a cor da esfera do `Para o tempo`
FERRO = cor(64, 66, 74)
AREIA = cor(226, 206, 156)
VERMELHO = cor(255, 47, 47)         # a cor do `beforeimage` do `reverter!!`
DOURADO = cor(255, 208, 96)

HANDLES = {
    # o relógio de bolso: caixa, mostrador e corrente
    "Instante Parado": [
        ("Handle", (0.4, 1.6, 0.4), "Block", BRONZE, "Metal", (0, 0, 0)),
        ("Caixa", (2.2, 0.4, 2.2), "Cylinder", BRONZE, "Metal", (0, 1.5, 0)),
        ("Mostrador", (1.8, 0.16, 1.8), "Cylinder", VIDRO, "Glass", (0, 1.72, 0)),
        ("Nucleo", (0.6, 0.6, 0.6), "Ball", AZUL_GELO, "Neon", (0, 1.5, 0)),
        ("Corrente", (0.12, 1.4, 0.12), "Block", BRONZE, "Metal", (0, -1.1, 0)),
    ],
    # a ampulheta virada de lado: areia correndo depressa
    "Aceleracao": [
        ("Handle", (0.42, 1.8, 0.42), "Block", FERRO, "Metal", (0, 0, 0)),
        ("BulboAlto", (1.5, 1.2, 1.5), "Ball", VIDRO, "Glass", (0, 2.4, 0)),
        ("BulboBaixo", (1.5, 1.2, 1.5), "Ball", VIDRO, "Glass", (0, 1.0, 0)),
        ("Garganta", (0.4, 0.5, 0.4), "Cylinder", BRONZE, "Metal", (0, 1.7, 0)),
        ("Areia", (0.9, 0.9, 0.9), "Ball", AREIA, "Neon", (0, 1.0, 0)),
    ],
    # o pêndulo: haste longa e peso na ponta
    "Lentidao": [
        ("Handle", (0.4, 2.0, 0.4), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Haste", (0.12, 3.6, 0.12), "Block", BRONZE, "Metal", (0, 2.6, 0)),
        ("Peso", (1.4, 0.3, 1.4), "Cylinder", BRONZE, "Metal", (0, 4.3, 0)),
        ("Brilho", (1.0, 1.0, 1.0), "Ball", AZUL_GELO, "Neon", (0, 4.3, 0)),
    ],
    # o paradoxo: dois ponteiros cruzados, um deles vermelho
    "Paradoxo": [
        ("Handle", (0.4, 1.8, 0.4), "Block", FERRO, "Metal", (0, 0, 0)),
        ("PonteiroA", (0.16, 3.2, 0.5), "Block", DOURADO, "Neon", (0, 2.2, 0)),
        ("PonteiroB", (3.2, 0.16, 0.5), "Block", VERMELHO, "Neon", (0, 2.2, 0)),
        ("Eixo", (0.7, 0.7, 0.7), "Ball", BRONZE, "Metal", (0, 2.2, 0)),
    ],
    # o mostrador rachado: a ultimate
    "Fim do Relogio": [
        ("Handle", (0.5, 1.8, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Mostrador", (3.4, 0.34, 3.4), "Cylinder", BRONZE, "Metal",
         (0, 2.4, 0)),
        ("Vidro", (3.0, 0.14, 3.0), "Cylinder", VIDRO, "Glass", (0, 2.62, 0)),
        ("Racha", (3.2, 0.2, 0.18), "Block", VERMELHO, "Neon", (0, 2.62, 0)),
        ("Nucleo", (1.0, 1.0, 1.0), "Ball", DOURADO, "Neon", (0, 2.4, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Instante Parado",
     "Trava um alvo no clique. R congela a area toda; T retoma, e o que ficou "
     "guardado cai de uma vez.",
     "ARCANO", 1.0, 20, 16, "Tempo_Instante"),

    ("Reversao",
     "Marca o instante. R devolve o alvo ao que ele era; T devolve VOCE.",
     "ARCANO", 1.0, 18, 26, "Tempo_Reversao"),

    ("Cajado Celeste",
     "M1 muda com a hora: chuva de fotons no sol, lamina no luar. R e o "
     "holofote; T e o eco do instante.",
     "ASTRAL", 0.8, 13, 22, "Tempo_Cajado"),

    ("Aceleracao",
     "Golpe rapido demais para ler. R acelera o seu passo; T envelhece o alvo.",
     "MELEE", 0.6, 14, 19, "Tempo_Aceleracao"),

    ("Lentidao",
     "Cada golpe pesa mais. R e o campo lento; T estica um segundo so.",
     "ARCANO", 0.9, 15, 21, "Tempo_Lentidao"),

    ("Paradoxo",
     "Deixa um eco de voce. R faz o eco lutar junto; T colapsa a linha inteira.",
     "ARCANO", 0.9, 17, 24, "Tempo_Paradoxo"),

    ("Fim do Relogio",
     "O ponteiro varre. R e a ampulheta que puxa; T e o Fim do Relogio, com cena.",
     "EXPLOSIVO", 1.2, 20, 42, "Tempo_Fim"),
]


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


def podar(item):
    """Tira as classes proibidas da subárvore, recursivamente.

    Por CLASSE, não por nome: um `ScreenGui` três níveis abaixo de um Handle
    entraria junto sem ninguém ver, e `ScreenGui` dentro de Tool é proibido.
    """
    cortados = []
    for filho in list(item.findall("Item")):
        if filho.get("class") in PODAR:
            item.remove(filho)
            cortados.append(filho.get("class"))
        else:
            cortados.extend(podar(filho))
    return cortados


def vetor(props, tag, nome, valores):
    v = ET.SubElement(props, tag, {"name": nome})
    for eixo, valor in zip("XYZ", valores):
        ET.SubElement(v, eixo).text = "%.4g" % valor
    return v


def cor3(props, nome, rgb):
    c = ET.SubElement(props, "Color3", {"name": nome})
    for canal, valor in zip(("R", "G", "B"), rgb):
        ET.SubElement(c, canal).text = "%.6g" % valor
    return c


def peca(pai, nome, tamanho, forma, tinta, material, marca):
    item, props = novo_item(pai, "Part", nome, "RV_MP_%s_%s" % (marca, nome))
    vetor(props, "Vector3", "size", tamanho)
    cor3(props, "Color3uint8", tinta)
    ET.SubElement(props, "token", {"name": "formFactorRaw"}).text = "1"
    ET.SubElement(props, "token", {"name": "shape"}).text = str(SHAPE[forma])
    # nada de `MaterialVariantSerialized`: `token` vazio faz o rbx-dom tentar
    # ler inteiro de string vazia, e a conversão para .rbxm morre com
    # ParseIntError.
    ET.SubElement(props, "token", {"name": "Material"}).text = str(MATERIAL[material])
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(props, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CastShadow"}).text = "false"
    ET.SubElement(props, "float", {"name": "Transparency"}).text = "0"
    return item, props


def soldar(pai, alvo_nome, marca, deslocamento, indice):
    item, props = novo_item(pai, "Weld", "SoldaM%d" % indice,
                            "RV_MW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_MP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_MP_%s_%s" % (marca, alvo_nome)
    return item


def handles_da_origem():
    """{nome da Tool de origem: <Item> do Handle}, já podado."""
    arvore = ET.parse(ORIGEM)
    achados, podados = {}, {}
    for tool in arvore.getroot().findall("Item"):
        nome = texto(tool, "Name")
        for filho in tool.findall("Item"):
            if texto(filho, "Name") == "Handle":
                copia = copy.deepcopy(filho)
                podados[nome] = podar(copia)
                achados[nome] = copia
                break
    return achados, podados


def montar_tool(raiz, dados, handles_origem):
    nome, tooltip, arquetipo, rec_m1, _r, _t, chave = dados
    marca = chave.replace("Tempo_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_MT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    herdado = HERDA_HANDLE.get(nome)
    if herdado and herdado in handles_origem:
        # o Handle INTEIRO da origem, com a geometria e os Sound dele
        copia = copy.deepcopy(handles_origem[herdado])
        renomear_referentes(copia, "RV_MH_%s_" % marca)
        tool.append(copia)
    else:
        partes = HANDLES[nome]
        for pnome, tam, forma, tinta, mat, _d in partes:
            peca(tool, pnome, tam, forma, tinta, mat, marca)
        handle = tool.find("Item")
        for indice, dp in enumerate(partes[1:], start=1):
            soldar(handle, dp[0], marca, dp[5], indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_MSFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo, "RV_MS_%s_%s" % (marca, rotulo))
        conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
        ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
        ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(sp, "float", {"name": "RollOffMaxDistance"}).text = "280"

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", arquetipo),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
        _i, vp = novo_item(tool, classe, alvo, "RV_MV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_MVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_MACAO_%s" % marca)

    scripts = [("Script", "%s_Server_V1" % nome.replace(" ", "")),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]

    if nome in COM_CUTSCENE:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_MCUT_%s" % marca)
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_MSC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript: LocalScript dentro de
            # Tool só roda para quem a segura.
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool


def carregar_shared(origem):
    """{md5: <SharedString>} da tabela do modelo de origem."""
    arvore = ET.parse(origem)
    tabela = arvore.getroot().find("SharedStrings")
    if tabela is None:
        return {}
    return {e.get("md5"): e for e in tabela}


def levar_shared(raiz, tabela_origem):
    """Leva para a saída SÓ os `SharedString` que a árvore realmente cita.

    ISTO NÃO É DETALHE. `MeshPart` guarda `AeroMeshData`, `ModelMeshData`,
    `SlimHash` e `PhysicalConfigData` como SharedString — um ponteiro md5 para
    uma tabela que vive na RAIZ do arquivo. Copiar a subárvore sem copiar a
    tabela deixa seis ponteiros pendurados, e o Studio recusa o arquivo como
    corrompido. Já aconteceu duas vezes neste repositório.

    E leva só o que é CITADO: a tabela da origem tem 8 entradas, e as duas
    Tools que herdam Handle usam 3. Carregar as 8 seria levar junto a malha de
    coisas que foram podadas.
    """
    usados = set()
    for no in raiz.iter("Item"):
        props = no.find("Properties")
        if props is None:
            continue
        for e in props:
            if e.tag == "SharedString":
                usados.add((e.text or "").strip())

    if not usados:
        return 0

    tabela = ET.SubElement(raiz, "SharedStrings")
    levados = 0
    for md5 in sorted(usados):
        vinda = tabela_origem.get(md5)
        if vinda is None:
            # ponteiro que a origem também não resolve: tirar a propriedade é
            # melhor que deixar o ponteiro pendurado, que corrompe o arquivo
            for no in raiz.iter("Item"):
                props = no.find("Properties")
                if props is None:
                    continue
                for e in list(props):
                    if e.tag == "SharedString" and (e.text or "").strip() == md5:
                        props.remove(e)
            continue
        tabela.append(copy.deepcopy(vinda))
        levados = levados + 1
    return levados


def main():
    if not os.path.exists(ORIGEM):
        print("faltando o modelo de origem: %s" % ORIGEM)
        return 1

    handles_origem, podados = handles_da_origem()
    tabela_origem = carregar_shared(ORIGEM)

    raiz = nova_raiz()
    for dados in CONJUNTO:
        montar_tool(raiz, dados, handles_origem)

    levados = levar_shared(raiz, tabela_origem)

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("BASE DO CONJUNTO TEMPO — a partir do timetools.rbxmx")
    print("")
    print("  %-20s %-10s %s" % ("TOOL", "ARQUETIPO", "Handle · sons · recargas"))
    for nome, _t, arq, m1, r, t, _c in CONJUNTO:
        herdado = HERDA_HANDLE.get(nome)
        origem_txt = ("da origem (%s)" % herdado) if herdado \
            else ("autoral, %d peça(s)" % len(HANDLES[nome]))
        cena = " · CENA" if nome in COM_CUTSCENE else ""
        print("  %-20s %-10s %-26s %d som(ns) · M1 %.1fs / R %ds / T %ds%s"
              % (nome, arq, origem_txt, len(SONS[nome]), m1, r, t, cena))
    print("")
    for tool, classes in sorted(podados.items()):
        if classes:
            print("  podado de %-18s %s" % (tool, ", ".join(sorted(set(classes)))))
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("  %d SoundId distinto(s), todos do SFX/ids.md da ficha" % len(ids))
    print("  %d SharedString levada(s) da tabela da origem — sem elas o Studio"
          % levados)
    print("     recusa o arquivo como corrompido")
    return 0


if __name__ == "__main__":
    sys.exit(main())
