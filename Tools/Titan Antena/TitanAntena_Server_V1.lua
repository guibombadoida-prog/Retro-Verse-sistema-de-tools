-- TitanAntena_Server_V1.lua
-- Script de servidor — Titan Antena  (conjunto TITAN)
--
--   M1   Chicote
--   R    Torre   (Extra 1)
--   T    Interferencia   (Extra 2)
--
--   Handle: haste cromada de 5.4 studs com prato e ponta Neon
--   CHICOTE 145486992 (sfx_swooshing) · SINAL 1310929645 (Locked On)
--   INTERFERE 8578316223 (charge) — os tres do catalogo do Acervo
--
-- CONJUNTO AUTORAL
--
--   O TITAN não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega.
--   A geometria é primitiva soldada, e a lógica é escrita aqui.
--
-- TRÊS HABILIDADES, E UM `AcaoRemote` SÓ
--
--   Quem separa as duas Extras é o NOME DA TECLA no payload, conferido aqui
--   antes de qualquer coisa. Confiar no cliente para dizer qual habilidade
--   rodar seria dar a ele a escolha da recarga também.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_titan.py. Editar aqui à mão faz as
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
	ALCANCE       = 16,
	RECARGA       = 1.0,
	RAIO          = 11,
	DANO          = 17,

	RECARGA_R     = 15,
	RAIO_TORRE    = 34,
	TEMPO_TORRE   = 8,
	PULSO_TORRE   = 1.1,
	DANO_PULSO    = 7,
	TEMPO_MARCA   = 6,
	BONUS_MARCA   = 1.4,

	RECARGA_T     = 20,
	RAIO_INTERF   = 26,
	DANO_INTERF   = 20,
	LENTIDAO      = 0.45,
	TEMPO_INTERF  = 4,
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
local torreId, torreAte = nil, 0
local marcados = setmetatable({}, { __mode = "k" })

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. Com TODOS os clientes desenhando, um
--- sorteio faria cada um ver uma cena diferente, o que lê como lag.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice: é o que espalha os raios do leque e os pontos do
--- chuvisco sem sorteio nenhum.
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
--
-- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
-- some no quadro seguinte mata o som no quadro em que ele nasce — por isso
-- `tocarEm` cria uma âncora própria.
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
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
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--
-- Cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { sfx = { "CORTE", 0.9 }, faz = bater }
--
--   `sfx`  toca um som: { nome, pitch }
--   `faz`  o trabalho que não cabe em dado
--
-- `TESTES/verificar_beats.py` confere, Tool a Tool, que todo beat despachado
-- aqui existe na sequência do `Poses.lua`.
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
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- `TakeDamage` respeita `ForceField`; escrever em `Health` fura. A tag
-- `creator` é o que credita o abate.
--
-- ORDEM DA TAG: `Name` ANTES de `Parent`. Ao contrário, o `Humanoid` recebe um
-- `ObjectValue` chamado "Value" e o abate não conta para ninguém.
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

--- Alvos num raio, por consulta espacial sob demanda — nunca varredura do
--- mundo inteiro por assinatura.
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

--- Lentidão com volta GARANTIDA. Guarda a velocidade de ANTES e devolve essa
--- — nunca um número fixo, porque o alvo pode ter velocidade própria.
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

--- Dano em área com NÚCLEO e BORDA. Raio grande com dano chapado mata quem
--- está na borda sem nenhum aviso visual.
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

--- Alvos num CONE à frente. O que separa cone de esfera é o produto escalar:
--- sem ele, "cone de choque" acerta quem está atrás de quem gritou.
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

--- Alvos ao longo de uma RETA. É o que o feixe precisa: quem está no caminho,
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

--- Avança o PRÓPRIO personagem. `BodyVelocity` com prazo, nunca escrita de
--- `CFrame` por quadro: escrever CFrame no servidor briga com a autoridade de
--- física do dono e produz o tranco que o jogador lê como travada.
local function avancar(direcao, forca, tempo)
	if not raiz or direcao.Magnitude < 0.01 then return nil end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = raiz
	Debris:AddItem(impulso, tempo or 0.3)
	return impulso
end


