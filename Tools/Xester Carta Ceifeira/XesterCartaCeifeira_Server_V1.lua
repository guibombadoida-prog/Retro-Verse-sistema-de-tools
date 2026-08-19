-- XesterCartaCeifeira_Server_V1.lua
-- Script de servidor — Xester Carta Ceifeira  (Xester Forma 2)
--
-- RECRIADA DO ZERO, e não remendada.
--
--   As 14 Tools do Xester eram as mais antigas do repositório: saíram de um
--   gerador anterior ao `despachar`, à pasta `SFX/` e ao preâmbulo
--   compartilhado, e tinham M1 mais UMA Extra. Esta traz QUATRO. A M1 é a da
--   origem, mecânica por mecânica — é a habilidade pela qual a Tool tem nome.
--   As três Extras estendem o mesmo tema, e nenhuma inventa um segundo assunto.
--
--   M1   tres cartas que perseguem   (a mecânica da origem, preservada)
--   R    Ceifar   (Extra 1)
--   T    Marca   (Extra 2)
--   Y    Colheita   (Extra 3)
--
-- DE ONDE VEM O MATERIAL
--
--   Forma 2 — cartas do `cards`, cajado do `staff`
--   SAI · CRAVA · CEIFA · COLHEITA, os quatro do `xesterv2`
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

local ARQUETIPO = "CEIFA"

