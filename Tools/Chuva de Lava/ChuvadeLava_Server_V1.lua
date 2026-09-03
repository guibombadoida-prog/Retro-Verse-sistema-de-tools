-- ChuvadeLava_Server_V1.lua
-- Script de servidor — Chuva de Lava  (conjunto NOOB)
--
-- Sai do `noob_despertado.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_noob.py` para o mapa.
--
--   M1   a laje que sobe — ultimate com cutscene
--   R    —  (esta Tool tem uma habilidade so)   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   laje clonada de `script.Lava`, **900 x 20 x 900 studs** (un.lua:1918)
--   sobe 2 studs por quadro, 10 quadros, com `wait(0.08)` (un.lua:1938)
--   ApplyAoE(new.Position, **900**, 90, 100, 0, **true**) (un.lua:1936)
--      raio 900 com INSTAKILL -> 105 no nucleo de 12, 46 na borda de 30
--   som 159882598 volume 10 e 62339698 volume 10 -> volume 2
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_noob.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	ALCANCE        = 10,
	RECARGA        = 34,
	RAIO_CENA      = 46,
	RAIO_LAVA      = 30,
	RAIO_NUCLEO    = 12,
	DANO_NUCLEO    = 105,
	DANO_BORDA     = 46,
	EMPURRAO       = 110,
	TOMBO          = 2.6,
	DURACAO_LAJE   = 4.5,
	LENTIDAO       = 0.6,
	TEMPO_LENTO    = 3,

	RECARGA_EXTRA  = 1,
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
local lajeId = nil

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

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Handle/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight"). Tool
--- antiga não muda de comportamento.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o clone é
--- parenteado no `Handle` pelo servidor, então a INSTÂNCIA replica e todo
--- mundo ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons
--- diferentes para o mesmo golpe.
---
--- ⚠️ O último `return` do sorteio não é paranoia: `math.random() * total`
---    pode sobrar por arredondamento e cair fora do laço. A implementação de
---    onde a ideia veio devolve `nil` aí — um som mudo, calado, de vez em
---    quando.
---
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1.
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

