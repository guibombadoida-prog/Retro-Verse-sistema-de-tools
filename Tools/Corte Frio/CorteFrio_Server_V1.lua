-- CorteFrio_Server_V1.lua
-- Script de servidor — Corte Frio  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   corte de lamina que congela
--   R    Serie de Cortes   (Extra, por `AcaoRemote` — e por botão no celular)
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
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 7,
	RAIO_CORTE    = 7.5,
	DANO          = 26,
	EMPURRAO      = 24,
	LENTIDAO      = 0.6,
	TEMPO_FRIO    = 1.8,
	RECARGA       = 0.9,

	RECARGA_EXTRA = 22,
	RAIO_ALVO     = 14,
	DANO_CORTE    = 16,
	DANO_ULTIMO   = 44,
	CORTES        = 5,
	AVANCO        = 6,
	DURACAO_GELO  = 2.8,
	LENTIDAO_GELO = 0.3,
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
local alvoDaSerie = nil
local cortesDados = 0

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
-- A CUTSCENE — um `FireClient` POR ESPECTADOR
--
-- `GRAMATICA_CUTSCENE.md` regra 2: enquadramento por espectador.
--
--   quem invoca  ->  vê o golpe de fora, com o alvo no quadro
--   quem é alvo  ->  vê a SI MESMO sendo alcançado
--
-- Uma cena que mostra a mesma coisa para o algoz e para a vítima desperdiça
-- metade dela. O servidor sabe quem é quem, e é aqui que ele diz.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

--- Quem assiste: SÓ o portador e o alvo, cada um com o papel dele.
---
--- Não é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
--- câmera por causa de uma briga alheia — e uma cutscene que toma a câmera de
--- quem não está envolvido é a definição de tempo morto.
local function abrirCena(alvoHum, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true
	local corpoAlvo = alvoHum and alvoHum.Parent
	local nomeAlvo = corpoAlvo and corpoAlvo.Name or nil

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, alvoNome = nomeAlvo,
	})

	-- a outra metade da regra 2: o alvo recebe a cena DELE
	local jogadorAlvo = corpoAlvo and Players:GetPlayerFromCharacter(corpoAlvo)
	if jogadorAlvo and jogadorAlvo ~= jogador then
		CutsceneRemote:FireClient(jogadorAlvo, "INICIO", {
			papel = "ALVO", nome = nomeBeat,
			portador = personagem.Name, alvoNome = nomeAlvo,
		})
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
-- M1 — o corte
--
-- Corte de lâmina que deixa o alvo LENTO. É o preparo da Extra: alvo devagar é
-- alvo que ainda está lá quando a série começa.
--══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CORTE", despachar({
		ERGUE = { sfx = { "PREPARA", 1.2 } },
		CORTA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local q = raiz.CFrame * CFrame.new(0, 1, -3)
			vfx("CORTE", { cframe = q, escala = 1 })
			local pegou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CORTE, 6)) do
				aplicarDano(alvo, CFG.DANO)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_FRIO)
				empurrar(alvo, raiz.CFrame.LookVector, CFG.EMPURRAO, 0.16)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("GELO", { posicao = alvoRaiz.Position, escala = 0.8,
						vida = CFG.TEMPO_FRIO })
				end
				pegou = true
			end
			if pegou then
				tocarEm("IMPACTO", ponto, 1.1)
			else
				tocar("GOLPE", 1.25)
			end
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Série de Cortes  (CUTSCENE)
--
-- O pedido foi "cutscene de cortes consecutivos", e a diferença com a execução
-- que estava aqui antes é a PROPORÇÃO. A execução tinha 70% de preparação e um
-- corte no fim: a leitura era "o golpe definitivo". Esta tem 0.57 s de
-- preparação e depois seis cortes seguidos, um a cada 0.22 s: a leitura é
-- "não dá para parar".
--
-- CADA CORTE É UM BEAT, E CADA BEAT É UM ACERTO
--
--   `CORTE_1` a `CORTE_5` e `ULTIMO` — seis marcas na sequência, seis entradas
--   na tabela do despachante. Nenhum `task.wait` encadeia nada: quem conduz o
--   tempo é o animator, e o dano cai quando a lâmina cai.
--
--   `TESTES/verificar_beats.py` confere que os seis existem dos dois lados. É
--   o verificador que nasceu porque 14 Tools saíram com beat escrito só de um
--   lado e dano zero.
--
-- O ALVO É FIXADO NO INÍCIO
--
--   Ele é escolhido uma vez, no `AVANCA`, e a série inteira persegue ESSE. Um
--   `maisPerto` por corte faria a lâmina pular de alvo em alvo no meio da
--   cena — o que é outra habilidade, e não a que foi pedida.
--══════════════════════════════════════════════════════════════

