-- PortaldoSubmundo_Server_V1.lua
-- Script de servidor — Portal do Submundo (conjunto COLLECTOR)
--
--   M1   Abre o portal; correntes prendem quem pisar nele.
--
-- CONJUNTO AUTORAL. Não há script de origem para citar: o conceito é do autor
-- do projeto e os números do `CFG` são decisão de balanceamento, não cópia.
--
-- O QUE A REGRA IMPÔS AO CONCEITO
--   corrente nao existe em asset nenhum do Acervo. O elo e a malha
--   de anel 3270017 repetida — a unica peca desenhada do conjunto.
--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py. Editar aqui à mão faz as
-- seis derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local MiraRemote = Tool:WaitForChild("MiraRemote")

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	RECARGA = 38,
	ALCANCE = 75,
	RAIO = 14,
	ESPESSURA = 0.6,
	DURACAO = 10,
	INTERVALO = 0.7,
	DANO_MIN = 7,
	DANO_MAX = 13,
	PRISAO = 0.95,
	PUXAO = 26,
	ELOS = 8,
}

--══════════════════════════════════════════════════════════════
-- ESTADO
--══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoUso = 0
local ultimaMira = nil
local ativos = {}
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 1000000 then semente = 1 end
	return semente
end

--- Faixa determinística, no lugar de `math.random(a, b)`.
local function naFaixa(minimo, maximo)
	local onda = (math.sin(proximo() * 2.399963) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

local function anguloDe(indice)
	return math.rad(137.507764 * indice)
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

--- Beat que SÓ o portador vê. Revelação de inimigo é informação dele, não do
--- servidor inteiro: mandar para todos entregaria a posição a quem está sendo
--- revelado.
local function vfxSo(tipo, dados)
	if jogador then VFXRemote:FireClient(jogador, tipo, dados) end
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

local function soltarTudo()
	for _, conexao in ipairs(ativos) do
		if conexao.Connected then conexao:Disconnect() end
	end
	ativos = {}
end

--══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo decide (§12.5 / §12.6)
--
-- Toda chamada é OPCIONAL: `<fallback>`.
-- A Tool sozinha num place vazio funciona por inteiro.
--══════════════════════════════════════════════════════════════

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

local function golpearArea(posicao, raio, minimo, maximo, forca, limite)
	local atingidos = 0
	for _, alvo in ipairs(alvosEm(posicao, raio, limite or 14)) do
		aplicarDano(alvo, naFaixa(minimo, maximo))
		atingidos = atingidos + 1
		if forca and forca > 0 then
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - posicao)
					+ Vector3.new(0, 0.3, 0), forca, 0.25)
			end
		end
	end
	return atingidos
end

--══════════════════════════════════════════════════════════════
-- ATORDOAMENTO — trava e SEMPRE devolve
--
-- Guardar o valor anterior e devolver não é zelo: WalkSpeed zerado sem
-- restauração é jogador preso para sempre, e a Tool pode sumir no meio do
-- prazo. Por isso a devolução mora em `task.delay` E no cleanup.
--══════════════════════════════════════════════════════════════

local presos = {}

local function atordoar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if presos[alvoHum] then return end
	presos[alvoHum] = { anda = alvoHum.WalkSpeed, pula = alvoHum.JumpPower }
	alvoHum.WalkSpeed = 0
	alvoHum.JumpPower = 0
	task.delay(tempo, function()
		local guardado = presos[alvoHum]
		if not guardado then return end
		presos[alvoHum] = nil
		if alvoHum.Parent then
			alvoHum.WalkSpeed = guardado.anda
			alvoHum.JumpPower = guardado.pula
		end
	end)
end

local function soltarPresos()
	for alvoHum, guardado in pairs(presos) do
		if alvoHum and alvoHum.Parent then
			alvoHum.WalkSpeed = guardado.anda
			alvoHum.JumpPower = guardado.pula
		end
	end
	presos = {}
end

--══════════════════════════════════════════════════════════════
-- MOLDES — o asset vem de DENTRO da Tool (Regra nº 1)
--══════════════════════════════════════════════════════════════

local function molde(nome)
	return Moldes:FindFirstChild(nome, true)
end

--- Clona um molde para o mundo já visível. O molde fica apagado dentro da Tool.
local function porNoMundo(nome, cframe, vida)
	local base = molde(nome)
	if not base then return nil end
	local copia = base:Clone()
	for _, peca in ipairs(copia:GetDescendants()) do
		if peca:IsA("BasePart") then peca.Transparency = 0 end
	end
	if copia:IsA("BasePart") then copia.Transparency = 0 end
	copia.Parent = workspace
	if copia:IsA("BasePart") then
		copia.CFrame = cframe
	elseif copia:IsA("Model") then
		if not copia.PrimaryPart then
			copia.PrimaryPart = copia:FindFirstChildWhichIsA("BasePart")
		end
		if copia.PrimaryPart then copia:PivotTo(cframe) end
	end
	Debris:AddItem(copia, vida or 8)
	return copia
end

