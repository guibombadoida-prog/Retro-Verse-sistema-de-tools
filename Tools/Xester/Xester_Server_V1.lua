-- Xester_Server_V1.lua
-- Script de servidor — Xester  (UMA Tool, DUAS formas, 13 habilidades)
--
--═══════════════════════════════════════════════════════════════
-- POR QUE UMA TOOL SÓ
--
--   `F` troca de forma: `The Final Deal` leva do baralho ao dragão, e
--   `Curtain Reversal` traz de volta. Com duas Tools, uma teria de ALCANÇAR a
--   outra — procurá-la na mochila, no `ReplicatedStorage`, num depósito. É
--   exatamente o que a Regra nº 1 proíbe, e ela vence a regra de distribuição
--   na ordem de precedência do `CLAUDE.md` (autocontenção é 1, distribuição
--   é 3).
--
--   Então a forma é ESTADO, aqui dentro. Nada sai, nada é procurado, e o teste
--   do place vazio continua passando: arraste `Xester` sozinho e as duas
--   formas funcionam, com as três cutscenes.
--
-- AS 13 HABILIDADES
--
--   FORMA 1 — Mestre do Baralho
--     Q  Curtain Call        some em cartas, deixa cópia, reaparece atrás
--     E  Four Suits Arsenal  oito cartas orbitando; o CLIQUE dispara o naipe
--     R  Joker's Labyrinth   cerca, embaralha posições, fecha no centro
--     T  Ace Gate            crava o Ás; T de novo teleporta até ele
--     Y  House Collapse      ergue o castelo; o CLIQUE derruba na mira
--     U  Eclipse Deck        carta negra no céu, marca, e tudo volta ao centro
--     P  Royal Guard         quatro Reis; CLIQUE lança um, P de novo baixa os quatro
--     F  The Final Deal      cutscene e virada para a Forma 2
--
--   FORMA 2 — Heavenbreaker
--     G  Wyrm Sparks         três cabeças de fogo que perseguem e marcam
--     H  Crown of Cinders    sol de Coringa; o CLIQUE estilhaça em brasas
--     J  Dragon's Requiem    SEGURAR carrega, soltar dispara o sopro curvado
--     K  Xester Prism        três máscaras, feixes que se cruzam e ANDAM
--     L  The Final Page      para o tempo, três pontos, e o dragão celeste
--     F  Curtain Reversal    cutscene e volta para a Forma 1
--
-- O CLIQUE É CONTEXTUAL, E ISSO É DE PROPÓSITO
--
--   §9 manda a primária ficar em `Tool.Activated`, nunca em botão. Cinco das
--   treze pedem "clicar para confirmar" no desenho: o naipe, o desabamento, o
--   Rei, as brasas e os três pontos da ultimate. Então o clique DESPACHA para
--   o que está armado, e cai num golpe simples quando não há nada armado.
--   Uma entrada, um significado por vez, e nunca um botão fazendo o papel da
--   primária.
--
-- A PASSIVA
--
--   A cada TRÊS habilidades da Forma 1, nasce a Carta Coringa. A próxima
--   habilidade a gasta e sai reforçada: dano × 1.6 e raio × 1.25. O contador
--   está aqui, no servidor, porque é ele que aplica o dano — deixar isso no
--   cliente seria deixar o multiplicador com quem pode mentir.
--
-- ESCRITO À MÃO, NÃO GERADO
--
--   Os outros conjuntos têm gerador porque são sete Tools quase iguais. Esta é
--   UMA. Um gerador aqui seria indireção sem ganho: o `.rbxmx` e o `.rbxm`
--   continuam DERIVADOS deste arquivo, que é o que a regra de entrega pede.
--═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool           = script.Parent
local Handle         = Tool:WaitForChild("Handle")
local VFXRemote      = Tool:WaitForChild("VFXRemote")
local AcaoRemote     = Tool:WaitForChild("AcaoRemote")
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")
local Poses          = require(Tool:WaitForChild("Poses"))
local Animator       = require(Tool:WaitForChild("R6CFrameAnimator"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ARCANO"

local CFG = {
	-- ── comum ─────────────────────────────────────────────────
	ALCANCE_MIRA   = 60,
	DANO_M1        = 16,
	RECARGA_M1     = 0.55,
	RAIO_M1        = 5,

	-- ── passiva ───────────────────────────────────────────────
	PASSO_CORINGA  = 3,      -- a cada 3 habilidades
	BONUS_DANO     = 1.6,
	BONUS_RAIO     = 1.25,
	VIDA_CORINGA   = 30,

	-- ── Q  Curtain Call ───────────────────────────────────────
	Q_RECARGA      = 14,
	Q_INVISIVEL    = 1.5,
	Q_TRANSPARENCIA = 0.85,   -- não 1: sumir por completo é injogável para quem enfrenta
	Q_RAIO         = 12,
	Q_DANO         = 32,
	Q_ATORDOA      = 1.6,
	Q_EMPURRAO     = 46,
	Q_ATRAS        = 5,

	-- ── E  Four Suits Arsenal ─────────────────────────────────
	E_RECARGA      = 16,
	E_DURACAO      = 12,
	E_CARTAS       = 8,
	E_ORBITA       = 5,
	E_PASSO        = 0.25,
	E_ALCANCE      = 55,
	E_VOO          = 0.2,
	E_RAIO         = 6,
	E_DANO         = 22,
	E_PERFURA      = 1.45,   -- Espadas: dano maior, sem empurrão
	E_EMPURRAO     = 78,     -- Paus: empurra
	E_RICOCHETES   = 2,      -- Ouros: ricocheteia
	E_CURA         = 9,      -- Copas: recupera

	-- ── R  Joker's Labyrinth ──────────────────────────────────
	R_RECARGA      = 24,
	R_RAIO         = 22,
	R_PAREDES      = 10,
	R_ESPERA       = 0.9,
	R_DURACAO      = 3.6,
	R_DANO_FECHA   = 54,
	R_BORDA_FECHA  = 27,
	R_NUCLEO       = 8,
	R_TOMBO        = 1.5,

	-- ── T  Ace Gate ───────────────────────────────────────────
	T_RECARGA      = 10,
	T_ALCANCE      = 60,
	T_VOO          = 0.28,
	T_VIDA_AS      = 10,
	T_RAIO         = 7,
	T_DANO         = 26,
	T_ATRAS        = 5,
	T_DANO_PORTAO  = 18,

	-- ── Y  House Collapse ─────────────────────────────────────
	Y_RECARGA      = 20,
	Y_DURACAO      = 12,
	Y_ANDARES      = 4,
	Y_ALCANCE      = 26,
	Y_LARGURA      = 10,
	Y_DANO_PAREDE  = 34,
	Y_EMPURRAO     = 96,
	Y_RAIO_CENTRO  = 13,
	Y_DANO_CENTRO  = 52,
	Y_BORDA_CENTRO = 26,
	Y_TOMBO        = 1.6,

	-- ── U  Eclipse Deck ───────────────────────────────────────
	U_RECARGA      = 34,
	U_RAIO_MARCA   = 40,
	U_ALTURA       = 46,
	U_ESPERA       = 1.4,
	U_DURACAO      = 5,
	U_LIMITE       = 10,
	U_RAIO_FINAL   = 26,
	U_NUCLEO       = 9,
	U_DANO         = 66,
	U_BORDA        = 33,
	U_PUXAO        = 92,
	U_TOMBO        = 2,

	-- ── P  Royal Guard ────────────────────────────────────────
	P_RECARGA      = 18,
	P_DURACAO      = 14,
	P_ORBITA       = 4.4,
	P_ALCANCE      = 42,
	P_VOO          = 0.24,
	P_RAIO_REI     = 8,
	P_DANO_REI     = 30,
	P_EMPURRAO     = 104,
	P_RAIO_BAQUE   = 14,
	P_NUCLEO_BAQUE = 6,
	P_DANO_BAQUE   = 46,
	P_BORDA_BAQUE  = 23,
	P_TOMBO        = 1.8,

	-- ── G  Wyrm Sparks ────────────────────────────────────────
	G_RECARGA      = 8,
	G_CABECAS      = 3,
	G_ALCANCE      = 55,
	G_INTERVALO    = 0.12,
	G_VOO          = 0.42,
	G_ESPALHA      = 4,
	G_RAIO         = 7,
	G_DANO         = 24,
	G_MARCA_VIDA   = 5,
	G_MARCA_RAIO   = 6,
	G_MARCA_PASSO  = 0.7,
	G_MARCA_DANO   = 6,

	-- ── H  Crown of Cinders ───────────────────────────────────
	H_RECARGA      = 26,
	H_DURACAO      = 8,
	H_ALTURA       = 22,
	H_FRAGMENTOS   = 9,
	H_INTERVALO    = 0.1,
	H_ESPALHA      = 12,
	H_VOO          = 0.5,
	H_ALCANCE      = 55,
	H_RAIO         = 9,
	H_NUCLEO       = 4,
	H_DANO         = 38,
	H_BORDA        = 19,
	H_EMPURRAO     = 54,

	-- ── J  Dragon's Requiem ───────────────────────────────────
	J_RECARGA      = 22,
	J_CARGA_MAX    = 2.4,
	J_NOS          = 9,
	J_ALCANCE_MIN  = 24,
	J_ALCANCE_MAX  = 64,
	J_LARGURA_MIN  = 5,
	J_LARGURA_MAX  = 12,
	J_CURVA        = 0.42,   -- quanto o sopro desvia para o lado do olhar
	J_DANO_MIN     = 30,
	J_DANO_MAX     = 72,
	J_EMPURRAO     = 62,

	-- ── K  Xester Prism ───────────────────────────────────────
	K_RECARGA      = 20,
	K_DURACAO      = 5,
	K_PASSO        = 0.28,
	K_RAIO_MASCARA = 7,
	K_ALTURA       = 7,
	K_ALCANCE      = 55,
	K_RAIO         = 6,
	K_DANO         = 13,
	K_LENTIDAO     = 0.7,

	-- ── L  The Final Page of Heaven ───────────────────────────
	L_RECARGA      = 70,
	L_RAIO_PARADA  = 34,
	L_PARADA       = 3.2,
	L_PONTOS       = 3,
	L_JANELA       = 6,      -- tempo para escolher os três pontos
	L_ALCANCE      = 65,
	L_RAIO_PONTO   = 16,
	L_DANO_PONTO   = 58,
	L_BORDA_PONTO  = 29,
	L_NUCLEO_PONTO = 6,
	L_TOMBO        = 2.4,

	-- ── F  a troca de forma ───────────────────────────────────
	F_RECARGA      = 30,
	F_PRAZO_CENA   = 8,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ocupado = false
local ativos = {}
local semente, idEfeito = 0, 0

--- 1 = Mestre do Baralho, 2 = Heavenbreaker. Nunca outro valor.
local forma = 1

--- O que o CLIQUE vai fazer. `nil` = golpe simples.
local armado = nil

--- Recarga por tecla. Uma tabela em vez de oito locais: com treze habilidades
--- a lista de `ultimoQ, ultimoE, ...` viraria uma parede de nomes.
local ultimo = {}
local ultimoM1 = 0

--- A passiva.
local usosDaForma1, coringaPronto, coringaId = 0, false, nil

--- Os efeitos com prazo, por habilidade. Cada um é um `id` que o cliente
--- conhece, e `VFX.Parar(id)` desfaz. Sem isto, a Tool guardada no meio de um
--- labirinto deixaria as cartas girando na tela para sempre.
local arsenalId, labirintoId, asId, casteloId = nil, nil, nil, nil
local eclipseId, guardaId, auraId = nil, nil, nil
local prismaId, requiemId, copiaId = nil, nil, nil
local coroaId = nil
local marcasEclipse = {}
local pontosPagina = {}
local pontosId = {}

--- Onde o Ás, o castelo e o sol da Coroa estão, para a segunda entrada saber
--- o alvo. Cada um tem o SEU: emprestar o campo de outro já apagou efeito por
--- engano neste repositório.
local asOnde, casteloOnde, coroaOnde = nil, nil, nil

--- A geração corta laço velho: cada habilidade com prazo incrementa a sua, e o
--- laço confere antes de cada passo. Sem isso, usar a habilidade duas vezes
--- deixa dois laços vivos escrevendo no mesmo `id`.
local geracao = {}

--- O cajado da Forma 2 e a solda dele. Peça REAL, não efeito: é ela que diz em
--- qual forma o Xester está, mesmo para quem chegou depois da cutscene.
local cajado, soldaCajado = nil, nil

--- A invisibilidade do Curtain Call guarda a transparência ANTERIOR de cada
--- peça, e devolve aquela. Devolver 0 chutado apagaria acessório transparente
--- e personagem com peça semi-transparente de propósito.
local transparenciaAntes = nil

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso virariam globais.
local primaria, aoEquipar, aoGuardar
local habilidade = {}

--═══════════════════════════════════════════════════════════════
-- DETERMINISMO — zero `math.random`
--
-- Com todos os clientes desenhando, um sorteio faria cada um ver uma cena
-- diferente, o que lê como lag. O ângulo áureo (137.507764°) nunca repete
-- alinhamento, então o que se espalha por ele nunca fica empilhado.
--═══════════════════════════════════════════════════════════════

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function anguloDe(indice)
	return (indice or proximo()) * 2.399963
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function apagarEfeito(id)
	if id then vfx("APAGAR", { id = id }) end
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Avança a geração de uma habilidade e devolve a nova. Quem roda um laço
--- guarda o valor e compara antes de cada passo.
local function novaGeracao(chave)
	geracao[chave] = (geracao[chave] or 0) + 1
	return geracao[chave]
end

--═══════════════════════════════════════════════════════════════
-- SOM — sempre numa âncora própria, nunca na peça que o pediu
--
-- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
-- some no quadro seguinte mata o som no quadro em que ele nasce.
--═══════════════════════════════════════════════════════════════

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
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- O BEAT VEM COMO KEYFRAME, NÃO COMO STRING
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local beatCena

--- Tabela de keyframe no lugar da escada de `elseif marca == "X"`.
---
---     GOLPE = { cam = true, sfx = { "DESABA", 0.9 }, faz = derrubar }
---
--- `cam` manda o beat para a câmera com o nome do PRÓPRIO keyframe — não dá
--- para escrever `beatCena("CARGA")` dentro de `GOLPE` por engano. `sfx` toca
--- um som. `faz` é o trabalho que não cabe em dado.
local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam then beatCena(marca) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro.
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

--- O bônus da Carta Coringa entra AQUI, numa porta só. Se um dia o número
--- mudar, muda aqui, e as treze habilidades acompanham.
local bonusAtivo = false

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local pedido = bonusAtivo and (bruto * CFG.BONUS_DANO) or bruto
	local final = (_G.Combate and _G.Combate.calcular
		and _G.Combate.calcular(jogador, alvoHum, pedido)) or pedido
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

local function comBonus(valor)
	if bonusAtivo then return valor * CFG.BONUS_RAIO end
	return valor
end

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
---
--- `personagem` é EXCLUÍDO da consulta: é o que garante que nenhuma das treze
--- fere o próprio portador, mesmo as que estouram em cima dele.
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

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or 20)
end

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

--- Prender no lugar com prazo. `BodyPosition` onde o alvo JÁ ESTÁ — não é
--- teleporte, é âncora. Nunca `Anchored`, que travaria o personagem inteiro e
--- deixaria o jogador preso se a Tool sumisse no meio.
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

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta garantida. Guarda a velocidade ANTES e devolve essa —
--- nunca um número fixo, porque o alvo pode ter velocidade própria.
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

--- Dano em área com NÚCLEO e BORDA. Dois raios é o que impede uma explosão
--- grande de matar meio servidor por estar por perto.
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

--- Cura o portador. `Health` escrito à mão é proibido em DANO — mas cura não
--- é dano, e `TakeDamage` negativo não existe. O teto é `MaxHealth`.
local function curar(quanto)
	if not (humanoide and humanoide.Parent and humanoide.Health > 0) then
		return 0
	end
	local antes = humanoide.Health
	humanoide.Health = math.min(humanoide.MaxHealth, antes + quanto)
	return humanoide.Health - antes
end

--═══════════════════════════════════════════════════════════════
-- A PASSIVA — a Carta Coringa
--═══════════════════════════════════════════════════════════════

local function apagarCoringa()
	apagarEfeito(coringaId)
	coringaId = nil
	coringaPronto = false
end

--- Chamada NO COMEÇO de toda habilidade. Se a carta estiver de pé, ela é
--- gasta e o bônus vale por esta habilidade inteira; o contador só anda na
--- Forma 1, que é onde a passiva existe.
local function abrirHabilidade()
	bonusAtivo = false
	if coringaPronto then
		bonusAtivo = true
		if raiz then
			vfx("CORINGA_GASTA", { posicao = raiz.Position })
			tocarEm("CORINGA", raiz.Position, 1.35)
		end
		apagarCoringa()
	end
	if forma ~= 1 then return end
	usosDaForma1 = usosDaForma1 + 1
	if usosDaForma1 >= CFG.PASSO_CORINGA then
		usosDaForma1 = 0
		if raiz then
			apagarCoringa()
			coringaId = novoId("CORINGA")
			coringaPronto = true
			vfx("CORINGA_NASCE", { posicao = raiz.Position,
				duracao = CFG.VIDA_CORINGA, id = coringaId })
			tocarEm("CORINGA", raiz.Position, 1.25)
		end
	end
end

--- Chamada no FIM de toda habilidade, pelo callback do `PlaySequence`.
local function fecharHabilidade()
	ocupado = false
	bonusAtivo = false
end

--═══════════════════════════════════════════════════════════════
-- A CÂMERA — beat nomeado, e só para o DONO
--
-- Câmera é 100% cliente: o servidor manda NOME e nunca `CFrame`. E o pedido
-- foi explícito — a cutscene não pode ser forçada nos outros jogadores —,
-- então é `FireClient(jogador, …)`, não `FireAllClients`.
--
-- O VFX da transformação continua indo para todo mundo: quem está por perto vê
-- o Xester virar dragão, só não perde o controle da própria câmera.
--═══════════════════════════════════════════════════════════════

function beatCena(nome)
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "BEAT", { nome = nome })
end

local function comecarCena(qual)
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "INICIO",
		{ cena = qual, prazo = CFG.F_PRAZO_CENA })
