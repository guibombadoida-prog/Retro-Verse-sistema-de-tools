#!/usr/bin/env python3
"""
preparar_noob.py — Retro-Verse / Studios

Monta o modelo de **7 Tools** a partir do `noob_despertado.rbxmx`.

    python3 FERRAMENTAS/preparar_noob.py

A ORIGEM NÃO É UMA TOOL, E ISSO MUDA O TRABALHO

    O `noob_despertado.rbxmx` é um `Script` de 2650 linhas solto na raiz, com
    props de vestir e uma `ScreenGui` — formato de *script showcase* que se cola
    dentro de um Character. Não há `Tool` nenhuma para clonar.

    Então aqui não se clona: se CONSTRÓI. Cada Tool nasce vazia e recebe o
    Handle, os moldes e os sons que lhe cabem.

NOVE ATAQUES, SEIS FORMAS, E TRÊS ATAQUES INALCANÇÁVEIS

    O `KeyDown` despacha por tecla e o ataque depende do `mode` que a forma
    ligou. A tecla `e` cai em DOIS `if` separados — `MasterForm()` e depois
    `LightForm()` — e como não é `if/elseif`, os dois rodam. O `mode` termina
    `"light"`, e não existe ramo `light` no despacho: **`TimeStop`, `BlackRole`
    e `ClockDestroyer` nunca disparam** no modelo como ele veio.

    Os três entram aqui. É o oposto do que o Faker mostrou (cinco malhas pagas e
    nunca acesas): lá era asset parado, aqui é habilidade escrita e enterrada
    por um `elseif` que ninguém digitou.

    As **formas não viram Tool**. `mode` global que troca aparência e desbloqueia
    ataque é estado de personagem; cada Tool aqui é autocontida por definição.
    O que sobrevive delas é o tema — vazio, tempo, lua, dominus — e os props.

OS NÚMEROS DA ORIGEM SÃO DE SHOWCASE, NÃO DE JOGO

    | Ataque | Raio | Dano | INSTAKILL |
    |---|---|---|---|
    | `Shot` | — | **Banish: `Foe:Destroy()`** | — |
    | `Lava` | **900** | 90–100 | **sim** |
    | `TimeStop` | **1000** | 25–50 | não |
    | `BlackRole` | 100 | 90–100 | **sim** |
    | `BlastShoot` | **400** | **999** | **sim** |
    | `SuperDominus` | 200 | 100 | **sim** |
    | `ClockDestroyer` | 15 | 30–40 | não |
    | `Lunar_Blast` | 25 | `killnearest(25, 25)` | — |
    | `Neckless` | — | `ApplyDamage(HUM, 0, true)` | — |

    Quatro dos nove são INSTAKILL e um faz 999 de dano em raio 400. Raio 1000 é
    o mapa inteiro. Isso não é balanceamento ruim: é script de exibição, feito
    para limpar o servidor num clique.

    A conversão mantém a IDENTIDADE e a proporção — a Lava é a de área, o
    BlastShoot é o tiro pesado, o ClockDestroyer é o preciso — e traz tudo para
    a faixa que os outros conjuntos usam (o maior do repositório é a `Era Do
    Fim`, 120 no núcleo em raio 58).

A PASTA `Effects` ESTÁ DUPLICADA NO ARQUIVO

    Ela existe como filha do `Script noob` E como `Folder` na raiz, com o mesmo
    conteúdo. Os 26 `ParticleEmitter` do XML são **13 reais**. Copiar os dois
    lados poria emissor em dobro dentro de cada Tool, e o efeito sairia com o
    dobro do `Rate` autorado.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Noob_Despertado",
                     "noob_despertado.rbxmx")
DESTINO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Noob_Despertado",
                       "Noob_7_Tools.rbxmx")

# alvo · tooltip · DamageClass · recarga · chave · cutscene · handle da origem ·
# moldes de peça · moldes de emissor
CONJUNTO = [
    ("Tiro do Vazio",
     "Feixe que bane o alvo; a Extra e o disparo pesado",
     "Espectral", 6, "Noob_TiroVazio", False, "c",
     ("MiniVoidCrystal",), ("VoidMagic", "VoidExplode")),

    ("Chuva de Lava",
     "Laje de lava que sobe do chao e queima a area",
     "Explosivo", 28, "Noob_ChuvaLava", True, None,
     ("Lava",), ("VoidExplode2",)),

    ("Parada do Tempo",
     "Trava quem esta perto; a Extra e o relogio que estoura",
     "Espectral", 22, "Noob_ParadaTempo", False, "hat",
     ("SmallVoidCrystal", "Bomb"), ("Stun", "VoidMagic")),

    ("Buraco Negro",
     "Esfera que puxa tudo para dentro e colapsa",
     "Espectral", 26, "Noob_BuracoNegro", False, "RobotPart",
     ("VoidCrystal",), ("VoidMagic", "VoidExplode2")),

    ("Colar das Trevas",
     "Prende o alvo pelo pescoco e drena",
     "Espectral", 16, "Noob_ColarTrevas", False, "RobotPart2",
     ("MiniVoidCrystal",), ("Stun", "VoidExplode")),

    ("Explosao Lunar",
     "Chama a lua sobre o ponto mirado",
     "Explosivo", 24, "Noob_ExplosaoLunar", False, None,
     ("Bomb",), ("VoidExplode",)),

    ("Super Dominus",
     "A coroa cai no alvo — ultimate com cutscene",
     "Explosivo", 40, "Noob_SuperDominus", True, "dominus",
     ("VoidCrystal", "SmallVoidCrystal"), ("VoidExplode2", "VoidMagic")),
]

# ═══════════════════════════════════════════════════════════════
# SFX — 13 ids que só existiam em CÓDIGO
#
# O modelo não tem um único `Sound` no XML: tudo sai de
# `CreateSound(ID, PARENT, VOLUME, PITCH, DOESLOOP)` em runtime. Isso significa
# que **nenhum vem com volume ou pitch autorado para copiar** — os valores
# abaixo saem das chamadas do próprio script, lidas uma a uma.
#
# Onde a origem pedia `VOLUME = 10` (o `Lava` e o `TimeStop` pedem), o valor
# entra como 2.0: o teto do Roblox é 10, e 10 é o teto — som de habilidade no
# volume máximo abafa o jogo inteiro.
# ═══════════════════════════════════════════════════════════════

SONS = {
    "GRAVE":    ("rbxassetid://62339698", "2", "0.8"),
    "ESTOURO":  ("rbxassetid://159882598", "2", "1"),
    "TEMPO":    ("rbxassetid://1636723480", "1.6", "1"),
    "LUA":      ("rbxassetid://168586621", "1.8", "1"),
    "VAZIO":    ("rbxassetid://487214658", "1.6", "1"),
    "COLAPSO":  ("rbxassetid://262562442", "2", "0.9"),
    "CORRENTE": ("rbxassetid://235097614", "1.5", "1"),
    "DRENO":    ("rbxassetid://363808674", "1.5", "1"),
    "COROA":    ("rbxassetid://824687369", "1.8", "1"),
    "TIRO":     ("rbxassetid://763717897", "1.6", "1"),
    "CARGA":    ("rbxassetid://340722848", "1.4", "1"),
    "ECO":      ("rbxassetid://649634100", "1.4", "0.7"),
    "ZUMBIDO":  ("rbxassetid://743521450", "1.2", "1"),
}

SONS_POR_TOOL = {
    "Tiro do Vazio":    ("CARGA", "TIRO", "VAZIO"),
    "Chuva de Lava":    ("ESTOURO", "GRAVE", "ECO"),
    "Parada do Tempo":  ("TEMPO", "ZUMBIDO", "ESTOURO"),
    "Buraco Negro":     ("VAZIO", "COLAPSO", "ECO"),
    "Colar das Trevas": ("CORRENTE", "DRENO", "ZUMBIDO"),
    "Explosao Lunar":   ("CARGA", "LUA", "ESTOURO"),
    "Super Dominus":    ("COROA", "GRAVE", "COLAPSO"),
}

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
CLASSES_FORA = CLASSES_SCRIPT + ("Animation", "ScreenGui", "TextLabel",
                                 "Frame", "Camera", "BillboardGui",
                                 "ClickDetector", "RemoteFunction",
                                 "RemoteEvent", "BindableEvent")
CLASSES_PECA = ("Part", "MeshPart", "UnionOperation", "WedgePart")


def props(item):
    p = item.find("Properties")
    if p is None:
        p = ET.SubElement(item, "Properties")
    return p


def prop(item, nome):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == nome:
            return e
    return None


def texto(item, nome):
    e = prop(item, nome)
    if e is None:
        return None
    u = e.find("url")
    if u is not None:
        return u.text
    return e.text


def definir(item, tag, nome, valor):
    e = prop(item, nome)
    if e is None:
        e = ET.SubElement(props(item), tag, {"name": nome})
    e.tag = tag
    e.text = valor
    for filho in list(e):
        e.remove(filho)
    return e


def novo_item(pai, classe, nome, referente):
    item = ET.SubElement(pai, "Item", {"class": classe, "referent": referente})
    p = ET.SubElement(item, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    return item, p


def pares(item):
    for filho in item.findall("Item"):
        for par in pares(filho):
            yield par
        yield item, filho


def reetiquetar(no, prefixo):
    """Prefixa todo `referent` e reescreve todo `<Ref>` que o citava.

    As sete recebem cópias dos MESMOS moldes, então sem isto os clones entram no
    arquivo com ids idênticos e o Studio religa propriedade no objeto errado.
    """
    mapa = {}
    for item in no.iter("Item"):
        antigo = item.get("referent")
        if antigo:
            novo = prefixo + antigo
            mapa[antigo] = novo
            item.set("referent", novo)
    for ref in no.iter("Ref"):
        alvo = (ref.text or "").strip()
        if alvo in mapa:
            ref.text = mapa[alvo]
    return len(mapa)


def colher(fonte):
    """Colhe props e moldes de UM lado só da árvore.

    A pasta `Effects` existe duas vezes no arquivo — filha do `Script noob` e
    `Folder` na raiz — com o mesmo conteúdo. Colher os dois lados poria cada
    emissor em dobro dentro da Tool, e o efeito sairia com o dobro do `Rate`
    que o autor escreveu.
    """
    achados = {}
    for _pai, filho in pares(fonte):
        nome = texto(filho, "Name")
        if not nome or nome in achados:
            continue
        if filho.get("class") in CLASSES_PECA:
            achados[nome] = copy.deepcopy(filho)
        elif filho.get("class") == "Attachment" and filho.findall("Item"):
            # `VoidMagic`, `Stun`, `VoidExplode`, `VoidExplode2` são
            # **Attachment**, não Part: os quatro moram dentro de uma peça só,
            # a `AttEffects`. Attachment não vive solto em `Tool/Moldes/` — na
            # montagem cada um ganha a âncora dele.
            achados[nome] = copy.deepcopy(filho)
    return achados


def limpar(no):
    """Tira script, GUI e som de dentro de um molde colhido."""
    n = 0
    for pai, filho in list(pares(no)):
        if filho.get("class") in CLASSES_FORA or filho.get("class") == "Sound":
            pai.remove(filho)
            n = n + 1
    return n


def assentar(peca, invisivel=True):
    """Molde de VFX: ancorado, sem colisão, e INVISÍVEL dentro da Tool.

    A regra que o usuário fixou: *"deixar os vfx invisível dentro da tool, e
    visível na execução da habilidade"*. Quem acende é o `VFXModule`, no clone.
    """
    definir(peca, "bool", "Anchored", "true")
    definir(peca, "bool", "CanCollide", "false")
    definir(peca, "bool", "CanTouch", "false")
    definir(peca, "bool", "CanQuery", "false")
    definir(peca, "bool", "Massless", "true")
    definir(peca, "bool", "CastShadow", "false")
    if invisivel:
        definir(peca, "float", "Transparency", "1")
    # emissor desligado no molde: quem liga é o VFXModule, por Enabled + Rate
    for _pai, filho in pares(peca):
        if filho.get("class") == "ParticleEmitter":
            definir(filho, "bool", "Enabled", "false")
    return peca


def encolher(peca, teto):
    """Corta o maior lado da peça para caber num molde de Tool.

    A `Lava` da origem tem **900 × 20 × 900 studs** — o mesmo 900 do
    `ApplyAoE(..., 900, ...)`. A peça É o raio, e nenhum dos dois cabe num jogo.
    """
    e = prop(peca, "size") or prop(peca, "Size")
    if e is None:
        return None
    try:
        partes = [float(x) for x in " ".join(e.itertext()).split()]
    except ValueError:
        return None
    if len(partes) != 3 or max(partes) <= teto:
        return None
    fator = teto / max(partes)
    novos = [round(v * fator, 4) for v in partes]
    for filho in list(e):
        e.remove(filho)
    e.text = None
    for nome, valor in zip(("X", "Y", "Z"), novos):
        ET.SubElement(e, nome).text = str(valor)
    return (partes, novos)


def novo_handle(tool, marca, origem):
    """O Handle: da origem quando ela tem geometria vestível, invisível quando não.

    Cinco das sete recebem um prop do modelo. `Chuva de Lava` e `Explosao Lunar`
    não recebem: a laje de 900 studs e a bomba de 13.7 são EFEITO, não coisa que
    se segura na mão. Elas ganham um invisível de 0.4 stud, como o `Fists` e o
    `dodge` do conjunto DRAMA.
    """
    if origem is not None:
        handle = copy.deepcopy(origem)
        reetiquetar(handle, "NBH%s_" % marca)
        limpar(handle)
        definir(handle, "string", "Name", "Handle")
        definir(handle, "bool", "Anchored", "false")
        definir(handle, "bool", "CanCollide", "false")
        definir(handle, "bool", "Massless", "true")
        tool.append(handle)
        return handle, True

    handle, p = novo_item(tool, "Part", "Handle", "NB_HANDLE_%s" % marca)
    tamanho = ET.SubElement(p, "Vector3", {"name": "size"})
    for eixo in ("X", "Y", "Z"):
        ET.SubElement(tamanho, eixo).text = "0.4"
    ET.SubElement(p, "float", {"name": "Transparency"}).text = "1"
    ET.SubElement(p, "bool", {"name": "Anchored"}).text = "false"
    ET.SubElement(p, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(p, "bool", {"name": "Massless"}).text = "true"
    ET.SubElement(p, "bool", {"name": "CastShadow"}).text = "false"
    return handle, False


def novo_som(pai, nome, ident, volume, pitch, referente):
    item, p = novo_item(pai, "Sound", nome, referente)
    conteudo = ET.SubElement(p, "Content", {"name": "SoundId"})
    ET.SubElement(conteudo, "url").text = ident
    ET.SubElement(p, "float", {"name": "Volume"}).text = volume
    ET.SubElement(p, "float", {"name": "PlaybackSpeed"}).text = pitch
    ET.SubElement(p, "float", {"name": "RollOffMaxDistance"}).text = "180"
    ET.SubElement(p, "bool", {"name": "Looped"}).text = "false"
    return item


def montar(dados, marca, colhidos):
    (nome, tooltip, classe_dano, recarga, chave, cutscene, handle_de,
     pecas, emissores) = dados

    tool = ET.Element("Item", {"class": "Tool", "referent": "NB_TOOL_%s" % marca})
    p = ET.SubElement(tool, "Properties")
    ET.SubElement(p, "string", {"name": "Name"}).text = nome
    ET.SubElement(p, "string", {"name": "ToolTip"}).text = tooltip
    ET.SubElement(p, "bool", {"name": "CanBeDropped"}).text = "false"
    ET.SubElement(p, "bool", {"name": "RequiresHandle"}).text = "true"

    origem = colhidos.get(handle_de) if handle_de else None
    _handle, veio_da_origem = novo_handle(tool, marca, origem)
    handle = None
    for filho in tool.findall("Item"):
        if texto(filho, "Name") == "Handle":
            handle = filho
            break

    # os moldes: peça e emissor, os dois invisíveis
    pasta, _pp = novo_item(tool, "Folder", "Moldes", "NB_MOLDES_%s" % marca)
    postos, cortes = [], []
    for i, alvo in enumerate(pecas + emissores):
        molde = colhidos.get(alvo)
        if molde is None:
            continue
        copia = copy.deepcopy(molde)
        reetiquetar(copia, "NBM%s_%d_" % (marca, i))
        limpar(copia)

        if copia.get("class") == "Attachment":
            # a âncora que falta: um Part invisível de 0.2 com o Attachment
            # dentro. Assim `Tool/Moldes/VoidMagic` é uma peça que o VFXModule
            # clona, posiciona e acende — e o Attachment vai junto.
            ancora, pa = novo_item(pasta, "Part", alvo,
                                   "NBA_%s_%d" % (marca, i))
            tam = ET.SubElement(pa, "Vector3", {"name": "size"})
            for eixo in ("X", "Y", "Z"):
                ET.SubElement(tam, eixo).text = "0.2"
            ancora.append(copia)
            assentar(ancora)
            postos.append(alvo)
            continue

        corte = encolher(copia, 24)
        if corte:
            cortes.append("%s %g->%g" % (alvo, max(corte[0]), max(corte[1])))
        assentar(copia)
        pasta.append(copia)
        postos.append(alvo)

    for i, papel in enumerate(SONS_POR_TOOL.get(nome, ())):
        ident, volume, pitch = SONS[papel]
        novo_som(handle, papel, ident, volume, pitch,
                 "NB_SFX_%s_%d" % (marca, i))

    for classe, tag, alvo, valor in (
            ("StringValue", "string", "DamageClass", classe_dano),
            ("StringValue", "string", "ChaveRecarga", chave),
            ("NumberValue", "float", "EnergyCost", "0"),
            ("NumberValue", "float", "RecargaGlobal", str(recarga))):
        item, pv = novo_item(tool, classe, alvo, "NB_%s_%s" % (alvo[:6], marca))
        ET.SubElement(pv, tag, {"name": "Value"}).text = valor

    novo_item(tool, "RemoteEvent", "VFXRemote", "NB_VFXR_%s" % marca)
    novo_item(tool, "RemoteEvent", "AcaoRemote", "NB_ACAO_%s" % marca)
    if cutscene:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "NB_CUTR_%s" % marca)

    objeto = "%s_Server_V1" % re.sub(r"[^\w]", "", nome)
    scripts = [("Script", objeto),
               ("Script", "Client"),
               ("ModuleScript", "R6CFrameAnimator"),
               ("ModuleScript", "Poses"),
               ("ModuleScript", "VFXModule")]
    if cutscene:
        scripts.append(("Script", "CutsceneCam"))

    for classe, alvo in scripts:
        item, pv = novo_item(tool, classe, alvo,
                             "NB_%s_%s" % (re.sub(r"[^\w]", "", alvo)[:12], marca))
        ET.SubElement(pv, "ProtectedString", {"name": "Source"}).text = ""
        if alvo in ("Client", "CutsceneCam"):
            # RunContext = Client (2), NÃO LocalScript. LocalScript dentro de
            # Tool só roda para quem a segura.
            ET.SubElement(pv, "token", {"name": "RunContext"}).text = "2"

    return tool, postos, cortes, veio_da_origem


def nova_raiz():
    raiz = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(raiz, "Meta", {"name": "ExplicitAutoJoints"}).text = "true"
    ET.SubElement(raiz, "External").text = "null"
    ET.SubElement(raiz, "External").text = "nil"
    return raiz


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1

    fonte = ET.parse(ORIGEM).getroot()
    tabela = {}
    for e in fonte.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text or ""

    colhidos = colher(fonte)
    usados = sorted({a for d in CONJUNTO for a in (d[7] + d[8])})
    faltando = [a for a in usados if a not in colhidos]
    emissores = sum(1 for a in usados if a in colhidos
                    for _p, f in pares(colhidos[a])
                    if f.get("class") == "ParticleEmitter")
    print("colhidos de UM lado só — a pasta `Effects` está DUPLICADA no arquivo,")
    print("e copiar os dois lados poria cada emissor em dobro dentro da Tool.")
    print("  %d molde(s) em uso, %d ParticleEmitter distinto(s)"
          % (len(usados), emissores))
    if faltando:
        print("  ⚠️  não achei: %s" % ", ".join(faltando))
        return 1
    print("")

    saida = nova_raiz()
    for indice, dados in enumerate(CONJUNTO, 1):
        marca = "%02d" % indice
        tool, postos, cortes, proprio = montar(dados, marca, colhidos)
        saida.append(tool)
        print("%-20s handle:%-9s moldes: %s"
              % (dados[0], "origem" if proprio else "invisível",
                 ", ".join(postos) or "—"))
        for corte in cortes:
            print("%-20s   ⚠️  encolhido %s" % ("", corte))
        if dados[5]:
            print("%-20s   CUTSCENE" % "")

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
    print("")
    print("%s  —  %d bytes · 7 Tools · %d SharedString"
          % (os.path.relpath(DESTINO, RAIZ), os.path.getsize(DESTINO),
             len(citadas)))
    if penduradas:
        print("   ⚠️  %d SharedString PENDURADA" % len(penduradas))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
