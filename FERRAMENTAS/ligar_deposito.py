#!/usr/bin/env python3
"""
ligar_deposito.py — Retro-Verse / Studios

Liga o `DepositoVFX` (Regra nº 2) nos Servers e nos VFXModules — nos geradores
e nos arquivos já gerados, para os dois ficarem iguais.

    python3 FERRAMENTAS/ligar_deposito.py

O QUE ELE FAZ, E POR QUE SÃO SÓ DUAS EMENDAS

    Toda a mecânica mora no módulo. Aqui só entram os dois pontos de contato:

    SERVER    `Deposito.ligar(Tool)` no fim do arquivo. O módulo faz o resto —
              instala na troca de pai, desinstala no `Destroying`, e conta as
              referências.

    VFXMODULE `acharPack` passa a perguntar ao depósito ANTES de olhar dentro
              de si. As duas portas, na ordem da regra.

    Uma emenda por arquivo, no mesmo lugar em todos. Espalhar a lógica por 94
    Servers é o que garantiria que um deles ficasse para trás — e o modo de
    falhar seria silencioso.
"""

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

REQUIRE = 'local Deposito  = require(Tool:WaitForChild("DepositoVFX"))'

RODAPE = '''
--═══════════════════════════════════════════════════════════════
-- REGRA Nº 2 — o VFX sai da Tool quando ela chega ao jogador
--
-- Uma linha. O `DepositoVFX` liga o ciclo inteiro sozinho: instala na troca de
-- pai (mochila OU mão), desinstala no `Tool.Destroying`, e conta as referências
-- para não arrancar o molde debaixo de quem ainda está com a Tool.
--
-- Ver DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
'''

REQUIRE_MOD = 'local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))'

ACHAR_VELHO = '''	raizPack = script:FindFirstChild(PACK.PASTA)
	return raizPack'''
ACHAR_NOVO = '''	-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois.
	-- A segunda não é redundância — num place vazio ninguém montou depósito
	-- nenhum, e até o primeiro `Equipped` o molde ainda está aqui dentro.
	raizPack = Deposito.achar(script, PACK.PASTA)
		or script:FindFirstChild(PACK.PASTA)
	return raizPack'''


def emendar_server(texto):
    if "DepositoVFX" in texto:
        return texto, False
    # o require entra junto dos outros, depois do último `require(Tool:...)`
    achados = list(re.finditer(
        r'(?m)^local \w+\s*=\s*require\(Tool:WaitForChild\("[^"]+"\)\)$', texto))
    if not achados:
        return texto, False
    fim = achados[-1].end()
    texto = texto[:fim] + "\n" + REQUIRE + texto[fim:]
    return texto.rstrip() + "\n" + RODAPE, True


def emendar_modulo(texto):
    if "DepositoVFX" in texto or ACHAR_VELHO not in texto:
        return texto, False
    texto = texto.replace(ACHAR_VELHO, ACHAR_NOVO)
    # o require vai depois do bloco de serviços, antes do primeiro `local VFX`
    m = re.search(r"(?m)^local VFX = \{\}$", texto)
    if not m:
        return texto, False
    return texto[:m.start()] + REQUIRE_MOD + "\n\n" + texto[m.start():], True


def main():
    servers, modulos = 0, 0

    for pasta, _sub, arqs in os.walk(os.path.join(RAIZ, "Tools")):
        for a in sorted(arqs):
            if "_Server_V" in a and a.endswith(".lua"):
                c = os.path.join(pasta, a)
                novo, mudou = emendar_server(open(c, encoding="utf-8").read())
                if mudou:
                    open(c, "w", encoding="utf-8").write(novo)
                    servers = servers + 1
            elif a == "VFXModule.lua":
                c = os.path.join(pasta, a)
                novo, mudou = emendar_modulo(open(c, encoding="utf-8").read())
                if mudou:
                    open(c, "w", encoding="utf-8").write(novo)
                    modulos = modulos + 1

    # e os geradores, para o próximo `gerar_*` já sair ligado
    ger = 0
    for a in sorted(os.listdir(os.path.join(RAIZ, "FERRAMENTAS", "dados"))):
        if not a.startswith("VFXModule_") or not a.endswith(".lua"):
            continue
        c = os.path.join(RAIZ, "FERRAMENTAS", "dados", a)
        novo, mudou = emendar_modulo(open(c, encoding="utf-8").read())
        if mudou:
            open(c, "w", encoding="utf-8").write(novo)
            ger = ger + 1

    print("  %d Server(s) ligados" % servers)
    print("  %d VFXModule(s) das Tools com as duas portas" % modulos)
    print("  %d VFXModule_*.lua de dados atualizados" % ger)
    return 0


if __name__ == "__main__":
    sys.exit(main())
