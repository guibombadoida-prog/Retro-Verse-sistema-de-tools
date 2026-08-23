-- Astral_Cometa_Server_V1.lua
-- Script de servidor — Astral Cometa
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  Cometa — projétil incandescente com cauda
--   X   Chuva Sideral — meteoros caem na área da mira
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
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ASTRAL"

local CFG = {
	DANO_COMETA     = 29,
	RAIO_COMETA     = 8,
	ALCANCE_COMETA  = 90,
	VELOCIDADE      = 120,
	DEBOUNCE_COMETA = 0.45,

	METEOROS        = 5,
	DANO_METEORO    = 22,
	RAIO_METEORO    = 12,
	RAIO_CHUVA      = 22,
	INTERVALO_METEORO = 0.22,
	CD_CHUVA        = 22,

	SFX_GOLPE       = "SlashSound",
	SFX_EXTRA       = "TeleWarp",
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

--- Cometa: o servidor não move geometria. Ele calcula a rota, manda UM beat
--- com origem, destino e tempo, e o cliente desenha a 60 Hz. Parte ancorada
--- movida por script de servidor replica a ~20 Hz sem interpolação.
function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_COMETA, function() Tool.Enabled = true end)

	local origem = raiz.Position + raiz.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0)
	local direcao = raiz.CFrame.LookVector

	tocar(CFG.SFX_GOLPE, 1.1)
	if rig then rig:PlaySequence("COMETA") end

	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(origem, direcao * CFG.ALCANCE_COMETA, filtro)
	local destino = batida and batida.Position or (origem + direcao * CFG.ALCANCE_COMETA)
	local voo = (destino - origem).Magnitude / CFG.VELOCIDADE

	vfx("COMETA", { posicao = origem, destino = destino, direcao = direcao,
		duracao = voo, escala = 1.1 })

	-- o dano acontece quando o cometa chega, não quando sai
	task.delay(voo, function()
		if not (personagem and personagem.Parent) then return end
		vfx("IMPACTO_NOVA", { posicao = destino, escala = 1.1 })
		for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_COMETA, 8)) do
			aplicarDano(alvo, CFG.DANO_COMETA)
		end
	end)
end

--- Chuva Sideral: meteoros na área da mira, espalhados por ÂNGULO ÁUREO —
--- nunca math.random, para os dois clientes verem a mesma chuva.
function extra(mira)
	if not podeExtra or not raiz then return end
	podeExtra = false
	task.delay(CFG.CD_CHUVA, function() podeExtra = true end)

	tocar(CFG.SFX_EXTRA, 0.95)
	if rig then rig:PlaySequence("CHUVA") end

	local i = 0
	while i < CFG.METEOROS do
		local indice = i
		local ang = indice * 2.39996
		local raioQueda = CFG.RAIO_CHUVA * math.sqrt((indice + 1) / CFG.METEOROS)
		local ponto = mira + Vector3.new(math.cos(ang) * raioQueda, 0,
			math.sin(ang) * raioQueda)

		task.delay(indice * CFG.INTERVALO_METEORO, function()
			if not (personagem and personagem.Parent) then return end
			vfx("CHUVA", { posicao = ponto, escala = 1 })
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_METEORO, 8)) do
				aplicarDano(alvo, CFG.DANO_METEORO)
			end
		end)
		i = i + 1
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

	rig = Animator.new(personagem, "AstralCometa", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	soltarTudo()
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
