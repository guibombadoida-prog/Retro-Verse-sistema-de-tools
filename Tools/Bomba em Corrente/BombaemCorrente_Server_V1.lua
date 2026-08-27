-- BombaemCorrente_Server_V1.lua
-- Script de servidor — Bomba em Corrente  (conjunto PODERES DE BOMBA)
--
--   M1   Estopim
--   R    Reacao   (Extra)
--
--   Handle: tres elos de ferro ligados por um fio Neon
--   ESTOPIM 2674547670 (Electric Explosion) · SALTO 96478259
--   (Lightning2) · FIM 142070127 (explosive) — do catalogo do Acervo
--
-- AS DUAS SÃO UM PAR, NÃO DUAS HABILIDADES SOLTAS
--
--   O M1 acende o ESTOPIM em quem acertar; o R faz a reação SALTAR dele para o mais perto, e do mais perto para o seguinte. Sem estopim aceso, o R não tem de onde partir.
--
-- CONJUNTO AUTORAL
--
--   O conjunto não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega. A
--   geometria é primitiva soldada, e a lógica é escrita aqui.
--
--   E ele NÃO repete o `Bomba_V4`. As seis de lá são split, nuke, meteoro,
--   quique, kamikaze e gelo; o eixo daqui é PLANTAR E DETONAR.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_bombas7.py. Editar aqui à mão faz as
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
	RECARGA       = 1.0,
	RAIO_M1       = 12,
	DANO_M1       = 30,
	TEMPO_ESTOPIM = 8,

	RECARGA_R     = 21,
	SALTOS        = 5,
	RAIO_SALTO    = 34,
	INTERVALO     = 0.16,
	RAIO          = 16,
	NUCLEO        = 6,
	DANO          = 55,
	BORDA         = 22,
	CRESCE        = 1.18,
	EMPURRAO      = 85,
	TOMBO         = 1.0,
	RAIO_CENA     = 30,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR = 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extraR
local estopimId, estopimAte = nil, 0
local estopimAlvo = nil

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

--- Ângulo áureo por índice: espalha sem sorteio nenhum.
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
-- `tocarEm` cria uma âncora própria. Numa Tool de bomba isso não é detalhe: a
-- peça que estoura é EXATAMENTE a que some.
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

--- Alvos num raio, por consulta espacial sob demanda.
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

--═══════════════════════════════════════════════════════════════
-- A EXPLOSÃO — NÚCLEO E BORDA, sempre
--
-- É a única forma de dano deste conjunto inteiro, e ela nunca é chapada. Raio
-- de 40 com dano igual em todo lugar mata quem está na borda sem nenhum aviso
-- visual de que estava dentro; e o VFX desenha um anel que ABRE, o que promete
-- ao jogador exatamente o contrário.
--
-- E NUNCA `Instance.new("Explosion")`: ela empurra e desmonta junta por conta
-- própria, sem passar por `TakeDamage` nem respeitar `ForceField`, e o
-- servidor perde o controle do que ela fez.
--═══════════════════════════════════════════════════════════════

local function estourar(centro, raio, raioNucleo, danoNucleo, danoBorda,
		forca, tombo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 20)) do
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
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.7, 0),
				forca, 0.34)
		end
		pegos = pegos + 1
	end
	return pegos
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um jato de espuma acerta quem está atrás de quem esguichou.
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

--- O chão sob um ponto mirado. Bomba que fica boiando na altura do mouse é o
--- que faz o jogador errar sem entender por quê.
local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(ponto + Vector3.new(0, 6, 0),
		Vector3.new(0, -60, 0), filtro)
	return batida and batida.Position or ponto
end

--═══════════════════════════════════════════════════════════════
-- A CENA — quem assiste, e o que cada um vê
--
-- NÃO é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
-- câmera por causa de uma bomba alheia — cutscene que toma a câmera de quem
-- não está envolvido é a definição de tempo morto.
--
-- Assistem: quem detonou, e quem estiver DENTRO do raio. É a regra 2 da
-- GRAMATICA_CUTSCENE — enquadramento por espectador — e aqui ela tem um
-- sentido que numa cena de espada não teria: numa bomba, "estar no raio" é
-- exatamente a informação que o jogador precisa ter.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(ponto, raioCena, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, ponto = ponto,
	})

	-- a outra metade da regra 2: cada um que está no raio recebe a cena DELE
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