--- Um corte da série. `ordem` é só para o desenho: o ângulo de cada lâmina sai
--- do ângulo áureo, então os seis nunca se sobrepõem.
local function cortarNaSerie(ordem, dano)
	local alvo = alvoDaSerie
	if not (alvo and alvo.Parent and alvo.Health > 0) then
		-- o alvo caiu no meio da série: o gesto continua, o dano não tem onde
		-- cair. Cortar o ar é melhor que a cena parar pela metade.
		tocar("GOLPE", 1.3 + ordem * 0.04)
		return
	end
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return end

	cortesDados = cortesDados + 1
	aplicarDano(alvo, dano)
	afrouxar(alvo, CFG.LENTIDAO_GELO, CFG.DURACAO_GELO)

	vfx("CORTE_SERIE", { posicao = alvoRaiz.Position, angulo = angulo(ordem),
		ordem = ordem, escala = 1 })
	tocarEm("GOLPE", alvoRaiz.Position, 1.1 + ordem * 0.06)
end

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.RAIO_ALVO), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.8)
		return
	end

	ocupado = true
	alvoDaSerie = alvo
	cortesDados = 0

	rig:PlaySequence("SERIE", despachar({
		CAMERA = { cam = true, sfx = { "CARGA", 0.9 }, faz = function()
			abrirCena(alvoDaSerie, "SERIE")
			rig:LockCharacter(true)
		end },
		AVANCA = { cam = true, faz = function()
			-- encosta no alvo: a série é corpo a corpo, e o avanço é o que
			-- fecha a distância sem teleportar ninguém.
			local alvoRaiz = raizDe(alvoDaSerie)
			if alvoRaiz and raiz then
				local delta = alvoRaiz.Position - raiz.Position
				local plano = Vector3.new(delta.X, 0, delta.Z)
				if plano.Magnitude > CFG.AVANCO then
					empurrar(humanoide, plano, plano.Magnitude * 2.4, 0.2)
				end
			end
			vfx("GELO", { posicao = raiz.Position, escala = 1.2, vida = 3 })
		end },
		CORTE_1 = { cam = true, faz = function() cortarNaSerie(1, CFG.DANO_CORTE) end },
		CORTE_2 = { faz = function() cortarNaSerie(2, CFG.DANO_CORTE) end },
		CORTE_3 = { cam = true, faz = function() cortarNaSerie(3, CFG.DANO_CORTE) end },
		CORTE_4 = { faz = function() cortarNaSerie(4, CFG.DANO_CORTE) end },
		CORTE_5 = { faz = function() cortarNaSerie(5, CFG.DANO_CORTE) end },
		SEGURA = { cam = true, sfx = { "CARGA", 0.7 } },
		ULTIMO = { cam = true, faz = function()
			cortarNaSerie(6, CFG.DANO_ULTIMO)
			local alvoRaiz = raizDe(alvoDaSerie)
			local onde = alvoRaiz and alvoRaiz.Position or frente(CFG.ALCANCE)
			vfx("ESTILHACO", { posicao = onde, escala = 1,
				cortes = cortesDados })
			tocarEm("IMPACTO", onde, 0.8)
			if alvoDaSerie and alvoDaSerie.Health > 0 then
				tombar(alvoDaSerie, 1.4)
			end
		end },
		FIM = { cam = true, faz = function()
			rig:LockCharacter(false)
			fecharCena()
			alvoDaSerie = nil
		end },
	}), function()
		ocupado = false
		rig:LockCharacter(false)
		fecharCena()
		alvoDaSerie = nil
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

	rig = Animator.new(personagem, "DramaCorteFrio", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	alvoDaSerie = nil
	cortesDados = 0
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
--
-- ISTO ESTAVA FORA DO GERADOR. A ligação tinha sido enxertada nos arquivos
-- prontos por `FERRAMENTAS/ligar_deposito.py`, e por isso a primeira
-- regeneração do DRAMA a perdeu — as sete Tools voltaram a não ter depósito, e
-- só o `verificar_deposito_vfx.py` percebeu. Enxerto que não volta para o
-- gerador é conserto que dura até a próxima geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
