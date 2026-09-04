-- Client.lua — LocalScript do conjunto BOMBAS
--
-- Papel (§12.10): mandar a MIRA e executar o VFX que chega pelo VFXRemote.
-- Não decide dano, não decide alvo, não decide estado.
--
-- MOBILE: não há botão a criar. Nenhuma das 6 Tools tem habilidade Extra, e
-- `Tool.Activated` já dispara no toque do ícone da própria Tool, em qualquer
-- plataforma. Botão de `ContextActionService` aqui só ocuparia a tela.
--
-- A mira viaja como Vector3 — dado, nunca Instance.

local Players = game:GetService("Players")

local Tool      = script.Parent
local Jogador   = Players.LocalPlayer
local VFXRemote = Tool:WaitForChild("VFXRemote")
local VFX       = require(Tool:WaitForChild("VFXModule"))

local Mouse = Jogador:GetMouse()

local function mira()
	if Mouse and Mouse.Hit then return Mouse.Hit.Position end
	local personagem = Jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz then return raiz.Position + raiz.CFrame.LookVector * 30 end
	return Vector3.new()
end

Tool.Activated:Connect(function()
	VFXRemote:FireServer(mira())
end)

--═══════════════════════════════════════════════════════════════
-- RECEPÇÃO DE VFX
--═══════════════════════════════════════════════════════════════

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

Tool.Unequipped:Connect(function() VFX.LimparTudo() end)
Tool.Destroying:Connect(function() VFX.LimparTudo() end)
Jogador.CharacterRemoving:Connect(function() VFX.LimparTudo() end)
