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


def montar(nomes, destino):
    """
    Monta o .rbxmx de entrega a partir dos _ORIGEM.rbxmx de cada Tool,
    reescrevendo SÓ o Source dos scripts que existem como .lua na pasta, e
    enxertando o pack de VFX do Acervo dentro do VFXModule.

    Sai um arquivo por Tool (REGRA_ENTREGA_RBXM: uma Tool, um arquivo, pronto
    para arrastar) e mais o conjunto com as Tools do modelo todo.
    """
    raiz = nova_raiz()
    trocados, mantidos, enxertados, legendadas, convertidos = 0, 0, 0, 0, 0
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
    print("   %d ToolTip preenchido(s) — a origem veio com o campo vazio"
          % legendadas)
    print("   %d Client LocalScript -> Script RunContext=Client (visibilidade)"
          % convertidos)
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
