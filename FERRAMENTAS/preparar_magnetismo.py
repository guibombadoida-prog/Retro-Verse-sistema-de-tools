#!/usr/bin/env python3
"""
preparar_magnetismo.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto MAGNETISMO.

    python3 FERRAMENTAS/preparar_magnetismo.py

Escreve `MODELOS_ENTRADA/Magnetismo/Magnetismo_7_Tools.rbxmx`.

════════════════════════════════════════════════════════════════════════
O QUINTO CONJUNTO AUTORAL
════════════════════════════════════════════════════════════════════════

    Não chegou modelo. Como o `collector`, o `Titan_TV_Man`, o
    `Poderes_de_Bomba` e o `Poder_da_Criacao`, ele nasce aqui.

    E ele existe por dois motivos, não um. O tema foi pedido; e ele é o lugar
    certo para PROVAR o que a triagem de VFX/SFX/animação/cutscene achou
    (`FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md`). Achado que não é
    usado em nada vira nota de rodapé.

════════════════════════════════════════════════════════════════════════
ELE É O PRIMEIRO CONJUNTO COM GRUPO DE VARIAÇÃO DE SFX
════════════════════════════════════════════════════════════════════════

    Achado nº 1 da triagem: as 129 Tools tocam UMA amostra por ação, e há 76
    variantes paradas nos modelos de entrada. `tocar()` já sabe sortear desde
    2026-08-29 — o que faltava era alguém montar os grupos.

    Aqui `Tool/SFX/<PAPEL>` é uma **Folder** quando há mais de uma gravação, e
    um `Sound` avulso quando há uma só. O peso é um `NumberValue` chamado
    `Weight` dentro do `Sound`.

    O caso mais bonito é a `Bobina de Tesla`: o Acervo tem `Lightning1` até
    `Lightning6` — SEIS gravações do mesmo raio, catalogadas há meses e nunca
    usadas juntas. O `ARCO` dela é um grupo de seis, e o jogador que segurar
    o M1 vinte vezes ouve vinte raios diferentes.

════════════════════════════════════════════════════════════════════════
A POLARIDADE É O EIXO DO CONJUNTO
════════════════════════════════════════════════════════════════════════

    Todo conjunto anterior tem sete Tools que não se falam. Este tem uma
    mecânica que atravessa as sete: **polaridade**.

    Quem é atingido fica carregado, NORTE ou SUL, por um prazo. E carga
    manda no que as OUTRAS Tools fazem com ele:

      · mesma polaridade  →  repele. O empurrão sai mais forte.
      · polaridade oposta →  atrai. O puxão sai mais forte.
      · sem carga         →  o efeito é o normal.

    A carga mora num `Attribute` no `Humanoid` do alvo — não num depósito, nem
    numa global. É o mesmo lugar e a mesma natureza da tag `creator` que o
    repositório já usa para creditar abate: marca de ENTIDADE EM CAMPO, que a
    regra nº 1 sempre permitiu.

════════════════════════════════════════════════════════════════════════
OS 21 SoundId SÃO DO CATÁLOGO
════════════════════════════════════════════════════════════════════════

    Id de som não se inventa: id chutado é som mudo que nenhum verificador
    estático pega — o `.rbxmx` fica válido e o jogo fica em silêncio. Todos
    saem das fichas do Acervo, e o comentário diz de qual.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Magnetismo",
                     "Magnetismo_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568, "Grass": 1280,
            "Slate": 800, "Concrete": 816, "Brick": 848,
            "DiamondPlate": 1072, "CorrodedMetal": 1104}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

COM_CUTSCENE = ("Colapso Magnetico",)


def cor(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# ═══════════════════════════════════════════════════════════════
# SFX — 21 papéis. GRUPO quando há mais de uma gravação do mesmo som.
#
#   (papel, [ (id, peso, volume, pitch, de_onde) ... ])
#
# Uma entrada só na lista vira `Sound` avulso; duas ou mais viram `Folder`.
# ═══════════════════════════════════════════════════════════════

SONS = {
    "Polo Norte": {
        # três formas de "puxar": a gravação de puxão, e dois deslocamentos de ar
        "PUXAR": [("7449454666", 3, 4, 0.9, "Pull — Trident"),
                  ("1489705211", 2, 4, 0.8, "Swoosh — Guest_Tools"),
                  ("181894961", 1, 4, 0.85, "Swoosh2 — Guest_Tools")],
        "CUPULA": [("9114524356", 1, 4, 0.75, "hum — VFX_Library_V2")],
        "IMPLOSAO": [("9125402735", 1, 6, 0.7, "DuperBoom — VFX_Library_V2")],
    },
    "Polo Sul": {
        "EMPURRAR": [("3755636638", 3, 4, 1.0, "Swoosh — Trident"),
                     ("3015952873", 2, 4, 1.1, "swoosh — VFX_Library_V2"),
                     ("9126231485", 1, 4, 0.95, "whoosh — VFX_Library_V2")],
        "ESCUDO": [("127416781", 1, 4, 1.0, "ChargeReady — VFX_Library_V2")],
        "ONDA": [("163064102", 1, 6, 0.85, "Explosion — VFX_Library_V2")],
    },
    "Ferrovia Magnetica": {
        # trilho é metal batendo em metal: as duas gravações do Guest
        "TRILHO": [("933780081", 2, 4, 0.9, "MetalHit — Guest_Tools"),
                   ("546410481", 2, 4, 1.05, "MetalHit2 — Guest_Tools")],
        "MONTAR": [("145486992", 1, 5, 0.9, "sfx_swooshing — VFX_Library_V2")],
        "MALHA": [("814635481", 1, 6, 0.8, "Big Explosion — Canhao_Satelite")],
    },
    "Sucata": {
        "COLETAR": [("933780081", 3, 4, 1.1, "MetalHit — Guest_Tools"),
                    ("546410481", 3, 4, 0.95, "MetalHit2 — Guest_Tools"),
                    ("743886825", 2, 4, 1.0, "Hit — Reality_Tools")],
        "ARREMESSAR": [("181894961", 1, 5, 0.85, "Swoosh2 — Guest_Tools")],
        "CHUVA": [("6741488567", 1, 6, 0.8, "expl — VFX_Library_V2")],
    },
    "Bobina de Tesla": {
        # ⭐ O GRUPO DE SEIS. `Lightning1`..`Lightning6` estão catalogados no
        #    Acervo há meses e nunca foram usados juntos por nada. Vinte
        #    cliques, vinte raios diferentes.
        "ARCO": [("80214468", 1, 4, 1.0, "Lightning1 — VFX_Library_V2"),
                 ("96478259", 1, 4, 1.0, "Lightning2 — VFX_Library_V2"),
                 ("96478567", 1, 4, 1.0, "Lightning3 — VFX_Library_V2"),
                 ("96478505", 1, 4, 1.0, "Lightning4 — VFX_Library_V2"),
                 ("96478346", 1, 4, 1.0, "Lightning5 — VFX_Library_V2"),
                 ("96478426", 1, 4, 1.0, "Lightning6 — VFX_Library_V2")],
        "BOBINA": [("8578316223", 1, 4, 0.85, "charge — VFX_Library_V2")],
        "DESCARGA": [("2674547670", 1, 6, 0.8, "Electric Explosion — Canhao")],
    },
    "Levitacao": {
        "SUSPENDER": [("9114524356", 3, 4, 1.05, "hum — VFX_Library_V2"),
                      ("5651577252", 1, 4, 1.2, "glint — VFX_Library_V2")],
        "FLUTUAR": [("127416781", 1, 4, 0.9, "ChargeReady — VFX_Library_V2")],
        "INVERTER": [("1846396833", 1, 5, 0.8, "Summon — VFX_Library_V2")],
    },
    "Colapso Magnetico": {
        "CARGA": [("175024455", 3, 4, 1.1, "Hit — VFX_Library_V2"),
                  ("3932505023", 2, 4, 1.0, "Hit2 — VFX_Library_V2"),
                  ("743886825", 1, 4, 1.15, "Hit — Reality_Tools")],
        "ATRAIR_CARGAS": [("5405455343", 1, 5, 0.85, "JupiterSummon — Jupiter")],
        "SINGULARIDADE": [("18872474050", 1, 6, 0.72,
                           "Supernova — Sword_of_Cosmic_Entity")],
    },
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES — (nome, tamanho, forma, cor, material, deslocamento)
#
# A gramática do conjunto: TODO Handle tem DOIS PÓLOS visíveis, e eles são
# vermelho e azul. É a convenção universal de ímã, e é o que faz o jogador
# saber o que a Tool faz antes de apertar qualquer coisa.
# ═══════════════════════════════════════════════════════════════

FERRO = cor(108, 114, 124)
ACO = cor(168, 176, 188)
NORTE = cor(226, 62, 58)          # vermelho — o pólo que ATRAI aqui
SUL = cor(58, 122, 226)           # azul — o pólo que REPELE
COBRE = cor(196, 122, 62)
FAISCA = cor(150, 220, 255)
ESCURO = cor(28, 26, 34)
FERRUGEM = cor(126, 86, 62)
ROXO = cor(148, 96, 224)

HANDLES = {
    # ferradura clássica, com a ponta norte acesa
    "Polo Norte": [
        ("Handle", (0.5, 2.0, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Arco", (1.9, 0.6, 0.6), "Block", FERRO, "Metal", (0, 1.7, 0)),
        ("HasteA", (0.55, 1.6, 0.55), "Block", FERRO, "Metal", (0.7, 2.6, 0)),
        ("HasteB", (0.55, 1.6, 0.55), "Block", FERRO, "Metal", (-0.7, 2.6, 0)),
        ("PontaN", (0.6, 0.45, 0.62), "Block", NORTE, "Neon", (0.7, 3.5, 0)),
        ("PontaS", (0.6, 0.45, 0.62), "Block", SUL, "Neon", (-0.7, 3.5, 0)),
    ],
    # a mesma ferradura, invertida: a haste azul é a longa
    "Polo Sul": [
        ("Handle", (0.5, 2.0, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Arco", (1.9, 0.6, 0.6), "Block", FERRO, "Metal", (0, 1.7, 0)),
        ("HasteA", (0.55, 1.9, 0.55), "Block", FERRO, "Metal", (0.7, 2.75, 0)),
        ("HasteB", (0.55, 1.2, 0.55), "Block", FERRO, "Metal", (-0.7, 2.4, 0)),
        ("PontaS", (0.62, 0.5, 0.64), "Block", SUL, "Neon", (0.7, 3.8, 0)),
        ("PontaN", (0.62, 0.5, 0.64), "Block", NORTE, "Neon", (-0.7, 3.1, 0)),
    ],
    # um pedaço de trilho de maglev num cabo
    "Ferrovia Magnetica": [
        ("Handle", (0.45, 1.8, 0.45), "Block", FERRUGEM, "Wood", (0, 0, 0)),
        ("Base", (0.7, 0.3, 3.2), "Block", FERRO, "DiamondPlate", (0, 1.6, 0)),
        ("TrilhoA", (0.22, 0.5, 3.4), "Block", ACO, "Metal", (0.28, 1.95, 0)),
        ("TrilhoB", (0.22, 0.5, 3.4), "Block", ACO, "Metal", (-0.28, 1.95, 0)),
        ("Faisca", (0.16, 0.16, 3.0), "Block", FAISCA, "Neon", (0, 1.95, 0)),
    ],
    # eletroímã de guindaste, com a bola de sucata pendurada
    "Sucata": [
        ("Handle", (0.5, 1.7, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Disco", (2.6, 0.5, 2.6), "Cylinder", FERRO, "CorrodedMetal",
         (0, 1.6, 0)),
        ("Bobina", (2.2, 0.3, 2.2), "Cylinder", COBRE, "Metal", (0, 1.95, 0)),
        ("Bola", (1.7, 1.7, 1.7), "Ball", FERRUGEM, "CorrodedMetal",
         (0, 0.1, 0)),
        ("Elo", (0.18, 1.2, 0.18), "Block", ACO, "Metal", (0, 0.9, 0)),
    ],
    # bobina de Tesla: pilha de anéis de cobre com a esfera no topo
    "Bobina de Tesla": [
        ("Handle", (0.5, 1.6, 0.5), "Block", ESCURO, "Metal", (0, 0, 0)),
        ("NucleoA", (1.5, 0.28, 1.5), "Cylinder", COBRE, "Metal", (0, 1.5, 0)),
        ("NucleoB", (1.3, 0.28, 1.3), "Cylinder", COBRE, "Metal", (0, 1.9, 0)),
        ("NucleoC", (1.1, 0.28, 1.1), "Cylinder", COBRE, "Metal", (0, 2.3, 0)),
        ("Toroide", (2.0, 0.5, 2.0), "Cylinder", ACO, "Metal", (0, 2.8, 0)),
        ("Arco", (0.9, 0.9, 0.9), "Ball", FAISCA, "Neon", (0, 3.2, 0)),
    ],
    # dois discos opostos, com a esfera flutuando entre eles
    "Levitacao": [
        ("Handle", (0.5, 1.8, 0.5), "Block", ACO, "Metal", (0, 0, 0)),
        ("DiscoBaixo", (2.4, 0.35, 2.4), "Cylinder", SUL, "Metal", (0, 1.6, 0)),
        ("DiscoAlto", (2.4, 0.35, 2.4), "Cylinder", NORTE, "Metal",
         (0, 3.6, 0)),
        ("Coluna", (0.22, 2.0, 0.22), "Block", ACO, "Metal", (0, 2.6, 0)),
        ("Suspensa", (1.0, 1.0, 1.0), "Ball", FAISCA, "Neon", (0, 2.6, 0)),
    ],
    # a ultimate: o núcleo escuro numa gaiola de anéis
    "Colapso Magnetico": [
        ("Handle", (0.55, 1.8, 0.55), "Block", ESCURO, "Metal", (0, 0, 0)),
        ("Nucleo", (1.9, 1.9, 1.9), "Ball", ESCURO, "Glass", (0, 2.6, 0)),
        ("Halo", (2.2, 2.2, 2.2), "Ball", ROXO, "Neon", (0, 2.6, 0)),
        ("AnelA", (3.2, 0.16, 3.2), "Cylinder", ACO, "Metal", (0, 2.6, 0)),
        ("AnelB", (0.16, 3.2, 3.2), "Cylinder", ACO, "Metal", (0, 2.6, 0)),
        ("AnelC", (3.2, 3.2, 0.16), "Cylinder", ACO, "Metal", (0, 2.6, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Polo Norte",
     "Puxa o que e de metal, e quem levar fica com carga NORTE. R abre a "
     "cupula que suga; T implode tudo no ponto.",
     "ARCANO", 0.9, 15, 26, "Magnetismo_Norte"),

    ("Polo Sul",
     "Empurra tudo a frente e carrega o alvo de SUL. R e o escudo repulsor; "
     "T e a onda que limpa o circulo.",
     "ARCANO", 0.9, 14, 24, "Magnetismo_Sul"),

    ("Ferrovia Magnetica",
     "Assenta um trilho que arrasta quem pisa. R lanca voce pelo proprio "
     "trilho; T cruza a malha inteira.",
     "MELEE", 1.0, 12, 25, "Magnetismo_Ferrovia"),

    ("Sucata",
     "Junta o metal solto numa bola. R arremessa a bola; T faz a chuva de "
     "sucata cair no alvo.",
     "EXPLOSIVO", 0.8, 13, 23, "Magnetismo_Sucata"),

    ("Bobina de Tesla",
     "O arco salta de alvo em alvo. R planta a bobina que pulsa; T solta a "
     "descarga em todos os carregados.",
     "ASTRAL", 0.8, 16, 27, "Magnetismo_Bobina"),

    ("Levitacao",
     "Suspende o alvo no ar, sem controle. R faz voce flutuar; T inverte a "
     "gravidade de quem esta na area.",
     "ARCANO", 1.0, 14, 28, "Magnetismo_Levitacao"),

    ("Colapso Magnetico",
     "Marca o alvo com carga. R faz as cargas se atrairem; T e a "
     "singularidade, com cena.",
     "EXPLOSIVO", 1.1, 18, 46, "Magnetismo_Colapso"),
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


def som(pai, nome, ident, volume, pitch, peso, ref):
    """Um `Sound`. Com `peso`, ganha o `NumberValue` que o sorteio lê."""
    _s, sp = novo_item(pai, "Sound", nome, ref)
    conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
    ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
    ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
    ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
    ET.SubElement(sp, "float", {"name": "RollOffMaxDistance"}).text = "280"
    ET.SubElement(sp, "bool", {"name": "Looped"}).text = "false"
    if peso is not None and peso != 1:
        _w, wp = novo_item(_s, "NumberValue", "Weight", ref + "_W")
        ET.SubElement(wp, "float", {"name": "Value"}).text = str(peso)
    return _s


def montar_sfx(tool, nome, marca):
    """`Tool/SFX/` — `Sound` avulso quando há uma gravação, `Folder` quando há
    mais de uma. É o grupo de variação da triagem, e é o que faz o mesmo golpe
    não soar igual cem vezes."""
    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_MSFX_%s" % marca)
    grupos = 0
    for papel, gravacoes in SONS[nome].items():
        base = "RV_MS_%s_%s" % (marca, papel)
        if len(gravacoes) == 1:
            ident, peso, volume, pitch, _de = gravacoes[0]
            som(sfx, papel, ident, volume, pitch, None, base)
        else:
            grupos = grupos + 1
            pasta, _p = novo_item(sfx, "Folder", papel, base + "_G")
            for i, (ident, peso, volume, pitch, _de) in enumerate(gravacoes, 1):
                som(pasta, "%s_%d" % (papel, i), ident, volume, pitch, peso,
                    "%s_%d" % (base, i))
    return grupos


def montar_tool(raiz, dados):
    nome, tooltip, arquetipo, rec_m1, _r, _t, chave = dados
    marca = chave.replace("Magnetismo_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_MT_%s" % marca)
    ET.SubElement(props, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(props, "bool", {"name": "RequiresHandle"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanBeDropped"}).text = "false"

    partes = HANDLES[nome]
    for pnome, tam, forma, tinta, mat, _d in partes:
        peca(tool, pnome, tam, forma, tinta, mat, marca)
    handle = tool.find("Item")
    for indice, dp in enumerate(partes[1:], start=1):
        soldar(handle, dp[0], marca, dp[5], indice)

    grupos = montar_sfx(tool, nome, marca)

    # ── Moldes: a limalha de ferro, invisível na entrega (regra nº 2)
    #
    # UM molde só, e minúsculo: a limalha é feita de CENTENAS de cópias dele.
    # É por isso que o VFXModule usa `workspace:BulkMoveTo` — mover 300 peças
    # com 300 escritas de propriedade é o que a triagem apontou como o custo
    # que ninguém estava pagando de propósito.
    moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_MMOLD_%s" % marca)
    _lim, lp = novo_item(moldes, "Part", "Limalha",
                         "RV_MLIM_%s" % marca)
    vetor(lp, "Vector3", "size", (0.08, 0.08, 0.34))
    cor3(lp, "Color3uint8", FERRO)
    ET.SubElement(lp, "token", {"name": "formFactorRaw"}).text = "1"
    ET.SubElement(lp, "token", {"name": "shape"}).text = "1"
    ET.SubElement(lp, "token", {"name": "Material"}).text = str(MATERIAL["Metal"])
    ET.SubElement(lp, "bool", {"name": "Anchored"}).text = "true"
    ET.SubElement(lp, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(lp, "bool", {"name": "CanTouch"}).text = "false"
    ET.SubElement(lp, "bool", {"name": "CanQuery"}).text = "false"
    ET.SubElement(lp, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(lp, "bool", {"name": "CastShadow"}).text = "false"
    ET.SubElement(lp, "float", {"name": "Transparency"}).text = "1"

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", arquetipo),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("StringValue", "string", "ChaveVFX", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
        _i, vp = novo_item(tool, classe, alvo, "RV_MV_%s_%s" % (marca, alvo[:7]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_MVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_MACAO_%s" % marca)

    scripts = [("Script", "%s_Server_V1" % nome.replace(" ", "")),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule"),
               ("ModuleScript", "DepositoVFX")]

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
    return tool, grupos


def main():
    raiz = nova_raiz()
    print("BASE DO CONJUNTO MAGNETISMO")
    print("")
    print("  %-20s %-10s %s" % ("TOOL", "ARQUETIPO", "peças · SFX · recargas"))

    total_grupos, total_sons = 0, 0
    for dados in CONJUNTO:
        _tool, grupos = montar_tool(raiz, dados)
        nome, _t, arq, m1, r, t, _c = dados
        n_som = sum(len(g) for g in SONS[nome].values())
        total_grupos = total_grupos + grupos
        total_sons = total_sons + n_som
        cena = " · CENA" if nome in COM_CUTSCENE else ""
        print("  %-20s %-10s %d peça(s) · %d som(ns) em %d grupo(s) · "
              "M1 %.1fs / R %ds / T %ds%s"
              % (nome, arq, len(HANDLES[nome]), n_som, grupos, m1, r, t, cena))

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    ids = {i for tool in SONS.values() for g in tool.values()
           for i, _p, _v, _pi, _de in g}
    print("")
    print("  %s — %d bytes · 7 Tools"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA)))
    print("  %d Sound em %d GRUPO(S) DE VARIAÇÃO · %d SoundId distinto(s), "
          "todos do catálogo" % (total_sons, total_grupos, len(ids)))
    print("  0 MeshId — a geometria inteira é primitiva soldada")
    return 0


if __name__ == "__main__":
    sys.exit(main())
