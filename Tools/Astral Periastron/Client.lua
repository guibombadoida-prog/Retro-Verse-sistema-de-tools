-- Client.lua — LocalScript "Client" do conjunto ASTRAL
--
-- Papel (§12.10): capturar entrada e EXECUTAR os VFX recebidos pelo VFXRemote.
-- Não decide dano, não decide alvo, não decide estado. Quem decide é o
-- servidor; o Núcleo é quem aplica regra de combate.
--
-- O VFXRemote é UNIDIRECIONAL: aqui só existe OnClientEvent.
-- O AcaoRemote é a saída: FireServer com o nome da habilidade e a MIRA.
--
-- Mira vai como DADO (Vector3), nunca como Instance. O original usava uma
-- RemoteFunction cliente->servidor para perguntar a posição do mouse: isso
-- pendura a thread do servidor quando o cliente não responde.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Tool       = script.Parent
local Jogador    = Players.LocalPlayer
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local Mouse = Jogador:GetMouse()

-- As teclas do original: Q redireciona, E detona, X é a grande.
-- Tool que não usa uma delas simplesmente ignora o pedido no servidor.
local TECLAS = {
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.X] = "X",
}

local equipado = false
local ligacoes = {}

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

local function mira()
	-- posição do mouse no mundo; se não houver alvo, um ponto à frente
	if Mouse and Mouse.Hit then return Mouse.Hit.Position end
	local personagem = Jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz then return raiz.Position + raiz.CFrame.LookVector * 30 end
	return Vector3.new()
end

local function ligarEntrada()
	if ligacoes.entrada then return end
	ligacoes.entrada = UserInputService.InputBegan:Connect(function(entrada, digitando)
		if digitando then return end
		if not equipado then return end
		local nome = TECLAS[entrada.KeyCode]
		if nome then
			AcaoRemote:FireServer(nome, mira())
		end
	end)
end

local function desligarEntrada()
	if ligacoes.entrada then
		ligacoes.entrada:Disconnect()
		ligacoes.entrada = nil
	end
end

Tool.Equipped:Connect(function()
	equipado = true
	ligarEntrada()
end)

Tool.Unequipped:Connect(function()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end)

--═══════════════════════════════════════════════════════════════
-- RECEPÇÃO DE VFX
--═══════════════════════════════════════════════════════════════

--- Resolve nome de personagem -> BasePart. O payload traz DADO, não Instance.
local function parteDe(nome)
	if type(nome) ~= "string" or nome == "" then return nil end
	local modelo = workspace:FindFirstChild(nome)
	if not modelo then return nil end
	return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
end

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	dados = dados or {}

	if tipo == "PARAR" then
		VFX.Parar(dados.id)
		return
	end

	-- Efeito presos a um personagem: o cliente resolve o nome em parte
	if dados.alvoNome then
		local parte = parteDe(dados.alvoNome)
		if not parte then return end
		dados.posicao = parte.Position + (dados.deslocamento or Vector3.new())
	end

	VFX.Executar(tipo, dados)
end)

--═══════════════════════════════════════════════════════════════
-- LIMPEZA
--═══════════════════════════════════════════════════════════════

local function limpar()
	desligarEntrada()
	VFX.LimparTudo()
end

Tool.Destroying:Connect(limpar)

Jogador.CharacterRemoving:Connect(limpar)
