-- Client.lua
-- Script com RunContext = Client — Genese  (conjunto CRIAÇÃO)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. `RunContext = Client` roda em TODO cliente, e nada saiu de dentro
-- da Tool.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica.
--
-- E A CÂMERA TAMBÉM NÃO. Quem enquadra é a `CutsceneCam`, que é outro
-- `Script` com `RunContext = Client` — só no `Demiurgo`. Este arquivo não
-- toca em `workspace.CurrentCamera` em lugar nenhum.
--
-- DOIS BOTÕES DE CELULAR, EM ALTURAS DIFERENTES
--
--   Com a mesma altura os dois empilham e o de baixo fica inalcançável.
--
-- Gerado por FERRAMENTAS/gerar_servers_criacao.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO_R = "Criacao_CriacaoGenese_R"
local ACAO_T = "Criacao_CriacaoGenese_T"
local ALCANCE_MIRA = 70

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" or tipo == "PARAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {})
end)

--══════════════════════════════════════════════════════════════
-- MIRA E ENTRADA — só o dono
--══════════════════════════════════════════════════════════════

local function souODono()
	local pai = Tool.Parent
	if not pai then return false end
	if not pai:FindFirstChildOfClass("Humanoid") then return false end
	return Players:GetPlayerFromCharacter(pai) == jogador
end

--- Onde o jogador aponta, limitado ao alcance.
---
--- A ORIGEM FAZIA ISTO POR `RemoteFunction`: `DirectionInvoker:InvokeClient`,
--- e o `Celestial Staff` chamava TRÊS VEZES por fóton, DENTRO de um laço. O
--- servidor invocava o cliente e ficava esperando a resposta — cliente que
--- não responde trava a thread do servidor até o timeout. Aqui a mira viaja
--- junto do pedido, num sentido só.
local function mira()
	local personagem = jogador.Character
	local origem = personagem and personagem:FindFirstChild("HumanoidRootPart")
	rato = rato or jogador:GetMouse()
	local alvo = rato and rato.Hit and rato.Hit.Position
	if not origem then return alvo or Vector3.new() end
	if not alvo then return origem.Position + origem.CFrame.LookVector * 20 end
	local delta = alvo - origem.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return origem.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end

local function ligarEntrada()
	ContextActionService:BindAction(ACAO_R, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("R", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)
	ContextActionService:SetTitle(ACAO_R, "Materia")
	ContextActionService:SetPosition(ACAO_R, UDim2.new(1, -150, 1, -190))

	ContextActionService:BindAction(ACAO_T, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("T", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.T, Enum.KeyCode.ButtonL1)
	ContextActionService:SetTitle(ACAO_T, "Primeiro Instante")
	-- 70 px acima do R: com a mesma altura os dois empilham
	ContextActionService:SetPosition(ACAO_T, UDim2.new(1, -150, 1, -260))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO_R)
	ContextActionService:UnbindAction(ACAO_T)
end

--══════════════════════════════════════════════════════════════
-- CICLO
--══════════════════════════════════════════════════════════════

Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira())
end)

Tool.Equipped:Connect(function()
	if not souODono() then return end
	equipado = true
	ligarEntrada()
end)

local function aoGuardar()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end

Tool.Unequipped:Connect(aoGuardar)
Tool.Destroying:Connect(aoGuardar)
