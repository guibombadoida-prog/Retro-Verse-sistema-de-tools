-- CortadaFatal_Server_V1.lua
-- Script de servidor — Cortada Fatal  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   cortada de cima, com onda no chao
--   R    Fatal   (Extra, por `AcaoRemote` — e por botão no celular)
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
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 6.5,
	RAIO_CORTADA  = 8,
	DANO          = 34,
	EMPURRAO      = 58,
	TOMBO         = 1.4,
	RECARGA       = 2.4,
	ALCANCE_ONDA  = 26,
	LARGURA_ONDA  = 5,
	DANO_ONDA     = 18,
	PASSOS_ONDA   = 8,

	RECARGA_EXTRA = 26,
	RAIO_ALVO     = 14,
	LIMIAR        = 0.4,
	DANO_FATAL    = 120,
	DANO_FRACO    = 44,
	AVANCO        = 5,
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
local alvoFatal = nil
local fatalArmado = false

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

--- Alvos num raio. O `Fists` varria `workspace:GetDescendants()` e o `dodge`
--- mantinha uma tabela viva de TODO Humanoid do jogo por
--- `workspace.DescendantAdded`. Aqui é consulta espacial sob demanda, e quem
--- filtra time é o Núcleo.
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
-- ⚠️ NÃO é `_G.Combate.aoAplicarDano`. Aquilo é gancho global, e o próprio
--    Núcleo o declara "§12.5 regra global — para SISTEMAS, nunca para Tools".
--    Ler a etiqueta também funciona num place vazio, sem Núcleo nenhum, que é
--    o que a Regra nº 1 cobra.
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


--══════════════════════════════════════════════════════════════
-- M1 — a cortada
--
-- Desce de CIMA. O arco passa inteiro acima da cabeça antes de cair, e a onda
-- corre pelo chão à frente — é o que separa esta Tool do soco do `Combate` e
-- do corredor do `Impacto Forte`.
--
-- Ela SUBSTITUI o combo de quatro da `TryHard`. Combo de quatro socos ao lado
-- do combo de três do `Combate` eram a mesma Tool com outro nome.
--══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CORTADA", despachar({
		ERGUE = { sfx = { "PREPARA", 0.9 } },
		SEGURA = { faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ Vector3.new(0, 3.4, 0), escala = 1 })
		end },
		DESCE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local direcao = raiz.CFrame.LookVector
			local chao = raiz.Position - Vector3.new(0, 2.2, 0)

			vfx("CORTADA", { posicao = ponto, cframe = raiz.CFrame,
				alcance = CFG.ALCANCE_ONDA, escala = 1 })
			tocarEm("IMPACTO", ponto, 0.85)

			local vistos = {}
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CORTADA, 8)) do
				vistos[alvo] = true
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				empurrar(alvo, direcao + Vector3.new(0, 0.25, 0),
					CFG.EMPURRAO, 0.24)
			end

			-- a onda: corre pelo chão, e é o que dá alcance à cortada
			for i = 1, CFG.PASSOS_ONDA do
				local passo = chao + direcao
					* (CFG.ALCANCE_ONDA * i / CFG.PASSOS_ONDA)
				for _, alvo in ipairs(alvosEm(passo, CFG.LARGURA_ONDA, 6)) do
					if not vistos[alvo] then
						vistos[alvo] = true
						aplicarDano(alvo, CFG.DANO_ONDA)
						tombar(alvo, CFG.TOMBO * 0.5)
					end
				end
			end
		end },
		FIM = { sfx = { "GOLPE", 1.05 } },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Fatal  (CUTSCENE)
--
-- A execução. Ela só sai CHEIA em alvo abaixo de `LIMIAR` da vida — 40%.
--
-- POR QUE O LIMIAR
--
--   Cutscene de execução que o alvo sobrevive é anticlímax: seis segundos de
--   câmera presa para um golpe que não fechou nada. E execução SEM limiar é só
--   um golpe grande com câmera, que é o que a `TryHard` era.
--
--   Acima do limiar a habilidade não é recusada — ela sai, com `DANO_FRACO` e
--   sem cena. Recusar gastaria a recarga de 26 s do jogador por um alvo que
--   ele não tinha como medir com precisão.
--
-- O ALVO É FIXADO NO INÍCIO, como na série do `Corte Frio`.
--══════════════════════════════════════════════════════════════

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.RAIO_ALVO), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.75)
		return
	end

	local fracao = alvo.MaxHealth > 0 and (alvo.Health / alvo.MaxHealth) or 1
	fatalArmado = fracao <= CFG.LIMIAR
	alvoFatal = alvo

	-- ACIMA do limiar: o golpe sai, sem cena e sem o dano de execução.
	if not fatalArmado then
		ocupado = true
		rig:PlaySequence("CORTADA", despachar({
			ERGUE = { sfx = { "PREPARA", 1.1 } },
			DESCE = { faz = function()
				local alvoRaiz = raizDe(alvoFatal)
				aplicarDano(alvoFatal, CFG.DANO_FRACO)
				tombar(alvoFatal, 1)
				if alvoRaiz then
					vfx("CORTADA", { posicao = alvoRaiz.Position,
						cframe = raiz.CFrame, alcance = 8, escala = 0.8 })
					tocarEm("IMPACTO", alvoRaiz.Position, 1)
				end
			end },
		}), function()
			ocupado = false
			alvoFatal = nil
		end)
		return
	end

	ocupado = true
	rig:PlaySequence("FATAL", despachar({
		CAMERA = { cam = true, sfx = { "CARGA", 0.7 }, faz = function()
			abrirCena(alvoFatal, "FATAL")
			rig:LockCharacter(true)
			if alvoFatal and alvoFatal.Health > 0 then
				atordoar(alvoFatal, 4)
			end
		end },
		ERGUE = { cam = true, faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ Vector3.new(0, 4, 0), escala = 1.4 })
		end },
		CARGA = { cam = true, sfx = { "PREPARA", 0.6 } },
		AVANCA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			if alvoRaiz and raiz then
				local delta = alvoRaiz.Position - raiz.Position
				local plano = Vector3.new(delta.X, 0, delta.Z)
				if plano.Magnitude > CFG.AVANCO then
					empurrar(humanoide, plano, plano.Magnitude * 2.6, 0.22)
				end
			end
		end },
		SEGURA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			if alvoRaiz then
				vfx("FATAL_MARCA", { posicao = alvoRaiz.Position, escala = 1 })
			end
		end },
		EXECUTA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			local onde = alvoRaiz and alvoRaiz.Position or frente(CFG.ALCANCE)
			vfx("FATAL", { posicao = onde, cframe = raiz.CFrame, escala = 1 })
			tocarEm("IMPACTO", onde, 0.55)
			if alvoFatal and alvoFatal.Health > 0 then
				aplicarDano(alvoFatal, CFG.DANO_FATAL)
				tombar(alvoFatal, 2.4)
			end
		end },
		FIM = { cam = true, faz = function()
			rig:LockCharacter(false)
			fecharCena()
			alvoFatal = nil
			fatalArmado = false
		end },
	}), function()
		ocupado = false
		rig:LockCharacter(false)
		fecharCena()
		alvoFatal = nil
		fatalArmado = false
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

	rig = Animator.new(personagem, "DramaCortada", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	alvoFatal = nil
	fatalArmado = false
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
