-- XesterProcissaodeCartas_Server_V1.lua
-- Script de servidor — Xester Procissao de Cartas  (Xester Forma 2)
--
-- RECRIADA DO ZERO, e não remendada.
--
--   As 14 Tools do Xester eram as mais antigas do repositório: saíram de um
--   gerador anterior ao `despachar`, à pasta `SFX/` e ao preâmbulo
--   compartilhado, e tinham M1 mais UMA Extra. Esta traz QUATRO. A M1 é a da
--   origem, mecânica por mecânica — é a habilidade pela qual a Tool tem nome.
--   As três Extras estendem o mesmo tema, e nenhuma inventa um segundo assunto.
--
--   M1   fileira de cartas ate o alvo   (a mecânica da origem, preservada)
--   R    Formacao   (Extra 1)
--   T    Marcha   (Extra 2)
--   Y    Dissolver   (Extra 3)
--
-- DE ONDE VEM O MATERIAL
--
--   Forma 2 — cartas do `cards`, cajado do `staff`
--   SOBE · FORMACAO · MARCHA · DISSOLVE, os quatro do `xesterv2`
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
	ALCANCE       = 60,
	PASSOS        = 14,
	ESPACO        = 4,
	INTERVALO     = 0.07,
	RAIO          = 6,
	NUCLEO        = 3,
	DANO          = 22,
	BORDA         = 11,
	EMPURRAO      = 34,
	RECARGA       = 9,

	RECARGA_R     = 12,
	ANEL          = 8,
	CARTAS_ANEL   = 8,
	DURACAO_ANEL  = 5,
	PASSO_ANEL    = 0.5,
	DANO_ANEL     = 13,

	RECARGA_T     = 17,
	PASSOS_MARCHA = 18,
	ESPACO_MARCHA = 4,
	PASSO_MARCHA  = 0.16,
	RAIO_MARCHA   = 7,
	DANO_MARCHA   = 16,
	EMPURRAO_MAR  = 52,

	RECARGA_Y     = 24,
	RAIO_DISSOLVE = 20,
	NUCLEO_DISS   = 7,
	DANO_DISSOLVE = 56,
	BORDA_DISSOLVE = 28,
	EMPURRAO_DISS = 90,
	TOMBO         = 1.7,
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
local anelId = nil
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
-- M1 — a procissão
--
-- A origem andava 200 passos POR QUADRO, num laço apertado que segurava o
-- servidor inteiro. Aqui os passos são `task.delay` com o mesmo espaçamento —
-- mesma fileira, mesmo desenho, e o servidor respira entre um e outro.
--══════════════════════════════════════════════════════════════

