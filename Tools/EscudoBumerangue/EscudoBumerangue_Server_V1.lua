--[[
	EscudoBumerangue_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Convertido de `Escudo Bumerangue`, do modelo Danilo_Escudos.

	O QUE MUDOU NA CONVERSÃO
		A origem usava `tick()` alimentando a posição do projétil, `wait()` no
		laço de voo, `math.random` na dispersão do multi-lançamento e `:Emit()`
		no servidor. Aqui: acumulador `dt` a partir de zero, `RunService`,
		leque por ÂNGULO FIXO derivado do índice, e VFX transmitido ao cliente.

		A origem também tinha um sistema de combo que multiplicava o dano até
		2x conforme acertos seguidos. Isso foi mantido, mas o multiplicador
		passa pelo Núcleo como aumento registrado (§12.5) em vez de multiplicar
		o número na mão — assim o teto de +300% do Núcleo continua valendo.

		Números da origem preservados: 18 de dano normal, 80 de velocidade,
		50 de alcance, 3 projéteis no multi com 14 de dano e leque de 15°,
		janela de combo de 3 s e bônus de 10% por acerto.

	PRIMÁRIA (Tool.Activated)  arremessa o escudo; ele vai, para no alcance e
	                           VOLTA para a mão, atingindo na ida e na volta
	EXTRA (X, via AcaoRemote)  três de uma vez, em leque
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:WaitForChild("AcaoRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "ARREMESSADOR"

local CFG = {
	NOME = "EscudoBumerangue",

	-- PRIMÁRIA
	DANO          = 18,
	VELOCIDADE    = 80,
	ALCANCE       = 50,
	RAIO_ACERTO   = 5,
	EMPURRAO      = 15,
	RECARGA_BASE  = 1.0,

	-- EXTRA — três em leque
	TRINCA_QUANTOS   = 3,
	TRINCA_DANO      = 14,
	TRINCA_VELOCIDADE = 90,
	TRINCA_ABERTURA  = 15,   -- graus entre um e outro
	TRINCA_RECARGA   = 3,

	-- COMBO — acertos seguidos aumentam o dano, com teto
	COMBO_JANELA   = 3.0,
	COMBO_BONUS    = 0.10,   -- +10% por acerto acumulado
	COMBO_TETO     = 1.0,    -- +100% no máximo (o dobro, como na origem)

	ESCUDO_TAMANHO = Vector3.new(3.0, 3.0, 0.26),

	COR_VFX     = Color3.fromRGB(0, 122, 190),
	COR_TRINCA  = Color3.fromRGB(96, 205, 255),
	ESCALA_VFX  = 1.0,

	SFX_ARREMESSO = "Arremesso",
	SFX_IMPACTO   = "Impacto",
	SFX_RETORNO   = "Retorno",

	CHAVE_EXTRA = "EscudoBumerangue_X",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local voando = {}
local comboAcertos = 0
local comboAte = 0
local ultimaTrinca = 0

local function tocarSequencia(nome)
	if not animador or not nome then
		return
	end
	animador:PlaySequence(nome)
end

--==============================================================================
-- AUXILIARES
--==============================================================================

local function tocarSom(nome, posicao)
	local original = pastaSFX:FindFirstChild(nome)
	if not original then
		return
	end

	local som = original:Clone()
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.CFrame = CFrame.new(posicao)
	ancora.Parent = workspace

	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora, som.TimeLength + 0.5)
end

local function transmitir(tipo, posicao, escala, cor, frente)
	local payload = {
		posicao = posicao,
		escala = escala or CFG.ESCALA_VFX,
		cor = cor or CFG.COR_VFX,
		frente = frente,
	}
	if _G.Combate and _G.Combate.transmitirVFX then
		_G.Combate.transmitirVFX(VFXRemote, tipo, payload)
		return
	end
	VFXRemote:FireAllClients(tipo, payload)
end

local function humanoidesEmArea(posicao, raio, meuPersonagem)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(posicao, raio, meuPersonagem) or {}
	end

	local achados = {}
	for _, outro in ipairs(Players:GetPlayers()) do
		local personagem = outro.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
		if humanoide and raiz and humanoide.Health > 0 and personagem ~= meuPersonagem then
			if (raiz.Position - posicao).Magnitude <= raio then
				table.insert(achados, humanoide)
			end
		end
	end
	return achados
end

local function podeAtingir(jogador, alvo)
	if _G.Combate and _G.Combate.podeCausarDano then
		return _G.Combate.podeCausarDano(jogador, alvo)
	end
	return true
end

-- O combo vira AUMENTO registrado no Núcleo, não multiplicação na mão. Assim o
-- teto de +300% do §12.5 continua valendo, e o bônus aparece no pipeline.
local function bonusDeCombo(jogador, humanoide)
	local agora = os.clock()
	if agora > comboAte then
		comboAcertos = 0
	end
	if comboAcertos <= 0 then
		return nil
	end

	local aumento = math.min(comboAcertos * CFG.COMBO_BONUS, CFG.COMBO_TETO)
	if _G.Combate and _G.Combate.registrarAumento and humanoide then
		return _G.Combate.registrarAumento(humanoide, aumento, 0.4, "Escudo_Combo")
	end
	return nil
end

local function contarAcerto()
	comboAcertos = comboAcertos + 1
	comboAte = os.clock() + CFG.COMBO_JANELA
end

local function aplicarDano(jogador, alvo, valor)
	if not podeAtingir(jogador, alvo) then
		return false
	end
	if _G.Combate and _G.Combate.registrarAtaque then
		_G.Combate.registrarAtaque(jogador, alvo, valor, ARQUETIPO)
	else
		alvo:TakeDamage(valor)
	end
	return true
end

--==============================================================================
-- O DISCO
--==============================================================================

local function novoDisco(cor)
	local disco = Instance.new("Part")
	disco.Name = "EscudoArremessado"
	disco.Anchored = true
	disco.CanCollide = false
	disco.CanQuery = false
	disco.CanTouch = false
	disco.CastShadow = false
	disco.Material = Enum.Material.Metal
	disco.Color = cor
	disco.Reflectance = 0.4
	disco.Size = CFG.ESCUDO_TAMANHO
	return disco
end

--[[
	Lança um disco. `volta` decide se ele retorna à mão — é o que separa esta
	Tool do Escudo Partido, que usa o mesmo voo sem o retorno.
]]
local function lancar(jogador, personagem, raiz, direcao, dano, velocidade, alcance, cor, volta)
	local origem = raiz.Position + direcao * 2 + Vector3.new(0, 1.2, 0)
	local disco = novoDisco(cor)
	disco.CFrame = CFrame.lookAt(origem, origem + direcao)
	disco.Parent = workspace
	table.insert(voando, disco)

	transmitir("LAMINA", origem, 0.9, cor, direcao)

	local percorrido = 0
	local voltando = false
	local giro = 0
	local jaAtingidos = {}
	local conexao

	conexao = RunService.Heartbeat:Connect(function(dt)
		if not disco.Parent then
			conexao:Disconnect()
			return
		end

		-- Acumulador dt a partir de zero. NUNCA tick(): tick() é tempo de
		-- parede e dá salto quando o servidor engasga.
		local passo = velocidade * dt
		giro = giro + dt * 14

		local alvoPos
		if not voltando then
			percorrido = percorrido + passo
			alvoPos = disco.Position + direcao * passo
			if percorrido >= alcance then
				if volta then
					voltando = true
					table.clear(jaAtingidos)   -- pode acertar de novo na volta
					tocarSom(CFG.SFX_RETORNO, disco.Position)
				else
					conexao:Disconnect()
					transmitir("ESTILHACO_ESCUDO", disco.Position, 1.0, cor)
					disco.Parent = nil
					return
				end
			end
		else
			if not (raiz and raiz.Parent) then
				conexao:Disconnect()
				disco.Parent = nil
				return
			end
			local paraMao = (raiz.Position + Vector3.new(0, 1.2, 0)) - disco.Position
			if paraMao.Magnitude <= 3.0 then
				conexao:Disconnect()
				transmitir("FAISCA", disco.Position, 0.7, cor)
				disco.Parent = nil
				return
			end
			alvoPos = disco.Position + paraMao.Unit * passo
		end

		disco.CFrame = CFrame.lookAt(alvoPos, alvoPos + direcao) * CFrame.Angles(0, 0, giro)

		for _, alvo in ipairs(humanoidesEmArea(alvoPos, CFG.RAIO_ACERTO, personagem)) do
			if not jaAtingidos[alvo] then
				jaAtingidos[alvo] = true
				local cancelar = bonusDeCombo(jogador, alvo)
				if aplicarDano(jogador, alvo, dano) then
					contarAcerto()
				end
				if type(cancelar) == "function" then
					pcall(cancelar)
				end

				local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					tocarSom(CFG.SFX_IMPACTO, alvoRaiz.Position)
					transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.8, cor)
					local empurrao = Instance.new("BodyVelocity")
					empurrao.MaxForce = Vector3.new(1e5, 0, 1e5)
					empurrao.Velocity = direcao * CFG.EMPURRAO
					empurrao.Parent = alvoRaiz
					Debris:AddItem(empurrao, 0.14)
				end
			end
		end
	end)

	Debris:AddItem(disco, (alcance / velocidade) * 2.5 + 1)
end

--==============================================================================
-- PRIMÁRIA E EXTRA
--==============================================================================

local function arremessar(jogador, personagem, raiz)
	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_ARREMESSO, raiz.Position)
	lancar(jogador, personagem, raiz, raiz.CFrame.LookVector,
		CFG.DANO, CFG.VELOCIDADE, CFG.ALCANCE, CFG.COR_VFX, true)
end

local function trinca(jogador, personagem, raiz)
	local agora = os.clock()
	if agora - ultimaTrinca < CFG.TRINCA_RECARGA then
		return
	end
	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_EXTRA, CFG.TRINCA_RECARGA) then
			return
		end
	end
	ultimaTrinca = agora

	tocarSequencia(Poses.extra())
	tocarSom(CFG.SFX_ARREMESSO, raiz.Position)
	transmitir("CLARAO_ESCUDO", raiz.Position + Vector3.new(0, 1.5, 0), 1.1, CFG.COR_TRINCA)

	local frente = raiz.CFrame.LookVector
	-- Leque por ÂNGULO FIXO derivado do índice. A origem usava math.random no
	-- espalhamento, e por isso o mesmo golpe nunca saía igual duas vezes.
	local meio = (CFG.TRINCA_QUANTOS + 1) / 2
	for i = 1, CFG.TRINCA_QUANTOS do
		local desvio = (i - meio) * CFG.TRINCA_ABERTURA
		local direcao = (CFrame.Angles(0, math.rad(desvio), 0) * frente).Unit
		lancar(jogador, personagem, raiz, direcao,
			CFG.TRINCA_DANO, CFG.TRINCA_VELOCIDADE, CFG.ALCANCE, CFG.COR_TRINCA, true)
	end
