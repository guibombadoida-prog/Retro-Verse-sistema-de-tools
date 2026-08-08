-- Client.lua
-- LocalScript — Olho do Vigia (conjunto SUBMUNDO)
--
-- Três trabalhos, e nenhum é regra de combate:
--   1. mandar a mira (o mouse só existe aqui)
--   2. tocar a sequência de pose no animator canônico
--   3. DESENHAR o que o servidor anuncia por beat nomeado
--
-- Gerado por FERRAMENTAS/gerar_servers_submundo.py.

local Players = game:GetService("Players")

local jogador = Players.LocalPlayer
local rato = jogador:GetMouse()

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local VFX       = require(Tool:WaitForChild("VFXModule"))
local MiraRemote = Tool:WaitForChild("MiraRemote")

local SEQUENCIA = "APONTAR"
local ALCANCE_MIRA = 70
local RITMO_MIRA = 0.1

local rig, personagem
local equipada = false

local function pontoMirado()
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return nil end
	local alvo = rato.Hit and rato.Hit.Position
	if not alvo then return raiz.Position + raiz.CFrame.LookVector * 20 end
	local delta = alvo - raiz.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return raiz.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end

local function montarRig()
	if rig then return rig end
	if not personagem then return nil end
	rig = Animator.new(personagem, "OlhodoVigia", Poses, Poses.SEQUENCIAS)
	return rig
end

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	VFX.desenhar(tipo, dados or {}, Moldes, personagem)
end)

local function aoEquipar()
	personagem = Tool.Parent
	equipada = true
	montarRig()
	if MiraRemote then
		-- 10 Hz, não por quadro: o servidor só precisa do PARA ONDE, e 60
		-- pacotes por segundo por jogador é tráfego jogado fora
		task.spawn(function()
			while equipada do
				local ponto = pontoMirado()
				if ponto then MiraRemote:FireServer(ponto) end
				task.wait(RITMO_MIRA)
			end
		end)
	end
end

local function aoGuardar()
	equipada = false
	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
	end
	VFX.limpar()
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)

Tool.Activated:Connect(function()
	if not equipada then return end
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence(SEQUENCIA, function(passo)
		if passo.marca then VFX.beat(passo.marca, personagem) end
	end)
end)

Tool.Destroying:Connect(function()
	aoGuardar()
	if rig then
		rig:Destroy()
		rig = nil
	end
end)
