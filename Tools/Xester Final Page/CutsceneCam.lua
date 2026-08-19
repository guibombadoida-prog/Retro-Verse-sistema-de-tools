-- CutsceneCam.lua
-- Script com RunContext = Client — Xester Final Page  (Xester)
--
--═══════════════════════════════════════════════════════════════
-- A CÂMERA É 100% CLIENTE, E SÓ DO DONO
--
--   O servidor manda BEAT NOMEADO e nunca `CFrame`. Ele não sabe onde a
--   câmera está e não precisa saber: timeline é decisão dele, enquadramento é
--   decisão daqui.
--
--   E o pedido foi explícito — *"A câmera deve ser local, para não forçar a
--   cutscene nos outros jogadores"*. Por isso o `CutsceneRemote` chega por
--   `FireClient(jogador, …)`: este script roda em todo cliente, mas só o dono
--   recebe o evento. Quem está por perto vê o VFX da transformação (esse é
--   `FireAllClients`) sem perder o controle da própria visão.
--
-- POR QUE RunContext = Client E NÃO LocalScript
--
--   Pela mesma razão do `Client.lua`: LocalScript dentro de Tool só roda para
--   quem a segura, e este arquivo precisa existir em todos os clientes para o
--   dia em que uma cena tiver enquadramento de espectador. Hoje ela não tem —
--   e a limitação ao dono vem do `FireClient`, não do tipo de script.
--
-- AS SEIS PORTAS DE SAÍDA
--
--   `Unequipped` · `Destroying` · `CharacterRemoving` · `Died` · PRAZO
--   estourado · PULO. A do prazo existe porque o servidor pode morrer no meio
--   da cena e nunca mandar o `FIM` — e câmera presa sem saída é o pior bug do
--   repertório: o jogador não tem o que fazer a não ser sair do jogo.
--
-- O PULO É SÓ VISUAL
--
--   Segurar `E` por 1.5 s solta a câmera. Ele NÃO encurta a timeline do
--   servidor: se encurtasse, pular a cutscene viraria vantagem de combate e
--   todo mundo pularia sempre.
--
-- AS TRÊS REGRAS DE MOVIMENTO
--
--   1. Aproximação EXPONENCIAL, nunca Tween bloqueante:
--      `k = 1 - math.exp(-VELOC * dt)`. Independente de FPS e interrompível.
--   2. Estágio troca por BEAT, dentro do `RenderStepped` — nunca por espera.
--   3. Tremor com ENVELOPE, duas frequências que não são múltiplas (24 e 41).
--      Zero `math.random`: sorteio aqui faria a cena tremer diferente a cada
--      execução, e a cena tem de ser a mesma sempre.
--═══════════════════════════════════════════════════════════════

-- Gerado por FERRAMENTAS/gerar_servers_xester_v3.py.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")

local jogador        = Players.LocalPlayer
local Tool           = script.Parent
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	FOV_BASE  = 70,
	VELOC_CAM = 3.4,
	VELOC_FOV = 6.5,
	SKIP_HOLD = 1.5,
	PRAZO     = 8,      -- teto; a cena mais longa daqui tem 3.00 s
	TREMOR_A  = 24,
	TREMOR_B  = 41,
}

--═══════════════════════════════════════════════════════════════
-- OS ENQUADRAMENTOS, POR CENA E POR BEAT
--
-- `de` é offset no espaço do HRP do portador: X para o lado, Y para cima, Z
-- para trás (negativo é à frente do peito).
--
-- `olhar` diz para onde a câmera aponta:
--   "mao"      a altura da mão direita — é onde a carta está
--   "corpo"    o peito do portador
--   "cima"     `alto` studs acima dele
--
-- CONTRASTE DE FOV É A TÉCNICA PRINCIPAL. Fechar a 30 comprime a perspectiva
-- e prende; estourar a 96 no quadro do rasgo abre tudo de uma vez. Um FOV
-- fixo, por melhor escolhido, não produz esse efeito.
--═══════════════════════════════════════════════════════════════

