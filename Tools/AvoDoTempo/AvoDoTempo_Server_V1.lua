--[[
	AvoDoTempo_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Primária: `GrandfatherTime` (tecla Q) — a ultimate do conjunto. A maior sequência do
	          modelo: 525 linhas, 11 camadas de som, badalada e mostrador.
	Extra:    `Taunt` (tecla T) — provocação. Só pose e voz, zero dano.

	Agrupamento (REGRA DE DISTRIBUIÇÃO): a provocação é a fala do Guardião — mora com a
	ultimate, que é onde ele fala.

	Enquanto a ultimate corre, o dono ganha redução de dano. Isso é registro no Núcleo,
	e o cancelamento é guardado e chamado em todo caminho de saída (§12.6).
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
	NOME              = "AvoDoTempo",
	TOOLTIP           = "Avô do Tempo - a hora chega para todos. T provoca",

	DANO_BADALADA     = 55,
	BADALADAS         = 12,     -- as 12 horas
	INTERVALO_BADALADA = 0.22,
	RAIO              = 46,
	LIMITE_ALVOS      = 24,

	REDUCAO_DONO      = 0.45,   -- enquanto a ultimate corre
	ARREMESSO_FINAL   = 90,

	RECARGA           = 20.0,
	RECARGA_GLOBAL    = 45.0,

	RECARGA_PROVOCACAO = 4.0,

	COR               = Color3.fromRGB(154, 205, 50),
	ESCALA_ABERTURA   = 3.4,
	ESCALA_BADALADA   = 1.8,
	ESCALA_FINAL      = 4.2,

	SFX_BADALADA      = "Badalada",
	SFX_VOZ           = "Voz",
	SFX_PROVOCACAO    = "Provocacao",
	SFX_SUPERNOVA     = "Supernova",  -- V2
	SFX_RAIO          = "Raio",       -- V2
	SFX_ESTOURO       = "Estouro",    -- V2
	VIDA_SOM          = 6,
}

--==============================================================================
-- ESTADO
--==============================================================================

local animador = nil

-- O V2 encadeia a sequência sozinho, por Tween.Completed. Passar o NOME da
-- sequência é o contrato; encadear com task.wait aqui somaria ~1 frame por beat.
local function tocarSequencia(nome)
	if not animador or not nome then
		return
	end
	animador:PlaySequence(nome)
end
local cancelamentos = {}
local cancelarReducao = nil
local proximaProvocacao = 0

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

-- Registro sem duração OBRIGA cancelamento explícito: senão vira redução permanente (§12.6)
local function tirarReducao()
	if cancelarReducao then
		local cancelar = cancelarReducao
		cancelarReducao = nil
		local ok, erro = pcall(cancelar)
		if not ok then
			warn("[" .. CFG.NOME .. "] redução não pôde ser retirada: " .. tostring(erro))
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

local function empurrar(humanoideAlvo, origem, forca)
	local corpoAlvo = humanoideAlvo.Parent
	if not corpoAlvo then
		return
	end
	local raiz = corpoAlvo:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end

	local direcao = raiz.Position - origem
	if direcao.Magnitude < 0.1 then
		return
	end
	raiz.AssemblyLinearVelocity = direcao.Unit * forca + Vector3.new(0, forca * 0.45, 0)
end

--==============================================================================
-- HABILIDADE PRIMÁRIA — a ultimate
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
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_Q", CFG.RECARGA_GLOBAL)
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

	-- Redução enquanto a ultimate corre. Guardar o cancelamento é obrigatório.
	tirarReducao()
	if _G.Combate then
		cancelarReducao = _G.Combate.registrarReducao(personagem, CFG.REDUCAO_DONO)
	end

	local centro = raiz.Position

	-- ABERTURA — SFX → física → VFX → dano (§8 V2)
	tocarSom(CFG.SFX_VOZ, centro)
	tocarSom(CFG.SFX_SUPERNOVA, centro)
	transmitir("MOSTRADOR_TEMPORAL", centro, CFG.ESCALA_ABERTURA)
	transmitir("ESFERA_TEMPORAL", centro, CFG.ESCALA_ABERTURA)
	transmitir("RAIO_TEMPORAL", centro, CFG.ESCALA_ABERTURA)
	transmitir("ESTILHACO_ESTELAR", centro, CFG.ESCALA_ABERTURA)
	transmitir("TREMOR", centro, 1.6)

	-- AS DOZE BADALADAS
	local hora = 1
	while hora <= CFG.BADALADAS do
		if not raiz.Parent then
			hora = CFG.BADALADAS + 1
		else
			local aqui = raiz.Position

			tocarSom(CFG.SFX_BADALADA, aqui)
			transmitir("ONDA_TEMPORAL", aqui, CFG.ESCALA_BADALADA + hora * 0.16)
			-- as horas alternam entre raio e estrela, para as 12 não ficarem iguais
			if hora % 2 == 0 then
				transmitir("RAIO_TEMPORAL", aqui, CFG.ESCALA_BADALADA)
			else
				transmitir("ESTILHACO_ESTELAR", aqui, CFG.ESCALA_BADALADA)
			end

			local atingidos = alvosEm(aqui, CFG.RAIO, personagem, jogador, humanoide)
			for _, alvo in ipairs(atingidos) do
				aplicarDano(jogador, alvo, CFG.DANO_BADALADA)
			end

			task.wait(CFG.INTERVALO_BADALADA)
			hora = hora + 1
		end
	end

	-- FECHAMENTO
	local fim = raiz.Parent and raiz.Position or centro

	tocarSom(CFG.SFX_BADALADA, fim)
	tocarSom(CFG.SFX_ESTOURO, fim)
	tocarSom(CFG.SFX_RAIO, fim)
	transmitir("ESFERA_TEMPORAL", fim, CFG.ESCALA_FINAL)
	transmitir("RAIO_TEMPORAL", fim, CFG.ESCALA_FINAL)
	transmitir("ESTILHACO_ESTELAR", fim, CFG.ESCALA_FINAL)
	transmitir("BRASA", fim, CFG.ESCALA_FINAL)
	transmitir("FAISCA", fim, CFG.ESCALA_FINAL)
	transmitir("MOSTRADOR_TEMPORAL", fim, CFG.ESCALA_FINAL)
	transmitir("DETRITOS", fim, CFG.ESCALA_FINAL)
	transmitir("TREMOR", fim, 2.0)

	local ultimos = alvosEm(fim, CFG.RAIO, personagem, jogador, humanoide)
	for _, alvo in ipairs(ultimos) do
		empurrar(alvo, fim, CFG.ARREMESSO_FINAL)
	end
	for _, alvo in ipairs(ultimos) do
		aplicarDano(jogador, alvo, CFG.DANO_BADALADA)
	end

	tirarReducao()

	task.wait(CFG.RECARGA)
	tool.Enabled = true
end)

