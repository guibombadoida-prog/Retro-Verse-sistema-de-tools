-- XesterEscudodeCartas_Server_V1.lua
-- Script de servidor — Xester Escudo de Cartas
--
--   M1   Levanta a carta; ativar de novo estilhaca.
--   Y    Sopro Do Dragao (habilidade Extra)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   carta 8 x 13 x 0.3 a (0, 3, -5) do portador (un.lua:1959-1960)
--   rebate: dano 23..44, empurrao 120 (un.lua:2030, 2028)
--   estilhaco: raio 20, dano 7..12 (un.lua:1820-1826)
--   Extra: 125 passos com raio e dano crescentes (un.lua:2988-2996)
--
-- O QUE NÃO ATRAVESSOU A CONVERSÃO
--   `death()` / `:Remove()` no alvo  — matar por deleção tira o abate do
--                                      Núcleo e apaga o personagem do jogador
--   `damagealll` próprio             — regra de combate tem uma porta só
--   `math.random` no dano            — faixa determinística por contador
--   `swait()` / `wait()`             — task.wait e beat do animator
--   geometria movida por quadro NO SERVIDOR — replica a ~20 Hz picotado
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local AcaoRemote = Tool:WaitForChild("AcaoRemote")

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ARCANO"

--- A sequência de pose que esta habilidade toca. Ela existe no `Poses.lua`
--- desde sempre; o que faltava era alguém chamá-la.
local SEQUENCIA = "ESCUDO_DE_CARTAS"
local SEQUENCIA_EXTRA = "SOPRO_DO_DRAGAO"

local CFG = {
	RECARGA = 16,
	RECARGA_EXTRA = 10,
	ALCANCE = 60,
	CARTA = Vector3.new(8, 13, 0.3),
	ALTURA = 3,
	FRENTE = 5,
	DURACAO = 10,
	DANO_MIN = 23,
	DANO_MAX = 44,
	REBATE = 120,
	CACOS = 12,
	RAIO_ESTILHACO = 20,
	DANO_CACO_MIN = 7,
	DANO_CACO_MAX = 12,
	EMPURRAO = 120,
	PASSOS_SOPRO = 25,
	INTERVALO_SOPRO = 0.06,
	AVANCO_SOPRO = 2.4,
	RAIO_SOPRO = 6,
	CRESCE_SOPRO = 10,
	DANO_SOPRO_MIN = 4,
	DANO_SOPRO_MAX = 10,
	EXTRA_SOPRO = 6,
	EMPURRAO_SOPRO = 150,
}

--══════════════════════════════════════════════════════════════
-- ESTADO
--══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoUso, ultimoExtra = 0, 0
local ultimaMira = nil
local ativos = {}
local semente = 0

--- Trava de sequência. Sem ela o jogador reencadeia a habilidade por cima da
--- animação anterior e o `PlaySequence` do quadro seguinte cancela o do
--- anterior no meio — o golpe sai, a pose não.
local ocupado = false

local function proximo()
	semente = semente + 1
	if semente > 1000000 then semente = 1 end
	return semente
end

