--[[
	PulsoGravitacional_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  DIRETRIZES v2.1 + REGRA 12 V3

	SEM require do Núcleo. A porta é _G.Combate, sempre com guarda (§12.2 / §12.6).
	Este script declara POSE, RITMO e NÚMEROS. Ele nunca escreve regra de combate.

	Renomear ao copiar: PulsoGravitacional → nome real da Tool, em TODO o arquivo.
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

local ARQUETIPO = "MAGO"   -- LUTADOR | ATIRADOR | MAGO | INVOCADOR | HIBRIDO

local CFG = {
	NOME            = "PulsoGravitacional",
	TOOLTIP         = "PulsoGravitacional - descrição breve da ferramenta",

	DANO_BASE       = 24,
	DANO_HABILIDADE = 58,

	ALCANCE_GOLPE   = 14,
	RAIO_AREA       = 28,

	RECARGA_BASE    = 0.75,   -- debounce de Tool.Enabled, habilidade primária
	RECARGA_X       = 16,     -- recarga global da habilidade Extra

	LIMITE_ALVOS    = 12,

	COR_VFX         = Color3.fromRGB(115, 170, 255),
	ESCALA_IMPACTO  = 2.4,

	-- Nome do Sound dentro de Tool/SFX/ — NUNCA um caminho fora da Tool (Regra nº 1).
	-- Volume, pitch e RollOff ficam na própria instância, que é filha da Tool.
	SFX_GOLPE       = "Golpe",

	VIDA_SOM        = 3,      -- s até o som sair de cena
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
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

-- SFX: o Sound é CLONADO de dentro da Tool (Tool/SFX/<nome>). Nenhum caminho externo.
-- Som posicional, sem :Destroy() — Debris tira de cena (§10).
local pastaSFX = tool:FindFirstChild("SFX")

local function tocarSom(nome, posicao)
	if not pastaSFX then
		return -- Tool sem SFX: silenciosa, nunca quebrada
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

	-- Clone do molde interno: volume, pitch e RollOff vêm configurados da instância da Tool
	local som = molde:Clone()
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
		tocarSequencia(sequencia)
	end

	if _G.Combate then
		_G.Combate.transmitirVFX(VFXRemote, "ESFERA_TEMPORAL", {
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
		tocarSequencia(Poses.extra())
	end

	if _G.Combate then
		_G.Combate.transmitirVFX(VFXRemote, "RAIO_TEMPORAL", {
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

	animador = Animator.new(personagem, CFG.NOME, Poses.POSES)

	if humanoide then
		-- Registro sem duração OBRIGA cancelamento em Humanoid.Died e em Tool.Destroying (§12.6)
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
	-- Tool.Enabled NÃO é resetado aqui: resetar transforma desequipar em cancelar recarga (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	cancelarTudo()
	if animador then
		animador:Destroy()
		animador = nil
	end
end)
