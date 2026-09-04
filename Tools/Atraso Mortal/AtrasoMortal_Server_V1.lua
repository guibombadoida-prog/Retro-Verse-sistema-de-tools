-- AtrasoMortal_Server_V1.lua
-- Script de servidor — Atraso Mortal (conjunto COLLECTOR)
--
--   M1   Solta a caveira que persegue devagar e bombardeia.
--
-- CONJUNTO AUTORAL. Não há script de origem para citar: o conceito é do autor
-- do projeto e os números do `CFG` são decisão de balanceamento, não cópia.
--
-- O QUE A REGRA IMPÔS AO CONCEITO
--   a caveira voa por `AlignPosition`, nao por CFrame de servidor:
--   fisica replica interpolada, CFrame ancorado replica picotado.
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
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
local MiraRemote = Tool:WaitForChild("MiraRemote")

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	RECARGA = 34,
	ALCANCE = 80,
	LIMITE = 2,
	VIDA = 22,
	VOO = 7,
	PASSO = 0.3,
	AVANCO = 5,
	VISAO = 70,
	CADA_QUANTOS = 6,
	FORCA_VOO = 24000,
	AGILIDADE = 12,
	VELOCIDADE_BOMBA = 58,
	ARCO = 16,
	VIDA_BOMBA = 2.4,
	RAIO_BOMBA = 16,
	DANO_MIN = 16,
	DANO_MAX = 26,
	EMPURRAO = 48,
}

--══════════════════════════════════════════════════════════════
-- ESTADO
--══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA, e o repositório inteiro dependia
--    dele: eram 217 pontos que conferiam só o TIPO.
--
--    `Vector3.new(0/0, 0/0, 0/0)` é um `Vector3` legítimo para o `typeof`.
--    Um cliente modificado manda isso, `.Unit` devolve NaN, e força NaN
--    aplicada a uma peça envenena a assembly dela — o alvo trava, voa para
--    coordenada absurda, ou o solver do motor engasga. Nenhum `pcall` pega,
--    porque não há erro: a conta simplesmente não tem resultado.
--
--    `n ~= n` é o único teste de NaN que funciona em Lua: NaN é o único valor
--    que não é igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda
--    na mesma linha.
--
-- E RATE LIMIT É DO SERVIDOR, não do cliente.
--
--    O `Client` já limita a 20 Hz, e isso não vale nada: quem manda o pacote
--    é o cliente, e cliente modificado manda a 2 000 Hz. O limite que conta
--    é o daqui.
--═══════════════════════════════════════════════════════════════

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
---
--- O corte por alcance não é só anticheat: mira a 5 000 studs faria o
--- `noChao()` varrer 400 studs de raycast a partir de um ponto onde não há
--- mapa, e a habilidade nasceria no vazio.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > CFG.MIRA_MAX then
		return raiz.Position + delta.Unit * CFG.MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem está abusando é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= CFG.PEDIDOS_POR_SEG
end
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
-- PRIMÁRIA — o Atraso Mortal
--
-- Uma caveira lenta que persegue e bombardeia. "Atraso" é o nome certo: ela
-- não alcança ninguém correndo — ela cobra o espaço com as bombas.
--
-- A caveira voa por `AlignPosition`, não por CFrame de servidor. Física
-- replica interpolada; CFrame ancorado empurrado por script replica picotado.
--══════════════════════════════════════════════════════════════

local caveiras = {}

local function dispensarCaveiras()
	for _, peca in ipairs(caveiras) do
		if peca and peca.Parent then peca.Parent = nil end
	end
	caveiras = {}
end

local function largarBomba(origem, alvoPos)
	local base = molde("Bomba")
	if not base then return end
	local bomba = base:Clone()
	bomba.Transparency = 0
	bomba.Anchored = false
	bomba.CanCollide = false
	bomba.Massless = true
	bomba.CFrame = CFrame.new(origem)
	bomba.Parent = workspace
	Debris:AddItem(bomba, CFG.VIDA_BOMBA + 1)

	local delta = alvoPos - origem
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = delta.Unit * CFG.VELOCIDADE_BOMBA
		+ Vector3.new(0, CFG.ARCO, 0)
	impulso.Parent = bomba
	Debris:AddItem(impulso, 0.35)

	vfx("BOMBA_SAI", { origem = origem })

	-- estoura ao tocar Humanoid OU por prazo, o que vier primeiro
	local gasta = false
	local function estourar()
		if gasta then return end
		gasta = true
		local onde = bomba.Position
		bomba.Parent = nil
		vfx("BOMBA_ESTOURA", { posicao = onde })
		golpearArea(onde, CFG.RAIO_BOMBA, CFG.DANO_MIN, CFG.DANO_MAX,
			CFG.EMPURRAO, 8)
	end

	local ligacao
	ligacao = bomba.Touched:Connect(function(parte)
		local modelo = parte:FindFirstAncestorOfClass("Model")
		if not modelo or modelo == personagem then return end
		if not modelo:FindFirstChildOfClass("Humanoid") then return end
		if ligacao.Connected then ligacao:Disconnect() end
		estourar()
	end)
	guardar(ligacao)
	task.delay(CFG.VIDA_BOMBA, estourar)
