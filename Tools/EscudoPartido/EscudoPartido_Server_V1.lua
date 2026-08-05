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
	CORTE_INTERVALO   = 0.217,  -- cadência medida no pack de referência
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

local function humanoidesEmArea(posicao, raio, meuPersonagem, jogador, humanoideDono)
	-- Assinatura do Núcleo: (posicao, raio, ignorar, jogador, humanoideDono, limite).
	-- Passar só os três primeiros deixa `jogador` nil, e aí o filtro de time do
	-- podeCausarDano é PULADO — aliado vira alvo válido.
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(posicao, raio, meuPersonagem, jogador, humanoideDono, CFG.LIMITE_ALVOS) or {}
	end

	-- Fallback sem Núcleo. Varre MODELOS com Humanoid no raio, não Players:
	-- NPC não é Player, e varrer Players:GetPlayers() simplesmente não enxerga
	-- NPC nenhum. Era por isso que o dano e a cutscene não pegavam em NPC.
	local achados = {}
	local parametros = OverlapParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	if meuPersonagem then
		parametros.FilterDescendantsInstances = { meuPersonagem }
	end
	parametros.MaxParts = CFG.LIMITE_PARTES

	local ok, partes = pcall(function()
		return workspace:GetPartBoundsInRadius(posicao, raio, parametros)
	end)
	if not ok or not partes then
		return achados
	end

	local vistos = {}
	for _, parte in ipairs(partes) do
		if #achados >= CFG.LIMITE_ALVOS then
			break
		end
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local humanoide = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if humanoide and not vistos[humanoide] and humanoide.Health > 0 then
			vistos[humanoide] = true
			if humanoide ~= humanoideDono then
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

-- `calcular` roda o pipeline do §12.5 (aumento, redução, escudo) e REGISTRA a
-- queda como prevista, para o observador não recalcular. Quem tira a vida é a
-- Tool, com TakeDamage — que respeita ForceField.
--
-- `registrarAtaque` NÃO serve para isto: ela só grava a atribuição de abate
-- (§12.8), e chamá-la no lugar de calcular resultava em dano ZERO.
local function aplicarDano(jogador, alvo, valor)
	if not podeAtingir(jogador, alvo) then
		return false
	end
	local final = valor
	if _G.Combate and _G.Combate.calcular then
		final = _G.Combate.calcular(jogador, alvo, valor) or valor
	end
	if final > 0 then
		alvo:TakeDamage(final)
	end
	return true
end

--==============================================================================
-- PRIMÁRIA — a lâmina que não volta
--==============================================================================

--[[
	A lâmina que não volta.

	O DESENHO é do cliente: `DISCO_VOO` com `volta = false`. O servidor não cria
	Part — Part ancorada movida por script de servidor replica a ~20 Hz sem
	interpolação, e era isso que picotava o voo. A trajetória é fórmula, e os
	dois lados usam a mesma.
]]
local function lancarLamina(jogador, personagem, raiz)
	local direcao = raiz.CFrame.LookVector
	local origem = raiz.Position + direcao * 2 + Vector3.new(0, 1.2, 0)

	tocarSom(CFG.SFX_CORTE, origem)
	transmitir("LAMINA", origem, 1.0, CFG.COR_VFX, direcao)

	local payload = {
		posicao = origem,
		frente = direcao,
		velocidade = CFG.LAMINA_VELOCIDADE,
		alcance = CFG.LAMINA_ALCANCE,
		volta = false,
		tamanho = CFG.LAMINA_TAMANHO,
		cor = CFG.COR_VFX,
		userId = jogador.UserId,
	}
	if _G.Combate and _G.Combate.transmitirVFX then
		_G.Combate.transmitirVFX(VFXRemote, "DISCO_VOO", payload)
	else
		VFXRemote:FireAllClients("DISCO_VOO", payload)
	end

	local percorrido = 0
	local posicao = origem
	local jaAtingidos = {}
	local conexao

	conexao = RunService.Heartbeat:Connect(function(dt)
		local passo = CFG.LAMINA_VELOCIDADE * dt
		percorrido = percorrido + passo
		posicao = posicao + direcao * passo

		for _, alvo in ipairs(humanoidesEmArea(posicao, CFG.LAMINA_RAIO, personagem, jogador, nil)) do
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
			transmitir("ESTILHACOS", posicao, 0.9)
			tocarSom(CFG.SFX_ESTILHACO, posicao)
		end
	end)

	task.delay(CFG.LAMINA_ALCANCE / CFG.LAMINA_VELOCIDADE + 1, function()
		if conexao.Connected then
			conexao:Disconnect()
		end
	end)
end

--==============================================================================
-- EXTRA — a sentença
--==============================================================================

-- Escolhe o alvo mais próximo que PODE ser atingido. Devolve nil se não houver:
-- a cutscene não roda no vazio.
local function escolherAlvo(jogador, personagem, raiz)
	local melhor, melhorDistancia = nil, math.huge
	for _, alvo in ipairs(humanoidesEmArea(raiz.Position, CFG.SENTENCA_ALCANCE, personagem, jogador, humanoide)) do
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

	-- Os dois escudos que cortam são desenhados no CLIENTE, um par de LAMINA por
	-- corte, em lados opostos do alvo. Manter duas Part no servidor e
	-- reposicioná-las por corte custaria replicação e chegaria picotado.
	local function encerrar()
		emSentenca = false
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

		-- A série de cortes é UMA sequência de animação, disparada uma vez: os
		-- seis beats já vêm na cadência de 0,217 s medida no pack. Chamar
		-- PlaySequence por corte cancelaria a anterior no meio.
		tocarSequencia(Poses.cortes())

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

				aplicarDano(jogador, alvo, CFG.SENTENCA_DANO)
				tocarSom(CFG.SFX_CORTE, centro)
				-- Os dois cortes, em lados opostos, no mesmo quadro.
				transmitir("LAMINA", centro, 1.1, CFG.COR_SENTENCA, desloca.Unit)
				transmitir("LAMINA", centro, 1.1, CFG.COR_SENTENCA, -desloca.Unit)
				transmitir("IMPACTO_ESCUDO", centro, 0.7, CFG.COR_SENTENCA)
				avisarCamera(jogador, "CORTE", indice)
			end)
		end

		-- O golpe mortal: 299, no fim da série.
		task.delay(CFG.SENTENCA_CORTES * CFG.CORTE_INTERVALO, function()
			if alvo.Parent and alvoRaiz.Parent then
				local centro = alvoRaiz.Position
				tocarSequencia(Poses.mortal())
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
