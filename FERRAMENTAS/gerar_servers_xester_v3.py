#!/usr/bin/env python3
"""
gerar_servers_xester_v3.py — Retro-Verse / Studios

Escreve o `Server`, o `Client` e (onde há cutscene) o `CutsceneCam` das **13
Tools** do Xester: 7 na Forma 1, 6 na Forma 2.

    python3 FERRAMENTAS/gerar_servers_xester_v3.py

TRÊS CANAIS DE ENTRADA, E CADA UM COM UM ASSUNTO

    `Tool.Activated`  a primária. §9: nunca em botão.
    `Tool.Deactivated` o lado de SOLTAR — só o `Dragons Requiem` usa, porque só
                      ele carrega. Ele viaja pelo mesmo `VFXRemote`, com a fase
                      no payload: um remote a mais seria uma porta a mais para
                      validar por uma coisa que é a metade de trás do clique.
    `AcaoRemote`      a habilidade Extra, com botão de celular. Só existe nas
                      DUAS Tools que têm Extra de verdade: `Eclipse Deck` (F,
                      The Final Deal) e `Royal Guard` (R, o baque dos quatro).

    A mira móvel do `Prism` também anda pelo `VFXRemote`, com a fase `MIRA`.
    Ela não é habilidade: não passa por recarga nem por `podeAgir`, e o
    servidor só a aceita com o prisma de pé.

O PREÂMBULO É UM SÓ

    `despachar`, dano, alvos, empurrão, tombo, a passiva, o cajado e a aura
    são iguais nas treze. Treze cópias de cada um seriam treze versões de cada
    bug — foi assim que `molde` sumiu de um módulo e só o console do jogo
    pegou.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(RAIZ, "FERRAMENTAS", "dados")
ANIMATOR = os.path.join(RAIZ, "ACERVO_RETROVERSE", "_AUTORAL_RetroVerse",
                        "R6_CFRAME", "R6CFrameAnimator_V2.lua")
VFXMODULE = os.path.join(DADOS, "VFXModule_Xester.lua")
PEDACOS = os.path.join(DADOS, "xester_v3")

sys.path.insert(0, DADOS)
from servers_xester_v3 import CONJUNTO, GUARDA_SIMPLES  # noqa: E402


def pedaco(nome):
    with open(os.path.join(PEDACOS, nome), encoding="utf-8") as f:
        return f.read()


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (Xester, Forma {forma})
--
-- POR QUE NÃO É LocalScript
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o desenho com `FireAllClients` e ele CHEGA em
--   todo mundo — mas o único ouvinte seria o de quem está segurando, e o VFX
--   apareceria só para o portador. `RunContext = Client` roda em TODO cliente.
--
--   A ENTRADA continua sendo só do dono: `souODono()` confere antes de tudo.
--   Rodar em todo cliente não é o mesmo que aceitar de todos.
--
-- A ANIMAÇÃO NÃO ESTÁ AQUI: o rig é do servidor, porque `Weld` criado no
-- cliente não replica e os outros jogadores viam o portador parado.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester_v3.py.

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local VFX       = require(Tool:WaitForChild("VFXModule"))
{cliente_remotes}
local ALCANCE_MIRA = 60

local equipado = false
local rato = nil
{cliente_estado}
--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {{}})
end)

--══════════════════════════════════════════════════════════════
-- MIRA — só o dono
--══════════════════════════════════════════════════════════════

local function souODono()
	local pai = Tool.Parent
	if not pai then return false end
	if not pai:FindFirstChildOfClass("Humanoid") then return false end
	return Players:GetPlayerFromCharacter(pai) == jogador
end

local function mira()
	local personagem = jogador.Character
	local origem = personagem and personagem:FindFirstChild("HumanoidRootPart")
	rato = rato or jogador:GetMouse()
	local alvo = rato and rato.Hit and rato.Hit.Position
	if not origem then return alvo or Vector3.new() end
	if not alvo then
		return origem.Position + origem.CFrame.LookVector * 20
	end
	local delta = alvo - origem.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return origem.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end
{cliente_extra}
--══════════════════════════════════════════════════════════════
-- CICLO
--══════════════════════════════════════════════════════════════

Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira(){fase_ativar})
end)
{ligacao_desativar}
Tool.Equipped:Connect(function()
	if not souODono() then return end
	equipado = true
{cliente_ao_equipar}end)

local function aoGuardar()
	equipado = false
{cliente_ao_guardar}	VFX.LimparTudo()
end

Tool.Unequipped:Connect(aoGuardar)
Tool.Destroying:Connect(aoGuardar)
'''

#: o bloco de bind da Extra, só nas duas Tools que têm uma
CLIENTE_EXTRA = '''
--══════════════════════════════════════════════════════════════
-- A HABILIDADE EXTRA
--
-- `BindAction(nome, fn, criarBotaoDeToque, ...)` — o terceiro argumento faz o
-- Roblox desenhar o botão sozinho, que é o que atende o celular. É UMA Extra,
-- então é um botão só, e ele não disputa espaço com nada.
--══════════════════════════════════════════════════════════════

local ACAO = "Xester_{sufixo}_Extra"

local function ligarEntrada()
	ContextActionService:BindAction(ACAO, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer(mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.{tecla_extra}, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle(ACAO, "{rotulo_extra}")
	ContextActionService:SetPosition(ACAO, UDim2.new(1, -150, 1, -190))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO)
end
'''

#: a mira móvel do Prisma
CLIENTE_MIRA = '''
--══════════════════════════════════════════════════════════════
-- A MIRA MÓVEL
--
-- Enquanto o prisma está de pé, o ponto de impacto segue o mouse. O cliente
-- manda o ponto; quem decide se ele ainda vale é o SERVIDOR, que sabe se o
-- prisma existe. 12 pacotes por segundo bastam para o feixe acompanhar —
-- um `RenderStepped` mandaria 60 por um alvo que anda devagar.
--══════════════════════════════════════════════════════════════

local PASSO_MIRA = 0.08
local DURACAO_MIRA = 5.4

local function seguirComOMouse()
	if seguindo then return end
	seguindo = true
	task.spawn(function()
		local ate = os.clock() + DURACAO_MIRA
		while seguindo and equipado and os.clock() < ate do
			VFXRemote:FireServer(mira(), "MIRA")
			task.wait(PASSO_MIRA)
		end
		seguindo = false
	end)
end
'''


def escrever_servidor(tool, d):
    canal = None
    if d["extra"] in ("F", "R"):
        canal = "acao"
    elif d["extra"] == "SOLTAR":
        canal = "soltar"
    elif d["extra"] == "MIRA":
        canal = "mira"

    remotes = ""
    if canal == "acao":
        remotes = 'local AcaoRemote = Tool:WaitForChild("AcaoRemote")\n'
    if d["cutscene"]:
        remotes = remotes + ('local CutsceneRemote = '
                             'Tool:WaitForChild("CutsceneRemote")\n')

    estado = d["estado"]
    if estado and not estado.endswith("\n"):
        estado = estado + "\n"

    corpo = pedaco("pre_a.lua").format(
        objeto=d["objeto"], tool=tool, forma=d["forma"],
        rotulo_m1=d["rotulo_m1"],
        origem="".join("--   %s\n" % linha for linha in d["origem"]),
        remotes=remotes, arquetipo=d["arquetipo"], cfg=d["cfg"],
        estado=estado)

    corpo = corpo + pedaco("comum_baixo.lua")
    corpo = corpo + (pedaco("pre_cam.lua") if d["cutscene"]
                     else pedaco("pre_semcam.lua"))
    corpo = corpo + pedaco("pre_c.lua")
    corpo = corpo + pedaco("comum_alto.lua")

    # `primaria`, `extra`, `limparTudo` e `segundaEtapa` são globais do
    # arquivo: declaradas no topo, atribuídas aqui.
    corpo = corpo + d["corpo"]

    guarda = d["guarda_m1"] or GUARDA_SIMPLES
    if canal == "soltar":
        guarda = ("\tif fase == \"End\" then\n"
                  "\t\textra(mira)\n"
                  "\t\treturn\n"
                  "\tend\n") + guarda
    elif canal == "mira":
        guarda = ("\t-- a mira móvel não é habilidade: não passa por recarga\n"
                  "\tif fase == \"MIRA\" then\n"
                  "\t\textra(mira)\n"
                  "\t\treturn\n"
                  "\tend\n") + guarda

    ligacao_extra = ""
    if canal == "acao":
        ligacao_extra = '''
AcaoRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador then return end
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente(20)
	if not podeAgir() then return end
	if not pronto(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	extra(mira)
end)
'''

    rodape = pedaco("rodape.lua").format(
        guarda_m1=guarda, ligacao_extra=ligacao_extra, sufixo=d["sufixo"],
        ao_equipar=d["ao_equipar"], ao_guardar=d["ao_guardar"])

    # `podeAgir` é chamado pelo caminho de soltar, que precisa passar mesmo
    # com `ocupado` — a carga É o estado ocupado.
    if canal == "soltar":
        rodape = rodape.replace(
            "VFXRemote.OnServerEvent:Connect(function(quem, mira)\n"
            "\tif quem ~= jogador or not podeAgir() then return end",
            "VFXRemote.OnServerEvent:Connect(function(quem, mira, fase)\n"
            "\tif quem ~= jogador then return end\n"
            "\t-- soltar tem de passar mesmo com `ocupado`: a carga É o estado\n"
            "\t-- ocupado, e exigir que ela acabe tornaria isto impossível.\n"
            "\tif fase ~= \"End\" and not podeAgir() then return end")
    elif canal == "mira":
        rodape = rodape.replace(
            "VFXRemote.OnServerEvent:Connect(function(quem, mira)\n"
            "\tif quem ~= jogador or not podeAgir() then return end",
            "VFXRemote.OnServerEvent:Connect(function(quem, mira, fase)\n"
            "\tif quem ~= jogador then return end\n"
            "\tif fase ~= \"MIRA\" and not podeAgir() then return end")

    return corpo + rodape


def escrever_cliente(tool, d):
    canal = None
    if d["extra"] in ("F", "R"):
        canal = "acao"
    elif d["extra"] == "SOLTAR":
        canal = "soltar"
    elif d["extra"] == "MIRA":
        canal = "mira"

    remotes, estado, extra_bloco = "", "", ""
    ao_equipar, ao_guardar, fase, desativar = "", "", "", ""

    if canal == "acao":
        remotes = 'local AcaoRemote = Tool:WaitForChild("AcaoRemote")\n'
        extra_bloco = CLIENTE_EXTRA.format(sufixo=d["sufixo"],
                                           tecla_extra=d["extra"],
                                           rotulo_extra=d["rotulo_extra"])
        ao_equipar = "\tligarEntrada()\n"
        ao_guardar = "\tdesligarEntrada()\n"
    elif canal == "soltar":
        desativar = '''
--- O lado de SOLTAR. `Tool.Deactivated` é o par de `Tool.Activated`, e o par
--- viaja pelo mesmo remote: um `RemoteEvent` a mais seria uma porta a mais
--- para validar por algo que é a metade de trás do mesmo clique.
Tool.Deactivated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira(), "End")
end)
'''
        fase = ', "Begin"'
    elif canal == "mira":
        estado = "local seguindo = false\n"
        extra_bloco = CLIENTE_MIRA
        ao_equipar = ""
        ao_guardar = "\tseguindo = false\n"

    corpo = CLIENTE.format(
        tool=tool, forma=d["forma"], cliente_remotes=remotes,
        cliente_estado=estado, cliente_extra=extra_bloco,
        fase_ativar=fase, ligacao_desativar=desativar,
        cliente_ao_equipar=ao_equipar, cliente_ao_guardar=ao_guardar)

    if canal == "mira":
        corpo = corpo.replace(
            "\tVFXRemote:FireServer(mira())\nend)",
            "\tVFXRemote:FireServer(mira())\n\tseguirComOMouse()\nend)")
    return corpo


def main():
    if not os.path.exists(ANIMATOR):
        print("faltando: %s" % ANIMATOR)
        return 1
    if not os.path.exists(VFXMODULE):
        print("faltando: %s" % VFXMODULE)
        return 1
    cutscene = pedaco("cutscenecam.lua")

    for tool, d in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s — rode preparar_xester_v3.py antes" % tool)
            return 1

        servidor = escrever_servidor(tool, d)
        with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
                  encoding="utf-8") as f:
            f.write(servidor)
        with open(os.path.join(pasta, "Client.lua"), "w",
                  encoding="utf-8") as f:
            f.write(escrever_cliente(tool, d))
        if d["cutscene"]:
            with open(os.path.join(pasta, "CutsceneCam.lua"), "w",
                      encoding="utf-8") as f:
                f.write(cutscene.replace("{tool}", tool))

        shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
        shutil.copyfile(VFXMODULE, os.path.join(pasta, "VFXModule.lua"))

        print("  %-28s F%d  %5d linhas · %s%s"
              % (tool, d["forma"], servidor.count("\n") + 1,
                 "M1 + Extra %s" % d["extra"] if d["extra"] else "só M1",
                 " · cutscene" if d["cutscene"] else ""))
    print("")
    print("13 Tool(s) escritas — 7 na Forma 1, 6 na Forma 2.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