end

local function acabarCena()
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "FIM", {})
end

--═══════════════════════════════════════════════════════════════
-- O CAJADO — a peça que troca de forma
--
-- O Handle NÃO pode trocar: `RequiresHandle` exige que ele exista o tempo
-- todo, e mexer na geometria dele desmonta o `Grip` do `Humanoid`. Então quem
-- carrega a forma é uma peça à parte, soldada ao braço direito.
--
-- `Weld` criado no SERVIDOR replica; criado no cliente, não — os outros
-- jogadores veriam o Xester de mãos vazias.
--═══════════════════════════════════════════════════════════════

local function tirarCajado()
	if soldaCajado then
		soldaCajado.Parent = nil
		soldaCajado = nil
	end
	if cajado then
		cajado.Parent = nil
		cajado = nil
	end
end

local function porCajado()
	tirarCajado()
	local moldes = Tool:FindFirstChild("Moldes")
	local base = moldes and moldes:FindFirstChild("Cajado")
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not (base and base:IsA("BasePart") and braco) then return end

	cajado = base:Clone()
	cajado.Name = "CajadoDoXester"
	cajado.Anchored = false
	cajado.CanCollide = false
	cajado.CanQuery = false
	cajado.CanTouch = false
	cajado.Massless = true
	cajado.Transparency = 0
	for _, filho in ipairs(cajado:GetDescendants()) do
		if filho:IsA("BasePart") then
			filho.Transparency = 0
			filho.CanCollide = false
			filho.Massless = true
		elseif filho:IsA("Decal") or filho:IsA("Texture") then
			filho.Transparency = 0
		elseif filho:IsA("PointLight") or filho:IsA("SpotLight") then
			filho.Enabled = true
		end
	end
	cajado.CFrame = braco.CFrame
	cajado.Parent = personagem

	soldaCajado = Instance.new("Weld")
	soldaCajado.Part0 = braco
	soldaCajado.Part1 = cajado
	soldaCajado.C0 = CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(90), 0, 0)
	soldaCajado.Parent = cajado
