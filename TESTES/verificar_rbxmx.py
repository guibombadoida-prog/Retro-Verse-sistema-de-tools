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
  2b. O `.rbxm` binário existe e é mais novo que o `.rbxmx` — ele É a entrega
  3. Existe um Handle, com esse nome exato
  4. (vago) — o `DamageClass` saiu junto com o Núcleo de Combate
  5. Todo script exigido pelo §12.10 está presente, com o nome de objeto certo
  6. A fonte embutida é BYTE A BYTE igual ao .lua do repositório
  6b. Nenhuma callback de beat compara o keyframe com string (o beat é `kf.marca`)
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
AMARELO = "\033[33m%s\033[0m"

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
    # o laço de scripts mais abaixo reusa o nome `caminho`; o arquivo da Tool
    # precisa de um nome próprio para sobreviver a ele
    arquivo_xml = caminho
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

    # 4. (vago) — aqui morava a cobrança do `DamageClass`.
    #
    # Ele existia para o Núcleo de Combate dar bônus por classe. O Núcleo saiu
    # do repositório, e etiqueta que ninguém lê é peso morto: a Tool passava a
    # carregar um `StringValue` que nenhum script do place consulta. A cobrança
    # sai junto com o que ela servia.

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

    # 6b. O BEAT VEM COMO KEYFRAME, NÃO COMO STRING
    #
    # `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)`: `kf` é a
    # TABELA do passo, e a marca mora em `kf.marca`. Uma callback escrita como
    # `function(marca) if marca == "BATE" then` compara a tabela com a string,
    # nunca dá verdadeiro, e FALHA EM SILÊNCIO — a animação roda inteira e o
    # dano, o VFX e o som do beat simplesmente não acontecem.
    #
    # Foi assim que os 14 Tools dos conjuntos GUEST e GRAVIDADE saíram sem dano
    # nenhum, passando em todo verificador. Esta checagem existe por causa disso.
    for nome_obj, fonte in fontes.items():
        limpo = sem_comentario(fonte)
        for m in re.finditer(r"PlaySequence\s*\([^)]*?function\s*\(\s*(\w+)\s*\)(.{0,400})",
                             limpo, re.S):
            parametro, corpo = m.group(1), m.group(2)
            if re.search(r"\b%s\s*==\s*[\"']" % re.escape(parametro), corpo):
                erros.append("%s compara o keyframe do beat com string "
                             "(`%s == \"...\"`) — a marca está em `%s.marca`, "
                             "e assim o beat NUNCA dispara"
                             % (nome_obj, parametro, parametro))

    # 6a. NENHUM SCRIPT ABRE FRONTEIRA DE SANDBOX
    #
    # `DefinesCapabilities = true` faz a thread do script rodar SANDBOXADA, e
    # thread sandboxada só pode dar `require` em ModuleScript que também seja
    # sandboxado. O `Poses`, o `R6CFrameAnimator` e o `VFXModule` nascem aqui,
    # limpos — então o `require` morre com:
    #
    #   The current thread cannot require 'Poses' since 'Poses' has the
    #   Sandboxed property set to false but the calling thread is sandboxed
    #
    # E a Tool morre junto: sem Poses não há animação, sem animação não há beat,
    # sem beat não há dano. Foi o que matou `A arma` em jogo.
    #
    # A propriedade viaja no ITEM, não no Source — o montador reescreve o código
    # e a fronteira do autor original fica. Esta checagem existe por causa disso.
    for item, caminho in percorrer_scripts(tool):
        p = item.find("Properties")
        if p is None:
            continue
        for campo in p:
            if campo.get("name") != "DefinesCapabilities":
                continue
            if (campo.text or "").strip() == "true":
                erros.append("%s tem DefinesCapabilities=true — a thread dele "
                             "roda SANDBOXADA e o `require` de Poses morre"
                             % caminho.rsplit("/", 1)[-1])

    # 6c. A ANIMAÇÃO TEM DE SER CHAMADA POR ALGUÉM
    #
    # Uma Tool pode carregar `Poses.lua` com `P.SEQUENCIAS`, o
    # `R6CFrameAnimator` inteiro, e um `animar()` bem escrito — e nunca invocar
    # nada disso. O arquivo passa em todo verificador de forma, e no jogo o
    # personagem executa a habilidade PARADO, com o golpe saindo no mesmo
    # quadro do clique.
    #
    # Foi o estado das 14 Tools do Xester: `animar()` definido nas 14, chamado
    # em ZERO. Esta checagem existe por causa disso.
    tem_sequencias = any("SEQUENCIAS" in f for f in fontes.values())
    if tem_sequencias:
        chamou = False
        for nome_obj, fonte in fontes.items():
            limpo = sem_comentario(fonte)
            # a definição não conta como chamada
            sem_def = re.sub(r"(local\s+)?function\s+animar\s*\(", "", limpo)
            if re.search(r"PlaySequence\s*\(|PlayTrack\s*\(", sem_def):
                chamou = True
            elif re.search(r"\banimar\s*\(", sem_def):
                chamou = True
        if not chamou:
            erros.append("tem P.SEQUENCIAS e NINGUÉM toca a animação — "
                         "sem PlaySequence/PlayTrack/animar() o personagem "
                         "executa a habilidade parado")

    # 6d. SOM DEPOSITADO É SOM QUE ALGUÉM TOCA
    #
    # `Sound` dentro da Tool que nenhum script referencia é asset pago e mudo.
    # As 14 do Xester tinham 34 `Sound` nomeados por papel e zero `tocar()` —
    # o "cadê os SFX" era isto.
    nomes_som = set()
    for item in tool.iter("Item"):
        if item.get("class") == "Sound":
            alvo = texto(item, "Name")
            if alvo:
                nomes_som.add(alvo)
    if nomes_som:
        citados = set()
        for fonte in fontes.values():
            # `\w+` NÃO casa espaço, e vários Sound do Roblox têm nome com
            # espaço — "Power Up", "Locked On", "User Sparkle". Com o regex
            # antigo eles nunca podiam ser vistos como citados: o Server
            # tocava o som e o verificador jurava que ele estava mudo. Um
            # aviso que não pode ser zerado deixa de ser aviso.
            citados.update(re.findall(r"[\"']([^\"'\n]+)[\"']",
                                      sem_comentario(fonte)))
        mudos = sorted(n for n in nomes_som if n not in citados)
        if mudos:
            # AVISO, não erro: a checagem é nova e encontrou o mesmo defeito em
            # conjuntos antigos que ninguém pediu para mexer. Contá-los como
            # falha esconderia as falhas de verdade no meio do inventário.
            erros.append("AVISO: Sound que nenhum script cita: %s — asset "
                         "depositado e mudo" % ", ".join(mudos))

    for obrigatorio in ("Client", "VFXModule", "Poses", "R6CFrameAnimator"):
        if obrigatorio not in fontes:
            erros.append("sem script chamado %r" % obrigatorio)

    # 7. remotes
    if achar(tool, "RemoteEvent", "VFXRemote") is None:
        erros.append("sem VFXRemote")

    # 7b. O BINÁRIO É A ENTREGA (REGRA_ENTREGA_RBXM)
    #
    # `.rbxmx` é a etapa do meio — fica versionado porque é o único dos dois em
    # que o `git diff` mostra o que mudou. Quem se arrasta para o Studio é o
    # `.rbxm`. Um `.rbxmx` novo sem o binário ao lado é entrega pela metade, e
    # o jeito de isso passar despercebido é justamente ninguém conferir.
    binario = os.path.join(pasta, "%s.rbxm" % nome)
    if not os.path.exists(binario):
        erros.append("sem %s.rbxm — o binário é a entrega "
                     "(FERRAMENTAS/converter_para_rbxm.py)" % nome)
    elif os.path.getmtime(binario) < os.path.getmtime(arquivo_xml):
        erros.append("%s.rbxm é mais VELHO que o .rbxmx — converta de novo" % nome)

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
    # O Sound pode morar numa pasta SFX (Tool autoral) ou pendurado no Handle
    # (Tool que chegou pronta, como a Astral). O que a regra cobra é que ele
    # esteja DENTRO da Tool — onde exatamente é decisão de quem montou.
    nomes_sfx = set()
    def varrer_sons(no):
        for filho in filhos(no):
            if filho.get("class") == "Sound":
                nomes_sfx.add(texto(filho, "Name"))
                url = prop(filho, "SoundId")
                destino = url.find("url") if url is not None else None
                # `rbxasset://` NÃO é `rbxassetid://`, e é igualmente válido:
                # é conteúdo que vem JUNTO com o cliente Roblox
                # (`rbxasset://sounds/swordslash.wav`). Mais "dentro" que
                # qualquer id de catálogo, porque não há nada para buscar. O
                # `drama.rbxmx` traz dois assim, e recusá-los era o verificador
                # sendo estreito, não a Tool sendo errada.
                valor = (destino.text or "") if destino is not None else ""
                if not (valor.startswith("rbxassetid://")
                        or valor.startswith("rbxasset://")):
                    erros.append("Sound %r sem SoundId utilizável (%r)"
                                 % (texto(filho, "Name"), valor))
            varrer_sons(filho)
    varrer_sons(tool)

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

    # 10. Regra nº 1 — com UMA ressalva, e ela tem nome
    #
    # `DepositoVFX` é o módulo da Regra nº 2, e ele existe justamente para
    # escrever em `ReplicatedStorage`. A ressalva é NOMINAL de propósito: vale
    # para esse módulo e para nenhum outro, e o que ele faz lá é montar a pasta
    # da PRÓPRIA Tool e desmontá-la quando ela morre.
    #
    # Qualquer outro script que toque em `ReplicatedStorage` continua sendo
    # violação — inclusive um que se chame parecido.
    for nome_obj, codigo in fontes.items():
        limpo = sem_comentario(codigo)
        curto = nome_obj.rsplit("/", 1)[-1]
        for termo in PROIBIDOS:
            if termo not in limpo:
                continue
            if curto == "DepositoVFX" and termo == "ReplicatedStorage":
                continue
            erros.append("%s referencia %s — fora da Tool (Regra nº 1)"
                         % (nome_obj, termo))

    return erros


