--[[
	CutsceneCam  —  LocalScript, filho direto da Tool
	Retro-Verse / Studios  ·  DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md

	Câmera 100% cliente. O servidor manda BEAT NOMEADO por CutsceneRemote;
	quem enquadra é este arquivo. Beats: START → CORTE → SENTENCA → STOP.

	Molde: ACERVO_RETROVERSE/_AUTORAL_RetroVerse/CAMERA/SeriousMode_CutsceneCam_V1.lua

	workspace.CurrentCamera NÃO viola a Regra nº 1: é singleton por cliente,
	como Players.LocalPlayer — existe em todo place, sem depósito nenhum.
	A condição é esta aqui: só em LocalScript, e SEMPRE devolvida.

	As quatro obrigações, todas nas últimas linhas ou no stopCutscene():
		1. guarda e restaura o CameraType anterior (não `Custom` chutado)
		2. restaura o FieldOfView
		3. desliga em Unequipped E Destroying
		4. é pulável, e o pulo é PURAMENTE VISUAL — solta a câmera e nada mais.
		   A timeline do servidor corre igual: pular não é vantagem de combate.

	Sem ScreenGui, sem ColorCorrection, sem Blur, sem Sky. Efeito de cutscene é
	enquadramento e lente: posição, alvo, FOV, roll, shake.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local tool = script.Parent
local cutsceneRemote = tool:WaitForChild("CutsceneRemote")

local jogador = Players.LocalPlayer
local camera = workspace.CurrentCamera

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	FOV_BASE     = 70,
	FOV_FECHADO  = 42,   -- telefoto durante os cortes: comprime e prende
	FOV_ESTOURO  = 98,   -- abre de uma vez no golpe mortal
	FOV_ENTRADA  = 1.10, -- tempo do fechamento inicial
	FOV_VOLTA    = 0.45, -- tempo do estouro voltando ao base

	SEGURAR_PARA_PULAR = 1.5,
	TECLA_PULAR = Enum.KeyCode.E,
	ACAO_PULAR = "EscudoPartido_PularCutscene",

	-- Órbita: dois estágios. Abertura mais alta e distante; corte mais baixo e
	-- perto. Aproximar dá peso sem precisar cortar o plano.
	ORBITA_VOLTAS = 0.55,   -- voltas por segundo em volta do alvo
	RAIO_ABERTURA = 11.0,
	ALTURA_ABERTURA = 4.2,
	RAIO_CORTE    = 6.5,
	ALTURA_CORTE  = 2.2,

	ALVO_ALTURA = 1.6,
}

--==============================================================================
-- ESTADO
--==============================================================================

local ativa = false
local conexao = nil
local tipoGuardado = nil
local decorrido = 0
local duracao = 4
local estagio = "A"        -- A = abertura | B = cortes
local segurando = false
local acumuladoSegurar = 0

--==============================================================================
-- CÂMERA
--==============================================================================

local function pararCutscene()
	if not ativa then
		return
	end
	ativa = false

	if conexao then
		conexao:Disconnect()
		conexao = nil
	end
	ContextActionService:UnbindAction(CFG.ACAO_PULAR)

	camera.FieldOfView = CFG.FOV_BASE
	-- O valor GUARDADO, não `Custom` chutado: o jogador pode estar em Follow,
	-- Attach ou Scriptable por outro sistema.
	camera.CameraType = tipoGuardado or Enum.CameraType.Custom
	tipoGuardado = nil

	decorrido = 0
	estagio = "A"
	segurando = false
	acumuladoSegurar = 0
end

local function aoPular(_, estado)
	if estado == Enum.UserInputState.Begin then
		segurando = true
	elseif estado == Enum.UserInputState.End or estado == Enum.UserInputState.Cancel then
		segurando = false
		acumuladoSegurar = 0
	end
	return Enum.ContextActionResult.Sink
end

local function comecarCutscene(total)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end

	pararCutscene()

	duracao = total or 4
	tipoGuardado = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	ativa = true
	decorrido = 0
	estagio = "A"

	ContextActionService:BindAction(CFG.ACAO_PULAR, aoPular, true, CFG.TECLA_PULAR)

	TweenService:Create(
		camera,
		TweenInfo.new(CFG.FOV_ENTRADA, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ FieldOfView = CFG.FOV_FECHADO }
	):Play()

	conexao = RunService.RenderStepped:Connect(function(dt)
		if not ativa then
			return
		end

		local vivo = jogador.Character and jogador.Character:FindFirstChild("HumanoidRootPart")
		if not vivo then
			pararCutscene()
			return
		end

		decorrido = decorrido + dt

		local raio = (estagio == "A") and CFG.RAIO_ABERTURA or CFG.RAIO_CORTE
		local altura = (estagio == "A") and CFG.ALTURA_ABERTURA or CFG.ALTURA_CORTE

		local centro = vivo.Position
		local angulo = decorrido * CFG.ORBITA_VOLTAS * math.pi * 2
		local pos = centro + Vector3.new(
			math.cos(angulo) * raio,
			altura,
			math.sin(angulo) * raio
		)

		-- Roll e shake por acumulador dt, com duas frequências que não se
		-- repetem. Sem math.random: a mesma cutscene sai igual toda vez.
		local avanco = math.clamp(decorrido / math.max(duracao, 0.001), 0, 1)
		local roll = math.sin(avanco * math.pi) * math.rad(4)
		local tremor = math.sin(decorrido * 26) * 0.05 * avanco
			+ math.sin(decorrido * 43) * 0.02 * avanco

		camera.CFrame = CFrame.lookAt(
			pos + Vector3.new(tremor, tremor * 0.5, 0),
			centro + Vector3.new(0, CFG.ALVO_ALTURA, 0)
		) * CFrame.Angles(0, 0, roll)

		if segurando then
			acumuladoSegurar = acumuladoSegurar + dt
			if acumuladoSegurar >= CFG.SEGURAR_PARA_PULAR then
				-- Puramente visual: solta a câmera. NÃO fala com o servidor, e
				-- a timeline lá corre igual — pular não é vantagem de combate.
				pararCutscene()
			end
		end
	end)
end

local function aproximar()
	if not ativa then
		return
	end
	estagio = "B"
end

local function estourarFov()
	if not ativa then
		return
	end
	camera.FieldOfView = CFG.FOV_ESTOURO
	TweenService:Create(
		camera,
		TweenInfo.new(CFG.FOV_VOLTA, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = CFG.FOV_FECHADO }
	):Play()
end

--==============================================================================
-- BEATS — o servidor manda nome, nunca CFrame
--==============================================================================

cutsceneRemote.OnClientEvent:Connect(function(beat, valor)
	if beat == "START" then
		comecarCutscene(valor)
	elseif beat == "CORTE" then
		-- O primeiro corte aproxima; os seguintes só sacodem a lente.
		if valor == 1 then
			aproximar()
		end
	elseif beat == "SENTENCA" then
		estourarFov()
	elseif beat == "STOP" or beat == "CANCEL" then
		pararCutscene()
	end
end)

-- Obrigação 3: as duas, sem exceção. Câmera presa com a Tool fora da mão é bug
-- sem saída — o jogador perde o controle e não tem como recuperar.
tool.Unequipped:Connect(pararCutscene)
tool.Destroying:Connect(pararCutscene)
