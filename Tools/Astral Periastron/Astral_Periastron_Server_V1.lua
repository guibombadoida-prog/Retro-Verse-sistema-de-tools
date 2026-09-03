-- Astral Periastron_Server_V1.lua
-- Script de servidor — habilidades ORIGINAIS do AstralPeriastron
--
-- CONVERSÃO (§12.12.2). O modelo trazia 4826 linhas em 47 scripts. Nada daquele
-- código entrou; o que entrou foram os NÚMEROS, preservados:
--
--   M1  Golpe .............. 27 de dano · clique duplo <= 0.2 s vira investida
--   M1  Investida .......... semeia 2 orbes astrais, cor por índice sequencial
--   Q   Redirecionar ....... CD 1 s · velocidade 100
--   E   Detonar ............ raio 20 · 25 de dano
--   X   Pulsar Astral ...... CD 60 s · duração 30 s · alcance 200 · 15 por pulso
--                            e fere o portador em 34, como no original
--
-- O QUE MUDOU, E POR QUÊ
--   `Humanoid.Health = 10`  -> TakeDamage. Escrever em Health ignora ForceField
--                              e a redução registrada pelo Núcleo (§12.5).
--   IsTeamMate/TagHumanoid  -> consulta espacial e etiqueta `creator`, na Tool.
--   `math.random`           -> índice sequencial e ângulo áureo.
--   `tick()`                -> `os.clock()`.
--   `wait/spawn/delay`      -> `task.*`.
--   Parte ancorada movida   -> o servidor manda BEAT; quem desenha é o cliente,
--   por frame no servidor      a 60 Hz. No servidor replicaria a ~20 Hz, sem
--                              interpolação — é o VFX picotado.
--   RemoteFunction de mira  -> a mira chega como Vector3 no AcaoRemote.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ASTRAL"

local CFG = {
	DANO_GOLPE      = 27,
	ALCANCE_GOLPE   = 9,
	DEBOUNCE_GOLPE  = 0.42,
	JANELA_DUPLO    = 0.2,

	ORBES_POR_INVESTIDA = 2,
	VIDA_ORBE       = 25,
	RAIO_ORBE       = 20,
	DANO_ORBE       = 25,
	CD_REDIRECIONAR = 1,
	CD_DETONAR      = 1,
	VELOCIDADE_ORBE = 100,

	CD_PULSAR       = 60,
	DURACAO_PULSAR  = 30,
	ALCANCE_PULSAR  = 200,
	DANO_PULSAR     = 15,
	PULSO_PULSAR    = 1.5,
	ALTURA_PULSAR   = 45,
	CUSTO_PULSAR    = 34,   -- o original fere o portador; mantido

	SFX_GOLPE       = "SlashSound",
	SFX_INVESTIDA   = "LungeSound",
	SFX_ORBE        = "OrbCreates",
	SFX_PULSAR      = "TeleWarp",
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA. `Vector3.new(0/0, 0/0, 0/0)` é um
--    `Vector3` legítimo para o `typeof`; um cliente modificado manda isso,
--    `.Unit` devolve NaN, e força NaN envenena a assembly do alvo. Nenhum
--    `pcall` pega, porque não há erro — a conta só não tem resultado.
--
--    `n ~= n` é o único teste de NaN em Lua: NaN é o único valor que não é
--    igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda junto.
--
-- E RATE LIMIT É DO SERVIDOR. O `Client` limita a taxa dele e isso não vale
-- nada: quem manda o pacote é o cliente, e cliente modificado manda o quanto
-- quiser. O limite que conta é o daqui.
--
-- Revisão do Codex no PR #1, item P1.6.
--═══════════════════════════════════════════════════════════════

local MIRA_MAX = 400
local PEDIDOS_POR_SEG = 30

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > MIRA_MAX then
		return raiz.Position + delta.Unit * MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem abusa é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= PEDIDOS_POR_SEG
end
local ultimoGolpe = 0
local podeRedirecionar, podeDetonar, podePulsar = true, true, true
local orbes = {}          -- { posicao = Vector3, cor = Color3, id = string }
local ativos = {}         -- conexões e tokens a cancelar no Unequipped
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function tocar(nome, pitch)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, (som.TimeLength > 0 and som.TimeLength or 4) + 1)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

