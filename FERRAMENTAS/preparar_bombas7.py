#!/usr/bin/env python3
"""
preparar_bombas7.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto PODERES DE BOMBA.

    python3 FERRAMENTAS/preparar_bombas7.py

Escreve `MODELOS_ENTRADA/Poderes_de_Bomba/Bomba_7_Tools.rbxmx`: Handle, SFX,
Values e os remotes. O Lua vem depois, dos geradores.

════════════════════════════════════════════════════════════════════════
DUAS HABILIDADES POR TOOL — E POR ISSO UMA TECLA SÓ
════════════════════════════════════════════════════════════════════════

    M1 no clique, mais UMA Extra em `R`. É o desenho base da
    REGRA_DISTRIBUICAO: "cada Tool comporta duas — primária em
    `Tool.Activated`, Extra por tecla via `AcaoRemote`".

    E as duas de cada Tool são um PAR, não duas habilidades soltas. Na `Fila
    de Bombas` o M1 planta e o R detona; na `Bomba Orbital` o M1 marca e o R
    faz cair. Quem usa só o M1 tem meia Tool — de propósito.

════════════════════════════════════════════════════════════════════════
QUATRO TÊM CUTSCENE, TRÊS NÃO
════════════════════════════════════════════════════════════════════════

    `Bomba Orbital`, `Bomba de Implosao`, `Bomba em Corrente` e `Bomba do
    Juizo` — as quatro épicas — ganham `CutsceneRemote` e o `CutsceneCam`.
    As três nomeadas (`Fila de Bombas`, `Explosao Nuclear`, `Coca Explosiva`)
    não ganham, e isso é decisão declarada: cutscene em habilidade de recarga
    curta vira tempo morto a cada quinze segundos.

    A cutscene é CÂMERA, não interface. `ScreenGui`, `ColorCorrection` e `Sky`
    continuam proibidos dentro de Tool — os três são estado de INTERFACE, e uma
    Tool que suma no meio deixaria a tela do jogador coberta e sem saída. A
    `CutsceneCam` guarda `CameraType` e `FieldOfView` de antes e devolve os
    dois por SEIS portas.

════════════════════════════════════════════════════════════════════════
O CONJUNTO É AUTORAL, MENOS OS SONS
════════════════════════════════════════════════════════════════════════

    Não chegou modelo de origem. A geometria das sete é primitiva soldada, e
    as 14 habilidades são escritas no repositório.

    Os 21 `SoundId` saem todos do catálogo do Acervo, e a coluna da direita de
    `SONS` diz de qual ficha. Id de som não se inventa: id chutado é som mudo
    que nenhum verificador estático pega — o `.rbxmx` fica válido e o jogo
    fica em silêncio.

    E ELE NÃO REPETE O `Bomba_V4`. As seis de lá são split, nuke, meteoro,
    quique, kamikaze e gelo. Nenhuma das sete daqui refaz qualquer uma
    dessas: o eixo deste conjunto é PLANTAR E DETONAR, não arremessar.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Poderes_de_Bomba",
                     "Bomba_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

#: as quatro épicas — as únicas com CutsceneRemote e CutsceneCam
COM_CUTSCENE = ("Bomba Orbital", "Bomba de Implosao", "Bomba em Corrente",
                "Bomba do Juizo")


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — 21 ids, TODOS do catálogo do Acervo
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Fila de Bombas": [
        ("PLANTA", "12221967", 4, 1.1),        # `Press` — Guest_Tools
        ("ESTOURA", "2691586", 5, 1.0),        # `DBExplode` — VFX_Library_V2
        ("TUDO", "814635481", 6, 0.85),        # `Big Explosion` — VFX_Library_V2
    ],
    "Explosao Nuclear": [
        ("OGIVA", "387278135", 4, 1.0),        # `Shoot` — Trident
        ("NUCLEAR", "180199793", 6, 0.8),      # `Explosion 4` — VFX_Library_V2
        ("VENTO", "9125402735", 5, 0.7),       # `DuperBoom` — Jupiter
    ],
    "Coca Explosiva": [
        ("CHACOALHA", "1489917733", 4, 1.15),  # `DrinkSound` — Guest_Tools
        ("ESTOURO", "6741488567", 5, 1.0),     # `expl` — VFX_Library_V2
        ("JATO", "145486992", 4, 1.25),        # `sfx_swooshing` — Dano_Verdadeiro
    ],
    "Bomba Orbital": [
        ("MARCA", "1310929645", 4, 1.2),       # `Locked On` — Sword_of_Cosmic_Entity
        ("QUEDA", "260281717", 5, 0.85),       # `MeteorSmash` — Jupiter
        ("IMPACTO", "165969964", 6, 0.75),     # `Explosion` — VFX_Library_V2
    ],
    "Bomba de Implosao": [
        ("SEMEIA", "8578316223", 4, 1.1),      # `charge` — VFX_Library_V2
        ("PUXA", "2162238374", 4, 0.9),        # `SpirtLoop` — Jupiter
        ("COLAPSO", "3313098116", 6, 0.8),     # `Explosion` — VFX_Library_V2
    ],
    "Bomba em Corrente": [
        ("ESTOPIM", "2674547670", 4, 1.05),    # `Electric Explosion` — Trident
        ("SALTO", "96478259", 4, 1.3),         # `Lightning2` — Jupiter
        ("FIM", "142070127", 5, 0.85),         # `explosive` — VFX_Library_V2
    ],
    "Bomba do Juizo": [
        ("CONTAGEM", "9125673453", 4, 1.0),    # `Beep` — Canhao_Satelite
        ("JUIZO", "95335614812989", 6, 0.75),  # `Supernova` — Sword_of_Cosmic_Entity
        ("ONDA", "4870579875", 6, 0.7),        # `earthquake1` — VFX_Library_V2
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES — (nome, tamanho, forma, cor, material, deslocamento)
#
# A primeira peça de cada lista É o Handle; as outras são soldadas nela.
# ═══════════════════════════════════════════════════════════════

FERRO = cor(72, 74, 82)
PRETO = cor(26, 24, 28)
LARANJA = cor(255, 138, 46)
VERMELHO = cor(210, 40, 40)
COCA = cor(140, 30, 26)
PRATA = cor(198, 202, 210)
VERDE_RAD = cor(150, 240, 150)
AZUL = cor(120, 200, 255)
BRANCO = cor(238, 240, 244)

HANDLES = {
    # a fila: um bandolim com três bombas presas
    "Fila de Bombas": [
        ("Handle", (0.5, 2.4, 0.5), "Block", PRETO, "Metal", (0, 0, 0)),
        ("BombaA", (0.9, 0.9, 0.9), "Ball", FERRO, "Metal", (0, 1.5, 0)),
        ("BombaB", (0.9, 0.9, 0.9), "Ball", FERRO, "Metal", (0, 0.4, 0)),
        ("BombaC", (0.9, 0.9, 0.9), "Ball", FERRO, "Metal", (0, -0.7, 0)),
        ("Pavio", (0.12, 1.2, 0.12), "Block", LARANJA, "Neon", (0, 2.3, 0)),
    ],
    # a ogiva: corpo cilíndrico, ponta e três aletas
    "Explosao Nuclear": [
        ("Handle", (0.5, 1.6, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Corpo", (1.4, 3.2, 1.4), "Cylinder", BRANCO, "SmoothPlastic",
         (0, 2.0, 0)),
        ("Ponta", (1.0, 1.0, 1.0), "Ball", VERMELHO, "Metal", (0, 3.7, 0)),
        ("Faixa", (1.6, 0.3, 1.6), "Cylinder", VERDE_RAD, "Neon", (0, 1.6, 0)),
        ("Aleta", (1.9, 0.7, 0.14), "Block", FERRO, "Metal", (0, 0.7, 0)),
    ],
    # a garrafa: corpo, gargalo e tampa
    "Coca Explosiva": [
        ("Handle", (0.45, 1.4, 0.45), "Block", COCA, "SmoothPlastic", (0, 0, 0)),
        ("Garrafa", (1.2, 2.6, 1.2), "Cylinder", COCA, "Glass", (0, 1.6, 0)),
        ("Gargalo", (0.55, 0.9, 0.55), "Cylinder", COCA, "Glass", (0, 3.2, 0)),
        ("Tampa", (0.62, 0.28, 0.62), "Cylinder", VERMELHO, "Metal",
         (0, 3.75, 0)),
        ("Rotulo", (1.3, 0.9, 1.3), "Cylinder", VERMELHO, "SmoothPlastic",
         (0, 1.6, 0)),
    ],
    # o farol orbital: prato, haste e ponta acesa
    "Bomba Orbital": [
        ("Handle", (0.5, 2.0, 0.5), "Block", PRETO, "Metal", (0, 0, 0)),
        ("Prato", (2.2, 0.2, 2.2), "Cylinder", PRATA, "Metal", (0, 1.6, 0)),
        ("Haste", (0.16, 2.0, 0.16), "Block", PRATA, "Metal", (0, 2.6, 0)),
        ("Farol", (0.7, 0.7, 0.7), "Ball", AZUL, "Neon", (0, 3.6, 0)),
    ],
    # a implosão: núcleo escuro dentro de um aro de contenção
    "Bomba de Implosao": [
        ("Handle", (0.55, 2.0, 0.55), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Nucleo", (1.5, 1.5, 1.5), "Ball", PRETO, "Glass", (0, 2.0, 0)),
        ("Aro", (2.6, 0.22, 2.6), "Cylinder", PRATA, "Metal", (0, 2.0, 0)),
        ("Halo", (2.0, 2.0, 2.0), "Ball", AZUL, "Neon", (0, 2.0, 0)),
    ],
    # a corrente: três esferas ligadas por fio aceso
    "Bomba em Corrente": [
        ("Handle", (0.45, 2.2, 0.45), "Block", PRETO, "Metal", (0, 0, 0)),
        ("Elo1", (0.8, 0.8, 0.8), "Ball", FERRO, "Metal", (0.9, 1.5, 0)),
        ("Elo2", (0.8, 0.8, 0.8), "Ball", FERRO, "Metal", (0, 2.1, 0)),
        ("Elo3", (0.8, 0.8, 0.8), "Ball", FERRO, "Metal", (-0.9, 1.5, 0)),
        ("Fio", (2.4, 0.1, 0.1), "Block", LARANJA, "Neon", (0, 1.7, 0)),
    ],
    # o juízo: a esfera grande, com o mostrador de contagem
    "Bomba do Juizo": [
        ("Handle", (0.6, 1.8, 0.6), "Block", PRETO, "Metal", (0, 0, 0)),
        ("Esfera", (3.0, 3.0, 3.0), "Ball", FERRO, "Metal", (0, 2.4, 0)),
        ("Mostrador", (1.5, 0.16, 1.5), "Cylinder", VERMELHO, "Neon",
         (0, 2.4, -1.5)),
        ("Cinta", (3.3, 0.3, 3.3), "Cylinder", LARANJA, "Neon", (0, 2.4, 0)),
        ("Pavio", (0.16, 1.4, 0.16), "Block", LARANJA, "Neon", (0, 4.2, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Fila de Bombas",
     "Planta uma fila de bombas com pavio correndo. R detona tudo de uma vez.",
     "EXPLOSIVO", 1.4, 12, "Bomba_Fila"),

    ("Explosao Nuclear",
     "Ogiva no ponto mirado. R e o cogumelo, com poeira que fica queimando.",
     "EXPLOSIVO", 1.6, 20, "Bomba_Nuclear7"),

    ("Coca Explosiva",
     "Garrafa chacoalhada que sai voando pela propria espuma. R e o jato.",
     "EXPLOSIVO", 1.2, 11, "Bomba_Coca"),

    ("Bomba Orbital",
     "Marca a zona com o farol. R chama a queda orbital, com cena.",
     "EXPLOSIVO", 1.1, 24, "Bomba_Orbital"),

    ("Bomba de Implosao",
     "Semeia o nucleo que puxa. R faz colapsar, com cena.",
     "GRAVIDADE", 1.2, 22, "Bomba_Implosao"),

    ("Bomba em Corrente",
     "Estopim que marca o primeiro. R dispara a reacao em cadeia, com cena.",
     "EXPLOSIVO", 1.0, 21, "Bomba_Corrente"),

    ("Bomba do Juizo",
     "Comeca a contagem. R e o Juizo Final, com cena — a grande do conjunto.",
     "EXPLOSIVO", 1.5, 40, "Bomba_Juizo"),
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
    item, props = novo_item(pai, "Part", nome, "RV_BP_%s_%s" % (marca, nome))
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
    """Solda uma peça ao Handle. `Weld` com C0 = deslocamento."""
    item, props = novo_item(pai, "Weld", "SoldaB%d" % indice,
                            "RV_BW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_BP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_BP_%s_%s" % (marca, alvo_nome)
    return item


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, _rec_r, chave = dados
    marca = chave.replace("Bomba_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_BT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for pnome, tam, forma, tinta, mat, _desloc in partes:
        peca(tool, pnome, tam, forma, tinta, mat, marca)
    handle = tool.find("Item")
    for indice, dados_peca in enumerate(partes[1:], start=1):
        soldar(handle, dados_peca[0], marca, dados_peca[5], indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_BSFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo,
                           "RV_BS_%s_%s" % (marca, rotulo))
        conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
        ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
        ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(sp, "float", {"name": "RollOffMaxDistance"}).text = "300"

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", arquetipo),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
        _i, vp = novo_item(tool, classe, alvo, "RV_BV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_BVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_BACAO_%s" % marca)

    scripts = [("Script", "%s_Server_V1" % nome.replace(" ", "")),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]

    # as quatro épicas ganham a cena. As três nomeadas não: cutscene em
    # habilidade de recarga curta vira tempo morto a cada quinze segundos.
    if nome in COM_CUTSCENE:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_BCUT_%s" % marca)
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_BSC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript: LocalScript dentro de
            # Tool só roda para quem a segura. No `Client` isso faria o VFX
            # aparecer só para o portador; na `CutsceneCam` faria o ALVO nunca
            # executar o arquivo, e a metade da cena que é dele não existiria.
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool


def main():
    raiz = nova_raiz()
    for dados in CONJUNTO:
        montar_tool(raiz, dados)

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("BASE DO CONJUNTO PODERES DE BOMBA")
    print("")
    print("  %-20s %-11s %s" % ("TOOL", "ARQUETIPO", "peças · sons · recargas"))
    for nome, _t, arq, m1, r, _c in CONJUNTO:
        cena = " · CENA" if nome in COM_CUTSCENE else ""
        print("  %-20s %-11s %d peça(s) · %d som(ns) · M1 %.1fs / R %ds%s"
              % (nome, arq, len(HANDLES[nome]), len(SONS[nome]), m1, r, cena))
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("  %d SoundId distinto(s), todos do catálogo do Acervo" % len(ids))
    print("  %d Tool(s) com CutsceneRemote + CutsceneCam" % len(COM_CUTSCENE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