end

--═══════════════════════════════════════════════════════════════
-- LIMPEZA — toda habilidade com prazo tem de saber se desfazer
--
-- É chamada pela troca de forma, pelo `Unequipped`, pelo `Destroying` e pela
-- morte. Efeito com prazo que ninguém desfaz é lixo na tela de todo mundo.
--═══════════════════════════════════════════════════════════════

local function aparecer()
	if not transparenciaAntes then return end
	for peca, valor in pairs(transparenciaAntes) do
		if peca and peca.Parent then peca.Transparency = valor end
	end
	transparenciaAntes = nil
end

local function sumir()
	aparecer()
	if not personagem then return end
	transparenciaAntes = {}
	for _, peca in ipairs(personagem:GetDescendants()) do
		if peca:IsA("BasePart") and peca.Name ~= "HumanoidRootPart" then
			transparenciaAntes[peca] = peca.Transparency
			peca.Transparency = math.max(peca.Transparency,
				CFG.Q_TRANSPARENCIA)
		end
	end
	transparenciaAntes[Handle] = Handle.Transparency
	Handle.Transparency = math.max(Handle.Transparency, CFG.Q_TRANSPARENCIA)
end

local function limparTudo()
	for chave in pairs(geracao) do
		geracao[chave] = (geracao[chave] or 0) + 1
	end
	for _, id in ipairs({ arsenalId, labirintoId, asId, casteloId, coroaId,
			eclipseId, guardaId, auraId, prismaId, requiemId, copiaId,
			coringaId }) do
		apagarEfeito(id)
	end
	for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
	for _, id in ipairs(pontosId) do apagarEfeito(id) end
	arsenalId, labirintoId, asId, casteloId = nil, nil, nil, nil
	eclipseId, guardaId, auraId, coroaId = nil, nil, nil, nil
	prismaId, requiemId, copiaId = nil, nil, nil
	coringaId, coringaPronto = nil, false
	marcasEclipse, pontosPagina, pontosId = {}, {}, {}
	asOnde, casteloOnde, coroaOnde, armado = nil, nil, nil, nil
	aparecer()
	acabarCena()
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — Q  ·  Curtain Call
--
-- Ele se desfaz em cartas, deixa uma CÓPIA falsa no lugar e fica invisível por
-- 1.5 s, andando. Ao reaparecer, a cópia estoura em cartas e atordoa quem
-- estiver perto DELA — não de quem reapareceu. É essa distância que faz a
-- habilidade valer: o estouro acontece onde o inimigo achava que você estava.
--
-- A cópia não tem `Humanoid`, e é de propósito: um boneco com Humanoid entra
-- na consulta de alvo de todo mundo, inclusive na sua própria.
--═══════════════════════════════════════════════════════════════

