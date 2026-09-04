-- Client.lua
-- Script com RunContext = Client — Fenix  (conjunto PODER DE FOGO)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. `RunContext = Client` roda em TODO cliente, e nada saiu de dentro
-- da Tool. É por isso que o efeito aparece para o servidor inteiro.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica.
--
-- UM BOTÃO DE CELULAR
--
--   Uma Extra, um botão. O M1 já sai do toque na tela — botão a mais para a
--   mesma ação foi exatamente a reclamação levantada nas Tools de escudo.
--
-- Gerado por FERRAMENTAS/gerar_servers_fogo.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO_R = "Fogo_Fenix_R"
local ALCANCE_MIRA = 60

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

--- Onde o jogador aponta, limitado ao alcance. A mira viaja JUNTO do pedido,
--- num sentido só: `RemoteFunction` do servidor para o cliente trava a thread
--- do servidor até o cliente responder, e cliente que não responde a trava até
--- o timeout.
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
	ContextActionService:SetTitle(ACAO_R, "Renascer")
	ContextActionService:SetPosition(ACAO_R, UDim2.new(1, -150, 1, -150))

end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO_R)
end

Tool.Equipped:Connect(function()
	if not souODono() then return end
	equipado = true
	ligarEntrada()
end)

Tool.Unequipped:Connect(function()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end)

Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira())
end)