local function soltarTudo()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	local marca = alvoHum:FindFirstChild("creator")
	if marca then marca.Parent = nil end
	marca = Instance.new("ObjectValue")
	marca.Name = "creator"
	marca.Value = jogador
	marca.Parent = alvoHum
	Debris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local final = bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--- Alvos num raio. NPC é Model com Humanoid, NÃO é Player: varrer
--- `Players:GetPlayers()` não enxerga NPC nenhum, e foi assim que uma leva
--- inteira saiu sem acertar inimigo de mapa.
local function alvosEm(posicao, raio, limite)

	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not vistos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

--═══════════════════════════════════════════════════════════════
-- ORBES — dado no servidor, desenho no cliente
--═══════════════════════════════════════════════════════════════

local function semearOrbe(posicao)
	local id = "orbe_" .. tostring(proximo())
	local registro = { posicao = posicao, id = id, nascido = os.clock() }
	table.insert(orbes, registro)
	vfx("ORBE", { posicao = posicao, id = id, duracao = CFG.VIDA_ORBE })
	tocar(CFG.SFX_ORBE, 1)

	task.delay(CFG.VIDA_ORBE, function()
		for i, o in ipairs(orbes) do
			if o.id == id then
				table.remove(orbes, i)
				break
			end
		end
		vfx("PARAR", { id = id })
	end)
	return registro
end

--- Q: manda todos os orbes para a mira. O deslocamento é DADO — o cliente
--- interpola a 60 Hz; o servidor só diz de onde para onde, e em quanto tempo.
local function redirecionar(mira)
	if not podeRedirecionar or #orbes == 0 then return end
	podeRedirecionar = false
	task.delay(CFG.CD_REDIRECIONAR, function() podeRedirecionar = true end)

	if rig then rig:PlaySequence("APONTAR") end

	for _, orbe in ipairs(orbes) do
		local distancia = (mira - orbe.posicao).Magnitude
		local tempo = math.clamp(distancia / CFG.VELOCIDADE_ORBE, 0.05, 3)
		vfx("PARAR", { id = orbe.id })
		vfx("ORBE", {
			posicao = mira, id = orbe.id,
			duracao = CFG.VIDA_ORBE, viagem = tempo, de = orbe.posicao,
		})
		orbe.posicao = mira
	end
end

--- E: estoura os orbes. Raio 20, dano 25 — os números do original.
local function detonar()
	if not podeDetonar or #orbes == 0 then return end
	podeDetonar = false
	task.delay(CFG.CD_DETONAR, function() podeDetonar = true end)

	if rig then rig:PlaySequence("DETONAR") end

	local lista = orbes
	orbes = {}
	for _, orbe in ipairs(lista) do
		vfx("PARAR", { id = orbe.id })
		vfx("ORBE_DETONA", { posicao = orbe.posicao, escala = 1.1 })
		for _, alvo in ipairs(alvosEm(orbe.posicao, CFG.RAIO_ORBE, 12)) do
			aplicarDano(alvo, CFG.DANO_ORBE)
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- PULSAR ASTRAL — X
--═══════════════════════════════════════════════════════════════