# Um conjunto por MODELO de origem, não um arquivo com o repositório inteiro.
CONJUNTOS = [
    ("Bombas_6_Tools.rbxmx", "Bomba_V4", [
        "Multiplas Bombas",
        "Bomba Nuclear",
        "Bomba Meteorica",
        "Bomba Basquete",
        "Bomba Doida",
        "Bomba Gelada",
    ]),
    ("Astral_5_Tools.rbxmx", "Astral_Peria", [
        "Astral Periastron",
        "Astral Nova",
        "Astral Cometa",
        "Astral Singularidade",
        "Astral Constelacao",
    ]),
    ("Escudos_7_Tools.rbxmx", "Danilo_Escudos_V4", [
        "Salvador",
        "Proteção",
        "Escudo Skate",
        "Escudo Bumerangue",
        "Escudo Bloqueador",
        "Escudo Cyclone",
        "Escudo Partido",
    ]),
    # 7 Tools de gravidade telecinética a partir das 5 do `calebe_tools.rbxmx`:
    # duas clonam o Handle de uma irmã. Ver FERRAMENTAS/preparar_gravidade.py.
    ("Gravidade_7_Tools.rbxmx", "Calebe_Tools", [
        "Tremores da Gravidade",
        "Controlador da Gravidade",
        "Telecinese Levitacao",
        "Lancador de Objetos",
        "Asas Telecineticas",
        "Terremoto",
        "Telecinese Gravitacional",
    ]),
    # As 5 remasterizadas do `guest_tools.rbxmx` mais as 2 do
    # `guest_tools_2_more.rbxmx`, fundidas por FERRAMENTAS/fundir_guest.py.
    # 7 Tools de briga a partir das 3 do `drama.rbxmx`: `Fists` e `dodge` não
    # têm Handle nenhum, e ganham um invisível. Duas têm CUTSCENE.
    ("Drama_7_Tools.rbxmx", "Drama", [
        "Combate",
        "Desviar",
        "Corte Frio",
        "Impacto Forte",
        "Aura",
        "Olhos Laser",
        "Cortada Fatal",
    ]),
    ("Guest_7_Tools.rbxmx", "Guest_Tools", [
        "Taco de Baseball",
        "Cano De Rua",
        "Abacate (roubado) do mexico",
        "Energetico",
        "Humilhador",
        "Diamond",
        "A arma",
    ]),
    # O Xester sai em DOIS arquivos, um por forma, pela regra de distribuição:
    # a Forma 1 tem OITO habilidades e vira 7 Tools (o `F` entra como Extra no
    # `Eclipse Deck`, que é o outro clímax dela); a Forma 2 tem SEIS e vira 6,
    # uma por habilidade.
    #
    # `F` troca de forma sem nenhuma Tool alcançar a outra: ela escreve o
    # Attribute `XesterForma` no Character, que é estado — mesma categoria do
    # estado opcional compartilhado —, não caminho de instância.
    ("Xester_Forma1_7_Tools.rbxmx", "Xester_Forma1", [
        "Xester Curtain Call",
        "Xester Four Suits Arsenal",
        "Xester Jokers Labyrinth",
        "Xester Ace Gate",
        "Xester House Collapse",
        "Xester Eclipse Deck",
        "Xester Royal Guard",
    ]),
    ("Xester_Forma2_6_Tools.rbxmx", "Xester_Forma2", [
        "Xester Wyrm Sparks",
        "Xester Crown of Cinders",
        "Xester Dragons Requiem",
        "Xester Prism",
        "Xester Final Page",
        "Xester Curtain Reversal",
    ]),
    # 7 Tools de pressão, do `Jupiter_Great_Pressure_Sword`. Da origem vieram
    # os ASSETS — 19 SoundId, a malha do planeta, seis texturas de emissor,
    # todos pela ficha do Acervo. A lógica dos 31 scripts dela ficou de fora.
    ("Jupiter_7_Tools.rbxmx", "Jupiter_Great_Pressure_Sword", [
        "Jupiter Grande Mancha",
        "Jupiter Pressao Esmagadora",
        "Jupiter Raio Joviano",
        "Jupiter Luas Galileanas",
        "Jupiter Cinturao de Radiacao",
        "Jupiter Espada de Pressao",
        "Jupiter Queda do Gigante",
    ]),
    # 5 Tools de DUAS fontes: quatro do `reality_tools.rbxmx` (que está em
    # QUARENTENA por causa do backdoor, que mora na `Pistol` — nenhuma destas
    # quatro tem veneno) e uma do `Canhao_satelite.rbxmx`.
    #
    # Aqui o script da origem ATRAVESSA, e é o único conjunto assim: a entrega
    # é o script original com remendos contados, não uma reescrita. `Trem` e
    # `Danca Provocadora` saíram a pedido.
    # 7 cajados. A origem tem OITO Tool com uma habilidade cada; `Curador` e
    # `Roubador de Hp` são o mesmo feixe espelhado, então o Roubar virou Extra
    # do Curador e 8 viraram 7 — o teto da REGRA_DISTRIBUICAO.
    #
    # QUATRO habilidades por Tool: a da origem mais três Extras (R, T, Y).
    ("Maria_7_Tools.rbxmx", "Maria_Tools", [
        "Cajado Curador",
        "Cajado da Escuridao",
        "Cajado da Ilusao",
        "Cajado das Estrelas",
        "Cajado de Gelo",
        "Cajado do Meteoro",
        "Cajado Relampago",
    ]),

    # 7 Tools AUTORAIS de meme — o primeiro conjunto com TRÊS habilidades
    # por Tool (M1 + R + T). Sem modelo de origem: Handle, som, pose e
    # habilidade são escritos no repositório.
    ("jodro.rbxmx", "Jodro", [
        "Bonk",
        "Chinelo Voador",
        "Sussy",
        "Caixa de Som",
        "Privada Sonora",
        "Pombo Correio",
        "Deu Ruim",
    ]),

    ("Reality Gui.rbxmx", "Reality_Gui", [
        "Lapada Seca",
        "Canhao Satelite",
        "Arvore Maligna",
        "Gato Ajudante Boss",
        "Samsungus",
    ]),
    # 7 Tools a partir do `noob_despertado.rbxmx`, que NÃO é uma Tool: é um
    # Script de 2650 linhas solto na raiz. Nove ataques viraram 7 primárias e
    # 2 Extras; as seis FORMAS não viram Tool. Duas têm CUTSCENE.
    ("Noob_7_Tools.rbxmx", "Noob_Despertado", [
        "Tiro do Vazio",
        "Chuva de Lava",
        "Parada do Tempo",
        "Buraco Negro",
        "Colar das Trevas",
        "Explosao Lunar",
        "Super Dominus",
    ]),
    # 7 Tools a partir da ÚNICA Tool do `faker_tools.rbxmx` (o His Cube
    # original). Duas têm CUTSCENE. O conserto do conjunto é de VISIBILIDADE:
    # a origem punha 796 linhas de habilidade em dois LocalScript, então o
    # efeito só existia na tela de quem segurava a Tool.
    ("Faker_7_Tools.rbxmx", "Faker_Tools", [
        "Ultra Combo",
        "Era Do Fim",
        "Sala Do Abismo",
        "Ilusao da Alucinacao",
        "Prisao Cubica",
        "Faker Entity",
        "Abismo Profundo",
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

    binario = os.path.join(TOOLS, arquivo.replace(".rbxmx", ".rbxm"))
    if not os.path.exists(binario):
        erros.append("sem o .rbxm do conjunto — o binário é a entrega")
    elif os.path.getmtime(binario) < os.path.getmtime(caminho):
        erros.append("o .rbxm do conjunto é mais VELHO que o .rbxmx")

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
    print("VERIFICAÇÃO DAS TOOLS ENTREGUES")
    print(CINZA % "Tool conforme, autocontida, fonte igual à do repositório, e o .rbxm ao lado")
    print("")

    total = 0
    avisados = []
    for nome in nomes:
        achados = verificar(nome)
        erros = [e for e in achados if not e.startswith("AVISO:")]
        avisos = [e for e in achados if e.startswith("AVISO:")]
        if avisos:
            avisados.append((nome, avisos))
        if erros:
            total += len(erros)
            print(VERMELHO % ("✗ %s" % nome))
            for e in erros:
                print("    %s" % e)
            for a in avisos:
                print(AMARELO % ("    %s" % a))
        else:
            caminho = os.path.join(TOOLS, nome, "%s.rbxmx" % nome)
            print(VERDE % ("✓ %-20s %7d bytes" % (nome, os.path.getsize(caminho))))

    if avisados:
        print("")
        print(AMARELO % ("AVISOS — %d Tool(s) com asset depositado e mudo"
                         % len(avisados)))
        for nome, avisos in avisados:
            for a in avisos:
                print(AMARELO % ("  %-24s %s" % (nome, a[7:])))

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
        print(VERDE % "TODAS AS ENTREGAS OK")
        print("")
        return 0
    print(VERMELHO % ("%d PROBLEMA(S)" % total))
    print("")
    return 1


if __name__ == "__main__":
    sys.exit(main())
