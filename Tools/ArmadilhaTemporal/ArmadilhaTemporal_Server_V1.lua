--[[
	ArmadilhaTemporal_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Origem: `TemporalTrap` (tecla G) do modelo Guardião do Tempo.
	Planta uma armadilha no chão. Quem entrar no raio leva o gatilho.

	A armadilha vive no mundo (Parent = workspace) — escrever no mundo é saída, não
	dependência (Regra nº 1). Ela some sozinha por tempo, e some junto com a Tool:
	armadilha órfã continuando a dar dano depois da Tool morta é falha grave.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local pastaSFX = tool:FindFirstChild("SFX")
local pastaEfeitos = tool:FindFirstChild("Efeitos")

--==============================================================================
-- ARQUETIPO + CFG
--==============================================================================

local ARQUETIPO = "INVOCADOR"

local CFG = {
	NOME             = "ArmadilhaTemporal",
	TOOLTIP          = "Armadilha Temporal - deixe o tempo esperando por alguém",

	DANO_TOQUE       = 15,      -- ApplyDamage(..., 15) do modelo
	DANO_GATILHO     = 65,      -- ApplyDamage(..., 65) do modelo

	RAIO_GATILHO     = 12,
	RAIO_ESTOURO     = 20,
	DURACAO          = 20,      -- s de espera antes de sumir sozinha
	INTERVALO_VARRE  = 0.25,    -- s entre varreduras: não roda a cada quadro

	ALTURA           = 0.4,
	TAMANHO          = 6,

	MAX_ARMADILHAS   = 2,       -- a mais antiga sai quando a terceira é plantada
	LIMITE_ALVOS     = 10,

	RECARGA          = 3.0,
	RECARGA_GLOBAL   = 5.0,

	COR              = Color3.fromRGB(154, 205, 50),
	ESCALA_PLANTIO   = 1.3,
	ESCALA_ESTOURO   = 2.6,

	SFX_PLANTAR      = "Plantar",
	SFX_DISPARO      = "Disparo",
	SFX_BRASA        = "Brasa",      -- V2
	SFX_FAISCA       = "Faisca",     -- V2
	VIDA_SOM         = 3,
}

--==============================================================================
-- ESTADO
--==============================================================================

local animador = nil

-- O Animator canônico toca UMA pose por chamada (PlayPose). A sequência é
-- encadeada aqui, não dentro dele.
local function tocarSequencia(sequencia)
	if not animador or not sequencia then
		return
	end
	task.spawn(function()
		for _, passo in ipairs(sequencia) do
			if not animador then
				return
			end
			animador:PlayPose(passo.pose, passo.duracao)
			task.wait(passo.duracao)
		end
	end)
end
local cancelamentos = {}
local armadilhas = {}   -- lista de { parte, cancelar }

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

local function recolherArmadilhas()
	for indice = #armadilhas, 1, -1 do
		local registro = armadilhas[indice]
		table.remove(armadilhas, indice)
		local ok, erro = pcall(registro.cancelar)
		if not ok then
			warn("[" .. CFG.NOME .. "] armadilha não pôde ser recolhida: " .. tostring(erro))
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

-- Corpo da armadilha: molde de dentro da Tool, ou procedural (Regra nº 1)
local function corpoDaArmadilha(posicao)
	local corpo = nil
	if pastaEfeitos then
		local original = pastaEfeitos:FindFirstChild("ARMADILHA")
		if original then
			corpo = original:Clone()
		end
	end

	if not corpo then
		corpo = Instance.new("Part")
		corpo.Shape = Enum.PartType.Cylinder
		corpo.Material = Enum.Material.Neon
		corpo.Color = CFG.COR
		corpo.Size = Vector3.new(CFG.ALTURA, CFG.TAMANHO, CFG.TAMANHO)
		corpo.Orientation = Vector3.new(0, 0, 90)
	end

	corpo.Name = CFG.NOME .. "_Armadilha"
	corpo.Anchored = true
	corpo.CanCollide = false
	corpo.CanQuery = false
	corpo.CanTouch = false
	corpo.CastShadow = false
	corpo.Transparency = 0.35
	corpo.CFrame = CFrame.new(posicao)
	return corpo
end

--==============================================================================
-- PLANTIO
--==============================================================================

local function plantar(jogador, personagem, humanoide, posicao)
	local corpo = corpoDaArmadilha(posicao)
	corpo.Parent = workspace

	local disparada = false
	local vivo = true
	local acumulado = 0
	local total = 0
	local conexao = nil

	local function recolher()
		if not vivo then
			return
		end
		vivo = false
		if conexao then
			conexao:Disconnect()
			conexao = nil
		end
		corpo.Parent = nil   -- nunca :Destroy() (§10)
	end

	local function disparar(alvos)
		if disparada then
			return
		end
		disparada = true

		-- SFX → física → VFX → dano (§8 V2)
		tocarSom(CFG.SFX_DISPARO, posicao)
		tocarSom(CFG.SFX_FAISCA, posicao)
		transmitir("ESFERA_TEMPORAL", posicao, CFG.ESCALA_ESTOURO)
		transmitir("FAISCA", posicao, CFG.ESCALA_ESTOURO)
		transmitir("BRASA", posicao, CFG.ESCALA_ESTOURO)
		transmitir("MOSTRADOR_TEMPORAL", posicao, CFG.ESCALA_ESTOURO)
		transmitir("DETRITOS", posicao, CFG.ESCALA_ESTOURO)
		transmitir("TREMOR", posicao, 0.9)

		for _, alvo in ipairs(alvos) do
			aplicarDano(jogador, alvo, CFG.DANO_GATILHO)
		end

		-- o estouro pega além de quem pisou
		local respingo = alvosEm(posicao, CFG.RAIO_ESTOURO, personagem, jogador, humanoide)
		for _, alvo in ipairs(respingo) do
			local jaLevou = false
			for _, direto in ipairs(alvos) do
				if direto == alvo then
					jaLevou = true
				end
			end
			if not jaLevou then
				aplicarDano(jogador, alvo, CFG.DANO_TOQUE)
			end
		end

		recolher()
	end

	-- Acumulador dt: a varredura roda a cada INTERVALO_VARRE, não a cada quadro
	conexao = RunService.Heartbeat:Connect(function(dt)
		if not vivo then
			return
		end

		total = total + dt
		if total >= CFG.DURACAO then
			recolher()
			return
		end

		acumulado = acumulado + dt
		if acumulado >= CFG.INTERVALO_VARRE then
			acumulado = 0

			-- pulso visual enquanto espera
			corpo.Transparency = 0.35 + 0.2 * math.sin(total * 4)

			local pisaram = alvosEm(posicao, CFG.RAIO_GATILHO, personagem, jogador, humanoide)
			if #pisaram > 0 then
				disparar(pisaram)
			end
		end
	end)

	local registro = { parte = corpo, cancelar = recolher }
	table.insert(armadilhas, registro)

	-- Teto de armadilhas: a mais antiga sai quando o teto estoura
	while #armadilhas > CFG.MAX_ARMADILHAS do
		local antiga = table.remove(armadilhas, 1)
		pcall(antiga.cancelar)
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
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_G", CFG.RECARGA_GLOBAL)
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
		tocarSequencia(Poses.primaria())
	end

	local posicao = raiz.Position - Vector3.new(0, 2.5, 0)

	tocarSom(CFG.SFX_PLANTAR, posicao)
	tocarSom(CFG.SFX_BRASA, posicao)
	transmitir("MOSTRADOR_TEMPORAL", posicao, CFG.ESCALA_PLANTIO)
	transmitir("BRASA", posicao, CFG.ESCALA_PLANTIO)

	plantar(jogador, personagem, humanoide, posicao)

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

	animador = Animator.new(personagem, CFG.NOME, Poses.POSES)

	-- AURA no Handle enquanto a Tool está na mão (efeito acrescentado na V2)
	transmitir("AURA", handle.Position, 1.0)

	if humanoide then
		local conexaoMorte
		conexaoMorte = humanoide.Died:Connect(function()
			-- Morreu: as armadilhas dele saem do mundo junto
			recolherArmadilhas()
			cancelarTudo()
			if animador then
				animador:Destroy()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
		guardarCancelamento(recolherArmadilhas)
	end
end)

tool.Unequipped:Connect(function()
	if animador then
		animador:Destroy()
		animador = nil
	end
	-- As armadilhas plantadas CONTINUAM armadas, e a recarga também corre (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	recolherArmadilhas()
	cancelarTudo()
	if animador then
		animador:Destroy()
		animador = nil
	end
end)
