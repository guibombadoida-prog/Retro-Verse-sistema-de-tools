-- XesterEsferadoFim_Server_V1.lua
-- Script de servidor — Xester Esfera do Fim  (Xester Forma 2)
--
-- RECRIADA DO ZERO, e não remendada.
--
--   As 14 Tools do Xester eram as mais antigas do repositório: saíram de um
--   gerador anterior ao `despachar`, à pasta `SFX/` e ao preâmbulo
--   compartilhado, e tinham M1 mais UMA Extra. Esta traz QUATRO. A M1 é a da
--   origem, mecânica por mecânica — é a habilidade pela qual a Tool tem nome.
--   As três Extras estendem o mesmo tema, e nenhuma inventa um segundo assunto.
--
--   M1   esfera que suga e detona   (a mecânica da origem, preservada)
--   R    Orbita   (Extra 1)
--   T    Compressao   (Extra 2)
--   Y    O Fim   (Extra 3)
--
-- DE ONDE VEM O MATERIAL
--
--   Forma 2 — `energb` e `staff`
--   CARREGA · DETONA · ECO · ORBITA, os quatro do `xesterv2`
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

local ARQUETIPO = "ARCANO"

local CFG = {
	CARGA         = 0.5,
	RAIO_SUGA     = 22,
	SUCCAO        = 46,
	RASPAO        = 5,
	PULSOS_CARGA  = 4,
	AVANCO        = 7,
	RAIO          = 16,
	NUCLEO        = 6,
	DANO          = 52,
	BORDA         = 26,
	EMPURRAO      = 88,
	TOMBO         = 1.6,
	RECARGA       = 14,

	RECARGA_R     = 13,
	ORBITAS       = 3,
	RAIO_ORBITA   = 9,
	DURACAO_ORB   = 6,
	PASSO_ORB     = 0.45,
	RAIO_TOQUE    = 6,
	DANO_ORBITA   = 11,

	RECARGA_T     = 16,
	RAIO_COMPRIME = 18,
	DURACAO_COMP  = 4.5,
	PASSO_COMP    = 0.5,
	LENTIDAO      = 0.35,
	DANO_COMPRIME = 7,

	RECARGA_Y     = 30,
	ALCANCE_FIM   = 45,
	RAIO_FIM      = 26,
	NUCLEO_FIM    = 9,
	DANO_FIM      = 78,
	BORDA_FIM     = 38,
	EMPURRAO_FIM  = 130,
	TOMBO_FIM     = 2.4,
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
local orbitaId = nil
local compressaoId = nil
local geracao = 0

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
-- M1 — a Esfera do Fim
--
-- A origem prendia a carga num `repeat ... until charging == false` amarrado ao
-- `Button1Up` do cliente: soltar o botão fora da tela deixava a sucção rodando
-- para sempre. Aqui a carga é o próprio compasso da animação — `CARGA` liga a
-- sucção, `SEGURA` a mantém, `GOLPE` detona. Não existe caminho em que ela
-- fique ligada.
--══════════════════════════════════════════════════════════════

local sugando = false

local function sugar()
	if not (personagem and raiz) then return end
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SUGA, 12)) do
		aplicarDano(alvo, CFG.RASPAO)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, raiz.Position - alvoRaiz.Position, CFG.SUCCAO, 0.22)
		end
	end
end

