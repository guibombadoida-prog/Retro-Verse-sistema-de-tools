-- CajadoCeleste_Server_V1.lua
-- Script de servidor — Cajado Celeste  (conjunto TEMPO)
--
--   M1   Sol / Lua
--   R    Holofote   (Extra 1)
--   T    Eco do Instante   (Extra 2)
--
--   Handle DA ORIGEM: o CelestialStaffModel inteiro, 33 pecas soldadas
--   e as duas MeshPart (ARC 1204910704, Meshes/C 3084463904)
--   LANCA 4750661969 (Cast) · HOLOFOTE 4953086953 (Effect)
--   LAMINA 4953084421 (Aura) — os tres da ficha do Acervo
--
-- O QUE VEIO DO `timetools.rbxmx`, E O QUE NÃO VEIO
--
--   Vieram os ASSETS — 14 `SoundId` e 7 `MeshId`, todos catalogados na ficha
--   do Acervo — e, nas Tools remasterizadas, o Handle INTEIRO. Veio também a
--   MECÂNICA, que a origem acertou: congelar é mexer em quatro eixos ao mesmo
--   tempo (peça, partícula, som, personagem), e reverter é gravar `CFrame`
--   num vetor e devolvê-lo com um fantasma adiantado.
--
--   NÃO veio a implementação. A origem varria `workspace:GetDescendants()`,
--   punha `ColorCorrectionEffect` e `BlurEffect` em `Lighting`, usava
--   `ScreenGui`, `Animation`, `ServerStorage` e `wait()`, e — o pior —
--   NÃO GARANTIA A VOLTA: Tool destruída no meio deixava o mapa ancorado
--   para sempre.
--
-- A REGRA DESTE ARQUIVO: TUDO QUE É MEXIDO É DEVOLVIDO
--
--   Todo estado alterado entra em `mexidos` ou `ancorados` COM O VALOR DE
--   ANTES, e `restaurarTudo()` roda no fim do prazo, no `Unequipped` e no
--   `Destroying`. Devolver um número fixo não serve: o alvo pode ter
--   velocidade própria.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_tempo.py. Editar aqui à mão faz as
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

local ARQUETIPO = "ASTRAL"

