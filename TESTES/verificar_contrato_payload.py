#!/usr/bin/env python3
"""
verificar_contrato_payload.py — Retro-Verse / Studios

Confere o contrato do payload entre o Server e o Client de cada Tool.

    python3 TESTES/verificar_contrato_payload.py

POR QUE ISTO EXISTE

    O `Escudo Bumerangue` passou meses com a habilidade que dá nome a ele
    QUEBRADA, e nenhum dos oito verificadores percebeu:

        Server  :  vfx("PROJETIL", { ..., pecaNome = personagem.Name })
        Client  :  if dados.alvoNome then dados.alvo = parteDe(...) end
        VFXModule: local volta = (d and d.peca) or nil
                   ...
                   if not volta then VFX.Parar(id) end

    O Server manda `pecaNome`. O Client resolve `alvoNome`. Ninguém transforma
    `pecaNome` em instância, então `d.peca` é sempre `nil` — e o escudo SOME no
    alcance máximo em vez de voltar.

    O servidor continuava fazendo o retorno e o dano. Só o desenho parava. Não
    há erro, não há aviso, e o `.rbxmx` é perfeitamente válido.

POR QUE NENHUM OUTRO VERIFICADOR PEGAVA

    Cada um cobre UMA porta, e esta ficava entre duas:

      `verificar_rbxmx`         confere que o VFX transmitido existe no módulo
                                — e `PROJETIL` existe. O tipo estava certo; o
                                CAMPO é que se perdia.
      `verificar_vfx_chamadas`  confere a porta Client → VFXModule.
      `verificar_pack_vfx`      confere os argumentos das chamadas ao pack.

    Nenhum olhava a porta Server → Client. Esta olha.

A REGRA

    Instância NÃO ATRAVESSA RemoteEvent de forma confiável quando o alvo pode
    não existir no cliente (streaming, alvo fora de alcance). A casa resolve
    isso mandando o NOME e resolvendo no cliente — e a convenção é o sufixo
    `Nome`.

    Então: todo campo `<x>Nome` que um Server manda tem de ter, no Client da
    MESMA Tool, uma linha que o resolva.

    E A SEVERIDADE DEPENDE DE ALGUÉM CONSUMIR O CAMPO:

      ERRO   o `VFXModule` lê `d.<x>` — ele recebe `nil` e o efeito morre
             calado. É o caso do `Escudo Bumerangue`.
      AVISO  ninguém lê — o campo é peso morto no pacote. Custa banda, não
             quebra nada.

    A primeira versão desta checagem não separava os dois e acusou cinco Tools
    que só desperdiçam payload. Verificador que dá o mesmo vermelho para
    "quebrado" e "desperdiçado" ensina a ignorar o vermelho.
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

ABERTURA_LONGA = re.compile(r"--\[(=*)\[")

#: o Server ESCREVE  `algumaCoisaNome = ...` dentro da tabela do payload
RE_ENVIA = re.compile(r"\b(\w+Nome)\s*=")
#: o Client LÊ `dados.algumaCoisaNome` ou `d.algumaCoisaNome`
RE_RESOLVE = re.compile(r"\b(?:dados|d)\.(\w+Nome)\b")


def sem_comentario(codigo):
    """Comentário não é contrato. Sem isto, um comentário que EXPLICA um campo
    antigo passa a valer como se o campo ainda fosse mandado."""
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


def ler(caminho):
    if not os.path.exists(caminho):
        return ""
    return sem_comentario(open(caminho, encoding="utf-8").read())


def main():
    print("")
    print("CONTRATO DO PAYLOAD — Server → Client")
    print(CINZA % "todo `<x>Nome` mandado tem de ser resolvido no Client da mesma Tool")
    print("")

    erros, avisos, conferidas = [], [], 0

    for pasta in sorted(os.listdir(TOOLS)):
        caminho = os.path.join(TOOLS, pasta)
        if not os.path.isdir(caminho) or pasta.startswith("_"):
            continue

        servers = [f for f in sorted(os.listdir(caminho))
                   if "_Server_V" in f and f.endswith(".lua")]
        if not servers:
            continue

        enviados = set()
        for arq in servers:
            enviados |= set(RE_ENVIA.findall(ler(os.path.join(caminho, arq))))
        if not enviados:
            continue

        conferidas = conferidas + 1
        cliente = ler(os.path.join(caminho, "Client.lua"))
        resolvidos = set(RE_RESOLVE.findall(cliente))
        modulo = ler(os.path.join(caminho, "VFXModule.lua"))

        # ⚠️ A SEVERIDADE DEPENDE DE ALGUÉM CONSUMIR O CAMPO, e a primeira
        #    versão desta checagem não fazia essa distinção — acusava cinco
        #    Tools que estão apenas desperdiçando payload.
        #
        #    `alvoNome` mandado, não resolvido e não lido por ninguém é peso
        #    morto no pacote: custa banda, não quebra nada.
        #
        #    `pecaNome` mandado, não resolvido, e o `VFXModule` lendo `d.peca`
        #    é outra coisa: o módulo recebe `nil` onde espera uma instância, e
        #    a habilidade morre calada. Foi o `Escudo Bumerangue`.
        #
        #    Verificador que dá o mesmo vermelho para os dois ensina a ignorar
        #    o vermelho.
        for campo in sorted(enviados - resolvidos):
            curto = campo[:-4]   # `pecaNome` -> `peca`
            lido = re.search(r"\b(?:d|dados)\.%s\b" % re.escape(curto), modulo)
            if lido:
                erros.append(
                    "%s: o Server manda %r, o Client NÃO o resolve, e o "
                    "VFXModule LÊ `d.%s` — ele recebe `nil` e o efeito morre "
                    "calado" % (pasta, campo, curto))
            else:
                avisos.append(
                    "%s: manda %r que ninguém resolve nem lê — payload morto"
                    % (pasta, campo))

        # o contrário é barato, mas denuncia meio par renomeado
        for campo in sorted(resolvidos - enviados):
            avisos.append("%s: o Client resolve %r, que nenhum Server manda"
                          % (pasta, campo))

    for e in erros:
        print(VERMELHO % ("✗ " + e))

    if avisos:
        print("")
        print(AMARELO % ("AVISO — %d resolução sem remetente" % len(avisos)))
        for a in avisos:
            print(AMARELO % ("  " + a))

    print("")
    if erros:
        print(VERMELHO % ("%d CONTRATO(S) QUEBRADO(S)" % len(erros)))
        return 1
    print(VERDE % ("CONTRATO OK — %d Tool(s) que mandam nome" % conferidas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
