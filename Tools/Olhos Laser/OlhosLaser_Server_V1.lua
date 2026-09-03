-- OlhosLaser_Server_V1.lua
-- Script de servidor — Olhos Laser  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   feixe continuo enquanto segurar o clique
--   R    Sobrecarga   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- Gerado por FERRAMENTAS/gerar_servers_drama.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

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

local ARQUETIPO = "RANGED"

local CFG = {
	ALCANCE       = 6,
	ALCANCE_FEIXE = 220,
	RECARGA       = 2.6,
	DURACAO_FEIXE = 6,
	INTERVALO     = 0.12,
	DANO_TIQUE    = 4,
	RAIO_FEIXE    = 3.5,
	PASSOS_FEIXE  = 22,
	ALTURA_OLHOS  = 1.5,

	RECARGA_EXTRA = 14,
	CARGA_SOBRE   = 0.9,
	RAIO_SOBRE    = 22,
	NUCLEO_SOBRE  = 8,
	DANO_SOBRE    = 62,
	BORDA_SOBRE   = 30,
	EMPURRAO_SOBRE = 72,
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
local feixeLigado = false
local idFeixe = nil
local pontoFeixe = nil
local geracaoFeixe = 0
--- `function x()` sem esta linha atribui a uma GLOBAL
local apontar, fechar

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 39 `math.random` da origem:
--- mesma variedade, e os dois clientes veem a mesma coisa.
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
-- O `Fists` de origem tinha NOVE `Health = Health - x` e UM `TakeDamage`.
-- `Health` direto ignora `ForceField`; `TakeDamage` não.
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

--- Alvos num raio. O `Fists` varria `workspace:GetDescendants()` e o `dodge`
--- mantinha uma tabela viva de TODO Humanoid do jogo por
--- `workspace.DescendantAdded`. Aqui é consulta espacial sob demanda, e quem
--- filtra time é o Núcleo.
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

--- O alvo mais perto de um ponto. É quem a cutscene enquadra.
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

--- Tombo com prazo. O `Fists` usava `BreakJoints`, que desmonta sem volta.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta GARANTIDA.
---
--- ELE FALTAVA. O `Corte Frio` chamava `afrouxar` em DOIS lugares — no beat do
--- corte e no gelo do chão — e ele não existia em lugar nenhum do arquivo:
--- `attempt to call a nil value`, e as duas habilidades morriam caladas. Só
--- apareceu quando a lista `AJUDANTES` do `verificar_beats.py` cresceu.
---
--- Guarda a velocidade de ANTES e devolve ESSA, nunca 16 fixo: o alvo pode ter
--- velocidade própria, e devolver um número chapado quebra quem tinha.
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
-- ATORDOAR — trava no lugar, e devolve garantido
--
-- Diferente do `tombar`: quem está atordoado continua DE PÉ. A leitura é
-- "travou", não "caiu", e as duas habilidades que atordoam neste conjunto
-- (o counter e a aura) querem a primeira.
--
-- O atributo não é enfeite. Sem ele, um segundo atordoamento em cima do
-- primeiro guardaria `WalkSpeed = 0` como "o valor de antes" e devolveria
-- zero no fim — o alvo ficaria parado para sempre. É o bug clássico de
-- lentidão que empilha, e ele não aparece em teste de um alvo só.
--═══════════════════════════════════════════════════════════════

local function atordoar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum:GetAttribute("DramaAtordoado") then return end

	local usaPotencia = alvoHum.UseJumpPower
	local andar = alvoHum.WalkSpeed
	local pular = usaPotencia and alvoHum.JumpPower or alvoHum.JumpHeight

	alvoHum:SetAttribute("DramaAtordoado", true)
	alvoHum.WalkSpeed = 0
	if usaPotencia then
		alvoHum.JumpPower = 0
	else
		alvoHum.JumpHeight = 0
	end

	task.delay(tempo or 1, function()
		if alvoHum and alvoHum.Parent then
			alvoHum.WalkSpeed = andar
			if usaPotencia then
				alvoHum.JumpPower = pular
			else
				alvoHum.JumpHeight = pular
			end
			alvoHum:SetAttribute("DramaAtordoado", nil)
		end
	end)
end

--═══════════════════════════════════════════════════════════════
-- QUEM ME BATEU — a etiqueta `creator`, lida do lado de dentro
--
-- O contra-ataque do `Combate` e a aura do `Aura` precisam da MESMA coisa: a
-- identidade de quem acabou de me acertar. O repositório já grava isso —
-- `creditar()` põe um `ObjectValue` chamado `creator` no Humanoid da VÍTIMA, e
-- o Núcleo faz igual em `marcarCredito`. A informação já está aqui dentro;
-- basta ler.
--
-- ⚠️ Nada de gancho global de sistema nenhum: a Tool não conhece sistema.
--    Ler a etiqueta funciona num place vazio, que é o que a Regra nº 1 cobra.
--═══════════════════════════════════════════════════════════════

local function quemMeBateu()
	if not humanoide then return nil end

	local marca = humanoide:FindFirstChild("creator")
	local autor = marca and marca:IsA("ObjectValue") and marca.Value or nil
	if autor and autor:IsA("Player") then
		local corpo = autor.Character
		local hum = corpo and corpo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then return hum end
	end

	-- Sem etiqueta — dano de queda, de NPC sem crédito, de qualquer coisa. O
	-- mais perto é o palpite honesto, e ele é LIMITADO POR RAIO: devolver dano
	-- em quem está do outro lado do mapa seria pior que não devolver nada.
	if raiz then
		return maisPerto(raiz.Position, CFG.RAIO_DEVOLVE or 24)
	end
	return nil
end

--- Vigia a própria vida e chama `aoLevar(quanto, quemBateu)` a cada QUEDA.
---
--- `HealthChanged` também dispara em cura; a subtração filtra. E a conexão é
--- devolvida para quem chamou desligar — janela de counter que fica ligada
--- depois do prazo é counter permanente.
local function vigiarVida(aoLevar)
	if not humanoide then return nil end
	local anterior = humanoide.Health
	return humanoide.HealthChanged:Connect(function(nova)
		local queda = anterior - nova
		anterior = nova
		if queda <= 0 then return end
		aoLevar(queda, quemMeBateu())
	end)
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


--══════════════════════════════════════════════════════════════
-- M1 — o feixe contínuo
--
-- O pedido foi "igual do Capitão Pátria", e o que define aquele feixe é que
-- ele é SEGURADO e VARRE. Tiro único aponta para onde estava o mouse quando
-- saiu; este acompanha, e é a varredura que corta o que atravessa.
--
-- TRÊS FASES NUM `RemoteEvent` SÓ
--
--   `ABRE` no `Tool.Activated`, `MIRA` a cada 0.08 s enquanto o clique está
--   mantido, `FECHA` no `Tool.Deactivated`. A fase vem no payload e é
--   conferida no servidor antes de qualquer coisa — um segundo remote seria
--   outra porta para o mesmo cômodo, e outra superfície para validar.
--
--   `MIRA` e `FECHA` NÃO passam por recarga e passam mesmo com `ocupado`.
--   Têm de passar: enquanto o feixe está de pé o estado É ocupado.
--
-- O DANO É POR TIQUE, NÃO POR QUADRO
--
--   `INTERVALO = 0.12` — cerca de 8 tiques por segundo, 4 de dano cada. Um
--   tique por quadro daria 60, e a mesma habilidade custaria 30 de dano por
--   segundo ou 240 dependendo do FPS de quem segura. Dano que depende de
--   framerate não é dano, é loteria.
--
-- O TETO DE TEMPO NÃO É ENFEITE
--
--   `DURACAO_FEIXE = 6`. Soltar o clique é o caminho normal de fechar, e ele
--   não pode ser o ÚNICO: um alt-tab, uma queda de conexão ou um cliente que
--   some deixariam o feixe ligado para sempre. O servidor conta o tempo dele.
--══════════════════════════════════════════════════════════════

--- Colhe a linha do olho até o ponto mirado. `vistos` impede o mesmo alvo de
--- levar duas vezes por estar entre dois passos.
local function queimarLinha(destino)
	local saida = raiz.Position + Vector3.new(0, CFG.ALTURA_OLHOS, 0)
	local delta = destino - saida
	local distancia = math.min(delta.Magnitude, CFG.ALCANCE_FEIXE)
	if distancia < 1 then return saida, saida end
	local direcao = delta.Unit
	local fim = saida + direcao * distancia

	local vistos = {}
	for i = 1, CFG.PASSOS_FEIXE do
		local passo = saida + direcao * (distancia * i / CFG.PASSOS_FEIXE)
		for _, alvo in ipairs(alvosEm(passo, CFG.RAIO_FEIXE, 6)) do
			if not vistos[alvo] then
				vistos[alvo] = true
				aplicarDano(alvo, CFG.DANO_TIQUE)
			end
		end
	end
	return saida, fim
end

--- Um tique do feixe. Recursivo por `task.delay`, e a GERAÇÃO é o que impede
--- dois feixes de rodarem juntos se o jogador reabrir antes do anterior morrer.
local function tiqueFeixe(geracao, restantes)
	if not (feixeLigado and geracao == geracaoFeixe) then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		fechar()
		return
	end

	local destino = pontoFeixe or frente(CFG.ALCANCE_FEIXE)
	local saida, fim = queimarLinha(destino)
	vfx("FEIXE", { id = idFeixe, posicao = saida, para = fim, escala = 1,
		tempo = CFG.INTERVALO })

	task.delay(CFG.INTERVALO, function()
		tiqueFeixe(geracao, restantes - 1)
	end)
end

--- A mira móvel. Não é habilidade: não passa por recarga, e só anota o ponto.
--- Quem decide se ele ainda vale é o servidor, que sabe se o feixe existe.
function apontar(mira)
	if not feixeLigado then return end
	pontoFeixe = mira
end

function fechar()
	if not feixeLigado then return end
	feixeLigado = false
	geracaoFeixe = geracaoFeixe + 1
	pontoFeixe = nil
	if idFeixe then
		vfx("PARAR", { id = idFeixe })
		idFeixe = nil
	end
	-- saída cedo em vez de aninhar: com o `PlaySequence` dentro de um `if`, o
	-- bloco do `despachar` fecha com uma tabulação a mais, e o
	-- `TESTES/verificar_beats.py` casa o fim errado — ele leu os beats da
	-- sequência SEGUINTE como se fossem desta. O verificador estava certo em
	-- reclamar; quem estava torto era a indentação.
	if not rig then
		ocupado = false
		return
	end
	rig:PlaySequence("FEIXE_FECHA", despachar({
		CORTA = { sfx = { "GOLPE", 1.4 } },
	}), function() ocupado = false end)
end

function primaria(mira)
	if feixeLigado then return end
	ocupado = true
	feixeLigado = true
	pontoFeixe = mira
	geracaoFeixe = geracaoFeixe + 1
	local geracao = geracaoFeixe
	idFeixe = novoId("FEIXE")

	rig:PlaySequence("FEIXE_ABRE", despachar({
		MIRA = { sfx = { "PREPARA", 1.4 } },
		ATIRA = { sfx = { "CARGA", 1.25 }, faz = function()
			-- a pose fica em `FEIXE_OLHOS` até alguém tocar outra sequência:
			-- `PlaySequence` para no último keyframe e não volta ao IDLE.
			tiqueFeixe(geracao, math.floor(CFG.DURACAO_FEIXE / CFG.INTERVALO))
		end },
	}))
end

--══════════════════════════════════════════════════════════════
-- R — Sobrecarga
--
-- O outro lado do mesmo poder: em vez de varrer, ele CONCENTRA. Carrega
-- `CARGA_SOBRE` segundos e estoura num ponto, com núcleo e borda.
--
-- Ela FECHA o feixe antes de começar. Os dois usam os olhos, e deixar os dois
-- ligados ao mesmo tempo daria dois desenhos disputando a mesma cabeça.
--══════════════════════════════════════════════════════════════

function extra(mira)
	fechar()
	ocupado = true
	local destino = mira

	rig:PlaySequence("SOBRECARGA", despachar({
		MIRA = { sfx = { "PREPARA", 0.9 } },
		ABRE = { faz = function()
			vfx("SOBRECARGA_CARGA", { posicao = raiz.Position
				+ Vector3.new(0, CFG.ALTURA_OLHOS, 0), escala = 1,
				vida = CFG.CARGA_SOBRE })
		end },
		CARREGA = { sfx = { "CARGA", 0.75 } },
		ESTOURA = { faz = function()
			local saida = raiz.Position + Vector3.new(0, CFG.ALTURA_OLHOS, 0)
			vfx("SOBRECARGA", { posicao = destino, de = saida,
				raio = CFG.RAIO_SOBRE, escala = 1 })
			tocarEm("IMPACTO", destino, 0.7)

			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_SOBRE, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - destino).Magnitude
					or CFG.RAIO_SOBRE
				if d <= CFG.NUCLEO_SOBRE then
					aplicarDano(alvo, CFG.DANO_SOBRE)
				else
					aplicarDano(alvo, CFG.BORDA_SOBRE)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - destino)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SOBRE, 0.28)
				end
			end
		end },
		FIM = { sfx = { "GOLPE", 0.8 } },
	}), function() ocupado = false end)
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


--- TRÊS fases num remote só. A FASE vem no payload e é conferida aqui antes
--- de qualquer coisa; um segundo `RemoteEvent` seria outra porta para o mesmo
--- cômodo, e outra superfície para validar.
---
--- `MIRA` e `FECHA` passam mesmo com `ocupado`. Têm de passar: enquanto o
--- feixe está de pé o estado É ocupado, e exigir que ele acabe tornaria
--- impossível mirar e soltar.
VFXRemote.OnServerEvent:Connect(function(quem, mira, fase)
	if quem ~= jogador then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if fase == "MIRA" then
		apontar(mira)
		return
	end
	if fase == "FECHA" then
		fechar()
		return
	end

	if not podeAgir() then return end
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

	rig = Animator.new(personagem, "DramaOlhos", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	fechar()
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
--
-- ISTO ESTAVA FORA DO GERADOR. A ligação tinha sido enxertada nos arquivos
-- prontos por `FERRAMENTAS/ligar_deposito.py`, e por isso a primeira
-- regeneração do DRAMA a perdeu — as sete Tools voltaram a não ter depósito, e
-- só o `verificar_deposito_vfx.py` percebeu. Enxerto que não volta para o
-- gerador é conserto que dura até a próxima geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
