#!/usr/bin/env python3
"""
preparar_submundo.py — Retro-Verse / Studios

Monta a árvore das 6 Tools do conjunto **SUBMUNDO**. É o primeiro conjunto
AUTORAL do repositório: não sai de um modelo, sai do Acervo.

    python3 FERRAMENTAS/preparar_submundo.py

A DIFERENÇA PARA OS CONJUNTOS ANTERIORES

    Escudos, Astral, Bombas e Xester nasceram de um `.rbxmx` de terceiro que foi
    podado e reescrito. Aqui não há modelo de origem: o conceito é do autor do
    projeto, e a matéria-prima é o que os quatro conjuntos anteriores deixaram
    depositado.

    Isso muda o que este script faz. Ele não PODA nada — ele COLHE:

      staff (Xester Forma 2)   → Handle das seis. O conjunto é de conjurador,
                                 e o cajado é o implemento dele.
      skully (Xester Forma 2)  → a caveira que persegue, na T3
      Effects/* (Xester F2)    → ball, spikeball, exploseball, woosh
      Handle (bomba_v4)        → as bombas que a caveira arremessa
      Stella_VFX_Addon         → onda, nova, explosão, corte, anel, rachadura,
                                 feixe e espiral, enxertados na montagem

    Geometria desenhada aqui: **uma peça**, o elo de corrente da T5 — um Part
    com a malha de anel 3270017, repetido para formar a corrente. Não existe
    corrente em asset nenhum do Acervo, e `rbxassetid://` dentro de instância
    filha da Tool é o que a Regra nº 1 permite.

O CONTADOR DA T2 NÃO É GUI

    `BillboardGui` é proibido dentro de Tool (`REGRA_CAMERA_DE_CUTSCENE`, §base:
    "UI é sistema de jogo, não é Tool"). O contador de 20 segundos existe como
    **20 selos em anel sobre a cabeça do alvo**, e um apaga por segundo. Mesma
    leitura, e vive no mundo 3D, que é onde efeito de Tool pode viver.
"""

import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import (CORES, achar, apagar, definir, definir_tamanho,
                             nova_raiz, novo_item, podar, prop,
                             renomear_referentes, texto)

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
XESTER = os.path.join(RAIZ, "MODELOS_ENTRADA", "Xester",
                      "Xester_Forma2_O_Despertar.rbxmx")
BOMBA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Bomba_V4", "bomba_v4.rbxmx")

# malha de anel — vira elo de corrente na T5. Único desenho autoral do conjunto.
MALHA_ANEL = "3270017"

# ═══════════════════════════════════════════════════════════════
# AS SEIS
# ═══════════════════════════════════════════════════════════════
#
# nome, tooltip, sequência, classe de dano, energia, recarga, chave,
# moldes colhidos, precisa de mira na primária

CONJUNTO = [
    ("Pilar das Lamentacoes",
     "Ergue um pilar que grita as almas: dano em area e atordoamento.",
     "ERGUER", "ESPECTRAL", 32, 26, "Submundo_Pilar",
     ["Effects", "spikeball", "energb"], True),

    ("Julgamento Final",
     "Marca um alvo com 20 selos. Se ele nao te matar em 20s, leva 250.",
     "SELAR", "ESPECTRAL", 45, 60, "Submundo_Julgamento",
     ["Effects", "spikeball"], True),

    ("Atraso Mortal",
     "Solta uma caveira lenta que persegue e bombardeia.",
     "SOLTAR", "ESPECTRAL", 30, 34, "Submundo_Atraso",
     ["skully", "Effects"], True),

    ("Perturbacao",
     "Fica incorporeo por 6s, absorve o dano e devolve tudo em area.",
     "DESFAZER", "ESPECTRAL", 26, 30, "Submundo_Perturbacao",
     ["Effects", "woosh"], False),

    ("Portal do Submundo",
     "Abre um portal que prende com correntes quem pisar nele.",
     "ABRIR", "ESPECTRAL", 34, 38, "Submundo_Portal",
     ["Effects", "exploseball"], True),

    ("Olho do Vigia",
     "Cria um olho gigante que revela inimigos atraves das paredes.",
     "APONTAR", "ESPECTRAL", 20, 28, "Submundo_Olho",
     ["Effects", "spikeball"], True),
]


def colher(fonte, alvo):
    """Traz uma subárvore da origem, sem script e com os moldes apagados."""
    achado = achar(fonte, alvo)
    if achado is None:
        return None
    copia = ET.fromstring(ET.tostring(achado))
    podar(copia, [])
    apagar(copia)
    return copia


def elo_de_corrente(pai, marca):
    """
    O elo da corrente da T5.

    Corrente não existe em asset nenhum do Acervo — procurei por `chain`,
    `corrente` e `elo` nos três catálogos de malha. O que existe é a malha de
    ANEL (3270017), que o Xester usa como anel de choque. Repetida e girada 90°
    a cada elo, ela vira corrente. É a única peça desenhada deste conjunto.
    """
    item, props = novo_item(pai, "Part", "Elo", "RV_ELO_%s" % marca)
    tam = ET.SubElement(props, "Vector3", {"name": "size"})
    for eixo, valor in zip("XYZ", (1.4, 1.4, 0.5)):
        ET.SubElement(tam, eixo).text = str(valor)
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(props, "float", {"name": "Transparency"}).text = "1"
    ET.SubElement(props, "token", {"name": "Material"}).text = "288"
    ET.SubElement(props, "int", {"name": "BrickColor"}).text = str(
        CORES["Really black"])
    _m, mp = novo_item(item, "SpecialMesh", "Mesh", "RV_ELOM_%s" % marca)
    ET.SubElement(mp, "token", {"name": "MeshType"}).text = "5"
    ET.SubElement(mp, "Content", {"name": "MeshId"}).append(ET.Element("url"))
    mp[-1][0].text = "rbxassetid://%s" % MALHA_ANEL
    return item