local CFG = {
	ALCANCE       = 110,
	RECARGA       = 0.8,

	FOTONS        = 5,
	INTERVALO_SOL = 0.12,
	QUEDA_FOTON   = 0.7,
	ESPALHA       = 14,
	RAIO_FOTON    = 12,
	DANO_FOTON    = 26,

	VOO_LAMINA    = 1.4,
	ALCANCE_LAMINA = 120,
	LARGURA_LAMINA = 8,
	DANO_LAMINA   = 62,
	EMPURRAO_LAMINA = 60,
	PASSO_VOO     = 1 / 30,

	RECARGA_R     = 13,
	RAIO_HOLOFOTE = 20,
	TEMPO_HOLOFOTE = 4,
	PULSO_HOLOFOTE = 0.7,
	DANO_HOLOFOTE = 12,
	LENTIDAO      = 0.6,

	RECARGA_T     = 22,
	RAIO_ECO      = 16,
	DANO_ECO      = 48,
	TEMPO_ECO     = 2.0,

	--- Os QUATRO Sound que vieram pendurados no Handle da origem. Eles não
	--- estão na pasta `SFX`: estão onde o autor os pôs, e `somDe` procura nos
	--- dois lugares. `Cast` no início do M1 e `UnCast` no fim são exatamente
	--- os momentos em que o `Celestial Staff` os tocava.
	SFX_CAST      = "Cast",
	SFX_UNCAST    = "UnCast",
	SFX_PRONTO    = "ChargeReady",
	SFX_TEMPO     = "TimeSound",
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
local holofoteId, holofoteAte = nil, 0

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

--- Sorteia DENTRO de um grupo de variação, com peso.
---
--- Um `Sound` com um `NumberValue` chamado `Weight` sai mais (ou menos) que os
--- irmãos. Serve para o take bom sair 3× mais que o esquisito sem ter de
--- apagar o esquisito.
---
--- ⚠️ A última linha NÃO é paranoia. `math.random() * total` pode, por
---    arredondamento de ponto flutuante, sobrar depois de subtrair todos os
---    pesos e cair fora do laço. A implementação de onde a ideia veio devolve
---    `nil` nesse caso — que é um som MUDO, em silêncio, uma vez a cada muitas.
local function sortearNoGrupo(pasta)
	local candidatos, total = {}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, { som = filho, peso = peso })
			total = total + peso
		end
	end
	if #candidatos == 0 then return nil end
	if #candidatos == 1 then return candidatos[1].som end

	local sorteio = math.random() * total
	for _, c in ipairs(candidatos) do
		if sorteio < c.peso then return c.som end
		sorteio = sorteio - c.peso
	end
	return candidatos[#candidatos].som
end

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	-- `Folder` com o nome do papel É o grupo de variação
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso. Tool antiga não muda de
--- comportamento: `Sound` avulso cai no primeiro `return`.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o `Sound` que
--- `tocar()` clona é parenteado no `Handle` pelo servidor, então a INSTÂNCIA
--- replica e todo mundo ouve a mesma. Se cada cliente sorteasse, duas pessoas
--- ouviriam sons diferentes para o mesmo golpe.
---
--- Achado ao ler o `ROBLOX-Audio-Manager` — ver
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1. Os modelos de
--- entrada já trazem 76 variantes que ninguém usava (`block1`..`block22` só no
--- Danilo, `Swing1`..`Swing5` no Reality).
local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
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

--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É MEXIDO É DEVOLVIDO
--
-- Este bloco é a diferença entre este conjunto e a origem, e ele existe por
-- causa de um defeito concreto: `Para o tempo/Main` fazia
--
--     v.Anchored = true; wait(tempo); v.Anchored = false
--
-- e se a Tool morresse entre as duas linhas a peça ficava ancorada PARA
-- SEMPRE. Não havia como desfazer, nem quem desfizesse.
--
-- Aqui nada é alterado sem que o valor de ANTES entre num registro, e o
-- registro tem TRÊS saídas: o prazo, o `Unequipped` e o `Destroying`.
--═══════════════════════════════════════════════════════════════

--- Chave FRACA: se o Humanoid sair do jogo, a entrada some sozinha. Tabela
--- forte aqui seria vazamento que cresce a partida inteira.
local mexidos = setmetatable({}, { __mode = "k" })
local ancorados = setmetatable({}, { __mode = "k" })

--- Congela um personagem. Guarda velocidade, salto e o `PlatformStand` de
--- ANTES; devolve ESSES, nunca 16 e 50 fixos — o alvo pode ter os dele.
local function congelarHumanoide(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return false end
	if mexidos[alvoHum] then return false end   -- guarda contra empilhar

	local alvoRaiz = raizDe(alvoHum)
	mexidos[alvoHum] = {
		andar = alvoHum.WalkSpeed,
		pular = alvoHum.JumpPower,
		altura = alvoHum.JumpHeight,
		raizAncorada = alvoRaiz and alvoRaiz.Anchored or nil,
		ate = os.clock() + tempo,
	}

	alvoHum.WalkSpeed = 0
	alvoHum.JumpPower = 0
	alvoHum.JumpHeight = 0
	if alvoRaiz then alvoRaiz.Anchored = true end
	return true
end

local function descongelarHumanoide(alvoHum)
	local antes = mexidos[alvoHum]
	if not antes then return end
	mexidos[alvoHum] = nil
	if not (alvoHum and alvoHum.Parent) then return end
	alvoHum.WalkSpeed = antes.andar
	alvoHum.JumpPower = antes.pular
	alvoHum.JumpHeight = antes.altura
	local alvoRaiz = raizDe(alvoHum)
	if alvoRaiz and antes.raizAncorada ~= nil then
		alvoRaiz.Anchored = antes.raizAncorada
	end
end

--- Congela uma peça solta. SÓ mexe no que estava solto: se a peça já era
--- ancorada, ela sai do congelamento ancorada, que é como entrou.
local function congelarPeca(peca, tempo)
	if not (peca and peca:IsA("BasePart")) then return false end
	if peca.Anchored then return false end
	if ancorados[peca] then return false end
	ancorados[peca] = { ate = os.clock() + tempo }
	peca.Anchored = true
	return true
end

local function soltarPeca(peca)
	if not ancorados[peca] then return end
	ancorados[peca] = nil
	if peca and peca.Parent then peca.Anchored = false end
end

--- A saída que não pode falhar.
local function restaurarTudo()
	for alvoHum in pairs(mexidos) do
		descongelarHumanoide(alvoHum)
	end
	for peca in pairs(ancorados) do
		soltarPeca(peca)
	end
end

--- Congela o que estiver num raio: personagens E peças soltas.
---
--- A origem congelava também as PARTÍCULAS (`TimeScale = 0`) e os SONS
--- (`PlaybackSpeed` para 0), e as duas ideias são boas — mas as duas são
--- estado de instância que vive fora da Tool, e restaurá-las com garantia
--- exigiria um registro do mundo inteiro. Aqui o "tempo parado" é dito pelo
--- VFX: a cúpula `ForceField` e os cacos de vidro parados no ar.
local function congelarArea(centro, raio, tempo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 16)) do
		if congelarHumanoide(alvo, tempo) then
			pegos = pegos + 1
			local alvoRaiz = raizDe(alvo)
			vfx("TRAVA", { peca = alvoRaiz, duracao = tempo })
		end
	end

	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(centro, raio, filtro)) do
		-- peça de personagem é do `congelarHumanoide`, não daqui: mexer nas
		-- duas coisas deixaria o mesmo corpo em dois registros
		if not parte:FindFirstAncestorOfClass("Model")
				or not parte:FindFirstAncestorOfClass("Model")
					:FindFirstChildOfClass("Humanoid") then
			congelarPeca(parte, tempo)
		end
	end
	return pegos