--══════════════════════════════════════════════════════════════
-- PORTA DE ENTRADA
--══════════════════════════════════════════════════════════════

local function podeUsar()
	if not (personagem and humanoide and humanoide.Health > 0 and raiz) then
		return false
	end
	return os.clock() - ultimoUso >= CFG.RECARGA
end

--- Mira: o cliente manda para onde aponta; o servidor CORTA pelo alcance.
--- Payload de cliente é entrada, nunca verdade.
local function mirar(pedido)
	if typeof(pedido) ~= "Vector3" then
		return raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE
	end
	local delta = pedido - raiz.Position
	if delta.Magnitude > CFG.ALCANCE then
		return raiz.Position + delta.Unit * CFG.ALCANCE
	end
	return pedido
end

--══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o Portal do Submundo
--
-- Um disco no chão que prende com correntes quem pisar. O portal é hitbox e
-- âncora; as correntes são desenho do cliente.
--
-- O preso é solto de três jeitos, e os três precisam existir: o prazo dele
-- acaba, o portal fecha, ou a Tool sai da mão. Corrente sem chave é jogador
-- travado para sempre.
--══════════════════════════════════════════════════════════════

local portal = nil

local function fecharPortal()
	if portal then
		local onde = portal.Position
		portal.Parent = nil
		portal = nil
		vfx("PORTAL_FECHA", { posicao = onde })
	end
	soltarPresos()
end

local function primaria(destino)
	local centro = mirar(destino)
	fecharPortal()

	portal = Instance.new("Part")
	portal.Name = "PortalDoSubmundo"
	portal.Shape = Enum.PartType.Cylinder
	portal.Size = Vector3.new(CFG.ESPESSURA, CFG.RAIO * 2, CFG.RAIO * 2)
	portal.CFrame = CFrame.new(centro) * CFrame.Angles(0, 0, math.rad(90))
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(28, 20, 34)
	portal.Transparency = 0.25
	portal.Anchored = true
	portal.CanCollide = false
	portal.Parent = workspace
	Debris:AddItem(portal, CFG.DURACAO + 1)

	vfx("PORTAL_ABRE", { posicao = centro, raio = CFG.RAIO,
		duracao = CFG.DURACAO })

	local pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
	local i = 1
	while i <= pulsos do
		local indice = i
		task.delay(indice * CFG.INTERVALO, function()
			if not (portal and portal.Parent and personagem) then return end
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
				aplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
				-- prende por pouco e reaplica: quem sai do disco se solta sozinho
				atordoar(alvo, CFG.PRISAO)
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					vfx("CORRENTE_PRENDE", { alvo = corpo, ancora = centro,
						elos = CFG.ELOS })
					empurrar(alvo, centro - alvoRaiz.Position, CFG.PUXAO, 0.2)
				end
			end
		end)
		i = i + 1
	end

	task.delay(CFG.DURACAO, fecharPortal)
end


--══════════════════════════════════════════════════════════════
-- MIRA — o mouse é do cliente, a conferência é do servidor
--══════════════════════════════════════════════════════════════

MiraRemote.OnServerEvent:Connect(function(quem, ponto)
	if quem ~= jogador then return end
	if typeof(ponto) ~= "Vector3" then return end
	ultimaMira = ponto
end)

--══════════════════════════════════════════════════════════════
-- ANIMAÇÃO — o rig é DO SERVIDOR, e é por isso que ele existe aqui
--
-- `Instance.new("Weld")` criado num LocalScript é instância LOCAL: não replica.
-- Enquanto o rig morou no cliente, os outros jogadores viam o portador
-- executando a habilidade PARADO. Weld criado no servidor replica, e a mudança
-- de `C0` replica junto — então a pose aparece para a sala inteira.
--
-- O beat volta para os clientes por VFXRemote: quem desenha o brilho na mão
-- continua sendo cada cliente, a 60 Hz.
--══════════════════════════════════════════════════════════════

local function montarRig()
	if rig then return rig end
	if not personagem then return nil end
	rig = Animator.new(personagem, "PortaldoSubmundo", Poses, Poses.SEQUENCIAS)
	return rig
end

local function animar()
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence("ABRIR", function(passo)
		if passo.marca then vfx("BEAT", { marca = passo.marca }) end
	end)
end

local function desmontarRig()
	if not rig then return end
	rig:CancelSequence()
	rig:ReleaseLegs()
end

--══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--══════════════════════════════════════════════════════════════

local function limpar()
	soltarTudo()
	soltarPresos()
	fecharPortal()
end

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	jogador = Players:GetPlayerFromCharacter(personagem)
	humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
end)

Tool.Unequipped:Connect(function()
	ultimaMira = nil
	limpar()
end)

Tool.Activated:Connect(function()
	if not podeUsar() then return end
	ultimoUso = os.clock()
	primaria(mirar(ultimaMira))
end)

--- `Destroying`, não `AncestryChanged`: guardar na mochila troca o pai sem
--- destruir nada, e o cleanup não pode disparar aí.
Tool.Destroying:Connect(function()
	limpar()
	if rig then
		rig:Destroy()
		rig = nil
	end
end)
