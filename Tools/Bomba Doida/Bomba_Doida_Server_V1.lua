-- Bomba_Doida_Server_V1.lua
-- Script de servidor — Bomba Doida
--
-- CLONE do bomba_v4: mesmo Handle, mesmo mesh, mesmos sons.
-- Habilidade única, em `Tool.Activated`. Sem Extra, sem AcaoRemote.
--
--   M1  solta 2 bombas-NPC kamikaze que ficam mais rápidas sem alvo
--
-- CONVERSÃO (§12.12.2) — o que veio do original foram os NÚMEROS:
--   dano 20 · raio 20 · 3 mini a 20% em raio 15 · delay 1 s · CD 1 s ·
--   explode ao tocar Humanoid OU por prazo.
--
-- O que NÃO veio, e por quê:
--   `require(8199013483)`  id numérico é execução de código remoto
--   `IsAlly` próprio       regra de combate tem uma porta só: o Núcleo
--   `workspace:GetDescendants()` por explosão — varria o jogo inteiro
--   `tick()` alimentando geometria, e a expansão animada NO SERVIDOR
--                          (replica a ~20 Hz; a expansão agora é Tween no cliente)
--   `math.random` na dispersão — virou ângulo áureo
--   `:Destroy()` e `AncestryChanged` — viraram `Parent = nil` e `Destroying`
--
-- Gerado por FERRAMENTAS/gerar_servers_bombas.py. Editar aqui à mão faz as
-- seis derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	EMPURRAO      = 50,
	ALCANCE_MAX   = 150,
	FORCA_MIN     = 45,
	ARCO          = 18,
	VIDA_BOMBA    = 6,
	PRAZO         = 1,

	RECARGA       = 30,
	QUANTAS       = 2,
	VIDA_NPC      = 20,     -- some sozinha depois disso
	VIDA_CORPO    = 60,

	DANO          = 55,
	RAIO          = 22,
	ESCALA        = 1.8,

	PROCURA       = 120,    -- alcance de busca por alvo
	PASSO_BUSCA   = 0.4,    -- de quanto em quanto tempo reavalia
	TOQUE         = 4.5,    -- distância que conta como "encostou"

	VEL_CALMA     = 14,
	VEL_BRAVA     = 42,
	SUBIDA_RAIVA  = 0.09,   -- por segundo SEM alvo
	ALIVIO_RAIVA  = 0.25,   -- por segundo COM alvo
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoUso = 0
local ativos = {}
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar do math.random da dispersão:
--- mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

--- Toca um som do Handle numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Era o bug que emudecia a explosão das seis: `tocar("Explode", bomba)`
--- punha o Sound dentro da bomba, e a linha seguinte tirava a bomba do mundo.
--- O som morria no quadro em que nascia. Um `Sound` só toca enquanto tem pai
--- no DataModel, então ele precisa de um pai que sobreviva a ele.
local function tocarEm(nome, posicao, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = ancora
	som:Play()

	local vida = corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1)
	Debris:AddItem(ancora, vida)
	return som
end

--- Versão presa a uma peça — só para peça que NÃO vai sumir (o Handle).
local function tocar(nome, onde, pitch, corte)
	local alvo = onde or Handle
	if alvo ~= Handle then
		-- qualquer peça que não seja o Handle pode sumir no meio do som
		return tocarEm(nome, alvo.Position, pitch, corte)
	end
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	local marca = alvoHum:FindFirstChild("creator")
	if marca then marca.Parent = nil end
	marca = Instance.new("ObjectValue")
	marca.Name = "creator"
	marca.Value = jogador
	marca.Parent = alvoHum
	Debris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local final = bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--- Alvos num raio. O original varria `workspace:GetDescendants()` INTEIRO a
--- cada explosão; aqui é consulta espacial, e o filtro de time é do Núcleo.
local function alvosEm(posicao, raio, limite)

	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not vistos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Estouro: dano em raio + empurrão + o beat de VFX para o cliente desenhar.
local function estourar(posicao, raio, dano, escala, tipo)
	vfx(tipo or "EXPLOSAO", { posicao = posicao, escala = escala or 1 })
	for _, alvo in ipairs(alvosEm(posicao, raio, 14)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - posicao) + Vector3.new(0, 0.3, 0),
				CFG.EMPURRAO, 0.2)
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- ARREMESSO — a bomba é Part NÃO ancorada, movida por FÍSICA
--
-- Física replica com interpolação; parte ancorada movida por script de
-- servidor replica a ~20 Hz picotado. É por isso que a bomba voa por
-- BodyVelocity e não por CFrame no Heartbeat.
--═══════════════════════════════════════════════════════════════

