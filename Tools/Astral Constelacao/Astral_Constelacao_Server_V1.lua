-- Astral_Constelacao_Server_V1.lua
-- Script de servidor — Astral Constelação
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  Traço Sideral — marca quem for atingido
--   X   Sentença da Constelação — liga as marcas e detona
--
-- Gerado por FERRAMENTAS/gerar_servers_astral.py — o esqueleto (ciclo de vida,
-- dano pelo Núcleo, detecção que enxerga NPC, beat para o cliente) mora lá.
-- Editar aqui à mão faz as quatro derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ASTRAL"

local CFG = {
	DANO_TRACO      = 24,
	ALCANCE_TRACO   = 10,
	DEBOUNCE_TRACO  = 0.4,
	VIDA_MARCA      = 8,
	MAX_MARCAS      = 6,

	DANO_SENTENCA   = 26,
	BONUS_TRES      = 40,     -- a partir de 3 marcas a sentença pesa mais
	CD_SENTENCA     = 30,

	SFX_GOLPE       = "SlashSound",
	SFX_EXTRA       = "Antificated",
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local podeExtra = true
local ativos = {}
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

--- NPC é Model com Humanoid, NÃO é Player: varrer `Players:GetPlayers()` não
--- enxerga NPC nenhum, e foi assim que uma leva inteira saiu sem acertar
--- inimigo de mapa.
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

--- Empurrão sem mexer em Health nem em estado: BodyVelocity com prazo.
local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADES
--═══════════════════════════════════════════════════════════════

local marcas = {}   -- [Humanoid] = { id = string, ate = number }

local function marcar(alvo)
	local atual = marcas[alvo]
	if atual then
		atual.ate = os.clock() + CFG.VIDA_MARCA
		return
	end

	local quantas = 0
	for _ in pairs(marcas) do quantas = quantas + 1 end
	if quantas >= CFG.MAX_MARCAS then return end

	local id = "marca_" .. tostring(proximo())
	marcas[alvo] = { id = id, ate = os.clock() + CFG.VIDA_MARCA }

	local corpo = alvo.Parent
	vfx("TRACO", {
		alvoNome = corpo and corpo.Name,
		deslocamento = Vector3.new(0, 3, 0),
		id = id, duracao = CFG.VIDA_MARCA,
	})

	task.delay(CFG.VIDA_MARCA, function()
		local reg = marcas[alvo]
		if reg and os.clock() >= reg.ate then
			marcas[alvo] = nil
			vfx("PARAR", { id = reg.id })
		end
	end)
end

function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_TRACO, function() Tool.Enabled = true end)

	local frente = raiz.CFrame.LookVector
	local ponto = raiz.Position + frente * 3

	tocar(CFG.SFX_GOLPE, 1)
	if rig then rig:PlaySequence("TRACO") end
	vfx("GOLPE", { posicao = ponto, direcao = frente, escala = 1 })

	for _, alvo in ipairs(alvosEm(ponto, CFG.ALCANCE_TRACO, 6)) do
		aplicarDano(alvo, CFG.DANO_TRACO)
		marcar(alvo)
		vfx("IMPACTO", { posicao = ponto, escala = 0.9 })
	end
end

--- Sentença: liga as marcas vivas e detona todas de uma vez. Sem marca não
--- acontece — e sem acontecer, NÃO gasta recarga.
function extra(mira)
	if not podeExtra or not raiz then return end

	local vivos, pontos = {}, {}
	local agora = os.clock()
	for alvo, reg in pairs(marcas) do
		if alvo and alvo.Health > 0 and agora < reg.ate then
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				table.insert(vivos, alvo)
				table.insert(pontos, alvoRaiz.Position + Vector3.new(0, 3, 0))
			end
		end
	end
	if #vivos == 0 then return end

	podeExtra = false
	task.delay(CFG.CD_SENTENCA, function() podeExtra = true end)

	tocar(CFG.SFX_EXTRA, 0.9)
	if rig then rig:PlaySequence("SENTENCA") end
	vfx("SENTENCA", { pontos = pontos })

	local dano = CFG.DANO_SENTENCA
	if #vivos >= 3 then dano = dano + CFG.BONUS_TRES end

	for _, alvo in ipairs(vivos) do
		local reg = marcas[alvo]
		if reg then vfx("PARAR", { id = reg.id }) end
		marcas[alvo] = nil
		aplicarDano(alvo, dano)
	end
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

	rig = Animator.new(personagem, "AstralConstelacao", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	soltarTudo()
	for _, reg in pairs(marcas) do
		vfx("PARAR", { id = reg.id })
	end
	marcas = {}
	if rig then
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
