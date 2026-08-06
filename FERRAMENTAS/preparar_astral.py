#!/usr/bin/env python3
"""
preparar_astral.py — Retro-Verse / Studios

Prepara a base de ASSETS do `AstralPeriastron` para as 5 Tools do conjunto.

    python3 FERRAMENTAS/preparar_astral.py

O QUE ESTA FERRAMENTA FAZ, E O QUE ELA NÃO FAZ

    NÃO toca em Handle, MeshPart, SpecialMesh, Sound, ParticleEmitter, Trail,
    Attachment, PointLight nem SurfaceGui. Toda a identidade visual da Tool
    vem da origem, intacta — é a mesma regra do clonar_tool.py.

    TIRA duas famílias, e as duas porque a regra proíbe:

      ScreenGui  — "efeito só no mundo 3D" (DIRETRIZES). A Astral_UI original
                   desenhava os cooldowns de Q/E/X na tela. Vai embora; quem
                   avisa recarga é o próprio efeito no mundo.
      Animation  — REGRA_ANIMACAO_R6: pose é tabela CFrame sob o
                   R6CFrameAnimator, nunca `Animation` + `LoadAnimation`.

    TIRA também todo Script/LocalScript/ModuleScript da origem: os 4826
    linhas de código de terceiro não entram em Tool nenhuma. O que entra é
    código autoral, escrito contra as diretrizes, com os NÚMEROS do original
    preservados (dano 27/25/15, CD 1/1/60, alcance 20/200).

    SurfaceGui FICA: é GUI no mundo 3D, na face de uma parte — não é ScreenGui.

    Sai um `Tools/<Nome>/_ORIGEM.rbxmx` por Tool do conjunto, cada um com o
    Name trocado e os referent com sufixo próprio (dois referent iguais no
    mesmo arquivo fazem o Studio religar propriedade no objeto errado).
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Astral_Peria", "astral_peria.rbxmx")

# As 5 Tools do conjunto. A primeira leva as habilidades ORIGINAIS; as outras
# quatro são clones com duas habilidades novas cada, no mesmo tema astral.
CONJUNTO = [
    # nome, tooltip, DamageClass, energia, recarga global, chave, tem cutscene
    ("Astral Periastron",
     "Golpe astral que semeia orbes. Q redireciona, E detona, X invoca o Pulsar.",
     "ASTRAL", 0, 0, "AstralPeriastron_Pulsar", False),
    ("Astral Nova",
     "Nova Estelar no golpe. X colapsa a estrela e puxa quem estiver perto.",
     "ASTRAL", 12, 18, "AstralNova_Colapso", False),
    ("Astral Cometa",
     "Cometa incandescente no golpe. X chama a Chuva Sideral.",
     "ASTRAL", 14, 22, "AstralCometa_Chuva", False),
    ("Astral Singularidade",
     "Horizonte de Eventos no golpe. X espaguetifica o alvo marcado.",
     "ASTRAL", 20, 45, "AstralSingularidade_Espaguete", True),
    ("Astral Constelacao",
     "Traço Sideral marca quem for atingido. X liga as marcas e sentencia.",
     "ASTRAL", 16, 30, "AstralConstelacao_Sentenca", False),
]

# Classes que a regra não deixa entrar em Tool
PROIBIDAS = ("ScreenGui", "Animation")
CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")

# Peças de GUI de tela: caem junto com a ScreenGui que as continha
GUI_DE_TELA = ("Frame", "UICorner", "UIStroke", "UIGradient", "TextLabel",
               "ImageLabel", "TextButton", "ImageButton", "UIListLayout",
               "UIPadding", "UIAspectRatioConstraint", "UIScale")

# O que vale resgatar de dentro de um script antes de podá-lo: é o que se VÊ
# e se OUVE. Parâmetro de script (NumberValue, ObjectValue) não vem — quem
# guarda número aqui é o bloco CFG do código autoral.
VISUAIS = ("MeshPart", "Part", "UnionOperation", "WedgePart", "SpecialMesh",
           "ParticleEmitter", "Trail", "Beam", "Attachment", "PointLight",
           "SpotLight", "SurfaceLight", "Highlight", "Sound", "SoundGroup",
           "ReverbSoundEffect", "EqualizerSoundEffect", "SurfaceGui", "Decal",
           "Texture", "Smoke", "Fire", "Sparkles")

# Molde guardado dentro da Tool não pode renderizar: Tool equipada está em
# workspace. Mesma regra do pack de VFX — apaga o molde, acende o clone.
RENDERIZAM = ("Part", "MeshPart", "UnionOperation", "WedgePart", "Decal",
              "Texture")
LIGAVEIS = ("ParticleEmitter", "Trail", "Beam", "Smoke", "Fire", "Sparkles")


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
    return u.text if u is not None else e.text


def definir_nome(item, valor):
    e = prop(item, "Name")
    if e is None:
        props = item.find("Properties")
        if props is None:
            props = ET.SubElement(item, "Properties")
        ET.SubElement(props, "string", {"name": "Name"}).text = valor
    else:
        e.text = valor


def som_morto(item):
    """Sound sem SoundId não toca nada — resgatar é carregar peso morto."""
    if item.get("class") != "Sound":
        return False
    e = prop(item, "SoundId")
    if e is None:
        return True
    u = e.find("url")
    valor = (u.text if u is not None else e.text) or ""
    return not valor.strip()


def podar_som_morto(item, removidos):
    for filho in list(item.findall("Item")):
        if som_morto(filho):
            removidos.append(("Sound(sem id)", texto(filho, "Name") or "?"))
            item.remove(filho)
            continue
        podar_som_morto(filho, removidos)
    return item


def tem_visual(item):
    """O subárvore contém algo que se vê ou se ouve?"""
    if item.get("class") in VISUAIS:
        return True
    for filho in item.findall("Item"):
        if tem_visual(filho):
            return True
    return False


def sem_scripts(item, removidos):
    """Tira Script/ScreenGui de dentro de um subárvore resgatado."""
    for filho in list(item.findall("Item")):
        classe = filho.get("class")
        if classe in CLASSES_SCRIPT or classe in PROIBIDAS:
            removidos.append((classe, texto(filho, "Name") or classe))
            item.remove(filho)
            continue
        sem_scripts(filho, removidos)
    return item


def podar(item, removidos, resgatados):
    """
    Remove o que a regra proíbe — RESGATANDO antes o que se vê e se ouve.

    O modelo guarda Pulsar, OrbCore, OrbOutline, as pastas de som e as de
    partícula DENTRO dos scripts. Podar o script levaria junto a identidade
    visual inteira das habilidades. Então: antes de tirar um script, o que
    for visual sai de dentro dele e vai para `Tool/Moldes/`.
    """
    for filho in list(item.findall("Item")):
        classe = filho.get("class")
        nome = texto(filho, "Name") or classe

        if classe in CLASSES_SCRIPT:
            for neto in list(filho.findall("Item")):
                if neto.get("class") in CLASSES_SCRIPT:
                    continue
                if neto.get("class") in PROIBIDAS or neto.get("class") in GUI_DE_TELA:
                    continue
                if som_morto(neto):
                    removidos.append(("Sound(sem id)", texto(neto, "Name") or "?"))
                    continue
                if tem_visual(neto):
                    resgatados.append(
                        podar_som_morto(sem_scripts(neto, removidos), removidos))
                    filho.remove(neto)
            removidos.append((classe, nome))
            item.remove(filho)
            continue

        if classe in PROIBIDAS:
            # tirar a ScreenGui já leva Frame, TextLabel e o resto junto
            removidos.append((classe, nome))
            item.remove(filho)
            continue

        podar(filho, removidos, resgatados)

    return item


def apagar_molde(item, registro, caminho=""):
    """Guarda o molde apagado e devolve [(caminho, transp, enabled)]."""
    for filho in item.findall("Item"):
        nome = texto(filho, "Name") or filho.get("class")
        abaixo = (caminho + "/" + nome) if caminho else nome
        classe = filho.get("class")

        if classe in RENDERIZAM:
            atual = texto(filho, "Transparency") or "0"
            registro.append((abaixo, atual, None))
            definir(filho, "float", "Transparency", "1")
        elif classe in LIGAVEIS:
            atual = texto(filho, "Enabled") or "true"
            registro.append((abaixo, None, atual))
            definir(filho, "bool", "Enabled", "false")

        apagar_molde(filho, registro, abaixo)
    return registro


def definir(item, tag, nome, valor):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    for e in props:
        if e.get("name") == nome:
            e.text = valor
            return
    ET.SubElement(props, tag, {"name": nome}).text = valor


def novo_item(pai, classe, nome, referent):
    item = ET.SubElement(pai, "Item", {"class": classe, "referent": referent})
    props = ET.SubElement(item, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = nome
    return item, props


def equipar_tool(tool, nome, tooltip, classe_dano, energia, recarga, chave,
                 cutscene):
    """
    Põe na Tool o que as diretrizes exigem e a origem não tinha:
    scripts autorais (vazios — o Source vem do .lua), Remotes e Values.
    """
    marca = nome.replace(" ", "")

    # ToolTip e as duas propriedades que o verificador cobra
    definir(tool, "string", "ToolTip", tooltip)
    definir(tool, "bool", "CanBeDropped", "false")
    definir(tool, "bool", "RequiresHandle", "true")

    # A origem manda a posição do mouse por RemoteFunction. RemoteFunction do
    # cliente para o servidor pendura a thread do servidor se o cliente não
    # responder — vira vetor de trava. Sai; a mira viaja como dado no
    # AcaoRemote, que é RemoteEvent e não espera resposta.
    for filho in list(tool.findall("Item")):
        if filho.get("class") == "RemoteFunction":
            tool.remove(filho)

    existentes = {texto(f, "Name") for f in tool.findall("Item")}

    for remoto in ("VFXRemote", "AcaoRemote"):
        if remoto not in existentes:
            novo_item(tool, "RemoteEvent", remoto, "RV_%s_%s" % (remoto, marca))
    if cutscene and "CutsceneRemote" not in existentes:
        novo_item(tool, "RemoteEvent", "CutsceneRemote", "RV_Cut_%s" % marca)

    # A Tool DECLARA o que é; quem aplica regra é o Núcleo (§12.4)
    _i, props = novo_item(tool, "StringValue", "DamageClass",
                          "RV_DC_%s" % marca)
    ET.SubElement(props, "string", {"name": "Value"}).text = classe_dano
    _i, props = novo_item(tool, "StringValue", "ChaveRecarga",
                          "RV_CR_%s" % marca)
    ET.SubElement(props, "string", {"name": "Value"}).text = chave
    _i, props = novo_item(tool, "NumberValue", "EnergyCost",
                          "RV_EC_%s" % marca)
    ET.SubElement(props, "float", {"name": "Value"}).text = str(energia)
    _i, props = novo_item(tool, "NumberValue", "RecargaGlobal",
                          "RV_RG_%s" % marca)
    ET.SubElement(props, "float", {"name": "Value"}).text = str(recarga)

    # Os scripts nascem vazios: o Source vem do .lua, no clonar_tool.py montar
    scripts = [
        ("Script", "%s_Server_V1" % nome),
        ("LocalScript", "Client"),
        ("ModuleScript", "Poses"),
        ("ModuleScript", "R6CFrameAnimator"),
        ("ModuleScript", "VFXModule"),
    ]
    if cutscene:
        scripts.append(("LocalScript", "CutsceneCam"))
    for classe, alvo in scripts:
        item, props = novo_item(tool, classe, alvo,
                                "RV_%s_%s" % (alvo.replace(" ", ""), marca))
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = ""

    return [a for _c, a in scripts]


def limpar_pastas_vazias(item, removidos):
    for filho in list(item.findall("Item")):
        if limpar_pastas_vazias(filho, removidos) is None:
            removidos.append((filho.get("class"), texto(filho, "Name") or "?"))
            item.remove(filho)
    if item.get("class") == "Folder" and not item.findall("Item"):
        return None
    return item


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
    tools = [i for i in fonte.findall("Item") if i.get("class") == "Tool"]
    if len(tools) != 1:
        print("esperava 1 Tool na origem, achei %d" % len(tools))
        return 1
    base = tools[0]

    tabela = {}
    for e in fonte.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text or ""

    print("PREPARAÇÃO DA BASE — AstralPeriastron")
    print("")

    for indice, dados in enumerate(CONJUNTO):
        nome, tooltip, classe_dano, energia, recarga, chave, cutscene = dados
        copia = ET.fromstring(ET.tostring(base))

        removidos, resgatados = [], []
        podar(copia, removidos, resgatados)
        limpar_pastas_vazias(copia, removidos)
        definir_nome(copia, nome)

        # O resgatado vira `Tool/Moldes/` — dentro da Tool, como manda a
        # Regra nº 1, e guardado APAGADO, como manda o molde de VFX.
        moldes = ET.Element("Item", {"class": "Folder",
                                     "referent": "RVMOLDES"})
        props = ET.SubElement(moldes, "Properties")
        ET.SubElement(props, "string", {"name": "Name"}).text = "Moldes"
        usados = set()
        for peca in resgatados:
            rotulo = texto(peca, "Name") or peca.get("class")
            final, n = rotulo, 2
            while final in usados:
                final, n = "%s_%d" % (base, n), n + 1
            usados.add(final)
            definir_nome(peca, final)
            moldes.append(peca)
        copia.append(moldes)

        registro = apagar_molde(moldes, [])
        criados = equipar_tool(copia, nome, tooltip, classe_dano, energia,
                               recarga, chave, cutscene)

        marca = nome.replace(" ", "")
        renomeado = {}
        for no in copia.iter("Item"):
            ref = no.get("referent")
            if ref:
                novo = "%s_%s" % (ref, marca)
                renomeado[ref] = novo
                no.set("referent", novo)
        for no in copia.iter("Item"):
            props = no.find("Properties")
            if props is None:
                continue
            for e in props:
                if e.tag == "Ref" and (e.text or "").strip() in renomeado:
                    e.text = renomeado[(e.text or "").strip()]

        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)

        raiz = nova_raiz()
        raiz.append(copia)

        citadas = [t for t in sorted({(e.text or "").strip()
                                      for e in raiz.iter("SharedString")
                                      if e.get("name")}) if t]
        if citadas:
            bloco = ET.SubElement(raiz, "SharedStrings")
            for md5 in citadas:
                ET.SubElement(bloco, "SharedString",
                              {"md5": md5}).text = tabela.get(md5, "")

        destino = os.path.join(pasta, "_ORIGEM.rbxmx")
        ET.ElementTree(raiz).write(destino, encoding="utf-8",
                                   xml_declaration=False)

        if indice == 0:
            contagem = {}
            for classe, _n in removidos:
                contagem[classe] = contagem.get(classe, 0) + 1
            print("  Removido (a regra proíbe), por Tool:")
            for classe in sorted(contagem):
                print("    %-14s %d" % (classe, contagem[classe]))
            print("")
            restante = {}
            for no in copia.iter("Item"):
                c = no.get("class")
                restante[c] = restante.get(c, 0) + 1
            print("  Mantido da origem, intacto:")
            for c in sorted(restante):
                print("    %-18s %d" % (c, restante[c]))
            print("")

        print("  %-24s → Tools/%s/  (%s)"
              % (nome, nome, ", ".join(criados)))

        if indice == 0:
            guardado = registro

    print("")
    print("%d Tool(s) preparada(s). Nenhum script da origem entrou." % len(CONJUNTO))
    print("")
    print("TABELA DE MOLDES — colar no VFXModule (Moldes/<caminho>)")
    print("local MOLDES = {")
    for caminho, transp, ligado in guardado:
        campos = []
        if transp is not None:
            campos.append("t = %s" % transp)
        if ligado is not None:
            campos.append("e = %s" % ligado)
        print('\t["%s"] = { %s },' % (caminho, ", ".join(campos)))
    print("}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
