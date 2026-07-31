--[[
	TemperoTemporal_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Origem: `TemporalTemper` (tecla Z) do modelo Guardião do Tempo.
	O golpe recolhe quem está em volta e, no fim da sequência, arremessa.

	SEM require do Núcleo. A porta é _G.Combate, sempre com guarda (§12.2 / §12.6).
	Regra nº 1: SFX vem de Tool/SFX, poses e módulos são filhos da Tool.
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
-- ARQUETIPO + CFG (§10.11 / §12.10)
--==============================================================================

local ARQUETIPO = "LUTADOR"

local CFG = {
	NOME            = "TemperoTemporal",
	TOOLTIP         = "Tempero Temporal - recolhe o tempo em volta e devolve tudo de uma vez",

	DANO            = 30,      -- era MRANDOM(25, 35) no modelo: fixado na média
	RAIO_RECOLHE    = 35,      -- ApplyAoE(HITPOS, 35, 0, 0, -15, false)
	RAIO_ARREMESSO  = 15,      -- ApplyAoE(HITPOS, 15, 25, 35, 125, false)
	PUXAO           = 15,      -- fling negativo do modelo: puxa para o centro
	ARREMESSO       = 125,

	PULSOS          = 3,       -- o modelo repete a onda 3 vezes (for i = 1, 3)
	INTERVALO_PULSO = 0.16,

	RECARGA         = 1.10,
	LIMITE_ALVOS    = 12,

	COR             = Color3.fromRGB(154, 205, 50),
	ESCALA_ONDA     = 1.4,
	ESCALA_IMPACTO  = 2.2,

	SFX_GOLPE       = "Golpe",
	SFX_ONDA        = "Onda",
	SFX_ESTILHACO   = "Estilhaco",   -- V2
	SFX_FAISCA      = "Faisca",      -- V2
	VIDA_SOM        = 3,
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
-- CONFIGURAÇÃO BASE (§2 / §3 / §7)
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

-- SFX clonado de dentro da Tool (Regra nº 1). Sem :Destroy() — Debris tira de cena.
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

-- Modo preciso (§12.6): uma linha, com guarda, sem require
local function aplicarDano(jogador, alvo, dano)
	local final = _G.Combate and _G.Combate.calcular(jogador, alvo, dano) or dano
	alvo:TakeDamage(final)
	return final
end

-- Empurra pela física, sem BodyMover órfão (§12.12.2)
local function empurrar(humanoideAlvo, origem, forca)
	local personagemAlvo = humanoideAlvo.Parent
	if not personagemAlvo then
		return
	end
	local raiz = personagemAlvo:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end

	local direcao = raiz.Position - origem
	if direcao.Magnitude < 0.1 then
		return
	end
	raiz.AssemblyLinearVelocity = direcao.Unit * forca + Vector3.new(0, forca * 0.25, 0)
end

--==============================================================================
-- HABILIDADE PRIMÁRIA — Tool.Activated (§9)
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
		tocarSequencia(Poses.primaria())
	end

	-- Ordem de impacto §8 V2: SFX → física → VFX → dano
	tocarSom(CFG.SFX_GOLPE, handle.Position)

	local centro = raiz.Position

	-- Fase 1: recolher. Três pulsos, como no modelo. Puxa, não machuca.
	local pulso = 1
	while pulso <= CFG.PULSOS do
		local presos = alvosEm(centro, CFG.RAIO_RECOLHE, personagem, jogador, humanoide)
		for _, alvo in ipairs(presos) do
			empurrar(alvo, centro, -CFG.PUXAO)
		end

		tocarSom(CFG.SFX_ONDA, centro)
		transmitir("ONDA_TEMPORAL", centro, CFG.ESCALA_ONDA + pulso * 0.35)
		transmitir("FAISCA", centro, CFG.ESCALA_ONDA)

		task.wait(CFG.INTERVALO_PULSO)
		pulso = pulso + 1
	end

	-- Fase 2: devolver tudo de uma vez
	tocarSom(CFG.SFX_GOLPE, centro)

	local atingidos = alvosEm(centro, CFG.RAIO_ARREMESSO, personagem, jogador, humanoide)
	for _, alvo in ipairs(atingidos) do
		empurrar(alvo, centro, CFG.ARREMESSO)
	end

	tocarSom(CFG.SFX_ESTILHACO, centro)
	tocarSom(CFG.SFX_FAISCA, centro)
	transmitir("ESFERA_TEMPORAL", centro, CFG.ESCALA_IMPACTO)
	transmitir("DETRITOS", centro, CFG.ESCALA_IMPACTO)
	transmitir("ESTILHACO_ESTELAR", centro, CFG.ESCALA_IMPACTO)
	transmitir("FAISCA", centro, CFG.ESCALA_IMPACTO)
	transmitir("TREMOR", centro, 1.0)

	for _, alvo in ipairs(atingidos) do
		aplicarDano(jogador, alvo, CFG.DANO)
	end

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
			cancelarTudo()
			if animador then
				animador:Destroy()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
	end
end)

tool.Unequipped:Connect(function()
	if animador then
		animador:Destroy()
		animador = nil
	end
	-- Tool.Enabled NÃO é resetado aqui: resetar vira cancelamento de recarga (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	cancelarTudo()
	if animador then
		animador:Destroy()
		animador = nil
	end
end)