habilidade.Q = function(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("CURTAIN_CALL", despachar({
		CARGA = { sfx = { "CORTINA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ondeSumiu = raiz.Position
			local minha = novaGeracao("Q")

			apagarEfeito(copiaId)
			copiaId = novoId("COPIA")
			vfx("CURTAIN_SOME", { posicao = ondeSumiu })
			vfx("CURTAIN_COPIA", { posicao = ondeSumiu,
				duracao = CFG.Q_INVISIVEL + 0.2, id = copiaId })
			tocarEm("CORTINA", ondeSumiu, 0.95)
			sumir()

			task.delay(CFG.Q_INVISIVEL, function()
				if geracao.Q ~= minha then return end
				aparecer()
				apagarEfeito(copiaId)
				copiaId = nil
				if not (personagem and raiz and raiz.Parent) then return end

				-- reaparece ATRÁS do alvo mais perto da cópia, quando há um
				local alvo = maisPerto(ondeSumiu, CFG.Q_RAIO)
				local alvoRaiz = alvo and raizDe(alvo)
				if alvoRaiz then
					local atras = alvoRaiz.Position
						- alvoRaiz.CFrame.LookVector * CFG.Q_ATRAS
					raiz.CFrame = CFrame.new(atras + Vector3.new(0, 1, 0),
						alvoRaiz.Position)
				end

				vfx("CURTAIN_ESTOURA", { posicao = ondeSumiu,
					raio = comBonus(CFG.Q_RAIO) })
				tocarEm("VOLTA", raiz.Position, 1.3)
				tocarEm("CORTINA", ondeSumiu, 0.8)
				for _, quem in ipairs(alvosEm(ondeSumiu,
						comBonus(CFG.Q_RAIO), 12)) do
					aplicarDano(quem, CFG.Q_DANO)
					tombar(quem, CFG.Q_ATORDOA)
					local quemRaiz = raizDe(quem)
					if quemRaiz then
						empurrar(quem, (quemRaiz.Position - ondeSumiu)
							+ Vector3.new(0, 0.5, 0), CFG.Q_EMPURRAO, 0.28)
					end
				end
			end)
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — E  ·  Four Suits Arsenal
--
-- Oito cartas orbitando. Cada CLIQUE dispara um naipe, na ordem, e cada naipe
-- faz uma coisa diferente:
--
--   Espadas  perfura   dano × 1.45, e nenhum empurrão — o alvo fica no lugar
--   Paus     empurra   dano cheio mais impulso forte
--   Ouros    ricocheteia  pega o alvo, depois o próximo mais perto, duas vezes
--   Copas    recupera  dano menor, e devolve vida a quem lançou
--
-- A ordem é FIXA, não sorteada: o jogador precisa poder planejar qual sai. É a
-- diferença entre uma habilidade e uma roleta.
--═══════════════════════════════════════════════════════════════

local ORDEM_NAIPES = { "ESPADAS", "PAUS", "OUROS", "COPAS" }
local proximoNaipe = 0

local function seguirArsenal()
	local minha = novaGeracao("E")
	task.spawn(function()
		local ate = os.clock() + CFG.E_DURACAO
		while geracao.E == minha and os.clock() < ate do
			if not (personagem and raiz and raiz.Parent
					and humanoide and humanoide.Health > 0) then
				break
			end
			vfx("MOVER", { id = arsenalId, posicao = raiz.Position,
				tempo = CFG.E_PASSO })
			task.wait(CFG.E_PASSO)
		end
		if geracao.E == minha then
			apagarEfeito(arsenalId)
			arsenalId = nil
			if armado == "ARSENAL" then armado = nil end
		end
	end)
end

habilidade.E = function(_mira)
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("ARSENAL", despachar({
		CARGA = { sfx = { "ARSENAL", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(arsenalId)
			arsenalId = novoId("ARSENAL")
			proximoNaipe = 0
			armado = "ARSENAL"
			vfx("ARSENAL_ANEL", { posicao = raiz.Position,
				raio = CFG.E_ORBITA, cartas = CFG.E_CARTAS,
				duracao = CFG.E_DURACAO, id = arsenalId })
			tocarEm("ARSENAL", raiz.Position, 1)
			seguirArsenal()
		end },
	}), fecharHabilidade)
end

--- Um tiro do arsenal. Roda no clique, com a sequência curta — a habilidade
--- pesada já aconteceu quando o anel subiu.
local function atirarNaipe(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("DISPARA_NAIPE", despachar({
		CARGA = { sfx = { "NAIPE", 1.1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			proximoNaipe = (proximoNaipe % #ORDEM_NAIPES) + 1
			local naipe = ORDEM_NAIPES[proximoNaipe]
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.E_ALCANCE)

			vfx("NAIPE_ATIRA", { origem = origem, destino = ponto,
				naipe = naipe, voo = CFG.E_VOO })
			tocarEm("NAIPE", ponto, 1.05)

			local raio = comBonus(CFG.E_RAIO)
			if naipe == "ESPADAS" then
				-- perfura: dano maior, e ninguém sai do lugar
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.E_DANO * CFG.E_PERFURA)
				end
			elseif naipe == "PAUS" then
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.E_DANO)
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						empurrar(alvo, (alvoRaiz.Position - origem)
							+ Vector3.new(0, 0.4, 0), CFG.E_EMPURRAO, 0.3)
					end
				end
			elseif naipe == "OUROS" then
				-- ricocheteia: o ponto de cada salto é o alvo já atingido, e
				-- `jaBatidos` impede o quique de voltar em quem já levou
				local jaBatidos = {}
				local ondeEstou = ponto
				local salto = 0
				while salto <= CFG.E_RICOCHETES do
					local achado = nil
					for _, alvo in ipairs(alvosEm(ondeEstou, raio * 2.6, 10)) do
						if not jaBatidos[alvo] then
							achado = alvo
							break
						end
					end
					if not achado then break end
					jaBatidos[achado] = true
					local achadoRaiz = raizDe(achado)
					local proxima = achadoRaiz and achadoRaiz.Position
						or ondeEstou
					if salto > 0 then
						vfx("NAIPE_ATIRA", { origem = ondeEstou,
							destino = proxima, naipe = "OUROS",
							voo = CFG.E_VOO })
					end
					aplicarDano(achado, CFG.E_DANO)
					ondeEstou = proxima
					salto = salto + 1
				end
			else
				-- COPAS: bate menos, e devolve vida
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.E_DANO * 0.7)
				end
				if curar(CFG.E_CURA) > 0 then
					vfx("NAIPE_COPAS_CURA", { posicao = raiz.Position })
				end
			end
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — R  ·  Joker's Labyrinth
--
-- Cartas gigantes cercam a área, EMBARALHAM a posição dos inimigos, e depois
-- se fecham no centro.
--
-- O embaralhar é uma permutação em CICLO: cada um vai para o lugar do
-- seguinte, e o último para o do primeiro. As posições são lidas TODAS antes
-- de qualquer escrita — ler e escrever no mesmo laço faria o segundo aparecer
-- onde o primeiro já não estava.
--═══════════════════════════════════════════════════════════════

habilidade.R = function(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("LABIRINTO", despachar({
		CARGA  = { sfx = { "LABIRINTO", 0.9 } },
		SEGURA = { faz = function()
			local centro = destino or frente(CFG.R_RAIO)
			apagarEfeito(labirintoId)
			labirintoId = novoId("LABIRINTO")
			vfx("LABIRINTO_SOBE", { posicao = centro,
				raio = comBonus(CFG.R_RAIO), paredes = CFG.R_PAREDES,
				duracao = CFG.R_DURACAO, id = labirintoId })
			tocarEm("LABIRINTO", centro, 0.85)
		end },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.R_RAIO)
			local raio = comBonus(CFG.R_RAIO)
			local minha = novaGeracao("R")
			local meu = labirintoId

			-- 1. embaralhar, em ciclo
			local presos = alvosEm(centro, raio, 12)
			local posicoes = {}
			for indice, alvo in ipairs(presos) do
				local alvoRaiz = raizDe(alvo)
				posicoes[indice] = alvoRaiz and alvoRaiz.CFrame or nil
			end
			if #presos >= 2 then
				tocarEm("EMBARALHA", centro, 0.95)
				for indice, alvo in ipairs(presos) do
					local seguinte = (indice % #presos) + 1
					local vaiPara = posicoes[seguinte]
					local alvoRaiz = raizDe(alvo)
					if vaiPara and alvoRaiz then
						vfx("LABIRINTO_EMBARALHA", {
							origem = alvoRaiz.Position,
							destino = vaiPara.Position })
						alvoRaiz.CFrame = CFrame.new(
							vaiPara.Position + Vector3.new(0, 1, 0),
							vaiPara.Position + vaiPara.LookVector)
					end
				end
			end

			-- 2. as paredes se fecham depois da espera
			task.delay(CFG.R_ESPERA, function()
				if geracao.R ~= minha then return end
				vfx("LABIRINTO_FECHA", { posicao = centro, raio = raio,
					id = meu })
				tocarEm("LABIRINTO", centro, 0.7)
				golpearArea(centro, raio, CFG.R_NUCLEO, CFG.R_DANO_FECHA,
					CFG.R_BORDA_FECHA, nil, CFG.R_TOMBO)
				for _, alvo in ipairs(alvosEm(centro, raio, 14)) do
					puxar(alvo, centro, 40, 0.4)
				end
				task.delay(0.4, function()
					if geracao.R ~= minha then return end
					apagarEfeito(meu)
					if labirintoId == meu then labirintoId = nil end
				end)
			end)
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — T  ·  Ace Gate
--
-- Arremessa um Ás. `T` de novo teleporta até a carta. Se o Ás acertou alguém,
-- a chegada é ATRÁS do alvo — `-LookVector` DELE, não do portador: chegar na
-- frente seria só um teleporte, e a habilidade é sobre chegar onde ninguém
-- esperava.
--═══════════════════════════════════════════════════════════════

local function cravarAs(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ACE_GATE", despachar({
		CARGA = { sfx = { "AS", 1.05 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.4, 0)
			local ponto = destino or frente(CFG.T_ALCANCE)
			vfx("AS_VOA", { origem = origem, destino = ponto,
				voo = CFG.T_VOO })

			local minha = novaGeracao("T")
			task.delay(CFG.T_VOO, function()
				if geracao.T ~= minha then return end
				apagarEfeito(asId)
				asId = novoId("AS")
				asOnde = ponto
				vfx("AS_CRAVA", { posicao = ponto, duracao = CFG.T_VIDA_AS,
					id = asId })
				tocarEm("AS", ponto, 0.95)
				for _, alvo in ipairs(alvosEm(ponto, comBonus(CFG.T_RAIO), 8)) do
					aplicarDano(alvo, CFG.T_DANO)
				end
				local meu = asId
				task.delay(CFG.T_VIDA_AS, function()
					if asId ~= meu then return end
					apagarEfeito(meu)
					asId, asOnde = nil, nil
				end)
			end)
		end },
	}), fecharHabilidade)
end

local function usarPortao()
	ocupado = true
	local ponto = asOnde
	rig:PlaySequence("ACE_PORTAO", despachar({
		CARGA = { sfx = { "PORTAO", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent and ponto) then return end
			local partida = raiz.Position
			local alvo = maisPerto(ponto, CFG.T_RAIO * 1.6)
			local alvoRaiz = alvo and raizDe(alvo)
			local chegada = ponto

			if alvoRaiz then
				chegada = alvoRaiz.Position
					- alvoRaiz.CFrame.LookVector * CFG.T_ATRAS
				raiz.CFrame = CFrame.new(chegada + Vector3.new(0, 1, 0),
					alvoRaiz.Position)
				aplicarDano(alvo, CFG.T_DANO_PORTAO)
			else
				raiz.CFrame = CFrame.new(chegada + Vector3.new(0, 3, 0),
					chegada + raiz.CFrame.LookVector)
			end

			vfx("AS_PORTAO", { origem = partida, destino = chegada })
			tocarEm("PORTAO", partida, 0.95)
			tocarEm("PORTAO", chegada, 1.1)
			apagarEfeito(asId)
			asId, asOnde = nil, nil
		end },
	}), fecharHabilidade)
end

habilidade.T = function(mira)
	abrirHabilidade()
	if asOnde then
		usarPortao()
	else
		cravarAs(mira)
	end
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — Y  ·  House Collapse
--
-- `Y` ergue o castelo. O CLIQUE derruba as paredes na direção do mouse,
-- empurrando quem está no corredor, e estoura no centro.
--═══════════════════════════════════════════════════════════════

habilidade.Y = function(_mira)
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("CASTELO", despachar({
		CARGA  = { sfx = { "CASTELO", 0.9 } },
		SEGURA = { sfx = { "CASTELO", 1.05 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(casteloId)
			casteloId = novoId("CASTELO")
			casteloOnde = raiz.Position
			armado = "CASTELO"
			vfx("CASTELO_SOBE", { posicao = casteloOnde,
				andares = CFG.Y_ANDARES, duracao = CFG.Y_DURACAO,
				id = casteloId })
			tocarEm("CASTELO", casteloOnde, 0.85)

			local minha = novaGeracao("Y")
			local meu = casteloId
			task.delay(CFG.Y_DURACAO, function()
				if geracao.Y ~= minha then return end
				apagarEfeito(meu)
				if casteloId == meu then
					casteloId, casteloOnde = nil, nil
					if armado == "CASTELO" then armado = nil end
				end
			end)
		end },
	}), fecharHabilidade)
end

local function derrubarCastelo(mira)
	ocupado = true
	local destino = mira
	local centro = casteloOnde
	local meu = casteloId
	rig:PlaySequence("DESABA", despachar({
		CARGA  = { sfx = { "DESABA", 0.95 } },
		SEGURA = { sfx = { "CASTELO", 0.8 } },
		GOLPE  = { faz = function()
			if not centro then return end
			local ponto = destino or (centro + Vector3.new(0, 0, 1))
			local delta = Vector3.new(ponto.X - centro.X, 0, ponto.Z - centro.Z)
			local dir = (delta.Magnitude > 0.5) and delta.Unit
				or Vector3.new(0, 0, 1)
			local alcance = comBonus(CFG.Y_ALCANCE)

			vfx("CASTELO_DESABA", { posicao = centro, direcao = dir,
				alcance = alcance, id = meu })
			tocarEm("DESABA", centro, 0.85)

			-- o corredor: quem está na faixa entre o castelo e o alcance
			for _, alvo in ipairs(alvosEm(centro, alcance + CFG.Y_LARGURA, 16)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local rel = alvoRaiz.Position - centro
					local aoLongo = rel:Dot(dir)
					local lateral = (rel - dir * aoLongo).Magnitude
					if aoLongo >= -2 and aoLongo <= alcance
							and lateral <= CFG.Y_LARGURA then
						aplicarDano(alvo, CFG.Y_DANO_PAREDE)
						empurrar(alvo, dir + Vector3.new(0, 0.35, 0),
							CFG.Y_EMPURRAO, 0.34)
					end
				end
			end

			-- e o estouro no centro
			golpearArea(centro, comBonus(CFG.Y_RAIO_CENTRO), CFG.Y_RAIO_CENTRO * 0.4,
				CFG.Y_DANO_CENTRO, CFG.Y_BORDA_CENTRO, nil, CFG.Y_TOMBO)

			apagarEfeito(meu)
			if casteloId == meu then casteloId, casteloOnde = nil, nil end
			if armado == "CASTELO" then armado = nil end
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — U  ·  Eclipse Deck
--
-- Uma carta negra abre no céu e marca quem está embaixo. Depois todas as
-- marcas voltam ao centro de uma vez, arrastando quem carrega cada uma.
--
-- A marca guarda o alvo, não a posição: quem foi marcado é puxado de ONDE
-- ESTIVER quando o retorno acontecer. Guardar a posição faria a habilidade
-- premiar quem ficou parado.
--═══════════════════════════════════════════════════════════════

habilidade.U = function(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("ECLIPSE", despachar({
		CARGA  = { sfx = { "ECLIPSE", 0.75 } },
		SEGURA = { sfx = { "ECLIPSE", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = destino or frente(CFG.U_RAIO_MARCA * 0.5)
			local minha = novaGeracao("U")

			apagarEfeito(eclipseId)
			for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
			marcasEclipse = {}

			eclipseId = novoId("ECLIPSE")
			vfx("ECLIPSE_ABRE", { posicao = centro, altura = CFG.U_ALTURA,
				duracao = CFG.U_DURACAO, id = eclipseId })
			tocarEm("ECLIPSE", centro, 0.7)

			local marcados = alvosEm(centro, comBonus(CFG.U_RAIO_MARCA),
				CFG.U_LIMITE)
			for _, alvo in ipairs(marcados) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local id = novoId("MARCA")
					table.insert(marcasEclipse, id)
					vfx("ECLIPSE_MARCA", { posicao = alvoRaiz.Position,
						duracao = CFG.U_ESPERA + 0.4, id = id })
				end
			end

			local meu = eclipseId
			task.delay(CFG.U_ESPERA, function()
				if geracao.U ~= minha then return end
				local onde = {}
				for _, alvo in ipairs(marcados) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz and alvo.Health > 0 then
						table.insert(onde, alvoRaiz.Position)
						puxar(alvo, centro, CFG.U_PUXAO, 0.45)
					end
				end
				vfx("ECLIPSE_RETORNA", { posicao = centro,
					raio = comBonus(CFG.U_RAIO_FINAL), marcados = onde })
				tocarEm("RETORNO", centro, 0.8)

				task.delay(0.45, function()
					if geracao.U ~= minha then return end
					golpearArea(centro, comBonus(CFG.U_RAIO_FINAL),
						CFG.U_NUCLEO, CFG.U_DANO, CFG.U_BORDA, nil,
						CFG.U_TOMBO)
					apagarEfeito(meu)
					for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
					marcasEclipse = {}
					if eclipseId == meu then eclipseId = nil end
				end)
			end)
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — P  ·  Royal Guard
--
-- Quatro Reis de guarda. O CLIQUE lança um para empurrar; `P` de novo faz os
-- quatro baterem no chão. É a única habilidade da Forma 1 que é defesa e
-- ataque na mesma tecla, e por isso a segunda pressão CONSOME a guarda.
--═══════════════════════════════════════════════════════════════

local function seguirGuarda()
	local minha = novaGeracao("P")
	task.spawn(function()
		local ate = os.clock() + CFG.P_DURACAO
		while geracao.P == minha and os.clock() < ate do
			if not (personagem and raiz and raiz.Parent
					and humanoide and humanoide.Health > 0) then
				break
			end
			vfx("MOVER", { id = guardaId, posicao = raiz.Position,
				tempo = 0.3 })
			task.wait(0.3)
		end
		if geracao.P == minha then
			apagarEfeito(guardaId)
			guardaId = nil
			if armado == "GUARDA" then armado = nil end
		end
	end)
end

local function levantarGuarda()
	ocupado = true
	rig:PlaySequence("GUARDA_REAL", despachar({
		CARGA = { sfx = { "GUARDA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(guardaId)
			guardaId = novoId("GUARDA")
			armado = "GUARDA"
			vfx("GUARDA_SOBE", { posicao = raiz.Position,
				raio = CFG.P_ORBITA, duracao = CFG.P_DURACAO, id = guardaId })
			tocarEm("GUARDA", raiz.Position, 1)
			seguirGuarda()
		end },
	}), fecharHabilidade)
end

local function baixarGuarda()
	ocupado = true
	local meu = guardaId
	rig:PlaySequence("REI_BAQUE", despachar({
		CARGA  = { sfx = { "REI", 0.9 } },
		SEGURA = { sfx = { "GUARDA", 0.85 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position
			vfx("GUARDA_BAQUE", { posicao = centro,
				raio = comBonus(CFG.P_RAIO_BAQUE), id = meu })
			tocarEm("REI", centro, 0.85)
			golpearArea(centro, comBonus(CFG.P_RAIO_BAQUE), CFG.P_NUCLEO_BAQUE,
				CFG.P_DANO_BAQUE, CFG.P_BORDA_BAQUE, CFG.P_EMPURRAO * 0.6,
				CFG.P_TOMBO)
			novaGeracao("P")
			apagarEfeito(meu)
			if guardaId == meu then guardaId = nil end
			if armado == "GUARDA" then armado = nil end
		end },
	}), fecharHabilidade)
end

habilidade.P = function(_mira)
	abrirHabilidade()
	if guardaId then
		baixarGuarda()
	else
		levantarGuarda()
	end
end

local function lancarRei(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("REI_LANCA", despachar({
		CARGA = { sfx = { "REI", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.P_ALCANCE)
			vfx("GUARDA_LANCA", { origem = origem, destino = ponto,
				voo = CFG.P_VOO })
			tocarEm("REI", ponto, 1.05)
			for _, alvo in ipairs(alvosEm(ponto, comBonus(CFG.P_RAIO_REI), 10)) do
				aplicarDano(alvo, CFG.P_DANO_REI)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - origem)
						+ Vector3.new(0, 0.4, 0), CFG.P_EMPURRAO, 0.32)
				end
			end
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — G  ·  Wyrm Sparks
--═══════════════════════════════════════════════════════════════

habilidade.G = function(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("WYRM", despachar({
		CARGA = { sfx = { "WYRM", 1.15 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.G_ALCANCE)
			local i = 1
			while i <= CFG.G_CABECAS do
				local indice = i
				task.delay(indice * CFG.G_INTERVALO, function()
					if not personagem then return end
					local ang = anguloDe(indice)
					-- a cabeça PERSEGUE: se há alvo perto do ponto, ela ajusta
					local perto = maisPerto(ponto, CFG.G_ESPALHA * 3)
					local pertoRaiz = perto and raizDe(perto)
					local chegada = pertoRaiz and pertoRaiz.Position
						or (ponto + Vector3.new(
							math.cos(ang) * CFG.G_ESPALHA, 0,
							math.sin(ang) * CFG.G_ESPALHA))

					vfx("WYRM_VOA", { origem = origem, destino = chegada,
						voo = CFG.G_VOO })
					task.delay(CFG.G_VOO, function()
						if not personagem then return end
						tocarEm("WYRM", chegada, 1.1)
						for _, alvo in ipairs(alvosEm(chegada,
								comBonus(CFG.G_RAIO), 8)) do
							aplicarDano(alvo, CFG.G_DANO)
						end
						-- a marca flamejante que fica no chão
						local id = novoId("MARCA_WYRM")
						vfx("WYRM_MARCA", { posicao = chegada,
							raio = CFG.G_MARCA_RAIO,
							duracao = CFG.G_MARCA_VIDA, id = id })
						local ate = os.clock() + CFG.G_MARCA_VIDA
						task.spawn(function()
							while os.clock() < ate do
								if not personagem then break end
								for _, alvo in ipairs(alvosEm(chegada,
										CFG.G_MARCA_RAIO, 8)) do
									aplicarDano(alvo, CFG.G_MARCA_DANO)
								end
								task.wait(CFG.G_MARCA_PASSO)
							end
							apagarEfeito(id)
						end)
					end)
				end)
				i = i + 1
			end
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — H  ·  Crown of Cinders
--═══════════════════════════════════════════════════════════════

habilidade.H = function(_mira)
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("COROA_BRASAS", despachar({
		CARGA = { sfx = { "COROA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local minha = novaGeracao("H")
			apagarEfeito(coroaId)

			coroaId = novoId("COROA")
			local meu = coroaId
			coroaOnde = raiz.Position
			armado = "COROA"
			vfx("COROA_SOL", { posicao = raiz.Position, altura = CFG.H_ALTURA,
				duracao = CFG.H_DURACAO, id = meu })
			tocarEm("COROA", raiz.Position, 0.95)

			task.delay(CFG.H_DURACAO, function()
				if geracao.H ~= minha then return end
				apagarEfeito(meu)
				if coroaId == meu then coroaId, coroaOnde = nil, nil end
				if armado == "COROA" then armado = nil end
			end)
		end },
	}), fecharHabilidade)
end

local function estilhacarCoroa(mira)
	ocupado = true
	local destino = mira
	local sol = coroaOnde
	local meu = coroaId
	rig:PlaySequence("BRASAS_CAEM", despachar({
		CARGA  = { sfx = { "COROA", 0.85 } },
		SEGURA = { sfx = { "BRASA", 1 } },
		GOLPE  = { faz = function()
			local origem = (sol or (raiz and raiz.Position) or Vector3.new())
				+ Vector3.new(0, CFG.H_ALTURA, 0)
			local ponto = destino or frente(CFG.H_ALCANCE)
			local i = 1
			while i <= CFG.H_FRAGMENTOS do
				local indice = i
				task.delay(indice * CFG.H_INTERVALO, function()
					if not personagem then return end
					local ang = anguloDe(indice)
					local raioQueda = CFG.H_ESPALHA * (indice / CFG.H_FRAGMENTOS)
					local chegada = ponto + Vector3.new(
						math.cos(ang) * raioQueda, 0,
						math.sin(ang) * raioQueda)
					vfx("COROA_FRAGMENTO", { origem = origem,
						destino = chegada, voo = CFG.H_VOO })
					task.delay(CFG.H_VOO, function()
						if not personagem then return end
						tocarEm("BRASA", chegada, 0.9)
						golpearArea(chegada, comBonus(CFG.H_RAIO),
							CFG.H_NUCLEO, CFG.H_DANO, CFG.H_BORDA,
							CFG.H_EMPURRAO, nil, 10)
					end)
				end)
				i = i + 1
			end
			apagarEfeito(meu)
			if coroaId == meu then coroaId, coroaOnde = nil, nil end
			if armado == "COROA" then armado = nil end
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — J  ·  Dragon's Requiem
--
-- SEGURAR carrega, soltar dispara. A carga é um prazo com TETO: a Tool largada
-- no chão, ou o cliente que some sem mandar o `End`, não deixa carga rodando
-- para sempre. Foi exatamente o defeito da Esfera da versão anterior.
--
-- O sopro é CURVADO. O arco é calculado aqui, no servidor, porque é ele que
-- define quem é atingido — deixar a curva no cliente seria deixar a hitbox com
-- quem pode mentir.
--═══════════════════════════════════════════════════════════════

local cargaRequiem = nil

local function pararRequiem()
	cargaRequiem = nil
	novaGeracao("J")
	apagarEfeito(requiemId)
	requiemId = nil
end

local function comecarRequiem()
	abrirHabilidade()
	ocupado = true
	cargaRequiem = os.clock()
	apagarEfeito(requiemId)
	requiemId = novoId("REQUIEM")
	local minha = novaGeracao("J")

	if raiz then
		vfx("REQUIEM_CARGA", { posicao = raiz.Position,
			duracao = CFG.J_CARGA_MAX + 0.4, id = requiemId })
		tocarEm("REQUIEM", raiz.Position, 0.8)
	end
	rig:PlaySequence("REQUIEM_CARGA", despachar({
		CARGA  = { sfx = { "REQUIEM", 0.9 } },
		SEGURA = { faz = function()
			if raiz then
				vfx("MOVER", { id = requiemId, posicao = raiz.Position,
					tempo = 0.3 })
			end
		end },
	}), function()
		-- A animação de carga acabou. Três desfechos, e nenhum deles pode
		-- deixar `ocupado` errado:
		--   geração mudou  -> `soltarRequiem` já assumiu; não tocar em nada
		--   ainda segurando -> segue `ocupado`, e o teto abaixo dispara
		--   já soltou      -> libera
		if geracao.J ~= minha then return end
		if not cargaRequiem then ocupado = false end
	end)

	-- TETO: se o `End` nunca chegar, o sopro sai sozinho no máximo
	task.delay(CFG.J_CARGA_MAX + 0.15, function()
		if geracao.J ~= minha or not cargaRequiem then return end
		if habilidade.J_soltar then habilidade.J_soltar(nil) end
	end)
end

local function soltarRequiem(mira)
	if not cargaRequiem then return end
	local carregado = math.min(os.clock() - cargaRequiem, CFG.J_CARGA_MAX)
	local t = carregado / CFG.J_CARGA_MAX
	cargaRequiem = nil
	-- corta a geração ANTES de qualquer coisa: o callback da sequência de
	-- carga ainda vai disparar, e sem este corte ele apagaria o `ocupado` do
	-- sopro que está começando agora.
	novaGeracao("J")
	apagarEfeito(requiemId)
	requiemId = nil

	ocupado = true
	local destino = mira
	rig:PlaySequence("REQUIEM_SOPRO", despachar({
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local alcance = CFG.J_ALCANCE_MIN
				+ (CFG.J_ALCANCE_MAX - CFG.J_ALCANCE_MIN) * t
			local largura = CFG.J_LARGURA_MIN
				+ (CFG.J_LARGURA_MAX - CFG.J_LARGURA_MIN) * t
			local dano = CFG.J_DANO_MIN + (CFG.J_DANO_MAX - CFG.J_DANO_MIN) * t

			local origem = raiz.Position + Vector3.new(0, 2.4, 0)
			local ponto = destino or frente(alcance)
			local reto = ponto - origem
			if reto.Magnitude < 1 then reto = raiz.CFrame.LookVector * alcance end
			local dir = reto.Unit
			-- o lado para onde a curva desvia: o RightVector do portador. É o
			-- que faz o sopro ser "curvado" e não só longo.
			local lado = Vector3.new(-dir.Z, 0, dir.X)

			local arco = {}
			local i = 1
			while i <= CFG.J_NOS do
				local passo = i / CFG.J_NOS
				local desvio = math.sin(passo * math.pi) * CFG.J_CURVA
					* alcance * 0.35
				table.insert(arco, origem + dir * (alcance * passo)
					+ lado * desvio)
				i = i + 1
			end

			vfx("REQUIEM_SOPRO", { arco = arco, largura = largura })
			tocarEm("REQUIEM", ponto, 0.75)

			local jaBatidos = {}
			for _, onde in ipairs(arco) do
				for _, alvo in ipairs(alvosEm(onde, comBonus(largura), 12)) do
					if not jaBatidos[alvo] then
						jaBatidos[alvo] = true
						aplicarDano(alvo, dano)
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							empurrar(alvo, dir + Vector3.new(0, 0.3, 0),
								CFG.J_EMPURRAO, 0.3)
						end
					end
				end
			end
		end },
	}), fecharHabilidade)
end

habilidade.J = comecarRequiem
habilidade.J_soltar = soltarRequiem

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — K  ·  Xester Prism
--
-- Três máscaras disparam feixes que se cruzam no ponto do mouse, e o jogador
-- MOVE o ponto durante alguns segundos. A mira nova chega pelo `AcaoRemote`
-- com a tecla `K_MIRA`, que só é aceita enquanto o prisma está de pé.
--═══════════════════════════════════════════════════════════════

local prismaAlvo = nil

habilidade.K = function(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("PRISMA", despachar({
		CARGA  = { sfx = { "PRISMA", 1 } },
		SEGURA = { sfx = { "PRISMA", 1.15 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(prismaId)
			prismaId = novoId("PRISMA")
			prismaAlvo = destino or frente(CFG.K_ALCANCE * 0.5)
			local meu = prismaId
			local minha = novaGeracao("K")

			vfx("PRISMA_MASCARAS", { posicao = raiz.Position,
				raio = CFG.K_RAIO_MASCARA, altura = CFG.K_ALTURA,
				duracao = CFG.K_DURACAO, id = meu })
			tocarEm("PRISMA", raiz.Position, 1)

			task.spawn(function()
				local ate = os.clock() + CFG.K_DURACAO
				while geracao.K == minha and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local ponto = prismaAlvo or frente(CFG.K_ALCANCE * 0.5)
					vfx("PRISMA_MIRA", { posicao = ponto, id = meu })
					for _, alvo in ipairs(alvosEm(ponto,
							comBonus(CFG.K_RAIO), 10)) do
						aplicarDano(alvo, CFG.K_DANO)
						afrouxar(alvo, CFG.K_LENTIDAO, CFG.K_PASSO * 2)
					end
					task.wait(CFG.K_PASSO)
				end
				if geracao.K == minha then
					local ponto = prismaAlvo or frente(CFG.K_ALCANCE * 0.5)
					vfx("PRISMA_ESTOURA", { posicao = ponto })
					apagarEfeito(meu)
					if prismaId == meu then prismaId = nil end
					prismaAlvo = nil
				end
			end)
		end },
	}), fecharHabilidade)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — L  ·  The Final Page of Heaven
--
-- A ultimate. Ela PARA os inimigos da área, o jogador escolhe três pontos com
-- o clique, e quando o tempo volta o dragão celestial atravessa os três de uma
-- vez com o dano acumulado.
--
-- "Dano acumulado" é literal: cada ponto guarda quem estava nele, e o dano
-- final de cada alvo cresce com o número de pontos que o pegaram. Quem for
-- pego pelos três leva três vezes — e é essa a recompensa por mirar bem.
--
-- A janela de escolha tem TETO. Sem ele, o jogador que abre a ultimate e não
-- clica deixa os inimigos presos indefinidamente.
--═══════════════════════════════════════════════════════════════

local presosPagina = {}

local function fecharPagina()
	novaGeracao("L")
	for _, id in ipairs(pontosId) do apagarEfeito(id) end
	pontosId, pontosPagina, presosPagina = {}, {}, {}
	if armado == "PAGINA" then armado = nil end
end

local function dispararPagina()
	local rota = {}
	for _, onde in ipairs(pontosPagina) do table.insert(rota, onde) end
	local guardados = presosPagina
	fecharPagina()

	ocupado = true
	rig:PlaySequence("CENA_PAGINA", despachar({
		PARA    = { cam = true, sfx = { "PAGINA", 0.9 } },
		RELOGIO = { cam = true, sfx = { "ECO", 0.85 } },
		QUEBRA  = { cam = true, sfx = { "PAGINA", 0.75 }, faz = function()
			if raiz then
				vfx("PAGINA_RELOGIO", { posicao = raiz.Position,
					altura = 30, duracao = 1.2 })
			end
		end },
		VOLTA   = { cam = true, faz = function()
			vfx("PAGINA_DRAGAO", { rota = rota })
			for _, onde in ipairs(rota) do
				tocarEm("ECO", onde, 0.8)
			end
			-- o dano acumulado: quem foi pego por mais de um ponto leva por
			-- cada um. `contados` guarda quantas vezes.
			local contados = {}
			for _, onde in ipairs(rota) do
				for _, alvo in ipairs(alvosEm(onde,
						comBonus(CFG.L_RAIO_PONTO), 16)) do
					contados[alvo] = (contados[alvo] or 0) + 1
				end
			end
			for alvo, quantos in pairs(contados) do
				local vez = 1
				while vez <= quantos do
					aplicarDano(alvo, CFG.L_DANO_PONTO)
					vez = vez + 1
				end
				tombar(alvo, CFG.L_TOMBO)
			end
			-- e quem estava preso e escapou da rota ainda leva a borda
			for _, alvo in ipairs(guardados) do
				if alvo and alvo.Parent and alvo.Health > 0
						and not contados[alvo] then
					aplicarDano(alvo, CFG.L_BORDA_PONTO)
				end
			end
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
	comecarCena("PAGINA")
end

habilidade.L = function(_mira)
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("PAGINA_FINAL", despachar({
		CARGA  = { sfx = { "PAGINA", 0.85 } },
		SEGURA = { sfx = { "ECO", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			fecharPagina()
			local centro = raiz.Position
			local minha = novaGeracao("L")
			armado = "PAGINA"

			vfx("PAGINA_PARA", { posicao = centro,
				raio = comBonus(CFG.L_RAIO_PARADA) })
			tocarEm("PAGINA", centro, 0.8)

			presosPagina = alvosEm(centro, comBonus(CFG.L_RAIO_PARADA), 16)
			for _, alvo in ipairs(presosPagina) do
				prender(alvo, CFG.L_PARADA)
				afrouxar(alvo, 0.1, CFG.L_PARADA)
			end

			-- TETO da janela: sem ele, quem abre e não clica prende para sempre
			task.delay(CFG.L_JANELA, function()
				if geracao.L ~= minha then return end
				if #pontosPagina > 0 then
					dispararPagina()
				else
					fecharPagina()
				end
			end)
		end },
	}), fecharHabilidade)
end

local function marcarPontoPagina(mira)
	if not (raiz and raiz.Parent) then return end
	local ponto = mira or frente(CFG.L_ALCANCE * 0.5)
	table.insert(pontosPagina, ponto)
	local id = novoId("PONTO")
	table.insert(pontosId, id)
	vfx("PAGINA_PONTO", { posicao = ponto, duracao = CFG.L_JANELA + 1,
		id = id })
	tocarEm("PAGINA", ponto, 1.1 + #pontosPagina * 0.08)
	if #pontosPagina >= CFG.L_PONTOS then
		dispararPagina()
	end
end

--═══════════════════════════════════════════════════════════════
-- F — a troca de forma
--
-- A cutscene É a sequência de animação: os beats saem do `Poses.lua` e viram
-- beat de câmera pelo `cam = true`. Quem manda o `FIM` é o callback do fim da
-- sequência, não um `task.wait` paralelo que poderia dessincronizar dela.
--═══════════════════════════════════════════════════════════════

local function virarForma2()
	ocupado = true
	limparTudo()
	comecarCena("TRANSFORMAR")
	local onde = raiz and raiz.Position or Vector3.new()

	rig:PlaySequence("TRANSFORMAR", despachar({
		MAO     = { cam = true, faz = function()
			vfx("CENA_MAO", { posicao = raiz and raiz.Position or onde })
		end },
		NAIPES  = { cam = true, sfx = { "NAIPES", 0.8 }, faz = function()
			vfx("CENA_NAIPES", { posicao = raiz and raiz.Position or onde })
		end },
		CORINGA = { cam = true, sfx = { "QUEIMA", 0.95 }, faz = function()
			vfx("CENA_CORINGA", { posicao = raiz and raiz.Position or onde })
		end },
		CONGELA = { cam = true, faz = function()
			vfx("CENA_CONGELA", { posicao = raiz and raiz.Position or onde })
		end },
		RASGA   = { cam = true, sfx = { "RASGA", 1.1 }, faz = function()
			vfx("CENA_RASGA", { posicao = raiz and raiz.Position or onde })
			porCajado()
			vfx("CAJADO_ACENDE", { posicao = raiz and raiz.Position or onde })
		end },
		TITULO  = { cam = true, sfx = { "TITULO", 1 }, faz = function()
			local aqui = raiz and raiz.Position or onde
			vfx("CENA_TITULO", { posicao = aqui })
			tocarEm("TITULO", aqui, 0.95)
			forma = 2
			armado = nil
			apagarEfeito(auraId)
			auraId = novoId("AURA")
			vfx("AURA_DRAGAO", { posicao = aqui, id = auraId })
			-- o cliente precisa saber a forma para trocar os binds e os botões
			AcaoRemote:FireClient(jogador, "FORMA", 2)
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
end

local function voltarForma1()
	ocupado = true
	limparTudo()
	comecarCena("REVERTER")
	local onde = raiz and raiz.Position or Vector3.new()

	rig:PlaySequence("REVERTER", despachar({
		ABSORVE = { cam = true, sfx = { "FECHA", 0.9 }, faz = function()
			vfx("CENA_ABSORVE", { posicao = raiz and raiz.Position or onde })
		end },
		APAGA   = { cam = true, faz = function()
			vfx("CENA_APAGA", { posicao = raiz and raiz.Position or onde })
			tirarCajado()
			apagarEfeito(auraId)
			auraId = nil
		end },
		FECHA   = { cam = true, sfx = { "FECHA", 1.05 }, faz = function()
			local aqui = raiz and raiz.Position or onde
			vfx("CENA_FECHA", { posicao = aqui })
			tocarEm("FECHA", aqui, 1)
			forma = 1
			armado = nil
			usosDaForma1 = 0
			AcaoRemote:FireClient(jogador, "FORMA", 1)
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
end

habilidade.F = function(_mira)
	if forma == 1 then
		virarForma2()
	else
		voltarForma1()
	end
end

--═══════════════════════════════════════════════════════════════
-- M1 — `Tool.Activated`, e o despacho contextual
--═══════════════════════════════════════════════════════════════

local function golpeSimples(mira)
	ocupado = true
	local destino = mira
	local quente = forma == 2
	rig:PlaySequence(quente and "CHAMA_SIMPLES" or "CARTA_SIMPLES", despachar({
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.2, 0)
			local ponto = destino or frente(20)
			vfx("GOLPE_SIMPLES", { origem = origem, destino = ponto,
				quente = quente })
			tocarEm(quente and "WYRM" or "NAIPE", ponto, quente and 1.3 or 1.2)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_M1, 6)) do
				aplicarDano(alvo, CFG.DANO_M1)
			end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if armado == "ARSENAL" and arsenalId then
		atirarNaipe(mira)
	elseif armado == "CASTELO" and casteloId and forma == 1 then
		derrubarCastelo(mira)
	elseif armado == "COROA" and coroaId and forma == 2 then
		estilhacarCoroa(mira)
	elseif armado == "GUARDA" and guardaId then
		lancarRei(mira)
	elseif armado == "PAGINA" then
		marcarPontoPagina(mira)
	else
		golpeSimples(mira)
	end
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

--- Quais teclas valem em cada forma. Tecla de outra forma é descartada sem
--- resposta: confiar no cliente para dizer qual habilidade rodar seria dar a
--- ele a escolha da recarga também.
local TECLAS = {
	[1] = { Q = true, E = true, R = true, T = true, Y = true, U = true,
		P = true, F = true },
	[2] = { G = true, H = true, J = true, K = true, L = true, F = true },
}

local RECARGA = {
	Q = CFG.Q_RECARGA, E = CFG.E_RECARGA, R = CFG.R_RECARGA,
	T = CFG.T_RECARGA, Y = CFG.Y_RECARGA, U = CFG.U_RECARGA,
	P = CFG.P_RECARGA, F = CFG.F_RECARGA, G = CFG.G_RECARGA,
	H = CFG.H_RECARGA, J = CFG.J_RECARGA, K = CFG.K_RECARGA,
	L = CFG.L_RECARGA,
}

--- A segunda pressão de `T` e de `P` NÃO paga recarga nova: ela é a metade de
--- trás da mesma habilidade. Cobrar duas vezes faria o portão e o baque serem
--- inalcançáveis na prática.
local function segundaPressao(tecla)
	if tecla == "T" and asOnde then return true end
	if tecla == "P" and guardaId then return true end
	return false
end

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
	if typeof(mira) ~= "Vector3" then mira = frente(20) end
	-- a marcação de ponto da ultimate não paga a recarga do M1: são três
	-- cliques seguidos de propósito, e o teto é `L_PONTOS`.
	if armado ~= "PAGINA" then
		if not pronto(ultimoM1, CFG.RECARGA_M1) then return end
		ultimoM1 = os.clock()
	end
	primaria(mira)
end)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira, fase)
	if quem ~= jogador then return end
	if typeof(mira) ~= "Vector3" then mira = frente(20) end

	-- a mira móvel do Prisma chega o tempo todo, e não é uma habilidade:
	-- ela não passa por `podeAgir` nem por recarga.
	if tecla == "K_MIRA" then
		if prismaId then prismaAlvo = mira end
		return
	end

	-- soltar o Requiem tem de passar mesmo com `ocupado`: a carga É o estado
	-- ocupado, e exigir que ele acabe tornaria a habilidade impossível.
	if tecla == "J" and fase == "End" then
		if forma == 2 and cargaRequiem then
			soltarRequiem(mira)
		end
		return
	end

	if not podeAgir() then return end
	local permitidas = TECLAS[forma]
	if not (permitidas and permitidas[tecla]) then return end
	local fn = habilidade[tecla]
	if not fn then return end

	if segundaPressao(tecla) then
		fn(mira)
		return
	end

	local recarga = RECARGA[tecla]
	if recarga and not pronto(ultimo[tecla] or -recarga, recarga) then return end
	ultimo[tecla] = os.clock()
	fn(mira)
end)

function aoEquipar()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then return end

	rig = Animator.new(personagem, "XesterV2", Poses, Poses.SEQUENCIAS,
		Poses.TRACKS)

	-- a Tool volta para a mão na forma em que estava. Se for a 2, o cajado e a
	-- aura voltam junto — a forma é estado da Tool, não da sessão.
	AcaoRemote:FireClient(jogador, "FORMA", forma)
	if forma == 2 then
		porCajado()
		apagarEfeito(auraId)
		auraId = novoId("AURA")
		vfx("AURA_DRAGAO", { posicao = raiz.Position, id = auraId })
	end

	-- morte devolve tudo: câmera, invisibilidade e efeito com prazo
	guardar(humanoide.Died:Connect(function()
		limparTudo()
		tirarCajado()
	end))
end

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência, e é aí que a câmera ficaria presa.
function aoGuardar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	bonusAtivo = false
	cargaRequiem = nil
	prismaAlvo = nil
	limparTudo()
	tirarCajado()
	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)
Tool.Destroying:Connect(aoGuardar)
