#!/usr/bin/env python3
"""
preparar_fogo.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto PODER DE FOGO.

    python3 FERRAMENTAS/preparar_fogo.py

Escreve `MODELOS_ENTRADA/Poder_de_Fogo/Fogo_7_Tools.rbxmx`.

════════════════════════════════════════════════════════════════════════
O SEXTO CONJUNTO AUTORAL — DUAS HABILIDADES POR TOOL
════════════════════════════════════════════════════════════════════════

    Sem modelo de origem: geometria primitiva soldada, e os `SoundId` saem do
    catálogo do Acervo. M1 + `R`, 14 habilidades.

════════════════════════════════════════════════════════════════════════
A QUEIMADURA É O EIXO, E ELA ACUMULA
════════════════════════════════════════════════════════════════════════

    Como a polaridade no MAGNETISMO, aqui uma mecânica atravessa as sete: toda
    Tool APLICA queimadura, e toda Tool LÊ a queimadura que as outras
    deixaram.

    A diferença é que fogo EMPILHA. Polaridade é um estado (norte ou sul);
    queimadura é uma contagem, com teto. Cada camada:

      · tira vida por segundo, sozinha
      · faz o próximo golpe de fogo doer mais
      · e, no teto, o alvo PEGA FOGO de verdade — passa a queimar quem
        encostar nele

    O teto existe para o M1 não virar dano infinito por repetição, e é a mesma
    razão do teto de aquecimento da `Forja`, no conjunto CRIAÇÃO.

    A contagem mora num `Attribute` do `Humanoid` do alvo, com prazo — marca
    de entidade em campo, a mesma natureza da tag `creator`.

════════════════════════════════════════════════════════════════════════
GRUPO DE VARIAÇÃO DE SFX
════════════════════════════════════════════════════════════════════════

    Fogo é o som que mais cansa por repetição: um chiado igual vinte vezes por
    minuto vira ruído branco. Os papéis com mais de uma gravação viram
    `Folder`, e `tocar()` sorteia com peso.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Poder_de_Fogo",
                     "Fogo_7_Tools.rbxmx")

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Wood": 512, "Fabric": 1280, "Glass": 1568, "Grass": 1280,
            "Slate": 800, "Concrete": 816, "Brick": 848,
            "DiamondPlate": 1072, "CorrodedMetal": 1104}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

COM_CUTSCENE = ()


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
    "Brasa": {
        "GOLPE": [("511340819", 3, 4, 1.15, "Smack — Reality_Tools"),
                  ("3015952873", 2, 4, 1.25, "swoosh — VFX_Library_V2")],
        "ESTOURO": [("698224146", 1, 4, 1.1, "burn — VFX_Library_V2")],
    },
    "Lanca Chamas": {
        "JATO": [("698224146", 3, 4, 0.9, "burn — VFX_Library_V2"),
                 ("9126231485", 2, 4, 1.0, "whoosh — VFX_Library_V2")],
        "COMBUSTAO": [("1837830314", 1, 5, 0.85, "boom — VFX_Library_V2")],
    },
    "Bola de Fogo": {
        "LANCA": [("9126231485", 3, 4, 1.05, "whoosh — VFX_Library_V2"),
                  ("1489705211", 2, 4, 0.95, "Swoosh — Guest_Tools"),
                  ("3015952873", 1, 4, 1.15, "swoosh — VFX_Library_V2")],
        "ESTILHACO": [("6741488567", 1, 5, 0.9, "expl — VFX_Library_V2")],
    },
    "Muralha de Fogo": {
        "RISCO": [("698224146", 2, 4, 1.2, "burn — VFX_Library_V2"),
                  ("3015952873", 1, 4, 1.1, "swoosh — VFX_Library_V2")],
        "MURALHA": [("165969964", 1, 5, 0.8, "Explosion — VFX_Library_V2")],
    },
    "Meteoro": {
        "PEDRA": [("933780081", 2, 4, 0.85, "MetalHit — Guest_Tools"),
                  ("743886825", 2, 4, 0.9, "Hit — Reality_Tools")],
        "QUEDA": [("9125402735", 1, 6, 0.75, "DuperBoom — VFX_Library_V2")],
    },
    "Fenix": {
        "ASA": [("1489705211", 3, 4, 1.1, "Swoosh — Guest_Tools"),
                ("5651577252", 1, 4, 1.3, "glint — VFX_Library_V2")],
        "RENASCER": [("1846396833", 1, 5, 0.9, "Summon — VFX_Library_V2")],
    },
    "Inferno": {
        "CHICOTE": [("698224146", 2, 4, 0.95, "burn — VFX_Library_V2"),
                    ("165969964", 2, 4, 1.2, "Explosion — VFX_Library_V2"),
                    ("163064102", 1, 4, 1.1, "Explosion — VFX_Library_V2")],
        "INFERNO": [("18872474050", 1, 6, 0.7, "Supernova — Sword_of_Cosmic")],
    },
}


# ═══════════════════════════════════════════════════════════════
# OS HANDLES — (nome, tamanho, forma, cor, material, deslocamento)
#
# A gramática do conjunto: TODO Handle tem DOIS PÓLOS visíveis, e eles são
# vermelho e azul. É a convenção universal de ímã, e é o que faz o jogador
# saber o que a Tool faz antes de apertar qualquer coisa.
# ═══════════════════════════════════════════════════════════════

BRASA = cor(255, 128, 40)
CHAMA = cor(255, 186, 66)
NUCLEO = cor(255, 240, 190)
CARVAO = cor(48, 40, 40)
FERRO = cor(108, 114, 124)
LATAO = cor(198, 162, 92)
PEDRA = cor(122, 96, 84)
CINZA = cor(96, 92, 92)
AZUL_Q = cor(120, 190, 255)

HANDLES = {
    # o punho com a brasa presa: o mais simples do conjunto, e o M1 do jogo
    "Brasa": [
        ("Handle", (0.5, 1.9, 0.5), "Block", CARVAO, "Wood", (0, 0, 0)),
        ("Garra", (0.9, 0.7, 0.9), "Block", FERRO, "Metal", (0, 1.5, 0)),
        ("Nucleo", (0.9, 0.9, 0.9), "Ball", BRASA, "Neon", (0, 1.9, 0)),
    ],
    # o bico do lança-chamas, com o tanque atrás
    "Lanca Chamas": [
        ("Handle", (0.5, 1.6, 0.5), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Cano", (0.5, 0.5, 3.2), "Block", FERRO, "DiamondPlate", (0, 1.3, -1.0)),
        ("Bico", (0.8, 0.8, 0.6), "Cylinder", LATAO, "Metal", (0, 1.3, -2.5)),
        ("Piloto", (0.4, 0.4, 0.4), "Ball", CHAMA, "Neon", (0, 1.3, -2.8)),
        ("Tanque", (1.1, 1.6, 1.1), "Cylinder", CARVAO, "Metal", (0, 1.2, 1.0)),
    ],
    # a esfera entre dois arcos: ela é a bola antes de sair
    "Bola de Fogo": [
        ("Handle", (0.5, 1.8, 0.5), "Block", LATAO, "Metal", (0, 0, 0)),
        ("Bola", (1.8, 1.8, 1.8), "Ball", BRASA, "Neon", (0, 2.2, 0)),
        ("ArcoA", (2.4, 0.16, 2.4), "Cylinder", FERRO, "Metal", (0, 2.2, 0)),
        ("ArcoB", (0.16, 2.4, 2.4), "Cylinder", FERRO, "Metal", (0, 2.2, 0)),
    ],
    # o archote de assentar: cabo longo, cabeça larga
    "Muralha de Fogo": [
        ("Handle", (0.46, 2.6, 0.46), "Block", CARVAO, "Wood", (0, 0, 0)),
        ("Cabeca", (1.2, 0.9, 1.2), "Cylinder", FERRO, "CorrodedMetal",
         (0, 2.2, 0)),
        ("Labareda", (1.0, 1.4, 1.0), "Ball", CHAMA, "Neon", (0, 2.9, 0)),
        ("Braseiro", (1.6, 0.2, 1.6), "Cylinder", CARVAO, "Slate", (0, 1.9, 0)),
    ],
    # a rocha suspensa no anel: o meteoro em miniatura
    "Meteoro": [
        ("Handle", (0.55, 1.8, 0.55), "Block", FERRO, "Metal", (0, 0, 0)),
        ("Rocha", (2.0, 1.8, 2.0), "Block", PEDRA, "Slate", (0, 2.5, 0)),
        ("Casca", (2.2, 2.0, 2.2), "Ball", BRASA, "Neon", (0, 2.5, 0)),
        ("Anel", (3.0, 0.18, 3.0), "Cylinder", FERRO, "Metal", (0, 2.5, 0)),
    ],
    # a asa: duas penas de fogo abertas
    "Fenix": [
        ("Handle", (0.45, 1.9, 0.45), "Block", LATAO, "Metal", (0, 0, 0)),
        ("PenaA", (2.6, 0.16, 1.0), "Block", CHAMA, "Neon", (0.9, 2.4, 0)),
        ("PenaB", (2.6, 0.16, 1.0), "Block", BRASA, "Neon", (-0.9, 2.4, 0)),
        ("Peito", (1.0, 1.0, 1.0), "Ball", NUCLEO, "Neon", (0, 2.4, 0)),
    ],
    # a ultimate: o núcleo AZUL na jaula de carvão — fogo quente é azul, e é
    # a única peça do conjunto que não é laranja
    "Inferno": [
        ("Handle", (0.55, 1.9, 0.55), "Block", CARVAO, "Metal", (0, 0, 0)),
        ("Jaula", (2.2, 2.2, 2.2), "Ball", CARVAO, "Slate", (0, 2.6, 0)),
        ("Nucleo", (1.6, 1.6, 1.6), "Ball", AZUL_Q, "Neon", (0, 2.6, 0)),
        ("AnelA", (3.0, 0.16, 3.0), "Cylinder", CINZA, "Metal", (0, 2.6, 0)),
        ("AnelB", (0.16, 3.0, 3.0), "Cylinder", CINZA, "Metal", (0, 2.6, 0)),
    ],
}


# ═══════════════════════════════════════════════════════════════
# (nome, ToolTip, arquetipo, recarga M1, recarga R, recarga T, chave)
# ═══════════════════════════════════════════════════════════════

CONJUNTO = [
    ("Brasa",
     "Soco em brasa que acumula queimadura. R solta a brasa acumulada num "
     "estouro curto.",
     "MELEE", 0.7, 9, "Fogo_Brasa"),

    ("Lanca Chamas",
     "O jato continuo que queima o cone a frente. R e a combustao: tudo que "
     "esta queimando estoura junto.",
     "ARCANO", 1.0, 14, "Fogo_LancaChamas"),

    ("Bola de Fogo",
     "Arremessa a bola, que voa em arco e quica. R divide em estilhacos.",
     "EXPLOSIVO", 0.9, 12, "Fogo_Bola"),

    ("Muralha de Fogo",
     "Risca o chao e acende a linha. R levanta a muralha que bloqueia.",
     "ARCANO", 0.9, 16, "Fogo_Muralha"),

    ("Meteoro",
     "Atira a pedra em brasa. R chama o meteoro do ceu, com marca no chao.",
     "EXPLOSIVO", 1.0, 20, "Fogo_Meteoro"),

    ("Fenix",
     "Corte de asa que queima. R e o renascer: voce sobe em chamas e cura o "
     "que a queimadura tirou.",
     "ASTRAL", 0.8, 22, "Fogo_Fenix"),

    ("Inferno",
     "Chicote de fogo azul. R abre o inferno: o campo que queima e espalha.",
     "EXPLOSIVO", 0.9, 26, "Fogo_Inferno"),
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
    item, props = novo_item(pai, "Part", nome, "RV_FP_%s_%s" % (marca, nome))
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
                            "RV_FW_%s_%d" % (marca, indice))
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "C0"})
    for eixo, valor in zip("XYZ", deslocamento):
        ET.SubElement(cf, eixo).text = "%.4g" % valor
    for campo, valor in (("R00", 1), ("R01", 0), ("R02", 0),
                         ("R10", 0), ("R11", 1), ("R12", 0),
                         ("R20", 0), ("R21", 0), ("R22", 1)):
        ET.SubElement(cf, campo).text = str(valor)
    ET.SubElement(props, "Ref", {"name": "Part0"}).text = "RV_FP_%s_Handle" % marca
    ET.SubElement(props, "Ref", {"name": "Part1"}).text = "RV_FP_%s_%s" % (marca, alvo_nome)
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
    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_FSFX_%s" % marca)
    grupos = 0
    for papel, gravacoes in SONS[nome].items():
        base = "RV_FS_%s_%s" % (marca, papel)
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
    nome, tooltip, arquetipo, rec_m1, _r, chave = dados
    marca = chave.replace("Fogo_", "")
    tool, props = novo_item(raiz, "Tool", nome, "RV_FT_%s" % marca)
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
    moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_FMOLD_%s" % marca)
    _lim, lp = novo_item(moldes, "Part", "Fagulha",
                         "RV_FLIM_%s" % marca)
    vetor(lp, "Vector3", "size", (0.14, 0.14, 0.14))
    cor3(lp, "Color3uint8", BRASA)
    ET.SubElement(lp, "token", {"name": "formFactorRaw"}).text = "1"
    ET.SubElement(lp, "token", {"name": "shape"}).text = "1"
    ET.SubElement(lp, "token", {"name": "Material"}).text = str(MATERIAL["Neon"])
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
        _i, vp = novo_item(tool, classe, alvo, "RV_FV_%s_%s" % (marca, alvo[:7]))
        ET.SubElement(vp, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_FVFX_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_FACAO_%s" % marca)

    scripts = [("Script", "%s_Server_V1" % nome.replace(" ", "")),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule"),
               ("ModuleScript", "DepositoVFX")]

    if nome in COM_CUTSCENE:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_FCUT_%s" % marca)
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        _i, sp = novo_item(tool, classe, alvo,
                           "RV_FSC_%s_%s" % (marca, alvo[:10]))
        ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
        if classe == "Script" and alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript: LocalScript dentro de
            # Tool só roda para quem a segura.
            ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"
    return tool, grupos


def main():
    raiz = nova_raiz()
    print("BASE DO CONJUNTO PODER DE FOGO")
    print("")
    print("  %-20s %-10s %s" % ("TOOL", "ARQUETIPO", "peças · SFX · recargas"))

    total_grupos, total_sons = 0, 0
    for dados in CONJUNTO:
        _tool, grupos = montar_tool(raiz, dados)
        nome, _t, arq, m1, r, _c = dados
        n_som = sum(len(g) for g in SONS[nome].values())
        total_grupos = total_grupos + grupos
        total_sons = total_sons + n_som
        cena = " · CENA" if nome in COM_CUTSCENE else ""
        print("  %-20s %-10s %d peça(s) · %d som(ns) em %d grupo(s) · "
              "M1 %.1fs / R %ds%s"
              % (nome, arq, len(HANDLES[nome]), n_som, grupos, m1, r, cena))

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
