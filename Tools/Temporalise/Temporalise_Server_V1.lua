--[[
	Temporalise_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Origem: `Temporalysis` (tecla B) do modelo Guardião do Tempo.
	Para o tempo em área: quem for pego não anda nem pula até o tempo voltar.

	O modelo ancorava as `BasePart` da vítima e pendurava um `BodyPosition` chamado
	"TimeStopPosition" em cada uma. Ancorar o personagem alheio quebra a física dele e
	sobrevive à morte da Tool. Aqui a parada é feita no `Humanoid` — WalkSpeed e JumpPower
	a zero — e TODA parada tem cancelamento guardado, chamado em Died e Destroying (§12.6).

	Habilidade de controle: não causa dano. `DamageClass = "Debuff"` (§12.4).
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

local ARQUETIPO = "MAGO"

local CFG = {
	NOME             = "Temporalise",
	TOOLTIP          = "Temporálise - o tempo para para todo mundo, menos para você",

	RAIO             = 34,
	DURACAO_PARADA   = 7.0,     -- wait(7) do modelo
	LIMITE_ALVOS     = 16,

	RECARGA          = 8.0,
	RECARGA_GLOBAL   = 22.0,

	COR              = Color3.fromRGB(154, 205, 50),
	ESCALA_PARADA    = 3.0,
	ESCALA_MARCA     = 1.1,
	ESCALA_RETOMADA  = 2.0,

	SFX_PARADA       = "Parada",
	SFX_RETOMADA     = "Retomada",
	SFX_ESTELAR      = "Estelar",    -- V2
	SFX_BRASA        = "Brasa",      -- V2
	VIDA_SOM         = 4,
}

--==============================================================================
-- ESTADO
--==============================================================================

local animador = nil
local cancelamentos = {}

-- Toda parada em curso. Registro órfão aqui é jogador congelado para sempre.
local paradasAtivas = {}

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

local function soltarTodos()
	for indice = #paradasAtivas, 1, -1 do
		local soltar = paradasAtivas[indice]
		table.remove(paradasAtivas, indice)
		local ok, erro = pcall(soltar)
		if not ok then
			warn("[" .. CFG.NOME .. "] parada não pôde ser desfeita: " .. tostring(erro))
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

-- Para um Humanoid e DEVOLVE a função que o solta. Nunca solta sozinho.
local function pararHumanoide(alvo)
	if not alvo or not alvo.Parent then
		return function() end
	end

	local andarAntes = alvo.WalkSpeed
	local puloAntes = alvo.JumpPower
	local soltou = false

	alvo.WalkSpeed = 0
	alvo.JumpPower = 0

	local function soltar()
		if soltou then
			return
		end
		soltou = true
		if alvo.Parent then
			alvo.WalkSpeed = andarAntes
			alvo.JumpPower = puloAntes
		end
	end

	-- Se a vítima morrer congelada, o registro sai da lista na mesma hora
	local conexao
	conexao = alvo.Died:Connect(function()
		soltou = true
		conexao:Disconnect()
	end)

	return function()
		conexao:Disconnect()
		soltar()
	end
end

--==============================================================================
-- HABILIDADE PRIMÁRIA
--==============================================================================

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end

	local jogador, personagem, humanoide = donoAtual()
	if not personagem or not jogador then
		return
	end

	if _G.Combate then
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_B", CFG.RECARGA_GLOBAL)
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

	local centro = raiz.Position

	-- SFX → física → VFX (§8 V2). Esta Tool não causa dano.
	tocarSom(CFG.SFX_PARADA, centro)

	local pegos = alvosEm(centro, CFG.RAIO, personagem, jogador, humanoide)
	for _, alvo in ipairs(pegos) do
		local soltar = pararHumanoide(alvo)
		table.insert(paradasAtivas, soltar)

		local corpoAlvo = alvo.Parent
		local raizAlvo = corpoAlvo and corpoAlvo:FindFirstChild("HumanoidRootPart")
		if raizAlvo then
			transmitir("MOSTRADOR_TEMPORAL", raizAlvo.Position, CFG.ESCALA_MARCA)
			transmitir("ESTILHACO_ESTELAR", raizAlvo.Position, CFG.ESCALA_MARCA)
		end
	end

	tocarSom(CFG.SFX_ESTELAR, centro)
	transmitir("ESFERA_TEMPORAL", centro, CFG.ESCALA_PARADA)
	transmitir("MOSTRADOR_TEMPORAL", centro, CFG.ESCALA_PARADA)
	transmitir("ESTILHACO_ESTELAR", centro, CFG.ESCALA_PARADA)
	transmitir("TREMOR", centro, 1.0)

	task.wait(CFG.DURACAO_PARADA)

	-- O tempo volta
	tocarSom(CFG.SFX_RETOMADA, centro)
	tocarSom(CFG.SFX_BRASA, centro)
	transmitir("ONDA_TEMPORAL", centro, CFG.ESCALA_RETOMADA)
	transmitir("BRASA", centro, CFG.ESCALA_RETOMADA)
	soltarTodos()

	task.wait(CFG.RECARGA)
	tool.Enabled = true
end)

--==============================================================================
-- CICLO DE VIDA
--==============================================================================

tool.Equipped:Connect(function()
	local _, personagem, humanoide = donoAtual()
	if not personagem then
		return
	end

	animador = Animator.novo(personagem)

	-- AURA no Handle enquanto a Tool está na mão (efeito acrescentado na V2)
	transmitir("AURA", handle.Position, 1.0)

	if humanoide then
		local conexaoMorte
		conexaoMorte = humanoide.Died:Connect(function()
			-- Morreu no meio da parada: ninguém fica congelado por causa disso
			soltarTodos()
			cancelarTudo()
			if animador then
				animador:parar()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
		guardarCancelamento(soltarTodos)
	end
end)

tool.Unequipped:Connect(function()
	if animador then
		animador:restaurar()
		animador = nil
	end
	-- A parada em curso NÃO é interrompida por desequipar, e a recarga também não (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	soltarTodos()
	cancelarTudo()
	if animador then
		animador:parar()
		animador = nil
	end
end)
