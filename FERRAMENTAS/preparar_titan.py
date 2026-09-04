#!/usr/bin/env python3
"""
preparar_titan.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto TITAN — o TV Man Titan.

    python3 FERRAMENTAS/preparar_titan.py

Escreve `MODELOS_ENTRADA/Titan_TV_Man/Titan_7_Tools.rbxmx`: Handle, SFX, Values
e os dois `RemoteEvent`. O Lua vem depois, dos geradores.

════════════════════════════════════════════════════════════════════════
ESTE CONJUNTO É AUTORAL — NÃO SAI DE MODELO NENHUM
════════════════════════════════════════════════════════════════════════

    Não chegou `.rbxmx` de origem. O conjunto é do mesmo tipo que o
    `collector`: nasce aqui, e por isso não há ficha §12.12 a abrir, nem
    lógica de terceiro a descartar — não há terceiro.

    O que NÃO é autoral são os 21 `SoundId`. Id de som não se inventa: id
    chutado é som mudo que nenhum verificador pega — o `.rbxmx` fica válido e
    o jogo fica em silêncio. Os 21 saem todos do catálogo do Acervo, dos
    `SFX/ids.md` que já estão em ficha, e a coluna da direita de `SONS` diz de
    qual. Isso é o §12.16.2 funcionando: "se já existe equivalente, reusar".

    A GEOMETRIA é primitiva soldada, montada aqui. Um TV Man é um gabinete de
    televisão com uma tela, duas antenas e um corpo de terno — tudo isso é
    `Part` com `Block`, `Cylinder` e `Ball`. Nenhuma malha de terceiro entra,
    e portanto nenhum `MeshId` precisa de ficha.

════════════════════════════════════════════════════════════════════════
TRÊS HABILIDADES POR TOOL, E POR ISSO DUAS TECLAS
════════════════════════════════════════════════════════════════════════

    M1 no clique, mais DUAS Extras em `R` e `T` — a mesma distribuição do
    JUPITER. Sete Tools, 21 habilidades, dentro do teto de 14 por conjunto?
    Não: o teto da REGRA_DISTRIBUICAO é 7 Tools, e o número de Extras por Tool
    é decisão autoral declarada no relatório. Aqui são duas.

    O `AcaoRemote` é UM só: quem diferencia é o nome da tecla no payload,
    conferido no servidor antes de agir. Dois remotes seriam duas portas para
    o mesmo cômodo, e duas superfícies para validar.

════════════════════════════════════════════════════════════════════════
O QUE NÃO ENTRA
════════════════════════════════════════════════════════════════════════

    A tentação óbvia de um personagem com TELA na cabeça é `ScreenGui` — o
    chuvisco na tela do jogador, a estática cobrindo a visão. `ScreenGui`,
    `ColorCorrection` e `Sky` são os três proibidos dentro de Tool. O
    chuvisco desta Tool vive no MUNDO 3D: um volume de partícula à frente de
    quem levou, que atrapalha porque está lá, não porque desenhou por cima da
    câmera de alguém.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Titan_TV_Man",
                     "Titan_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — 21 ids, TODOS do catálogo do Acervo
#
# A coluna da direita é a ficha de onde o id saiu. Nenhum foi inventado.
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Titan Estatica": [
        ("CHUVISCO", "9114524356", 4, 1.0),    # `hum`  — VFX_Library_V2
        ("ESTATICA", "2674547670", 5, 0.9),    # `Electric Explosion` — Trident
        ("ESPELHO", "9125673453", 4, 1.2),     # `Beep` — Canhao_Satelite
    ],
    "Titan Raio Catodico": [
        ("FAISCA", "2273224484", 4, 1.15),     # `eyeglow` — VFX_Library_V2
        ("FEIXE", "782353443", 5, 0.95),       # `energystrike` — VFX_Library_V2
        ("LEQUE", "80214468", 4, 1.05),        # `Lightning1` — Jupiter
    ],
    "Titan Antena": [
        ("CHICOTE", "145486992", 4, 1.1),      # `sfx_swooshing` — Dano_Verdadeiro
        ("SINAL", "1310929645", 4, 0.9),       # `Locked On` — Sword_of_Cosmic_Entity
        ("INTERFERE", "8578316223", 4, 0.8),   # `charge` — VFX_Library_V2
    ],
    "Titan Alto Falante": [
        ("BATIDA", "145486953", 4, 1.0),       # `sfx_hit` — Dano_Verdadeiro
        ("CONE", "9125402735", 5, 0.85),       # `DuperBoom` — Jupiter
        ("GRITO", "7127123554", 6, 0.75),      # `Roar2` — Xester_Forma2
    ],
    "Titan Lamina": [
        ("CORTE", "4958430453", 4, 1.0),       # `Slash` — Guest_Tools
        ("ESTOCADA", "8145344127", 4, 1.1),    # `SwordLunge` — Jupiter
        ("DESCE", "5287092000", 5, 0.85),      # `SwordHit` — Jupiter
    ],
    "Titan Propulsor": [
        ("INVESTIDA", "9126231485", 4, 1.0),   # `whoosh` — Canhao_Satelite
        ("VOO", "8186570431", 4, 0.95),        # `Fly` — YorrSlayer
        ("DESVIO", "7449437048", 4, 1.2),      # `Launch1` — Trident
    ],
    "Titan Sobrecarga": [
        ("DESCARGA", "6523812578", 4, 1.0),    # `Power Up` — Sword_of_Cosmic_Entity
        ("SOBRECARGA", "814635481", 5, 0.9),   # `Big Explosion` — VFX_Library_V2
        ("REINICIO", "18872474050", 6, 0.8),   # `Supernova` — Sword_of_Cosmic_Entity
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES
#
# (nome, tamanho, forma, cor, material, deslocamento)
# A primeira peça de cada lista É o Handle; as outras são soldadas nela.
#
# A paleta é a do personagem: o gabinete preto fosco da TV, o branco-azulado
# da varredura na tela, o cromado da antena e o marrom do terno.
# ═══════════════════════════════════════════════════════════════

GABINETE = cor(28, 28, 32)
TELA = cor(226, 240, 255)
VARREDURA = cor(120, 200, 255)
CROMADO = cor(198, 202, 210)
TERNO = cor(78, 58, 44)
BRASA = cor(255, 148, 62)
ALERTA = cor(255, 72, 72)

HANDLES = {
    # a estática: o gabinete inteiro na mão, tela para a frente
    "Titan Estatica": [
        ("Handle", (0.5, 2.2, 0.5), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Gabinete", (2.4, 2.0, 1.8), "Block", GABINETE, "Metal", (0, 1.9, 0)),
        ("Tela", (2.0, 1.6, 0.16), "Block", TELA, "Neon", (0, 1.9, -0.9)),
        ("AntenaE", (0.1, 2.2, 0.1), "Block", CROMADO, "Metal", (-0.7, 3.4, 0.4)),
        ("AntenaD", (0.1, 2.2, 0.1), "Block", CROMADO, "Metal", (0.7, 3.4, 0.4)),
    ],
    # o raio catódico: o tubo de imagem, sem gabinete
    "Titan Raio Catodico": [
        ("Handle", (0.45, 2.0, 0.45), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Tubo", (1.3, 2.6, 1.3), "Cylinder", CROMADO, "Metal", (0, 1.8, 0)),
        ("Lente", (1.1, 1.1, 1.1), "Ball", VARREDURA, "Neon", (0, 3.1, 0)),
        ("Bobina", (1.6, 0.24, 1.6), "Cylinder", GABINETE, "Metal", (0, 1.0, 0)),
    ],
    # a antena: haste longa, prato no meio, ponta acesa
    "Titan Antena": [
        ("Handle", (0.35, 1.8, 0.35), "Block", TERNO, "Fabric", (0, 0, 0)),
        ("Haste", (0.14, 5.4, 0.14), "Block", CROMADO, "Metal", (0, 3.4, 0)),
        ("Prato", (1.8, 0.12, 1.8), "Cylinder", CROMADO, "SmoothPlastic",
         (0, 2.4, 0)),
        ("Ponta", (0.42, 0.42, 0.42), "Ball", ALERTA, "Neon", (0, 6.1, 0)),
    ],
    # o alto-falante: caixa, cone e cúpula
    "Titan Alto Falante": [
        ("Handle", (0.5, 1.9, 0.5), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Caixa", (2.2, 2.2, 1.4), "Block", GABINETE, "SmoothPlastic",
         (0, 1.9, 0)),
        ("Cone", (1.7, 0.5, 1.7), "Cylinder", TERNO, "Fabric", (0, 1.9, -0.8)),
        ("Cupula", (0.7, 0.7, 0.7), "Ball", CROMADO, "Metal", (0, 1.9, -1.0)),
    ],
    # a lâmina: a espada gigante do Titan melhorado
    "Titan Lamina": [
        ("Handle", (0.42, 1.6, 0.42), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Lamina", (0.26, 6.0, 1.2), "Block", CROMADO, "Metal", (0, 3.6, 0)),
        ("Fio", (0.12, 5.8, 0.34), "Block", VARREDURA, "Neon", (0, 3.6, 0.42)),
        ("Guarda", (2.1, 0.3, 0.7), "Block", GABINETE, "Metal", (0, 0.9, 0)),
        ("Contrapeso", (0.5, 0.5, 0.5), "Ball", ALERTA, "Neon", (0, -0.9, 0)),
    ],
    # o propulsor: a turbina das costas, na mão
    "Titan Propulsor": [
        ("Handle", (0.5, 2.0, 0.5), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Turbina", (1.5, 2.4, 1.5), "Cylinder", CROMADO, "Metal", (0, 1.8, 0)),
        ("Bocal", (1.1, 0.9, 1.1), "Cylinder", GABINETE, "Metal", (0, 0.5, 0)),
        ("Chama", (0.9, 0.9, 0.9), "Ball", BRASA, "Neon", (0, 0.0, 0)),
    ],
    # a sobrecarga: o núcleo exposto, com o aro de contenção
    "Titan Sobrecarga": [
        ("Handle", (0.55, 2.0, 0.55), "Block", GABINETE, "Metal", (0, 0, 0)),
        ("Nucleo", (1.7, 1.7, 1.7), "Ball", ALERTA, "Neon", (0, 2.0, 0)),
        ("Aro", (2.6, 0.2, 2.6), "Cylinder", CROMADO, "Metal", (0, 2.0, 0)),
        ("Grade", (2.0, 0.16, 2.0), "Cylinder", GABINETE, "Metal", (0, 1.0, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Titan Estatica",
     "Bate com a tela. R solta o chuvisco; T espelha o dano de volta.",
     "ARCANO", 0.9, 13, 24, "Titan_Estatica"),

    ("Titan Raio Catodico",
     "Faisca curta do tubo. R e o feixe reto; T abre o leque de raios.",
     "ASTRAL", 0.8, 11, 22, "Titan_Catodico"),

    ("Titan Antena",
     "Chicote de antena, longo. R planta a torre que marca; T interfere.",
     "ARCANO", 1.0, 15, 20, "Titan_Antena"),

    ("Titan Alto Falante",
     "Batida sonica. R e o cone de choque; T e o grito que derruba.",
     "EXPLOSIVO", 0.9, 12, 23, "Titan_Falante"),

    ("Titan Lamina",
     "Corte pesado em tres tempos. R e a estocada; T e o corte que abre o chao.",
     "MELEE", 0.7, 10, 21, "Titan_Lamina"),

    ("Titan Propulsor",
     "Investida com turbina. R e o voo curto com pouso; T e o desvio lateral.",
     "MELEE", 0.8, 12, 9, "Titan_Propulsor"),

    ("Titan Sobrecarga",
     "Descarga na mao. R e a sobrecarga do campo; T e o reinicio.",
     "EXPLOSIVO", 1.2, 18, 38, "Titan_Sobrecarga"),
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
    item, props = novo_item(pai, "Part", nome, "RV_TP_%s_%s" % (marca, nome))
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
    item, props = novo_item(pai, "Weld", "SoldaT%d" % indice,
                            "RV_TW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_TP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_TP_%s_%s" % (marca, alvo_nome)
    return item


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, _rec_r, _rec_t, chave = dados
    marca = chave.replace("Titan_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_TT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for pnome, tam, forma, tinta, mat, _desloc in partes:
        peca(tool, pnome, tam, forma, tinta, mat, marca)
    handle = tool.find("Item")
    for indice, dados_peca in enumerate(partes[1:], start=1):
        soldar(handle, dados_peca[0], marca, dados_peca[5], indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_TSFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo,
                           "RV_TS_%s_%s" % (marca, rotulo))
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
        _i, vp = novo_item(tool, classe, alvo, "RV_TV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    # UM `AcaoRemote` para as DUAS Extras: quem separa é o nome da tecla no
    # payload, conferido no servidor.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_TVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_TACAO_%s" % marca)

    for classe, alvo in (("Script", "%s_Server_V1" % nome.replace(" ", "")),
                         ("Script", "Client"),
                         ("ModuleScript", "R6CFrameAnimator"),
                         ("ModuleScript", "Poses"),
                         ("ModuleScript", "VFXModule")):
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_TSC_%s_%s" % (marca, alvo[:10]))
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

    print("BASE DO CONJUNTO TITAN — TV Man Titan")
    print("")
    print("  %-24s %-11s %s" % ("TOOL", "ARQUETIPO", "peças · sons · recargas"))
    for nome, _t, arq, m1, r, t, _c in CONJUNTO:
        print("  %-24s %-11s %d peça(s) · %d som(ns) · M1 %.1fs / R %ds / T %ds"
              % (nome, arq, len(HANDLES[nome]), len(SONS[nome]), m1, r, t))
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("  %d SoundId distinto(s), todos do catálogo do Acervo" % len(ids))
    print("  0 MeshId — a geometria inteira é primitiva soldada")
    return 0


if __name__ == "__main__":
    sys.exit(main())
