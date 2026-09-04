#!/usr/bin/env python3
"""
verificar_sintaxe.py — Retro-Verse / Studios

Confere que todo `.lua` do repositório é sintaticamente válido.

    python3 TESTES/verificar_sintaxe.py

POR QUE ISTO EXISTE

    Duas Tools ficaram semanas no repositório com um ERRO DE SINTAXE, passando
    em todos os verificadores:

        local laçoVida = nil                     (Tools/Perturbacao)
        for _, conexao in ipairs(sentenca.laços) (Tools/Julgamento Final)

    `ç` não é letra para o lexer de Lua nem para o de Luau — identificador é
    `[A-Za-z_][A-Za-z0-9_]*`, e ponto final. Essas duas Tools NÃO COMPILAM no
    Studio, e nenhum dos sete verificadores existentes percebeu, porque todos
    eles leem o Lua como TEXTO: conferem nome de som, nome de VFX, marca de
    beat, referência fora da Tool. Nenhum tentava compilar.

    Foi achado por acidente, rodando `luac` à mão sobre as 129 Tools.

AS DUAS CHECAGENS, E POR QUE SÃO DUAS

    1. IDENTIFICADOR NÃO-ASCII — sempre roda, e é ERRO.

       É o defeito que aconteceu, e a única forma de ele entrar é alguém
       escrever em português numa variável, o que é natural neste repositório:
       os comentários são todos em português. Comentário pode; nome não.

    2. `luac -p` — roda só se `luac` existir, e é AVISO, nunca erro.

       ⚠️ `luac` é Lua 5.4, e o Roblox roda LUAU. As duas linguagens divergem:
          Luau aceita anotação de tipo (`local x: number`), `continue`, e
          interpolação de string — e `luac` rejeita as três.

          Por isso ele NÃO é o portão. Se um dia alguém escrever Luau moderno
          aqui, o aviso vai acusar código correto, e um verificador que acusa
          código correto ensina as pessoas a ignorar o vermelho. Ele fica como
          rede de segurança para o caso comum (o repositório hoje é Lua 5.4
          válido em 100% dos arquivos), e o julgamento fica com quem lê.
"""

import os
import re
import shutil
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
AMARELO = "\033[33m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

PASTAS = ("Tools", "ACERVO_RETROVERSE", "FERRAMENTAS")

#: identificador em posição de DECLARAÇÃO ou de ACESSO POR PONTO
RE_LOCAL = re.compile(r"\blocal\s+([A-Za-z_][^\s,=\(\)]*)")
RE_FUNCAO = re.compile(r"\bfunction\s+([A-Za-z_][^\s\(]*)")
RE_CAMPO = re.compile(r"\.([A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F][^\s\(\)\.,\[\]=]*)")


def sem_comentario(codigo):
    """Tira comentário de linha e de bloco. Comentário em português é a norma
    aqui — cobrar acento neles seria cobrar o idioma do repositório."""
    saida, nivel = [], None
    for linha in codigo.splitlines():
        if nivel is not None:
            fecha = "]" + nivel + "]"
            i = linha.find(fecha)
            if i >= 0:
                linha, nivel = linha[i + len(fecha):], None
            else:
                linha = ""
        if nivel is None:
            m = re.search(r"--\[(=*)\[", linha)
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


def sem_string(codigo):
    """Tira literal de string. `"café"` é dado, não identificador."""
    codigo = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', codigo)
    codigo = re.sub(r"'(?:[^'\\\n]|\\.)*'", "''", codigo)
    codigo = re.sub(r"\[(=*)\[.*?\]\1\]", "[[]]", codigo, flags=re.S)
    return codigo


def nao_ascii(caminho):
    """(linha, trecho) de todo identificador com caractere fora do ASCII."""
    bruto = open(caminho, encoding="utf-8", errors="replace").read()
    limpo = sem_string(sem_comentario(bruto))
    achados = []
    for n, linha in enumerate(limpo.splitlines(), 1):
        for regex in (RE_LOCAL, RE_FUNCAO, RE_CAMPO):
            for m in regex.finditer(linha):
                nome = m.group(1)
                if any(ord(c) > 127 for c in nome):
                    achados.append((n, nome))
    return achados


def arquivos():
    for pasta in PASTAS:
        raiz = os.path.join(RAIZ, pasta)
        if not os.path.isdir(raiz):
            continue
        for dirpath, _dirs, nomes in os.walk(raiz):
            for nome in sorted(nomes):
                if nome.endswith(".lua") or nome.endswith(".luau"):
                    yield os.path.join(dirpath, nome)


def main():
    luac = shutil.which("luac5.4") or shutil.which("luac")

    print("")
    print("VERIFICAÇÃO DE SINTAXE")
    print(CINZA % "identificador não-ASCII é ERRO; o passe do luac é AVISO")
    print("")

    erros, avisos, total = [], [], 0

    for caminho in arquivos():
        total = total + 1
        rel = os.path.relpath(caminho, RAIZ)

        for linha, nome in nao_ascii(caminho):
            erros.append("%s:%d  identificador %r tem caractere fora do ASCII "
                         "— o lexer de Luau não aceita, o arquivo NÃO COMPILA"
                         % (rel, linha, nome))

        if luac:
            r = subprocess.run([luac, "-p", caminho],
                               capture_output=True, text=True)
            if r.returncode != 0:
                msg = (r.stderr or r.stdout).strip().splitlines()
                avisos.append("%s  %s" % (rel, msg[0] if msg else "?"))

    for e in erros:
        print(VERMELHO % ("✗ " + e))

    if avisos:
        print("")
        print(AMARELO % ("AVISO — %d arquivo(s) que o luac (Lua 5.4) recusou"
                         % len(avisos)))
        print(CINZA % "  luac NÃO é Luau: anotação de tipo, `continue` e")
        print(CINZA % "  interpolação são válidos no Roblox e recusados aqui.")
        for a in avisos:
            print(AMARELO % ("  " + a))

    print("")
    if erros:
        print(VERMELHO % ("%d ERRO(S) DE SINTAXE" % len(erros)))
        return 1
    print(VERDE % ("SINTAXE OK — %d arquivo(s)%s"
                   % (total, "" if luac else " (sem luac; só a checagem ASCII)")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
