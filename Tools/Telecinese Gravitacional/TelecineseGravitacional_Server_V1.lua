-- TelecineseGravitacional_Server_V1.lua
-- Script de servidor — Telecinese Gravitacional  (conjunto GRAVIDADE)
--
-- Sai do `reality_tools.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_reality.py` para o mapa.
--
--   M1   puxa todos para o ponto mirado   (a habilidade que a origem ja tinha)
--   R    Singularidade   (Extra 1)
--   T    Orbita   (Extra 2)
--   Y    Expulsar   (Extra 3)
--
-- TRÊS HABILIDADES, E UM `AcaoRemote` SÓ
--
--   Os conjuntos anteriores tinham M1 mais uma Extra. Estas têm DUAS, e a
--   tentação seria dois `RemoteEvent`. Não: quem separa é o NOME DA TECLA no
--   payload, conferido aqui antes de qualquer coisa. Dois remotes seriam duas
--   portas para o mesmo cômodo, e duas superfícies para validar.
--
-- CONJUNTO SEM MODELO DE ORIGEM
--
--   Ninguém mandou um modelo de meme: Handle, som e pose são autorais. O
--   `SoundId` de cada um já toca em outra Tool entregue deste repositório —
--   nenhum id foi inventado, porque id chutado é som mudo que nenhum
--   verificador pega.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_gravidade_v2.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "TELECINESE"

local CFG = {
	ALCANCE       = 8,
	RAIO_PUXAO    = 30,
	DANO_PUXAO    = 16,
	TEMPO_PUXAO   = 0.8,
	RECARGA       = 12,

	RECARGA_R     = 26,
	RAIO_SING     = 26,
	DANO_SING     = 30,
	DANO_ESTOURO  = 55,
	TEMPO_SING    = 1.1,
	EMPURRAO_SING = 95,
	RECARGA_T      = 18,
	ALCANCE_ORBITA = 60,
	RAIO_ORBITA    = 18,
	DURACAO_ORBITA = 4.5,
	PASSO_ORBITA   = 0.4,
	ANEL_ORBITA    = 9,
	ALTURA_ORBITA  = 4,
	DANO_ORBITA    = 8,

	RECARGA_Y      = 20,
	RAIO_EXPULSA   = 24,
	NUCLEO_EXPULSA = 9,
	DANO_EXPULSA   = 44,
	BORDA_EXPULSA  = 22,
	FORCA_EXPULSA  = 165,
	TOMBO_EXPULSA  = 1.9,
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

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 18 `math.random` que o
--- `calebe_tools.rbxmx` tinha — e com todos os clientes desenhando, um sorteio
--- faria cada um ver uma cena diferente, o que lê como lag.
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
-- A FAVOR DESTA ORIGEM: as cinco Tools do `calebe_tools.rbxmx` já usavam
-- `TakeDamage`, e isso ficou. O que saiu foi o `BreakJoints` do `GravityHammer`
-- — destruição permanente não é dano — e o `IsTeamMate` que ele fazia por
-- conta própria, porque regra de time só existe dentro do Núcleo.
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

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
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

--═══════════════════════════════════════════════════════════════
-- AS DUAS QUE SÓ ESTE CONJUNTO PRECISA
--
-- `suspender` segura um alvo NO AR, a uma altura acima de onde ele estava.
-- `atrair` o puxa PARA um ponto. As duas por `BodyPosition` com prazo no
-- `Debris` — nunca por `Anchored`, que travaria o personagem inteiro e
-- deixaria o jogador preso se a Tool sumisse no meio.
--
-- E nenhuma das duas encosta em `workspace.Gravity`, que é global.
--═══════════════════════════════════════════════════════════════

local function suspender(alvoHum, altura, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 12000
	prender.D = 900
	prender.Position = alvoRaiz.Position + Vector3.new(0, altura, 0)
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
end

--- Puxa um alvo PARA um ponto.
local function atrair(alvoHum, ponto, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 9000
	prender.D = 1100
	prender.Position = ponto
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
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


--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o puxão
--
-- Todo mundo no raio vem PARA o ponto. É o inverso de toda explosão do
-- repositório, e é a leitura que define telecinese: as coisas vão para onde a
-- física não mandaria.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("PUXAO", despachar({
		ALCANCA = { faz = function()
			tocar("SendOut", 1.1)
			vfx("AGARRA", { origem = Handle.Position, destino = mira })
		end },
		PUXA = { faz = function()
			tocarEm("InitialHit", mira, 0.9)
			vfx("PUXAO", { posicao = mira, escala = 1.3, raio = CFG.RAIO_PUXAO })
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_PUXAO, 14)) do
				aplicarDano(alvo, CFG.DANO_PUXAO)
				atrair(alvo, mira, CFG.TEMPO_PUXAO, 11000)
			end
		end },
		SEGURA = { faz = function()
			tocar("Whack", 0.8)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a singularidade
--
-- Junta, segura, e estoura. O dano vem em dois tempos, e o segundo é maior:
-- quem ficou preso paga mais caro que quem escapou da atração.
--═══════════════════════════════════════════════════════════════

function extraR(mira)
	ocupado = true
	local id = novoId("SING")

	rig:PlaySequence("SINGULARIDADE", despachar({
		ABRE = { faz = function()
			tocar("SendOut", 0.8)
		end },
		REUNE = { faz = function()
			tocarEm("InitialHit", mira, 0.75)
			vfx("SINGULARIDADE", { posicao = mira, escala = 1.4,
				duracao = CFG.TEMPO_SING, id = id })
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING, 16)) do
				aplicarDano(alvo, CFG.DANO_SING)
				atrair(alvo, mira, CFG.TEMPO_SING, 14000)
			end
		end },
		SEGURA = { faz = function()
			tocarEm("Whack", mira, 0.6)
		end },
		COLAPSA = { faz = function()
			vfx("APAGAR", { id = id })
			vfx("COLAPSO", { posicao = mira, escala = 1.2 })
			tocarEm("Hit", mira, 0.7)
			-- quem ficou preso paga o dobro do que pagou na atração
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING * 0.6, 16)) do
				aplicarDano(alvo, CFG.DANO_ESTOURO)
				tombar(alvo, 2)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - mira)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SING, 0.32)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--- T — ÓRBITA: os alvos GIRAM em volta do ponto, presos num anel.
---
--- Cada alvo recebe o próprio `atrair`, para um ponto do anel que avança a
--- cada passo. É o giro: ninguém fica no centro, e ninguém escapa.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ORBITA", despachar({
		ABRE = { sfx = { "SendOut", 1.05 } },
		GIRA = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = destino or frente(CFG.ALCANCE_ORBITA * 0.5)
			apagarEfeito(orbitaId)
			orbitaId = novoId("ORBITA")
			local meu = orbitaId
			local minha = novaGeracao("T")
			vfx("PUXAO", { posicao = centro, raio = CFG.RAIO_ORBITA,
				duracao = CFG.DURACAO_ORBITA, id = meu })
			tocarEm("Hit", centro, 1.15)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ORBITA
				local passo = 0
				while geracao.T == minha and os.clock() < ate do
					if not personagem then break end
					local presos = alvosEm(centro, CFG.RAIO_ORBITA, 12)
					for indice, alvo in ipairs(presos) do
						local ang = passo * 0.8
							+ indice * (math.pi * 2 / math.max(#presos, 1))
						local onde = centro + Vector3.new(
							math.cos(ang) * CFG.ANEL_ORBITA,
							CFG.ALTURA_ORBITA,
							math.sin(ang) * CFG.ANEL_ORBITA)
						atrair(alvo, onde, CFG.PASSO_ORBITA * 1.4)
						aplicarDano(alvo, CFG.DANO_ORBITA)
					end
					passo = passo + 1
					task.wait(CFG.PASSO_ORBITA)
				end
				if orbitaId == meu then
					apagarEfeito(meu)
					orbitaId = nil
				end
			end)
		end },
	}), function() ocupado = false end)
