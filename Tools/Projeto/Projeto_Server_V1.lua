-- Projeto_Server_V1.lua
-- Script de servidor — Projeto  (conjunto CRIAÇÃO)
--
--   M1   Traco
--   R    Esboco   (Extra 1)
--   T    Materializar   (Extra 2)
--
--   Handle autoral: prancheta com regua e linha de tinta
--   TRACO 5651577252 (glint) · ESBOCO 1388726556 (ClickAccept)
--   MATERIALIZA 550210020 (loot_appears) — do catalogo do Acervo
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ARCANO"

local CFG = {
	ALCANCE       = 26,
	RECARGA       = 0.8,
	LARGURA       = 4,
	DANO          = 28,

	RECARGA_R     = 13,
	RAIO_ESBOCO   = 22,
	TEMPO_ESBOCO  = 8,
	DANO_ESBOCO   = 8,
	PULSO         = 1.0,

	RECARGA_T     = 21,
	FATOR         = 1.0,
	TETO_CONTA    = 200,
	DANO_BLOCO    = 40,
	EMPURRAO      = 80,
	TOMBO         = 1.3,
	VIDA_BLOCO    = 8,
	TETO_CRIADAS  = 8,
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
local esbocoId, esbocoOnde, esbocoAte = nil, nil, 0
--- O que cada alvo acumulou dentro do esboço. Chave FRACA.
local conta = setmetatable({}, { __mode = "k" })

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


--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil

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
-- O DESENHO ACUMULA, E O `T` CONSTRÓI
--
-- Dentro do esboço, o dano não é só dano: ele é ANOTADO. O `T` materializa o
-- que foi desenhado, e a conta cai de uma vez. É o par que dá razão às três
-- habilidades desta Tool existirem juntas.
--
-- O TETO existe porque sem ele um alvo parado oito segundos dentro do esboço
-- acumula a conta de oito segundos de todo mundo e morre sem aviso.
--══════════════════════════════════════════════════════════════

local function anotar(alvoHum, quanto)
	if not alvoHum then return end
	conta[alvoHum] = math.min((conta[alvoHum] or 0) + quanto, CFG.TETO_CONTA)
end

local function cobrar(alvoHum)
	local devido = conta[alvoHum]
	if not devido or devido <= 0 then return 0 end
	conta[alvoHum] = nil
	aplicarDano(alvoHum, math.floor(devido * CFG.FATOR + 0.5))
	return devido
end

--══════════════════════════════════════════════════════════════
-- M1 — o traço
--
-- Uma reta. Quem está NO CAMINHO leva, não quem está perto do fim.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("TRACO", despachar({

		CARGA = { sfx = { "TRACO", 1.2 } },

		TRACA = {
			sfx = { "TRACO", 1.0 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector
				if typeof(alvo) == "Vector3" then
					local delta = alvo - origem
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local destino = origem + direcao * CFG.ALCANCE

				vfx("TRACO", { posicao = raiz.Position, destino = destino,
					direcao = direcao, raio = CFG.ALCANCE })

				for _, quem in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.LARGURA, 10)) do
					aplicarDano(quem, CFG.DANO)
					if esbocoOnde then anotar(quem, CFG.DANO) end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o esboço
--
-- ELE NÃO DÁ QUASE DANO NENHUM: 8 por segundo. O que ele faz é marcar o chão
-- e ligar a contagem — é a habilidade de PREPARAR, e o `T` é a de cobrar.
--══════════════════════════════════════════════════════════════

function pararEsboco()
	if esbocoId then
		vfx("PARAR", { id = esbocoId })
		esbocoId = nil
	end
	esbocoOnde, esbocoAte = nil, 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ESBOCO", despachar({

		CARGA = { sfx = { "ESBOCO", 1.15 } },

		TRACA = {
			sfx = { "ESBOCO", 0.95 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())
				pararEsboco()

				esbocoId = novoId("esboco")
				esbocoOnde = centro
				esbocoAte = os.clock() + CFG.TEMPO_ESBOCO

				vfx("ESBOCO", { id = esbocoId, posicao = centro,
					raio = CFG.RAIO_ESBOCO, duracao = CFG.TEMPO_ESBOCO })
				tocarEm("ESBOCO", centro, 1.0)

				local function pulsar()
					if os.clock() > esbocoAte then
						pararEsboco()
						return
					end
					if not (personagem and personagem.Parent) then
						pararEsboco()
						return
					end
					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_ESBOCO, 16)) do
						aplicarDano(quem, CFG.DANO_ESBOCO)
						anotar(quem, CFG.DANO_ESBOCO)
					end
					task.delay(CFG.PULSO, pulsar)
				end
				task.delay(CFG.PULSO, pulsar)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — materializar
--
-- Seis blocos nascem no esboço, e a conta de todo mundo lá dentro cai de uma
-- vez. Sem esboço aberto, ele nasce onde você mira — e sem conta nenhuma para
-- cobrar, que é o que faz valer a pena preparar antes.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("MATERIALIZAR", despachar({

		CARGA = { sfx = { "MATERIALIZA", 1.1 } },
		SEGURA = { sfx = { "TRACO", 1.35 } },

		ERGUE = {
			sfx = { "MATERIALIZA", 0.85 },
			faz = function()
				local centro = esbocoOnde
					or noChao((typeof(onde) == "Vector3") and onde or frente())

				vfx("MATERIALIZAR", { posicao = centro,
					raio = CFG.RAIO_ESBOCO })
				tocarEm("MATERIALIZA", centro, 0.9)

				local i = 1
				while i <= 6 do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_ESBOCO * 0.6
					local ponto = centro + Vector3.new(math.cos(a) * alcance, 0,
						math.sin(a) * alcance)
					criar(CFrame.new(noChao(ponto) + Vector3.new(0, 2.5, 0)),
						Vector3.new(3, 5, 3), {
							Color = Color3.fromRGB(232, 236, 242),
							Material = Enum.Material.SmoothPlastic,
						}, CFG.VIDA_BLOCO)
					i = i + 1
				end

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_ESBOCO, 18)) do
					aplicarDano(quem, CFG.DANO_BLOCO)
					cobrar(quem)
					local qr = raizDe(quem)
					if qr then
						empurrar(quem, (qr.Position - centro)
							+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.3)
					end
					tombar(quem, CFG.TOMBO)
				end
				pararEsboco()
			end,
		},

	}), function()
		ocupado = false
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

	rig = Animator.new(personagem, "CriacaoProjeto", Poses,
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
	pararEsboco()
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
