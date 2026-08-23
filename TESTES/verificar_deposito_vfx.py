#!/usr/bin/env python3
"""
verificar_deposito_vfx.py — Retro-Verse / Studios

Confere a REGRA Nº 2 (`DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md`) Tool a Tool.

    python3 TESTES/verificar_deposito_vfx.py

O QUE ELE COBRA

    1. a Tool tem `DepositoVFX` e `ChaveVFX`, e a chave é ÚNICA no repositório;
    2. o Server chama `Deposito.ligar(Tool)` — instalar e desinstalar vêm de
       graça, é o módulo que os liga;
    3. quem lê molde tem as DUAS PORTAS, e o depósito vem primeiro;
    4. ninguém instala pelo cliente — `ReplicatedStorage` replica do servidor
       para os clientes, e um cliente que mova instância para lá move só para
       ele mesmo. Esse bug já custou uma leva inteira aqui.

    A checagem 3 é a que pega o defeito caro. O depósito MOVE `Efeitos` e
    `Moldes` para fora da Tool; um módulo que só saiba olhar para dentro dela
    para de achar a própria malha no instante em que a Tool chega ao jogador —
    e falha em silêncio, desenhando nada.
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
AMARELO = "\033[33m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

#: quem lê molde: as duas formas que existem no repositório
LE_PACK = re.compile(r"raizPack\s*=\s*Deposito\.achar\(")
LE_MOLDES = re.compile(r"pastaMoldes\s*=\s*Deposito\.achar\(")
#: e as formas ANTIGAS, que só olham para dentro da Tool
SO_DENTRO_PACK = re.compile(r"raizPack\s*=\s*script:FindFirstChild\(")
SO_DENTRO_MOLDES = re.compile(r"pastaMoldes\s*=\s*tool and tool:FindFirstChild\(")


def sem_comentario(texto):
    return "\n".join(l for l in texto.split("\n")
                     if not l.lstrip().startswith("--"))


def chave_do_xml(caminho):
    """`ChaveVFX` declarada no `.rbxmx` avulso da Tool."""
    if not os.path.exists(caminho):
        return None
    try:
        raiz = ET.parse(caminho).getroot()
    except ET.ParseError:
        return None
    for item in raiz.iter("Item"):
        if item.get("class") != "StringValue":
            continue
        props = item.find("Properties")
        nome, valor = None, None
        for e in props if props is not None else []:
            if e.get("name") == "Name":
                nome = e.text
            elif e.get("name") == "Value":
                valor = e.text
        if nome == "ChaveVFX":
            return valor
    return None


def main():
    erros, avisos = [], []
    chaves = {}
    conferidas = 0

    for tool in sorted(os.listdir(TOOLS)):
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            continue
        servers = [f for f in sorted(os.listdir(pasta))
                   if "_Server_V" in f and f.endswith(".lua")]
        if not servers:
            continue
        conferidas = conferidas + 1

        # 1. chave presente e única
        chave = chave_do_xml(os.path.join(pasta, "%s.rbxmx" % tool))
        if chave is None:
            avisos.append("%s: sem ChaveVFX no .rbxmx — remonte" % tool)
        elif chave in chaves:
            erros.append("%s e %s dividem a ChaveVFX %r — dois modelos "
                         "escrevendo na MESMA pasta do depósito"
                         % (tool, chaves[chave], chave))
        else:
            chaves[chave] = tool

        # 2. o Server liga o ciclo
        for arq in servers:
            fonte = sem_comentario(
                open(os.path.join(pasta, arq), encoding="utf-8").read())
            if "Deposito.ligar(Tool)" not in fonte:
                erros.append("%s/%s não chama Deposito.ligar(Tool) — os moldes "
                             "nunca saem da Tool e nunca voltam" % (tool, arq))
            # 4. instalar é do servidor
            if re.search(r"Deposito\.instalar\(", fonte) \
                    and "RunService:IsServer" not in fonte:
                avisos.append("%s/%s instala à mão; prefira `ligar`" % (tool, arq))

        cliente = os.path.join(pasta, "Client.lua")
        if os.path.exists(cliente):
            fonte = sem_comentario(open(cliente, encoding="utf-8").read())
            if re.search(r"Deposito\.(instalar|desinstalar)\(", fonte):
                erros.append("%s/Client.lua mexe no depósito — cliente não "
                             "replica, o efeito volta a ser local" % tool)

        # 3. as duas portas
        modulo = os.path.join(pasta, "VFXModule.lua")
        if os.path.exists(modulo):
            fonte = sem_comentario(open(modulo, encoding="utf-8").read())
            if SO_DENTRO_PACK.search(fonte) and not LE_PACK.search(fonte):
                erros.append("%s/VFXModule.lua acha o Pack só DENTRO da Tool — "
                             "o depósito move a pasta e ele para de achar" % tool)
            if SO_DENTRO_MOLDES.search(fonte) and not LE_MOLDES.search(fonte):
                erros.append("%s/VFXModule.lua acha os Moldes só DENTRO da "
                             "Tool — o depósito move a pasta e ele para de "
                             "achar" % tool)

    for e in erros:
        print(VERMELHO % ("✗ " + e))
    for a in avisos:
        print(AMARELO % ("• " + a))
    print("")
    if erros:
        print(VERMELHO % ("%d PROBLEMA(S) NO DEPÓSITO" % len(erros)))
        return 1
    print(VERDE % ("DEPÓSITO OK — %d Tool(s), %d chave(s) distinta(s)"
                   % (conferidas, len(chaves))))
    if avisos:
        print(CINZA % ("    %d aviso(s) acima." % len(avisos)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