end

--- Y — EXPULSAR: o contrário do puxão. Tudo vai para fora de uma vez.
---
--- É o fecho natural da `ÓRBITA`: junta com T, expulsa com Y.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("EXPULSAR", despachar({
		ERGUE  = { sfx = { "InitialHit", 0.9 } },
		SEGURA = { sfx = { "SendOut", 0.8 } },
		EXPULSA = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position
			if orbitaId then
				apagarEfeito(orbitaId)
				orbitaId = nil
				novaGeracao("T")
			end
			vfx("SINGULARIDADE", { posicao = centro,
				raio = CFG.RAIO_EXPULSA })
			vfx("PULSO", { posicao = centro, escala = 1.8 })
			tocarEm("Whack", centro, 0.8)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_EXPULSA, 16)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz
					and (alvoRaiz.Position - centro).Magnitude
					or CFG.RAIO_EXPULSA
				if d <= CFG.NUCLEO_EXPULSA then
					aplicarDano(alvo, CFG.DANO_EXPULSA)
					tombar(alvo, CFG.TOMBO_EXPULSA)
				else
					aplicarDano(alvo, CFG.BORDA_EXPULSA)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.6, 0), CFG.FORCA_EXPULSA, 0.34)
				end
			end
		end },
	}), function() ocupado = false end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e DUAS Extras
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

	rig = Animator.new(personagem, "GravGravitacional", Poses,
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