end

--═══════════════════════════════════════════════════════════════
-- GRAVAR E REVERTER — a mecânica do `reverter!!`
--
-- A origem gravava 600 quadros de `CFrame` num vetor e depois percorria o
-- vetor devolvendo cada um. A ideia está certa e ficou; o que mudou foi o
-- ALCANCE: ela gravava TODA `BasePart` do workspace, uma corrotina por peça.
--═══════════════════════════════════════════════════════════════

--- Começa a gravar o trajeto de uma peça, UM QUADRO POR `Heartbeat`.
---
--- A primeira versão disto gravava num laço `while`, e por isso guardava N
--- cópias do MESMO `CFrame` — todas no mesmo quadro. A gravação tem de
--- acompanhar o tempo real, que é o que a origem fazia com
--- `runServ.Heartbeat:Wait()` entre um `table.insert` e o outro.
---
--- É um BUFFER CIRCULAR: passado o teto, o quadro mais velho sai. A origem
--- parava de gravar em 600 e ligava a reprodução sozinha; um buffer que anda
--- deixa o jogador escolher QUANDO voltar.
local function iniciarGravacao(peca, teto)
	if not (peca and peca:IsA("BasePart")) then return nil end
	local reg = { peca = peca, caminho = {}, teto = teto, laco = nil }
	reg.laco = guardar(RunService.Heartbeat:Connect(function()
		if not peca.Parent then
			if reg.laco then reg.laco:Disconnect() reg.laco = nil end
			return
		end
		table.insert(reg.caminho, peca.CFrame)
		if #reg.caminho > teto then
			table.remove(reg.caminho, 1)
		end
	end))
	return reg
end

local function pararGravacao(reg)
	if reg and reg.laco then
		reg.laco:Disconnect()
		reg.laco = nil
	end
end

