-- XesterInvocacao_Server_V1.lua
-- Script de servidor — Xester Invocacao  (Xester Forma 2)
--
-- RECRIADA DO ZERO, e não remendada.
--
--   As 14 Tools do Xester eram as mais antigas do repositório: saíram de um
--   gerador anterior ao `despachar`, à pasta `SFX/` e ao preâmbulo
--   compartilhado, e tinham M1 mais UMA Extra. Esta traz QUATRO. A M1 é a da
--   origem, mecânica por mecânica — é a habilidade pela qual a Tool tem nome.
--   As três Extras estendem o mesmo tema, e nenhuma inventa um segundo assunto.
--
--   M1   chama um servo   (a mecânica da origem, preservada)
--   R    Comandar   (Extra 1)
--   T    Legiao   (Extra 2)
--   Y    Dispensar   (Extra 3)
--
-- DE ONDE VEM O MATERIAL
--
--   Forma 2 — `enemy` e `skully`, PODADOS: os scripts `ai` e `core`
--   da origem não vieram junto
--   CHAMA · NASCE · COMANDA · LEGIAO, os quatro do `xesterv2`
--
--   Handle, moldes e sons saem dos dois arquivos de origem, pelo mapa de
--   `FERRAMENTAS/preparar_xester.py`. Nenhum `SoundId` foi inventado: id
--   chutado é som mudo que nenhum verificador pega.
--
-- TRÊS EXTRAS, E UM `AcaoRemote` SÓ
--
--   A tentação seria três `RemoteEvent`. Não: quem separa é o NOME DA TECLA no
--   payload, conferido no servidor antes de qualquer coisa. Três remotes
--   seriam três portas para o mesmo cômodo, e três superfícies para validar.
--
-- O QUE A ORIGEM FAZIA E AQUI NÃO ACONTECE
--
--   Ela escrevia em `Health` cinco vezes, chamava `BreakJoints` seis, e o
--   `Banish` fazia `Foe:Destroy()` — matar por deleção tira o abate do Núcleo e
--   apaga o personagem do jogador. Tinha 21 `math.random`, que com todos os
--   clientes desenhando faria cada um ver uma cena diferente. E deixava
--   `WalkSpeed` alterado para sempre. Nada disso sobreviveu.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester_novo.py. Editar aqui à mão faz as
-- catorze derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	ALCANCE       = 55,
	LIMITE        = 4,
	VIDA          = 22,
	PASSO         = 0.5,
	VELOCIDADE    = 18,
	VISAO         = 30,
	ALCANCE_GOLPE = 5,
	DANO          = 12,
	RECARGA       = 9,

	RECARGA_R     = 10,
	RAIO_COMANDO  = 10,
	DANO_COMANDO  = 24,
	EMPURRAO      = 44,

	RECARGA_T     = 26,
	LEGIAO        = 3,
	ANEL_LEGIAO   = 7,

	RECARGA_Y     = 16,
	RAIO_DISPENSA = 12,
	NUCLEO_DISP   = 5,
	DANO_DISPENSA = 42,
	BORDA_DISPENSA = 21,
	EMPURRAO_DISP = 70,
	TOMBO         = 1.5,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT, ultimoY = 0, 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as quatro virariam globais.
local primaria, extraR, extraT, extraY
local servos = {}

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 21 `math.random` da origem —
--- e com todos os clientes desenhando, um sorteio faria cada um ver uma cena
--- diferente, o que lê como lag.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Faixa determinística no lugar de `math.random(minimo, maximo)`.
local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Toca um som numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
--- some no quadro seguinte mata o som no quadro em que ele nasce.
--- No JODRO o som mora em `Tool/SFX/`, não pendurado no Handle: são três por
--- Tool e a pasta deixa claro que são irmãos.
local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
end