def bomba_para_caveira(pai, fonte_bomba, marca):
    """A bomba que a caveira arremessa — Handle do bomba_v4, com os dois Sound."""
    tools = [i for i in fonte_bomba.findall("Item") if i.get("class") == "Tool"]
    if not tools:
        return None
    handle = achar(tools[0], "Handle")
    if handle is None:
        return None
    copia = ET.fromstring(ET.tostring(handle))
    podar(copia, [])
    definir(copia, "string", "Name", "Bomba")
    apagar(copia)
    renomear_referentes(copia, "RV_BMB_%s_" % marca)
    pai.append(copia)
    return copia


def equipar(tool, dados, marca):
    (nome, tooltip, _seq, classe_dano, energia, recarga, chave,
     _moldes, precisa_mira) = dados

    definir(tool, "string", "Name", nome)
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFX_%s" % marca)
    if precisa_mira:
        novo_item(tool, "RemoteEvent", "MiraRemote", "RV_MIR_%s" % marca)

    for classe, tag, alvo, valor in (
        ("StringValue", "string", "DamageClass", classe_dano),
        ("StringValue", "string", "ChaveRecarga", chave),
        ("NumberValue", "float", "EnergyCost", str(energia)),
        ("NumberValue", "float", "RecargaGlobal", str(recarga)),
    ):
        _i, props = novo_item(tool, classe, alvo, "RV_%s_%s" % (alvo[:6], marca))
        ET.SubElement(props, tag, {"name": "Value"}).text = valor

    for classe, alvo in (
        ("Script", "%s_Server_V1" % nome.replace(" ", "")),
        ("LocalScript", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ):
        _i, props = novo_item(tool, classe, alvo,
                              "RV_%s_%s" % (alvo.replace(" ", "")[:14], marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""


def main():
    for caminho in (XESTER, BOMBA):
        if not os.path.exists(caminho):
            print("origem não encontrada: %s" % caminho)
            return 1
    fonte = ET.parse(XESTER).getroot()
    fonte_bomba = ET.parse(BOMBA).getroot()

    compartilhadas = {}
    for arquivo in (XESTER, BOMBA):
        for e in ET.parse(arquivo).getroot().iter("SharedString"):
            if e.get("md5"):
                compartilhadas[e.get("md5")] = e.text or ""

    # o Handle é o mesmo nas seis: o cajado do Xester. Conjunto de conjurador.
    staff = achar(fonte, "staff")
    grip = achar(staff, "t") if staff is not None else None
    if grip is None:
        print("não achei `staff/t` para o Handle")
        return 1

    print("PREPARAÇÃO — conjunto SUBMUNDO (autoral)")
    print("")
    print("  Sem modelo de origem. O Handle das seis é o cajado do Xester")
    print("  Forma 2; os moldes saem de skully, Effects e do bomba_v4.")
    print("  Desenhado aqui: só o elo de corrente da T5 (malha de anel 3270017).")
    print("")

    for dados in CONJUNTO:
        nome, _tt, _seq, _cd, _en, _rc, _ch, quais, _mira = dados
        marca = nome.replace(" ", "")

        tool = ET.Element("Item", {"class": "Tool", "referent": "RV_T_%s" % marca})
        ET.SubElement(tool, "Properties")
        equipar(tool, dados, marca)

        handle = ET.fromstring(ET.tostring(grip))
        podar(handle, [])
        definir(handle, "string", "Name", "Handle")
        definir(handle, "bool", "CanCollide", "false")
        definir(handle, "bool", "Anchored", "false")
        definir(handle, "float", "Transparency", "0")
        renomear_referentes(handle, "RV_HD_%s_" % marca)
        handle.set("referent", "RV_HDL_%s" % marca)
        tool.append(handle)

        moldes, _ = novo_item(tool, "Folder", "Moldes", "RV_MOL_%s" % marca)
        trazidos = []
        for alvo in quais:
            copia = colher(fonte, alvo)
            if copia is None:
                continue
            renomear_referentes(copia, "RV_%s_%s_" % (alvo[:3], marca))
            moldes.append(copia)
            trazidos.append(alvo)

        if nome == "Atraso Mortal":
            if bomba_para_caveira(moldes, fonte_bomba, marca) is None:
                print("  PAREI: não achei o Handle do bomba_v4")
                return 1
            trazidos.append("Bomba(bomba_v4)")
        if nome == "Portal do Submundo":
            elo_de_corrente(moldes, marca)
            trazidos.append("Elo(autoral)")

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)
        raiz = nova_raiz()
        raiz.append(tool)

        citadas = sorted({(e.text or "").strip() for e in raiz.iter("SharedString")
                          if e.get("name")})
        citadas = [c for c in citadas if c]
        if citadas:
            bloco = ET.SubElement(raiz, "SharedStrings")
            for md5 in citadas:
                if md5 not in compartilhadas:
                    print("  PAREI: md5 %s citado e ausente das origens" % md5)
                    return 1
                ET.SubElement(bloco, "SharedString",
                              {"md5": md5}).text = compartilhadas[md5]

        ET.ElementTree(raiz).write(os.path.join(pasta, "_ORIGEM.rbxmx"),
                                   encoding="utf-8", xml_declaration=False)
        print("  %-24s colhido de: %s" % (nome, ", ".join(trazidos)))

    print("")
    print("%d Tool(s) preparada(s)." % len(CONJUNTO))
    return 0


if __name__ == "__main__":
    sys.exit(main())