--- Fechar a cena é caminho que não pode falhar: ele roda no fim da sequência,
--- no `desmontar()`, e por prazo do lado do cliente.
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
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--
--     ESTOURA = { cam = true, sfx = { "NUCLEAR", 0.8 }, faz = detonar }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe
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
		if kf.cam and beatCena then beatCena(marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end


--══════════════════════════════════════════════════════════════
-- O ESTOPIM
--
-- Guardado por referência FRACA não dá: aqui é uma variável só, e ela é
-- limpa quando o alvo morre ou o prazo vence. O que não pode acontecer é o
-- `R` partir de um Humanoid que já saiu do jogo.
--══════════════════════════════════════════════════════════════

function pararEstopim()
	if estopimId then
		vfx("PARAR", { id = estopimId })
		estopimId = nil
	end
	estopimAlvo, estopimAte = nil, 0
end

local function estopimVivo()
	if not estopimAlvo then return false end
	if os.clock() > estopimAte then return false end
	if not estopimAlvo.Parent or estopimAlvo.Health <= 0 then return false end
	return true
end

--══════════════════════════════════════════════════════════════
-- M1 — acender o estopim
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ESTOPIM", despachar({

		CARGA = { sfx = { "ESTOPIM", 1.2 } },

		LANCA = {
			sfx = { "ESTOPIM", 1.0 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				local pegos = alvosEm(centro, CFG.RAIO_M1, 6)
				for _, quem in ipairs(pegos) do
					aplicarDano(quem, CFG.DANO_M1)
				end

				vfx("ESTOURO_ELO", { posicao = centro, raio = CFG.RAIO_M1 })

				-- o estopim acende no PRIMEIRO que levou
				if #pegos > 0 then
					pararEstopim()
					estopimAlvo = pegos[1]
					estopimAte = os.clock() + CFG.TEMPO_ESTOPIM
					estopimId = novoId("estopim")
					local alvoRaiz = raizDe(estopimAlvo)
					vfx("ESTOPIM", {
						id = estopimId, peca = alvoRaiz,
						posicao = alvoRaiz and alvoRaiz.Position or centro,
						duracao = CFG.TEMPO_ESTOPIM,
					})
					task.delay(CFG.TEMPO_ESTOPIM, function()
						if not estopimVivo() then pararEstopim() end
					end)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a reação em cadeia, COM CENA
--
-- Salta do estopim para o mais perto, e do mais perto para o seguinte, até
-- `SALTOS`. Cada elo bate `CRESCE` vezes mais que o anterior — é o que faz a
-- corrente valer a pena montar em vez de só bater.
--
-- NINGUÉM É ACERTADO DUAS VEZES. `visitados` é o que impede a corrente de
-- pingar entre dois alvos vizinhos e aplicar cinco vezes o dano no mesmo par.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not rig or not raiz then return end
	if not estopimVivo() then return end

	local primeiro = estopimAlvo
	local primeiroRaiz = raizDe(primeiro)
	local ponto = primeiroRaiz and primeiroRaiz.Position or raiz.Position

	ocupado = true
	rig:PlaySequence("REACAO", despachar({

		CENA = {
			sfx = { "SALTO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "ESTOPIM", 1.1 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "FIM", 0.85 },
			faz = function()
				local visitados = {}
				local atual = primeiro
				visitados[atual] = true

				local elo = 0
				local function saltar()
					elo = elo + 1
					if elo > CFG.SALTOS or not atual then
						return
					end
					if not (personagem and personagem.Parent) then return end

					local atualRaiz = raizDe(atual)
					if not atualRaiz then return end
					local onde = atualRaiz.Position
					local forca = CFG.CRESCE ^ (elo - 1)

					vfx("ESTOURO_ELO", { posicao = onde, raio = CFG.RAIO })
					tocarEm("FIM", onde, 0.9 + elo * 0.04)

					estourar(onde, CFG.RAIO, CFG.NUCLEO,
						CFG.DANO * forca, CFG.BORDA * forca,
						CFG.EMPURRAO, CFG.TOMBO, 10)

					-- o próximo elo: o mais perto que ainda não levou
					local melhor, dist = nil, math.huge
					for _, quem in ipairs(alvosEm(onde, CFG.RAIO_SALTO, 16)) do
						if not visitados[quem] then
							local qr = raizDe(quem)
							if qr then
								local dd = (qr.Position - onde).Magnitude
								if dd < dist then melhor, dist = quem, dd end
							end
						end
					end

					if melhor then
						local mr = raizDe(melhor)
						vfx("SALTO", { posicao = onde,
							destino = mr and mr.Position or onde })
						tocarEm("SALTO", onde, 1.1 + elo * 0.05)
						visitados[melhor] = true
						atual = melhor
						task.delay(CFG.INTERVALO, saltar)
					end
				end
				saltar()
				pararEstopim()
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.5, fecharCena)
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e UMA Extra
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

--- A Extra chega pelo `AcaoRemote`, com a tecla no payload. Qualquer coisa
--- fora de "R" é descartada sem resposta: confiar no cliente para dizer qual
--- habilidade rodar seria dar a ele a escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if tecla ~= "R" then return end
	if not pronto(ultimoR, CFG.RECARGA_R) then return end
	ultimoR = os.clock()
	extraR(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "BombaCorrente", Poses,
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
	pararEstopim()
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
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- fica lá até o servidor cair.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
