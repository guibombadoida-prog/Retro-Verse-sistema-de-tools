#!/usr/bin/env python3
"""
preparar_reality_v2.py — Retro-Verse / Studios

Monta o modelo de **7 Tools** do conjunto REALITY, refeito **do zero** sob o
tema de FÍSICA DINÂMICA.

    python3 FERRAMENTAS/preparar_reality_v2.py

⛔ A FONTE PRINCIPAL CONTINUA EM QUARENTENA — E SÃO TRÊS VETORES, NÃO UM

    Releitura de 2026-08-29 do `reality_tools.rbxmx`, com contagem:

      1. `Physics Gun/qPerfectionWeld`  — busca em `https://assetimport.org/`
         por `HttpService:GetAsync` e passa o resultado para `require()`.
         Execução remota de código com permissão de servidor.
      2. `TrenchGun/Script`             — `require(206209239)`, id de terceiro.
      3. `RbxUtility`                   — alcança `http://www.chipmunkav.com`.

    ⛔ **Não arraste `reality_tools.rbxmx` para place nenhum, nem para testar.**

    E este conjunto usa a `Physics Gun`, que é justamente a Tool do vetor nº 1.
    Isso não muda nada, porque a regra aqui nunca dependeu de qual Tool está
    suja: **nenhum script da origem atravessa. Nem um.** O que entra é
    geometria, som, malha e dado. `descodificar()` é a barreira, e o `main()`
    varre o arquivo escrito atrás dos três vetores antes de declarar sucesso.

O QUE MUDOU DA V1 PARA A V2

    | V1 (5 Tools entregues) | V2 (7 Tools) |
    |---|---|
    | `Trem` | ❌ removida a pedido |
    | `Danca Provocadora` | ❌ removida a pedido |
    | — | ✅ `Arma de Fisica`, da `Physics Gun` |
    | — | ✅ `Indutor de Gravidade`, do `Gravity Inducer` |

    As cinco que ficam mantêm o NOME, e por isso a pasta `Tools/<Nome>/`. O
    conteúdo é refeito: o pedido foi "do 0".

    As duas novas não são invenção: são as DUAS Tools de física de verdade que
    a origem tem, e que a V1 não aproveitou. `Physics Gun` é a garra de força
    (segura sem teleportar), `Gravity Inducer` é o poço de gravidade (força por
    massa). São o tema que foi pedido, e já estavam lá.

UMA HABILIDADE POR TOOL — SÓ O CLIQUE

    Instrução em pé para ESTE conjunto: *"SEM HABILIDADES EXTRAS apenas click"*.
    Nenhuma Tool ganha `AcaoRemote`, e nenhuma lê tecla.

    A `Arma de Fisica` precisaria de duas entradas (pegar e soltar) e não abre
    exceção: usa `Tool.Activated` e `Tool.Deactivated`, que são o botão descendo
    e o MESMO botão subindo. Continua sendo só o clique.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# A maquinaria de XML é a mesma da V1, e é importada em vez de copiada: duas
# cópias divergem em silêncio, e `descodificar()` é a barreira de quarentena —
# barreira duplicada é barreira que um dia só metade recebe o conserto.
from preparar_reality import (          # noqa: E402
    CLASSES_PECA, CLASSES_SCRIPT, RE_REQUIRE_ID,
    achar_tool, assentar, colher, definir, descodificar, nova_raiz, novo_item,
    normalizar_som, pares, reetiquetar, sons_de, texto,
)

REALITY = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                       "reality_tools.rbxmx")
CANHAO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Canhao_Satelite",
                      "Canhao_satelite.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                       "Reality_7_Tools.rbxmx")

#: os três vetores confirmados, mais a família deles
VENENO = ("assetimport", "chipmunkav", "loadstring", "getfenv", "setfenv",
          "HttpService", "GetAsync", "PostAsync", "InsertService")


# nome · Tool de origem · fonte · tooltip · recarga · ChaveVFX · moldes
CONJUNTO = [
    ("Lapada Seca", "SLAP", "reality",
     "Tapa que joga o alvo girando — impulso e giro, nao teleporte",
     4.0, "Reality_Lapada", ("Hand",)),

    ("Canhao Satelite", "LowOrbitIonCannon", "canhao",
     "Marca o ponto e chama o feixe de orbita, que empurra o que sobra",
     26.0, "Reality_Canhao", ()),

    ("Arvore Maligna", "tre", "reality",
     "Ergue a arvore, e os cipos AMARRAM quem chega perto",
     22.0, "Reality_Arvore", ("Phys", "Phys2", "Phys3", "Phys4", "Death")),

    ("Gato Ajudante Boss", "gravity cat not amused", "reality",
     "Invoca o gato, que persegue por fisica ate o prazo acabar",
     30.0, "Reality_Gato", ("Gravity Cat Not Amused",)),

    ("Samsungus", "samsung", "reality",
     "Arremessa o aparelho, que QUICA de verdade e estoura no fim",
     9.0, "Reality_Samsungus", ()),

    ("Arma de Fisica", "Physics Gun", "reality",
     "Segura a peca no ar com forca; solta com a velocidade que ela tinha",
     1.5, "Reality_ArmaFisica", ("Shoot",)),

    ("Indutor de Gravidade", "Gravity Inducer", "reality",
     "Abre um poco de gravidade: a forca sobe com a massa de cada peca",
     20.0, "Reality_Indutor", ()),
]

#: Tool de origem -> `Sound` a trazer, e com que nome de papel
SONS = {
    "SLAP": {"Smack": "TAPA", "Boom": "ESTOURO", "slaps": "SEQUENCIA",
             "Sound": "CHICOTE"},
    "LowOrbitIonCannon": {"Call": "CHAMADA", "Big Explosion": "FEIXE",
                          "Electric Explosion": "CARGA",
                          "Explosion SFX": "ECO"},
    "tre": {"Kill": "GALHO"},
    "gravity cat not amused": {"theme": "MIADO"},
    "samsung": {"MetalHit": "BATE", "Swoosh": "GIRO", "Hit": "IMPACTO",
                "unequip": "GUARDA", "Swoosh2": "QUICA"},
    "Physics Gun": {},
    "Gravity Inducer": {"Sound": "TRAVA", "BlackHoleSound": "POCO"},
}

#: A `Physics Gun` da origem NÃO TEM UM ÚNICO `Sound` — conferido na árvore.
#: Ferramenta muda é asset faltando, não escolha de projeto. Ela pega
#: emprestado do Canhão, que trouxe 21, e o empréstimo fica DECLARADO aqui em
#: vez de o id aparecer chutado no meio do Server.
SONS_EMPRESTADOS = {
    "Arma de Fisica": [("LowOrbitIonCannon", "Electric Explosion", "TRAVA"),
                       ("LowOrbitIonCannon", "Call", "SOLTA")],
    "Indutor de Gravidade": [("LowOrbitIonCannon", "Big Explosion", "COLAPSO")],
}


def handle_de(origem):
    """A peça chamada `Handle` dentro da Tool de origem, se houver."""
    for _pai, filho in pares(origem):
        if texto(filho, "Name") == "Handle" and filho.get("class") in CLASSES_PECA:
            return filho
    return None


def limpar_handle(handle, marca):
    copia = copy.deepcopy(handle)
    reetiquetar(copia, "RVH%s_" % marca)
    descodificar(copia)
    for pai, filho in list(pares(copia)):
        if filho.get("class") == "Sound":
            pai.remove(filho)
    definir(copia, "string", "Name", "Handle")
    definir(copia, "bool", "Anchored", "false")
    definir(copia, "bool", "CanCollide", "false")
    definir(copia, "bool", "Massless", "true")
    return copia


def handle_invisivel(marca):
    item = ET.Element("Item", {"class": "Part",
                               "referent": "RV_HANDLE_%s" % marca})
    p = ET.SubElement(item, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = "Handle"
    tamanho = ET.SubElement(p, "Vector3", {"name": "size"})
    for eixo in ("X", "Y", "Z"):
        ET.SubElement(tamanho, eixo).text = "0.4"
    ET.SubElement(p, "float", {"name": "Transparency"}).text = "1"
    ET.SubElement(p, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(p, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(p, "bool", {"name": "CastShadow"}).text = "false"
    return item


def montar(dados, marca, fontes):
    nome, origem_nome, fonte, tooltip, recarga, chave, quais = dados

    origem = achar_tool(fontes[fonte], origem_nome)
    if origem is None:
        return None, "não achei a Tool %r em %s" % (origem_nome, fonte)

    tool = ET.Element("Item", {"class": "Tool",
                               "referent": "RV_TOOL_%s" % marca})
    p = ET.SubElement(tool, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    ET.SubElement(p, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(p, "bool", {"name": "CanBeDropped"}).text = "false"
    ET.SubElement(p, "bool", {"name": "RequiresHandle"}).text = "true"

    bruto = handle_de(origem)
    proprio = bruto is not None
    handle = limpar_handle(bruto, marca) if proprio else handle_invisivel(marca)
    tool.append(handle)

    # ── moldes: geometria de VFX, filha da Tool na ENTREGA (regra nº 2)
    pasta, _ = novo_item(tool, "Folder", "Moldes", "RV_MOLDES_%s" % marca)
    colhidos = colher(origem, set(quais))
    postos = []
    for i, alvo in enumerate(quais):
        molde = colhidos.get(alvo)
        if molde is None:
            continue
        copia = copy.deepcopy(molde)
        reetiquetar(copia, "RVM%s_%d_" % (marca, i))
        descodificar(copia)
        if copia.get("class") == "Model":
            for _pai2, filho2 in pares(copia):
                if filho2.get("class") in CLASSES_PECA:
                    assentar(filho2)
        else:
            assentar(copia)
        pasta.append(copia)
        postos.append(alvo)

    # ── SFX, todos filhos do Handle
    disponiveis = sons_de(origem)
    n_som = 0
    usados = set()
    for cru, papel in sorted(SONS.get(origem_nome, {}).items()):
        som = disponiveis.get(cru)
        if som is None:
            continue
        copia = copy.deepcopy(som)
        reetiquetar(copia, "RVS%s_%d_" % (marca, n_som))
        descodificar(copia)
        if not normalizar_som(copia):
            continue
        definir(copia, "string", "Name", papel)
        definir(copia, "bool", "Looped", "false")
        handle.append(copia)
        usados.add(papel)
        n_som = n_som + 1

    for de_tool, cru, papel in SONS_EMPRESTADOS.get(nome, []):
        if papel in usados:
            continue
        doadora = (achar_tool(fontes["canhao"], de_tool)
                   or achar_tool(fontes["reality"], de_tool))
        if doadora is None:
            continue
        som = sons_de(doadora).get(cru)
        if som is None:
            continue
        copia = copy.deepcopy(som)
        reetiquetar(copia, "RVE%s_%d_" % (marca, n_som))
        descodificar(copia)
        if not normalizar_som(copia):
            continue
        definir(copia, "string", "Name", papel)
        definir(copia, "bool", "Looped", "false")
        handle.append(copia)
        usados.add(papel)
        n_som = n_som + 1

    # ── valores
    #
    # `ChaveVFX` é do MODELO, não da instância (regra nº 2): a primeira Tool a
    # chegar cria `ReplicatedStorage/RetroVerse_VFX/<chave>/`, e a segunda
    # REUSA. Uma chave por Tool porque cada uma tem molde diferente.
    for classe, tag, alvo, valor in (
            ("StringValue", "string", "ChaveRecarga", chave),
            ("StringValue", "string", "ChaveVFX", chave),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, pv = novo_item(tool, classe, alvo, "RV_%s_%s" % (alvo[:7], marca))
        ET.SubElement(pv, tag, {"name": "Value"}).text = valor

    # Sem `AcaoRemote`: uma habilidade por Tool, e ela é no clique. RemoteEvent
    # que nenhum script cita é porta aberta de graça.
    novo_item(tool, "RemoteEvent", "VFXRemote", "RV_VFXR_%s" % marca)

    objeto = "%s_Server_V1" % re.sub(r"[^\w]", "", nome)
    scripts = [("Script", objeto), ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"), ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule"), ("ModuleScript", "DepositoVFX")]
    for classe, alvo in scripts:
        item, pv = novo_item(tool, classe, alvo,
                             "RV_%s_%s" % (re.sub(r"[^\w]", "", alvo)[:12], marca))
        ET.SubElement(pv, "ProtectedString", {"name": "Source"}).text = ""
        if alvo == "Client":
            ET.SubElement(pv, "token", {"name": "RunContext"}).text = "2"

    return (tool, postos, n_som, proprio), None


def main():
    for caminho in (REALITY, CANHAO):
        if not os.path.exists(caminho):
            print("fonte não encontrada: %s" % caminho)
            return 1

    fontes = {"reality": ET.parse(REALITY).getroot(),
              "canhao": ET.parse(CANHAO).getroot()}
    tabela = {}
    for raiz in fontes.values():
        for e in raiz.iter("SharedString"):
            if e.get("md5"):
                tabela[e.get("md5")] = e.text or ""

    print("⛔ QUARENTENA — 3 vetores na fonte; nenhum script atravessa")
    print("")

    saida = nova_raiz()
    for indice, dados in enumerate(CONJUNTO, 1):
        marca = "%02d" % indice
        feito, erro = montar(dados, marca, fontes)
        if erro:
            print("PAREI: %s" % erro)
            return 1
        tool, postos, n_som, proprio = feito
        saida.append(tool)
        print("%-22s %-24s handle:%-9s %2d som(ns) · moldes: %s"
              % (dados[0], dados[1], "origem" if proprio else "invisível",
                 n_som, ", ".join(postos) or "—"))

    # `SharedStrings` viaja como IRMÃ dos `<Item>`, e só com os md5 CITADOS.
    # Md5 citado sem bloco, ou bloco com md5 a mais, e o Studio chama o arquivo
    # de corrompido — foi o que aconteceu com o conjunto TEMPO.
    citadas = sorted({(e.text or "").strip()
                      for e in saida.iter("SharedString") if e.get("name")})
    citadas = [c for c in citadas if c]
    penduradas = []
    if citadas:
        bloco = ET.SubElement(saida, "SharedStrings")
        for md5 in citadas:
            if md5 in tabela:
                ET.SubElement(bloco, "SharedString", {"md5": md5}).text = tabela[md5]
            else:
                penduradas.append(md5)

    ET.ElementTree(saida).write(DESTINO, encoding="utf-8", xml_declaration=True)

    with open(DESTINO, encoding="utf-8", errors="replace") as f:
        corpo = f.read()
    achados = [v for v in VENENO if v.lower() in corpo.lower()]
    if RE_REQUIRE_ID.search(corpo):
        achados.append("require(<id>)")
    n_script = sum(1 for i in saida.iter("Item")
                   if i.get("class") in CLASSES_SCRIPT
                   and (texto(i, "Source") or "").strip())

    print("")
    print("%s  —  %d bytes · %d Tools · %d SharedString"
          % (os.path.relpath(DESTINO, RAIZ), os.path.getsize(DESTINO),
             len(CONJUNTO), len(citadas)))
    print("QUARENTENA: %d script(s) da origem · veneno: %s"
          % (n_script, ", ".join(achados) if achados else "nenhum"))
    if achados or n_script:
        print("   ⛔ FALHOU — não entregue este arquivo")
        return 1
    if penduradas:
        print("   ⚠️  %d SharedString PENDURADA" % len(penduradas))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
