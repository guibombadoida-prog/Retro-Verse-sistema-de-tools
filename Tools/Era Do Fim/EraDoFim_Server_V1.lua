-- EraDoFim_Server_V1.lua
-- Script de servidor — Era Do Fim  (conjunto FAKER)
--
-- Sai da ÚNICA Tool do `faker_tools.rbxmx`, que é o His Cube original. Handle e
-- malhas vêm de lá; a habilidade é escrita aqui. Ver
-- `FERRAMENTAS/preparar_faker.py` para o mapa das sete malhas.
--
--   M1   o cogumelo — ultimate com cutscene
--   R    Onda   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
-- A origem punha tudo em LocalScript, e por isso a habilidade dela era
-- invisível para o resto do servidor.
--
-- Gerado por FERRAMENTAS/gerar_servers_faker.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	ALCANCE        = 10,
	RECARGA        = 40,
	RAIO_CENA      = 70,
	RAIO_FIM       = 58,
	RAIO_NUCLEO    = 22,
	DANO_FIM       = 120,
	DANO_BORDA     = 55,
	EMPURRAO_FIM   = 130,
	TOMBO_FIM      = 3,

	RECARGA_EXTRA  = 14,
	RAIO_ONDA      = 88,
	DANO_ONDA      = 34,
	EMPURRAO_ONDA  = 92,
	DURACAO_ONDA   = 1.1,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoExtra = 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extra


local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 67 `math.random` da origem —
--- e neste conjunto isso pesa mais que nos outros, porque TODOS os clientes
--- desenham. Um sorteio faria cada um ver uma cena diferente, o que lê como
--- lag, não como efeito.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function angulo(i)
	return i * 2.399963
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
local function tocarEm(nome, posicao, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end

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
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end
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
-- A ORIGEM NÃO TINHA DANO NENHUM. Zero `TakeDamage` e zero escrita em `Health`
-- nas 796 linhas dela: era casca de VFX privada. Este bloco é o que faz as sete
-- serem Tools de combate e não fogos de artifício.
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
			posicao, raio, personagem, jogador, humanoide, limite or 10) or {}
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

--- Puxar é empurrar com o sinal trocado, e é o verbo deste conjunto: o poço, a
--- prisão e a implosão puxam. Sai por prazo no `Debris`, como tudo aqui.
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
--- não é teleporte, é âncora.
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


--═══════════════════════════════════════════════════════════════
-- A CUTSCENE — um `FireClient` POR ESPECTADOR
--
-- `GRAMATICA_CUTSCENE.md` regra 2: enquadramento por espectador.
--
--   quem invoca  ->  vê o evento de fora e de baixo
--   quem está no raio  ->  vê a coisa vindo em cima DELE
--
-- A diferença para o conjunto DRAMA: lá a cena é entre DOIS, porque é execução
-- de um alvo. Aqui é evento de área, então a plateia é toda a gente dentro do
-- raio — cada um recebendo o papel `ALVO`, e o `INVOCADOR` só um. Quem está
-- fora do raio não perde a câmera, que é o ponto da regra.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(plateia, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	-- o primeiro da plateia é a referência de enquadramento do invocador
	local primeiro = plateia and plateia[1]
	local corpoPrimeiro = primeiro and primeiro.Parent
	local nomeAlvo = corpoPrimeiro and corpoPrimeiro.Name or nil

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, alvoNome = nomeAlvo,
	})

	for _, alvoHum in ipairs(plateia or {}) do
		local corpo = alvoHum and alvoHum.Parent
		local jogadorAlvo = corpo and Players:GetPlayerFromCharacter(corpo)
		if jogadorAlvo and jogadorAlvo ~= jogador then
			CutsceneRemote:FireClient(jogadorAlvo, "INICIO", {
				papel = "ALVO", nome = nomeBeat,
				portador = personagem.Name, alvoNome = corpo.Name,
			})
		end
	end
end

local function beatCena(nome)
	if not emCena then return end
	CutsceneRemote:FireAllClients("BEAT", { nome = nome })
end

--- Fechar a cena é caminho que não pode falhar: ele roda no fim da sequência,
--- no `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end


--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o fim de uma era, COM CUTSCENE
--
-- "An end of an Era" é o nome que o PRÓPRIO modelo dá à habilidade E dele:
-- `Services.Input:SetTitle("Secondary", "An end of an Era")`.
--
-- ULTIMATE: 7.20 s com 74% de preparação, dentro da faixa da regra 5. A malha é
-- o `Mushroom` de **522 × 543 × 522 studs** — a maior coisa que já entrou neste
-- repositório por duas ordens de grandeza.
--
-- A plateia da cena é toda a gente no raio, não um alvo só. É evento de área, e
-- a regra 2 vale igual: cada um recebe o papel dele.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 16), "CAMERA")

	rig:PlaySequence("FIM_DA_ERA", function(passo)
		local marca = marcaDe(passo)
		if not marca then return end

		if marca == "CAMERA" then
			tocar("GRAVE", 0.5)
		elseif marca == "ERGUE" then
			beatCena("ERGUE")
			tocar("AGUDO", 0.6)
		elseif marca == "CARGA" then
			beatCena("CARGA")
			tocar("GRAVE", 0.4)
		elseif marca == "SEGURA" then
			beatCena("SEGURA")
		elseif marca == "DESCE" then
			beatCena("DESCE")
			tocar("DISPARO", 0.7)
		elseif marca == "DETONA" then
			beatCena("DETONA")
			local onde = raiz and raiz.Position or centro
			vfx("COGUMELO", { posicao = onde, escala = 1 })
			vfx("ANEL", { posicao = onde, escala = 1.4, duracao = 1.6 })
			tocarEm("GRAVE", onde, 0.35)
			tocarEm("DISPARO", onde, 0.45)

			-- quem está no núcleo paga o cheio; quem está na borda paga menos.
			-- Dois raios, não um: uma explosão de 58 studs com dano chapado
			-- mataria meio servidor por estar por perto.
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_FIM, 20)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude or CFG.RAIO_FIM
				if d <= CFG.RAIO_NUCLEO then
					aplicarDano(alvo, CFG.DANO_FIM)
					tombar(alvo, CFG.TOMBO_FIM)
				else
					aplicarDano(alvo, CFG.DANO_BORDA)
					tombar(alvo, CFG.TOMBO_FIM * 0.5)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - onde)
						+ Vector3.new(0, 0.8, 0), CFG.EMPURRAO_FIM, 0.4)
				end
			end
		elseif marca == "FIM" then
			fecharCena()
		end
	end, function()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a onda
--
-- O `Ring` de 500 studs, rasteiro. Dano baixo e alcance enorme: é limpeza de
-- espaço, não execução.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("ONDA", function(passo)
		local marca = marcaDe(passo)
		if marca == "ABRE" then
			tocar("AGUDO", 0.75)
		elseif marca == "SOLTA" then
			local centro = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("ANEL", { posicao = centro, escala = 1,
				duracao = CFG.DURACAO_ONDA })
			tocarEm("GRAVE", centro, 0.6)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ONDA, 20)) do
				aplicarDano(alvo, CFG.DANO_ONDA)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_ONDA, 0.34)
				end
			end
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
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

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if tecla ~= "R" then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	extra(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "FakerEraDoFim", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
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