local function fileira(origem, direcao, passos, espaco, intervalo, raio,
		nucleo, danoNucleo, danoBorda, forca, som)
	local i = 1
	while i <= passos do
		local indice = i
		task.delay(indice * intervalo, function()
			if not personagem then return end
			local onde = origem + direcao * (indice * espaco)
			vfx("CARTA_ERGUE", { posicao = onde })
			if som and indice % 4 == 1 then
				tocarEm(som, onde, 1)
			end
			golpearArea(onde, raio, nucleo, danoNucleo, danoBorda, forca,
				nil, 8)
		end)
		i = i + 1
	end
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PROCISSAO", despachar({
		CARGA  = { sfx = { "SOBE", 1 } },
		SEGURA = { sfx = { "FORMACAO", 1.1 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local ponto = destino or frente(CFG.ALCANCE)
			local delta = ponto - origem
			local distancia = delta.Magnitude
			if distancia < 1 then return end
			local passos = math.min(CFG.PASSOS,
				math.floor(distancia / CFG.ESPACO))
			if passos < 1 then passos = 1 end
			local direcao = delta.Unit
			vfx("PROCISSAO", { origem = origem, direcao = direcao,
				passos = passos, espaco = CFG.ESPACO,
				intervalo = CFG.INTERVALO })
			fileira(origem, direcao, passos, CFG.ESPACO, CFG.INTERVALO,
				CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA, CFG.EMPURRAO,
				"SOBE")
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Formação  ·  T — Marcha  ·  Y — Dissolver
--══════════════════════════════════════════════════════════════

local function apagarAnel()
	geracao = geracao + 1
	if anelId then
		vfx("APAGAR", { id = anelId })
		anelId = nil
	end
end

--- Formação: as cartas sobem em ANEL em volta do portador e ficam. É a
--- procissão parada — cobre as costas, que é o que a fileira não faz.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("FORMACAO", despachar({
		CARGA = { sfx = { "FORMACAO", 1 } },
		GOLPE = { faz = function()
			apagarAnel()
			geracao = geracao + 1
			local minha = geracao
			anelId = novoId("ANEL")
			vfx("PROCISSAO", { origem = raiz.Position,
				raio = CFG.ANEL, passos = CFG.CARTAS_ANEL,
				duracao = CFG.DURACAO_ANEL, id = anelId })
			tocar("FORMACAO", 0.95)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ANEL
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local centro = raiz.Position
					local i = 1
					while i <= CFG.CARTAS_ANEL do
						local ang = i * (math.pi * 2 / CFG.CARTAS_ANEL)
						local onde = centro + Vector3.new(
							math.cos(ang) * CFG.ANEL, 0,
							math.sin(ang) * CFG.ANEL)
						for _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 4)) do
							aplicarDano(alvo, CFG.DANO_ANEL)
							vfx("CARTA_ERGUE", { posicao = onde })
						end
						i = i + 1
					end
					task.wait(CFG.PASSO_ANEL)
				end
				if minha == geracao then apagarAnel() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Marcha: a fileira anda sozinha, mais longe e mais devagar que a M1, e
--- empurra em vez de estourar. É deslocamento de linha, não pico de dano.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MARCHA", despachar({
		CARGA  = { sfx = { "MARCHA", 1.1 } },
		SEGURA = { sfx = { "FORMACAO", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local ponto = destino or frente(CFG.ALCANCE)
			local delta = ponto - origem
			if delta.Magnitude < 1 then return end
			local direcao = delta.Unit
			vfx("PROCISSAO", { origem = origem, direcao = direcao,
				passos = CFG.PASSOS_MARCHA, espaco = CFG.ESPACO_MARCHA,
				intervalo = CFG.PASSO_MARCHA })
			fileira(origem, direcao, CFG.PASSOS_MARCHA, CFG.ESPACO_MARCHA,
				CFG.PASSO_MARCHA, CFG.RAIO_MARCHA, CFG.RAIO_MARCHA,
				CFG.DANO_MARCHA, CFG.DANO_MARCHA, CFG.EMPURRAO_MAR, "MARCHA")
		end },
	}), function() ocupado = false end)
end

--- Dissolver: a formação cai de uma vez. Com o anel de pé ela sai inteira; sem
--- ele, sai pela metade — a habilidade nunca é nula, mas premia quem preparou.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISSOLVER", despachar({
		CARGA  = { sfx = { "DISSOLVE", 1.2 } },
		SEGURA = { sfx = { "MARCHA", 0.85 } },
		GOLPE  = { faz = function()
			local centro = raiz.Position
			local cheio = anelId ~= nil
			apagarAnel()
			vfx("CARTA_DESABA", { posicao = centro, raio = CFG.RAIO_DISSOLVE })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("DISSOLVE", centro, 1.15)
			local nucleo = cheio and CFG.DANO_DISSOLVE
				or CFG.DANO_DISSOLVE * 0.5
			golpearArea(centro, CFG.RAIO_DISSOLVE, CFG.NUCLEO_DISS,
				nucleo, nucleo * 0.5, CFG.EMPURRAO_DISS, CFG.TOMBO)
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

	rig = Animator.new(personagem, "XesterProcissao", Poses,
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
	apagarAnel()
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