local CFG = {
	ALCANCE       = 55,
	CARTAS        = 3,
	INTERVALO     = 0.12,
	VOO           = 0.35,
	SAIDA         = 3,
	ESPALHA       = 4,
	RAIO          = 8,
	NUCLEO        = 3,
	DANO          = 26,
	BORDA         = 13,
	EMPURRAO      = 40,
	RECARGA       = 7,

	RECARGA_R     = 11,
	FRENTE_CEIFA  = 9,
	RAIO_CEIFA    = 11,
	NUCLEO_CEIFA  = 5,
	DANO_CEIFA    = 48,
	BORDA_CEIFA   = 24,
	TOMBO         = 1.4,

	RECARGA_T     = 13,
	ALCANCE_MARCA = 55,
	DURACAO_MARCA = 9,
	BONUS_MARCA   = 1.6,
	LENTIDAO      = 0.6,

	RECARGA_Y     = 24,
	RAIO_COLHEITA = 22,
	NUCLEO_COLH   = 8,
	DANO_COLHEITA = 58,
	BORDA_COLHEITA = 29,
	PUXAO         = 66,
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
local marcado = nil
local marcaAte = 0
local marcaId = nil

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
-- A MARCA — o multiplicador mora aqui, e vale para as três outras
--
-- `marcado` é um Humanoid, não um nome nem um caminho: se o alvo morre ou sai,
-- a referência ainda existe mas `Health <= 0` derruba o bônus sozinho. O prazo
-- é `os.clock()`, nunca `tick()`.
--══════════════════════════════════════════════════════════════

local function marcaViva()
	if not marcado then return false end
	if marcado.Health <= 0 then return false end
	if os.clock() > marcaAte then return false end
	return true
end

local function limparMarca()
	if marcaId then
		vfx("APAGAR", { id = marcaId })
		marcaId = nil
	end
	marcado = nil
	marcaAte = 0
end

--- O dano com o bônus da marca já aplicado. Uma porta só: se um dia o bônus
--- mudar, muda aqui, e as quatro habilidades acompanham.
local function ceifar(alvo, bruto)
	if marcaViva() and alvo == marcado then
		return aplicarDano(alvo, bruto * CFG.BONUS_MARCA)
	end
	return aplicarDano(alvo, bruto)
end

local function estourarEm(onde, raio, nucleo, danoNucleo, danoBorda, forca)
	for _, alvo in ipairs(alvosEm(onde, raio, 12)) do
		local alvoRaiz = raizDe(alvo)
		local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude or raio
		if d <= nucleo then
			ceifar(alvo, danoNucleo)
		else
			ceifar(alvo, danoBorda)
		end
		if alvoRaiz and forca then
			empurrar(alvo, (alvoRaiz.Position - onde) + Vector3.new(0, 0.5, 0),
				forca, 0.28)
		end
	end
end

--══════════════════════════════════════════════════════════════
-- M1 — três cartas ceifeiras
--
-- A mecânica é a da origem: três cartas saem acima do ombro, espalham em volta
-- do ponto mirado e estouram ao chegar. O espalhamento era `math.random` lá;
-- aqui é o ângulo áureo, para todos os clientes desenharem o mesmo leque.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CEIFEIRA", despachar({
		CARGA = { sfx = { "SAI", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ponto = destino or frente(CFG.ALCANCE)
			local origem = raiz.Position + Vector3.new(0, CFG.SAIDA, 0)
			local i = 1
			while i <= CFG.CARTAS do
				local indice = i
				task.delay(indice * CFG.INTERVALO, function()
					if not (personagem and raiz) then return end
					local ang = indice * 2.399963
					local chegada = ponto + Vector3.new(
						math.cos(ang) * CFG.ESPALHA, 0,
						math.sin(ang) * CFG.ESPALHA)
					vfx("CEIFEIRA_VOA", { origem = origem, destino = chegada,
						voo = CFG.VOO })
					task.delay(CFG.VOO, function()
						if not personagem then return end
						vfx("CEIFEIRA_ESTOURA", { posicao = chegada })
						tocarEm("CRAVA", chegada, 0.95)
						estourarEm(chegada, CFG.RAIO, CFG.NUCLEO, CFG.DANO,
							CFG.BORDA, CFG.EMPURRAO)
					end)
				end)
				i = i + 1
			end
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Ceifar  ·  T — Marca  ·  Y — Colheita
--══════════════════════════════════════════════════════════════

--- Corte largo à frente. É o único golpe corpo a corpo da Tool, e o que fecha
--- a distância que as cartas abrem.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("CEIFAR", despachar({
		CARGA  = { sfx = { "CEIFA", 0.85 } },
		SEGURA = { sfx = { "SAI", 1.2 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local onde = raiz.Position
				+ raiz.CFrame.LookVector * CFG.FRENTE_CEIFA
			vfx("MACHADO_CORTA", { posicao = onde })
			vfx("CEIFEIRA_ESTOURA", { posicao = onde })
			tocarEm("CEIFA", onde, 0.9)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_CEIFA, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude
					or CFG.RAIO_CEIFA
				if d <= CFG.NUCLEO_CEIFA then
					ceifar(alvo, CFG.DANO_CEIFA)
					tombar(alvo, CFG.TOMBO)
				else
					ceifar(alvo, CFG.BORDA_CEIFA)
					tombar(alvo, CFG.TOMBO * 0.5)
				end
			end
		end },
	}), function() ocupado = false end)
end

--- Marca o alvo mirado. Não fere: só faz doer mais, e mais devagar.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MARCA", despachar({
		CARGA = { sfx = { "COLHEITA", 1.25 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_MARCA),
				CFG.ALCANCE_MARCA)
			if not alvo then
				tocar("COLHEITA", 0.9)
				return
			end
			limparMarca()
			marcado = alvo
			marcaAte = os.clock() + CFG.DURACAO_MARCA
			marcaId = novoId("MARCA")
			local alvoRaiz = raizDe(alvo)
			local onde = alvoRaiz and alvoRaiz.Position or frente(10)
			vfx("CARTA_CHAO", { posicao = onde, duracao = CFG.DURACAO_MARCA,
				id = marcaId })
			tocarEm("COLHEITA", onde, 1.2)
			afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_MARCA)
			task.delay(CFG.DURACAO_MARCA, function()
				if marcado == alvo then limparMarca() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Colheita: puxa tudo para o centro e ceifa. Com a marca de pé, o marcado
--- entra no núcleo, e é ali que o bônus paga.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COLHEITA", despachar({
		CARGA  = { sfx = { "CEIFA", 0.75 } },
		SEGURA = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("PORTAL_ABRE", { posicao = centro, raio = CFG.RAIO_COLHEITA,
				duracao = 0.6 })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLHEITA, 16)) do
				puxar(alvo, centro, CFG.PUXAO, 0.5)
			end
		end },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("CEIFEIRA_ESTOURA", { posicao = centro })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("COLHEITA", centro, 0.75)
			estourarEm(centro, CFG.RAIO_COLHEITA, CFG.NUCLEO_COLH,
				CFG.DANO_COLHEITA, CFG.BORDA_COLHEITA, nil)
			limparMarca()
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

	rig = Animator.new(personagem, "XesterCeifeira", Poses,
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
	limparMarca()
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
