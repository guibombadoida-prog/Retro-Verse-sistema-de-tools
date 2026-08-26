-- Client.lua
-- Script com RunContext = Client — Cosmic Sword Revamp
--
-- POR QUE ISTO NÃO É UM LocalScript
--
--   `LocalScript` dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
--   mundo — mas o único ouvinte seria o de quem está segurando, e os outros
--   jogadores veriam o portador girando o braço no vazio.
--
--   Os dois Clients que esta Tool tinha eram `LocalScript`. É a mesma falha
--   que já custou o conjunto do escudo, e é por isso que ela vinha sendo
--   relatada como "o efeito só aparece para mim".
--
-- A ANIMAÇÃO NÃO ESTÁ AQUI
--
--   O rig é do servidor, porque `Weld` criado no cliente não replica: os
--   outros jogadores viam o portador parado.
--
-- QUATRO BOTÕES DE CELULAR, EM ALTURAS DIFERENTES
--
--   `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...)` — o
--   terceiro argumento faz o Roblox desenhar o botão sozinho. São quatro
--   Extras, e as alturas são separadas de propósito: empilhados na mesma
--   altura, os de baixo ficam inalcançáveis.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ALCANCE_MIRA = 120

--- As quatro Extras. O rótulo é o que o jogador lê no botão.
local EXTRAS = {
	{ tecla = "E", nome = "Cosmic_E", rotulo = "Supernova",
	  chave = Enum.KeyCode.E, gamepad = Enum.KeyCode.ButtonX, altura = -190 },
	{ tecla = "Q", nome = "Cosmic_Q", rotulo = "Shuriken do Espaco",
	  chave = Enum.KeyCode.Q, gamepad = Enum.KeyCode.ButtonR1, altura = -260 },
	{ tecla = "X", nome = "Cosmic_X", rotulo = "Dobra",
	  chave = Enum.KeyCode.X, gamepad = Enum.KeyCode.ButtonL1, altura = -330 },
	{ tecla = "H", nome = "Cosmic_H", rotulo = "Hawking",
	  chave = Enum.KeyCode.H, gamepad = Enum.KeyCode.ButtonY, altura = -400 },
}

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "PARAR" then
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

--- Onde o jogador está apontando, limitado ao alcance.
---
--- A origem fazia isto por `RemoteFunction` (`DirectionInvoker`): o servidor
--- INVOCAVA o cliente e ficava esperando a resposta. Cliente que não responde
--- trava a thread do servidor até o timeout. Aqui a mira viaja junto do
--- pedido, num sentido só.
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
	for _, extra in ipairs(EXTRAS) do
		ContextActionService:BindAction(extra.nome, function(_nome, estado)
			if estado ~= Enum.UserInputState.Begin then return end
			if not equipado then return end
			AcaoRemote:FireServer(extra.tecla, mira())
			return Enum.ContextActionResult.Sink
		end, true, extra.chave, extra.gamepad)
		ContextActionService:SetTitle(extra.nome, extra.rotulo)
		ContextActionService:SetPosition(extra.nome,
			UDim2.new(1, -150, 1, extra.altura))
	end
end

local function desligarEntrada()
	for _, extra in ipairs(EXTRAS) do
		ContextActionService:UnbindAction(extra.nome)
	end
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
end

Tool.Unequipped:Connect(aoGuardar)

--- Desequipar NÃO limpa o desenho: a shuriken já lançada continua no ar, como
--- a bomba já arremessada. Só a destruição da Tool e a morte do dono limpam.
Tool.Destroying:Connect(function()
	aoGuardar()
	VFX.LimparTudo()
end)

local function ligarMorte(personagem)
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then humanoide.Died:Connect(function() VFX.LimparTudo() end) end
end

if jogador.Character then ligarMorte(jogador.Character) end
jogador.CharacterAdded:Connect(ligarMorte)