--══════════════════════════════════════════════════════════════
-- A MARCA
--
-- Quem está marcado leva `BONUS_MARCA` vezes o dano de QUALQUER habilidade
-- desta Tool. A tabela é de chave FRACA (`__mode = "k"`): se o Humanoid morrer
-- e sair do jogo, a entrada some sozinha. Tabela forte aqui seria vazamento
-- que cresce a partida inteira.
--══════════════════════════════════════════════════════════════

local function marcar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	marcados[alvoHum] = os.clock() + (tempo or CFG.TEMPO_MARCA)
	local alvoRaiz = raizDe(alvoHum)
	if alvoRaiz then
		vfx("MARCA", { peca = alvoRaiz, duracao = tempo or CFG.TEMPO_MARCA })
	end
end

local function estaMarcado(alvoHum)
	local ate = marcados[alvoHum]
	if not ate then return false end
	if os.clock() > ate then
		marcados[alvoHum] = nil
		return false
	end
	return true
end

--- O dano desta Tool passa TODO por aqui: é o único lugar que sabe do bônus.
local function danoNoAlvo(alvoHum, bruto)
	local final = bruto
	if estaMarcado(alvoHum) then
		final = bruto * CFG.BONUS_MARCA
	end
	return aplicarDano(alvoHum, math.floor(final + 0.5))
end

--══════════════════════════════════════════════════════════════
-- M1 — o chicote de antena
--
-- Alcance longo para um golpe corpo a corpo: a haste tem 5.4 studs, e o golpe
-- respeita isso.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("CHICOTE", despachar({

		CARGA = { sfx = { "CHICOTE", 1.2 } },

		GOLPE = {
			sfx = { "CHICOTE", 0.95 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("CHICOTE", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.RAIO })

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					danoNoAlvo(alvo, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a torre de sinal
--
-- Um mastro cravado no chão que, a cada `PULSO_TORRE`, marca e sangra quem
-- estiver no raio. Ela NÃO segue o jogador: quem plantou pode sair de perto, e
-- a torre continua trabalhando onde foi plantada. É o que a torna decisão de
-- posição em vez de aura.
--══════════════════════════════════════════════════════════════

function pararTorre()
	if torreId then
		vfx("PARAR", { id = torreId })
		torreId = nil
	end
	torreAte = 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("TORRE", despachar({

		CARGA = { sfx = { "SINAL", 1.15 } },

		SEGURA = { sfx = { "INTERFERE", 1.2 } },

		GOLPE = {
			sfx = { "SINAL", 0.9 },
			faz = function()
				pararTorre()
				torreId = novoId("torre")
				torreAte = os.clock() + CFG.TEMPO_TORRE

				vfx("TORRE", { id = torreId, posicao = onde,
					raio = CFG.RAIO_TORRE, duracao = CFG.TEMPO_TORRE })
				tocarEm("SINAL", onde, 0.85)

				local function pulsar()
					if not torreId or os.clock() > torreAte then
						pararTorre()
						return
					end
					if not (personagem and personagem.Parent) then
						pararTorre()
						return
					end
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_TORRE, 16)) do
						danoNoAlvo(alvo, CFG.DANO_PULSO)
						marcar(alvo, CFG.TEMPO_MARCA)
					end
					task.delay(CFG.PULSO_TORRE, pulsar)
				end
				pulsar()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a interferência
--
-- Área grande, dano médio, e todo mundo sai mais devagar e marcado. É a
-- habilidade de ABRIR briga: ela não fecha nada sozinha.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("INTERFERENCIA", despachar({

		CARGA = { sfx = { "INTERFERE", 1.1 } },

		SEGURA = { sfx = { "INTERFERE", 0.8 } },

		GOLPE = {
			sfx = { "SINAL", 1.25 },
			faz = function()
				vfx("INTERFERENCIA", { posicao = onde, raio = CFG.RAIO_INTERF })
				tocarEm("INTERFERE", onde, 0.9)

				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_INTERF, 18)) do
					danoNoAlvo(alvo, CFG.DANO_INTERF)
					afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_INTERF)
					marcar(alvo, CFG.TEMPO_MARCA)
				end
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

--- As DUAS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R" e "T" é descartada sem resposta.
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

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "TitanAntena", Poses,
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
	pararTorre()
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
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- fica lá até o servidor cair.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
