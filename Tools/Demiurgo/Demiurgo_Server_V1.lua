-- Demiurgo_Server_V1.lua
-- Script de servidor — Demiurgo  (conjunto CRIAÇÃO)
--
--   M1   Molde do Mundo
--   R    Continente   (Extra 1)
--   T    Criacao   (Extra 2)
--
--   Handle autoral: mundo pequeno com oceano de vidro e compasso
--   MOLDE_MUNDO 2836888600 (summoning) · CONTINENTE 165969964
--   (Explosion) · CRIACAO 18872474050 (Supernova) — do catalogo
--
-- CONJUNTO AUTORAL
--
--   O CRIAÇÃO não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega. A
--   geometria do Handle é primitiva soldada, e a lógica é escrita aqui.
--
-- A REGRA DESTE ARQUIVO: TUDO QUE É CRIADO É RECOLHIDO
--
--   Esta é a primeira Tool do repositório que põe no mundo `Part` DE
--   SERVIDOR — coisa colidível, com que todo mundo esbarra. Todo conjunto
--   anterior punha só VFX, que é do cliente e some sozinho.
--
--   Peça de servidor que fica é lixo permanente no mapa. Por isso NADA é
--   criado fora de `criar()`, que registra a peça com prazo, e o registro tem
--   TRÊS saídas: o prazo, o `Unequipped` e o `Destroying`. E tem TETO, porque
--   sem ele um jogador ergue trinta muralhas e todas ficam.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_criacao.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito   = require(Tool:WaitForChild("DepositoVFX"))
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	ALCANCE       = 20,
	RECARGA       = 1.2,
	ABERTURA      = 70,
	COSSENO       = 0.34,
	DANO          = 34,
	EMPURRAO      = 60,

	RECARGA_R     = 20,
	PLACAS        = 5,
	RAIO_CONT     = 30,
	VIDA_PLACA    = 12,
	LEVANTA       = 82,
	DANO_CONT     = 30,
	TOMBO         = 1.2,

	RECARGA_T     = 44,
	RAIO_FIM      = 52,
	NUCLEO_FIM    = 20,
	DANO_FIM      = 175,
	BORDA_FIM     = 60,
	EMPURRAO_FIM  = 150,
	TOMBO_FIM     = 2.4,
	PLACAS_FIM    = 10,
	VIDA_FIM      = 14,
	RAIO_CENA     = 58,
	TETO_CRIADAS  = 18,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT


local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function anguloDe(i)
	return (i or proximo()) * 2.399963
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

--═══════════════════════════════════════════════════════════════
-- SOM — mora em `Tool/SFX/`, três por Tool
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	achado = Handle:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
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

--- Toca numa ÂNCORA PRÓPRIA. Um `Sound` só toca enquanto tem pai no
--- DataModel, e a peça que congela é exatamente a que pode sumir.
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

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- `TakeDamage` respeita `ForceField`; escrever em `Health` fura. A tag
-- `creator` é o que credita o abate, e o `Name` vem ANTES do `Parent`.
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
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

--- Alvos num raio, por consulta espacial sob demanda.
---
--- A ORIGEM VARRIA `workspace:GetDescendants()` em três lugares. Num mapa de
--- verdade isso é o place inteiro por chamada, e ela ancorava tudo o que
--- achasse — inclusive o cenário de quem não estava na briga.
local function alvosEm(posicao, raio, limite)
	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum ~= humanoide and not vistos[hum] then
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
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE)
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

