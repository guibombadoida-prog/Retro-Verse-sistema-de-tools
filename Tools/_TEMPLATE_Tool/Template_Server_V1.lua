--[[
	[NomeDaTool]_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  DIRETRIZES v2.1 + REGRA 12 V3

	SEM require do Núcleo. A porta é _G.Combate, sempre com guarda (§12.2 / §12.6).
	Este script declara POSE, RITMO e NÚMEROS. Ele nunca escreve regra de combate.

	Renomear ao copiar: Template → nome real da Tool, em TODO o arquivo.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")

--==============================================================================
-- ARQUETIPO + CFG — bloco único no topo (§10.11 / §12.10)
--==============================================================================

local ARQUETIPO = "HIBRIDO"   -- LUTADOR | ATIRADOR | MAGO | INVOCADOR | HIBRIDO

local CFG = {
	NOME            = "Template",
	TOOLTIP         = "Template - descrição breve da ferramenta",

	DANO_BASE       = 28,
	DANO_HABILIDADE = 65,

	ALCANCE_GOLPE   = 9,
	RAIO_AREA       = 24,

	RECARGA_BASE    = 0.75,   -- debounce de Tool.Enabled, habilidade primária
	RECARGA_X       = 18,     -- recarga global da habilidade Extra

	LIMITE_ALVOS    = 12,

	COR_VFX         = Color3.fromRGB(140, 90, 255),
	ESCALA_IMPACTO  = 2.4,

	SFX_GOLPE       = "rbxassetid://0",   -- preencher a partir do Acervo · SFX/ids.md
	SFX_VOLUME      = 0.6,
	SFX_PITCH       = 1.0,
	SFX_ALCANCE     = 60,

	VIDA_SOM        = 3,      -- s até o som sair de cena
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local cancelamentos = {}   -- toda função de cancelamento devolvida pelo Núcleo (§12.6)
local contadorGolpe = 0    -- substitui math.random: variação por índice sequencial

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
-- CONFIGURAÇÃO BASE OBRIGATÓRIA (§2 / §3 / §7)
--==============================================================================

tool.CanBeDropped = false
tool.RequiresHandle = true
tool.ToolTip = CFG.TOOLTIP
tool.Enabled = true

--==============================================================================
-- AUXILIARES
--==============================================================================

local function personagemAtual()
	local personagem = tool.Parent
	if personagem and personagem:FindFirstChildOfClass("Humanoid") then
		return personagem
	end
	return nil
end

local function donoAtual()
	local personagem = personagemAtual()
	if not personagem then
		return nil, nil, nil
	end
	return Players:GetPlayerFromCharacter(personagem), personagem, personagem:FindFirstChildOfClass("Humanoid")
end

-- SFX: som posicional, sem :Destroy() — Debris tira de cena (§10)
local function tocarSom(id, posicao)
	if id == "rbxassetid://0" or id == "" then
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

	local som = Instance.new("Sound")
	som.SoundId = id
	som.Volume = CFG.SFX_VOLUME
	som.PlaybackSpeed = CFG.SFX_PITCH
	som.RollOffMaxDistance = CFG.SFX_ALCANCE
	som.Parent = ancora

	ancora.Parent = workspace
	som:Play()
	Debris:AddItem(ancora, CFG.VIDA_SOM)
end

-- Dano no MODO PRECISO (§12.6): uma linha, com guarda, sem require
local function aplicarDano(jogador, humanoideAlvo, danoBruto)
	local final = _G.Combate and _G.Combate.calcular(jogador, humanoideAlvo, danoBruto) or danoBruto
	humanoideAlvo:TakeDamage(final)
	return final
end

local function alvosEmArea(posicao, raio, personagem, jogador, humanoideDono)
	if _G.Combate then
		return _G.Combate.detectarHumanoides(posicao, raio, personagem, jogador, humanoideDono, CFG.LIMITE_ALVOS)
	end
	return {}
end

--==============================================================================
-- HABILIDADE PRIMÁRIA — Tool.Activated (§9: nunca por botão)
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

	contadorGolpe = contadorGolpe + 1
	local sequencia = Poses.golpe(contadorGolpe)

	-- Ordem de impacto §8 V2: SFX → física → VFX → dano
	tocarSom(CFG.SFX_GOLPE, handle.Position)

	if animador then
		animador:tocar(sequencia)
	end

	if _G.Combate then
		_G.Combate.transmitirVFX(VFXRemote, "IMPACTO", {
			posicao = handle.Position,
			escala = CFG.ESCALA_IMPACTO,
			cor = CFG.COR_VFX,
		})
	end

	local alvos = alvosEmArea(handle.Position, CFG.ALCANCE_GOLPE, personagem, jogador, humanoide)
	for _, alvo in ipairs(alvos) do
		aplicarDano(jogador, alvo, CFG.DANO_BASE)
	end

	task.wait(CFG.RECARGA_BASE)
	tool.Enabled = true
end)

--==============================================================================
-- HABILIDADE EXTRA — chamada pelo Client via ContextActionService
-- Recarga GLOBAL, por jogador + chave: imune a clone na mochila (§12.9)
--==============================================================================

local function habilidadeExtra()
	local jogador, personagem, humanoide = donoAtual()
	if not personagem or not jogador then
		return
	end

	if _G.Combate then
		local liberado = _G.Combate.recargaGlobal(jogador, CFG.NOME .. "_X", CFG.RECARGA_X)
		if not liberado then
			return
		end
	end

	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end

	tocarSom(CFG.SFX_GOLPE, raiz.Position)

	if animador then
		animador:tocar(Poses.extra())
	end

	if _G.Combate then
		_G.Combate.transmitirVFX(VFXRemote, "IMPACTO_NOVA", {
			posicao = raiz.Position,
			escala = CFG.ESCALA_IMPACTO * 2,
			cor = CFG.COR_VFX,
		})
	end

	local alvos = alvosEmArea(raiz.Position, CFG.RAIO_AREA, personagem, jogador, humanoide)
	for _, alvo in ipairs(alvos) do
		aplicarDano(jogador, alvo, CFG.DANO_HABILIDADE)
	end
end

-- Único OnServerEvent tolerado: pedido de INPUT do dono. VFXRemote é unidirecional (§12.14).
local acaoRemote = tool:FindFirstChild("AcaoRemote")
if acaoRemote and acaoRemote:IsA("RemoteEvent") then
	acaoRemote.OnServerEvent:Connect(function(jogadorQuePediu)
		local jogador = donoAtual()
		if jogador and jogadorQuePediu == jogador then
			habilidadeExtra()
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

	if humanoide then
		-- Registro sem duração OBRIGA cancelamento em Humanoid.Died e em Tool.Destroying (§12.6)
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
	-- Tool.Enabled NÃO é resetado aqui: resetar transforma desequipar em cancelar recarga (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	cancelarTudo()
	if animador then
		animador:parar()
		animador = nil
	end
end)