local function tocarEm(nome, posicao, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end

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

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- O beat vem como KEYFRAME, não como string.
---
--- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
--- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
--- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
--- dano não acontece. Custou os 14 Tools de dois conjuntos.
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL. A Tool sozinha num place vazio funciona
-- por inteiro — é o teste que decide a Regra nº 1.
--
-- A ORIGEM NÃO TINHA UM `TakeDamage`. Ela escrevia em `Health` cinco vezes,
-- chamava `BreakJoints` seis, e o `Banish` fazia `Foe:Destroy()` — matar por
-- deleção tira o abate do Núcleo e apaga o personagem do jogador.
--═══════════════════════════════════════════════════════════════

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

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
local function alvosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(
			posicao, raio, personagem, jogador, humanoide, limite or 12) or {}
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


--═══════════════════════════════════════════════════════════════
-- ALIADO — o espelho de `alvosEm`, e o primeiro do repositório
--
-- O `Cajado Curador` é a primeira Tool que precisa saber em quem NÃO bater. E
-- o `CLAUDE.md` é explícito: `IsTeamMate` só existe dentro do
-- `NucleoCombate.lua`. Chamar aqui seria abrir uma segunda porta para a regra
-- de time, e é exatamente o que o invariante proíbe.
--
-- Então a pergunta é feita ao Núcleo. E o FALLBACK não inventa regra de time:
-- ele DERIVA. Quem está no raio e NÃO está na lista de inimigos que o próprio
-- `alvosEm` devolveu é aliado — mais o portador, que nunca é inimigo de si.
--
-- Sem Núcleo e sem time configurado, `alvosEm` devolve todo mundo, a subtração
-- devolve só o portador, e a cura vira auto-cura. Que é o comportamento certo
-- para uma Tool sozinha num place vazio.
--═══════════════════════════════════════════════════════════════

local function aliadosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarAliados then
		return _G.Combate.detectarAliados(
			posicao, raio, personagem, jogador, humanoide, limite or 12) or {}
	end

	local inimigos = {}
	for _, hostil in ipairs(alvosEm(posicao, raio, limite or 12)) do
		inimigos[hostil] = true
	end

	local achados, vistos = {}, {}
	if humanoide and humanoide.Health > 0 then
		vistos[humanoide] = true
		table.insert(achados, humanoide)
	end

	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not vistos[hum] and not inimigos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function maisPertoAliado(ponto, raio)
	local melhor, dist = nil, math.huge
	for _, amigo in ipairs(aliadosEm(ponto, raio or 24, 12)) do
		local corpo = amigo.Parent
		local amigoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		local onde = amigoRaiz and amigoRaiz.Position
			or (corpo and corpo:FindFirstChild("Head")
				and corpo.Head.Position)
		if onde then
			local d = (onde - ponto).Magnitude
			if d < dist then melhor, dist = amigo, d end
		end
	end
	return melhor or humanoide
end

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE)
end

--- O alvo mais perto de um ponto.
local function maisPerto(ponto, raio)
	local melhor, dist = nil, math.huge
	for _, alvo in ipairs(alvosEm(ponto, raio, 12)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local d = (alvoRaiz.Position - ponto).Magnitude
			if d < dist then melhor, dist = alvo, d end
		end
	end
	return melhor
end

local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

local function puxar(alvoHum, centro, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end
	local delta = centro - alvoRaiz.Position
	if delta.Magnitude < 0.5 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.3)
end

--- Prender no lugar com prazo. `BodyPosition` no ponto onde o alvo já está —
--- não é teleporte, é âncora. Nunca `Anchored`, que travaria o personagem
--- inteiro e deixaria o jogador preso se a Tool sumisse no meio.
local function prender(alvoHum, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local ancora = Instance.new("BodyPosition")
	ancora.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	ancora.P = 12000
	ancora.D = 900
	ancora.Position = alvoRaiz.Position
	ancora.Parent = alvoRaiz
	Debris:AddItem(ancora, tempo or 3)
	return ancora
end

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta —
--- a origem chamava seis.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta garantida. Guarda a velocidade ANTES de mexer, e devolve
--- essa — nunca um número fixo, porque o alvo pode ter velocidade própria.
local function afrouxar(alvoHum, fator, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	local antes = alvoHum.WalkSpeed
	alvoHum.WalkSpeed = antes * (fator or 0.5)
	task.delay(tempo or 3, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = antes
		end
	end)
end

--- Dano em área com NÚCLEO e BORDA.
---
--- A origem fazia `ApplyAoE(pos, RAIO, MIN, MAX, FLING, INSTAKILL)` com um raio
--- só e dano chapado — e quatro das nove marcavam INSTAKILL. Dois raios é o que
--- impede uma explosão grande de matar meio servidor por estar por perto.
local function golpearArea(centro, raio, raioNucleo, danoNucleo, danoBorda,
		forca, tombo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 16)) do
		local alvoRaiz = raizDe(alvo)
		local d = alvoRaiz and (alvoRaiz.Position - centro).Magnitude or raio
		if d <= raioNucleo then
			aplicarDano(alvo, danoNucleo)
			if tombo then tombar(alvo, tombo) end
		else
			aplicarDano(alvo, danoBorda)
			if tombo then tombar(alvo, tombo * 0.5) end
		end
		if alvoRaiz and forca then
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.6, 0),
				forca, 0.32)
		end
		pegos = pegos + 1
	end
	return pegos
end


