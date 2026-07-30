--[[
	CanhaoCronos_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Origem: `ChronosCannon` (tecla V) do modelo Guardião do Tempo.
	Carrega, depois dispara um feixe reto que atravessa e castiga o que estiver na linha.

	⚠️ O modelo chamava `ApplyDamage(HUM, 600000)` — morte garantida, furando ForceField.
	Aqui o dano é um número de balanceamento no CFG, aplicado por TakeDamage com o
	dano calculado pelo Núcleo (§12.6 / §12.7).
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

local ARQUETIPO = "ATIRADOR"

local CFG = {
	NOME             = "CanhaoCronos",
	TOOLTIP          = "Canhão Cronos - concentra o tempo numa linha e solta",

	DANO             = 120,
	ALCANCE          = 220,
	SEGMENTOS        = 22,      -- o feixe é varrido em segmentos, para atingir tudo na linha
	RAIO_SEGMENTO    = 9,
	INTERVALO_FEIXE  = 0.015,

	CARGA            = 0.55,    -- s de carga antes do disparo
	RECARGA          = 6.0,     -- debounce local
	RECARGA_GLOBAL   = 9.0,     -- imune a clone na mochila (§12.9)

	LIMITE_ALVOS     = 20,

	COR              = Color3.fromRGB(154, 205, 50),
	ESCALA_CARGA     = 1.5,
	ESCALA_FEIXE     = 1.1,
	ESCALA_ESTOURO   = 2.8,

	SFX_CARGA        = "Carga",
	SFX_DISPARO      = "Disparo",
	VIDA_SOM         = 4,
}

--==============================================================================
-- ESTADO
--==============================================================================

local animador = nil
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

	-- Recarga global ANTES de gastar o debounce local: três cópias na mochila
	-- não podem render três disparos (§12.9)
	if _G.Combate then
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_V", CFG.RECARGA_GLOBAL)
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

	-- CARGA
	tocarSom(CFG.SFX_CARGA, handle.Position)
	transmitir("ESFERA_TEMPORAL", handle.Position, CFG.ESCALA_CARGA)
	transmitir("MOSTRADOR_TEMPORAL", raiz.Position, CFG.ESCALA_CARGA)
	task.wait(CFG.CARGA)

	-- DISPARO — SFX → física → VFX → dano (§8 V2)
	tocarSom(CFG.SFX_DISPARO, handle.Position)
	transmitir("TREMOR", raiz.Position, 1.4)

	local origem = handle.Position
	local direcao = raiz.CFrame.LookVector
	local trecho = CFG.ALCANCE / CFG.SEGMENTOS
	local jaAtingidos = {}

	local segmento = 1
	while segmento <= CFG.SEGMENTOS do
		local ponto = origem + direcao * (trecho * segmento)

		transmitir("ONDA_TEMPORAL", ponto, CFG.ESCALA_FEIXE)

		local alvos = alvosEm(ponto, CFG.RAIO_SEGMENTO, personagem, jogador, humanoide)
		for _, alvo in ipairs(alvos) do
			-- o feixe atravessa, mas cada alvo é atingido uma vez só
			if not jaAtingidos[alvo] then
				jaAtingidos[alvo] = true
				aplicarDano(jogador, alvo, CFG.DANO)
				transmitir("ESFERA_TEMPORAL", ponto, CFG.ESCALA_ESTOURO)
				transmitir("DETRITOS", ponto, CFG.ESCALA_FEIXE)
			end
		end

		task.wait(CFG.INTERVALO_FEIXE)
		segmento = segmento + 1
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

	animador = Animator.novo(personagem)

	if humanoide then
		local conexaoMorte
		conexaoMorte = humanoide.Died:Connect(function()
			cancelarTudo()
			if animador then
				animador:parar()
			end
		end)
		guardarCancelamento(function()
			conexaoMorte:Disconnect()
		end)
	end
end)

tool.Unequipped:Connect(function()
	if animador then
		animador:restaurar()
		animador = nil
	end
	-- Tool.Enabled NÃO é resetado aqui (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	cancelarTudo()
	if animador then
		animador:parar()
		animador = nil
	end
end)
