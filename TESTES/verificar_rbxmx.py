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
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

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
    esperados = [
        ("Script", "%s_Server_V1" % nome, "%s_Server_V1.lua" % nome),
        ("LocalScript", "Client", "Client.lua"),
        ("ModuleScript", "R6CFrameAnimator", "R6CFrameAnimator.lua"),
        ("ModuleScript", "VFXModule", "VFXModule.lua"),
        ("ModuleScript", "Poses", "Poses_GravidadeTelecinese_%s_V1.lua" % nome),
    ]
    fontes = {}
    for classe, nome_obj, arquivo in esperados:
        item = achar(tool, classe, nome_obj)
        if item is None:
            erros.append("sem %s chamado %r" % (classe, nome_obj))
            continue
        embutido = texto(item, "Source")
        if embutido is None:
            erros.append("%s sem Source" % nome_obj)
            continue
        fontes[nome_obj] = embutido
        disco = open(os.path.join(pasta, arquivo), encoding="utf-8").read()
        if embutido != disco:
            erros.append("%s diverge de %s — rode montar_rbxmx.py de novo"
                         % (nome_obj, arquivo))

    # 7. remotes
    if achar(tool, "RemoteEvent", "VFXRemote") is None:
        erros.append("sem VFXRemote")

    servidor = fontes.get("%s_Server_V1" % nome, "")
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
    implementados = set(re.findall(r"function VFX\.([A-Z][A-Z0-9_]*)", modulo))
    for citado in set(re.findall(r'transmitirVFX\(\s*\w+\s*,\s*"([A-Z0-9_]+)"',
                                 sem_comentario(servidor))):
        if citado not in implementados:
            erros.append("o Server transmite o VFX %r, que o VFXModule desta Tool "
                         "não implementa — o efeito não desenha e nada avisa" % citado)

    # 10. Regra nº 1
    for nome_obj, codigo in fontes.items():
        limpo = sem_comentario(codigo)
        for termo in PROIBIDOS:
            if termo in limpo:
                erros.append("%s referencia %s — fora da Tool (Regra nº 1)"
                             % (nome_obj, termo))

    return erros


# Um conjunto por MODELO de origem, não um arquivo com o repositório inteiro.
# Espelha CONJUNTOS de FERRAMENTAS/montar_rbxmx.py — se um mudar, o outro muda.
CONJUNTOS = [
    ("GravidadeTelecinese_7_Tools.rbxmx", "Gravidade / Telecinese", [
        "PulsoGravitacional", "CampoZeroG", "MaoTelecinetica", "OrbitaPsi",
        "LancaVetorial", "PocoDeMassa", "MarionetePsi"]),
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
        for classe, nome_obj in (("Script", "%s_Server_V1" % nome),
                                 ("LocalScript", "Client"),
                                 ("ModuleScript", "Poses")):
            a = achar(tool, classe, nome_obj)
            b = achar(t2, classe, nome_obj)
            if a is None or b is None:
                erros.append("%s/%s ausente na comparação com o arquivo individual"
                             % (nome, nome_obj))
            elif texto(a, "Source") != texto(b, "Source"):
                erros.append("%s/%s diverge do .rbxmx individual" % (nome, nome_obj))

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