--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- Antes cada sequência tinha uma escada de `elseif marca == "X" then`, com o
-- nome do beat escrito DUAS vezes: no `Poses.lua` e de novo no `if`. Errar a
-- segunda falha em silêncio — a animação roda inteira e o beat não acontece.
-- Foi assim que 14 Tools de dois conjuntos ficaram sem dano.
--
-- Agora cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { cam = true, sfx = { "IMPACTO", 0.9 }, faz = bater }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe —
--          não dá mais para escrever `beatCena("CARGA")` dentro de `GOLPE`
--   `sfx`  toca um som: `{ nome, pitch }`
--   `faz`  o trabalho que não cabe em dado
--
-- Câmera e som viraram DADO. Só o que é trabalho continua sendo código, e ele
-- vem com nome em vez de posição na escada.
--
-- A ideia é do `grims-cutscene-engine`, que guarda Keyframes e Actions como
-- dado e deixa um runner interpretar. Nenhuma linha dele foi copiada — aquele
-- repositório não declara licença. Ver
-- FERRAMENTAS/TRIAGEM_FERRAMENTAS_EXTERNAS.md.
--═══════════════════════════════════════════════════════════════

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam and beatCena then beatCena(marca) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end


--══════════════════════════════════════════════════════════════
-- O SERVO — molde da própria Tool, e SEM script nenhum
--
-- A origem clonava `enemy` com os scripts `ai` e `core` ligados. Script de
-- terceiro rodando com vida própria dentro de uma Tool é o oposto da
-- autocontenção: ele lê o mundo, e ninguém sabe o que mais faz. O
-- `preparar_xester.py` poda os scripts do molde, e a perseguição é escrita
-- aqui, neste Server, que é filho da Tool.
--══════════════════════════════════════════════════════════════

local function moldeDe(nome)
	local pasta = Tool:FindFirstChild("Moldes")
	local achado = pasta and pasta:FindFirstChild(nome)
	return achado
end

local function porNoMundo(nome, cframe, vida)
	local base = moldeDe(nome)
	if not base then return nil end
	local copia = base:Clone()
	if copia:IsA("Model") then
		if not copia.PrimaryPart then
			local qualquer = copia:FindFirstChildWhichIsA("BasePart", true)
			if qualquer then copia.PrimaryPart = qualquer end
		end
		if copia.PrimaryPart then copia:PivotTo(cframe) end
	elseif copia:IsA("BasePart") then
		copia.CFrame = cframe
	end
	copia.Parent = workspace
	Debris:AddItem(copia, vida)
	return copia
end

--- Servo NÃO é alvo. `alvosEm` só sabe tirar o portador da conta; sem este
--- filtro os servos bateriam uns nos outros, e a Dispensar mataria os próprios
--- invocados antes de estourar.
local function hostisEm(posicao, raio, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(posicao, raio, (limite or 12) + CFG.LIMITE)) do
		local corpo = alvo.Parent
		if corpo and corpo.Name ~= "ServoDoXester" then
			table.insert(achados, alvo)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function esquecer(servo)
	local i = 1
	while i <= #servos do
		if servos[i] == servo then
			table.remove(servos, i)
			return
		end
		i = i + 1
	end
end

local function nascer(ponto)
	if #servos >= CFG.LIMITE then return nil end
	local servo = porNoMundo("enemy", CFrame.new(ponto + Vector3.new(0, 3, 0)),
		CFG.VIDA)
	if not servo then
		-- sem o molde a habilidade ainda acontece: o estouro do nascimento
		vfx("INVOCA", { posicao = ponto })
		return nil
	end
	servo.Name = "ServoDoXester"
	table.insert(servos, servo)
	vfx("INVOCA", { posicao = ponto })
	tocarEm("NASCE", ponto, 1)

	local servoHum = servo:FindFirstChildOfClass("Humanoid")
	local servoRaiz = servo:FindFirstChild("HumanoidRootPart")
		or servo:FindFirstChild("Torso")
	if not (servoHum and servoRaiz) then
		task.delay(CFG.VIDA, function() esquecer(servo) end)
		return servo
	end
	servoHum.WalkSpeed = CFG.VELOCIDADE

	-- a caça é por PRAZO, não por quadro: o servo escolhe alvo a cada passo e
	-- deixa o `Humanoid` andar. Quem interpola é o motor de física.
	task.spawn(function()
		local ate = os.clock() + CFG.VIDA
		while os.clock() < ate do
			if not (servo.Parent and servoHum.Health > 0) then break end
			local presa = hostisEm(servoRaiz.Position, CFG.VISAO, 1)[1]
			if presa then
				local presaRaiz = raizDe(presa)
				if presaRaiz then
					servoHum:MoveTo(presaRaiz.Position)
					if (presaRaiz.Position - servoRaiz.Position).Magnitude
							<= CFG.ALCANCE_GOLPE then
						vfx("SERVO_GOLPE", { posicao = servoRaiz.Position })
						aplicarDano(presa, CFG.DANO)
					end
				end
			end
			task.wait(CFG.PASSO)
		end
		esquecer(servo)
	end)
	return servo
end

local function dispensarServos()
	local guardados = servos
	servos = {}
	for _, servo in ipairs(guardados) do
		if servo.Parent then servo.Parent = nil end
	end
	return guardados
