#!/usr/bin/env python3
"""
preparar_xester_v2.py — Retro-Verse / Studios

Monta a base de assets da Tool **Xester** — UMA Tool, DUAS formas.

    python3 FERRAMENTAS/preparar_xester_v2.py

POR QUE UMA TOOL SÓ, E NÃO SETE

    O desenho novo tem `F` trocando de forma: `The Final Deal` leva da Forma 1
    para a Forma 2, e `Curtain Reversal` traz de volta. Com duas Tools, uma
    teria de ALCANÇAR a outra — procurá-la na mochila, no `ReplicatedStorage`,
    em algum depósito. Isso é exatamente o que a Regra nº 1 proíbe, e ela vence
    a regra de distribuição na ordem de precedência do `CLAUDE.md`
    (autocontenção é 1, distribuição é 3).

    Então a forma é ESTADO, dentro da Tool. Nada sai, nada é procurado, e o
    teste do place vazio continua passando: arraste `Xester` sozinho e as duas
    formas funcionam, com as três cutscenes.

    São 13 habilidades — abaixo do teto real da regra de distribuição
    (7 Tools × 2 = 14). O que mudou foi o empacotamento, não a quantidade.

DE ONDE VEM CADA COISA

    Handle           `cards/card1` da Forma 2, no tamanho do `cardtable` da
                     Forma 1 — a carta do próprio Xester
    Cajado           `staff/t`, soldado ao braço quando a Forma 2 entra
    Moldes           `cards`, `staff`, `energb` e `Effects` da origem
    Ás / malhas      os mesmos decais e MeshId que as 14 Tools já usavam
    SFX              22 sons, um por habilidade e por beat de cutscene. TODOS
                     os ids já tocam em Tool entregue deste repositório —
                     nenhum inventado, porque id chutado é som mudo que
                     nenhum verificador pega.

    Nenhum script da origem entra. `podar` tira Script, LocalScript,
    ModuleScript, classe proibida e Sound sem disparador.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import (ENTRADA, MALHAS, RAIZ, TAMANHO_CARTA, TOOLS,
                             achar, apagar, definir, definir_tamanho,
                             novo_item, nova_raiz, parte, podar,
                             renomear_referentes, texto)

TOOL = "Xester"
MARCA = "XesterV2"

#: subárvores da origem que entram como molde
SUBARVORES = ("cards", "staff", "energb", "Effects")

#: os quatro Ases — decal por naipe, do próprio modelo
ASES = {
    "AsEspadas": "1880203893",
    "AsPaus": "1881287656",
    "AsOuros": "1881287420",
    "AsCopas": "1881288034",
}

#: `Sound` por MOMENTO em que toca. Todo id já toca em Tool entregue.
SONS = [
    # ── Forma 1, o baralho ────────────────────────────────────────────
    ("CORTINA",   "1898092341", 4, 1.00),   # Q  Curtain Call — o sumiço
    ("VOLTA",     "1894958339", 5, 1.30),   # Q  o reaparecimento
    ("ARSENAL",   "1882057730", 4, 1.00),   # E  as oito cartas nascendo
    ("NAIPE",     "1499747506", 3, 1.10),   # E  cada naipe disparado
    ("LABIRINTO", "342337569",  5, 0.90),   # R  as cartas gigantes subindo
    ("EMBARALHA", "1888686669", 4, 0.95),   # R  a troca de posição
    ("AS",        "1843578719", 5, 0.95),   # T  o Ás cravando
    ("PORTAO",    "1894958339", 5, 1.00),   # T  o teleporte até ele
    ("CASTELO",   "236989198",  4, 0.90),   # Y  o castelo subindo
    ("DESABA",    "765590102",  6, 0.85),   # Y  as paredes caindo
    ("ECLIPSE",   "472579737",  6, 0.75),   # U  a carta negra abrindo
    ("RETORNO",   "142070127",  6, 0.85),   # U  as cartas voltando ao centro
    ("GUARDA",    "3855293277", 4, 1.00),   # P  os quatro Reis
    ("REI",       "288641686",  4, 1.00),   # P  o Rei lançado / o baque
    ("CORINGA",   "1072606965", 3, 1.25),   # passiva — a Carta Coringa

    # ── Forma 2, o dragão ─────────────────────────────────────────────
    ("WYRM",      "842332424",  4, 1.15),   # G  as três cabeças de fogo
    ("COROA",     "1845012046", 3, 1.00),   # H  o sol de Coringa
    ("BRASA",     "1982011510", 5, 0.90),   # H  os fragmentos caindo
    ("REQUIEM",   "2014087015", 5, 0.80),   # J  o sopro curvado
    ("PRISMA",    "1910988873", 5, 1.00),   # K  os feixes cruzando
    ("PAGINA",    "54111471",   5, 0.85),   # L  a página final
    ("ECO",       "1040136448", 4, 0.90),   # L  o eco do dragão celeste

    # ── Cutscene ──────────────────────────────────────────────────────
    ("NAIPES",    "1499747506", 4, 0.80),   # os quatro naipes na carta
    ("QUEIMA",    "3292075199", 5, 0.95),   # o Coringa pegando fogo
    ("RASGA",     "413682983",  4, 1.10),   # Xester rasgando a carta
    ("TITULO",    "4571960003", 5, 1.00),   # o estouro do título
    ("FECHA",     "314678645",  4, 0.85),   # o baralho fechando na volta
]

#: os quatro `Value` de §12.4
VALORES = [
    ("StringValue", "string", "DamageClass", "ARCANO"),
    ("StringValue", "string", "ChaveRecarga", "Xester_FinalDeal"),
    ("NumberValue", "float", "EnergyCost", "34"),
    ("NumberValue", "float", "RecargaGlobal", "30"),
]

#: os scripts autorais. O `Source` vem do `.lua`; aqui nascem vazios.
SCRIPTS = [
    ("Script", "Xester_Server_V1", None),
    ("Script", "Client", "2"),
    ("Script", "CutsceneCam", "2"),
    ("ModuleScript", "Poses", None),
    ("ModuleScript", "R6CFrameAnimator", None),
    ("ModuleScript", "VFXModule", None),
]


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


def handle(tool, fonte):
    """A carta do próprio Xester, na escala de jogo do `cardtable`.

    O Handle NÃO muda com a forma. Ele não pode: `RequiresHandle` exige que a
    peça exista o tempo todo, e trocar a geometria no meio do jogo desmonta o
    `Grip` do `Humanoid`. Quem carrega a forma é o CAJADO — uma peça à parte,
    soldada ao braço quando a Forma 2 entra e solta quando ela sai.
    """
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
    renomear_referentes(copia, "RV_HD_%s_" % MARCA)
    copia.set("referent", "RV_HDL_%s" % MARCA)
    tool.append(copia)
    return copia


def moldes(tool, fonte):
    """`Moldes/` — tudo APAGADO, e aceso só na execução da habilidade.

    A regra do usuário: *"deixar os vfx invisivel dentro da tool, e visivel na
    execução da habilidade"*. `apagar` põe `Transparency = 1` e
    `Enabled = false` em tudo; o `VFXModule` acende a CÓPIA, nunca o molde.
    """
    pasta, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % MARCA)
    apagados, trazidos = 0, []

    # as subárvores inteiras da origem
    for alvo in SUBARVORES:
        origem = achar(fonte, alvo)
        if origem is None:
            continue
        copia = ET.fromstring(ET.tostring(origem))
        podar(copia, [])
        apagados = apagados + apagar(copia)
        renomear_referentes(copia, "RV_%s_%s_" % (alvo[:3], MARCA))
        pasta.append(copia)
        trazidos.append(alvo)

    # as quatro cartas soltas, no tamanho de jogo, para o VFX clonar
    baralho = cartas_do_modelo(fonte)
    for indice, peca in enumerate(baralho):
        copia = ET.fromstring(ET.tostring(peca))
        podar(copia, [])
        definir(copia, "string", "Name", "Carta%d" % (indice + 1))
        definir_tamanho(copia, TAMANHO_CARTA)
        apagar(copia)
        renomear_referentes(copia, "RV_CT%d_%s_" % (indice + 1, MARCA))
        pasta.append(copia)

    # os quatro Ases: carta com o decal do naipe
    for nome, decal in ASES.items():
        base = parte(pasta, nome, "RV_A%s_%s" % (nome[2:5], MARCA),
                     TAMANHO_CARTA, cor="White")
        _d, dp = novo_item(base, "Decal", "Naipe",
                           "RV_D%s_%s" % (nome[2:5], MARCA))
        ET.SubElement(dp, "Content", {"name": "Texture"}).append(
            ET.Element("url"))
        dp[-1][0].text = "rbxassetid://%s" % decal
        ET.SubElement(dp, "float", {"name": "Transparency"}).text = "1"
        ET.SubElement(dp, "token", {"name": "Face"}).text = "1"

    # as malhas de efeito — onda, anel, tempestade, máscara
    for nome, (malha, textura) in MALHAS.items():
        base = parte(pasta, nome, "RV_M%s_%s" % (nome[:3], MARCA), (1, 1, 1),
                     cor="White")
        _m, mp = novo_item(base, "SpecialMesh", "Mesh",
                           "RV_MM%s_%s" % (nome[:3], MARCA))
        ET.SubElement(mp, "token", {"name": "MeshType"}).text = "5"
        ET.SubElement(mp, "Content", {"name": "MeshId"}).append(
            ET.Element("url"))
        mp[-1][0].text = "rbxassetid://%s" % malha
        if textura:
            ET.SubElement(mp, "Content", {"name": "TextureId"}).append(
                ET.Element("url"))
            mp[-1][0].text = "rbxassetid://%s" % textura

    # o orbe, bola Neon — sol da Coroa, núcleo do Requiem, nó do Prisma
    orbe = parte(pasta, "Orbe", "RV_MOR_%s" % MARCA, (2, 2, 2), cor="White")
    ET.SubElement(orbe.find("Properties"), "token", {"name": "shape"}).text = "0"

    # o CAJADO da Forma 2, solto: é ele que troca de forma, não o Handle
    staff = achar(fonte, "staff")
    haste = achar(staff, "t") if staff is not None else None
    if haste is not None:
        copia = ET.fromstring(ET.tostring(haste))
        podar(copia, [])
        definir(copia, "string", "Name", "Cajado")
        definir(copia, "bool", "CanCollide", "false")
        definir(copia, "bool", "Anchored", "false")
        definir(copia, "float", "Transparency", "1")
        renomear_referentes(copia, "RV_CJ_%s_" % MARCA)
        pasta.append(copia)
        trazidos.append("staff/t -> Cajado")

    return apagados, trazidos, len(baralho) + len(ASES) + len(MALHAS) + 1


def sfx(tool):
    pasta, _ = novo_item(tool, "Folder", "SFX", "RV_SFX_%s" % MARCA)
    for rotulo, ident, volume, pitch in SONS:
        _s, props = novo_item(pasta, "Sound", rotulo,
                              "RV_SN%s_%s" % (rotulo, MARCA))
        ET.SubElement(props, "Content", {"name": "SoundId"}).append(
            ET.Element("url"))
        props[-1][0].text = "rbxassetid://%s" % ident
        ET.SubElement(props, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(props, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(props, "float",
                      {"name": "RollOffMaxDistance"}).text = "260"
    return len(SONS)


def equipar(tool):
    definir(tool, "string", "Name", TOOL)
    definir(tool, "string", "ToolTip",
            "Mestre do Baralho. F transforma em Heavenbreaker.")
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # TRÊS remotes, e cada um com um assunto:
    #   VFXRemote     desenho para TODO cliente, mais o clique do dono
    #   AcaoRemote    a tecla, com o NOME dela no payload
    #   CutsceneRemote  o beat da câmera, só para o DONO — o usuário pediu
    #                 explicitamente que a cutscene não seja forçada nos outros
    for alvo, sufixo in (("VFXRemote", "VFX"), ("AcaoRemote", "ACA"),
                         ("CutsceneRemote", "CUT")):
        novo_item(tool, "RemoteEvent", alvo, "RV_%s_%s" % (sufixo, MARCA))

    for classe, tag, alvo, valor in VALORES:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:6], MARCA))
        ET.SubElement(props, tag, {"name": "Value"}).text = valor

    for classe, alvo, runcontext in SCRIPTS:
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo[:14], MARCA))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""
        if runcontext:
            # RunContext = Client (2), NÃO LocalScript. LocalScript dentro de
            # Tool só roda para quem a segura, e o VFX apareceria só para o
            # portador. A cutscene usa o mesmo script e se limita ao dono pelo
            # `FireClient`, não pelo tipo de script.
            ET.SubElement(props, "token", {"name": "RunContext"}).text = runcontext


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

    print("PREPARAÇÃO DA BASE — Xester, UMA Tool e DUAS formas")
    print("")

    tool = ET.Element("Item", {"class": "Tool", "referent": "RV_T_%s" % MARCA})
    ET.SubElement(tool, "Properties")
    equipar(tool)

    if handle(tool, fonte) is None:
        print("  PAREI: não achei `cards/card1` na origem para o Handle")
        return 1
    apagados, trazidos, autorais = moldes(tool, fonte)
    n_sons = sfx(tool)

    pasta = os.path.join(TOOLS, TOOL)
    os.makedirs(pasta, exist_ok=True)
    raiz = nova_raiz()
    raiz.append(tool)

    # A tabela de SharedStrings é IRMÃ do <Item>, não descendente. Sair sem ela
    # deixa md5 pendurado, e o Studio responde "arquivo corrompido" sem dizer
    # por quê. Já aconteceu duas vezes neste repositório.
    citadas = sorted({(e.text or "").strip() for e in raiz.iter("SharedString")
                      if e.get("name")})
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

    pecas = sum(1 for _ in raiz.iter("Item"))
    print("  Handle      cards/card1, no tamanho do cardtable")
    print("  Moldes      %s" % ", ".join(trazidos))
    print("              + %d moldes montados aqui (cartas, Ases, malhas, orbe)"
          % autorais)
    print("              %d instância(s) apagada(s) — acende só na execução"
          % apagados)
    print("  SFX         %d som(ns), nenhum id inventado" % n_sons)
    print("  Remotes     VFXRemote, AcaoRemote, CutsceneRemote")
    print("  SharedString %d na tabela, 0 pendurada" % len(citadas))
    print("")
    print("  %s — %d peça(s), %d bytes"
          % (os.path.relpath(destino, RAIZ), pecas,
             os.path.getsize(destino)))
    print("")
    print("1 Tool preparada. Nenhum script da origem entrou.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
