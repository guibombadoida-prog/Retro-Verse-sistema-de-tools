#!/usr/bin/env python3
"""
verificar_rbxmx.py — Retro-Verse / Studios

Confere que cada .rbxmx entregue é uma Tool conforme e AUTOCONTIDA.

    python3 TESTES/verificar_rbxmx.py

Sai com 1 se qualquer Tool falhar. Rodar depois de FERRAMENTAS/montar_rbxmx.py
e antes de fechar entrega.

O que confere:
  1. O XML abre e a raiz é uma Tool
  2. CanBeDropped = false · RequiresHandle = true · ToolTip preenchido
  3. Existe um Handle, com esse nome exato
  4. DamageClass declarado (§12.4) — sem ele, bônus por classe fica inerte
  5. Todo script exigido pelo §12.10 está presente, com o nome de objeto certo
  6. A fonte embutida é BYTE A BYTE igual ao .lua do repositório
  7. VFXRemote presente; AcaoRemote só onde há habilidade Extra
  8. Todo Sound citado pelo Server Script existe dentro de Tool/SFX
  9. Todo VFX transmitido existe no VFXModule da própria Tool
 10. Nenhum script referencia depósito fora da Tool (Regra nº 1)
 11. Cutscene: CutsceneCam e CutsceneRemote andam juntos, ou nenhum dos dois
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
# Fonte única do pack de VFX que viaja DENTRO de cada Tool
PACK_ACERVO = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Stella_VFX_Addon", "VFX")

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

PROIBIDOS = ("ReplicatedStorage", "ServerStorage", "ServerScriptService",
             "InsertService", "StarterGui", "StarterPack", "ACERVO")


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
    return (e.text or "") if e is not None else None


def filhos(item):
    return item.findall("Item")


def achar(item, classe=None, nome=None):
    for f in filhos(item):
        if classe and f.get("class") != classe:
            continue
        if nome and texto(f, "Name") != nome:
            continue
        return f
    return None


ABERTURA_LONGA = re.compile(r"--\[(=*)\[")


def sem_comentario(codigo):
    """
    Remove comentário de linha e de bloco, respeitando o NÍVEL do bloco longo:
    --[[ ]], --[=[ ]=], --[==[ ]==]. Ignorar o nível fazia documentação ser
    lida como código.
    """
    saida, nivel = [], None
    for linha in codigo.splitlines():
        if nivel is not None:
            fecha = "]" + nivel + "]"
            i = linha.find(fecha)
            if i >= 0:
                linha = linha[i + len(fecha):]
                nivel = None
            else:
                linha = ""
        if nivel is None:
            m = ABERTURA_LONGA.search(linha)
            if m:
                fecha = "]" + m.group(1) + "]"
                resto = linha[m.end():]
                i = resto.find(fecha)
                if i >= 0:
                    linha = linha[:m.start()] + resto[i + len(fecha):]
                else:
                    nivel = m.group(1)
                    linha = linha[:m.start()]
            linha = re.sub(r"--.*$", "", linha)
        saida.append(linha)
    return "\n".join(saida)


CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")


def percorrer_scripts(item, caminho=""):
    """(item, caminho) de todo script descendente. Espelha clonar_tool.py."""
    nome = texto(item, "Name") or item.get("class")
    atual = (caminho + "/" + nome) if caminho else nome
    if item.get("class") in CLASSES_SCRIPT:
        yield item, atual
    for filho in item.findall("Item"):
        for par in percorrer_scripts(filho, atual):
            yield par


def nome_arquivo(caminho):
    """Nome de arquivo estável a partir do caminho do script dentro da Tool.

    Tem de ser byte a byte a mesma regra de FERRAMENTAS/clonar_tool.py — se as
    duas divergirem, o verificador procura um arquivo que o clonador nunca
    escreveu e acusa divergência onde não há.
    """
    limpo = re.sub(r"[^\w/]", "_", caminho)
    return limpo.replace("/", "__") + ".lua"


def achar_servidor(fontes):
    """O Script de servidor da Tool, seja qual for o V do nome."""
    for nome_obj in sorted(fontes):
        if re.search(r"_Server_V\d+$", nome_obj):
            return nome_obj, fontes[nome_obj]
    return None, ""


def verificar(nome):
    pasta = os.path.join(TOOLS, nome)
    caminho = os.path.join(pasta, "%s.rbxmx" % nome)
    erros = []

    if not os.path.exists(caminho):
        return ["%s.rbxmx não existe — rode FERRAMENTAS/montar_rbxmx.py" % nome]

    try:
        raiz = ET.parse(caminho).getroot()
    except ET.ParseError as e:
        return ["XML inválido: %s" % e]

    tools = [i for i in raiz.findall("Item") if i.get("class") == "Tool"]
    if len(tools) != 1:
        return ["esperava exatamente 1 Tool na raiz, achei %d" % len(tools)]
    tool = tools[0]

    # 2. propriedades obrigatórias
    if texto(tool, "Name") != nome:
        erros.append("Name da Tool é %r, esperava %r" % (texto(tool, "Name"), nome))
    if texto(tool, "CanBeDropped") != "false":
        erros.append("CanBeDropped não é false")
    if texto(tool, "RequiresHandle") != "true":
        erros.append("RequiresHandle não é true")
    if not (texto(tool, "ToolTip") or "").strip():
        erros.append("ToolTip vazio")

    # 3. Handle
    handle = achar(tool, nome="Handle")
    if handle is None:
        erros.append("sem Handle (nome exato, case-sensitive)")
    elif handle.get("class") not in ("Part", "MeshPart", "UnionOperation"):
        erros.append("Handle é %s, esperava Part/MeshPart" % handle.get("class"))

    # 4. DamageClass
    dc = achar(tool, "StringValue", "DamageClass")
    if dc is None:
        erros.append("sem DamageClass — todo bônus por classe fica inerte (§12.4)")
    elif not (texto(dc, "Value") or "").strip():
        erros.append("DamageClass vazio")

    # 5 + 6. scripts, com fonte idêntica ao .lua do repositório
    #
    # A lista de scripts sai da PRÓPRIA Tool, não de uma convenção de nome.
    # Enquanto ela era fixa ("Poses_<Conjunto>_<Tool>_V1.lua"), só Tool nascida
    # aqui passava: Tool que CHEGA pronta traz os nomes dela, e o clonador grava
    # o .lua por caminho (FERRAMENTAS/clonar_tool.py, nome_arquivo). Verificador
    # que só entende o que ele mesmo montou não verifica o que a gente entrega.
    fontes = {}
    vistos = set()
    for item, caminho in percorrer_scripts(tool):
        nome_obj = caminho.rsplit("/", 1)[-1]
        relativo = caminho.split("/", 1)[1] if "/" in caminho else caminho
        arquivo = nome_arquivo(relativo)

        embutido = texto(item, "Source")
        if embutido is None:
            erros.append("%s sem Source" % nome_obj)
            continue
        fontes[nome_obj] = embutido

        # O pack de VFX vive DENTRO da Tool (Regra nº 1), mas a fonte dele é
        # uma só: a do Acervo, já conformada pelo §12.12.2. Comparar contra ela
        # é o que impede as 7 cópias de derivarem em silêncio.
        if relativo.startswith("VFXModule/Pack/"):
            no_disco = os.path.join(PACK_ACERVO, "%s.lua" % nome_obj)
            origem = "o pack do Acervo"
        else:
            no_disco = os.path.join(pasta, arquivo)
            origem = arquivo
            vistos.add(arquivo)

        if not os.path.exists(no_disco):
            erros.append("%s está no .rbxmx mas não há %s no repositório"
                         % (caminho, os.path.relpath(no_disco, RAIZ)))
            continue
        if embutido != open(no_disco, encoding="utf-8").read():
            erros.append("%s diverge de %s — remonte com clonar_tool.py"
                         % (caminho, origem))

    # O caminho inverso: .lua versionado que não entrou no .rbxmx é código morto
    # no repositório — alguém editou e o arquivo entregue não tem a edição.
    for arquivo in sorted(os.listdir(pasta)):
        if arquivo.endswith(".lua") and arquivo not in vistos:
            erros.append("%s existe no repositório mas não entrou no .rbxmx"
                         % arquivo)

    for obrigatorio in ("Client", "VFXModule", "Poses", "R6CFrameAnimator"):
        if obrigatorio not in fontes:
            erros.append("sem script chamado %r" % obrigatorio)

    # 7. remotes
    if achar(tool, "RemoteEvent", "VFXRemote") is None:
        erros.append("sem VFXRemote")

    tem_cam = os.path.exists(os.path.join(pasta, "CutsceneCam.lua"))
    tem_cut = achar(tool, "RemoteEvent", "CutsceneRemote") is not None
    if tem_cam and not tem_cut:
        erros.append("tem CutsceneCam, mas o CutsceneRemote não está na Tool")
    if tem_cut and not tem_cam:
        erros.append("CutsceneRemote presente sem CutsceneCam que o escute")

    nome_servidor, servidor = achar_servidor(fontes)
    if nome_servidor is None:
        erros.append("sem Script de servidor (<Nome>_Server_V<N>)")
    usa_acao = "AcaoRemote" in sem_comentario(servidor)
    tem_acao = achar(tool, "RemoteEvent", "AcaoRemote") is not None
    if usa_acao and not tem_acao:
        erros.append("o Server usa AcaoRemote, mas o RemoteEvent não está na Tool")
    if tem_acao and not usa_acao:
        erros.append("AcaoRemote presente sem habilidade Extra que o use")

    # 8. todo SFX citado existe dentro da Tool
    pasta_sfx = achar(tool, "Folder", "SFX")
    nomes_sfx = set()
    if pasta_sfx is not None:
        for s in filhos(pasta_sfx):
            if s.get("class") == "Sound":
                nomes_sfx.add(texto(s, "Name"))
                url = prop(s, "SoundId")
                alvo = url.find("url") if url is not None else None
                if alvo is None or not (alvo.text or "").startswith("rbxassetid://"):
                    erros.append("Sound %r sem SoundId" % texto(s, "Name"))

    citados = re.findall(r'SFX_\w+\s*=\s*"([^"]+)"', sem_comentario(servidor))
    for citado in citados:
        if citado not in nomes_sfx:
            erros.append("CFG cita o som %r, que não existe em Tool/SFX" % citado)

    # 9. todo VFX transmitido existe no VFXModule DA PRÓPRIA TOOL
    #
    # VFX.executar faz `local efeito = VFX[tipo]` e volta calado se não achar.
    # Um tipo herdado de outra Tool não quebra nada, não avisa nada, e
    # simplesmente não desenha — foi o que aconteceu com as 7 Tools de
    # gravidade, que pediam dois tipos herdados sem implementar nenhum deles.
    modulo = fontes.get("VFXModule", "")
    implementados = set(re.findall(r"function (?:VFX|Efeitos)\.([A-Z][A-Z0-9_]*)",
                                   modulo))
    # O servidor transmite por um wrapper local — `vfx("TIPO", {...})` — ou
    # direto pelo Remote. As duas formas contam: o que importa é o nome do tipo
    # que chega ao cliente.
    #
    # Nem tudo que trafega pelo VFXRemote é efeito: PARAR, CUTSCENE_INICIO e
    # CUTSCENE_FIM são CONTROLE, e o Client os intercepta antes de chegar ao
    # VFXModule. Cobrar implementação deles seria acusar o desenho correto — a
    # lista de controle sai do próprio Client, não de uma constante aqui.
    controle = set(re.findall(r'if\s+tipo\s*==\s*"([A-Z0-9_]+)"',
                              sem_comentario(fontes.get("Client", ""))))

    limpo_srv = sem_comentario(servidor)
    transmitidos = set(re.findall(r'\bvfx\(\s*"([A-Z0-9_]+)"', limpo_srv))
    transmitidos |= set(re.findall(r'transmitirVFX\(\s*\w+\s*,\s*"([A-Z0-9_]+)"',
                                   limpo_srv))
    transmitidos |= set(re.findall(
        r'VFXRemote:Fire(?:All)?Clients?\(\s*(?:\w+\s*,\s*)?"([A-Z0-9_]+)"',
        limpo_srv))
    for citado in sorted(transmitidos - controle):
        if citado not in implementados:
            erros.append("o Server transmite o VFX %r, que o VFXModule desta Tool "
                         "não implementa — o efeito não desenha e nada avisa" % citado)

    # 9b. Molde guardado não pode renderizar
    #
    # Tool equipada vive em workspace, e aí TODO BasePart descendente dela
    # aparece — inclusive os moldes de VFX, pendurados no personagem antes de
    # qualquer habilidade rodar. O molde fica guardado apagado e quem acende é
    # o clone, na execução (`_rv_clone`, ver FERRAMENTAS/conformar_pack_vfx.py).
    #
    # Apagar por propriedade, e não por script, é o que faz isso valer também
    # para os OUTROS jogadores: eles não rodam LocalScript da minha Tool.
    RENDERIZAM = ("Part", "MeshPart", "UnionOperation", "WedgePart",
                  "TrussPart", "CornerWedgePart", "Decal", "Texture")
    LIGAVEIS = ("ParticleEmitter", "Trail", "Beam")

    def moldes(item, dentro_de_modulo, caminho):
        for filho in filhos(item):
            nome = texto(filho, "Name") or filho.get("class")
            abaixo = (caminho + "/" + nome) if caminho else nome
            classe = filho.get("class")
            se_molde = dentro_de_modulo or classe == "ModuleScript"

            if dentro_de_modulo and classe in RENDERIZAM:
                if (texto(filho, "Transparency") or "0") != "1":
                    erros.append("molde %s renderiza dentro da Tool "
                                 "(Transparency %s) — apareceria pendurado no "
                                 "personagem ao equipar"
                                 % (abaixo, texto(filho, "Transparency") or "0"))
            if dentro_de_modulo and classe in LIGAVEIS:
                if (texto(filho, "Enabled") or "true") != "false":
                    erros.append("molde %s está com Enabled ligado dentro da "
                                 "Tool — emitiria sem habilidade nenhuma" % abaixo)

            moldes(filho, se_molde, abaixo)

    moldes(tool, False, "")

    # 10. Regra nº 1 — sem ressalva
    for nome_obj, codigo in fontes.items():
        limpo = sem_comentario(codigo)
        for termo in PROIBIDOS:
            if termo in limpo:
                erros.append("%s referencia %s — fora da Tool (Regra nº 1)"
                             % (nome_obj, termo))

    return erros


# Um conjunto por MODELO de origem, não um arquivo com o repositório inteiro.
CONJUNTOS = [
    ("Escudos_7_Tools.rbxmx", "Danilo_Escudos_V4", [
        "Salvador",
        "Proteção",
        "Escudo Skate",
        "Escudo Bumerangue",
        "Escudo Bloqueador",
        "Escudo Cyclone",
        "Escudo Partido",
    ]),
]


def verificar_conjunto(arquivo, nomes):
    """O arquivo único com todas as Tools de UM modelo."""
    caminho = os.path.join(TOOLS, arquivo)
    erros = []

    if not os.path.exists(caminho):
        return ["arquivo do conjunto não existe — rode FERRAMENTAS/montar_rbxmx.py"]

    try:
        raiz = ET.parse(caminho).getroot()
    except ET.ParseError as e:
        return ["XML inválido: %s" % e]

    tools = [i for i in raiz.findall("Item") if i.get("class") == "Tool"]
    achados = [texto(t, "Name") for t in tools]

    if len(tools) != len(nomes):
        erros.append("tem %d Tools, esperava %d" % (len(tools), len(nomes)))
    for nome in nomes:
        if nome not in achados:
            erros.append("falta a Tool %r" % nome)
    # Tool de OUTRO modelo dentro deste conjunto é entrega errada: quem importa
    # o arquivo recebe Tools que não pediu, e o nome mente sobre o conteúdo.
    for achado in achados:
        if achado not in nomes:
            erros.append("tem a Tool %r, que é de outro modelo" % achado)

    # As Tools têm de ser itens de RAIZ. Dentro de uma Folder, a StarterPack
    # não entrega nada ao jogador.
    for item in raiz.findall("Item"):
        if item.get("class") != "Tool":
            erros.append("item de raiz %r não é Tool — na StarterPack não seria entregue"
                         % item.get("class"))

    # referent duplicado faz o Studio religar propriedades no objeto errado
    vistos = set()
    for item in raiz.iter("Item"):
        ref = item.get("referent")
        if ref in vistos:
            erros.append("referent duplicado: %s" % ref)
        vistos.add(ref)

    # cada Tool do conjunto tem de bater com o .rbxmx individual dela
    for tool in tools:
        nome = texto(tool, "Name")
        if nome not in nomes:
            continue
        individual = os.path.join(TOOLS, nome, "%s.rbxmx" % nome)
        if not os.path.exists(individual):
            continue
        r2 = ET.parse(individual).getroot()
        t2 = [i for i in r2.findall("Item") if i.get("class") == "Tool"][0]

        # Compara TODO script por caminho, não uma lista fixa de três nomes: o
        # conjunto e o individual saem da mesma montagem, então qualquer
        # divergência é sinal de que um dos dois ficou para trás.
        no_conjunto = {c: texto(i, "Source") for i, c in percorrer_scripts(tool)}
        no_individual = {c: texto(i, "Source") for i, c in percorrer_scripts(t2)}

        for caminho in sorted(set(no_conjunto) | set(no_individual)):
            if caminho not in no_individual:
                erros.append("%s falta no .rbxmx individual" % caminho)
            elif caminho not in no_conjunto:
                erros.append("%s está no individual mas não no conjunto" % caminho)
            elif no_conjunto[caminho] != no_individual[caminho]:
                erros.append("%s diverge do .rbxmx individual" % caminho)

    return erros


def main():
    nomes = sorted(d for d in os.listdir(TOOLS)
                   if os.path.isdir(os.path.join(TOOLS, d))
                   and not d.startswith("_"))

    print("")
    print("VERIFICAÇÃO DOS .rbxmx ENTREGUES")
    print(CINZA % "Tool conforme, autocontida, e com a fonte igual à do repositório")
    print("")

    total = 0
    for nome in nomes:
        erros = verificar(nome)
        if erros:
            total += len(erros)
            print(VERMELHO % ("✗ %s" % nome))
            for e in erros:
                print("    %s" % e)
        else:
            caminho = os.path.join(TOOLS, nome, "%s.rbxmx" % nome)
            print(VERDE % ("✓ %-20s %7d bytes" % (nome, os.path.getsize(caminho))))

    print("")
    print(CINZA % "CONJUNTOS — um arquivo por modelo de origem")
    for arquivo, modelo, ordem in CONJUNTOS:
        erros = verificar_conjunto(arquivo, ordem)
        if erros:
            total += len(erros)
            print(VERMELHO % ("✗ %s" % arquivo))
            for e in erros:
                print("    %s" % e)
        else:
            caminho = os.path.join(TOOLS, arquivo)
            print(VERDE % ("✓ %-22s %7d bytes  (as %d Tools num arquivo só)"
                           % (modelo, os.path.getsize(caminho), len(ordem))))

    print("")
    if total == 0:
        print(VERDE % "TODOS OS .rbxmx OK")
        print("")
        return 0
    print(VERMELHO % ("%d PROBLEMA(S)" % total))
    print("")
    return 1


if __name__ == "__main__":
    sys.exit(main())
