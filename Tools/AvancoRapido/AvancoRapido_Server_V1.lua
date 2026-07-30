--[[
	AvancoRapido_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Primária: `FastForward` (tecla C) — avanço rápido para a frente, atropelando quem estiver
	          no caminho.
	Extra:    Aceleração (tecla M) — alternância de velocidade 16 ↔ 48 do modelo.

	Agrupamento (REGRA DE DISTRIBUIÇÃO): as duas são deslocamento — moram na mesma Tool.

	A Aceleração altera WalkSpeed, e por isso EXIGE restauração em todo caminho de saída:
	Unequipped, Died e Destroying. Buff que sobrevive à Tool é falha grave (§12.6).
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

local ARQUETIPO = "LUTADOR"

local CFG = {
	NOME             = "AvancoRapido",
	TOOLTIP          = "Avanço Rápido - atravesse o instante. M alterna a aceleração",

	DANO_AVANCO      = 22,
	DISTANCIA        = 42,
	PASSOS           = 14,       -- o avanço é dividido em passos, para atingir no caminho
	RAIO_PASSO       = 7,
	INTERVALO_PASSO  = 0.02,

	RECARGA_AVANCO   = 2.20,

	VELOCIDADE_BASE  = 16,       -- Speed do modelo
	VELOCIDADE_ALTA  = 48,       -- SPEDUP do modelo
	RECARGA_M        = 0.60,

	LIMITE_ALVOS     = 8,

	COR              = Color3.fromRGB(154, 205, 50),
	ESCALA_RASTRO    = 0.9,
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
-- PRIMÁRIA — avanço
--==============================================================================

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end
	tool.Enabled = false

	local jogador, personagem, humanoide = donoAtual()
	if not personagem then
		tool.Enabled = true
		return
	end

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		tool.Enabled = true
		return
	end

	if animador then
		animador:tocar(Poses.primaria())
	end

	tocarSom(CFG.SFX_AVANCO, handle.Position)
	transmitir("MOSTRADOR_TEMPORAL", raiz.Position, CFG.ESCALA_MOSTRADOR)

	local direcao = raiz.CFrame.LookVector
	local trecho = CFG.DISTANCIA / CFG.PASSOS
	local jaAtingidos = {}

	local passo = 1
	while passo <= CFG.PASSOS do
		if not raiz.Parent then
			passo = CFG.PASSOS + 1
		else
			raiz.CFrame = raiz.CFrame + direcao * trecho
			local aqui = raiz.Position

			transmitir("ONDA_TEMPORAL", aqui, CFG.ESCALA_RASTRO)

			local alvos = alvosEm(aqui, CFG.RAIO_PASSO, personagem, jogador, humanoide)
			for _, alvo in ipairs(alvos) do
				-- cada alvo leva o avanço uma vez só, mesmo passando por vários passos
				if not jaAtingidos[alvo] then
					jaAtingidos[alvo] = true
					aplicarDano(jogador, alvo, CFG.DANO_AVANCO)
				end
			end

			task.wait(CFG.INTERVALO_PASSO)
			passo = passo + 1
		end
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
	desacelerar(humanoideEquipado)
	cancelarTudo()
	if animador then
		animador:parar()
		animador = nil
	end
end)
