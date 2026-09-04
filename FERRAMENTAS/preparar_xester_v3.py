#!/usr/bin/env python3
"""
preparar_xester_v3.py — Retro-Verse / Studios

Monta a base de assets das **13 Tools** do Xester: 7 na Forma 1, 6 na Forma 2.

    python3 FERRAMENTAS/preparar_xester_v3.py

A DISTRIBUIÇÃO, PELA REGRA

    Forma 1 tem OITO habilidades (Q E R T Y U P F). A regra manda: 8 ou mais
    → 7 Tools, e o excedente vira habilidade **Extra** na Tool de tema mais
    próximo. `The Final Deal` é o grande final da Forma 1, e vai como Extra em
    `Xester Eclipse Deck`, que é a outra habilidade de clímax dela.

    Forma 2 tem SEIS (G H J K L F). De 3 a 7 → uma Tool por habilidade. Seis
    Tools, seis habilidades, nenhum agrupamento.

    13 Tools, 13 habilidades, dois arquivos de entrega.

A TROCA DE FORMA, SEM UMA TOOL ALCANÇAR A OUTRA

    `F` transforma. Se a Tool que transforma tivesse de PROCURAR a Tool da
    outra forma, seria referência para fora — Regra nº 1, que vence tudo.

    Ela não procura. O que `F` faz é escrever um **Attribute no Character**:
    `XesterForma = 2`. Quem lê é quem quiser, sob guarda, com padrão. É a mesma
    categoria do estado opcional compartilhado: não é caminho de
    instância, não depósito de asset.

    O teste que decide continua passando: arraste QUALQUER uma das 13 sozinha
    para um place vazio e ela funciona por inteiro. Sem as outras doze, o
    atributo simplesmente não existe, a Tool o cria com o padrão dela, e a
    habilidade sai igual.

    O mesmo vale para a passiva: `XesterUsos` e `XesterCoringa` contam as três
    habilidades da Forma 1 atravessando as sete Tools. Sozinha, uma Tool conta
    as próprias e a Carta Coringa nasce do mesmo jeito.

O MOLDE ENTRA MAGRO

    A versão anterior carregava as subárvores `cards`, `staff`, `energb` e
    `Effects` inteiras — 76 instâncias e 430 KB por Tool. O `VFXModule` procura
    os moldes POR NOME, e os nomes que ele procura são treze:
    `Carta1..4`, os quatro `As*`, `Mascara`, `Anel`, `Onda`, `Tempestade`,
    `Orbe` — mais o `Cajado`, que é a única peça grande e vem de `staff/t`.

    Levar a árvore inteira para achar treze peças é peso morto viajando dentro
    de cada Tool.

    Tudo entra APAGADO (`Transparency = 1`, `Enabled = false`). Quem acende é a
    CÓPIA, no momento da habilidade.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import (ENTRADA, MALHAS, RAIZ, TAMANHO_CARTA, TOOLS,
                             achar, apagar, definir, definir_tamanho,
                             novo_item, nova_raiz, parte, podar,
                             renomear_referentes)

#: os quatro Ases — decal por naipe, do próprio modelo
ASES = {
    "AsEspadas": "1880203893",
    "AsPaus": "1881287656",
    "AsOuros": "1881287420",
    "AsCopas": "1881288034",
}

#: o catálogo de sons. Cada Tool leva SÓ os que cita.
CATALOGO = {
    "CORTINA":   ("1898092341", 4, 1.00),
    "VOLTA":     ("1894958339", 5, 1.30),
    "ARSENAL":   ("1882057730", 4, 1.00),
    "NAIPE":     ("1499747506", 3, 1.10),
    "LABIRINTO": ("342337569",  5, 0.90),
    "EMBARALHA": ("1888686669", 4, 0.95),
    "AS":        ("1843578719", 5, 0.95),
    "PORTAO":    ("1894958339", 5, 1.00),
    "CASTELO":   ("236989198",  4, 0.90),
    "DESABA":    ("765590102",  6, 0.85),
    "ECLIPSE":   ("472579737",  6, 0.75),
    "RETORNO":   ("142070127",  6, 0.85),
    "GUARDA":    ("3855293277", 4, 1.00),
    "REI":       ("288641686",  4, 1.00),
    "CORINGA":   ("1072606965", 3, 1.25),
    "WYRM":      ("842332424",  4, 1.15),
    "COROA":     ("1845012046", 3, 1.00),
    "BRASA":     ("1982011510", 5, 0.90),
    "REQUIEM":   ("2014087015", 5, 0.80),
    "PRISMA":    ("1910988873", 5, 1.00),
    "PAGINA":    ("54111471",   5, 0.85),
    "ECO":       ("1040136448", 4, 0.90),
    "NAIPES":    ("1499747506", 4, 0.80),
    "QUEIMA":    ("3292075199", 5, 0.95),
    "RASGA":     ("413682983",  4, 1.10),
    "TITULO":    ("4571960003", 5, 1.00),
    "FECHA":     ("314678645",  4, 0.85),
}

#: A Carta Coringa NASCE só na Forma 1, mas é GASTA por qualquer habilidade:
#: quem acumula três no baralho, transforma e solta o sopro leva o bônus junto.
#: Por isso o som dela viaja nas TREZE, não nas sete.
SONS_PASSIVA = ["CORINGA"]

#: (nome, forma, tooltip, sons, extra, arquetipo, energia, recarga, cutscene)
#:
#: `extra` é o rótulo da habilidade Extra, ou None. `cutscene` diz se a Tool
#: leva o `CutsceneCam.lua` — só as duas que transformam levam.
CONJUNTO = [
    # ── FORMA 1 — Mestre do Baralho ───────────────────────────────────
    ("Xester Curtain Call", 1,
     "Desfaz-se em cartas, deixa uma copia e reaparece atras do alvo.",
     ["CORTINA", "VOLTA"], None, "ESPECTRAL", 22, 14, False),

    ("Xester Four Suits Arsenal", 1,
     "Oito cartas orbitando. Clique de novo dispara o naipe da vez.",
     ["ARSENAL", "NAIPE"], None, "ARCANO", 26, 16, False),

    ("Xester Jokers Labyrinth", 1,
     "Cartas gigantes cercam, embaralham os inimigos e fecham no centro.",
     ["LABIRINTO", "EMBARALHA"], None, "ARCANO", 34, 24, False),

    ("Xester Ace Gate", 1,
     "Crava um As. Clique de novo teleporta ate ele.",
     ["AS", "PORTAO"], None, "ESPECTRAL", 18, 10, False),

    ("Xester House Collapse", 1,
     "Ergue um castelo de cartas. Clique de novo derruba na direcao do mouse.",
     ["CASTELO", "DESABA"], None, "EXPLOSIVO", 30, 20, False),

    ("Xester Eclipse Deck", 1,
     "Carta negra no ceu que marca e traz todos de volta ao centro.",
     ["ECLIPSE", "RETORNO", "NAIPES", "QUEIMA", "RASGA", "TITULO"],
     "The Final Deal", "ARCANO", 40, 34, True),

    ("Xester Royal Guard", 1,
     "Quatro Reis de guarda. Clique lanca um; a tecla R baixa os quatro.",
     ["GUARDA", "REI"], "Baque dos Reis", "SUPORTE", 28, 18, False),

    # ── FORMA 2 — Heavenbreaker ───────────────────────────────────────
    ("Xester Wyrm Sparks", 2,
     "Tres cabecas de dragao de fogo que perseguem e marcam o chao.",
     ["WYRM"], None, "CEIFA", 20, 8, False),

    ("Xester Crown of Cinders", 2,
     "Um sol de Coringa. Clique de novo estilhaca em brasas na area mirada.",
     ["COROA", "BRASA"], None, "EXPLOSIVO", 36, 26, False),

    ("Xester Dragons Requiem", 2,
     "Segure para carregar o dragao espectral; solte para o sopro curvado.",
     ["REQUIEM"], None, "CEIFA", 34, 22, False),

    ("Xester Prism", 2,
     "Tres mascaras disparam feixes que se cruzam e seguem o mouse.",
     ["PRISMA"], None, "ARCANO", 30, 20, False),

    ("Xester Final Page", 2,
     "Para o tempo na area. Tres cliques marcam, e o dragao celeste atravessa.",
     ["PAGINA", "ECO"], None, "CEIFA", 48, 70, True),

    ("Xester Curtain Reversal", 2,
     "A cutscene de volta: o dragao e absorvido e Xester fecha o baralho.",
     ["FECHA", "NAIPES", "RASGA"], None, "SUPORTE", 20, 30, True),
]

#: os scripts autorais. O `Source` vem do `.lua`; aqui nascem vazios.
SCRIPTS_BASE = [
    ("Script", "Client", "2"),
    ("ModuleScript", "Poses", None),
    ("ModuleScript", "R6CFrameAnimator", None),
    ("ModuleScript", "VFXModule", None),
]


def marca_de(nome):
    return nome.replace(" ", "")


def cartas_do_modelo(fonte):
    baralho = achar(fonte, "cards")
    if baralho is None:
        return []
    saida = []
    for alvo in ("card1", "card2", "card3", "card4"):
        peca = achar(baralho, alvo)
        if peca is not None:
            saida.append(peca)
    return saida


def handle(tool, fonte, marca):
    """A carta do próprio Xester, na escala de jogo do `cardtable`."""
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


def moldes(tool, fonte, marca):
    """Os TREZE nomes que o `VFXModule` procura, mais o Cajado.

    Nada de subárvore inteira: o módulo busca por nome, e nome é o que se
    entrega. `apagar` deixa tudo invisível — quem acende é a cópia.
    """
    pasta, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % marca)
    contagem = 0

    for indice, peca in enumerate(cartas_do_modelo(fonte)):
        copia = ET.fromstring(ET.tostring(peca))
        podar(copia, [])
        definir(copia, "string", "Name", "Carta%d" % (indice + 1))
        definir_tamanho(copia, TAMANHO_CARTA)
        apagar(copia)
        renomear_referentes(copia, "RV_CT%d_%s_" % (indice + 1, marca))
        pasta.append(copia)
        contagem = contagem + 1

    for nome, decal in ASES.items():
        base = parte(pasta, nome, "RV_A%s_%s" % (nome[2:5], marca),
                     TAMANHO_CARTA, cor="White")
        _d, dp = novo_item(base, "Decal", "Naipe",
                           "RV_D%s_%s" % (nome[2:5], marca))
        ET.SubElement(dp, "Content", {"name": "Texture"}).append(
            ET.Element("url"))
        dp[-1][0].text = "rbxassetid://%s" % decal
        ET.SubElement(dp, "float", {"name": "Transparency"}).text = "1"
        ET.SubElement(dp, "token", {"name": "Face"}).text = "1"
        contagem = contagem + 1

    for nome, (malha, textura) in MALHAS.items():
        base = parte(pasta, nome, "RV_M%s_%s" % (nome[:3], marca), (1, 1, 1),
                     cor="White")
        _m, mp = novo_item(base, "SpecialMesh", "Mesh",
                           "RV_MM%s_%s" % (nome[:3], marca))
        ET.SubElement(mp, "token", {"name": "MeshType"}).text = "5"
        ET.SubElement(mp, "Content", {"name": "MeshId"}).append(
            ET.Element("url"))
        mp[-1][0].text = "rbxassetid://%s" % malha
        if textura:
            ET.SubElement(mp, "Content", {"name": "TextureId"}).append(
                ET.Element("url"))
            mp[-1][0].text = "rbxassetid://%s" % textura
        contagem = contagem + 1

    orbe = parte(pasta, "Orbe", "RV_MOR_%s" % marca, (2, 2, 2), cor="White")
    ET.SubElement(orbe.find("Properties"), "token", {"name": "shape"}).text = "0"
    contagem = contagem + 1

    # O CAJADO: a peça que diz em qual forma o Xester está. Ele é soldado ao
    # braço e mora no CHARACTER, não na Tool — por isso sobrevive à troca de
    # Tool na mochila, e morre com o respawn sem ninguém precisar limpá-lo.
    staff = achar(fonte, "staff")
    haste = achar(staff, "t") if staff is not None else None
    if haste is not None:
        copia = ET.fromstring(ET.tostring(haste))
        podar(copia, [])
        definir(copia, "string", "Name", "Cajado")
        definir(copia, "bool", "CanCollide", "false")
        definir(copia, "bool", "Anchored", "false")
        definir(copia, "float", "Transparency", "1")
        renomear_referentes(copia, "RV_CJ_%s_" % marca)
        pasta.append(copia)
        contagem = contagem + 1

    return contagem


def sfx(tool, marca, rotulos):
    pasta, _ = novo_item(tool, "Folder", "SFX", "RV_SFX_%s" % marca)
    for rotulo in rotulos:
        ident, volume, pitch = CATALOGO[rotulo]
        _s, props = novo_item(pasta, "Sound", rotulo,
                              "RV_SN%s_%s" % (rotulo, marca))
        ET.SubElement(props, "Content", {"name": "SoundId"}).append(
            ET.Element("url"))
        props[-1][0].text = "rbxassetid://%s" % ident
        ET.SubElement(props, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(props, "float",
                      {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(props, "float",
                      {"name": "RollOffMaxDistance"}).text = "260"
    return len(rotulos)


def equipar(tool, dados):
    nome, forma, tooltip, _sons, extra, arquetipo, energia, recarga, cena = dados
    marca = marca_de(nome)

    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # `VFXRemote` leva o desenho para TODO cliente e traz o clique do dono.
    # `AcaoRemote` só existe onde há Extra — RemoteEvent que ninguém usa é
    # porta a mais para validar.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFX_%s" % marca)
    if extra:
        novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_ACA_%s" % marca)
    if cena:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_CUT_%s" % marca)

    # As duas que transformam DIVIDEM a recarga: `ChaveRecarga` igual impede o
    # jogador de trocar de Tool na mochila para burlar a espera da virada.
    chave = ("Xester_TrocaDeForma" if cena
             else "Xester_%s" % marca.replace("Xester", ""))
    valores = [
        ("StringValue", "string", "DamageClass", arquetipo),
        ("StringValue", "string", "ChaveRecarga", chave),
        ("NumberValue", "float", "EnergyCost", str(energia)),
        ("NumberValue", "float", "RecargaGlobal", str(recarga)),
    ]
    for classe, tag, alvo, valor in valores:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:6], marca))
        ET.SubElement(props, tag, {"name": "Value"}).text = valor

    scripts = [("Script", "%s_Server_V1" % marca, None)] + list(SCRIPTS_BASE)
    if cena:
        scripts.append(("Script", "CutsceneCam", "2"))
    for classe, alvo, runcontext in scripts:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:14], marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""
        if runcontext:
            # RunContext = Client (2), NÃO LocalScript. LocalScript dentro de
            # Tool só roda para quem a segura, e o VFX apareceria só para o
            # portador.
            ET.SubElement(props, "token",
                          {"name": "RunContext"}).text = runcontext


def main():
    origem = os.path.join(ENTRADA, "Xester_Forma2_O_Despertar.rbxmx")
    if not os.path.exists(origem):
        print("origem não encontrada: %s" % origem)
        return 1
    fonte = ET.parse(origem).getroot()

    compartilhadas = {}
    for e in fonte.iter("SharedString"):
        if e.get("md5"):
            compartilhadas[e.get("md5")] = e.text or ""

    print("PREPARAÇÃO DA BASE — Xester, 7 Tools + 6 Tools")
    print("")

    total_sons = 0
    for dados in CONJUNTO:
        nome, forma, _tt, sons, extra, _arq, _en, _rec, cena = dados
        marca = marca_de(nome)

        tool = ET.Element("Item", {"class": "Tool",
                                   "referent": "RV_T_%s" % marca})
        ET.SubElement(tool, "Properties")
        equipar(tool, dados)

        if handle(tool, fonte, marca) is None:
            print("  PAREI: não achei `cards/card1` na origem para o Handle")
            return 1
        n_moldes = moldes(tool, fonte, marca)

        lista = list(sons)
        for extra_som in SONS_PASSIVA:
            if extra_som not in lista:
                lista.append(extra_som)
        n_sons = sfx(tool, marca, lista)
        total_sons = total_sons + n_sons

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)
        raiz = nova_raiz()
        raiz.append(tool)

        # A tabela de SharedStrings é IRMÃ do <Item>, não descendente. Sair sem
        # ela deixa md5 pendurado, e o Studio responde "arquivo corrompido".
        citadas = sorted({(e.text or "").strip()
                          for e in raiz.iter("SharedString") if e.get("name")})
        citadas = [c for c in citadas if c]
        if citadas:
            bloco = ET.SubElement(raiz, "SharedStrings")
            for md5 in citadas:
                if md5 not in compartilhadas:
                    print("  PAREI: md5 %s citado e ausente da origem" % md5)
                    return 1
                ET.SubElement(bloco, "SharedString",
                              {"md5": md5}).text = compartilhadas[md5]

        destino = os.path.join(pasta, "_ORIGEM.rbxmx")
        ET.ElementTree(raiz).write(destino, encoding="utf-8",
                                   xml_declaration=False)
        print("  %-28s F%d  %2d molde(s) · %2d som(ns) · %s%s"
              % (nome, forma, n_moldes, n_sons,
                 "Extra: %s" % extra if extra else "só M1",
                 " · cutscene" if cena else ""))

    print("")
    print("13 Tool(s) preparada(s) — 7 na Forma 1, 6 na Forma 2.")
    print("%d Sound no total, nenhum id inventado." % total_sons)
    print("Nenhum script da origem entrou.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
