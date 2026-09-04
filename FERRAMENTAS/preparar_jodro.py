#!/usr/bin/env python3
"""
preparar_jodro.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto JODRO — o conjunto de meme.

    python3 FERRAMENTAS/preparar_jodro.py

Escreve `MODELOS_ENTRADA/Jodro/Jodro_7_Tools.rbxmx`: Handle, SFX, Values e os
dois `RemoteEvent`. O Lua vem depois, dos geradores.

════════════════════════════════════════════════════════════════════════
SEM MODELO DE ORIGEM — E ISSO MUDA DUAS COISAS
════════════════════════════════════════════════════════════════════════

    Não há `.rbxmx` de terceiro aqui. Ninguém mandou um modelo de meme; as 7
    são autorais inteiras. Consequências:

    1. **O Handle é primitiva montada aqui.** Cada um é uma pequena assembleia
       de `Part` soldada por `Weld` ao Handle, com cor e forma escolhidas para
       ler o meme de longe. Sem malha de terceiro, sem `rbxassetid` de mesh —
       nada a licenciar (§12.12.3 já nasce resolvido).

    2. **O som é REUSADO do que já roda aqui.** Nenhum `SoundId` foi inventado.
       Cada id abaixo já está tocando em alguma Tool entregue deste
       repositório, e por isso sabidamente carrega. Id chutado é som mudo que
       nenhum verificador pega — o `.rbxmx` fica válido e o jogo fica em
       silêncio.

════════════════════════════════════════════════════════════════════════
TRÊS HABILIDADES POR TOOL, E POR ISSO DUAS TECLAS
════════════════════════════════════════════════════════════════════════

    Os conjuntos anteriores tinham M1 + uma Extra. Estas têm M1 + DUAS, em `R`
    e `T`. O `AcaoRemote` continua sendo UM só: quem diferencia é o nome da
    tecla no payload, que o servidor confere antes de agir.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Jodro", "Jodro_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — TODO id abaixo já toca em alguma Tool entregue deste repositório
#
# A coluna da direita diz onde ele já vive. Isso não é curiosidade: é a prova
# de que o id carrega. Ver o cabeçalho.
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Bonk": [
        ("BONK", "933780081", 4, 1.25),      # MetalHit (Guest / Astral)
        ("MEGA", "472579737", 5, 0.7),       # Explode (bombas)
        ("CADEIA", "413682983", 3, 1.0),     # CORRENTE (Submundo)
    ],
    "Chinelo Voador": [
        ("TAPA", "1086616651", 4, 1.3),      # sfx_corte (Escudos)
        ("VOA", "342337569", 3, 1.35),       # VARRE (Olho do Vigia)
        ("BRAVA", "1072606965", 4, 0.85),    # GRITO (Submundo)
    ],
    "Sussy": [
        ("FACA", "1086616651", 3.5, 1.55),   # sfx_corte
        ("VENT", "1894958339", 4, 0.95),     # DESFAZ (Perturbacao)
        ("REUNIAO", "743521450", 4, 0.8),    # ZUMBIDO
    ],
    "Caixa de Som": [
        ("ONDA", "2960518660", 4, 0.9),      # GRAVE (Faker)
        ("NUNCA", "824687369", 5, 0.75),     # COROA (Astral)
        ("TROCA", "260281717", 3.5, 1.2),    # TeleSpike (Astral)
    ],
    "Privada Sonora": [
        ("JATO", "342337569", 4, 0.7),       # VARRE
        ("DESCARGA", "472579737", 5, 1.15),  # Explode
        ("CORO", "1072606965", 4, 1.4),      # GRITO agudo
    ],
    "Pombo Correio": [
        ("BICADA", "546410481", 3, 1.5),     # MetalHit2 (Guest)
        ("REVOADA", "743521450", 4, 1.25),   # ZUMBIDO
        ("ENCOMENDA", "472214107", 3, 0.9),  # AFUNDA (Submundo)
    ],
    "Deu Ruim": [
        ("APONTA", "220834019", 3, 1.1),     # sfx_impacto (Escudos)
        ("STONKS", "236989198", 4, 1.3),     # ERGUE / SOBE
        ("NOT", "1894958339", 4, 0.65),      # DESFAZ, bem grave
    ],
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES — cada um é uma assembleia de `Part` primitiva
#
# (nome, tamanho, forma, cor, material, deslocamento em relação ao Handle)
# A primeira peça de cada lista É o Handle; as outras são soldadas nele.
# ═══════════════════════════════════════════════════════════════

BRANCO = cor(245, 245, 245)
PRETO = cor(28, 28, 32)
MADEIRA = cor(140, 96, 54)
ACO = cor(150, 160, 172)
VERMELHO = cor(196, 42, 58)
AZUL = cor(0, 122, 190)
AMARELO = cor(255, 196, 40)
VERDE = cor(120, 200, 90)
ROSA = cor(255, 120, 190)

HANDLES = {
    # o martelo: cabo comprido e uma cabeça retangular gorda
    "Bonk": [
        ("Handle", (0.5, 4.2, 0.5), "Block", MADEIRA, "Wood", (0, 0, 0)),
        ("Cabeca", (1.6, 1.4, 1.6), "Block", ACO, "Metal", (0, 2.3, 0)),
        ("Faixa", (1.7, 0.3, 1.7), "Block", PRETO, "SmoothPlastic", (0, 2.3, 0)),
    ],
    # o chinelo: sola fina, tira em V
    "Chinelo Voador": [
        ("Handle", (1.5, 0.35, 3.6), "Block", AZUL, "Fabric", (0, 0, 0)),
        ("Tira", (1.2, 0.2, 0.9), "Block", BRANCO, "Fabric", (0, 0.28, -0.9)),
        ("Dedo", (0.25, 0.2, 0.9), "Block", BRANCO, "Fabric", (0, 0.28, 0.5)),
    ],
    # a faca do impostor: lâmina e cabo curto
    "Sussy": [
        ("Handle", (0.35, 1.2, 0.35), "Block", PRETO, "SmoothPlastic", (0, 0, 0)),
        ("Lamina", (0.12, 2.4, 0.7), "Block", ACO, "Metal", (0, 1.7, 0)),
        ("Guarda", (0.7, 0.2, 0.7), "Block", VERMELHO, "SmoothPlastic", (0, 0.65, 0)),
    ],
    # a caixa de som: caixa e dois cones
    "Caixa de Som": [
        ("Handle", (2.4, 1.6, 1.2), "Block", PRETO, "SmoothPlastic", (0, 0, 0)),
        ("AltoA", (0.9, 0.9, 0.3), "Cylinder", ACO, "Metal", (-0.6, 0, 0.72)),
        ("AltoB", (0.9, 0.9, 0.3), "Cylinder", ACO, "Metal", (0.6, 0, 0.72)),
        ("Luz", (0.3, 0.15, 0.15), "Block", VERDE, "Neon", (0, 0.6, 0.65)),
    ],
    # a privada: base, tampa e um cano
    "Privada Sonora": [
        ("Handle", (1.8, 1.6, 2.2), "Block", BRANCO, "SmoothPlastic", (0, 0, 0)),
        ("Tampa", (1.9, 0.25, 1.6), "Block", BRANCO, "SmoothPlastic", (0, 0.9, -0.2)),
        ("Cano", (0.6, 1.8, 0.6), "Cylinder", ACO, "Metal", (0, 0.6, 1.2)),
    ],
    # o pombo: corpo, cabeça e bico
    "Pombo Correio": [
        ("Handle", (1.1, 1.0, 1.9), "Ball", ACO, "SmoothPlastic", (0, 0, 0)),
        ("Cabeca", (0.7, 0.7, 0.7), "Ball", ACO, "SmoothPlastic", (0, 0.6, -0.9)),
        ("Bico", (0.22, 0.22, 0.55), "Block", AMARELO, "SmoothPlastic", (0, 0.55, -1.4)),
        ("Carta", (0.9, 0.12, 0.7), "Block", BRANCO, "Fabric", (0, -0.45, -0.2)),
    ],
    # o dedo apontado: mão fechada e um dedo
    "Deu Ruim": [
        ("Handle", (1.0, 1.0, 1.0), "Block", ROSA, "SmoothPlastic", (0, 0, 0)),
        ("Dedo", (0.32, 0.32, 1.6), "Block", ROSA, "SmoothPlastic", (0, 0.2, -1.2)),
        ("Unha", (0.3, 0.12, 0.28), "Block", BRANCO, "SmoothPlastic", (0, 0.36, -1.9)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Bonk", "Bonk. Mega Bonk. Cadeia. Nesta ordem.",
     "MELEE", 0.8, 12, 20, "Jodro_Bonk"),
    ("Chinelo Voador", "A chinelada, o chinelo teleguiado e a mae brava.",
     "MELEE", 0.7, 10, 22, "Jodro_Chinelo"),
    ("Sussy", "Facada pelas costas, cano de ventilacao e reuniao de emergencia.",
     "MELEE", 0.9, 14, 26, "Jodro_Sussy"),
    ("Caixa de Som", "Onda sonora, a musica que prende, e a troca de faixa.",
     "SUPORTE", 1.1, 16, 24, "Jodro_Caixa"),
    ("Privada Sonora", "Jato, descarga e o coro de tres.",
     "EXPLOSIVO", 1.0, 15, 30, "Jodro_Privada"),
    ("Pombo Correio", "Bicada, revoada e encomenda que cai do ceu.",
     "ESPECTRAL", 0.8, 13, 28, "Jodro_Pombo"),
    ("Deu Ruim", "O dedo, o Stonks e o Not Stonks.",
     "SUPORTE", 0.9, 18, 25, "Jodro_DeuRuim"),
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
    item, props = novo_item(pai, "Part", nome, "RV_JP_%s_%s" % (marca, nome))
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
    return item, props


def soldar(pai, alvo_nome, marca, deslocamento, indice):
    """Solda uma peça ao Handle. `Weld` com C0 = deslocamento."""
    item, props = novo_item(pai, "Weld", "SoldaJ%d" % indice,
                            "RV_JW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_JP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_JP_%s_%s" % (marca, alvo_nome)
    return item


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, rec_r, rec_t, chave = dados
    marca = chave.replace("Jodro_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_JT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for indice, (pnome, tam, forma, tinta, mat, _desloc) in enumerate(partes):
        peca(tool, pnome, tam, forma, tinta, mat, marca)
    # as soldas vão no Handle, que é a primeira peça
    handle = tool.find("Item")
    for indice, (pnome, _t, _f, _c, _m, desloc) in enumerate(partes[1:], start=1):
        soldar(handle, pnome, marca, desloc, indice)

    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_JSFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, sp = novo_item(sfx, "Sound", rotulo,
                           "RV_JS_%s_%s" % (marca, rotulo))
        conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
        ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
        ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(sp, "float", {"name": "RollOffMaxDistance"}).text = "160"

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", arquetipo),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
        _i, vp = novo_item(tool, classe, alvo, "RV_JV_%s_%s" % (marca, alvo[:6]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    # UM `AcaoRemote` para as DUAS Extras: quem separa é o nome da tecla no
    # payload, conferido no servidor. Dois remotes seriam duas portas para o
    # mesmo cômodo.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_JVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_JACAO_%s" % marca)

    for classe, alvo in (("Script", "%s_Server_V1" % nome.replace(" ", "")),
                         ("Script", "Client"),
                         ("ModuleScript", "R6CFrameAnimator"),
                         ("ModuleScript", "Poses"),
                         ("ModuleScript", "VFXModule")):
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_JSC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo == "Client":
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool


def main():
    raiz = nova_raiz()
    for dados in CONJUNTO:
        montar_tool(raiz, dados)

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("%-22s %-10s %s" % ("TOOL", "ARQUETIPO", "pecas · sons · recargas"))
    for nome, _t, arq, m1, r, t, _c in CONJUNTO:
        print("%-22s %-10s %d · %d · M1 %.1fs / R %ds / T %ds"
              % (nome, arq, len(HANDLES[nome]), len(SONS[nome]), m1, r, t))
    print("")
    print("%s — %d bytes · 7 Tools" % (os.path.relpath(SAIDA, RAIZ),
                                       os.path.getsize(SAIDA)))
    ids = {i for lista in SONS.values() for _r, i, _v, _p in lista}
    print("%d SoundId distinto(s), todos já em uso no repositório" % len(ids))
    return 0


if __name__ == "__main__":
    sys.exit(main())