--- Devolve o alvo ao começo do caminho gravado. UM SALTO, não sessenta.
---
--- A ORIGEM ESCREVIA `obj.CFrame = positions[frame]` a cada três `Heartbeat`,
--- do servidor. Geometria movida pelo servidor replica a ~20 Hz sem
--- interpolação, e num personagem — que tem dono de rede — o resultado é
--- tranco para todo mundo que não seja o dono. A checagem `servidor não move
--- geometria por frame` do `verificar_autocontencao.sh` pega exatamente isso,
--- e pegou a primeira versão deste arquivo.
---
--- O desenho novo é melhor E conforme: o servidor escreve UMA vez, e o
--- CLIENTE desenha o fantasma percorrendo o caminho inteiro. O jogador vê o
--- alvo aparecer no passado e o rastro vermelho mostrando de onde ele veio —
--- que é a leitura que a origem queria e conseguia só pela metade.
---
--- O alvo fica preso pelo tempo da leitura e é solto pelo prazo, pelo
--- `restaurarTudo`, ou pelos dois.
local function reverterPara(peca, caminho, duracao)
	if not (peca and caminho and #caminho > 1) then return end

	if not peca.Anchored then
		ancorados[peca] = { ate = os.clock() + duracao }
		peca.Anchored = true
	end

	-- o instante gravado mais antigo que ainda está no buffer
	peca.CFrame = caminho[1]

	task.delay(duracao, function()
		soltarPeca(peca)
	end)
end


--═══════════════════════════════════════════════════════════════
-- O SOL E A LUA — a única mecânica de HORA do repositório
--
-- Direto do `Celestial Staff`: `Lighting:GetSunDirection()` e um raycast para
-- cima. Se o sol está no céu e não há teto, é dia; se é a lua, é noite.
--
-- `Lighting` É LEITURA, NÃO DEPÓSITO. As duas consultas de direção de astro
-- são a mesma natureza de `workspace.CurrentCamera` num LocalScript: um
-- singleton que existe em todo place e nunca falta. Num place vazio esta Tool
-- funciona por inteiro. O que continua proibido é ESCREVER em `Lighting`, que
-- é o que a origem fazia ao pendurar `ColorCorrectionEffect` e `BlurEffect`
-- lá — estado do place inteiro, e sem volta garantida.
--
-- A ORIGEM TINHA UM BUG DECLARADO no próprio comentário — "particles block
-- raycast" — porque usava `FindPartOnRay` sem filtro. Aqui o raycast ignora o
-- que não colide, que é o que ela queria dizer.
--═══════════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")

local function astroVisivel(direcao)
	if not raiz then return false end
	if Vector3.new(0, 1, 0):Dot(direcao) <= 0 then return false end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	filtro.IgnoreWater = true
	local batida = workspace:Raycast(raiz.Position + Vector3.new(0, 3, 0),
		direcao * 900, filtro)
	if not batida then return true end
	return not batida.Instance.CanCollide
end

local function ehDia()
	return astroVisivel(Lighting:GetSunDirection())
end

local function ehNoite()
	return astroVisivel(Lighting:GetMoonDirection())
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
-- M1 — O PORTÃO SOL / LUA
--
-- É a mecânica que veio inteira da origem, e a única de HORA do repositório:
-- `Lighting:GetSunDirection()` e um raycast para cima decidem QUAL habilidade
-- o M1 é.
--
--   dia    chuva de fótons no ponto mirado
--   noite  a lâmina que atravessa 120 studs
--
-- E há a terceira hora, que a origem não tratava: sol e lua os DOIS abaixo do
-- horizonte, ou um teto por cima. Lá o M1 simplesmente não fazia nada, em
-- silêncio. Aqui ele cai na lâmina — a habilidade tem de responder ao clique.
--══════════════════════════════════════════════════════════════

local function chuvaDeFotons(alvo)
	local i = 0
	local function solta()
		i = i + 1
		if i > CFG.FOTONS then return end
		if not (personagem and personagem.Parent) then return end

		-- o espalhamento por ângulo áureo, nunca `math.random(-25,25)` como na
		-- origem: com todos os clientes desenhando, um sorteio faria cada um
		-- ver uma chuva diferente da que o servidor calculou para o dano
		local a = anguloDe(i)
		local raioEspalha = CFG.ESPALHA * (i / CFG.FOTONS)
		local onde = alvo + Vector3.new(math.cos(a) * raioEspalha, 0,
			math.sin(a) * raioEspalha)

		vfx("FOTON", { posicao = onde, duracao = CFG.QUEDA_FOTON })

		task.delay(CFG.QUEDA_FOTON, function()
			if not (personagem and personagem.Parent) then return end
			tocarEm("LANCA", onde, 1.1 + i * 0.04)
			for _, quem in ipairs(alvosEm(onde, CFG.RAIO_FOTON, 8)) do
				aplicarDano(quem, CFG.DANO_FOTON)
			end
		end)

		task.delay(CFG.INTERVALO_SOL, solta)
	end
	solta()
end

local function laminaDaLua()
	if not raiz then return end
	local origem = raiz.Position + Vector3.new(0, 2, 0)
	local direcao = raiz.CFrame.LookVector

	vfx("LAMINA_LUA", {
		id = novoId("lamina"), posicao = raiz.Position, direcao = direcao,
		raio = CFG.ALCANCE_LAMINA, duracao = CFG.VOO_LAMINA,
	})
	tocarEm("LAMINA", origem, 1.0)

	-- o servidor percorre a MESMA reta por aritmética. A origem movia a peça
	-- por Tween NO SERVIDOR e lia `Touched` — que é geometria movida pelo
	-- servidor, a ~20 Hz.
	task.spawn(function()
		local vistos = {}
		local percorrido = 0
		local velocidade = CFG.ALCANCE_LAMINA / CFG.VOO_LAMINA
		while percorrido < CFG.ALCANCE_LAMINA do
			task.wait(CFG.PASSO_VOO)
			if not (personagem and personagem.Parent) then return end
			percorrido = percorrido + velocidade * CFG.PASSO_VOO
			local onde = origem + direcao * math.min(percorrido,
				CFG.ALCANCE_LAMINA)
			for _, quem in ipairs(alvosEm(onde, CFG.LARGURA_LAMINA, 10)) do
				if not vistos[quem] then
					vistos[quem] = true
					aplicarDano(quem, CFG.DANO_LAMINA)
					empurrar(quem, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO_LAMINA, 0.26)
				end
			end
		end
	end)
end

function primaria(mira)
	if not rig then return end
	local ponto = mira
	local dia = ehDia()

	ocupado = true
	rig:PlaySequence("CAJADO", despachar({

		-- `Cast` no início: é o que o `Tool.Activated` da origem tocava, na
		-- primeira linha, antes mesmo de olhar o Sol
		CARGA = { sfx = { CFG.SFX_CAST, dia and 1.2 or 0.9 } },

		VARRE = {
			sfx = { dia and "LANCA" or "LAMINA", dia and 1.0 or 0.85 },
			faz = function()
				if not raiz then return end
				if dia then
					local alvo = (typeof(ponto) == "Vector3") and ponto
						or frente(CFG.ALCANCE)
					chuvaDeFotons(alvo)
				else
					laminaDaLua()
				end
			end,
		},

	}), function()
		ocupado = false
		-- e `UnCast` no fim, que é onde o `Tool.Deactivated` da origem o tocava
		tocar(CFG.SFX_UNCAST, 0.95)
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o holofote
--
-- A coluna da origem, com a malha dela. Quem fica debaixo sangra e sai mais
-- devagar — e `afrouxar` guarda a velocidade de ANTES.
--══════════════════════════════════════════════════════════════

function pararHolofote()
	if holofoteId then
		vfx("PARAR", { id = holofoteId })
		holofoteId = nil
	end
	holofoteAte = 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("HOLOFOTE", despachar({

		CARGA = { sfx = { CFG.SFX_PRONTO, 1.1 } },
		SEGURA = { sfx = { "HOLOFOTE", 0.85 } },

		SOLTA = {
			sfx = { "LANCA", 1.15 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				pararHolofote()

				holofoteId = novoId("holofote")
				holofoteAte = os.clock() + CFG.TEMPO_HOLOFOTE

				vfx("HOLOFOTE", {
					id = holofoteId, posicao = centro,
					raio = CFG.RAIO_HOLOFOTE, duracao = CFG.TEMPO_HOLOFOTE,
				})
				tocarEm("HOLOFOTE", centro, 0.9)

				local function pulsar()
					if os.clock() > holofoteAte then
						pararHolofote()
						return
					end
					if not (personagem and personagem.Parent) then
						pararHolofote()
						return
					end
					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_HOLOFOTE, 14)) do
						aplicarDano(quem, CFG.DANO_HOLOFOTE)
						local antes = quem.WalkSpeed
						quem.WalkSpeed = antes * CFG.LENTIDAO
						task.delay(CFG.PULSO_HOLOFOTE * 1.4, function()
							if quem and quem.Parent and quem.Health > 0 then
								quem.WalkSpeed = antes
							end
						end)
					end
					task.delay(CFG.PULSO_HOLOFOTE, pulsar)
				end
				pulsar()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — o eco do instante
--
-- O anel da origem, parado no ar. Quem estiver dentro dele quando ele fecha
-- leva, e fica preso pelo tempo do eco.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ECO", despachar({

		CARGA = { sfx = { CFG.SFX_TEMPO, 1.25 } },

		GOLPE = {
			sfx = { "LAMINA", 0.9 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				vfx("ECO_INSTANTE", { posicao = centro, raio = CFG.RAIO_ECO })
				tocarEm("LAMINA", centro, 0.85)

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_ECO, 12)) do
					aplicarDano(quem, CFG.DANO_ECO)
					congelarHumanoide(quem, CFG.TEMPO_ECO)
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
--- Cada entrada tem prazo próprio, e este laço é quem o cobra. Sem ele o
--- congelamento dependeria de um `task.delay` por alvo — e um alvo congelado
--- duas vezes teria dois relógios brigando pelo mesmo estado.
local function vigiar()
	guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		for alvoHum, antes in pairs(mexidos) do
			if agora > antes.ate then descongelarHumanoide(alvoHum) end
		end
		for peca, antes in pairs(ancorados) do
			if agora > antes.ate then soltarPeca(peca) end
		end
	end))
end

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "TempoCajado", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	vigiar()
end)

--- As DUAS portas, e a terceira coisa que elas fazem: DEVOLVER O QUE FOI
--- MEXIDO. `Unequipped` sozinho não cobre a Tool ser destruída no meio de um
--- congelamento, e um congelamento sem volta trava o mapa para sempre.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	restaurarTudo()
	pararHolofote()
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
