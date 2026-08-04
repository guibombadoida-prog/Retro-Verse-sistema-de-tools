--[[
	Cronostase_Server_V1  —  Server Script, filho direto da Tool
	Retro-Verse / Studios  ·  Regra nº 1 · REGRA 12 V3 · DIRETRIZES v2.1

	Origem: `Chronostasis` (tecla X) do modelo Guardião do Tempo.
	Primeira ativação marca um ponto no tempo. A segunda devolve o corpo a ele,
	com a velocidade que ele tinha no instante da marca.

	Habilidade de mobilidade: não causa dano. Declara DamageClass mesmo assim (§12.4) —
	sem a etiqueta, todo bônus por classe do jogo fica inerte para esta Tool.
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
	NOME            = "Cronostase",
	TOOLTIP         = "Cronostase - marca um ponto no tempo. Ative de novo para voltar a ele",

	DURACAO_MARCA   = 12,      -- s até a marca expirar sozinha
	RECARGA_RETORNO = 1.20,    -- debounce depois de voltar
	RECARGA_MARCA   = 0.45,    -- debounce depois de marcar

	ALTURA_MARCA    = 0.5,     -- studs acima do chão, para não enterrar o retorno

	COR             = Color3.fromRGB(154, 205, 50),
	ESCALA_MARCA    = 1.2,
	ESCALA_RETORNO  = 2.0,

	SFX_MARCA       = "Marca",
	SFX_RETORNO     = "Retorno",
	SFX_ESTELAR     = "Estelar",     -- V2
	VIDA_SOM        = 3,
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

-- A marca temporal: posição, velocidade e o momento em que foi feita
local marca = nil
local expiracao = nil

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

local function limparMarca()
	marca = nil
	expiracao = nil
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

local function marcaValida()
	if not marca or not expiracao then
		return false
	end
	-- os.clock() é monotônico e nunca alimenta CFrame (§12.9)
	if os.clock() >= expiracao then
		limparMarca()
		return false
	end
	return true
end

--==============================================================================
-- HABILIDADE PRIMÁRIA — marcar, depois voltar
--==============================================================================

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end
	tool.Enabled = false

	local _, personagem = donoAtual()
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

	if marcaValida() then
		-- RETORNO: SFX → física → VFX (§8 V2). Não há dano nesta Tool.
		local destino = marca.cframe
		local velocidade = marca.velocidade

		tocarSom(CFG.SFX_RETORNO, raiz.Position)
		transmitir("ESFERA_TEMPORAL", raiz.Position, CFG.ESCALA_RETORNO)

		raiz.CFrame = destino
		raiz.AssemblyLinearVelocity = velocidade

		transmitir("MOSTRADOR_TEMPORAL", destino.Position, CFG.ESCALA_RETORNO)
		transmitir("ESTILHACO_ESTELAR", destino.Position, CFG.ESCALA_RETORNO)
		transmitir("TREMOR", destino.Position, 0.7)

		limparMarca()
		task.wait(CFG.RECARGA_RETORNO)
	else
		-- MARCA
		tocarSom(CFG.SFX_MARCA, handle.Position)

		marca = {
			cframe = raiz.CFrame + Vector3.new(0, CFG.ALTURA_MARCA, 0),
			velocidade = raiz.AssemblyLinearVelocity,
		}
		expiracao = os.clock() + CFG.DURACAO_MARCA

		tocarSom(CFG.SFX_ESTELAR, raiz.Position)
		transmitir("MOSTRADOR_TEMPORAL", raiz.Position, CFG.ESCALA_MARCA)
		transmitir("ESTILHACO_ESTELAR", raiz.Position, CFG.ESCALA_MARCA)

		task.wait(CFG.RECARGA_MARCA)
	end

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
			-- Morreu: a marca morre junto. Voltar a um ponto de outra vida é exploit.
			limparMarca()
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
	-- A marca SOBREVIVE ao desequipar, e a recarga também (§8 / §12.9)
end)

tool.Destroying:Connect(function()
	limparMarca()
	cancelarTudo()
	if animador then
		animador:Destroy()
		animador = nil
	end
end)