local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um arco para a frente acerta quem está atrás de quem o traçou.
local function alvosNoCone(origem, direcao, alcance, cosseno, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(origem, alcance, (limite or 12) * 2)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - origem
			if delta.Magnitude > 0.01
					and delta.Unit:Dot(direcao.Unit) >= cosseno then
				table.insert(achados, alvo)
				if #achados >= (limite or 12) then break end
			end
		end
	end
	return achados
end

--- Alvos ao longo de uma RETA. É o que o traço precisa: quem está NO CAMINHO,
--- não quem está perto do ponto final.
local function alvosNaReta(origem, direcao, alcance, largura, limite)
	local achados, vistos = {}, {}
	local passo = math.max(largura * 0.8, 2)
	local andado = 0
	while andado <= alcance do
		local onde = origem + direcao.Unit * andado
		for _, alvo in ipairs(alvosEm(onde, largura, limite or 12)) do
			if not vistos[alvo] then
				vistos[alvo] = true
				table.insert(achados, alvo)
			end
		end
		andado = andado + passo
	end
	return achados
end

--- O chão sob um ponto mirado.
---
--- NUM CONJUNTO QUE CONSTRÓI, ISTO NÃO É DETALHE. Uma muralha que nasce na
--- altura do mouse fica boiando, e o jogador não entende por que ela não
--- bloqueia nada. Toda peça deste conjunto assenta no chão.
local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(ponto + Vector3.new(0, 8, 0),
		Vector3.new(0, -80, 0), filtro)
	return batida and batida.Position or ponto
end

--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É CRIADO É RECOLHIDO
--
-- Este bloco é o conjunto inteiro. As sete Tools criam `Part` DE SERVIDOR —
-- colidível, com que todo mundo esbarra — e peça de servidor que fica é lixo
-- permanente no mapa.
--
-- É a mesma família do defeito que o `timetools` tinha com `Anchored`:
-- `Instance.new("Part")` seguido de `Debris:AddItem` parece resolver, mas o
-- `Debris` não roda se o script morrer antes de chamá-lo, e a Tool destruída
-- no meio deixa a muralha no mapa até o servidor cair.
--
-- Aqui nada é criado sem entrar no registro, e o registro tem TRÊS saídas: o
-- prazo, o `Unequipped` e o `Destroying`. E tem TETO — sem ele um jogador
-- ergue trinta muralhas e todas ficam.
--═══════════════════════════════════════════════════════════════

local criadas = {}

--- Manda o desmanche para o cliente e tira a peça do mundo.
---
--- O `RECOLHER` não é enfeite: sem ele o jogador vê a muralha sumir e não sabe
--- se ela acabou ou se quebrou. Com ele, ela volta a ser andaime e apaga —
--- que é a única leitura possível de "o prazo venceu".
local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
		vfx("RECOLHER", {
			quadro = reg.peca.CFrame, tamanho = reg.peca.Size,
			cor = reg.peca.Color,
		})
		reg.peca.CanCollide = false
		reg.peca.Parent = nil
	end
	reg.peca = nil
end

local function recolherTudo()
	for _, reg in ipairs(criadas) do
		recolher(reg)
	end
	table.clear(criadas)
end

--- Cria uma peça de servidor, colidível, e a REGISTRA.
---
--- Esta é a única porta pela qual matéria entra no mundo neste conjunto. Toda
--- habilidade que constrói passa por aqui, e por isso o teto e o prazo valem
--- para todas sem cada uma ter de lembrar.
local function criar(quadro, tamanho, props, vida)
	while #criadas >= CFG.TETO_CRIADAS do
		recolher(table.remove(criadas, 1))
	end

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = tamanho
	p.CFrame = quadro
	p.Material = Enum.Material.SmoothPlastic
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace

	local reg = { peca = p, ate = os.clock() + vida }
	table.insert(criadas, reg)
	task.delay(vida, function()
		local i = table.find(criadas, reg)
		if i then
			table.remove(criadas, i)
			recolher(reg)
		end
	end)
	return p
end

--- Levanta quem estiver em cima do que subiu.
---
--- Sem isto, a torre nasce DENTRO do alvo e o Roblox o empurra para um lado
--- qualquer — ou o prende dentro da peça. Empurrar para cima de propósito é a
--- única forma de a habilidade ser legível.
local function levantar(centro, raio, forca, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 10)) do
		empurrar(alvo, Vector3.new(jitter(1) * 0.25, 1, jitter(2) * 0.25),
			forca, 0.3)
		pegos = pegos + 1
	end
	return pegos
end


--═══════════════════════════════════════════════════════════════
-- A CENA — quem assiste, e o que cada um vê
--
-- NÃO é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
-- câmera por causa de um relógio alheio. Assistem: quem virou a ampulheta, e
-- quem estiver DENTRO do raio.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(ponto, raioCena, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, ponto = ponto,
	})

	for _, alvo in ipairs(alvosEm(ponto, raioCena, 8)) do
		local corpo = alvo.Parent
		local outro = corpo and Players:GetPlayerFromCharacter(corpo)
		if outro and outro ~= jogador then
			CutsceneRemote:FireClient(outro, "INICIO", {
				papel = "ALVO", nome = nomeBeat,
				portador = personagem.Name, ponto = ponto,
			})
		end
	end
end

local function beatCena(nome, ponto)
	if not emCena then return end
	CutsceneRemote:FireAllClients("BEAT", { nome = nome, ponto = ponto })
end

