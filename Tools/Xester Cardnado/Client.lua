-- Client.lua
-- LocalScript — Xester Cardnado
--
-- Três trabalhos, e nenhum deles é regra de combate:
--   1. mandar a mira (o mouse só existe aqui)
--   2. tocar a sequência de pose no animator canônico
--   3. DESENHAR o VFX que o servidor anuncia por beat nomeado
--
-- POR QUE O VFX É DAQUI
--   Parte ancorada movida por script de servidor replica a ~20 Hz, sem
--   interpolação — é o "não está fluido". Aqui o desenho roda a 60 Hz no
--   Heartbeat de cada cliente, e o servidor só diz O QUE e ONDE.
--
-- MOBILE
--   `ContextActionService:BindAction(nome, fn, true, tecla)` — o `true` é o
--   `createTouchButton`: o Roblox desenha o botão sozinho no celular. Não é
--   ScreenGui, e ContextActionService é serviço, não depósito de asset.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local jogador = Players.LocalPlayer
local rato = jogador:GetMouse()

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local VFX       = require(Tool:WaitForChild("VFXModule"))
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local MiraRemote = nil

local SEQUENCIA = "CARDNADO"
local SEQUENCIA_EXTRA = "BOLA_DE_FOGO"

local ALCANCE_MIRA = 60
local RITMO_MIRA = 0.1

local rig, personagem
local equipada = false
local conexoes = {}

local function guardar(conexao)
	table.insert(conexoes, conexao)
	return conexao
end

local function soltarTudo()
	for _, conexao in ipairs(conexoes) do
		if conexao.Connected then conexao:Disconnect() end
	end
	conexoes = {}
end

--- Ponto mirado, cortado pelo alcance. O servidor CONFERE de novo — este
--- corte é para o traçado do efeito, não é a autoridade.
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

--══════════════════════════════════════════════════════════════
-- ANIMAÇÃO
--══════════════════════════════════════════════════════════════

local function montarRig()
	if rig then return rig end
	if not personagem then return nil end
	rig = Animator.new(personagem, "XesterCardnado", Poses, Poses.SEQUENCIAS)
	return rig
end

--- Toca a sequência e devolve o beat ao VFX. `marca` é o que o keyframe
--- carrega: "CARGA" quando o gesto começa, "GOLPE" quando ele solta.
local function tocar(nome)
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence(nome, function(passo)
		if passo.marca then
			VFX.beat(passo.marca, personagem)
		end
	end)
end

--══════════════════════════════════════════════════════════════
-- VFX — o servidor anuncia, este cliente desenha
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	VFX.desenhar(tipo, dados or {}, Moldes, personagem)
end)

--══════════════════════════════════════════════════════════════
-- ENTRADA
--══════════════════════════════════════════════════════════════

local function aoEquipar()
	personagem = Tool.Parent
	equipada = true
	montarRig()

	-- o `true` no terceiro argumento é o botão de mobile
	ContextActionService:BindAction("Xester_XesterCardnado", function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipada then return end
		AcaoRemote:FireServer(pontoMirado())
		tocar(SEQUENCIA_EXTRA)
	end, true, Enum.KeyCode.Y)
	ContextActionService:SetTitle("Xester_XesterCardnado", "Bola De Fogo")

	-- a mira vai a 10 Hz, não por quadro: o servidor só precisa do PARA ONDE,
	-- e 60 pacotes por segundo por jogador é tráfego jogado fora
	if MiraRemote then
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
	soltarTudo()
	ContextActionService:UnbindAction("Xester_XesterCardnado")

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
	tocar(SEQUENCIA)
end)

--- `Destroying`, não `AncestryChanged`: guardar a Tool na mochila troca o pai
--- sem destruir nada, e o cleanup não pode disparar aí.
Tool.Destroying:Connect(function()
	aoGuardar()
	if rig then
		rig:Destroy()
		rig = nil
	end
end)