end

--══════════════════════════════════════════════════════════════
-- M1 — chama um servo no ponto mirado
--══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("INVOCAR", despachar({
		CARGA = { sfx = { "CHAMA", 0.95 } },
		GOLPE = { faz = function()
			nascer(destino or frente(CFG.ALCANCE))
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Comandar  ·  T — Legião  ·  Y — Dispensar
--══════════════════════════════════════════════════════════════

--- Comandar: manda TODOS ao ponto mirado, e o ponto leva um golpe junto. Sem
--- servo em pé ela ainda vale — é o golpe que chega.
function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COMANDAR", despachar({
		CARGA = { sfx = { "COMANDA", 0.9 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("INVOCA", { posicao = ponto })
			tocarEm("COMANDA", ponto, 0.85)
			for _, servo in ipairs(servos) do
				local servoHum = servo.Parent
					and servo:FindFirstChildOfClass("Humanoid")
				if servoHum and servoHum.Health > 0 then
					servoHum:MoveTo(ponto)
				end
			end
			for _, alvo in ipairs(hostisEm(ponto, CFG.RAIO_COMANDO, 10)) do
				aplicarDano(alvo, CFG.DANO_COMANDO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, alvoRaiz.Position - ponto, CFG.EMPURRAO, 0.24)
				end
			end
		end },
	}), function() ocupado = false end)
end

--- Legião: três de uma vez, em anel em volta do ponto. O teto de `LIMITE`
--- continua valendo — `nascer` recusa sozinho.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LEGIAO", despachar({
		CARGA  = { sfx = { "LEGIAO", 0.85 } },
		SEGURA = { sfx = { "CHAMA", 0.8 } },
		GOLPE  = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("PORTAL_ABRE", { posicao = ponto, raio = CFG.ANEL_LEGIAO,
				duracao = 1 })
			tocarEm("LEGIAO", ponto, 0.8)
			local i = 1
			while i <= CFG.LEGIAO do
				local ang = i * (math.pi * 2 / CFG.LEGIAO)
				nascer(ponto + Vector3.new(
					math.cos(ang) * CFG.ANEL_LEGIAO, 0,
					math.sin(ang) * CFG.ANEL_LEGIAO))
				i = i + 1
			end
		end },
	}), function() ocupado = false end)
end

--- Dispensar: cada servo estoura onde estava. É a saída de emergência quando
--- a legião inteira está longe e o portador está cercado.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISPENSAR", despachar({
		CARGA  = { sfx = { "NASCE", 0.75 } },
		SEGURA = { sfx = { "CHAMA", 0.7 } },
		GOLPE  = { faz = function()
			local guardados = dispensarServos()
			local pontos = {}
			for _, servo in ipairs(guardados) do
				local peca = servo:FindFirstChild("HumanoidRootPart")
					or servo:FindFirstChild("Torso")
					or servo:FindFirstChildWhichIsA("BasePart", true)
				if peca then table.insert(pontos, peca.Position) end
			end
			if #pontos == 0 then
				table.insert(pontos, frente(CFG.RAIO_DISPENSA))
			end
			for _, onde in ipairs(pontos) do
				vfx("CEIFEIRA_ESTOURA", { posicao = onde })
				tocarEm("NASCE", onde, 0.7)
				for _, alvo in ipairs(hostisEm(onde, CFG.RAIO_DISPENSA, 12)) do
					local alvoRaiz = raizDe(alvo)
					local d = alvoRaiz
						and (alvoRaiz.Position - onde).Magnitude
						or CFG.RAIO_DISPENSA
					if d <= CFG.NUCLEO_DISP then
						aplicarDano(alvo, CFG.DANO_DISPENSA)
						tombar(alvo, CFG.TOMBO)
					else
						aplicarDano(alvo, CFG.BORDA_DISPENSA)
					end
					if alvoRaiz then
						empurrar(alvo, (alvoRaiz.Position - onde)
							+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_DISP, 0.3)
					end
				end
			end
		end },
	}), function() ocupado = false end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e TRÊS Extras
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

--- As TRÊS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R", "T" e "Y" é descartada sem
--- resposta.
--- Confiar no cliente para dizer qual habilidade rodar seria dar a ele a
--- escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if tecla == "R" then
		if not pronto(ultimoR, CFG.RECARGA_R) then return end
		ultimoR = os.clock()
		extraR(mira)
	elseif tecla == "T" then
		if not pronto(ultimoT, CFG.RECARGA_T) then return end
		ultimoT = os.clock()
		extraT(mira)
	elseif tecla == "Y" then
		if not pronto(ultimoY, CFG.RECARGA_Y) then return end
		ultimoY = os.clock()
		extraY(mira)
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "XesterInvocacao", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	dispensarServos()
	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