--- Faixa determinística no lugar de `math.random(a, b)`.
--- O original sorteava o dano a cada golpe; aqui a variedade vem de uma
--- senoide sobre o contador — mesma dispersão, e reproduzível.
local function naFaixa(minimo, maximo)
	local onda = (math.sin(proximo() * 2.399963) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

--- Ângulo áureo: espalha N pontos sem repetir e sem sortear.
local function anguloDe(indice)
	return math.rad(137.507764 * indice)
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
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
-- SOM — os `Sound` da Tool, que estavam MUDOS
--
-- As 14 Tools carregavam de 1 a 4 `Sound` nomeados por papel (`SELA`,
-- `AFUNDA`, `RISO`, `CONJURA`…) dentro do `.rbxmx`, e **nenhum server tocava
-- nenhum**. O asset estava depositado e nunca ligado — foi o "cadê os SFX".
--
-- `tocarEm` põe o som numa ÂNCORA PRÓPRIA, nunca na peça que o pediu: um
-- `Sound` só toca enquanto tem pai no DataModel, e pendurá-lo na carta que some
-- no quadro seguinte mata o som no quadro em que ele nasce.
--══════════════════════════════════════════════════════════════

local function tocar(nome, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function tocarEm(nome, posicao, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo decide (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro.
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

--- Golpe em área: dano + empurrão + o beat para o cliente desenhar.
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
-- MOLDES — o asset vem de DENTRO da Tool (Regra nº 1)
--══════════════════════════════════════════════════════════════

--- Acha um molde por nome, em qualquer profundidade de `Moldes/`.
local function molde(nome)
	return Moldes:FindFirstChild(nome, true)
end

--- Clona um molde para o mundo. O molde mora apagado (Transparency = 1);
--- quem acende é o cliente, ao desenhar. O que o servidor põe no mundo é
--- SÓ o que precisa de física ou de colisão.
local function porNoMundo(nome, cframe, vida)
	local base = molde(nome)
	if not base then return nil end
	local copia = base:Clone()
	copia.Parent = workspace
	if copia:IsA("BasePart") then
		copia.CFrame = cframe
	elseif copia:IsA("Model") and copia.PrimaryPart then
		copia:PivotTo(cframe)
	end
	Debris:AddItem(copia, vida or 8)
	return copia
end

--══════════════════════════════════════════════════════════════
-- PORTA DE ENTRADA — recarga, energia, e o beat
--══════════════════════════════════════════════════════════════

local function podeUsar(quando, recarga)
	if not (personagem and humanoide and humanoide.Health > 0 and raiz) then
		return false
	end
	if os.clock() - quando < recarga then return false end
	return true
end

--- Mira: o cliente manda para onde aponta. O servidor CONFERE o alcance em
--- vez de confiar — payload de cliente é entrada, não verdade.
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
-- PRIMÁRIA — Escudo de Cartas
--
-- Primeira ativação levanta a carta à frente; a segunda a estilhaça. É o
-- mesmo contrato do original ("Click to bounce people off, press p again to
-- shred"), com a diferença de que quem rebate é o `Touched` da carta REAL no
-- servidor — o original conectava `Touched` numa parte movida por quadro.
--══════════════════════════════════════════════════════════════

local escudo, toque = nil, nil

local function baixarEscudo()
	if toque then
		if toque.Connected then toque:Disconnect() end
		toque = nil
	end
	if escudo then
		-- o estilhaço soa onde o escudo ESTAVA, e só se ele existia: guardar a
		-- Tool sem escudo de pé não deve fazer barulho de vidro quebrando
		tocarEm("ESTILHACA", escudo.Position, 1)
		escudo.Parent = nil
		escudo = nil
	end
end

local function primaria()
	if escudo then
		-- segunda ativação: estilhaça
		local onde = escudo.Position
		baixarEscudo()
		vfx("ESCUDO_ESTILHACA", { posicao = onde, cacos = CFG.CACOS })
		golpearArea(onde, CFG.RAIO_ESTILHACO, CFG.DANO_CACO_MIN,
			CFG.DANO_CACO_MAX, CFG.EMPURRAO, 12)
		return
	end

	local base = molde("Carta1")
	if not base then return end

	escudo = base:Clone()
	escudo.Name = "EscudoDeCartas"
	escudo.Size = CFG.CARTA
	escudo.Transparency = 0
	escudo.Anchored = true
	escudo.CanCollide = false
	for _, decal in ipairs(escudo:GetChildren()) do
		if decal:IsA("Decal") then decal.Transparency = 0 end
	end
	escudo.CFrame = raiz.CFrame * CFrame.new(0, CFG.ALTURA, -CFG.FRENTE)
	escudo.Parent = workspace
	vfx("ESCUDO_SOBE", { posicao = escudo.Position })

	-- o escudo acompanha o portador sem que o servidor mexa nele por quadro:
	-- um Weld o prende à raiz, e a física replica interpolada
	escudo.Anchored = false
	escudo.Massless = true
	local solda = Instance.new("Weld")
	solda.Part0 = raiz
	solda.Part1 = escudo
	solda.C0 = CFrame.new(0, CFG.ALTURA, -CFG.FRENTE)
	solda.Parent = escudo

	toque = guardar(escudo.Touched:Connect(function(parte)
		local modelo = parte:FindFirstAncestorOfClass("Model")
		if not modelo or modelo == personagem then return end
		local alvo = modelo:FindFirstChildOfClass("Humanoid")
		if not alvo or alvo.Health <= 0 then return end
		aplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
		local alvoRaiz = modelo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.REBATE, 0.3)
		end
		vfx("ESCUDO_REBATE", { posicao = parte.Position })
	end))

	task.delay(CFG.DURACAO, baixarEscudo)
end

--══════════════════════════════════════════════════════════════
-- EXTRA — Sopro do Dragão
--
-- Jato que cresce enquanto avança: 125 passos no original, com o raio e o
-- dano subindo a cada passo ("The longer you hold, the more insaner it gets").
-- Aqui o crescimento é o mesmo, por passo, com teto.
--══════════════════════════════════════════════════════════════

local function extra()
	local origem = raiz.Position + Vector3.new(0, 1.5, 0)
	local direcao = raiz.CFrame.LookVector

	vfx("SOPRO", { origem = origem, direcao = direcao, passos = CFG.PASSOS_SOPRO,
		intervalo = CFG.INTERVALO_SOPRO })

	local i = 1
	while i <= CFG.PASSOS_SOPRO do
		local indice = i
		task.delay(indice * CFG.INTERVALO_SOPRO, function()
			if not (personagem and raiz) then return end
			local fracao = indice / CFG.PASSOS_SOPRO
			local onde = origem + direcao * (indice * CFG.AVANCO_SOPRO)
			local raio = CFG.RAIO_SOPRO + CFG.CRESCE_SOPRO * fracao
			golpearArea(onde, raio, CFG.DANO_SOPRO_MIN + CFG.EXTRA_SOPRO * fracao,
				CFG.DANO_SOPRO_MAX + CFG.EXTRA_SOPRO * fracao,
				CFG.EMPURRAO_SOPRO, 10)
		end)
		i = i + 1
	end
end


--══════════════════════════════════════════════════════════════
-- ANIMAÇÃO — o rig é DO SERVIDOR
--
-- `Instance.new("Weld")` criado num LocalScript é instância LOCAL: não replica.
-- Enquanto o rig morou no cliente, os outros jogadores viam o portador
-- executando a habilidade PARADO. Weld do servidor replica, e o C0 junto.
--══════════════════════════════════════════════════════════════

local function montarRig()
	if rig then return rig end
	if not personagem then return nil end
	rig = Animator.new(personagem, "XesterEscudodeCartas", Poses, Poses.SEQUENCIAS)
	return rig
end

--- O beat vem como KEYFRAME, não como string.
---
--- `PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a TABELA do
--- passo, e a marca está em `kf.marca`. Comparar o keyframe com uma string
--- nunca dá verdadeiro, e falha em SILÊNCIO.
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--- Toca a sequência e devolve o controle no beat.
---
--- ⚠️ ISTO NÃO ERA CHAMADO. O `animar()` existia nas 14 Tools e **nenhuma o
---    invocava**: `Poses.lua` e o `R6CFrameAnimator` eram código morto, o
---    personagem ficava parado, e o golpe saía inteiro no mesmo quadro do
---    clique. A habilidade acontecia; a animação, não.
---
--- `aoGolpe` é chamado na marca `GOLPE`. Se a sequência não tiver essa marca —
--- três delas terminam em `CARGA` —, ele é chamado no FIM. Habilidade que não
--- dispara é a falha que este repositório já pagou uma vez; aqui não há caminho
--- em que o golpe simplesmente não aconteça.
local function animar(sequencia, aoGolpe, aoCarga)
	local atual = montarRig()
	local disparou = false

	local function soltar()
		if disparou then return end
		disparou = true
		if aoGolpe then aoGolpe() end
	end

	if not atual then
		-- sem rig (Humanoid sumiu no meio do equipar) a habilidade ainda sai
		soltar()
		ocupado = false
		return
	end

	ocupado = true
	atual:PlaySequence(sequencia, function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		vfx("BEAT", { marca = marca })
		if marca == "CARGA" then
			if aoCarga then aoCarga() end
		elseif marca == "GOLPE" then
			soltar()
		end
	end, function()
		soltar()
		ocupado = false
	end)
end

--- Solta o rig POR INTEIRO, e zera a referência.
---
--- Zerar é o que importa: `montarRig()` devolve o `rig` em cache, e depois de
--- um respawn esse cache aponta para o Character MORTO. A sequência tocaria
--- num corpo que não existe mais — sem erro, sem pose, sem nada. Guardar o rig
--- entre duas vidas é o mesmo tipo de silêncio que o beat comparado com string.
local function desmontarRig()
	if not rig then return end
	rig:CancelSequence()
	rig:ReleaseLegs()
	rig:LockCharacter(false)
	rig:Destroy()
	rig = nil
end

--══════════════════════════════════════════════════════════════
-- OS DISPAROS — a habilidade sai NO BEAT, não no clique
--
-- Era aqui que faltava o fio. `primaria()` e `extra()` eram chamadas direto do
-- `Tool.Activated`, e a sequência de pose nunca tocava: dano, VFX e empurrão
-- saíam todos no MESMO quadro do clique, com o personagem parado.
--
-- Agora quem chama é o beat. `CARGA` toca o som de preparação, `GOLPE` solta a
-- habilidade. A trava `ocupado` impede reencadear por cima da animação.
--══════════════════════════════════════════════════════════════

local function dispararPrimaria()
	animar(SEQUENCIA, function()
		tocarEm("REBATE", raiz.Position, 1)
		primaria()
	end, function()
		tocar("SOBE", 1)
	end)
end

local function dispararExtra(ponto)
	animar(SEQUENCIA_EXTRA, function()
		tocarEm("SOPRO", raiz.Position, 1)
		extra(ponto)
	end)
end


--══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--══════════════════════════════════════════════════════════════

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	jogador = Players:GetPlayerFromCharacter(personagem)
	humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
end)

--- As duas portas fecham pelo MESMO caminho.
---
--- `desmontarRig` era o terceiro código morto desta Tool: definido e nunca
--- chamado, como o `animar()`. Com a trava `ocupado`, deixá-lo solto seria
--- pior que inútil — guardar a Tool no meio de uma sequência travaria
--- `ocupado = true` para sempre, e ao reequipar a habilidade nunca mais sairia.
local function desmontar()
	soltarTudo()
	desmontarRig()
	ocupado = false
	baixarEscudo()
end

Tool.Unequipped:Connect(desmontar)

Tool.Activated:Connect(function()
	-- a trava vem ANTES da recarga: barrar depois de `ultimoUso = os.clock()`
	-- cobraria o tempo de espera por um golpe que não saiu
	if ocupado then return end
	if not podeUsar(ultimoUso, CFG.RECARGA) then return end
	ultimoUso = os.clock()
	dispararPrimaria()
end)

AcaoRemote.OnServerEvent:Connect(function(quem, mira)
	-- O Remote é a porta de fora: confere QUEM chamou antes de qualquer coisa.
	if quem ~= jogador then return end
	if ocupado then return end
	if not podeUsar(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	dispararExtra(mirar(mira))
end)

--- `Destroying`, não `AncestryChanged`: a Tool pode trocar de pai a cada
--- equipar sem estar sendo destruída.
Tool.Destroying:Connect(desmontar)
