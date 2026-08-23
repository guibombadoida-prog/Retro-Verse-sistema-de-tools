-- Astral Singularidade_Server_V1.lua
-- Script de servidor — Astral Singularidade
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons.
--
--   M1  Horizonte de Eventos — campo na mira que retarda e drena
--   X   Espaguetificação — cutscene sobre o alvo marcado, golpe mortal 210
--
-- Escrito à mão (e não pelo gerador) porque é a única do conjunto com
-- cutscene, e cutscene tem regra própria: a câmera é 100% CLIENTE. O servidor
-- manda BEAT NOMEADO pelo CutsceneRemote; quem enquadra é o LocalScript. E o
-- pulo da cutscene é só visual — não encurta a linha do tempo do servidor,
-- senão pular viraria vantagem de combate.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool           = script.Parent
local Handle         = Tool:WaitForChild("Handle")
local VFXRemote      = Tool:WaitForChild("VFXRemote")
local AcaoRemote     = Tool:WaitForChild("AcaoRemote")
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")
local Poses          = require(Tool:WaitForChild("Poses"))
local Animator       = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ASTRAL"

local CFG = {
	RAIO_HORIZONTE  = 14,
	DANO_HORIZONTE  = 9,
	PULSO_HORIZONTE = 0.5,
	DURACAO_HORIZONTE = 4,
	LENTIDAO        = 0.45,   -- fração da WalkSpeed original
	DEBOUNCE_M1     = 0.6,

	RAIO_MARCA      = 16,
	DANO_MORTAL     = 210,
	CD_ESPAGUETE    = 45,
	BEATS_ESPAGUETE = {
		{ nome = "ABRE",  tempo = 0.45 },
		{ nome = "PUXA",  tempo = 0.55 },
		{ nome = "RASGA", tempo = 0.40 },
		{ nome = "FIM",   tempo = 0.35 },
	},

	SFX_GOLPE = "SlashSound",
	SFX_EXTRA = "TeleSpike",
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local podeExtra = true
local ativos = {}
local retardados = {}   -- [Humanoid] = WalkSpeed original
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function vfx(tipo, dados) VFXRemote:FireAllClients(tipo, dados) end

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

--═══════════════════════════════════════════════════════════════
-- DANO
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

--- Lentidão guardada e SEMPRE devolvida. Velocidade alterada e não restaurada
--- é bug sem saída para o jogador — a Tool largada no meio deixaria o alvo
--- lento para sempre.
local function retardar(alvoHum)
	if retardados[alvoHum] then return end
	retardados[alvoHum] = alvoHum.WalkSpeed
	alvoHum.WalkSpeed = alvoHum.WalkSpeed * CFG.LENTIDAO
end

local function devolverVelocidade()
	for alvo, original in pairs(retardados) do
		if alvo and alvo.Parent then alvo.WalkSpeed = original end
	end
	retardados = {}
end

--═══════════════════════════════════════════════════════════════
-- M1 — HORIZONTE DE EVENTOS
--═══════════════════════════════════════════════════════════════

local function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_M1, function() Tool.Enabled = true end)

	local centro = raiz.Position + raiz.CFrame.LookVector * 10
	local id = "horizonte_" .. tostring(proximo())

	tocar(CFG.SFX_GOLPE, 0.85)
	if rig then rig:PlaySequence("HORIZONTE") end
	vfx("HORIZONTE", { posicao = centro, id = id,
		duracao = CFG.DURACAO_HORIZONTE, escala = 1.1 })

	local fim = os.clock() + CFG.DURACAO_HORIZONTE
	local proximoPulso = 0
	local laco
	laco = guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		if agora >= fim or not (personagem and personagem.Parent) then
			if laco then laco:Disconnect() end
			devolverVelocidade()
			vfx("PARAR", { id = id })
			return
		end
		if agora < proximoPulso then return end
		proximoPulso = agora + CFG.PULSO_HORIZONTE

		for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_HORIZONTE, 10)) do
			aplicarDano(alvo, CFG.DANO_HORIZONTE)
			retardar(alvo)
		end
	end))
end

--═══════════════════════════════════════════════════════════════
-- X — ESPAGUETIFICAÇÃO (cutscene)
--═══════════════════════════════════════════════════════════════

local function escolherAlvo(centro)
	local melhor, menor = nil, math.huge
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_MARCA, 12)) do
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			local d = (alvoRaiz.Position - centro).Magnitude
			if d < menor then melhor, menor = alvo, d end
		end
	end
	return melhor
end

local function extra(mira)
	if not podeExtra or not raiz then return end

	-- A CONDIÇÃO É A HABILIDADE: sem alvo válido não acontece, e não gasta
	-- recarga. Cutscene rodando no vazio prende a câmera para não mostrar nada.
	local alvo = escolherAlvo(mira)
	if not alvo then return end
	local corpoAlvo = alvo.Parent
	if not corpoAlvo then return end

	podeExtra = false
	task.delay(CFG.CD_ESPAGUETE, function() podeExtra = true end)

	tocar(CFG.SFX_EXTRA, 0.8)
	if rig then rig:PlaySequence("ESPAGUETE") end

	-- Beat NOMEADO, nunca CFrame: quem enquadra é o cliente.
	CutsceneRemote:FireAllClients("INICIO", {
		portador = personagem.Name,
		alvoNome = corpoAlvo.Name,
	})

	-- Os beats caminham por PRAZO ABSOLUTO, nunca por `task.wait(beat.tempo)`
	-- encadeado: cada wait devolve um pouco depois do pedido, e o erro se
	-- acumula beat a beat. Com prazo absoluto o atraso de um não empurra o
	-- seguinte, e o fim da cena cai onde foi escrito.
	task.spawn(function()
		local inicio = os.clock()
		local marco = 0
		for _, beat in ipairs(CFG.BEATS_ESPAGUETE) do
			marco = marco + beat.tempo
			local falta = (inicio + marco) - os.clock()
			if falta > 0 then task.wait(falta) end
			if not (personagem and personagem.Parent) then break end

			CutsceneRemote:FireAllClients("BEAT", { nome = beat.nome })

			if beat.nome == "RASGA" then
				local alvoRaiz = corpoAlvo:FindFirstChild("HumanoidRootPart")
				local onde = alvoRaiz and alvoRaiz.Position or mira
				vfx("ESPAGUETE", { posicao = onde, escala = 1.2 })
			elseif beat.nome == "FIM" then
				if alvo and alvo.Health > 0 then
					aplicarDano(alvo, CFG.DANO_MORTAL)
				end
				local alvoRaiz = corpoAlvo:FindFirstChild("HumanoidRootPart")
				vfx("IMPACTO_NOVA", {
					posicao = alvoRaiz and alvoRaiz.Position or mira,
					escala = 1.5,
				})
			end
		end
		CutsceneRemote:FireAllClients("FIM", {})
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

Tool.Activated:Connect(primaria)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	if tecla ~= "X" then return end
	if typeof(mira) ~= "Vector3" then mira = raiz and raiz.Position or Vector3.new() end
	extra(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "AstralSingularidade", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	devolverVelocidade()
	CutsceneRemote:FireAllClients("FIM", {})
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
