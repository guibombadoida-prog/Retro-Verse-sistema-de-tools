#!/usr/bin/env python3
"""
preparar_jupiter.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto JUPITER.

    python3 FERRAMENTAS/preparar_jupiter.py

Escreve `MODELOS_ENTRADA/Jupiter_Great_Pressure_Sword/Jupiter_7_Tools.rbxmx`:
Handle, SFX, Values e os dois `RemoteEvent`. O Lua vem depois, dos geradores.

════════════════════════════════════════════════════════════════════════
O MATERIAL VEM DO ACERVO, A LÓGICA NÃO
════════════════════════════════════════════════════════════════════════

    `ACERVO_RETROVERSE/Jupiter_Great_Pressure_Sword/` está **LIMPO** e traz o
    que interessa em ficha: 21 `SoundId`, o `MeshId` do planeta
    (`907848103`, textura `8077647902`), e as texturas de partícula.

    Nenhum desses números foi inventado — todos saem do `SFX/ids.md` e do
    `MALHAS/ids.md`, que foram lidos do modelo de origem. Id chutado é som mudo
    e malha invisível que nenhum verificador pega: o `.rbxmx` fica válido e o
    jogo fica em silêncio.

    A LÓGICA da origem NÃO entra (§12.12.1). O `LOGICA/HABILIDADES.md` lista o
    que ela fazia — `Health = 0` na desintegração, raio de **1500 studs** no
    `OnUnwing`, `TagHumanoid` e `IsTeamMate` reimplementados, 69 `:Destroy()`,
    37 `wait()`, 16 `math.random` — e é consulta, não material de reuso. As 21
    habilidades daqui são escritas do zero, conforme.

    Também não entra o `Impact_Frame`, que é `ScreenGui` + `ColorCorrection` +
    `Sky` — os três proibidos juntos. O clarão dele vive no mundo 3D.

════════════════════════════════════════════════════════════════════════
O HANDLE É PRIMITIVA MONTADA AQUI, MAIS A MALHA DO PLANETA
════════════════════════════════════════════════════════════════════════

    Cada Handle é uma pequena assembleia de `Part` soldada por `Weld`. Onde o
    tema pede o planeta — `Luas Galileanas`, `Cinturao de Radiacao` e `Queda
    do Gigante` —, uma das peças carrega o `SpecialMesh` do Júpiter, que é a
    única geometria de terceiro no conjunto e está em ficha.

    Nada é lido de fora em runtime: a malha é filha da Tool, como tudo.

════════════════════════════════════════════════════════════════════════
TRÊS HABILIDADES POR TOOL, E POR ISSO DUAS TECLAS
════════════════════════════════════════════════════════════════════════

    M1 no clique, mais DUAS Extras em `R` e `T`. O `AcaoRemote` é UM só: quem
    diferencia é o nome da tecla no payload, conferido no servidor antes de
    agir. Dois remotes seriam duas portas para o mesmo cômodo.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Jupiter_Great_Pressure_Sword",
                     "Jupiter_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

#: a malha do planeta, do `MALHAS/ids.md` da ficha
MALHA_JUPITER = ("907848103", "8077647902")


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — os 21 ids do `SFX/ids.md` da ficha do Jupiter
#
# A coluna da direita é o caminho na origem, que é de onde o id saiu. Os 21
# estão distribuídos pelas 7 Tools; nenhum fica de fora, e nenhum é inventado.
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Jupiter Grande Mancha": [
        ("GIRA", "2162238374", 4, 1.0),       # SpirtLoop
        ("OLHO", "9125402735", 5, 0.8),       # DuperBoom
        ("DISPERSA", "5405455343", 4, 1.15),  # Unwing
    ],
    "Jupiter Pressao Esmagadora": [
        ("PRENSA", "9125403260", 4, 0.9),     # Impact_Sound
        ("ESMAGA", "260281717", 5, 0.8),      # MeteorSmash
        ("VACUO", "763717897", 4, 1.1),       # VJ_Explosion
    ],
    "Jupiter Raio Joviano": [
        ("RAIO", "80214468", 4, 1.0),         # Lightning1
        ("CADEIA", "96478567", 4, 1.2),       # Lightning3
        ("TORMENTA", "96478346", 5, 0.85),    # Lightning5
    ],
    "Jupiter Luas Galileanas": [
        ("ORBITA", "160773067", 4, 1.0),      # SpawnJupiter
        ("IO", "96478259", 4, 1.3),           # Lightning2
        ("ECLIPSE", "401056199", 5, 0.75),    # VJ_Explosion2
    ],
    "Jupiter Cinturao de Radiacao": [
        ("CAMPO", "1146689657", 4, 0.9),      # DistantJupiter
        ("PULSO", "96478505", 4, 1.15),       # Lightning4
        ("BLINDA", "96478426", 4, 0.7),       # Lightning6
    ],
    "Jupiter Espada de Pressao": [
        ("LAMINA", "8145344127", 4, 1.2),     # SwordLunge
        ("CORTE", "5287092000", 4, 1.0),      # SwordHit
        ("GIGANTE", "3360000345", 5, 0.85),   # SwordHit2
    ],
    "Jupiter Queda do Gigante": [
        ("INVOCA", "5405455343", 5, 0.875),   # JupiterSummon
        ("PRESENCA", "9125402735", 5, 0.7),   # DuperBoom
        ("IMPACTO", "83367202273950", 6, 0.955),  # VJ_Explosion3
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES
#
# (nome, tamanho, forma, cor, material, deslocamento, malha ou None)
# A primeira peça de cada lista É o Handle; as outras são soldadas nela.
#
# A paleta é a de Júpiter visto de perto: as faixas creme e ocre, a Grande
# Mancha vermelha, e o branco-azulado do raio.
# ═══════════════════════════════════════════════════════════════

CREME = cor(238, 222, 190)
OCRE = cor(196, 148, 96)
MANCHA = cor(198, 84, 62)
FERRO = cor(146, 152, 164)
PRETO = cor(26, 24, 30)
RAIO = cor(196, 228, 255)
BRASA = cor(255, 156, 62)
VERDE_RAD = cor(150, 240, 150)

HANDLES = {
    # a mancha: um bastão curto com um disco vermelho girando na ponta
    "Jupiter Grande Mancha": [
        ("Handle", (0.45, 2.6, 0.45), "Block", OCRE, "Metal", (0, 0, 0), None),
        ("Disco", (2.6, 0.4, 2.6), "Cylinder", MANCHA, "Neon", (0, 1.7, 0), None),
        ("Aro", (2.9, 0.18, 2.9), "Cylinder", CREME, "SmoothPlastic",
         (0, 1.7, 0), None),
    ],
    # a prensa: dois blocos pesados nas pontas de um eixo
    "Jupiter Pressao Esmagadora": [
        ("Handle", (0.5, 3.0, 0.5), "Block", FERRO, "Metal", (0, 0, 0), None),
        ("BlocoAlto", (2.0, 0.7, 2.0), "Block", FERRO, "Metal",
         (0, 1.9, 0), None),
        ("BlocoBaixo", (2.0, 0.7, 2.0), "Block", FERRO, "Metal",
         (0, -1.9, 0), None),
        ("Nucleo", (0.9, 0.9, 0.9), "Ball", MANCHA, "Neon", (0, 0, 0), None),
    ],
    # o raio: uma lança fina com uma ponta em neon azul
    "Jupiter Raio Joviano": [
        ("Handle", (0.35, 3.4, 0.35), "Block", PRETO, "Metal", (0, 0, 0), None),
        ("Ponta", (0.5, 1.6, 0.5), "Block", RAIO, "Neon", (0, 2.2, 0), None),
        ("Farpa", (0.9, 0.22, 0.22), "Block", RAIO, "Neon", (0, 1.5, 0), None),
    ],
    # as luas: o planeta pequeno na mão, com quatro esferas em volta
    "Jupiter Luas Galileanas": [
        ("Handle", (0.4, 2.2, 0.4), "Block", OCRE, "Metal", (0, 0, 0), None),
        ("Planeta", (2.2, 2.2, 2.2), "Ball", CREME, "SmoothPlastic",
         (0, 1.8, 0), MALHA_JUPITER),
        ("LuaIo", (0.5, 0.5, 0.5), "Ball", BRASA, "Neon", (1.6, 1.8, 0), None),
        ("LuaEuropa", (0.45, 0.45, 0.45), "Ball", RAIO, "Neon",
         (-1.6, 1.8, 0), None),
        ("LuaGanimedes", (0.55, 0.55, 0.55), "Ball", FERRO, "SmoothPlastic",
         (0, 1.8, 1.6), None),
        ("LuaCalisto", (0.5, 0.5, 0.5), "Ball", PRETO, "SmoothPlastic",
         (0, 1.8, -1.6), None),
    ],
    # o cinturão: um anel largo em volta de um núcleo verde
    "Jupiter Cinturao de Radiacao": [
        ("Handle", (0.4, 2.4, 0.4), "Block", FERRO, "Metal", (0, 0, 0), None),
        ("Planeta", (1.6, 1.6, 1.6), "Ball", CREME, "SmoothPlastic",
         (0, 1.6, 0), MALHA_JUPITER),
        ("Cinturao", (3.4, 0.16, 3.4), "Cylinder", VERDE_RAD, "Neon",
         (0, 1.6, 0), None),
        ("Nucleo", (0.7, 0.7, 0.7), "Ball", VERDE_RAD, "Neon",
         (0, 1.6, 0), None),
    ],
    # a espada: a única lâmina de verdade do conjunto
    "Jupiter Espada de Pressao": [
        ("Handle", (0.4, 1.5, 0.4), "Block", PRETO, "Metal", (0, 0, 0), None),
        ("Lamina", (0.22, 5.2, 1.0), "Block", CREME, "Metal", (0, 3.2, 0), None),
        ("Fio", (0.1, 5.0, 0.3), "Block", RAIO, "Neon", (0, 3.2, 0.36), None),
        ("Guarda", (1.9, 0.28, 0.6), "Block", OCRE, "Metal", (0, 0.8, 0), None),
        ("Contrapeso", (0.55, 0.55, 0.55), "Ball", MANCHA, "Neon",
         (0, -0.9, 0), None),
    ],
    # a queda: o planeta grande, cravado num pedestal curto
    "Jupiter Queda do Gigante": [
        ("Handle", (0.6, 1.8, 0.6), "Block", OCRE, "Metal", (0, 0, 0), None),
        ("Planeta", (3.2, 3.2, 3.2), "Ball", CREME, "SmoothPlastic",
         (0, 2.6, 0), MALHA_JUPITER),
        ("Faixa", (3.5, 0.3, 3.5), "Cylinder", MANCHA, "Neon",
         (0, 2.6, 0), None),
        ("Base", (1.4, 0.4, 1.4), "Cylinder", FERRO, "Metal", (0, 0.8, 0), None),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Jupiter Grande Mancha",
     "A tempestade que gira. R abre o olho; T dispersa tudo para fora.",
     "GRAVIDADE", 1.0, 14, 22, "Jupiter_Mancha"),

    ("Jupiter Pressao Esmagadora",
     "Coluna de pressao no ponto. R e a prensa; T e o vacuo que puxa.",
     "GRAVIDADE", 1.1, 16, 24, "Jupiter_Pressao"),

    ("Jupiter Raio Joviano",
     "Raio do ceu no ponto. R salta entre alvos; T e a tormenta.",
     "ASTRAL", 0.9, 12, 26, "Jupiter_Raio"),

    ("Jupiter Luas Galileanas",
     "Quatro luas orbitam e batem. R lanca Io; T faz as quatro cairem.",
     "ASTRAL", 1.0, 13, 25, "Jupiter_Luas"),

    ("Jupiter Cinturao de Radiacao",
     "Campo que corroi. R e o pulso radial; T e a blindagem.",
     "ARCANO", 1.0, 15, 20, "Jupiter_Radiacao"),

    ("Jupiter Espada de Pressao",
     "Golpe com onda de pressao. R e a estocada; T e o corte gigante.",
     "MELEE", 0.7, 10, 21, "Jupiter_Espada"),

    ("Jupiter Queda do Gigante",
     "Invoca o planeta. R o faz pairar e pressionar; T o derruba.",
     "EXPLOSIVO", 1.4, 20, 40, "Jupiter_Queda"),
]


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


def peca(pai, nome, tamanho, forma, tinta, material, marca, malha):
    item, props = novo_item(pai, "Part", nome, "RV_UP_%s_%s" % (marca, nome))
    vetor(props, "Vector3", "size", tamanho)
    cor3(props, "Color3uint8", tinta)
    ET.SubElement(props, "token", {"name": "formFactorRaw"}).text = "1"
    ET.SubElement(props, "token", {"name": "shape"}).text = str(SHAPE[forma])
    # nada de `MaterialVariantSerialized`: `token` vazio faz o rbx-dom tentar
    # ler inteiro de string vazia, e a conversão para .rbxm morre com
    # ParseIntError. A propriedade não é necessária — o Studio a preenche.
    ET.SubElement(props, "token", {"name": "Material"}).text = str(MATERIAL[material])
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(props, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CastShadow"}).text = "false"
    ET.SubElement(props, "float", {"name": "Transparency"}).text = "0"

    if malha:
        # `SpecialMesh` filho da Part, não `MeshPart`: assim a malha viaja como
        # id dentro da Tool, sem `AeroMeshData` nem tabela de SharedStrings
        # para carregar junto — que é o que já fez o Studio chamar arquivo de
        # corrompido neste repositório, duas vezes.
        _m, mp = novo_item(item, "SpecialMesh", "Mesh",
                           "RV_UM_%s_%s" % (marca, nome))
        ET.SubElement(mp, "token", {"name": "MeshType"}).text = "5"
        conteudo = ET.SubElement(mp, "Content", {"name": "MeshId"})
        ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % malha[0]
        if malha[1]:
            textura = ET.SubElement(mp, "Content", {"name": "TextureId"})
            ET.SubElement(textura, "url").text = "rbxassetid://%s" % malha[1]
    return item, props


def soldar(pai, alvo_nome, marca, deslocamento, indice):
    """Solda uma peça ao Handle. `Weld` com C0 = deslocamento."""
    item, props = novo_item(pai, "Weld", "SoldaU%d" % indice,
                            "RV_UW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_UP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_UP_%s_%s" % (marca, alvo_nome)
    return item


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, _rec_r, _rec_t, chave = dados
    marca = chave.replace("Jupiter_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_UT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for pnome, tam, forma, tinta, mat, _desloc, malha in partes:
        peca(tool, pnome, tam, forma, tinta, mat, marca, malha)
    # as soldas vão no Handle, que é a primeira peça
    handle = tool.find("Item")
    for indice, dados_peca in enumerate(partes[1:], start=1):
        soldar(handle, dados_peca[0], marca, dados_peca[5], indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_USFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo,
                           "RV_US_%s_%s" % (marca, rotulo))
        conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
        ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
        ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(sp, "float", {"name": "RollOffMaxDistance"}).text = "240"

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", arquetipo),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
        _i, vp = novo_item(tool, classe, alvo, "RV_UV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    # UM `AcaoRemote` para as DUAS Extras: quem separa é o nome da tecla no
    # payload, conferido no servidor. Dois remotes seriam duas portas para o
    # mesmo cômodo.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_UVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_UACAO_%s" % marca)

    for classe, alvo in (("Script", "%s_Server_V1" % nome.replace(" ", "")),
                         ("Script", "Client"),
                         ("ModuleScript", "R6CFrameAnimator"),
                         ("ModuleScript", "Poses"),
                         ("ModuleScript", "VFXModule")):
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_USC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo == "Client":
            # RunContext = Client (2), NÃO LocalScript: LocalScript dentro de
            # Tool só roda para quem a segura, e o VFX apareceria só para o
            # portador.
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool


def main():
    raiz = nova_raiz()
    for dados in CONJUNTO:
        montar_tool(raiz, dados)

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("BASE DO CONJUNTO JUPITER")
    print("")
    print("  %-30s %-10s %s" % ("TOOL", "ARQUETIPO", "peças · sons · recargas"))
    for nome, _t, arq, m1, r, t, _c in CONJUNTO:
        malhas = sum(1 for p in HANDLES[nome] if p[6])
        print("  %-30s %-10s %d peça(s)%s · %d som(ns) · M1 %.1fs / R %ds / T %ds"
              % (nome, arq, len(HANDLES[nome]),
                 " (%d com malha)" % malhas if malhas else "",
                 len(SONS[nome]), m1, r, t))
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("  %d SoundId distinto(s), todos do SFX/ids.md da ficha" % len(ids))
    print("  1 MeshId, do MALHAS/ids.md da ficha, em 3 Tools")
    return 0


if __name__ == "__main__":
    sys.exit(main())