local function pulsar()
	if not podePulsar or not raiz then return end
	podePulsar = false
	task.delay(CFG.CD_PULSAR, function() podePulsar = true end)

	local centro = raiz.Position + Vector3.new(0, CFG.ALTURA_PULSAR, 0)
	local id = "pulsar_" .. tostring(proximo())

	if rig then rig:PlaySequence("INVOCAR") end
	tocar(CFG.SFX_PULSAR, 0.9)
	vfx("PULSAR", { posicao = centro, id = id, duracao = CFG.DURACAO_PULSAR })

	-- O original fere o portador em 34. Mantido — mas por TakeDamage, que
	-- respeita ForceField e a redução do Núcleo. `Health = 10` matava quem
	-- tinha acabado de nascer.
    if humanoide and humanoide.Health > 0 then
		local reduzido = CFG.CUSTO_PULSAR
		humanoide:TakeDamage(reduzido)
	end

	local fim = os.clock() + CFG.DURACAO_PULSAR
	local proximoPulso = 0

	local laco
	laco = guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		if agora >= fim or not (personagem and personagem.Parent) then
			if laco then laco:Disconnect() end
			vfx("PARAR", { id = id })
			return
		end
		if agora < proximoPulso then return end
		proximoPulso = agora + CFG.PULSO_PULSAR

		vfx("PULSAR_TICK", { posicao = centro })
		for _, alvo in ipairs(alvosEm(centro, CFG.ALCANCE_PULSAR, 16)) do
			aplicarDano(alvo, CFG.DANO_PULSAR)
		end
	end))
end

--═══════════════════════════════════════════════════════════════
-- GOLPE — Tool.Activated
--═══════════════════════════════════════════════════════════════

local function golpear()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_GOLPE, function() Tool.Enabled = true end)

	local agora = os.clock()
	local investida = (agora - ultimoGolpe) <= CFG.JANELA_DUPLO
	ultimoGolpe = agora

	local frente = raiz.CFrame.LookVector
	local ponto = raiz.Position + frente * 3

	if investida then
		tocar(CFG.SFX_INVESTIDA, 1)
		if rig then rig:PlaySequence("INVESTIDA") end
		vfx("GOLPE", { posicao = ponto, direcao = frente, escala = 1.25 })

		-- Semeia os orbes do original: 2 por investida, cor por índice
		local i = 0
		while i < CFG.ORBES_POR_INVESTIDA do
			local ang = i * 2.39996
			local desvio = Vector3.new(math.cos(ang) * 2.5, 1.5, math.sin(ang) * 2.5)
			semearOrbe(raiz.Position + frente * 4 + desvio)
			i = i + 1
		end
		if rig then rig:PlaySequence("SEMEAR") end
	else
		tocar(CFG.SFX_GOLPE, 1)
		if rig then rig:PlaySequence("GOLPE") end
		vfx("GOLPE", { posicao = ponto, direcao = frente, escala = 1 })
	end

	local dano = CFG.DANO_GOLPE
	if investida then dano = math.floor(dano * 1.2) end
	local acertou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.ALCANCE_GOLPE, 6)) do
		aplicarDano(alvo, dano)
		acertou = true
	end
	if acertou then
		vfx("IMPACTO", { posicao = ponto, escala = investida and 1.3 or 1 })
	end
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

Tool.Activated:Connect(golpear)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	if not taxaOk() then return end
	if type(tecla) ~= "string" then return end
	mira = sanearMira(mira) or (raiz and raiz.Position) or Vector3.new()

	if tecla == "Q" then
		redirecionar(mira)
	elseif tecla == "E" then
		detonar()
	elseif tecla == "X" then
		pulsar()
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "AstralPeriastron", Poses, Poses.SEQUENCIAS)
	if rig then rig:PlaySequence("GOLPE") end
end)

local function desmontar()
	soltarTudo()
	for _, orbe in ipairs(orbes) do
		vfx("PARAR", { id = orbe.id })
	end
	orbes = {}
	if rig then
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)

--═══════════════════════════════════════════════════════════════
-- REGRA Nº 2 — o VFX sai da Tool quando ela chega ao jogador
--
-- Uma linha. O `DepositoVFX` liga o ciclo inteiro sozinho: instala na troca de
-- pai (mochila OU mão), desinstala no `Tool.Destroying`, e conta as referências
-- para não arrancar o molde debaixo de quem ainda está com a Tool.
--
-- Ver DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
