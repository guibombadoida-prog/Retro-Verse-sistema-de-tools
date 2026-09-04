#!/usr/bin/env python3
"""
clonar_tool.py — Retro-Verse / Studios

Clona Tools de um `.rbxmx` de origem **sem remontar nada**.

    python3 FERRAMENTAS/clonar_tool.py extrair <origem.rbxmx>
    python3 FERRAMENTAS/clonar_tool.py montar  <origem.rbxmx> <destino.rbxmx>

POR QUE ESTA FERRAMENTA EXISTE, E POR QUE ELA NÃO É O montar_rbxmx.py

    O `montar_rbxmx.py` CONSTRÓI a Tool: Handle com primitivas, Values, SFX,
    emissores. Serve para Tool autoral, nascida aqui.

    Não serve para Tool que CHEGA pronta. Usá-lo para isso foi o erro da leva
    anterior: o modelo vinha com `SpecialMesh` próprio e eu remontei um escudo
    em código. Passava em todo verificador e entregava outra coisa.

    Aqui a regra é outra: **o `.rbxmx` de origem é a verdade**. Handle, Mesh,
    Model, Sound, Value, hierarquia — nada disso é tocado. A única coisa que
    esta ferramenta escreve de volta é o `Source` dos scripts, e só dos que
    existirem como `.lua` na pasta da Tool.

    extrair  origem .rbxmx  →  Tools/<Nome>/*.lua   (para revisar e versionar)
    montar   os .lua        →  .rbxmx, com TUDO O MAIS vindo da origem intacto
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")

# ToolTip por Tool. O modelo de origem veio com o campo vazio nas sete, e
# ToolTip vazio é o texto que o jogador lê na mochila — some a legenda inteira.
#
# Só é escrito quando a origem NÃO trouxe um. Se o modelo declarar o seu, o dele
# vence: aqui a origem continua sendo a verdade.
TOOLTIPS = {
    "Salvador":           "Ergue a barreira e devolve o golpe a quem o deu",
    "Proteção":           "Três escudos em órbita, e nenhum flanco aberto",
    "Escudo Skate":       "O escudo vira prancha — atropela quem estiver no caminho",
    "Escudo Bumerangue":  "Arremessa e recolhe; segure para carregar o giro",
    "Escudo Bloqueador":  "Fecha a guarda e absorve o que vier de frente",
    "Escudo Cyclone":     "Gira até o vento levantar quem chegar perto",
    "Escudo Partido":     "Quebra o escudo no impacto — cada caco é um golpe",
}


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


def nome_arquivo(caminho):
    """Nome de arquivo estável a partir do caminho do script dentro da Tool."""
    limpo = re.sub(r"[^\w/]", "_", caminho)
    return limpo.replace("/", "__") + ".lua"


def percorrer(item, caminho=""):
    """Emite (item, caminho) de todo script descendente."""
    nome = texto(item, "Name") or item.get("class")
    atual = (caminho + "/" + nome) if caminho else nome
    if item.get("class") in CLASSES_SCRIPT:
        yield item, atual
    for filho in item.findall("Item"):
        for par in percorrer(filho, atual):
            yield par


def tools_de(caminho):
    raiz = ET.parse(caminho).getroot()
    return raiz, [i for i in raiz.findall("Item") if i.get("class") == "Tool"]


def envolver_cdata(texto_xml):
    def trocar(m):
        corpo = m.group(1)
        corpo = (corpo.replace("&lt;", "<").replace("&gt;", ">")
                      .replace("&quot;", '"').replace("&#10;", "\n")
                      .replace("&amp;", "&"))
        return '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % corpo

    return re.sub(r'<ProtectedString name="Source">(.*?)</ProtectedString>',
                  trocar, texto_xml, flags=re.S)


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


def tabela_compartilhada(caminhos):
    """md5 -> conteúdo, lido do <SharedStrings> dos arquivos de origem."""
    tabela = {}
    for caminho in caminhos:
        if not caminho or not os.path.exists(caminho):
            continue
        raiz = ET.parse(caminho).getroot()
        for e in raiz.iter("SharedString"):
            if e.get("md5"):
                tabela[e.get("md5")] = e.text or ""
    return tabela


def fechar_compartilhadas(raiz, tabela):
    """
    Emite o <SharedStrings> com TODA md5 que os Items citam.

    ISTO É O QUE FAZIA O STUDIO DIZER "ARQUIVO CORROMPIDO".

    A instância cita a string em `<SharedString name="Tags">md5</SharedString>`,
    e a tabela que resolve essa md5 é um bloco `<SharedStrings>` **irmão** dos
    `<Item>`, não descendente. Copiando só os Item para uma raiz nova, o bloco
    fica para trás e a citação fica pendurada — o arquivo abre como XML válido
    e o Studio recusa.

    Devolve as md5 que os Items citam e a tabela não tem (não deve sobrar nenhuma).
    """
    citadas = [t for t in sorted({(e.text or "").strip()
                                  for e in raiz.iter("SharedString")
                                  if e.get("name")}) if t]
    if not citadas:
        return []

    bloco = ET.SubElement(raiz, "SharedStrings")
    faltando = []
    for md5 in citadas:
        if md5 not in tabela:
            faltando.append(md5)
            continue
        ET.SubElement(bloco, "SharedString", {"md5": md5}).text = tabela[md5]
    return faltando


def escrever(raiz, destino, tabela=None):
    faltando = fechar_compartilhadas(raiz, tabela or {})
    ET.ElementTree(raiz).write(destino, encoding="utf-8", xml_declaration=False)
    with open(destino, encoding="utf-8") as f:
        conteudo = f.read()
    with open(destino, "w", encoding="utf-8") as f:
        f.write(envolver_cdata(conteudo))
    return faltando


def extrair(origem):
    raiz, tools = tools_de(origem)
    if not tools:
        print("nenhuma Tool na raiz de %s" % origem)
        return 1

    for tool in tools:
        nome = texto(tool, "Name")
        pasta = os.path.join(TOOLS, nome)
        os.makedirs(pasta, exist_ok=True)

        n = 0
        for item, caminho in percorrer(tool):
            fonte = texto(item, "Source")
            if fonte is None:
                continue
            # o caminho relativo à Tool, para o arquivo bater na volta
            relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
            destino = os.path.join(pasta, nome_arquivo(relativo))
            with open(destino, "w", encoding="utf-8") as f:
                f.write(fonte)
            n = n + 1

        # a origem fica guardada: é ela que o `montar` usa como base — e leva o
        # <SharedStrings> junto, senão a cópia já nasce com citação pendurada
        base = os.path.join(pasta, "_ORIGEM.rbxmx")
        sub = nova_raiz()
        sub.append(tool)
        faltando = escrever(sub, base, tabela_compartilhada([origem]))

        aviso = ""
        if faltando:
            aviso = "   ⚠️  %d SharedString sem tabela" % len(faltando)
        print("%-22s %2d scripts  →  Tools/%s/%s" % (nome, n, nome, aviso))
    return 0


PACK_VFX = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Stella_VFX_Addon",
                        "VFX", "PACK_VFX.rbxmx")


DEPOSITO_LUA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "dados", "DepositoVFX.lua")


def enxertar_deposito(tool, nome_tool):
    """
    Põe `DepositoVFX` (ModuleScript) e `ChaveVFX` (StringValue) dentro da Tool.

    REGRA Nº 2. O módulo é filho da Tool como o `Poses` e o `R6CFrameAnimator` —
    a Regra nº 1 continua satisfeita, ele veio dentro dela.

    A CHAVE É DO MODELO, NÃO DA INSTÂNCIA. Duas pessoas com a mesma Tool
    compartilham uma pasta no depósito; se a chave fosse por instância, o
    depósito teria oito cópias do mesmo `MeshPart` e não teríamos resolvido o
    problema que a regra existe para resolver.

    Nome de Tool não serve sozinho — dois modelos podem se chamar `Aura` —,
    então a chave é o nome normalizado, e o verificador cobra que seja única.

    Idempotente: montar duas vezes não empilha dois módulos.
    """
    if not os.path.exists(DEPOSITO_LUA):
        return 0

    for filho in list(tool.findall("Item")):
        if texto(filho, "Name") in ("DepositoVFX", "ChaveVFX"):
            tool.remove(filho)

    fonte = open(DEPOSITO_LUA, encoding="utf-8").read()
    modulo = ET.SubElement(tool, "Item", {"class": "ModuleScript",
                                          "referent": "RV_DEP_%s" % abs(hash(nome_tool))})
    props = ET.SubElement(modulo, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = "DepositoVFX"
    ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = fonte

    chave = re.sub(r"[^A-Za-z0-9]+", "_", nome_tool).strip("_")
    valor = ET.SubElement(tool, "Item", {"class": "StringValue",
                                         "referent": "RV_CHV_%s" % abs(hash(nome_tool))})
    props = ET.SubElement(valor, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = "ChaveVFX"
    ET.SubElement(props, "string", {"name": "Value"}).text = chave
    return 1


def enxertar_pack(tool):
    """
    Copia o pack de VFX do Acervo PARA DENTRO do VFXModule da Tool.

    Regra nº 1: o efeito é filho da Tool, ponto. O Acervo é prateleira de
    edição — o material sai de lá e entra na Tool na montagem, nunca é lido
    de lá em runtime.

    Devolve quantos efeitos entraram.
    """
    if not os.path.exists(PACK_VFX):
        return 0

    modulo = None
    for item, _caminho in percorrer(tool):
        if texto(item, "Name") == "VFXModule":
            modulo = item
            break
    if modulo is None:
        return 0

    # Enxerto é idempotente: montar duas vezes não empilha dois packs.
    for filho in list(modulo.findall("Item")):
        if texto(filho, "Name") == "Pack":
            modulo.remove(filho)

    pack = ET.parse(PACK_VFX).getroot().find("Item")
    if pack is None:
        return 0

    # referent tem de ser único dentro do arquivo montado: dois iguais fazem o
    # Studio religar propriedade no objeto errado. Como o mesmo pack entra em
    # 7 Tools, cada cópia ganha um sufixo.
    #
    # E renomear o referent SEM renomear os <Ref> que apontam para ele deixa o
    # ponteiro pendurado — foi o que aconteceu com o `PrimaryPart` do Model do
    # Smoky_Explosion. Os dois lados mudam juntos, sempre.
    enxerto = ET.fromstring(ET.tostring(pack))
    marca = texto(tool, "Name").replace(" ", "")

    renomeado = {}
    for no in enxerto.iter("Item"):
        ref = no.get("referent")
        if ref:
            novo = "%s_%s" % (ref, marca)
            renomeado[ref] = novo
            no.set("referent", novo)

    for no in enxerto.iter("Item"):
        props = no.find("Properties")
        if props is None:
            continue
        for e in props:
            if e.tag != "Ref":
                continue
            alvo = (e.text or "").strip()
            if alvo in renomeado:
                e.text = renomeado[alvo]

    modulo.append(enxerto)
    return len([i for i in enxerto.findall("Item")
                if i.get("class") == "ModuleScript"])


def cliente_para_runcontext(tool):
    """
    `Client` como LocalScript vira `Script` com RunContext = Client.

    POR QUE ISSO PRECISA ACONTECER NA MONTAGEM

        LocalScript dentro de uma Tool só roda para o jogador cujo Character a
        contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em
        todo mundo — mas o único ouvinte que existe é o de quem está segurando.
        Era por isso que o VFX aparecia só para o portador.

        As Bombas, o Xester e o collector já nasceram com `RunContext = 2`
        porque o `preparar_*` de cada um o escreve. Os 7 Escudos NÃO: eles
        vieram do clonador, e o `_ORIGEM.rbxmx` deles guarda o `Client` como
        LocalScript desde antes do conserto. Remontar não bastava — o defeito
        estava na base, não no `.lua`.

        Conferido antes de escrever esta função: `Bomba Nuclear` e
        `Xester Teleporte` já saíam com `Script` + RunContext 2, e os sete
        Escudos ainda saíam com `LocalScript`.
    """
    trocados = 0
    for item, _caminho in percorrer(tool):
        if item.get("class") != "LocalScript":
            continue
        if texto(item, "Name") != "Client":
            continue
        item.set("class", "Script")
        campo = prop(item, "RunContext")
        if campo is None:
            campo = ET.SubElement(item.find("Properties"), "token",
                                  {"name": "RunContext"})
        campo.tag = "token"
        campo.text = "2"
        trocados = trocados + 1
    return trocados


#: As duas propriedades que transformam um script em FRONTEIRA DE SANDBOX.
CAMPOS_SANDBOX = ("DefinesCapabilities", "Capabilities")


def tirar_sandbox(tool):
    """Tira a fronteira de capabilities de todo script dentro da Tool.

    O QUE ISTO CONSERTA, E COMO ELE APARECIA

        The current thread cannot require 'Poses' since 'Poses' has the
        Sandboxed property set to false but the calling thread is sandboxed
        Script 'Players.<jogador>.Backpack.A arma.Aarma_Server_V1', Line 21

    `DefinesCapabilities = true` num script faz a thread dele rodar SANDBOXADA.
    Thread sandboxada só pode dar `require` em ModuleScript que também seja
    sandboxado — e o `Poses`, o `R6CFrameAnimator` e o `VFXModule` nascem aqui,
    limpos, sem essa marca. O `require` da linha 21 morre, e a Tool inteira
    morre com ele: sem Poses não há animação, sem animação não há beat, sem beat
    não há dano.

    DE ONDE VEIO

        Do próprio modelo de origem. Este montador é fiel por desenho — ele
        reescreve o `Source` e **não toca em mais nada do Item**, que é o que
        preserva Handle, Mesh e Sound. Só que `DefinesCapabilities` viaja no
        Item, não no Source: o código passou a ser nosso e a fronteira de
        sandbox continuou sendo do autor original.

        `A arma` era a única Tool com o SERVER marcado assim, e por isso a única
        que morria. Os 10 módulos do pack Stella carregam a mesma marca nas 73
        Tools — ali ela não estourava, mas limitava o que o pack podia fazer.

    POR QUE TIRAR, E NÃO MARCAR O POSES COMO SANDBOXED

        Porque a fronteira não é nossa. Todo o Lua entregue foi escrito neste
        repositório e roda em Tool comum; herdar um sandbox de um script que já
        foi substituído é carregar uma restrição sem dono. Tirar devolve o
        comportamento padrão, que é o que as outras 72 Tools já usavam.
    """
    limpos = 0
    for item, _caminho in percorrer(tool):
        if item.get("class") not in CLASSES_SCRIPT:
            continue
        propriedades = item.find("Properties")
        if propriedades is None:
            continue
        tirou = False
        for campo in list(propriedades):
            if campo.get("name") in CAMPOS_SANDBOX:
                propriedades.remove(campo)
                tirou = True
        if tirou:
            limpos = limpos + 1
    return limpos


def montar(nomes, destino):
    """
    Monta o .rbxmx de entrega a partir dos _ORIGEM.rbxmx de cada Tool,
    reescrevendo SÓ o Source dos scripts que existem como .lua na pasta, e
    enxertando o pack de VFX do Acervo dentro do VFXModule.

    Sai um arquivo por Tool (REGRA_ENTREGA_RBXM: uma Tool, um arquivo, pronto
    para arrastar) e mais o conjunto com as Tools do modelo todo.
    """
    raiz = nova_raiz()
    trocados, mantidos, enxertados, depositos, legendadas, convertidos = 0, 0, 0, 0, 0, 0
    dessandbox = 0
    penduradas = []

    # A tabela de SharedStrings vem das DUAS fontes: o _ORIGEM de cada Tool e o
    # pack do Acervo. Sem ela o Studio recusa o arquivo como corrompido.
    fontes = [os.path.join(TOOLS, n, "_ORIGEM.rbxmx") for n in nomes]
    fontes.append(PACK_VFX)
    tabela = tabela_compartilhada(fontes)
    for nome in nomes:
        pasta = os.path.join(TOOLS, nome)
        base = os.path.join(pasta, "_ORIGEM.rbxmx")
        if not os.path.exists(base):
            print("sem _ORIGEM.rbxmx em Tools/%s — rode `extrair` antes" % nome)
            return 1

        sub = ET.parse(base).getroot()
        tool = sub.find("Item")

        convertidos = convertidos + cliente_para_runcontext(tool)
        dessandbox = dessandbox + tirar_sandbox(tool)

        if not (texto(tool, "ToolTip") or "").strip() and nome in TOOLTIPS:
            campo = prop(tool, "ToolTip")
            if campo is None:
                campo = ET.SubElement(tool.find("Properties"), "string")
                campo.set("name", "ToolTip")
            campo.text = TOOLTIPS[nome]
            legendadas = legendadas + 1

        for item, caminho in percorrer(tool):
            relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
            arquivo = os.path.join(pasta, nome_arquivo(relativo))
            campo = prop(item, "Source")
            if campo is None:
                continue
            if os.path.exists(arquivo):
                with open(arquivo, encoding="utf-8") as f:
                    campo.text = f.read()
                trocados = trocados + 1
            else:
                mantidos = mantidos + 1

        enxertados = enxertados + enxertar_pack(tool)
        depositos = depositos + enxertar_deposito(tool, nome)

        # Uma Tool, um arquivo — é assim que ela chega no Studio.
        sozinha = nova_raiz()
        sozinha.append(tool)
        individual = os.path.join(pasta, "%s.rbxmx" % nome)
        penduradas.extend(escrever(sozinha, individual, tabela))

        raiz.append(tool)

    penduradas.extend(escrever(raiz, destino, tabela))

    print("%s  —  %d bytes" % (os.path.relpath(destino, RAIZ),
                               os.path.getsize(destino)))
    print("   %d arquivo(s) individual(is) em Tools/<Nome>/<Nome>.rbxmx" % len(nomes))
    print("   %d script(s) vindos do .lua, %d mantidos como na origem"
          % (trocados, mantidos))
    print("   %d efeito(s) do pack enxertados DENTRO das Tools (Regra nº 1)"
          % enxertados)
    print("   %d DepositoVFX + ChaveVFX dentro das Tools (Regra nº 2)"
          % depositos)
    print("   %d ToolTip preenchido(s) — a origem veio com o campo vazio"
          % legendadas)
    print("   %d Client LocalScript -> Script RunContext=Client (visibilidade)"
          % convertidos)
    print("   %d script(s) sem a fronteira de sandbox (DefinesCapabilities)"
          % dessandbox)
    print("   %d SharedString na tabela, 0 pendurada" % len(tabela)
          if not penduradas else
          "   ⚠️  %d SharedString PENDURADA: %s"
          % (len(set(penduradas)), ", ".join(sorted(set(penduradas)))))
    print("   Handle, Mesh, Model, Sound e Value: intactos, da origem")
    return 1 if penduradas else 0


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    acao = sys.argv[1]
    if acao == "extrair":
        return extrair(sys.argv[2])
    if acao == "montar":
        origem = sys.argv[2]
        destino = sys.argv[3] if len(sys.argv) > 3 else None
        _, tools = tools_de(origem)
        nomes = [texto(t, "Name") for t in tools]
        return montar(nomes, destino or os.path.join(TOOLS, "Conjunto.rbxmx"))
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
