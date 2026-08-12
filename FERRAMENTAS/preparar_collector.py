#!/usr/bin/env python3
"""
preparar_collector.py — Retro-Verse / Studios

Monta a árvore das 6 Tools do conjunto **COLLECTOR**. É o primeiro conjunto
AUTORAL do repositório: não sai de um modelo, sai do Acervo.

    python3 FERRAMENTAS/preparar_collector.py

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
# SFX — do catálogo do Xester Forma 1, que está LIMPO
# ═══════════════════════════════════════════════════════════════
#
# Cada id abaixo mantém, no Submundo, um PAPEL próximo do que tinha no script
# de origem — não escolhi por nome bonito, escolhi pelo uso que o `un.lua` dava
# a ele. Eu não posso ouvir os arquivos daqui, e é a única base honesta que
# tenho para casar som com momento.
#
#   1888686669  portal/carta grande aparecendo     -> abertura, nascimento
#   1072606965  rugido sustentado do Cardnado      -> o grito do pilar
#   472579737   colapso do buraco negro            -> queda, devolução
#   236989198   carta colossal surgindo (peso)     -> algo grande se ergue
#   765590102   carta colossal batendo             -> impacto
#   1898092341  selo/decal do ato de desaparecer   -> selar
#   472214107   plataforma selando                 -> tique do contador
#   1910988873  o raio                             -> a sentença descendo
#   1894958339  teleporte                          -> desfazer o corpo
#   1882057730  leque de cartas abrindo            -> o olho abrindo
#   342337569   arranque do Cardnado               -> varredura
#   54111471    fim do ato de desaparecer          -> fechamento
#   413682983   escudo                             -> corrente prendendo
#
# ATENÇÃO, e isto é uma inconsistência do Acervo, não minha escolha:
# `_INDICE.md` marca os SFX de Jupiter e Cosmic Entity como LIMPO, mas o
# `SFX/ids.md` de cada um diz CRU no cabeçalho. Enquanto os dois não
# concordarem, não puxo som de lá — os ids abaixo vêm do Xester Forma 1, cuja
# ficha está fechada nos quatro campos.

SONS = {
    "Pilar das Lamentacoes": [
        ("ERGUE", "236989198", 4, 0.85),
        ("GRITO", "1072606965", 3, 1.0),
        ("CAI", "472579737", 5, 0.8),
    ],
    "Julgamento Final": [
        ("SELA", "1898092341", 4, 1.0),
        ("TIQUE", "472214107", 1.5, 1.6),
        ("EXECUTA", "1910988873", 6, 0.75),
    ],
    "Atraso Mortal": [
        ("NASCE", "1888686669", 4, 1.15),
    ],
    "Perturbacao": [
        ("DESFAZ", "1894958339", 4, 0.8),
        ("DEVOLVE", "472579737", 5, 1.1),
    ],
    "Portal do Submundo": [
        ("ABRE", "1888686669", 4, 0.7),
        ("CORRENTE", "413682983", 3, 1.2),
        ("FECHA", "54111471", 4, 0.9),
    ],
    "Olho do Vigia": [
        ("ABRE", "1882057730", 4, 0.9),
        ("VARRE", "342337569", 2.5, 1.3),
        ("FECHA", "54111471", 3, 1.1),
    ],
}


def pasta_de_sfx(tool, nome, marca):
    """
    `Tool/SFX/` com os moldes de som. O script CLONA daqui; nunca cria
    `SoundId` solto — o som é filho da Tool, como todo o resto (Regra nº 1).
    """
    if nome not in SONS:
        return 0
    sfx, _ = novo_item(tool, "Folder", "SFX", "RV_SFX_%s" % marca)
    for rotulo, ident, volume, pitch in SONS[nome]:
        _s, props = novo_item(sfx, "Sound", rotulo,
                              "RV_SN%s_%s" % (rotulo, marca))
        ET.SubElement(props, "Content", {"name": "SoundId"}).append(
            ET.Element("url"))
        props[-1][0].text = "rbxassetid://%s" % ident
        ET.SubElement(props, "float", {"name": "Volume"}).text = str(volume)
        ET.SubElement(props, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
        ET.SubElement(props, "float", {"name": "RollOffMaxDistance"}).text = "220"
    return len(SONS[nome])

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
        ("Script", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ):
        item, props = novo_item(tool, classe, alvo,
                                "RV_%s_%s" % (alvo.replace(" ", "")[:14], marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""
        if alvo == "Client":
            # RunContext = Client (2), NÃO LocalScript.
            #
            # LocalScript dentro de Tool só roda para o jogador cujo Character
            # a contém. O servidor manda o beat com `FireAllClients` e ele
            # CHEGA em todo mundo — mas o único ouvinte que existe é o de quem
            # está segurando a Tool. Resultado: o VFX aparecia só para o dono.
            #
            # `Script` com RunContext = Client roda em TODO cliente, onde quer
            # que esteja na árvore, inclusive dentro da Tool de outro jogador.
            # É o que faz o efeito aparecer para a sala inteira sem tirar nada
            # de dentro da Tool (Regra nº 1 intacta).
            ET.SubElement(props, "token", {"name": "RunContext"}).text = "2"


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

    print("PREPARAÇÃO — conjunto COLLECTOR (autoral)")
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

        quantos = pasta_de_sfx(tool, nome, marca)
        if quantos:
            trazidos.append("%d som(ns)" % quantos)

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
