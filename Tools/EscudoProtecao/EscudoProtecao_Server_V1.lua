--[[
	EscudoProtecao_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Convertido de `Proteção`, do modelo Danilo_Escudos.

	O QUE MUDOU NA CONVERSÃO
		A origem varria `workspace:GetDescendants()` procurando qualquer Part
		com velocidade alta para chamar de "projétil". Isso é ler o mundo
		inteiro todo frame — caro, e pega qualquer coisa que esteja caindo.
		Aqui a varredura é por `GetPartBoundsInRadius` no raio do escudo, e só
		considera Part NÃO ancorada, sem Humanoid no modelo pai, e acima da
		velocidade mínima. É a mesma ideia, sem varrer o place.

		A origem também usava `tick()` para a fase da órbita. Aqui é acumulador
		`dt` a partir de zero.

		Números da origem preservados: 4 s de duração, raio de órbita 4,
		velocidade 8, raio de reflexão 8, força 100, 5 de dano ao devolver.

	PRIMÁRIA (Tool.Activated)  o escudo sai da mão e orbita o portador por 4 s,
	                           rebatendo projétil de volta em quem atirou
	Sem Extra — a órbita já é a habilidade, e ela é passiva por natureza.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "GUARDIAO"

local CFG = {
	NOME = "EscudoProtecao",

	DURACAO       = 4.0,
	RECARGA       = 7,

	ORBITA_RAIO   = 4.0,
	ORBITA_VOLTAS = 1.27,   -- 8 rad/s da origem, em voltas por segundo
	ORBITA_ALTURA = 1.0,
	ESCUDO_TAMANHO = Vector3.new(2.6, 2.6, 0.24),

	REFLEXO_RAIO      = 8,
	REFLEXO_FORCA     = 100,
	REFLEXO_DANO      = 5,
	REFLEXO_INTERVALO = 0.12,
	-- Abaixo disso não é projétil, é entulho caindo.
	PROJETIL_VELOCIDADE_MINIMA = 24,
	PROJETIL_MASSA_MAXIMA = 20,

	COR_VFX     = Color3.fromRGB(0, 122, 190),
	COR_REBATE  = Color3.fromRGB(255, 100, 0),
	ESCALA_VFX  = 1.0,

	SFX_ORBITA = "Orbita",
	SFX_REBATE = "Rebate",

	LIMITE_ALVOS = 24,
	LIMITE_PARTES = 80,

	CHAVE_PRIMARIA = "EscudoProtecao_Primaria",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local orbita = nil
local jaRebatidos = {}

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

--[[
	Projéteis no raio do escudo.

	A origem varria workspace:GetDescendants() inteiro. Aqui é consulta espacial
	no raio, e o filtro é explícito: Part solta, leve, rápida, e que não faça
	parte de um personagem. Sem isso, o escudo rebateria o próprio jogador
	quando ele pulasse perto.
]]
local function projeteisPerto(posicao, personagem)
	local parametros = OverlapParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	parametros.FilterDescendantsInstances = { personagem }
	parametros.MaxParts = 24

	local achados = {}
	local ok, partes = pcall(function()
		return workspace:GetPartBoundsInRadius(posicao, CFG.REFLEXO_RAIO, parametros)
	end)
	if not ok or not partes then
		return achados
	end

	for _, parte in ipairs(partes) do
		if not parte.Anchored and parte:IsA("BasePart") then
			local modelo = parte:FindFirstAncestorOfClass("Model")
			local ehPersonagem = modelo and modelo:FindFirstChildOfClass("Humanoid") ~= nil
			if not ehPersonagem then
				local velocidade = parte.AssemblyLinearVelocity.Magnitude
				if velocidade >= CFG.PROJETIL_VELOCIDADE_MINIMA
					and parte:GetMass() <= CFG.PROJETIL_MASSA_MAXIMA then
					table.insert(achados, parte)
				end
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

-- `calcular` roda o pipeline do §12.5 e REGISTRA a queda como prevista. Quem
-- tira a vida é a Tool, com TakeDamage. `registrarAtaque` só grava atribuição
-- de abate (§12.8) — chamá-la no lugar de calcular resultava em dano ZERO.
local function aplicarDano(jogador, alvo, valor)
	if not podeAtingir(jogador, alvo) then
		return false
	end
	local final = valor
	if _G.Combate and _G.Combate.calcular then
		final = _G.Combate.calcular(jogador, alvo, valor) or valor
	end
	if final > 0 then
		alvo:TakeDamage(final)
	end
	return true
end

--==============================================================================
-- PRIMÁRIA — soltar o escudo em órbita
--==============================================================================

local function pararOrbita()
	if not orbita then
		return
	end
	if orbita.conexao then
		orbita.conexao:Disconnect()
		orbita.conexao = nil
	end
	if orbita.parte then
		orbita.parte.Parent = nil
	end
	orbita = nil
	table.clear(jaRebatidos)
end

local function soltar(jogador, personagem, humanoide, raiz)
	pararOrbita()

	local escudo = Instance.new("Part")
	escudo.Name = "EscudoOrbitando"
	escudo.Anchored = true
	escudo.CanCollide = false
	escudo.CanQuery = false
	escudo.CanTouch = false
	escudo.CastShadow = false
	escudo.Material = Enum.Material.Metal
	escudo.Color = CFG.COR_VFX
	escudo.Reflectance = 0.4
	escudo.Transparency = 0.08
	escudo.Size = CFG.ESCUDO_TAMANHO
	escudo.Parent = workspace

	orbita = { parte = escudo }

	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_ORBITA, raiz.Position)
	transmitir("CLARAO_ESCUDO", raiz.Position + Vector3.new(0, 2, 0), 1.0)
	transmitir("AURA", raiz.Position + Vector3.new(0, 1.5, 0), 1.2)

	local t = 0
	local desdeVarredura = 0

	orbita.conexao = RunService.Heartbeat:Connect(function(dt)
		if not orbita then
			return
		end
		if not (raiz and raiz.Parent and humanoide and humanoide.Health > 0) then
			pararOrbita()
			return
		end

		t = t + dt
		if t >= CFG.DURACAO then
			transmitir("FAISCA", escudo.Position, 0.8)
			pararOrbita()
			return
		end

		local centro = raiz.Position + Vector3.new(0, CFG.ORBITA_ALTURA, 0)
		local angulo = t * CFG.ORBITA_VOLTAS * math.pi * 2
		local pos = centro + Vector3.new(
			math.cos(angulo) * CFG.ORBITA_RAIO,
			0,
			math.sin(angulo) * CFG.ORBITA_RAIO
		)
		escudo.CFrame = CFrame.lookAt(pos, pos + (pos - centro).Unit)

		desdeVarredura = desdeVarredura + dt
		if desdeVarredura < CFG.REFLEXO_INTERVALO then
			return
		end
		desdeVarredura = 0

		for _, projetil in ipairs(projeteisPerto(escudo.Position, personagem)) do
			if not jaRebatidos[projetil] then
				jaRebatidos[projetil] = true

				-- Devolve na direção de onde veio, com a força da origem.
				local devolta = -projetil.AssemblyLinearVelocity
				if devolta.Magnitude > 0.001 then
					projetil.AssemblyLinearVelocity = devolta.Unit * CFG.REFLEXO_FORCA
				end

				tocarSom(CFG.SFX_REBATE, projetil.Position)
				transmitir("IMPACTO_ESCUDO", projetil.Position, 0.7, CFG.COR_REBATE)
				transmitir("FAISCA", projetil.Position, 0.6, CFG.COR_REBATE)

				-- Quem atirou leva o troco, se o Núcleo souber dizer quem foi.
				local marca = projetil:FindFirstChild("creator")
				local dono = marca and marca.Value
				local alvoHum = dono and dono.Character
					and dono.Character:FindFirstChildOfClass("Humanoid")
				if alvoHum then
					aplicarDano(jogador, alvoHum, CFG.REFLEXO_DANO)
				end
			end
		end
	end)
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

	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_PRIMARIA, CFG.RECARGA) then
			return
		end
	end

	tool.Enabled = false
	soltar(jogador, personagem, humanoide, raiz)
	task.delay(CFG.RECARGA, function()
		tool.Enabled = true
	end)
end)

local function desmontar()
	pararOrbita()
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
