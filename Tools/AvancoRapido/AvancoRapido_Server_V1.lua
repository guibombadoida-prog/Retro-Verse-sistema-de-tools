--[[
	AvancoRapido_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Primária: `FastForward` (tecla C) — adianta o tempo. Carga longa, com o relógio surgindo
	          na mão e o tique-taque acelerando, e no fim tudo em volta envelhece de uma vez.
	Extra:    Aceleração (tecla M) — alternância de velocidade 16 ↔ 48 do modelo.

	FIDELIDADE (ver DIRETRIZES/MAPA_DE_FIDELIDADE_Guardiao_Do_Tempo.md):
	o ritmo do original é reproduzido inteiro — surgimento (25 quadros), pausa de 0,5 s,
	aceleração do tique (120 quadros), tremor de alcance 125, três esferas de escala 50/100/150.
	O que NÃO foi reproduzido é o desfecho: o modelo varria `workspace:GetDescendants()` e
	chamava `CHILD:BreakJoints()` em todo Humanoid do mapa — morte instantânea de todos, sem
	filtro de time e furando `ForceField`. Aqui o desfecho é dano alto num raio grande, pelo
	Núcleo. Reproduzir o original seria entregar uma Tool que limpa o servidor inteiro.

	A Aceleração altera WalkSpeed, e a carga imobiliza o dono (`Rooted` no modelo). As duas
	coisas EXIGEM restauração em todo caminho de saída: Unequipped, Died e Destroying.
	Buff ou trava que sobrevive à Tool é falha grave (§12.6).
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local pastaSFX = tool:FindFirstChild("SFX")

--==============================================================================
-- ARQUETIPO + CFG
--==============================================================================

local ARQUETIPO = "HIBRIDO"

local CFG = {
	NOME             = "AvancoRapido",
	TOOLTIP          = "Avanço Rápido - adianta o tempo até tudo em volta envelhecer. M acelera",

	-- Carga: os três tempos do original, convertidos de quadros a 60 fps
	CARGA_SURGIMENTO = 0.42,     -- 25 quadros: o relógio aparece e o tique sobe
	CARGA_PAUSA      = 0.50,     -- wait(0.5) do modelo
	CARGA_ACELERACAO = 2.00,     -- 120 quadros: o tique acelera até o estouro
	PULSOS_CARGA     = 6,        -- mostradores durante a aceleração

	DANO_DETONACAO   = 180,      -- era BreakJoints em todos: virou dano alto, pelo Núcleo
	RAIO_DETONACAO   = 120,      -- o alcance do CamShake do original
	ESCALAS_ESFERA   = {2.0, 3.5, 5.0},   -- as três esferas 50/100/150 do modelo

	RECARGA_AVANCO   = 12.0,
	RECARGA_GLOBAL   = 60.0,

	VELOCIDADE_BASE  = 16,       -- Speed do modelo
	VELOCIDADE_ALTA  = 48,       -- SPEDUP do modelo
	RECARGA_M        = 0.60,

	LIMITE_ALVOS     = 24,

	COR              = Color3.fromRGB(154, 205, 50),
	ESCALA_MOSTRADOR = 1.6,

	SFX_AVANCO       = "Avanco",
	SFX_ACELERACAO   = "Aceleracao",
	VIDA_SOM         = 3,
}

--==============================================================================
-- ESTADO
--==============================================================================

local animador = nil
local cancelamentos = {}
local acelerado = false
local proximoM = 0
local carregando = false
local puloAntes = 50

-- Guardado no Equipped: em Unequipped e Destroying o tool.Parent já NÃO é mais o personagem,
-- e donoAtual() devolveria nil — a aceleração ficaria pendurada no jogador para sempre.
local humanoideEquipado = nil

local function guardarCancelamento(cancelar)
	if type(cancelar) == "function" then
		table.insert(cancelamentos, cancelar)
	end
end

local function cancelarTudo()
	for indice = #cancelamentos, 1, -1 do
		local cancelar = cancelamentos[indice]
		table.remove(cancelamentos, indice)
		local ok, erro = pcall(cancelar)
		if not ok then
			warn("[" .. CFG.NOME .. "] cancelamento falhou: " .. tostring(erro))
		end
	end
end

--==============================================================================
-- CONFIGURAÇÃO BASE
--==============================================================================

tool.CanBeDropped = false
tool.RequiresHandle = true
tool.ToolTip = CFG.TOOLTIP
tool.Enabled = true

--==============================================================================
-- AUXILIARES
--==============================================================================

local function donoAtual()
	local personagem = tool.Parent
	if not personagem or not personagem:FindFirstChildOfClass("Humanoid") then
		return nil, nil, nil
	end
	return Players:GetPlayerFromCharacter(personagem), personagem, personagem:FindFirstChildOfClass("Humanoid")
end

local function tocarSom(nome, posicao)
	if not pastaSFX then
		return
	end
	local molde = pastaSFX:FindFirstChild(nome)
	if not molde or not molde:IsA("Sound") then
		return
	end

	local ancora = Instance.new("Part")
	ancora.Name = CFG.NOME .. "_SFX"
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(1, 1, 1)
	ancora.CFrame = CFrame.new(posicao)

	local som = molde:Clone()
	som.Parent = ancora
	ancora.Parent = workspace
	som:Play()
	Debris:AddItem(ancora, CFG.VIDA_SOM)
end

local function transmitir(tipo, posicao, escala)
	if _G.Combate then
		_G.Combate.transmitirVFX(VFXRemote, tipo, {
			posicao = posicao,
			escala = escala,
			cor = CFG.COR,
		})
	end
end

local function alvosEm(posicao, raio, personagem, jogador, humanoide)
	if _G.Combate then
		return _G.Combate.detectarHumanoides(posicao, raio, personagem, jogador, humanoide, CFG.LIMITE_ALVOS)
	end
	return {}
end

local function aplicarDano(jogador, alvo, dano)
	local final = _G.Combate and _G.Combate.calcular(jogador, alvo, dano) or dano
	alvo:TakeDamage(final)
	return final
end

-- Devolve a velocidade normal. Chamada em TODO caminho de saída.
local function desacelerar(humanoide)
	if acelerado and humanoide and humanoide.Parent then
		humanoide.WalkSpeed = CFG.VELOCIDADE_BASE
	end
	acelerado = false
end

--==============================================================================
-- PRIMÁRIA — adiantar o tempo: carrega, e no fim tudo em volta envelhece
--==============================================================================

-- Solta a imobilização da carga. Guardada, e chamada em todo caminho de saída.
local function soltarCarga(humanoide)
	if carregando and humanoide and humanoide.Parent then
		humanoide.WalkSpeed = acelerado and CFG.VELOCIDADE_ALTA or CFG.VELOCIDADE_BASE
		humanoide.JumpPower = puloAntes
	end
	carregando = false
end

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end

	local jogador, personagem, humanoide = donoAtual()
	if not personagem or not jogador or not humanoide then
		return
	end

	if _G.Combate then
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_C", CFG.RECARGA_GLOBAL)
		if not liberado then
			return
		end
	end

	tool.Enabled = false

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		tool.Enabled = true
		return
	end

	if animador then
		animador:tocar(Poses.primaria())
	end

	-- O modelo trava o dono durante a carga inteira (`Rooted = true`)
	puloAntes = humanoide.JumpPower
	carregando = true
	humanoide.WalkSpeed = 0
	humanoide.JumpPower = 0

	-- FASE 1 — o relógio surge, o tique sobe
	tocarSom(CFG.SFX_AVANCO, handle.Position)
	transmitir("MOSTRADOR_TEMPORAL", handle.Position, CFG.ESCALA_MOSTRADOR)
	task.wait(CFG.CARGA_SURGIMENTO)

	-- FASE 2 — a pausa antes da aceleração
	task.wait(CFG.CARGA_PAUSA)

	-- FASE 3 — o tique acelera. Um mostrador por pulso, cada vez maior.
	local intervalo = CFG.CARGA_ACELERACAO / CFG.PULSOS_CARGA
	local pulso = 1
	while pulso <= CFG.PULSOS_CARGA do
		if not raiz.Parent then
			pulso = CFG.PULSOS_CARGA + 1
		else
			transmitir("MOSTRADOR_TEMPORAL", raiz.Position, CFG.ESCALA_MOSTRADOR * (0.6 + pulso * 0.25))
			task.wait(intervalo)
			pulso = pulso + 1
		end
	end

	soltarCarga(humanoide)

	if not raiz.Parent then
		task.wait(CFG.RECARGA_AVANCO)
		tool.Enabled = true
		return
	end

	-- DETONAÇÃO — SFX → física → VFX → dano (§8 V2)
	local centro = raiz.Position

	tocarSom(CFG.SFX_ACELERACAO, centro)
	transmitir("TREMOR", centro, 2.4)

	for indice = 1, #CFG.ESCALAS_ESFERA do
		transmitir("ESFERA_TEMPORAL", centro, CFG.ESCALAS_ESFERA[indice])
	end
	transmitir("ONDA_TEMPORAL", centro, CFG.ESCALAS_ESFERA[#CFG.ESCALAS_ESFERA])
	transmitir("DETRITOS", centro, 3.0)

	local atingidos = alvosEm(centro, CFG.RAIO_DETONACAO, personagem, jogador, humanoide)
	for _, alvo in ipairs(atingidos) do
		aplicarDano(jogador, alvo, CFG.DANO_DETONACAO)
	end

	task.wait(CFG.RECARGA_AVANCO)
	tool.Enabled = true
end)

--==============================================================================
-- EXTRA — Aceleração (tecla M no Client)
--==============================================================================

local function alternarAceleracao()
	local _, personagem, humanoide = donoAtual()
	if not personagem or not humanoide then
		return
	end

	-- Debounce próprio: a Extra não usa Tool.Enabled, que é da primária (§8)
	local agora = os.clock()
	if agora < proximoM then
		return
	end
	proximoM = agora + CFG.RECARGA_M

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	local ponto = raiz and raiz.Position or handle.Position

	tocarSom(CFG.SFX_ACELERACAO, ponto)

	if acelerado then
		desacelerar(humanoide)
	else
		acelerado = true
		humanoide.WalkSpeed = CFG.VELOCIDADE_ALTA
	end

	transmitir("MOSTRADOR_TEMPORAL", ponto, CFG.ESCALA_MOSTRADOR)
end

local acaoRemote = tool:FindFirstChild("AcaoRemote")
if acaoRemote and acaoRemote:IsA("RemoteEvent") then
	acaoRemote.OnServerEvent:Connect(function(jogadorQuePediu)
		local jogador = donoAtual()
		if jogador and jogadorQuePediu == jogador then
			alternarAceleracao()
		end
	end)
end

--==============================================================================
-- CICLO DE VIDA
--==============================================================================

tool.Equipped:Connect(function()
	local _, personagem, humanoide = donoAtual()
	if not personagem then
		return
	end

	animador = Animator.novo(personagem)
	humanoideEquipado = humanoide

	if humanoide then
		local conexaoMorte
		conexaoMorte = humanoide.Died:Connect(function()
			soltarCarga(humanoide)
			desacelerar(humanoide)
			cancelarTudo()
			if animador then
				animador:parar()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
		guardarCancelamento(function()
			soltarCarga(humanoide)
			desacelerar(humanoide)
		end)
	end
end)

tool.Unequipped:Connect(function()
	-- A aceleração NÃO sobrevive ao desequipar: buff órfão é falha grave (§12.6).
	-- Isto não é resetar Tool.Enabled — a recarga da primária continua correndo (§8).
	desacelerar(humanoideEquipado)

	if animador then
		animador:restaurar()
		animador = nil
	end
end)

tool.Destroying:Connect(function()
	soltarCarga(humanoideEquipado)
	desacelerar(humanoideEquipado)
	cancelarTudo()
	if animador then
		animador:parar()
		animador = nil
	end
end)
