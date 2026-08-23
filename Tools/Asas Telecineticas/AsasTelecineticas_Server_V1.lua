-- AsasTelecineticas_Server_V1.lua
-- Script de servidor — Asas Telecineticas  (conjunto GRAVIDADE)
--
-- Sai do `reality_tools.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_reality.py` para o mapa.
--
--   M1   bate as asas: sobe e empurra quem estiver perto   (a habilidade que a origem ja tinha)
--   R    Mergulho   (Extra 1)
--   T    Planar   (Extra 2)
--   Y    Vendaval   (Extra 3)
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "TELECINESE"

local CFG = {
	ALCANCE       = 8,
	IMPULSO_CIMA  = 78,
	IMPULSO_FRENTE = 46,
	RAIO_SOPRO    = 14,
	DANO_SOPRO    = 12,
	EMPURRAO      = 62,
	RECARGA       = 5,

	RECARGA_R     = 12,
	ALTURA_SUBIDA = 34,
	FORCA_MERGULHO = 190,
	RAIO_MERGULHO = 17,
	DANO_MERGULHO = 42,
	RECARGA_T      = 13,
	DURACAO_PLANO  = 5,
	PASSO_PLANO    = 0.35,
	SUSTENTO_PLANO = 3.2,
	VELOCIDADE_PLANO = 1.5,

	RECARGA_Y      = 17,
	ALCANCE_VENTO  = 40,
	LARGURA_VENTO  = 12,
	DANO_VENTO     = 24,
	FORCA_VENTO    = 130,
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
local impulsoAtivo = nil
local planandoAte = 0

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
-- PRIMÁRIA — a batida de asa
--
-- Sobe o portador e empurra quem está perto. O impulso do PRÓPRIO portador é
-- guardado: se a Tool sumir no meio, `desmontar()` o tira — corpo de força
-- pendurado num personagem é estado que vaza.
--═══════════════════════════════════════════════════════════════

local function impulsionar(direcao, forca, tempo)
	if impulsoAtivo then impulsoAtivo.Parent = nil end
	impulsoAtivo = Instance.new("BodyVelocity")
	impulsoAtivo.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulsoAtivo.Velocity = direcao.Unit * forca
	impulsoAtivo.Parent = raiz
	Debris:AddItem(impulsoAtivo, tempo)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BATIDA", despachar({
		ABRE = { faz = function()
			tocar("ScifiLiftSound", 1.2)
		end },
		BATE = { faz = function()
			tocar("ScifiBlastSound", 1.05)
			impulsionar(Vector3.new(0, CFG.IMPULSO_CIMA, 0)
				+ raiz.CFrame.LookVector * CFG.IMPULSO_FRENTE, 1, 0.3)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1.2 })
			for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SOPRO, 10)) do
				aplicarDano(alvo, CFG.DANO_SOPRO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.22)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o mergulho
--
-- Sobe, segura, e desce com peso. É a sequência com mais quadro segurado do
-- conjunto depois do ultimate — a regra 7 vale para o alto também: o instante
-- parado no ar é o que vende a queda.
--═══════════════════════════════════════════════════════════════

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("MERGULHO", despachar({
		ERGUE = { faz = function()
			tocar("ScifiLiftSound", 0.85)
			impulsionar(Vector3.new(0, CFG.ALTURA_SUBIDA, 0), 1, 0.45)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1 })
		end },
		DESCE = { faz = function()
			tocar("ScifiBlastSound", 0.75)
			impulsionar(Vector3.new(0, -1, 0), CFG.FORCA_MERGULHO, 0.35)
		end },
		IMPACTO = { faz = function()
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("MERGULHO", { posicao = chao, escala = 1.4 })
			tocarEm("Bam", chao, 0.8)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_MERGULHO, 12)) do
				aplicarDano(alvo, CFG.DANO_MERGULHO)
				tombar(alvo, 1.6)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - chao)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO * 1.4, 0.28)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--- T — PLANAR: queda lenta e passo mais rápido, por prazo.
---
--- A queda lenta é um empurrão para cima FRACO e repetido — 3.2 contra os ~196
--- da gravidade do jogo. Ele não levanta: ele segura. E de novo, `workspace.
--- Gravity` não é tocado.
function extraT(_mira)
	ocupado = true
	rig:PlaySequence("PLANAR", despachar({
		ABRE  = { sfx = { "EquipSound", 1.15 } },
		PLANA = { faz = function()
			if not (personagem and humanoide and raiz) then return end
			planandoAte = os.clock() + CFG.DURACAO_PLANO
			local minha = novaGeracao("T")
			vfx("ASA", { posicao = raiz.Position, escala = 1.1 })
			tocar("ScifiLiftSound", 1.2)
			afrouxar(humanoide, CFG.VELOCIDADE_PLANO, CFG.DURACAO_PLANO)

			task.spawn(function()
				while geracao.T == minha and os.clock() < planandoAte do
					if not (personagem and raiz and raiz.Parent
							and humanoide and humanoide.Health > 0) then
						break
					end
					-- só segura QUEM ESTÁ CAINDO: empurrar para cima quem já
					-- sobe viraria voo infinito
					if raiz.AssemblyLinearVelocity.Y < 0 then
						local freio = Instance.new("BodyVelocity")
						freio.MaxForce = Vector3.new(0, 1e5, 0)
						freio.Velocity = Vector3.new(0, -CFG.SUSTENTO_PLANO, 0)
						freio.Parent = raiz
						Debris:AddItem(freio, CFG.PASSO_PLANO)
					end
					task.wait(CFG.PASSO_PLANO)
				end
			end)
		end },
	}), function() ocupado = false end)
end

--- Y — VENDAVAL: uma batida de asa que empurra tudo à frente, num corredor.
---
--- Projeção no eixo mais distância lateral, não um raio: um raio pegaria quem
--- está atrás, e a habilidade é direcional.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("VENDAVAL", despachar({
		ERGUE  = { sfx = { "EquipSound", 0.8 } },
		SEGURA = { sfx = { "Bam", 0.9 } },
		SOPRA  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local ponto = destino or frente(CFG.ALCANCE_VENTO)
			local delta = Vector3.new(ponto.X - origem.X, 0, ponto.Z - origem.Z)
			local dir = (delta.Magnitude > 0.5) and delta.Unit
				or raiz.CFrame.LookVector

			vfx("ASA", { posicao = origem, escala = 1.6 })
			vfx("PULSO", { posicao = origem + dir * 6, escala = 1.3 })
			tocarEm("ScifiBlastSound", origem, 0.85)

			for _, alvo in ipairs(alvosEm(origem,
					CFG.ALCANCE_VENTO + CFG.LARGURA_VENTO, 16)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local rel = alvoRaiz.Position - origem
					local aoLongo = rel:Dot(dir)
					local lateral = (rel - dir * aoLongo).Magnitude
					if aoLongo >= -2 and aoLongo <= CFG.ALCANCE_VENTO
							and lateral <= CFG.LARGURA_VENTO then
						aplicarDano(alvo, CFG.DANO_VENTO)
						empurrar(alvo, dir + Vector3.new(0, 0.45, 0),
							CFG.FORCA_VENTO, 0.34)
					end
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

	rig = Animator.new(personagem, "GravAsas", Poses,
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
