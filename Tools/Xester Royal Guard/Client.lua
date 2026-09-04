-- Client.lua
-- Script com RunContext = Client — Xester Royal Guard  (Xester, Forma 1)
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
local AcaoRemote = Tool:WaitForChild("AcaoRemote")

local ALCANCE_MIRA = 60

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {})
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

--══════════════════════════════════════════════════════════════
-- A HABILIDADE EXTRA
--
-- `BindAction(nome, fn, criarBotaoDeToque, ...)` — o terceiro argumento faz o
-- Roblox desenhar o botão sozinho, que é o que atende o celular. É UMA Extra,
-- então é um botão só, e ele não disputa espaço com nada.
--══════════════════════════════════════════════════════════════

local ACAO = "Xester_XesterGuarda_Extra"

local function ligarEntrada()
	ContextActionService:BindAction(ACAO, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer(mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle(ACAO, "Baque dos Reis")
	ContextActionService:SetPosition(ACAO, UDim2.new(1, -150, 1, -190))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO)
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
