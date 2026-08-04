--[[
	EscudoPartido_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1 · REGRA_CAMERA_DE_CUTSCENE

	Habilidade AUTORAL. Foi pedida assim: "o melee do escudo partido é cortes
	(tipo o escudo bumerangue só que não volta)", e a Extra é "uma cutscene SE
	PEGAR O DANO no jogador/NPC inimigo, onde cria 2 escudos que cortam o
	personagem várias vezes dando um golpe mortal de 299 de dano".

	PRIMÁRIA (Tool.Activated)  lança uma lâmina que segue reto e NÃO volta.
	                           É o bumerangue sem o retorno — o escudo partiu.
	EXTRA (X, via AcaoRemote)  SENTENÇA. Só dispara se houver alvo válido no
	                           alcance. Dois escudos cortam o alvo N vezes e o
	                           último corte tira 299.

	A CONDIÇÃO É A HABILIDADE
		"SE pegar o dano" não é detalhe: sem alvo, a Extra **não acontece** e
		**não gasta recarga**. Uma cutscene que roda no vazio é o pior caso —
		prende a câmera do jogador por 3 s para não mostrar nada. O alvo é
		escolhido ANTES de qualquer beat, e a cutscene só começa com ele em mãos.

	A CÂMERA NÃO ESTÁ AQUI
		Zero `Camera` neste arquivo, e é regra: câmera é 100% cliente. O que sai
		daqui é BEAT NOMEADO por CutsceneRemote — "START", "CORTE", "SENTENCA",
		"STOP". Quem enquadra é o CutsceneCam, LocalScript da própria Tool.
		Ver DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md.

	O SKIP NÃO ENCURTA A TIMELINE
		O cliente pode soltar a câmera segurando a tecla. Isso é visual: os
		cortes e os 299 acontecem no mesmo tempo de qualquer jeito. Se o skip
		mexesse no servidor, pular a cutscene viraria vantagem de combate.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:WaitForChild("AcaoRemote")
local cutsceneRemote = tool:WaitForChild("CutsceneRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "EXECUTOR"

local CFG = {
	NOME = "EscudoPartido",

	-- PRIMÁRIA — a lâmina que não volta
	LAMINA_DANO      = 21,
	LAMINA_VELOCIDADE = 92,
	LAMINA_ALCANCE   = 62,
	LAMINA_RAIO      = 4.2,
	LAMINA_EMPURRAO  = 18,
	LAMINA_TAMANHO   = Vector3.new(3.0, 3.0, 0.24),
	RECARGA_BASE     = 0.85,

	-- EXTRA — a sentença
	SENTENCA_ALCANCE  = 26,
	SENTENCA_CORTES   = 6,
	SENTENCA_DANO     = 12,     -- por corte, antes do golpe final
	SENTENCA_FINAL    = 299,    -- o golpe mortal
	SENTENCA_RECARGA  = 22,
	CORTE_INTERVALO   = 0.26,
	ABERTURA          = 0.55,   -- da câmera prender até o primeiro corte
	FECHAMENTO        = 0.90,   -- do golpe final até a câmera voltar

	COR_VFX      = Color3.fromRGB(0, 122, 190),
	COR_SENTENCA = Color3.fromRGB(255, 60, 60),
	ESCALA_VFX   = 1.0,

	SFX_CORTE     = "Corte",
	SFX_SENTENCA  = "Sentenca",
	SFX_ESTILHACO = "Estilhaco",

	CHAVE_EXTRA = "EscudoPartido_X",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local emSentenca = false
local ultimaSentenca = 0
local laminasVivas = {}

local function tocarSequencia(nome)
	if not animador or not nome then
		return
	end
	animador:PlaySequence(nome)
end

--==============================================================================
-- AUXILIARES
--==============================================================================

local function tocarSom(nome, posicao)
	local original = pastaSFX:FindFirstChild(nome)
	if not original then
		return
	end

	local som = original:Clone()
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.CFrame = CFrame.new(posicao)
	ancora.Parent = workspace

	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora, som.TimeLength + 0.5)
end

local function transmitir(tipo, posicao, escala, cor, frente)
	local payload = {
		posicao = posicao,
		escala = escala or CFG.ESCALA_VFX,
		cor = cor or CFG.COR_VFX,
		frente = frente,
	}
	if _G.Combate and _G.Combate.transmitirVFX then
		_G.Combate.transmitirVFX(VFXRemote, tipo, payload)
		return
	end
	VFXRemote:FireAllClients(tipo, payload)
end

local function humanoidesEmArea(posicao, raio, meuPersonagem)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(posicao, raio, meuPersonagem) or {}
	end

	local achados = {}
	for _, outro in ipairs(Players:GetPlayers()) do
		local personagem = outro.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
		if humanoide and raiz and humanoide.Health > 0 and personagem ~= meuPersonagem then
			if (raiz.Position - posicao).Magnitude <= raio then
				table.insert(achados, humanoide)
			end
		end
	end
	return achados
end

local function podeAtingir(jogador, alvo)
	if _G.Combate and _G.Combate.podeCausarDano then
		return _G.Combate.podeCausarDano(jogador, alvo)
	end
	return true
end

local function aplicarDano(jogador, alvo, valor)
	if not podeAtingir(jogador, alvo) then
		return
	end
	if _G.Combate and _G.Combate.registrarAtaque then
		_G.Combate.registrarAtaque(jogador, alvo, valor, ARQUETIPO)
		return
	end
	alvo:TakeDamage(valor)
end

--==============================================================================
-- PRIMÁRIA — a lâmina que não volta
--==============================================================================

local function lancarLamina(jogador, personagem, raiz)
	local direcao = raiz.CFrame.LookVector
	local origem = raiz.Position + direcao * 2 + Vector3.new(0, 1.2, 0)

	local lamina = Instance.new("Part")
	lamina.Name = "LaminaPartida"
	lamina.Anchored = true
	lamina.CanCollide = false
	lamina.CanQuery = false
	lamina.CanTouch = false
	lamina.CastShadow = false
	lamina.Material = Enum.Material.Metal
	lamina.Color = CFG.COR_VFX
	lamina.Reflectance = 0.4
	lamina.Size = CFG.LAMINA_TAMANHO
	lamina.CFrame = CFrame.lookAt(origem, origem + direcao)
	lamina.Parent = workspace
	table.insert(laminasVivas, lamina)

	tocarSom(CFG.SFX_CORTE, origem)
	transmitir("LAMINA", origem, 1.0, CFG.COR_VFX, direcao)

	local percorrido = 0
	local jaAtingidos = {}
	local conexao

	conexao = RunService.Heartbeat:Connect(function(dt)
		if not lamina.Parent then
			conexao:Disconnect()
			return
		end

		local passo = CFG.LAMINA_VELOCIDADE * dt
		percorrido = percorrido + passo
		local nova = lamina.Position + direcao * passo

		-- Gira no próprio eixo enquanto vai — é o que faz ler como lâmina
		-- girando, e não como placa deslizando.
		lamina.CFrame = CFrame.lookAt(nova, nova + direcao)
			* CFrame.Angles(0, 0, percorrido * 0.42)

		for _, alvo in ipairs(humanoidesEmArea(nova, CFG.LAMINA_RAIO, personagem)) do
			if not jaAtingidos[alvo] and podeAtingir(jogador, alvo) then
				jaAtingidos[alvo] = true
				aplicarDano(jogador, alvo, CFG.LAMINA_DANO)

				local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					tocarSom(CFG.SFX_CORTE, alvoRaiz.Position)
					transmitir("LAMINA", alvoRaiz.Position, 0.9, CFG.COR_VFX, direcao)
					transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.8)

					local empurrao = Instance.new("BodyVelocity")
					empurrao.MaxForce = Vector3.new(1e5, 0, 1e5)
					empurrao.Velocity = direcao * CFG.LAMINA_EMPURRAO
					empurrao.Parent = alvoRaiz
					Debris:AddItem(empurrao, 0.14)
				end
			end
		end

		-- Sem retorno: chegou no alcance, estilhaça e acaba. É o que separa
		-- esta Tool do Bumerangue.
		if percorrido >= CFG.LAMINA_ALCANCE then
			conexao:Disconnect()
			transmitir("ESTILHACO_ESCUDO", lamina.Position, 1.0)
			transmitir("ESTILHACOS", lamina.Position, 0.9)
			tocarSom(CFG.SFX_ESTILHACO, lamina.Position)
			lamina.Parent = nil
		end
	end)

	Debris:AddItem(lamina, CFG.LAMINA_ALCANCE / CFG.LAMINA_VELOCIDADE + 1)
end

--==============================================================================
-- EXTRA — a sentença
--==============================================================================

-- Escolhe o alvo mais próximo que PODE ser atingido. Devolve nil se não houver:
-- a cutscene não roda no vazio.
local function escolherAlvo(jogador, personagem, raiz)
	local melhor, melhorDistancia = nil, math.huge
	for _, alvo in ipairs(humanoidesEmArea(raiz.Position, CFG.SENTENCA_ALCANCE, personagem)) do
		if podeAtingir(jogador, alvo) and alvo.Health > 0 then
			local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				local distancia = (alvoRaiz.Position - raiz.Position).Magnitude
				if distancia < melhorDistancia then
					melhor, melhorDistancia = alvo, distancia
				end
			end
		end
	end
	return melhor
end

local function avisarCamera(jogador, beat, duracao)
	cutsceneRemote:FireClient(jogador, beat, duracao)
end

local function sentenca(jogador, personagem, humanoide, raiz)
	if emSentenca then
		return
	end

	-- A CONDIÇÃO: sem alvo, nada acontece — nem cutscene, nem recarga gasta.
	local alvo = escolherAlvo(jogador, personagem, raiz)
	if not alvo then
		return
	end

	local agora = os.clock()
	if agora - ultimaSentenca < CFG.SENTENCA_RECARGA then
		return
	end
	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_EXTRA, CFG.SENTENCA_RECARGA) then
			return
		end
	end
	ultimaSentenca = agora
	emSentenca = true

	local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
	local total = CFG.ABERTURA + CFG.SENTENCA_CORTES * CFG.CORTE_INTERVALO + CFG.FECHAMENTO

	-- Beat nomeado, nunca CFrame. Quem enquadra é o LocalScript.
	avisarCamera(jogador, "START", total)
	tocarSequencia(Poses.extra())
	tocarSom(CFG.SFX_SENTENCA, raiz.Position)

	if animador then
		animador:LockCharacter(true)
	end

	-- Os dois escudos que cortam. São geometria de verdade, no mundo, porque o
	-- alvo e os espectadores precisam ver de onde vem cada corte.
	local pasta = Instance.new("Folder")
	pasta.Name = "SentencaDeEscudos"
	pasta.Parent = workspace

	local escudos = {}
	for i = 1, 2 do
		local escudo = Instance.new("Part")
		escudo.Name = "EscudoSentenca" .. i
		escudo.Anchored = true
		escudo.CanCollide = false
		escudo.CanQuery = false
		escudo.CanTouch = false
		escudo.CastShadow = false
		escudo.Material = Enum.Material.Metal
		escudo.Color = CFG.COR_SENTENCA
		escudo.Reflectance = 0.45
		escudo.Size = CFG.LAMINA_TAMANHO
		escudo.Parent = pasta
		table.insert(escudos, escudo)
	end

	local function encerrar()
		emSentenca = false
		pasta.Parent = nil
		if animador then
			animador:LockCharacter(false)
			animador:PlaySequence(Poses.repouso())
		end
		avisarCamera(jogador, "STOP")
	end

	task.delay(CFG.ABERTURA, function()
		if not (alvo and alvo.Parent and alvoRaiz and alvoRaiz.Parent) then
			encerrar()
			return
		end

		-- Os cortes. `indice` é sequencial: o ângulo de cada corte vem dele, e
		-- não de math.random — a mesma sentença sai igual toda vez.
		for indice = 1, CFG.SENTENCA_CORTES do
			task.delay(indice * CFG.CORTE_INTERVALO, function()
				if not (alvo.Parent and alvoRaiz.Parent) then
					return
				end

				local angulo = (indice - 1) * (math.pi * 2 / CFG.SENTENCA_CORTES)
				local centro = alvoRaiz.Position
				local desloca = Vector3.new(math.cos(angulo) * 4.5, 1.4, math.sin(angulo) * 4.5)

				-- Os dois escudos ficam em lados opostos do alvo a cada corte.
				escudos[1].CFrame = CFrame.lookAt(centro + desloca, centro)
				escudos[2].CFrame = CFrame.lookAt(centro - desloca, centro)

				aplicarDano(jogador, alvo, CFG.SENTENCA_DANO)
				tocarSom(CFG.SFX_CORTE, centro)
				transmitir("LAMINA", centro, 1.1, CFG.COR_SENTENCA, desloca.Unit)
				transmitir("IMPACTO_ESCUDO", centro, 0.7, CFG.COR_SENTENCA)
				avisarCamera(jogador, "CORTE", indice)
			end)
		end

		-- O golpe mortal: 299, no fim da série.
		task.delay(CFG.SENTENCA_CORTES * CFG.CORTE_INTERVALO, function()
			if alvo.Parent and alvoRaiz.Parent then
				local centro = alvoRaiz.Position
				avisarCamera(jogador, "SENTENCA")
				tocarSom(CFG.SFX_SENTENCA, centro)
				transmitir("CLARAO_ESCUDO", centro + Vector3.new(0, 1.5, 0), 1.8, CFG.COR_SENTENCA)
				transmitir("ONDA_ESCUDO", centro, 1.6, CFG.COR_SENTENCA)
				transmitir("ESTILHACO_ESCUDO", centro, 1.4)
				transmitir("ESTILHACOS", centro, 1.2, CFG.COR_SENTENCA)

				-- 299 pelo Núcleo, que respeita ForceField, escudo e redução.
				-- Nunca `Health = 0`: isso ignoraria tudo isso.
				aplicarDano(jogador, alvo, CFG.SENTENCA_FINAL)
			end

			task.delay(CFG.FECHAMENTO, encerrar)
		end)
	end)
end

--==============================================================================
-- LIGAÇÃO COM A TOOL
--==============================================================================

local function contexto()
	local personagem = tool.Parent
	local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	local jogador = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then
		return nil
	end
	if humanoide.Health <= 0 then
		return nil
	end
	return jogador, personagem, humanoide, raiz
end

tool.Activated:Connect(function()
	if not tool.Enabled or emSentenca then
		return
	end
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador then
		return
	end

	tool.Enabled = false
	tocarSequencia(Poses.primaria())
	lancarLamina(jogador, personagem, raiz)
	task.delay(CFG.RECARGA_BASE, function()
		tool.Enabled = true
	end)
end)

acaoRemote.OnServerEvent:Connect(function(quemPediu)
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador or quemPediu ~= jogador then
		return
	end
	sentenca(jogador, personagem, humanoide, raiz)
end)

local function desmontar()
	for _, lamina in ipairs(laminasVivas) do
		if lamina and lamina.Parent then
			lamina.Parent = nil
		end
	end
	table.clear(laminasVivas)

	if emSentenca then
		emSentenca = false
		local jogador = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
		if jogador then
			avisarCamera(jogador, "CANCEL")
		end
	end

	if animador then
		animador:LockCharacter(false)
		animador:Destroy()
		animador = nil
	end
end

tool.Equipped:Connect(function()
	local personagem = tool.Parent
	if not personagem then
		return
	end
	animador = Animator.new(personagem, CFG.NOME, Poses.POSES, Poses.SEQUENCIAS)
	if animador then
		animador:PlaySequence(Poses.repouso())
	end

	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then
		humanoide.Died:Connect(desmontar)
	end
end)

tool.Unequipped:Connect(desmontar)
tool.Destroying:Connect(desmontar)
