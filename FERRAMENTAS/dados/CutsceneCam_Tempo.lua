-- CutsceneCam.lua
-- Script com RunContext = Client — conjunto TEMPO
--
-- Vive SÓ no `Fim do Relogio`. É a ultimate do conjunto, e é a única com
-- recarga alta o bastante (42 s) para uma cena não virar tempo morto.
--
--═══════════════════════════════════════════════════════════════
-- POR QUE NÃO É LocalScript
--═══════════════════════════════════════════════════════════════
--
--   `LocalScript` dentro de Tool só roda para quem a segura. O ALVO nunca
--   executaria o arquivo, e a metade da cena que é dele não existiria.
--   `RunContext = Client` roda em TODO cliente, e nada saiu de dentro da Tool.
--
--═══════════════════════════════════════════════════════════════
-- O QUE A ORIGEM FAZIA, E QUE NÃO PODE SER FEITO
--═══════════════════════════════════════════════════════════════
--
--   O `timetools.rbxmx` tinha o efeito de tempo parado em
--   `Para o tempo/Main/GrayScale`, e ele funcionava assim:
--
--       blur.Parent = game.Lighting
--       grayscale.Parent = game.Lighting
--
--   `ColorCorrectionEffect` e `BlurEffect` em `Lighting` são estado do PLACE
--   INTEIRO. Quem estivesse do outro lado do mapa ficava sem cor por causa de
--   uma briga alheia, e uma Tool destruída no meio deixava o mundo cinza para
--   sempre — os dois têm `Debris:AddItem`, mas o `Debris` não roda se o script
--   morrer antes de chamá-lo.
--
--   Aqui o peso da cena é FOV e enquadramento, que são por espectador e
--   voltam sozinhos. O que substitui o cinza é a cúpula `ForceField` do
--   `VFXModule`, que vive no mundo 3D e some com prazo próprio.
--
--═══════════════════════════════════════════════════════════════
-- AS SEIS REGRAS DA GRAMATICA_CUTSCENE
--═══════════════════════════════════════════════════════════════
--
--   1. FOV é a técnica principal. Fecha na carga (46), ESTOURA no fim (106).
--      Amplitude 60 — a maior do repositório, e cabe: é o relógio quebrando.
--   2. Enquadramento POR ESPECTADOR: quem virou a ampulheta vê de fora; quem
--      está no raio vê a si mesmo sendo alcançado.
--   3. Aproximação EXPONENCIAL, nunca Tween bloqueante.
--   4. Estágio troca por TEMPO dentro do RenderStepped.
--   5. Tremor com ENVELOPE, e só na janela do estouro.
--   6. Pular é obrigatório, e é SÓ visual: segurar E por 1.5 s solta a
--      câmera. `E` está livre — as Extras são `R` e `T`.
--
--═══════════════════════════════════════════════════════════════
-- E A SEXTA PORTA
--═══════════════════════════════════════════════════════════════
--
--   Câmera presa é o pior do repertório. Aqui ela é devolvida por:
--   `Unequipped`, `Destroying`, `CharacterRemoving`, `Died`, prazo estourado,
--   e o pulo.
--
-- Gerado por FERRAMENTAS/gerar_servers_tempo.py.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")

local Tool           = script.Parent
local jogador        = Players.LocalPlayer
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local CFG = {
	FOV_BASE   = 70,
	VELOC_CAM  = 3.0,     -- regra 3
	VELOC_FOV  = 6.5,
	SKIP_HOLD  = 1.5,     -- regra 6
	PRAZO      = 11,      -- teto de segurança, não cronômetro
	TREMOR_A   = 24,      -- regra 5: as duas frequências não são múltiplas
	TREMOR_B   = 41,
}

--═══════════════════════════════════════════════════════════════
-- OS ENQUADRAMENTOS, POR PAPEL E POR BEAT
--
-- Os QUATRO beats são exatamente os quatro passos da sequência `epica` do
-- `Poses.lua` — CENA, CARGA, ESTOURA, FIM. É de propósito: beat que a câmera
-- não acompanha é um corte que não acontece, e enquadramento sem beat é
-- câmera parada esperando.
--
-- `de` é offset no espaço do ANCORADOURO daquele papel.
--═══════════════════════════════════════════════════════════════