--==============================================================================
-- EXTRA — Provocação (tecla T no Client). Zero dano.
--==============================================================================

local function provocar()
	local _, personagem = donoAtual()
	if not personagem then
		return
	end

	-- Debounce próprio: a Extra não usa Tool.Enabled, que é da primária (§8)
	local agora = os.clock()
	if agora < proximaProvocacao then
		return
	end
	proximaProvocacao = agora + CFG.RECARGA_PROVOCACAO

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	local ponto = raiz and raiz.Position or handle.Position

	if animador then
		tocarSequencia(Poses.extra())
	end

	tocarSom(CFG.SFX_PROVOCACAO, ponto)
	transmitir("MOSTRADOR_TEMPORAL", ponto, 1.0)
	transmitir("ESTILHACO_ESTELAR", ponto, 1.0)
end

local acaoRemote = tool:FindFirstChild("AcaoRemote")
if acaoRemote and acaoRemote:IsA("RemoteEvent") then
	acaoRemote.OnServerEvent:Connect(function(jogadorQuePediu)
		local jogador = donoAtual()
		if jogador and jogadorQuePediu == jogador then
			provocar()
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

	animador = Animator.new(personagem, CFG.NOME, Poses.POSES)

	-- AURA no Handle enquanto a Tool está na mão (efeito acrescentado na V2)
	transmitir("AURA", handle.Position, 1.0)

	if humanoide then
		local conexaoMorte
		conexaoMorte = humanoide.Died:Connect(function()
			tirarReducao()
			cancelarTudo()
			if animador then
				animador:Destroy()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
		guardarCancelamento(tirarReducao)
	end
end)

tool.Unequipped:Connect(function()
	if animador then
		animador:Destroy()
		animador = nil
	end
	-- Tool.Enabled NÃO é resetado aqui (§8 / §12.9).
	-- A redução também não é retirada: ela pertence à ultimate em curso, não ao equipar.
end)

tool.Destroying:Connect(function()
	tirarReducao()
	cancelarTudo()
	if animador then
		animador:Destroy()
		animador = nil
	end
end)