local function novaBomba(posicao, tamanho)
	local bomba = Handle:Clone()
	bomba.Name = "Bomba"
	bomba.Transparency = 0
	bomba.CanCollide = true
	bomba.Anchored = false
	bomba.Massless = false
	bomba.Size = Handle.Size * (tamanho or 1)
	bomba.CFrame = CFrame.new(posicao)
	for _, filho in ipairs(bomba:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	bomba.Parent = workspace
	pcall(function() bomba:SetNetworkOwner(nil) end)
	Debris:AddItem(bomba, CFG.VIDA_BOMBA)
	return bomba
end

local function rastroDe(bomba)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = bomba
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = bomba
	local rastro = Instance.new("Trail")
	rastro.Attachment0, rastro.Attachment1 = a0, a1
	rastro.FaceCamera = true
	rastro.Lifetime = 0.25
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.WidthScale = NumberSequence.new(1, 0)
	rastro.Parent = bomba
end

--- Some com a bomba sem `:Destroy()`: transparente, sem colisão, e o Debris
--- recolhe. Destruir na hora deixa o som do estouro sem pai.
local function sumir(bomba)
	if not bomba or not bomba.Parent then return end
	bomba.Transparency = 1
	bomba.CanCollide = false
	bomba.CanTouch = false
	Debris:AddItem(bomba, 0.15)
end

--- Arremessa a bomba na direção da mira e chama `aoEstourar(posicao)` quando
--- ela tocar um Humanoid ou o prazo vencer — o que vier primeiro.
local function arremessar(mira, aoEstourar, prazo)
	local origem = Handle.Position
	local bomba = novaBomba(origem, 1)
	bomba.CFrame = CFrame.new(origem, mira)
	rastroDe(bomba)

	local dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = bomba.CFrame.LookVector * math.max(dist, CFG.FORCA_MIN)
		+ Vector3.new(0, CFG.ARCO, 0)
	impulso.Parent = bomba
	Debris:AddItem(impulso, 0.1)

	local estourou = false
	local function detonar()
		if estourou or not bomba.Parent then return end
		estourou = true
		local onde = bomba.Position
		tocar("Explode", bomba, 1)
		sumir(bomba)
		aoEstourar(onde)
	end

	guardar(bomba.Touched:Connect(function(atingido)
		if estourou then return end
		local corpo = atingido and atingido.Parent
		if not corpo or corpo == personagem then return end
		local hum = corpo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then detonar() end
	end))

	task.delay(prazo or CFG.PRAZO, detonar)
	return bomba
end

--- Esconde o Handle enquanto a bomba está no ar e devolve com o "crescer" do
--- original. `Size` guardado uma vez — reler depois pegaria o valor animado.
local TAMANHO_HANDLE = Handle.Size

local function piscarHandle(tempo)
	Handle.Transparency = 1
	Handle.Size = Vector3.new(0.05, 0.05, 0.05)
	game:GetService("TweenService"):Create(Handle,
		TweenInfo.new(tempo or 1), { Size = TAMANHO_HANDLE }):Play()
	task.delay(tempo or 1, function()
		if Handle.Parent then Handle.Transparency = 0 end
	end)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE
--═══════════════════════════════════════════════════════════════

--- A bomba-NPC é montada AQUI, com primitivas — nada de modelo guardado fora
--- da Tool (Regra nº 1). R6 mínimo: HumanoidRootPart, Torso, Head e o
--- Humanoid, com os Motor6D que o Humanoid precisa para andar.
---
--- NOTA DE ESCOPO: isto é uma HABILIDADE de Tool, não um sistema de NPC. A
--- bomba nasce no uso, persegue, estoura e some; não há spawner, não há
--- respawn, não há nada dela fora da Tool.
local function montarBombaNPC(posicao, cor)
	local corpo = Instance.new("Model")
	corpo.Name = "BombaDoida"

	local function pedaco(nome, tamanho, offset)
		local p = Instance.new("Part")
		p.Name = nome
		p.Size = tamanho
		p.CFrame = CFrame.new(posicao + offset)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Color = cor
		p.Material = Enum.Material.Metal
		p.Parent = corpo
		return p
	end

	local raizNPC = pedaco("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
	raizNPC.Transparency = 1
	raizNPC.CanCollide = false

	local torso = pedaco("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
	local cabeca = pedaco("Head", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 4.6, 0))
	cabeca.Shape = Enum.PartType.Ball
	cabeca.Material = Enum.Material.Neon

	-- as juntas que o Humanoid usa para andar
	local function junta(nome, p0, p1, c0, c1)
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1, m.C0, m.C1 = nome, p0, p1, c0, c1
		m.Parent = p0
		return m
	end
	junta("RootJoint", raizNPC, torso, CFrame.new(), CFrame.new())
	junta("Neck", torso, cabeca, CFrame.new(0, 1.6, 0), CFrame.new())

	local humNPC = Instance.new("Humanoid")
	humNPC.MaxHealth = CFG.VIDA_CORPO
	humNPC.Health = CFG.VIDA_CORPO
	humNPC.WalkSpeed = CFG.VEL_CALMA
	humNPC.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humNPC.Parent = corpo

	corpo.PrimaryPart = raizNPC
	corpo.Parent = workspace
	return corpo, humNPC, raizNPC
end

--- Alvo mais próximo. Reusa `alvosEm`, que já passa pelo filtro de time do
--- Núcleo — a bomba não persegue aliado.
local function alvoMaisProximo(de)
	local melhor, menor = nil, math.huge
	for _, alvo in ipairs(alvosEm(de, CFG.PROCURA, 16)) do
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			local d = (alvoRaiz.Position - de).Magnitude
			if d < menor then melhor, menor = alvoRaiz, d end
		end
	end
	return melhor, menor
end

local vivas = {}

local function soltarUma(indice, mira)
	local ang = indice * 2.39996
	local saida = (raiz and raiz.Position or mira)
		+ Vector3.new(math.cos(ang) * 4, 1, math.sin(ang) * 4)

	local corpo, humNPC, raizNPC = montarBombaNPC(saida,
		Color3.fromRGB(60, 55, 50))
	table.insert(vivas, corpo)
	Debris:AddItem(corpo, CFG.VIDA_NPC)

	local raiva = 0
	local estourou = false
	local proximaBusca = 0
	local alvo = nil

	local function detonar()
		if estourou or not corpo.Parent then return end
		estourou = true
		local onde = raizNPC.Position
		tocar("Explode", raizNPC, 1.1)
		corpo.Parent = nil
		estourar(onde, CFG.RAIO, CFG.DANO, CFG.ESCALA)
	end

	local laco
	laco = guardar(RunService.Heartbeat:Connect(function(dt)
		if estourou or not corpo.Parent or humNPC.Health <= 0 then
			if laco then laco:Disconnect() end
			if humNPC.Health <= 0 then detonar() end
			return
		end

		local agora = os.clock()
		if agora >= proximaBusca then
			proximaBusca = agora + CFG.PASSO_BUSCA
			local achado = alvoMaisProximo(raizNPC.Position)
			alvo = achado
			if alvo then
				humNPC:MoveTo(alvo.Position)
			else
				-- sem alvo: anda em círculo à espera, e vai ficando brava
				humNPC:MoveTo(raizNPC.Position
					+ Vector3.new(math.cos(agora) * 8, 0, math.sin(agora) * 8))
			end
		end

		-- QUANTO MAIS TEMPO SEM ALVO, MAIS BRAVA E MAIS RÁPIDA
		if alvo then
			raiva = math.max(0, raiva - CFG.ALIVIO_RAIVA * dt)
		else
			raiva = math.min(1, raiva + CFG.SUBIDA_RAIVA * dt)
		end
		humNPC.WalkSpeed = CFG.VEL_CALMA
			+ (CFG.VEL_BRAVA - CFG.VEL_CALMA) * raiva

		-- a cabeça acende conforme a raiva sobe
		local cabeca = corpo:FindFirstChild("Head")
		if cabeca then
			cabeca.Color = Color3.fromRGB(255, 151, 0):Lerp(
				Color3.fromRGB(255, 40, 30), raiva)
		end
		if agora >= proximaBusca - CFG.PASSO_BUSCA * 0.5 then
			vfx("RAIVA", { posicao = raizNPC.Position, nivel = raiva, escala = 1 })
		end

		-- KAMIKAZE: encostou, estourou
		if alvo and (alvo.Position - raizNPC.Position).Magnitude <= CFG.TOQUE then
			detonar()
		end
	end))

	-- se o prazo vencer sem achar ninguém, estoura onde estiver
	task.delay(CFG.VIDA_NPC - 0.1, detonar)
end

function primaria(mira)
	tocar("Throw", Handle, 0.85)
	if rig then rig:PlaySequence("SOLTAR") end
	piscarHandle(1)

	local i = 0
	while i < CFG.QUANTAS do
		soltarUma(i, mira)
		i = i + 1
	end
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

--- Recarga por TIMESTAMP, como no original: sobrevive a desequipar/equipar, e
--- por isso não dá para zerar a recarga guardando e sacando a Tool.
VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not personagem then return end
	if typeof(mira) ~= "Vector3" then
		mira = raiz and (raiz.Position + raiz.CFrame.LookVector * 20) or Vector3.new()
	end
	if not humanoide or humanoide.Health <= 0 then return end

	local agora = os.clock()
	if agora - ultimoUso < CFG.RECARGA then return end
	ultimoUso = agora

	primaria(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "BombaDoida", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	for _, corpo in ipairs(vivas) do
		if corpo and corpo.Parent then corpo.Parent = nil end
	end
	table.clear(vivas)
	if Handle.Parent then
		Handle.Transparency = 0
		Handle.Size = TAMANHO_HANDLE
	end
	if rig then
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)

--═══════════════════════════════════════════════════════════════
-- REGRA Nº 2 — o VFX sai da Tool quando ela chega ao jogador
--
-- Uma linha. O `DepositoVFX` liga o ciclo inteiro sozinho: instala na troca de
-- pai (mochila OU mão), desinstala no `Tool.Destroying`, e conta as referências
-- para não arrancar o molde debaixo de quem ainda está com a Tool.
--
-- Ver DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
