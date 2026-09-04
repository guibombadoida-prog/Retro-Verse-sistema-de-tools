#!/usr/bin/env python3
"""
preparar_criacao.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto CRIAÇÃO.

    python3 FERRAMENTAS/preparar_criacao.py

Escreve `MODELOS_ENTRADA/Poder_da_Criacao/Criacao_7_Tools.rbxmx`.

════════════════════════════════════════════════════════════════════════
O QUARTO CONJUNTO AUTORAL — E O PRIMEIRO QUE CRIA MATÉRIA
════════════════════════════════════════════════════════════════════════

    Não chegou modelo. Como o `collector`, o `Titan_TV_Man` e o
    `Poderes_de_Bomba`, ele nasce aqui.

    E ele é o primeiro conjunto do repositório cujo VERBO é criar. Isso muda
    uma coisa de arquitetura, não de tema: até agora toda Tool que punha peça
    no mundo punha VFX, que é do cliente e some sozinho com `Debris`. Aqui a
    peça é a HABILIDADE — a muralha bloqueia, a torre levanta, o cipó prende —
    e por isso ela existe no SERVIDOR, onde todo mundo colide com ela.

    Peça de servidor que fica é lixo permanente no mapa. É a mesma família do
    defeito que o `timetools` tinha com `Anchored`, e a resposta é a mesma:
    tudo que é criado entra num registro com prazo, e é recolhido pelo prazo,
    pelo `Unequipped` e pelo `Destroying`.

════════════════════════════════════════════════════════════════════════
AS SETE FACETAS
════════════════════════════════════════════════════════════════════════

    `Forja`       criar metal — martelo, bigorna, têmpera
    `Alvenaria`   criar estrutura — tijolo, muralha, torre
    `Semente`     criar vida — broto, cipó, árvore
    `Projeto`     criar por desenho — traço, esboço, materializar
    `Prototipo`   criar imitação — peça, molde, série
    `Genese`      criar do nada — faísca, matéria, primeiro instante
    `Demiurgo`    criar um mundo — a ultimate, com cena

    A escala sobe: metal, pedra, vida, desenho, cópia, matéria crua, mundo.

════════════════════════════════════════════════════════════════════════
OS 21 SoundId SÃO DO CATÁLOGO
════════════════════════════════════════════════════════════════════════

    Id de som não se inventa: id chutado é som mudo que nenhum verificador
    estático pega — o `.rbxmx` fica válido e o jogo fica em silêncio. Os 21
    saem das fichas que já estão no Acervo, e a coluna da direita diz de qual.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Poder_da_Criacao",
                     "Criacao_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568, "Grass": 1280,
            "Slate": 800, "Concrete": 816, "Brick": 848}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

COM_CUTSCENE = ("Demiurgo",)


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — 21 ids, TODOS do catálogo do Acervo
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Forja": [
        ("MARTELO", "1255794", 5, 0.95),      # `Gravity Hammer` — VFX_Library_V2
        ("BIGORNA", "933780081", 5, 0.85),    # `MetalHit` — Guest_Tools
        ("TEMPERA", "546410481", 4, 1.1),     # `MetalHit2` — Guest_Tools
    ],
    "Alvenaria": [
        ("TIJOLO", "131219241", 4, 1.05),     # `SFX: Gavel` — VFX_Library_V2
        ("MURALHA", "281633012", 5, 0.9),     # `earthparticle` — VFX_Library_V2
        ("TORRE", "4870579875", 6, 0.8),      # `earthquake1` — VFX_Library_V2
    ],
    "Semente": [
        ("BROTO", "1489705211", 4, 1.2),      # `Swoosh` — Guest_Tools
        ("CIPO", "124444290902740", 4, 0.9),  # `chains_break` — VFX_Library_V2
        ("ARVORE", "3264923", 5, 0.8),        # `Defile` — VFX_Library_V2
    ],
    "Projeto": [
        ("TRACO", "5651577252", 4, 1.15),     # `glint` — VFX_Library_V2
        ("ESBOCO", "1388726556", 4, 1.0),     # `ClickAccept` — Canhao_Satelite
        ("MATERIALIZA", "550210020", 5, 0.9), # `loot_appears` — Canhao_Satelite
    ],
    "Prototipo": [
        ("PECA", "7449454513", 4, 1.1),       # `Drop` — Trident
        ("MOLDE", "7449454869", 4, 1.0),      # `Pickup` — Trident
        ("SERIE", "6741488567", 5, 0.9),      # `expl` — VFX_Library_V2
    ],
    "Genese": [
        ("FAISCA", "2273224484", 4, 1.2),     # `eyeglow` — VFX_Library_V2
        ("MATERIA", "8578316223", 4, 0.95),   # `charge` — VFX_Library_V2
        ("PRIMEIRO", "782353443", 6, 0.8),    # `energystrike` — VFX_Library_V2
    ],
    "Demiurgo": [
        ("MOLDE_MUNDO", "2836888600", 5, 0.9),  # `summoning` — VFX_Library_V2
        ("CONTINENTE", "165969964", 5, 0.85),   # `Explosion` — VFX_Library_V2
        ("CRIACAO", "18872474050", 6, 0.75),    # `Supernova` — Sword_of_Cosmic
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES — (nome, tamanho, forma, cor, material, deslocamento)
# ═══════════════════════════════════════════════════════════════

FERRO = cor(96, 100, 110)
BRASA = cor(255, 138, 46)
PEDRA = cor(150, 146, 138)
TIJOLO = cor(168, 88, 66)
VERDE = cor(96, 168, 84)
SEIVA = cor(180, 220, 120)
PAPEL = cor(232, 236, 242)
TINTA = cor(64, 120, 208)
LATAO = cor(198, 162, 92)
LUZ = cor(255, 244, 200)
OURO = cor(255, 208, 96)
TERRA = cor(122, 96, 68)

HANDLES = {
    # o martelo de forja: cabo e cabeça de ferro, com a brasa dentro
    "Forja": [
        ("Handle", (0.5, 2.6, 0.5), "Block", TERRA, "Wood", (0, 0, 0)),
        ("Cabeca", (1.1, 1.3, 2.2), "Block", FERRO, "Metal", (0, 1.9, 0)),
        ("Brasa", (0.7, 0.7, 0.7), "Ball", BRASA, "Neon", (0, 1.9, 0)),
        ("Cunha", (0.5, 0.5, 0.9), "Block", FERRO, "Metal", (0, 1.9, -1.3)),
    ],
    # a colher de pedreiro, com um tijolo preso
    "Alvenaria": [
        ("Handle", (0.42, 1.8, 0.42), "Block", TERRA, "Wood", (0, 0, 0)),
        ("Colher", (1.6, 0.16, 2.4), "Block", FERRO, "Metal", (0, 1.6, -0.6)),
        ("Tijolo", (1.2, 0.6, 2.0), "Block", TIJOLO, "Brick", (0, 1.9, -0.6)),
        ("Argamassa", (1.3, 0.1, 2.1), "Block", PEDRA, "Concrete",
         (0, 1.72, -0.6)),
    ],
    # o cajado de semente: galho vivo com um broto na ponta
    "Semente": [
        ("Handle", (0.4, 2.4, 0.4), "Block", TERRA, "Wood", (0, 0, 0)),
        ("Galho", (0.3, 2.2, 0.3), "Block", TERRA, "Wood", (0, 2.2, 0)),
        ("Folha", (1.4, 0.14, 0.9), "Block", VERDE, "Grass", (0, 3.0, 0)),
        ("Broto", (0.7, 0.7, 0.7), "Ball", SEIVA, "Neon", (0, 3.4, 0)),
    ],
    # a prancheta: papel, régua e a linha de tinta
    "Projeto": [
        ("Handle", (0.4, 1.6, 0.4), "Block", LATAO, "Metal", (0, 0, 0)),
        ("Prancha", (2.4, 0.12, 3.2), "Block", PAPEL, "SmoothPlastic",
         (0, 1.7, 0)),
        ("Regua", (2.6, 0.1, 0.3), "Block", LATAO, "Metal", (0, 1.82, -1.0)),
        ("Linha", (2.0, 0.08, 0.12), "Block", TINTA, "Neon", (0, 1.84, 0.4)),
    ],
    # a bancada de protótipo: uma peça meio pronta num suporte
    "Prototipo": [
        ("Handle", (0.5, 2.0, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Base", (1.8, 0.3, 1.8), "Block", FERRO, "Metal", (0, 1.5, 0)),
        ("Peca", (1.0, 1.0, 1.0), "Block", PAPEL, "SmoothPlastic",
         (0, 2.2, 0)),
        ("Meio", (1.05, 0.5, 1.05), "Block", TINTA, "Neon", (0, 2.45, 0)),
    ],
    # a gênese: uma esfera de matéria crua entre dois anéis
    "Genese": [
        ("Handle", (0.5, 2.0, 0.5), "Block", LATAO, "Metal", (0, 0, 0)),
        ("Materia", (1.6, 1.6, 1.6), "Ball", LUZ, "Neon", (0, 2.2, 0)),
        ("AnelA", (2.6, 0.16, 2.6), "Cylinder", LATAO, "Metal", (0, 2.2, 0)),
        ("AnelB", (0.16, 2.6, 2.6), "Cylinder", LATAO, "Metal", (0, 2.2, 0)),
    ],
    # o demiurgo: o mundo pequeno na mão, com o compasso
    "Demiurgo": [
        ("Handle", (0.55, 2.0, 0.55), "Block", OURO, "Metal", (0, 0, 0)),
        ("Mundo", (3.0, 3.0, 3.0), "Ball", VERDE, "Grass", (0, 2.6, 0)),
        ("Oceano", (3.1, 3.1, 3.1), "Ball", TINTA, "Glass", (0, 2.6, 0)),
        ("Orbita", (3.8, 0.14, 3.8), "Cylinder", OURO, "Neon", (0, 2.6, 0)),
        ("Compasso", (0.14, 2.6, 0.14), "Block", OURO, "Metal", (0, 4.4, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Forja",
     "Martela, e cada golpe esquenta o alvo. R derruba a bigorna; T tempera "
     "uma placa em volta de voce.",
     "MELEE", 0.8, 14, 20, "Criacao_Forja"),

    ("Alvenaria",
     "Atira o tijolo. R levanta a muralha; T abre a torre debaixo do alvo.",
     "MELEE", 0.9, 16, 22, "Criacao_Alvenaria"),

    ("Semente",
     "O broto rasga o chao. R prende com cipo; T faz a arvore crescer.",
     "ARCANO", 0.9, 15, 24, "Criacao_Semente"),

    ("Projeto",
     "O traco vira lamina. R esboca a zona; T materializa o que foi desenhado.",
     "ARCANO", 0.8, 13, 21, "Criacao_Projeto"),

    ("Prototipo",
     "Atira a peca bruta. R deixa um molde que puxa atencao; T solta a serie.",
     "EXPLOSIVO", 0.8, 14, 23, "Criacao_Prototipo"),

    ("Genese",
     "A faisca da materia. R condensa e estoura; T e o primeiro instante.",
     "ASTRAL", 0.9, 17, 26, "Criacao_Genese"),

    ("Demiurgo",
     "O molde do mundo. R levanta o continente; T e a Criacao, com cena.",
     "EXPLOSIVO", 1.2, 20, 44, "Criacao_Demiurgo"),
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


def peca(pai, nome, tamanho, forma, tinta, material, marca):
    item, props = novo_item(pai, "Part", nome, "RV_CP_%s_%s" % (marca, nome))
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
    item, props = novo_item(pai, "Weld", "SoldaC%d" % indice,
                            "RV_CW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_CP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_CP_%s_%s" % (marca, alvo_nome)
    return item


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, _r, _t, chave = dados
    marca = chave.replace("Criacao_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_CT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for pnome, tam, forma, tinta, mat, _d in partes:
        peca(tool, pnome, tam, forma, tinta, mat, marca)
    handle = tool.find("Item")
    for indice, dp in enumerate(partes[1:], start=1):
        soldar(handle, dp[0], marca, dp[5], indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_CSFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo, "RV_CS_%s_%s" % (marca, rotulo))
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
        _i, vp = novo_item(tool, classe, alvo, "RV_CV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_CVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_CACAO_%s" % marca)

    scripts = [("Script", "%s_Server_V1" % nome.replace(" ", "")),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]

    if nome in COM_CUTSCENE:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_CCUT_%s" % marca)
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_CSC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript: LocalScript dentro de
            # Tool só roda para quem a segura.
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool


def main():
    raiz = nova_raiz()
    for dados in CONJUNTO:
        montar_tool(raiz, dados)

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("BASE DO CONJUNTO CRIAÇÃO")
    print("")
    print("  %-12s %-11s %s" % ("TOOL", "ARQUETIPO", "peças · sons · recargas"))
    for nome, _t, arq, m1, r, t, _c in CONJUNTO:
        cena = " · CENA" if nome in COM_CUTSCENE else ""
        print("  %-12s %-11s %d peça(s) · %d som(ns) · M1 %.1fs / R %ds / T %ds%s"
              % (nome, arq, len(HANDLES[nome]), len(SONS[nome]), m1, r, t, cena))
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("  %d SoundId distinto(s), todos do catálogo do Acervo" % len(ids))
    print("  0 MeshId — a geometria inteira é primitiva soldada")
    return 0


if __name__ == "__main__":
    sys.exit(main())
