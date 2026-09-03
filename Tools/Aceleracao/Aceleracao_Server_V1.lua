-- Aceleracao_Server_V1.lua
-- Script de servidor — Aceleracao  (conjunto TEMPO)
--
--   M1   Golpe Acelerado
--   R    Passo Rapido   (Extra 1)
--   T    Envelhecer   (Extra 2)
--
--   Handle autoral: ampulheta deitada, a areia correndo depressa
--   GOLPE 127416781 (ChargeReady) · PASSO 4750661969 (Cast)
--   ENVELHECE 116049255 (TimeSound) — os tres da ficha do Acervo
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

local ARQUETIPO = "MELEE"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	ALCANCE       = 12,
	RECARGA       = 0.6,
	GOLPES        = 3,
	INTERVALO     = 0.05,
	RAIO          = 8,
	DANO          = 16,

	RECARGA_R     = 14,
	TEMPO_PASSO   = 5,
	FATOR_ANDAR   = 1.9,
	FATOR_SALTO   = 1.35,

	RECARGA_T     = 19,
	RAIO_VELHICE  = 22,
	TEMPO_VELHICE = 4,
	TIQUES        = 5,
	DANO_BASE     = 8,
	CRESCE        = 1.55,
	LENTIDAO      = 0.6,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA, e o repositório inteiro dependia
--    dele: eram 217 pontos que conferiam só o TIPO.
--
--    `Vector3.new(0/0, 0/0, 0/0)` é um `Vector3` legítimo para o `typeof`.
--    Um cliente modificado manda isso, `.Unit` devolve NaN, e força NaN
--    aplicada a uma peça envenena a assembly dela — o alvo trava, voa para
--    coordenada absurda, ou o solver do motor engasga. Nenhum `pcall` pega,
--    porque não há erro: a conta simplesmente não tem resultado.
--
--    `n ~= n` é o único teste de NaN que funciona em Lua: NaN é o único valor
--    que não é igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda
--    na mesma linha.
--
-- E RATE LIMIT É DO SERVIDOR, não do cliente.
--
--    O `Client` já limita a 20 Hz, e isso não vale nada: quem manda o pacote
--    é o cliente, e cliente modificado manda a 2 000 Hz. O limite que conta
--    é o daqui.
--═══════════════════════════════════════════════════════════════

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
---
--- O corte por alcance não é só anticheat: mira a 5 000 studs faria o
--- `noChao()` varrer 400 studs de raycast a partir de um ponto onde não há
--- mapa, e a habilidade nasceria no vazio.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > CFG.MIRA_MAX then
		return raiz.Position + delta.Unit * CFG.MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem está abusando é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= CFG.PEDIDOS_POR_SEG
end
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT
local passoAte = 0
local meuAndar, meuSalto, minhaAltura = nil, nil, nil

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
-- M1 — o golpe acelerado
--
-- Três golpes com 0.05 s entre eles. Não é combo: é UMA entrada, e os três
-- saem juntos demais para o olho separar. É o `TimeScale` da origem visto do
-- outro lado — lá o tempo ia a zero, aqui ele corre.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ACELERADO", despachar({

		CARGA = { sfx = { "GOLPE", 1.35 } },

		GOLPE = {
			sfx = { "GOLPE", 1.15 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("GOLPE_RAPIDO", { posicao = raiz.Position,
					direcao = direcao, raio = CFG.RAIO })

				local n = 0
				local function bater()
					n = n + 1
					if n > CFG.GOLPES then return end
					if not (personagem and personagem.Parent and raiz) then
						return
					end
					local aqui = raiz.Position
						+ raiz.CFrame.LookVector * (CFG.ALCANCE * 0.6)
					for _, quem in ipairs(alvosEm(aqui, CFG.RAIO, 8)) do
						aplicarDano(quem, CFG.DANO)
					end
					task.delay(CFG.INTERVALO, bater)
				end
				bater()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o passo rápido
--
-- Guarda `WalkSpeed`, `JumpPower` e `JumpHeight` de ANTES e devolve ESSES.
-- Devolver 16 e 50 fixos quebraria qualquer personagem que tenha os dele — e
-- é o defeito clássico que a REGRA_AUTOCONTENCAO chama de "efeito de status
-- que não volta".
--══════════════════════════════════════════════════════════════

function devolverPasso()
	if not humanoide then return end
	if meuAndar then humanoide.WalkSpeed = meuAndar end
	if meuSalto then humanoide.JumpPower = meuSalto end
	if minhaAltura then humanoide.JumpHeight = minhaAltura end
	meuAndar, meuSalto, minhaAltura = nil, nil, nil
	passoAte = 0
end

function extraR()
	if not rig or not humanoide then return end

	ocupado = true
	rig:PlaySequence("PASSO", despachar({

		CARGA = { sfx = { "PASSO", 1.35 } },

		GOLPE = {
			sfx = { "PASSO", 1.2 },
			faz = function()
				if not (humanoide and raiz) then return end

				-- guarda contra empilhar: acionar duas vezes guardaria o valor
				-- JÁ ACELERADO como "o de antes", e o passo nunca voltaria
				if not meuAndar then
					meuAndar = humanoide.WalkSpeed
					meuSalto = humanoide.JumpPower
					minhaAltura = humanoide.JumpHeight
				end

				humanoide.WalkSpeed = meuAndar * CFG.FATOR_ANDAR
				humanoide.JumpPower = meuSalto * CFG.FATOR_SALTO
				humanoide.JumpHeight = minhaAltura * CFG.FATOR_SALTO
				passoAte = os.clock() + CFG.TEMPO_PASSO

				vfx("PASSO_RAPIDO", { id = novoId("passo"), peca = raiz,
					duracao = CFG.TEMPO_PASSO })

				task.delay(CFG.TEMPO_PASSO, function()
					if os.clock() >= passoAte then devolverPasso() end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — envelhecer
--
-- O tempo do alvo corre depressa demais. O dano por tique CRESCE a cada
-- tique — é o que separa isto de um veneno comum, e é o que dá razão para
-- deixar o alvo vivo por quatro segundos.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ENVELHECER", despachar({

		CARGA = { sfx = { "ENVELHECE", 1.0 } },

		VARRE = {
			sfx = { "ENVELHECE", 0.8 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				tocarEm("ENVELHECE", centro, 0.85)

				local pegos = alvosEm(centro, CFG.RAIO_VELHICE, 14)
				for _, quem in ipairs(pegos) do
					local qr = raizDe(quem)
					vfx("ENVELHECER", { id = novoId("velhice"), peca = qr,
						posicao = qr and qr.Position or centro,
						duracao = CFG.TEMPO_VELHICE })

					local antes = quem.WalkSpeed
					quem.WalkSpeed = antes * CFG.LENTIDAO
					task.delay(CFG.TEMPO_VELHICE, function()
						if quem and quem.Parent and quem.Health > 0 then
							quem.WalkSpeed = antes
						end
					end)
				end

				local tique = 0
				local passo = CFG.TEMPO_VELHICE / CFG.TIQUES
				local function envelhecer()
					tique = tique + 1
					if tique > CFG.TIQUES then return end
					if not (personagem and personagem.Parent) then return end
					local dano = CFG.DANO_BASE * (CFG.CRESCE ^ (tique - 1))
					for _, quem in ipairs(pegos) do
						aplicarDano(quem, math.floor(dano + 0.5))
					end
					task.delay(passo, envelhecer)
				end
				task.delay(passo, envelhecer)
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
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end

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

	rig = Animator.new(personagem, "TempoAceleracao", Poses,
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
	devolverPasso()
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