local function somDe(nome)
	local achado = Handle:FindFirstChild(nome)
	if not achado then
		local pasta = Tool:FindFirstChild("SFX")
		achado = pasta and pasta:FindFirstChild(nome)
	end
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
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
-- A CUTSCENE — um `FireClient` POR ESPECTADOR
--
-- `GRAMATICA_CUTSCENE.md` regra 2: enquadramento por espectador.
--
-- As duas cenas deste conjunto nascem NO PORTADOR: a laje sobe sob os pés
-- dele, a coroa desce sobre a cabeça. A plateia é quem está no raio, e cada um
-- recebe o papel dele. Quem está fora não perde a câmera.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(plateia, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

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
-- O DESPACHANTE DE BEAT
--
-- ⚠️ ESTE BLOCO ESTAVA FALTANDO. O gerador emitia `despachar({...})` em toda
--    habilidade e NUNCA emitia a definição: `attempt to call a nil value` na
--    primeira linha de cada `primaria`/`extra`. Sem dano, sem VFX, sem som —
--    28 Tools de quatro conjuntos, mortas.
--
--    A conversão de `if marca == "X"` para tabela de keyframe trocou o corpo
--    das habilidades nos GERADORES, mas só três dos sete ganharam a definição
--    junto. Os arquivos `.lua` já gerados continuaram certos até alguém
--    regerar — e aí a Tool inteira parava.
--
-- Cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { cam = true, sfx = { "IMPACTO", 0.9 }, faz = bater }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe
--   `sfx`  toca um som: `{ nome, pitch }`
--   `faz`  o trabalho que não cabe em dado
--
-- `beatCena` só existe nas Tools com cutscene. Nas outras ele é nil, e a
-- guarda `kf.cam and beatCena` resolve — ler global inexistente devolve nil,
-- não estoura.
--═══════════════════════════════════════════════════════════════

--- ⚠️ `beatCena` DECLARADO, mesmo nas Tools sem cutscene.
---
--- A guarda do despachante é `if kf.cam and beatCena then`, e sem esta linha
--- `beatCena` é uma GLOBAL IMPLÍCITA: em Lua ler global inexistente devolve
--- `nil`, então o curto-circuito segura e nada quebra — hoje.
---
--- O risco não é este arquivo: é qualquer script do place que um dia crie uma
--- global com esse nome. A partir daí `kf.cam` verdadeiro chamaria função de
--- estranho, com os argumentos desta Tool.
---
--- Nas Tools COM cutscene, o `local function beatCena` mais abaixo sombreia
--- este `nil` — que é o comportamento certo, e é por isso que a declaração
--- pode ser incondicional.
local beatCena = nil

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
-- PRIMÁRIA — a laje, COM CUTSCENE
--
-- ULTIMATE: 7.10 s com 70% de preparação, dentro da faixa da regra 5.
--
-- A peça de origem tem **900 × 20 × 900 studs**, o mesmo 900 do
-- `ApplyAoE(..., 900, ...)`: a laje ERA o raio. Os dois vieram para 30 juntos,
-- porque mexer num sem o outro deixaria o efeito mentindo sobre o alcance.
--═══════════════════════════════════════════════════════════════

local function apagarLaje()
	if lajeId then
		vfx("APAGAR", { id = lajeId })
		lajeId = nil
	end
end

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 14), "CAMERA")

	rig:PlaySequence("LAVA", despachar({
		CAMERA = { sfx = { "GRAVE", 0.55 } },
		CARGA = { cam = true, sfx = { "ESTOURO", 0.6 } },
		SEGURA = { cam = true },
		DESCE = { cam = true, faz = function()
			apagarLaje()
			local onde = raiz and raiz.Position or centro
			lajeId = novoId("LAJE")
			vfx("LAVA", { posicao = onde, escala = 1, raio = CFG.RAIO_LAVA,
				duracao = CFG.DURACAO_LAJE, id = lajeId })
			tocarEm("GRAVE", onde, 0.5)
		end },
		GOLPE = { cam = true, faz = function()
			local onde = raiz and raiz.Position or centro
			vfx("LAVA_FIM", { posicao = onde, escala = 1.6 })
			tocarEm("ESTOURO", onde, 0.7)
			tocarEm("ECO", onde, 0.6)
			golpearArea(onde, CFG.RAIO_LAVA, CFG.RAIO_NUCLEO,
				CFG.DANO_NUCLEO, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_LAVA, 16)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
			end
		end },
		FIM = { faz = function()
			apagarLaje()
			fecharCena()
		end },
	}), function()
		apagarLaje()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- SEM EXTRA
--
-- O `mode == "banish"` da origem tinha três ataques e os três já estão no
-- `Tiro do Vazio` (z e c). A Lava é o `x`, e sozinha: uma ultimate de 7 s com
-- segunda habilidade por cima seria a Tool inteira num botão.
--
-- `extra` existe e não faz nada porque o `AcaoRemote` está montado — a Tool
-- não ganha botão de toque, e apertar a tecla não deve dar erro.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	return
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

	rig = Animator.new(personagem, "NoobChuvaLava", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	apagarLaje()
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
-- ⚠️ ISTO VIVIA FORA DO GERADOR, e o defeito estava em NOVE conjuntos.
--
--    A ligação tinha sido enxertada nos arquivos PRONTOS por
--    `FERRAMENTAS/ligar_deposito.py`, uma vez. Enquanto ninguém regerasse,
--    tudo passava. A primeira regeneração de cada conjunto a perdia — em
--    silêncio, porque o Server continua funcionando sem ela; o que para é o
--    VFX sair da Tool.
--
--    Enxerto que não volta para o gerador é conserto que dura até a próxima
--    geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