--- `ECO` é RÉPLICA, não segunda explosão: chega depois, mais grave, e não
--- carrega dano nenhum. Quem fere é o `DETONA`, que já saiu no beat.
local function detonar(centro, raio, nucleo, danoNucleo, danoBorda, forca, tombo)
	vfx("ESFERA_DETONA", { posicao = centro, raio = raio })
	tocarEm("DETONA", centro, 0.85)
	golpearArea(centro, raio, nucleo, danoNucleo, danoBorda, forca, tombo)
	task.delay(0.35, function()
		tocarEm("ECO", centro, 0.7)
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("ESFERA", despachar({
		CARGA  = { sfx = { "CARREGA", 1 }, faz = function()
			sugando = true
			vfx("ESFERA_CARREGA", { duracao = CFG.CARGA })
			local i = 1
			while i <= CFG.PULSOS_CARGA do
				task.delay(i * (CFG.CARGA / CFG.PULSOS_CARGA), function()
					if sugando then sugar() end
				end)
				i = i + 1
			end
		end },
		SEGURA = { faz = sugar },
		GOLPE  = { faz = function()
			sugando = false
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position + raiz.CFrame.LookVector * CFG.AVANCO
			detonar(centro, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
				CFG.EMPURRAO, CFG.TOMBO)
		end },
		FIM    = { faz = function() sugando = false end },
	}), function()
		ocupado = false
		sugando = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — Órbita  ·  T — Compressão  ·  Y — O Fim
--══════════════════════════════════════════════════════════════

local function apagarOrbita()
	geracao = geracao + 1
	if orbitaId then
		vfx("APAGAR", { id = orbitaId })
		orbitaId = nil
	end
end

--- Três esferas menores girando em volta do portador. Elas seguem o portador,
--- então o centro é lido A CADA PASSO — guardar a posição de partida deixaria
--- a órbita para trás no primeiro passo dado.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("ORBITA", despachar({
		CARGA = { sfx = { "ORBITA", 1.3 } },
		GOLPE = { faz = function()
			apagarOrbita()
			geracao = geracao + 1
			local minha = geracao
			orbitaId = novoId("ORBITA")
			vfx("ESFERA_CARREGA", { duracao = CFG.DURACAO_ORB,
				raio = CFG.RAIO_ORBITA, id = orbitaId })

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ORB
				local passo = 0
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local centro = raiz.Position
					local i = 1
					while i <= CFG.ORBITAS do
						local ang = passo * 0.9 + i * (math.pi * 2 / CFG.ORBITAS)
						local onde = centro + Vector3.new(
							math.cos(ang) * CFG.RAIO_ORBITA, 1,
							math.sin(ang) * CFG.RAIO_ORBITA)
						vfx("BARALHO_GOLPE", { posicao = onde })
						for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_TOQUE, 6)) do
							aplicarDano(alvo, CFG.DANO_ORBITA)
						end
						i = i + 1
					end
					passo = passo + 1
					task.wait(CFG.PASSO_ORB)
				end
				if minha == geracao then apagarOrbita() end
			end)
		end },
	}), function() ocupado = false end)
end

local function apagarCompressao()
	if compressaoId then
		vfx("APAGAR", { id = compressaoId })
		compressaoId = nil
	end
end

--- Compressão: campo parado que puxa devagar e afrouxa. É controle, não dano —
--- 7 por passo é raspão, e quem entra sai lento.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COMPRESSAO", despachar({
		CARGA  = { sfx = { "CARREGA", 0.8 } },
		SEGURA = { sfx = { "ORBITA", 0.9 } },
		GOLPE  = { faz = function()
			apagarCompressao()
			compressaoId = novoId("COMPRIME")
			local meu = compressaoId
			local onde = destino or frente(CFG.RAIO_COMPRIME)
			vfx("ONDA_CHAO", { posicao = onde, raio = CFG.RAIO_COMPRIME,
				duracao = CFG.DURACAO_COMP, id = meu })
			tocarEm("CARREGA", onde, 0.75)
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_COMP
				while compressaoId == meu and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_COMPRIME, 14)) do
						aplicarDano(alvo, CFG.DANO_COMPRIME)
						afrouxar(alvo, CFG.LENTIDAO, CFG.PASSO_COMP * 2)
						puxar(alvo, onde, 24, CFG.PASSO_COMP)
					end
					task.wait(CFG.PASSO_COMP)
				end
				if compressaoId == meu then apagarCompressao() end
			end)
		end },
	}), function() ocupado = false end)
end

--- O Fim: a detonação inteira, no ponto mirado, e longe do portador.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("FIM", despachar({
		CARGA  = { sfx = { "CARREGA", 0.7 } },
		SEGURA = { sfx = { "ORBITA", 0.7 } },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.ALCANCE_FIM)
			vfx("ESFERA_CARREGA", { posicao = centro, duracao = 0.2 })
			detonar(centro, CFG.RAIO_FIM, CFG.NUCLEO_FIM, CFG.DANO_FIM,
				CFG.BORDA_FIM, CFG.EMPURRAO_FIM, CFG.TOMBO_FIM)
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

	rig = Animator.new(personagem, "XesterEsfera", Poses,
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
	apagarOrbita()
	apagarCompressao()
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
