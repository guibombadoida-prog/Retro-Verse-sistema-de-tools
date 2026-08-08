-- PilardasLamentacoes_Server_V1.lua
-- Script de servidor — Pilar das Lamentacoes (conjunto SUBMUNDO)
--
--   M1   Ergue o pilar no ponto mirado; grita por 8s.
--
-- CONJUNTO AUTORAL. Não há script de origem para citar: o conceito é do autor
-- do projeto e os números do `CFG` são decisão de balanceamento, não cópia.
--
-- O QUE A REGRA IMPÔS AO CONCEITO
--   nada — o conceito coube inteiro
--
-- Gerado por FERRAMENTAS/gerar_servers_submundo.py. Editar aqui à mão faz as
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
	RECARGA = 26,
	ALCANCE = 70,
	ALTURA = 40,
	GROSSURA = 6,
	DURACAO = 8,
	INTERVALO = 0.8,
	RAIO = 26,
	DANO_MIN = 9,
	DANO_MAX = 16,
	ATORDOAMENTO = 1.1,
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
-- Toda chamada é OPCIONAL: `_G.Combate and _G.Combate.x(...) or <fallback>`.
-- A Tool sozinha num place vazio funciona por inteiro.
--══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	if _G.Combate and _G.Combate.registrarAtaque then
		_G.Combate.registrarAtaque(jogador, Tool, ARQUETIPO)
	else
		local marca = alvoHum:FindFirstChild("creator")
		if marca then marca.Parent = nil end
		marca = Instance.new("ObjectValue")
		marca.Name = "creator"
		marca.Value = jogador
		marca.Parent = alvoHum
		Debris:AddItem(marca, 3)
	end
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local final = (_G.Combate and _G.Combate.calcular
		and _G.Combate.calcular(jogador, alvoHum, bruto)) or bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

local function alvosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(
			posicao, raio, personagem, jogador, humanoide, limite or 14) or {}
	end

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
-- PRIMÁRIA — o Pilar das Lamentações
--
-- O pilar é uma Part ANCORADA que nasce e não se move mais: quem cresce e
-- gira é a cópia do cliente. Servidor que empurra geometria por quadro replica
-- a ~20 Hz picotado — o pilar aqui só existe como hitbox e âncora do som.
--══════════════════════════════════════════════════════════════

local pilar = nil

local function derrubarPilar()
	if pilar then
		pilar.Parent = nil
		pilar = nil
	end
end

local function primaria(destino)
	local centro = mirar(destino)
	derrubarPilar()

	pilar = Instance.new("Part")
	pilar.Name = "PilarDasLamentacoes"
	pilar.Shape = Enum.PartType.Cylinder
	pilar.Size = Vector3.new(CFG.ALTURA, CFG.GROSSURA, CFG.GROSSURA)
	pilar.CFrame = CFrame.new(centro + Vector3.new(0, CFG.ALTURA / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	pilar.Material = Enum.Material.Slate
	pilar.Color = Color3.fromRGB(24, 22, 30)
	pilar.Anchored = true
	pilar.CanCollide = false
	pilar.Parent = workspace
	Debris:AddItem(pilar, CFG.DURACAO + 1)

	vfx("PILAR_ERGUE", { posicao = centro, altura = CFG.ALTURA,
		grossura = CFG.GROSSURA, duracao = CFG.DURACAO })

	-- o grito: um pulso por vez, com o atordoamento junto
	local pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
	local i = 1
	while i <= pulsos do
		local indice = i
		task.delay(indice * CFG.INTERVALO, function()
			if not (pilar and pilar.Parent and personagem) then return end
			vfx("PILAR_GRITO", { posicao = centro, passo = indice })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 12)) do
				aplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
				-- o atordoamento é curto e reaplicado a cada grito: assim ele
				-- solta sozinho se o alvo sair do alcance, sem prender ninguém
				atordoar(alvo, CFG.ATORDOAMENTO)
			end
		end)
		i = i + 1
	end

	task.delay(CFG.DURACAO, function()
		vfx("PILAR_CAI", { posicao = centro })
		derrubarPilar()
	end)
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
	rig = Animator.new(personagem, "PilardasLamentacoes", Poses, Poses.SEQUENCIAS)
	return rig
end

local function animar()
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence("ERGUER", function(passo)
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
	derrubarPilar()
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