local QUADROS = {
	INVOCADOR = {
		-- longe e alto, o ponto inteiro no quadro
		CENA    = { de = Vector3.new(14, 20, 26), olhar = "ponto", fov = 64, tremor = false },
		-- fecha: o FOV é a técnica (regra 1)
		CARGA   = { de = Vector3.new(8, 10, 14),  olhar = "ponto", fov = 46, tremor = false },
		-- e ESTOURA — abre tudo e sacode
		ESTOURA = { de = Vector3.new(26, 24, 34), olhar = "ponto", fov = 106, tremor = true },
		-- FIM assenta antes de devolver. Sem ele a câmera volta no mesmo quadro
		-- do impacto, e a cena termina sem respirar.
		FIM     = { de = Vector3.new(22, 16, 30), olhar = "ponto", fov = 70, tremor = false },
	},
	ALVO = {
		-- a metade da regra 2 que é do alvo: ele ancora em SI MESMO e vê a
		-- coisa chegando nele, não o outro trabalhando
		CENA    = { de = Vector3.new(-7, 4.5, 13), olhar = "eu",    fov = 68, tremor = false },
		CARGA   = { de = Vector3.new(-4, 3.2, 8),  olhar = "eu",    fov = 54, tremor = false },
		ESTOURA = { de = Vector3.new(-9, 6, 15),   olhar = "eu",    fov = 102, tremor = true },
		FIM     = { de = Vector3.new(-8, 5, 14),   olhar = "eu",    fov = 74, tremor = false },
	},
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local camera = workspace.CurrentCamera
local guardado = nil
local ligacao, escuta, escutaSolta = nil, nil, nil
local papel, nomePortador, pontoCena = nil, nil, nil
local quadroAtual = nil
local posAtual, focoAtual = nil, nil
local relogio, desdeBeat = 0, 0
local segurando = 0

local function parteDe(nome)
	if type(nome) ~= "string" or nome == "" then return nil end
	local modelo = workspace:FindFirstChild(nome)
	if not modelo then return nil end
	return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
end

--═══════════════════════════════════════════════════════════════
-- DEVOLVER A CÂMERA — o caminho que não pode falhar
--═══════════════════════════════════════════════════════════════

local function devolver()
	if ligacao then ligacao:Disconnect() ligacao = nil end
	if escuta then escuta:Disconnect() escuta = nil end
	if escutaSolta then escutaSolta:Disconnect() escutaSolta = nil end
	quadroAtual, papel = nil, nil
	posAtual, focoAtual = nil, nil
	pontoCena = nil
	segurando = 0

	camera = workspace.CurrentCamera
	if camera and guardado then
		camera.CameraType  = guardado.tipo
		camera.FieldOfView = guardado.fov
		local personagem = jogador.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		if humanoide then camera.CameraSubject = humanoide end
	end
	guardado = nil
end

local function tomar()
	camera = workspace.CurrentCamera
	if not camera then return false end
	if not guardado then
		guardado = { tipo = camera.CameraType, fov = camera.FieldOfView }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	return true
end

--═══════════════════════════════════════════════════════════════
-- REGRA 5 — tremor com envelope, e só na janela do estouro
--
-- Duas frequências que não se repetem, com envelope que faz o tremor nascer
-- forte e sumir sozinho. Zero `math.random`: os dois espectadores veem a mesma
-- trepidação, e um sorteio aqui faria a cena tremer diferente para cada um —
-- o que lê como lag, não como impacto.
--═══════════════════════════════════════════════════════════════

local function tremor(t, idade)
	local env = math.clamp(1 - idade * 1.3, 0, 1)
	if env <= 0 then return Vector3.new() end
	return Vector3.new(
		math.sin(t * CFG.TREMOR_A) * 0.42 * env,
		math.sin(t * CFG.TREMOR_B) * 0.24 * env,
		math.sin(t * (CFG.TREMOR_A + 7)) * 0.16 * env)
end

--═══════════════════════════════════════════════════════════════
-- O TRILHO — regra 3: aproximação exponencial, nunca Tween bloqueante
--═══════════════════════════════════════════════════════════════

local function seguir()
	if ligacao then return end
	relogio, desdeBeat = 0, 0
	ligacao = RunService.RenderStepped:Connect(function(dt)
		relogio = relogio + dt
		desdeBeat = desdeBeat + dt

		-- regra 4: o estágio troca por TEMPO, e o prazo fecha a cena mesmo se
		-- o servidor nunca mandar o FIM
		if relogio > CFG.PRAZO then
			devolver()
			return
		end
		if not quadroAtual then return end

		camera = workspace.CurrentCamera
		if not camera then return end

		local eu = jogador.Character
			and (jogador.Character:FindFirstChild("HumanoidRootPart")
				or jogador.Character:FindFirstChild("Torso"))
		local portador = parteDe(nomePortador)

		-- O ANCORADOURO. No papel ALVO é o próprio espectador; no INVOCADOR é
		-- o PONTO da bomba, não o portador — numa queda orbital quem mandou
		-- quer ver a coisa cair, não se ver apontando para o céu.
		local ancoraCF
		if papel == "ALVO" and eu then
			ancoraCF = eu.CFrame
		elseif pontoCena then
			ancoraCF = CFrame.new(pontoCena)
		elseif portador then
			ancoraCF = portador.CFrame
		elseif eu then
			ancoraCF = eu.CFrame
		else
			devolver()
			return
		end

		local metaFoco
		if quadroAtual.olhar == "eu" then
			metaFoco = eu and eu.Position or ancoraCF.Position
		elseif quadroAtual.olhar == "portador" then
			metaFoco = portador and portador.Position or ancoraCF.Position
		else
			metaFoco = pontoCena or ancoraCF.Position
		end

		local metaPos = ancoraCF:PointToWorldSpace(quadroAtual.de)

		posAtual = posAtual or metaPos
		focoAtual = focoAtual or metaFoco

		local k = 1 - math.exp(-CFG.VELOC_CAM * dt)
		posAtual = posAtual:Lerp(metaPos, k)
		focoAtual = focoAtual:Lerp(metaFoco, k)

		local sacode = quadroAtual.tremor
			and tremor(relogio, desdeBeat) or Vector3.new()

		camera.CFrame = CFrame.new(posAtual + sacode, focoAtual)

		-- regra 1: o FOV é a técnica. Também exponencial, e mais rápido que a
		-- posição — o estouro tem de chegar antes da câmera terminar de andar.
		local kf = 1 - math.exp(-CFG.VELOC_FOV * dt)
		camera.FieldOfView = camera.FieldOfView
			+ (quadroAtual.fov - camera.FieldOfView) * kf
	end)
end

--═══════════════════════════════════════════════════════════════
-- REGRA 6 — pular é obrigatório, e é SÓ visual
--
-- `E` está livre neste conjunto: a Extra é `R`, e o M1 é o clique. Pular não
-- adianta o dano nem cancela a bomba — o servidor segue no tempo dele.
--═══════════════════════════════════════════════════════════════

local function pular()
	if escuta then return end
	escuta = UserInput.InputBegan:Connect(function(entrada, digitando)
		if digitando then return end
		if entrada.KeyCode ~= Enum.KeyCode.E then return end
		segurando = os.clock()
		task.delay(CFG.SKIP_HOLD, function()
			-- só solta se o E continuou pressionado o tempo todo
			if segurando > 0 and os.clock() - segurando >= CFG.SKIP_HOLD - 0.05 then
				devolver()
			end
		end)
	end)
	escutaSolta = UserInput.InputEnded:Connect(function(entrada)
		if entrada.KeyCode == Enum.KeyCode.E then segurando = 0 end
	end)
end

--═══════════════════════════════════════════════════════════════
-- BEATS DO SERVIDOR
--
-- Um `FireClient` por espectador, com o PAPEL dele no payload. O servidor sabe
-- quem detonou e quem está no raio; o cliente só desenha o que lhe cabe.
--═══════════════════════════════════════════════════════════════

CutsceneRemote.OnClientEvent:Connect(function(evento, dados)
	dados = dados or {}

	if evento == "INICIO" then
		papel = (dados.papel == "ALVO") and "ALVO" or "INVOCADOR"
		nomePortador = dados.portador
		pontoCena = (typeof(dados.ponto) == "Vector3") and dados.ponto or nil
		if not tomar() then return end
		quadroAtual = QUADROS[papel][dados.nome or "CENA"]
			or QUADROS[papel].CENA
		posAtual, focoAtual = nil, nil
		desdeBeat = 0
		seguir()
		pular()
		return
	end

	if evento == "BEAT" then
		if not (ligacao and papel) then return end
		-- o servidor pode reposicionar o ponto no meio: a queda orbital cai
		-- onde o farol foi plantado, não onde o portador está agora
		if typeof(dados.ponto) == "Vector3" then pontoCena = dados.ponto end
		local novo = QUADROS[papel][dados.nome]
		if novo then
			quadroAtual = novo
			desdeBeat = 0
		end
		return
	end

	if evento == "FIM" then
		devolver()
	end
end)

--═══════════════════════════════════════════════════════════════
-- AS PORTAS DE SAÍDA
--═══════════════════════════════════════════════════════════════

Tool.Unequipped:Connect(devolver)
Tool.Destroying:Connect(devolver)
jogador.CharacterRemoving:Connect(devolver)

local function ligarMorte(personagem)
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then humanoide.Died:Connect(devolver) end
end

if jogador.Character then ligarMorte(jogador.Character) end
jogador.CharacterAdded:Connect(ligarMorte)