end

local function primaria(destino)
	if #caveiras >= CFG.LIMITE then return end
	local ponto = mirar(destino)

	local caveira = porNoMundo("skully",
		CFrame.new(ponto + Vector3.new(0, CFG.VOO, 0)), CFG.VIDA)
	if not caveira then return end
	caveira.Name = "CaveiraDoAtraso"
	table.insert(caveiras, caveira)
	vfx("CAVEIRA_NASCE", { posicao = ponto + Vector3.new(0, CFG.VOO, 0) })

	local corpo = caveira:IsA("Model")
		and (caveira.PrimaryPart or caveira:FindFirstChildWhichIsA("BasePart"))
		or caveira
	if not corpo then return end

	-- solta as peças e prende tudo na principal, para a física ter um corpo só
	for _, peca in ipairs(caveira:GetDescendants()) do
		if peca:IsA("BasePart") then
			peca.Anchored = false
			peca.CanCollide = false
			peca.Massless = true
			if peca ~= corpo then
				local solda = Instance.new("WeldConstraint")
				solda.Part0 = corpo
				solda.Part1 = peca
				solda.Parent = corpo
			end
		end
	end
	corpo.Massless = false

	local apoio = Instance.new("Attachment")
	apoio.Parent = corpo
	local voo = Instance.new("AlignPosition")
	voo.Attachment0 = apoio
	voo.Mode = Enum.PositionAlignmentMode.OneAttachment
	voo.MaxForce = CFG.FORCA_VOO
	voo.Responsiveness = CFG.AGILIDADE
	voo.Position = corpo.Position
	voo.Parent = corpo

	local passos = math.floor(CFG.VIDA / CFG.PASSO)
	local i = 1
	while i <= passos do
		local indice = i
		task.delay(indice * CFG.PASSO, function()
			if not (caveira.Parent and corpo.Parent and personagem) then return end
			local perto = alvosEm(corpo.Position, CFG.VISAO, 1)
			local presa = perto[1]
			if not presa then return end
			local presaCorpo = presa.Parent
			local presaRaiz = presaCorpo
				and presaCorpo:FindFirstChild("HumanoidRootPart")
			if not presaRaiz then return end

			-- persegue devagar: o alvo sempre à frente, nunca alcançado
			local rumo = (presaRaiz.Position - corpo.Position)
			if rumo.Magnitude > 1 then
				voo.Position = corpo.Position + rumo.Unit * CFG.AVANCO
					+ Vector3.new(0, CFG.VOO * 0.1, 0)
			end
			if indice % CFG.CADA_QUANTOS == 0 then
				largarBomba(corpo.Position, presaRaiz.Position)
			end
		end)
		i = i + 1
	end

	task.delay(CFG.VIDA, function()
		for indice, guardada in ipairs(caveiras) do
			if guardada == caveira then
				table.remove(caveiras, indice)
				break
			end
		end
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
	rig = Animator.new(personagem, "AtrasoMortal", Poses, Poses.SEQUENCIAS)
	return rig
end

local function animar()
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence("SOLTAR", function(passo)
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
	dispensarCaveiras()
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

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- ISTO ESTAVA FORA DO GERADOR — o mesmo defeito que o DRAMA teve, e pela mesma
-- causa: a ligação foi enxertada nos arquivos PRONTOS por
-- `FERRAMENTAS/ligar_deposito.py`, e a primeira regeneração a perdeu. As 6
-- Tools voltaram a não ter depósito, e só o `verificar_deposito_vfx.py`
-- percebeu.
--
-- Enxerto que não volta para o gerador é conserto que dura até a próxima
-- geração. Agora ele mora aqui.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
