#!/usr/bin/env python3
"""
verificar_vfx_chamadas.py — Retro-Verse / Studios

Pega função chamada e nunca definida dentro de um `VFXModule`.

    python3 TESTES/verificar_vfx_chamadas.py

POR QUE ISTO EXISTE

    Três vezes o mesmo defeito, e nenhuma foi pega por verificador:

      `angulo` e `registroDe`   faltavam no VFXModule_Jodro — peguei relendo
      `molde`                   faltava no VFXModule_Maria — só o CONSOLE DO
                                JOGO pegou, com `attempt to call a nil value`
                                em METEORO e RAIO
      `Executar`/`Parar`/       o VFXModule do Xester exportava `desenhar` e
      `LimparTudo`              `limpar`, de um Client anterior. O Client atual
                                chamava `VFX.Executar` — TODO efeito das 14
                                Tools morria na primeira linha, calado

    A causa é sempre a mesma: o andaime de um módulo é reusado de outro
    conjunto, os EFEITOS novos usam um helper que aquele andaime não tinha, e
    em Lua chamar função inexistente só estoura NA HORA DE CHAMAR.

    E o `VFX.Executar` roda todo efeito sob `pcall`. O erro vira `warn`, o jogo
    não trava, o efeito simplesmente não aparece. Nenhum verificador de
    estrutura, pose ou tipo enxerga isso — o arquivo é Lua válido.

O QUE ELE FAZ

    DUAS conferências. A segunda nasceu do caso do Xester: um módulo pode ter
    todos os helpers no lugar e ainda assim não servir, porque o `Client.lua`
    chama uma PORTA que ele não abre. Um helper faltando apaga um efeito; a
    porta faltando apaga todos.

    Lê cada `VFXModule`, junta o que está DEFINIDO (`local function x`,
    `function x`, `local x = function`, parâmetro de função, `local x`), e
    compara com o que é CHAMADO na forma `nome(`.

    Comentário é removido antes da comparação: `prender()` dentro de um `---`
    não é chamada, e acusá-lo seria ruído que faz o verificador ser ignorado.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VERDE, VERMELHO, CINZA, FIM = "\033[32m", "\033[31m", "\033[90m", "\033[0m"

#: nome global do Luau/Roblox — chamá-los é normal
GLOBAIS = {
    "math", "table", "task", "string", "os", "coroutine", "utf8", "bit32",
    "ipairs", "pairs", "next", "select", "type", "typeof", "tostring",
    "tonumber", "pcall", "xpcall", "error", "assert", "warn", "print",
    "require", "unpack", "rawget", "rawset", "rawequal", "rawlen", "setmetatable",
    "getmetatable", "game", "workspace", "script", "shared", "newproxy",
    "Instance", "CFrame", "Vector3", "Vector2", "Color3", "ColorSequence",
    "NumberSequence", "NumberRange", "UDim", "UDim2", "Enum", "Ray", "Region3",
    "TweenInfo", "BrickColor", "Random", "Faces", "Axes", "OverlapParams",
    "RaycastParams", "ColorSequenceKeypoint", "NumberSequenceKeypoint",
    "PhysicalProperties", "DateTime", "buffer", "vector",
}

PALAVRAS = {"if", "for", "while", "return", "and", "or", "not", "then", "do",
            "end", "function", "local", "elseif", "else", "repeat", "until",
            "in", "break", "continue", "nil", "true", "false"}

RE_COMENTARIO_LONGO = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)
RE_COMENTARIO = re.compile(r"--[^\n]*")
RE_TEXTO = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'')


def sem_ruido(fonte):
    """Tira comentário e literal de texto: nenhum dos dois é chamada."""
    fonte = RE_COMENTARIO_LONGO.sub(" ", fonte)
    fonte = RE_COMENTARIO.sub("", fonte)
    return RE_TEXTO.sub('""', fonte)


def definidos(fonte):
    nomes = set()
    nomes |= set(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", fonte))
    nomes |= set(re.findall(r"\blocal\s+function\s+([A-Za-z_]\w*)", fonte))
    # `local a, b = ...` e `local x = function`
    for grupo in re.findall(r"\blocal\s+([A-Za-z_][\w,\s]*?)\s*(?:=|\n)", fonte):
        for parte in grupo.split(","):
            parte = parte.strip()
            if parte and re.fullmatch(r"[A-Za-z_]\w*", parte):
                nomes.add(parte)
    # parâmetros: viram função quando o chamador passa uma
    for grupo in re.findall(r"\bfunction\s*[\w.:]*\s*\(([^)]*)\)", fonte):
        for parte in grupo.split(","):
            parte = parte.strip().lstrip(".")
            if parte and re.fullmatch(r"[A-Za-z_]\w*", parte):
                nomes.add(parte)
    for grupo in re.findall(r"\bfor\s+([A-Za-z_][\w,\s]*?)\s+in\b", fonte):
        for parte in grupo.split(","):
            parte = parte.strip()
            if parte:
                nomes.add(parte)
    return nomes


def chamados(fonte):
    #  `nome(`  mas não  `.nome(`  nem  `:nome(`
    return set(re.findall(r"(?<![.:\w])([a-z_]\w*)\s*\(", fonte))


def verificar(caminho):
    bruto = open(caminho, encoding="utf-8").read()
    fonte = sem_ruido(bruto)
    faltando = sorted(chamados(fonte) - definidos(fonte) - GLOBAIS - PALAVRAS)
    return faltando


#: o que um `Client.lua` chama no módulo, `VFX.<Nome>(`
CHAMADA_NO_MODULO = re.compile(r"\bVFX\.([A-Z]\w*)\s*\(")

#: o que um `VFXModule.lua` exporta: `function <tabela>.<Nome>(` ou
#: `<tabela>.<Nome> = ` — a tabela devolvida costuma ser `M` ou `VFX`
EXPORTA_FUNCAO = re.compile(r"(?m)^function\s+\w+\.([A-Z]\w*)\s*\(")
EXPORTA_ALIAS = re.compile(r"(?m)^\w+\.([A-Z]\w*)\s*=\s*")


def porta(pasta):
    """(faltando, testou) — o `Client.lua` da Tool chama porta que o
    `VFXModule.lua` dela não exporta?

    Só olha `VFX.<Nome>` com inicial MAIÚSCULA: `VFX.Executar` é a porta do
    módulo, e `vfx("TEMPESTADE", …)` no Server é outra coisa — aquele passa
    pelo despachante, e a checagem dele é a de cima.
    """
    cliente = os.path.join(pasta, "Client.lua")
    modulo = os.path.join(pasta, "VFXModule.lua")
    if not (os.path.exists(cliente) and os.path.exists(modulo)):
        return [], False
    usa = set(CHAMADA_NO_MODULO.findall(
        sem_ruido(open(cliente, encoding="utf-8").read())))
    if not usa:
        return [], False
    fonte = sem_ruido(open(modulo, encoding="utf-8").read())
    tem = set(EXPORTA_FUNCAO.findall(fonte)) | set(EXPORTA_ALIAS.findall(fonte))
    return sorted(usa - tem), True


def main():
    alvos = []
    for base, _dirs, arquivos in os.walk(RAIZ):
        if ".git" in base:
            continue
        for arq in arquivos:
            if arq.startswith("VFXModule") and arq.endswith(".lua"):
                alvos.append(os.path.join(base, arq))
    alvos.sort()

    # A fonte em `FERRAMENTAS/dados/` é a que interessa quando existe — o mesmo
    # módulo é copiado para dentro de cada Tool.
    #
    # Mas nem todo conjunto tem fonte solta: o Xester guarda o dele como
    # TEMPLATE dentro do gerador, com `%(paleta)s` trocado por forma. Template
    # não é Lua válido e não pode virar arquivo. Então o que se confere ali é o
    # módulo GERADO, dentro da Tool — que é o que embarca de verdade.
    #
    # Um por conteúdo: 14 cópias do mesmo módulo são um módulo.
    import hashlib
    fontes, vistos = [], set()
    for caminho in alvos:
        se_dados = "FERRAMENTAS/dados" in caminho.replace("\\", "/")
        chave = hashlib.md5(
            open(caminho, "rb").read()).hexdigest() if not se_dados else None
        if se_dados:
            fontes.append(caminho)
        elif chave not in vistos:
            vistos.add(chave)
            fontes.append(caminho)

    problemas = 0
    for caminho in fontes:
        faltando = verificar(caminho)
        rotulo = os.path.relpath(caminho, RAIZ)
        if faltando:
            problemas = problemas + 1
            print("%s✗ %s%s" % (VERMELHO, rotulo, FIM))
            for nome in faltando:
                print("    chama %r e nunca define — `attempt to call a nil "
                      "value` dentro do pcall, e o efeito some calado" % nome)
        else:
            print("%s✓ %s%s" % (VERDE, rotulo, FIM))

    print("")
    print("PORTA DO MÓDULO — o que o Client chama, o VFXModule exporta?")
    print("")
    portas = 0
    for pasta in sorted(os.listdir(os.path.join(RAIZ, "Tools"))):
        cheio = os.path.join(RAIZ, "Tools", pasta)
        if not os.path.isdir(cheio):
            continue
        faltando, testou = porta(cheio)
        if not testou:
            continue
        if faltando:
            portas = portas + 1
            print("%s✗ %s%s" % (VERMELHO, pasta, FIM))
            for nome in faltando:
                print("    o Client chama VFX.%s, que o VFXModule desta Tool "
                      "não exporta — o efeito morre na primeira linha" % nome)
    if portas == 0:
        print("%s✓ toda porta chamada pelo Client existe no módulo%s"
              % (VERDE, FIM))

    print("")
    if portas:
        print("%s%d TOOL(S) COM PORTA DE VFX QUEBRADA%s"
              % (VERMELHO, portas, FIM))
        return 1
    if problemas:
        print("%s%d MÓDULO(S) COM CHAMADA SEM DEFINIÇÃO%s" % (VERMELHO, problemas, FIM))
        print("%s    Foi assim que `molde` sumiu do VFXModule_Maria e só o"
              " console do jogo pegou.%s" % (CINZA, FIM))
        return 1
    print("%sVFX OK — %d módulo(s), toda chamada tem definição%s"
          % (VERDE, len(fontes), FIM))
    return 0


if __name__ == "__main__":
    sys.exit(main())