end

--==============================================================================
-- LIGAÇÃO COM A TOOL
--==============================================================================

local function contexto()
	local personagem = tool.Parent
	local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	local jogador = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then
		return nil
	end
	if humanoide.Health <= 0 then
		return nil
	end
	return jogador, personagem, humanoide, raiz
end

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador then
		return
	end

	tool.Enabled = false
	arremessar(jogador, personagem, raiz)
	task.delay(CFG.RECARGA_BASE, function()
		tool.Enabled = true
	end)
end)

acaoRemote.OnServerEvent:Connect(function(quemPediu)
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador or quemPediu ~= jogador then
		return
	end
	trinca(jogador, personagem, raiz)
end)

local function desmontar()
	for _, disco in ipairs(voando) do
		if disco and disco.Parent then
			disco.Parent = nil
		end
	end
	table.clear(voando)
	comboAcertos = 0

	if animador then
		animador:Destroy()
		animador = nil
	end
end

tool.Equipped:Connect(function()
	local personagem = tool.Parent
	if not personagem then
		return
	end
	animador = Animator.new(personagem, CFG.NOME, Poses.POSES, Poses.SEQUENCIAS)
	if animador then
		animador:PlaySequence(Poses.repouso())
	end

	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then
		humanoide.Died:Connect(desmontar)
	end
end)

tool.Unequipped:Connect(desmontar)
tool.Destroying:Connect(desmontar)
