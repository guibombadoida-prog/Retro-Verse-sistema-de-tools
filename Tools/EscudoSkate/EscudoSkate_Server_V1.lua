--[[
	EscudoSkate_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Convertido de `Escudo Skate`, do modelo Danilo_Escudos.

	O QUE MUDOU NA CONVERSÃO
		A origem guardava `originalSpeed` numa variável local e devolvia com
		`humanoid.WalkSpeed = originalSpeed` no fim. Se a Tool fosse largada no
		meio, ou o dono morresse, a velocidade FICAVA em 51 para sempre. Aqui a
		restauração está em `desmontar()`, ligada em Unequipped, Destroying e
		Died — os três, sempre.

		A origem também somava `WalkSpeed + 35` sobre o valor corrente. Duas
		ativações sobrepostas davam +70. Aqui o bônus só entra se não houver
		outro ativo, e o valor guardado é o de antes do primeiro.

		Números da origem preservados: +35 de velocidade, 5 s de duração,
		10 de dano de contato, raio 4, recarga de 0,5 s por alvo, 8 s de recarga.

	PRIMÁRIA (Tool.Activated)  monta no escudo: +35 de velocidade por 5 s, e
	                           quem estiver no caminho leva 10 e é empurrado
	Sem Extra — a Tool é de mobilidade, e a mobilidade já é a habilidade.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "CORREDOR"

local CFG = {
	NOME = "EscudoSkate",

	DURACAO       = 5.0,
	BONUS_VELOCIDADE = 35,
	RECARGA       = 8,

	DANO_CONTATO  = 10,
	RAIO_CONTATO  = 4,
	EMPURRAO      = 60,
	ESPERA_POR_ALVO = 0.5,

	-- Poeira: sai enquanto a velocidade for alta. Abaixo disso o personagem
	-- está parado, e poeira de quem está parado lê como bug.
	VELOCIDADE_MINIMA_POEIRA = 12,
	POEIRA_INTERVALO = 0.28,

	COR_VFX    = Color3.fromRGB(0, 122, 190),
	COR_BATIDA = Color3.fromRGB(255, 150, 0),
	ESCALA_VFX = 1.0,

	SFX_PARTIDA  = "Partida",
	SFX_ATROPELO = "Atropelo",

	CHAVE_PRIMARIA = "EscudoSkate_Primaria",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local montado = false
local velocidadeGuardada = nil
local conexao = nil
local ultimaBatida = {}

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
-- DESMONTAR — a velocidade SEMPRE volta
--==============================================================================

local function descer()
	if conexao then
		conexao:Disconnect()
		conexao = nil
	end

	if montado then
		montado = false
		local personagem = tool.Parent
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		-- Restaurar o valor GUARDADO, não subtrair o bônus: se outro sistema
		-- mexeu na velocidade no meio, subtrair deixaria o jogador devendo.
		if humanoide and velocidadeGuardada then
			humanoide.WalkSpeed = velocidadeGuardada
		end
	end

	velocidadeGuardada = nil
	table.clear(ultimaBatida)
end

--==============================================================================
-- PRIMÁRIA — montar no escudo
--==============================================================================

local function montar(jogador, personagem, humanoide, raiz)
	if montado then
		return
	end
	montado = true
	velocidadeGuardada = humanoide.WalkSpeed
	humanoide.WalkSpeed = velocidadeGuardada + CFG.BONUS_VELOCIDADE

	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_PARTIDA, raiz.Position)
	transmitir("POEIRA_ESCUDO", raiz.Position, 1.2)
	transmitir("IMPACTO_ESCUDO", raiz.Position, 0.9)

	local t = 0
	local desdePoeira = 0

	conexao = RunService.Heartbeat:Connect(function(dt)
		if not montado then
			return
		end
		if not (raiz and raiz.Parent and humanoide and humanoide.Health > 0) then
			descer()
			return
		end

		t = t + dt
		if t >= CFG.DURACAO then
			descer()
			if animador then
				animador:PlaySequence(Poses.repouso())
			end
			return
		end

		local velocidade = raiz.AssemblyLinearVelocity.Magnitude

		-- Poeira só enquanto corre de verdade.
		desdePoeira = desdePoeira + dt
		if velocidade >= CFG.VELOCIDADE_MINIMA_POEIRA and desdePoeira >= CFG.POEIRA_INTERVALO then
			desdePoeira = 0
			transmitir("POEIRA_ESCUDO", raiz.Position - Vector3.new(0, 2.4, 0), 0.8)
		end

		-- Atropelo: só vale correndo. Parado em cima de alguém não machuca.
		if velocidade < CFG.VELOCIDADE_MINIMA_POEIRA then
			return
		end

		local agora = os.clock()
		for _, alvo in ipairs(humanoidesEmArea(raiz.Position, CFG.RAIO_CONTATO, personagem, jogador, humanoide)) do
			local ultimo = ultimaBatida[alvo] or 0
			if agora - ultimo >= CFG.ESPERA_POR_ALVO and podeAtingir(jogador, alvo) then
				ultimaBatida[alvo] = agora
				aplicarDano(jogador, alvo, CFG.DANO_CONTATO)

				local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					tocarSom(CFG.SFX_ATROPELO, alvoRaiz.Position)
					transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.8, CFG.COR_BATIDA)
					transmitir("FAISCA", alvoRaiz.Position, 0.7, CFG.COR_BATIDA)

					local direcao = raiz.CFrame.LookVector
					local empurrao = Instance.new("BodyVelocity")
					empurrao.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					empurrao.Velocity = direcao * CFG.EMPURRAO + Vector3.new(0, 22, 0)
					empurrao.Parent = alvoRaiz
					Debris:AddItem(empurrao, 0.16)
				end
			end
		end
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
	if not tool.Enabled or montado then
		return
	end
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador then
		return
	end

	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_PRIMARIA, CFG.RECARGA) then
			return
		end
	end

	tool.Enabled = false
	montar(jogador, personagem, humanoide, raiz)
	task.delay(CFG.RECARGA, function()
		tool.Enabled = true
	end)
end)

local function desmontar()
	descer()
	if animador then
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
