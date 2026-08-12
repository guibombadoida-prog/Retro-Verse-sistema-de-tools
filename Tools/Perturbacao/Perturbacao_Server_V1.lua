-- Perturbacao_Server_V1.lua
-- Script de servidor — Perturbacao (conjunto COLLECTOR)
--
--   M1   Fica incorporeo 6s, absorve o dano e devolve em area.
--
-- CONJUNTO AUTORAL. Não há script de origem para citar: o conceito é do autor
-- do projeto e os números do `CFG` são decisão de balanceamento, não cópia.
--
-- O QUE A REGRA IMPÔS AO CONCEITO
--   a absorcao tem TETO. Sem ele, dois jogadores batendo por 6 s
--   viram um golpe de area impossivel de sobreviver.
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

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	RECARGA = 30,
	ALCANCE = 40,
	DURACAO = 6,
	TETO = 220,
	CONVERSAO = 0.75,
	RAIO = 24,
	EMPURRAO = 70,
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
-- PRIMÁRIA — a Perturbação
--
-- Seis segundos incorpóreo: o dano que chegaria é ABSORVIDO em vez de sofrido,
-- e no fim volta como golpe em área. Quanto mais te bateram, maior o troco.
--
-- Como a absorção funciona, e por que ela tem teto:
--   `HealthChanged` avisa DEPOIS que a vida caiu. O servidor devolve a vida e
--   guarda o quanto caiu. Sem teto, dois jogadores batendo juntos por 6 s
--   viram um golpe de área impossível de sobreviver — `CFG.TETO` corta isso.
--
-- E a devolução é obrigatória: se a Tool sair da mão no meio, o estado tem de
-- desligar, senão fica um jogador imortal em campo.
--══════════════════════════════════════════════════════════════

local desfeito = false
local absorvido = 0
local laçoVida = nil

local function refazer(devolver)
	if not desfeito then return end
	desfeito = false
	if laçoVida and laçoVida.Connected then laçoVida:Disconnect() end
	laçoVida = nil

	local troco = math.min(absorvido, CFG.TETO)
	absorvido = 0
	vfx("PERTURBA_VOLTA", {})

	if not devolver then return end
	if not (personagem and raiz and humanoide and humanoide.Health > 0) then return end
	if troco <= 0 then return end

	vfx("PERTURBA_DEVOLVE", { posicao = raiz.Position, escala = troco / CFG.TETO })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO, 14)) do
		aplicarDano(alvo, troco * CFG.CONVERSAO)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.EMPURRAO, 0.3)
		end
	end
end

local function primaria()
	if desfeito then return end
	desfeito = true
	absorvido = 0

	local vidaAntes = humanoide.Health
	vfx("PERTURBA_DESFAZ", { duracao = CFG.DURACAO })

	laçoVida = humanoide.HealthChanged:Connect(function(agora)
		if not desfeito then return end
		if agora >= vidaAntes then
			vidaAntes = agora
			return
		end
		local perdido = vidaAntes - agora
		absorvido = absorvido + perdido
		-- devolve a vida: o golpe foi absorvido, não sofrido
		humanoide.Health = math.min(vidaAntes, humanoide.MaxHealth)
		vfx("PERTURBA_ABSORVE", { posicao = raiz and raiz.Position or nil })
	end)
	guardar(laçoVida)

	task.delay(CFG.DURACAO, function()
		refazer(true)
	end)
end


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
	rig = Animator.new(personagem, "Perturbacao", Poses, Poses.SEQUENCIAS)
	return rig
end

local function animar()
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence("DESFAZER", function(passo)
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
	refazer(false)
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
	primaria()
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
