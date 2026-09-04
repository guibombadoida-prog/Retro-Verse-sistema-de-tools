#!/usr/bin/env python3
"""
verificar_beats.py — Retro-Verse / Studios

Confere o FIO entre o Server, o `Poses.lua` e o `CutsceneCam.lua`.

    python3 TESTES/verificar_beats.py

Sai com 1 se qualquer Tool falhar.

POR QUE ESTE VERIFICADOR EXISTE

    O nome de um beat é escrito em DOIS lugares: no `marca = "GOLPE"` do
    `Poses.lua` e de novo na tabela do `despachar` do Server. Errar o segundo
    não é erro de sintaxe, não é erro de runtime, e não aparece em log nenhum:
    a animação roda inteira, bonita, e o golpe simplesmente não acontece.

    Já custou catorze Tools de dois conjuntos, que foram entregues com dano
    zero. É o defeito mais caro que este repositório teve, e era invisível para
    os cinco verificadores que existiam na época.

O QUE ELE CONFERE

    1. Toda sequência que o Server toca EXISTE no `Poses.lua`.
       `PlaySequence("CULHEITA")` com um erro de digitação não faz nada — o
       animator não acha a sequência e volta calado.

    2. Todo beat que o Server despacha EXISTE naquela sequência.
       Despachar `SEGURA` numa sequência que só tem `CARGA`, `GOLPE` e `FIM` é
       trabalho escrito que nunca roda.

    3. Todo beat marcado `cam = true` tem ENQUADRAMENTO no `CutsceneCam.lua`.
       Beat de câmera sem quadro é uma cutscene que não corta: a câmera prende
       e fica parada no primeiro enquadramento até o `FIM`.

O QUE ELE NÃO CONFERE

    Sequência definida e nunca tocada é AVISO, não erro: uma Tool pode trazer
    uma pose de reserva de propósito. Mas ela é impressa, porque na prática
    quase sempre é uma habilidade que ficou pelo caminho.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
AMARELO = "\033[33m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

#: `SEQ = {` no topo de um bloco de sequências
RE_SEQ_DEF = re.compile(r"(?m)^\t([A-Z][A-Z0-9_]*) = \{\n((?:\t\t\{[^\n]*\n)+)\t\},")
#: `PlaySequence("NOME"` e `PlayTrack("NOME"`
RE_TOCA = re.compile(r'Play(?:Sequence|Track)\(\s*"([A-Z][A-Z0-9_]*)"')
#: o M1 que escolhe a sequência pela forma, na mesma expressão
RE_TOCA_TERNARIO = re.compile(
    r'Play(?:Sequence|Track)\(\s*\w+ and "([A-Z][A-Z0-9_]*)"'
    r'\s+or\s+"([A-Z][A-Z0-9_]*)"')
#: um bloco `PlaySequence(<alvo>, despachar({ … }))`.
#:
#: `<alvo>` pode ser literal (`"COLHEITA"`) ou uma expressão — o `TryHard`
#: chama `PlaySequence(ORDEM_COMBO[passo], …)`, com o nome vindo de uma tabela.
#: Quando não é literal, o beat é conferido contra a UNIÃO das sequências: não
#: dá para saber qual delas vai tocar, mas dá para saber se aquele beat não
#: existe em nenhuma.
# ⚠️ NÃO volte a fechar este bloco por REGEX.
#
# A versão anterior era
#
#     PlaySequence\(\s*([^,\n]+?)\s*,\s*despachar\(\{(.*?)\n\t\}\)\)
#
# e ela exigia que a tabela fechasse em `\n\t}))`. Só que a forma usada em
# quase todo o repositório é
#
#     rig:PlaySequence("X", despachar({ ... }), function() ocupado = false end)
#
# que fecha em `\n\t}), function(...)`. O regex não casava, `findall` devolvia
# vazio, e a checagem nº 2 — a que existe PORQUE 14 Tools saíram com dano zero
# — não conferia nada. Medido: **1 bloco casado de 170**. O verificador
# imprimia OK a leva inteira sem ter olhado para nada.
#
# É a mesma família do defeito que o `verificar_pack_vfx.py` tinha, e o
# conserto é o mesmo: contar chave, não adivinhar o terminador.
RE_ABRE_DESPACHO = re.compile(
    r'PlaySequence\(\s*([^,\n]+?)\s*,\s*despachar\(\{')


def despachos(texto):
    """(alvo, corpo) de cada `despachar({...})`, fechando por contagem."""
    for m in RE_ABRE_DESPACHO.finditer(texto):
        nivel, i = 1, m.end()
        while i < len(texto) and nivel > 0:
            ch = texto[i]
            if ch == "{":
                nivel = nivel + 1
            elif ch == "}":
                nivel = nivel - 1
                if nivel == 0:
                    break
            elif ch == '"':
                # string: pular até a próxima aspa não escapada, para que uma
                # chave dentro de texto não desequilibre a contagem
                i = i + 1
                while i < len(texto) and texto[i] != '"':
                    if texto[i] == "\\":
                        i = i + 1
                    i = i + 1
            i = i + 1
        if nivel == 0:
            yield m.group(1), texto[m.end():i]

#: Os ajudantes que o Server usa e define ELE MESMO. Se um deles é chamado e
#: não está definido no arquivo, a Tool morre na primeira habilidade.
#:
#: Todos são `local function` do preâmbulo — não são API do Roblox, não são
#: global de outro script, e não podem vir de fora: a Regra nº 1 diz que a Tool
#: é autocontida, então o Server é a fronteira inteira.
AJUDANTES = (
    "despachar", "marcaDe", "tocar", "tocarEm", "aplicarDano", "alvosEm",
    "raizDe", "frente", "empurrar", "tombar", "creditar", "vfx",
    # ── acrescentados depois, cada um por um susto ──────────────────────────
    # `noChao` e `alvosNoCone` foram CHAMADOS e não definidos no primeiro
    # gerador do conjunto CRIAÇÃO: ele nasceu de uma cópia do gerador do
    # TEMPO, cujo preâmbulo não tinha os dois. Quatro habilidades morriam com
    # `attempt to call a nil value` na primeira linha do `faz`.
    #
    # É EXATAMENTE o defeito das 28 Tools, repetido por outro caminho: lá o
    # gerador emitia a chamada e esquecia a definição; aqui o gerador foi
    # clonado de outro que tinha menos ajudantes. A lista só protege contra os
    # nomes que estão nela — por isso ela cresce sempre que um gerador novo
    # usa um ajudante novo.
    "noChao", "alvosNoCone", "alvosNaReta", "golpearArea", "estourar",
    "avancar", "criar", "recolher", "recolherTudo", "levantar",
    "congelarHumanoide", "descongelarHumanoide", "restaurarTudo",
    "iniciarGravacao", "pararGravacao", "reverterPara", "afrouxar",
)

#: qualquer literal MAIÚSCULO no Server. Serve só para o AVISO de sequência não
#: tocada: um nome guardado em tabela e chamado por índice é invisível para o
#: padrão do `PlaySequence`, e acusá-lo de morto seria mentira.
RE_LITERAL = re.compile(r'"([A-Z][A-Z0-9_]*)"')
#: as chaves de primeiro nível da tabela do despachar
RE_BEAT = re.compile(r"(?m)^\t\t([A-Z][A-Z0-9_]*)\s*=\s*\{")
#: um beat que manda a câmera cortar
RE_BEAT_CAM = re.compile(r"(?m)^\t\t([A-Z][A-Z0-9_]*)\s*=\s*\{[^\n]*cam = true")
#: as cenas do CutsceneCam: `NOME = {` com beats dentro
RE_CENA = re.compile(r"(?m)^\t([A-Z][A-Z0-9_]*) = \{\n(.*?)\n\t\},", re.S)
RE_QUADRO = re.compile(r"(?m)^\t\t([A-Z][A-Z0-9_]*)\s*=\s*\{")


def sem_comentario(texto):
    return "\n".join(l for l in texto.split("\n")
                     if not l.lstrip().startswith("--"))


def servidores(pasta):
    saida = []
    for arq in sorted(os.listdir(pasta)):
        if arq.endswith(".lua") and "_Server_V" in arq:
            saida.append(os.path.join(pasta, arq))
    return saida


def verificar(pasta):
    """(erros, avisos) de uma pasta de Tool."""
    erros, avisos = [], []

    caminho_poses = None
    for arq in sorted(os.listdir(pasta)):
        if arq.startswith("Poses") and arq.endswith(".lua"):
            caminho_poses = os.path.join(pasta, arq)
            break
    fontes = servidores(pasta)
    if not (caminho_poses and fontes):
        return erros, avisos

    poses = open(caminho_poses, encoding="utf-8").read()
    # só o que vem DEPOIS de `SEQUENCIAS = {`: as poses soltas do topo têm a
    # mesma forma e virariam sequências fantasma
    corte = poses.find("SEQUENCIAS")
    bloco = poses[corte:] if corte >= 0 else poses
    marcas_por_seq = {}
    for nome, corpo in RE_SEQ_DEF.findall(bloco):
        # `[A-Z0-9_]`, com DÍGITO. O padrão anterior era `[A-Z_]+` e não pegava
        # `CORTE_1`: do lado do Server o `RE_BEAT` aceita dígito, do lado do
        # Poses não aceitava, e todo beat numerado saía como "a sequência não
        # tem" — falso positivo garantido para qualquer combo enumerado.
        marcas_por_seq[nome] = set(
            re.findall(r'marca = "([A-Z][A-Z0-9_]*)"', corpo))
    if not marcas_por_seq:
        return erros, avisos

    cenas = {}
    caminho_cam = os.path.join(pasta, "CutsceneCam.lua")
    if os.path.exists(caminho_cam):
        cam = sem_comentario(open(caminho_cam, encoding="utf-8").read())
        for nome, corpo in RE_CENA.findall(cam):
            quadros = set(RE_QUADRO.findall(corpo))
            if quadros:
                cenas[nome] = quadros

    tocadas = set()
    for caminho in fontes:
        fonte = sem_comentario(open(caminho, encoding="utf-8").read())
        rotulo = os.path.basename(caminho)

        # 0. O AJUDANTE CHAMADO EXISTE NO ARQUIVO
        #
        # Esta é a checagem mais boba do arquivo e a que pegou o pior defeito
        # que o repositório já teve: `gerar_servers_drama`, `_faker`, `_guest`
        # e `_noob` emitiam `despachar({...})` em toda habilidade e NUNCA
        # emitiam a definição. `attempt to call a nil value` na primeira linha
        # de cada `primaria` — 28 Tools de quatro conjuntos sem dano, sem VFX e
        # sem som, e os cinco outros verificadores passando verdes.
        #
        # A Regra nº 1 é o que torna isto conferível: a Tool é AUTOCONTIDA, e
        # o Server é UM arquivo. Um nome chamado ali e definido em lugar nenhum
        # do arquivo não tem como existir em tempo de execução.
        for ajudante in AJUDANTES:
            chama = re.search(r"(?<![\w.:])%s\(" % ajudante, fonte)
            if not chama:
                continue
            # A DEFINIÇÃO VALE EM QUALQUER INDENTAÇÃO.
            #
            # O padrão antigo exigia coluna 0 (`^local function x(`), e por
            # isso acusava `Atraso Mortal`, que define `estourar` ANINHADO
            # dentro da habilidade e o chama duas linhas abaixo — em escopo, e
            # correto. Falso positivo em verificador ensina quem escreve a
            # ignorá-lo, que é pior que checagem nenhuma.
            #
            # O preço é conhecido e aceito: uma definição aninhada CHAMADA DE
            # FORA do escopo dela passa batida. É um caso raro; o caso comum —
            # e o que custou 28 Tools — é o nome que não existe em lugar
            # nenhum do arquivo.
            define = re.search(
                r"(?m)^\s*(?:local\s+)?function\s+%s\s*\(|^\s*local\s+%s\b"
                % (ajudante, ajudante),
                fonte)
            if not define:
                erros.append("%s chama %s() e NÃO o define — `attempt to call "
                             "a nil value` na primeira linha da habilidade, e "
                             "a Tool inteira morre calada"
                             % (rotulo, ajudante))

        # 1. a sequência tocada existe
        nomes = set(RE_TOCA.findall(fonte))
        for a, b in RE_TOCA_TERNARIO.findall(fonte):
            nomes.update((a, b))
        tocadas.update(nomes)
        for nome in sorted(nomes - set(marcas_por_seq)):
            erros.append("%s toca a sequência %r, que o Poses não define — "
                         "o animator não acha e volta calado" % (rotulo, nome))

        # o nome pode estar guardado numa tabela e vir por índice
        tocadas.update(set(RE_LITERAL.findall(fonte)) & set(marcas_por_seq))

        # 2. o beat despachado existe naquela sequência
        todas = set()
        for conjunto in marcas_por_seq.values():
            todas.update(conjunto)
        for alvo, corpo in despachos(fonte):
            literal = re.fullmatch(r'"([A-Z][A-Z0-9_]*)"', alvo.strip())
            if literal:
                seq = literal.group(1)
                tem = marcas_por_seq.get(seq)
                se_qual = "%s" % seq
            else:
                seq, tem = None, todas
                se_qual = "a sequência que %s escolher" % alvo.strip()
            if tem is None:
                continue
            for beat in sorted(set(RE_BEAT.findall(corpo)) - tem):
                erros.append("%s: %s despacha o beat %r, que a sequência não "
                             "tem — o trabalho está escrito e nunca roda"
                             % (rotulo, se_qual, beat))

            # 3. beat de câmera tem enquadramento
            com_cam = set(RE_BEAT_CAM.findall(corpo))
            if com_cam and cenas:
                if not any(com_cam <= quadros for quadros in cenas.values()):
                    faltando = sorted(com_cam)
                    erros.append("%s: %s manda a câmera cortar em %s, e "
                                 "nenhuma cena do CutsceneCam tem esses "
                                 "quadros" % (rotulo, seq, ", ".join(faltando)))
            elif com_cam and not cenas:
                erros.append("%s: %s manda a câmera cortar, e a Tool não tem "
                             "CutsceneCam.lua" % (rotulo, seq))

    for nome in sorted(set(marcas_por_seq) - tocadas):
        avisos.append("sequência %r definida e nunca tocada" % nome)

    return erros, avisos


def main():
    print("")
    print("VERIFICAÇÃO DO BEAT")
    print(CINZA % "O fio entre o Server, o Poses.lua e o CutsceneCam.lua")
    print("")

    problemas, alertas, olhadas = 0, 0, 0
    for nome in sorted(os.listdir(TOOLS)):
        pasta = os.path.join(TOOLS, nome)
        if not os.path.isdir(pasta):
            continue
        erros, avisos = verificar(pasta)
        if not (erros or avisos):
            continue
        olhadas = olhadas + 1
        if erros:
            problemas = problemas + len(erros)
            print(VERMELHO % ("✗ %s" % nome))
            for e in erros:
                print("    %s" % e)
        elif avisos:
            alertas = alertas + len(avisos)
            print(AMARELO % ("• %s" % nome))
            for a in avisos:
                print(CINZA % ("    %s" % a))

    total = 0
    for nome in sorted(os.listdir(TOOLS)):
        pasta = os.path.join(TOOLS, nome)
        if os.path.isdir(pasta) and servidores(pasta):
            total = total + 1

    print("")
    if problemas:
        print(VERMELHO % ("%d BEAT(S) SEM DESTINO" % problemas))
        print(CINZA % "    Falham em SILÊNCIO: a animação roda e nada acontece.")
        return 1
    print(VERDE % ("BEAT OK — %d Tool(s) conferidas" % total))
    if alertas:
        print(CINZA % ("    %d aviso(s) acima: sequência escrita e não usada."
                       % alertas))
    print("")
    return 0


if __name__ == "__main__":
    sys.exit(main())
