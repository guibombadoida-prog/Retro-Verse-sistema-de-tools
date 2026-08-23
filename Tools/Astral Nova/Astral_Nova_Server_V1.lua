-- Astral_Nova_Server_V1.lua
-- Script de servidor — Astral Nova
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  Nova Estelar — onda estelar em cone, empurra quem pega
--   X   Colapso Anão — puxa tudo para o centro e detona
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
	DANO_NOVA       = 31,
	ALCANCE_NOVA    = 15,
	ANGULO_NOVA     = 70,      -- graus, meia-abertura do cone
	EMPURRAO_NOVA   = 55,
	DEBOUNCE_NOVA   = 0.5,

	RAIO_COLAPSO    = 26,
	DANO_COLAPSO    = 44,
	PUXAO_COLAPSO   = 70,
	TEMPO_COLAPSO   = 0.55,
	CD_COLAPSO      = 18,

	SFX_GOLPE       = "SlashSound",
	SFX_EXTRA       = "TeleSpike",
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

--- Nova Estelar: cone à frente. O cone é conferido por ÂNGULO, não por
--- caixa: quem está atrás do portador não leva.
function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_NOVA, function() Tool.Enabled = true end)

	local frente = raiz.CFrame.LookVector
	local centro = raiz.Position + frente * 4

	tocar(CFG.SFX_GOLPE, 1.05)
	if rig then rig:PlaySequence("NOVA") end
	vfx("NOVA", { posicao = centro, escala = 1.2, direcao = frente })

	local limite = math.cos(math.rad(CFG.ANGULO_NOVA))
	local acertou = false
	for _, alvo in ipairs(alvosEm(centro, CFG.ALCANCE_NOVA, 12)) do
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			local para = (alvoRaiz.Position - raiz.Position)
			if para.Magnitude > 0.1 and para.Unit:Dot(frente) >= limite then
				aplicarDano(alvo, CFG.DANO_NOVA)
				empurrar(alvo, para + Vector3.new(0, 0.4, 0), CFG.EMPURRAO_NOVA, 0.22)
				acertou = true
			end
		end
	end
	if acertou then
		vfx("IMPACTO", { posicao = centro, escala = 1.2 })
	end
end

--- Colapso Anão: puxa por PULSOS, não continuamente. Puxão contínuo briga
--- com o Humanoid do alvo — dois donos do mesmo corpo, e o alvo trava.
function extra(mira)
	if not podeExtra or not raiz then return end
	podeExtra = false
	task.delay(CFG.CD_COLAPSO, function() podeExtra = true end)

	local centro = raiz.Position + raiz.CFrame.LookVector * 8
	tocar(CFG.SFX_EXTRA, 0.9)
	if rig then rig:PlaySequence("COLAPSO") end
	vfx("COLAPSO", { posicao = centro, escala = 1.3 })

	local fim = os.clock() + CFG.TEMPO_COLAPSO
	local proximoPulso = 0
	local laco
	laco = guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		if agora >= fim then
			if laco then laco:Disconnect() end
			vfx("IMPACTO_NOVA", { posicao = centro, escala = 1.4 })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
				aplicarDano(alvo, CFG.DANO_COLAPSO)
			end
			return
		end
		if agora < proximoPulso then return end
		proximoPulso = agora + 0.2

		for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				local para = centro - alvoRaiz.Position
				if para.Magnitude > 2 then
					empurrar(alvo, para, CFG.PUXAO_COLAPSO, 0.18)
				end
			end
		end
	end))
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

	rig = Animator.new(personagem, "AstralNova", Poses, Poses.SEQUENCIAS)
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