local CENAS = {
	--  F  The Final Deal — 3.00 s, os seis beats do roteiro
	TRANSFORMAR = {
		-- 1. a câmera aproxima-se da MÃO segurando uma carta vazia
		MAO     = { de = Vector3.new(1.8, 2.9, -3.4), olhar = "mao",
			fov = 32, roll = 2 },
		-- 2. os quatro naipes aparecem na carta: fecha ainda mais
		NAIPES  = { de = Vector3.new(1.2, 3.0, -2.6), olhar = "mao",
			fov = 28, roll = -3 },
		-- 3. vira Coringa e começa a queimar: abre um pouco para ver o fogo
		CORINGA = { de = Vector3.new(-2.4, 3.4, -4.6), olhar = "mao",
			fov = 42, roll = 4 },
		-- 4. as cartas congelam no ar e o dragão circula: quadro médio, tenso
		CONGELA = { de = Vector3.new(-4.6, 3.2, -6.4), olhar = "corpo",
			fov = 34, roll = -5, tremor = 0.35 },
		-- 5. o RASGO: o estouro do FOV é aqui
		RASGA   = { de = Vector3.new(0, 4.6, -9.5), olhar = "corpo",
			fov = 96, roll = 0, tremor = 1 },
		-- 6. o título: contra-plongée, câmera baixa olhando para cima
		TITULO  = { de = Vector3.new(0, -1.4, -13), olhar = "cima", alto = 6,
			fov = 62, roll = 0, tremor = 0.25 },
	},

	--  F  Curtain Reversal — 1.80 s, três beats
	REVERTER = {
		ABSORVE = { de = Vector3.new(-2.2, 3.4, -5.2), olhar = "mao",
			fov = 44, roll = -3 },
		APAGA   = { de = Vector3.new(1.8, 3.0, -7.0), olhar = "corpo",
			fov = 58, roll = 2 },
		FECHA   = { de = Vector3.new(0, 2.6, -10), olhar = "corpo",
			fov = CFG.FOV_BASE, roll = 0 },
	},

	--  L  The Final Page of Heaven — a cena curta da ultimate
	PAGINA = {
		-- o mundo para: quadro largo, para caber quem foi preso
		PARA    = { de = Vector3.new(0, 8, -18), olhar = "corpo",
			fov = 92, roll = 0 },
		-- o relógio de naipes no céu
		RELOGIO = { de = Vector3.new(0, 2, -9), olhar = "cima", alto = 26,
			fov = 46, roll = 3, tremor = 0.2 },
		-- a carta final se quebra: fecha
		QUEBRA  = { de = Vector3.new(2.2, 3.2, -4.2), olhar = "mao",
			fov = 34, roll = -4, tremor = 0.6 },
		-- e o tempo volta de uma vez
		VOLTA   = { de = Vector3.new(0, 5, -15), olhar = "corpo",
			fov = 100, roll = 0, tremor = 1 },
	},
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local camera = workspace.CurrentCamera
local ligada = false
local cenaAtual, beatAtual = nil, nil
local quadroAtual = nil
local decorrido, desdeOBeat = 0, 0
local prazo = CFG.PRAZO

--- o que havia ANTES. Devolver `Custom` chutado quebraria quem estivesse em
--- `Follow`, `Attach` ou `Scriptable` por outro sistema.
local tipoAntes, fovAntes = nil, nil

local ligacao = nil
local segurandoPulo = 0
local conexaoEntrada = nil
local conexaoSaida = nil

--═══════════════════════════════════════════════════════════════
-- SOLTAR — a única função que devolve a câmera, e todas as portas chamam ela
--═══════════════════════════════════════════════════════════════

local function soltar()
	if not ligada then return end
	ligada = false
	cenaAtual, beatAtual, quadroAtual = nil, nil, nil
	segurandoPulo = 0

	if ligacao then
		ligacao:Disconnect()
		ligacao = nil
	end
	if conexaoEntrada then
		conexaoEntrada:Disconnect()
		conexaoEntrada = nil
	end
	if conexaoSaida then
		conexaoSaida:Disconnect()
		conexaoSaida = nil
	end

	camera = workspace.CurrentCamera
	if camera then
		if tipoAntes then camera.CameraType = tipoAntes end
		if fovAntes then camera.FieldOfView = fovAntes end
	end
	tipoAntes, fovAntes = nil, nil
end

--═══════════════════════════════════════════════════════════════
-- O QUADRO
--═══════════════════════════════════════════════════════════════

local function corpoDoPortador()
	local personagem = jogador.Character
	if not personagem then return nil, nil end
	local hrp = personagem:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, nil end
	return personagem, hrp
end

local function ondeOlhar(personagem, hrp, quadro)
	local alvo = quadro and quadro.olhar or "corpo"
	if alvo == "mao" then
		local braco = personagem:FindFirstChild("Right Arm")
		if braco then return braco.Position end
		return hrp.Position + Vector3.new(0, 1.6, 0)
	elseif alvo == "cima" then
		return hrp.Position + Vector3.new(0, (quadro and quadro.alto) or 6, 0)
	end
	return hrp.Position + Vector3.new(0, 0.8, 0)
end

--- Tremor com envelope: duas frequências que não são múltiplas, então o
--- padrão não se repete dentro da cena. `forca` vem do beat.
local function tremorDe(forca)
	if not forca or forca <= 0 then return Vector3.new() end
	local a = math.sin(decorrido * CFG.TREMOR_A) * 0.045 * forca
	local b = math.sin(decorrido * CFG.TREMOR_B) * 0.018 * forca
	-- o envelope cai ao longo do beat: o soco é no começo dele
	local envelope = math.max(0, 1 - desdeOBeat * 2.2)
	return Vector3.new(a, b, a * 0.5) * envelope
end

local function passo(dt)
	if not ligada then return end
	decorrido = decorrido + dt
	desdeOBeat = desdeOBeat + dt

	if decorrido > prazo then
		soltar()
		return
	end

	camera = workspace.CurrentCamera
	local personagem, hrp = corpoDoPortador()
	if not (camera and hrp) then
		soltar()
		return
	end

	local quadro = quadroAtual
	if not quadro then return end

	local base = hrp.CFrame
	local ponto = base * CFrame.new(quadro.de)
	local alvo = ondeOlhar(personagem, hrp, quadro)
	local desejado = CFrame.lookAt(ponto.Position + tremorDe(quadro.tremor),
		alvo)
	if quadro.roll and quadro.roll ~= 0 then
		desejado = desejado * CFrame.Angles(0, 0, math.rad(quadro.roll))
	end

	-- aproximação exponencial: independente de FPS, e interrompível a qualquer
	-- quadro. Tween bloqueante aqui prenderia a câmera mesmo depois do `FIM`.
	local k = 1 - math.exp(-CFG.VELOC_CAM * dt)
	camera.CFrame = camera.CFrame:Lerp(desejado, k)

	local kf = 1 - math.exp(-CFG.VELOC_FOV * dt)
	camera.FieldOfView = camera.FieldOfView
		+ ((quadro.fov or CFG.FOV_BASE) - camera.FieldOfView) * kf
end

--═══════════════════════════════════════════════════════════════
-- O PULO — segurar E por 1.5 s. Só visual.
--═══════════════════════════════════════════════════════════════

local function ligarPulo()
	if conexaoEntrada then conexaoEntrada:Disconnect() end
	segurandoPulo = 0
	conexaoEntrada = UserInput.InputBegan:Connect(function(entrada, processado)
		if processado then return end
		if entrada.KeyCode ~= Enum.KeyCode.E then return end
		local comecou = os.clock()
		task.spawn(function()
			while ligada and UserInput:IsKeyDown(Enum.KeyCode.E) do
				if os.clock() - comecou >= CFG.SKIP_HOLD then
					-- solta a câmera e NADA MAIS. O servidor segue no tempo
					-- dele: pular não adianta o dano.
					soltar()
					return
				end
				task.wait(0.1)
			end
		end)
	end)
end

--═══════════════════════════════════════════════════════════════
-- AS PORTAS
--═══════════════════════════════════════════════════════════════

local function prender(cena, prazoPedido)
	local quadros = CENAS[cena]
	if not quadros then return end

	camera = workspace.CurrentCamera
	local _personagem, hrp = corpoDoPortador()
	if not (camera and hrp) then return end

	if not ligada then
		tipoAntes = camera.CameraType
		fovAntes = camera.FieldOfView
	end
	ligada = true
	cenaAtual = cena
	beatAtual = nil
	quadroAtual = nil
	decorrido, desdeOBeat = 0, 0
	prazo = prazoPedido or CFG.PRAZO
	camera.CameraType = Enum.CameraType.Scriptable

	if ligacao then ligacao:Disconnect() end
	ligacao = RunService.RenderStepped:Connect(passo)
	ligarPulo()

	if conexaoSaida then conexaoSaida:Disconnect() end
	local humanoide = jogador.Character
		and jogador.Character:FindFirstChildOfClass("Humanoid")
	if humanoide then
		conexaoSaida = humanoide.Died:Connect(soltar)
	end
end

local function beat(nome)
	if not ligada then return end
	local quadros = CENAS[cenaAtual]
	local quadro = quadros and quadros[nome]
	if not quadro then return end
	beatAtual = nome
	quadroAtual = quadro
	desdeOBeat = 0
end

CutsceneRemote.OnClientEvent:Connect(function(assunto, dados)
	if assunto == "INICIO" then
		prender(dados and dados.cena, dados and dados.prazo)
	elseif assunto == "BEAT" then
		beat(dados and dados.nome)
	elseif assunto == "FIM" then
		soltar()
	end
end)

Tool.Unequipped:Connect(soltar)
Tool.Destroying:Connect(soltar)
jogador.CharacterRemoving:Connect(soltar)