--- Fechar a cena é caminho que não pode falhar: no fim da sequência, no
--- `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end

--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO.
--
-- `TESTES/verificar_beats.py` confere que todo beat despachado aqui existe na
-- sequência do `Poses.lua`, e que todo beat com `cam` tem enquadramento.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam and beatCena then beatCena(marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end


--══════════════════════════════════════════════════════════════
-- M1 — o molde do mundo
--
-- Um arco à frente, não uma reta: quem molda um mundo o faz em volta. O
-- `COSSENO` é o que separa cone de esfera — sem o produto escalar, o arco
-- acerta quem está atrás.
--══════════════════════════════════════════════════════════════

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("MOLDE_MUNDO", despachar({

		CARGA = { sfx = { "MOLDE_MUNDO", 1.15 } },

		TRACA = {
			sfx = { "MOLDE_MUNDO", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				vfx("MOLDE_MUNDO", { posicao = raiz.Position,
					direcao = direcao, raio = CFG.ALCANCE })

				for _, quem in ipairs(alvosNoCone(origem, direcao,
						CFG.ALCANCE, CFG.COSSENO, 12)) do
					aplicarDano(quem, CFG.DANO)
					local qr = raizDe(quem)
					if qr then
						empurrar(quem, (qr.Position - origem)
							+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO, 0.24)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o continente
--
-- Cinco placas de pedra sobem em volta. O dano é baixo: o que a habilidade
-- entrega é TERRENO — cobertura, altura, e um caminho que o outro não tinha.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("CONTINENTE", despachar({

		CARGA = { sfx = { "CONTINENTE", 1.1 } },
		SEGURA = { sfx = { "MOLDE_MUNDO", 1.3 } },

		ERGUE = {
			sfx = { "CONTINENTE", 0.85 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("CONTINENTE", { posicao = centro, raio = CFG.RAIO_CONT })
				tocarEm("CONTINENTE", centro, 0.85)

				local i = 1
				while i <= CFG.PLACAS do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_CONT
						* (0.3 + (i / CFG.PLACAS) * 0.55)
					local ponto = noChao(centro
						+ Vector3.new(math.cos(a) * alcance, 0,
							math.sin(a) * alcance))
					local alto = 5 + math.abs(jitter(a)) * 6

					levantar(ponto, 7, CFG.LEVANTA, 6)
					for _, quem in ipairs(alvosEm(ponto, 7, 6)) do
						aplicarDano(quem, CFG.DANO_CONT)
						tombar(quem, CFG.TOMBO)
					end

					criar(CFrame.new(ponto + Vector3.new(0, alto * 0.5, 0)),
						Vector3.new(9, alto, 9), {
							Color = Color3.fromRGB(122, 96, 68),
							Material = Enum.Material.Slate,
						}, CFG.VIDA_PLACA)
					i = i + 1
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a Criação, COM CENA
--
-- A ultimate. Dez placas sobem, o mundo se forma acima, e tudo no raio leva.
--
-- O beat `CENA` abre a cutscene; `CARGA` e `ESTOURA` levam `cam = true`.
-- `fecharCena` roda no fim da sequência E no `desmontar`: câmera presa é o
-- pior do repertório.
--══════════════════════════════════════════════════════════════

function extraT()
	if not rig or not raiz then return end
	local ponto = noChao(raiz.Position)

	ocupado = true
	rig:PlaySequence("CRIACAO", despachar({

		CENA = {
			sfx = { "CRIACAO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "CONTINENTE", 1.35 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "CRIACAO", 0.75 },
			faz = function()
				vfx("CRIACAO", { posicao = ponto, raio = CFG.RAIO_FIM })
				tocarEm("CRIACAO", ponto, 0.7)

				-- levanta ANTES de as placas existirem: assim ninguém nasce
				-- dentro de uma delas
				levantar(ponto, CFG.RAIO_FIM, CFG.EMPURRAO_FIM * 0.5, 24)

				for _, quem in ipairs(alvosEm(ponto, CFG.RAIO_FIM, 26)) do
					local qr = raizDe(quem)
					local d = qr and (qr.Position - ponto).Magnitude
						or CFG.RAIO_FIM
					local dano = (d <= CFG.NUCLEO_FIM) and CFG.DANO_FIM
						or CFG.BORDA_FIM
					aplicarDano(quem, dano)
					tombar(quem, CFG.TOMBO_FIM)
				end

				local i = 1
				while i <= CFG.PLACAS_FIM do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_FIM
						* (0.25 + (i / CFG.PLACAS_FIM) * 0.65)
					local lugar = noChao(ponto
						+ Vector3.new(math.cos(a) * alcance, 0,
							math.sin(a) * alcance))
					local alto = 6 + math.abs(jitter(a)) * 9
					criar(CFrame.new(lugar + Vector3.new(0, alto * 0.5, 0)),
						Vector3.new(8, alto, 8), {
							Color = Color3.fromRGB(122, 96, 68),
							Material = Enum.Material.Slate,
						}, CFG.VIDA_FIM)
					i = i + 1
				end
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.6, fecharCena)
	end)
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

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
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
	end
end)

--- O VIGIA DO REGISTRO
---
--- Cada peça tem prazo próprio, e o `task.delay` do `criar` é quem o cobra no
--- caso normal. Este laço é a rede embaixo: se um `task.delay` for perdido —
--- e ele é, se a thread morrer —, o vigia recolhe assim mesmo.
local function vigiar()
	guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		local i = #criadas
		while i >= 1 do
			local reg = criadas[i]
			if agora > reg.ate then
				table.remove(criadas, i)
				recolher(reg)
			end
			i = i - 1
		end
	end))
end

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "CriacaoDemiurgo", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	vigiar()
end)

--- As DUAS portas, e a terceira coisa que elas fazem: RECOLHER O QUE FOI
--- CRIADO. `Unequipped` sozinho não cobre a Tool ser destruída com uma
--- muralha de pé, e muralha sem dono fica no mapa até o servidor cair.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	recolherTudo()
	fecharCena()
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
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
