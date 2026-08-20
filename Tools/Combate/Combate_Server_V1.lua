-- Combate_Server_V1.lua
-- Script de servidor — Combate  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   combo de tres socos que encadeiam
--   R    Counter   (Extra, por `AcaoRemote` — e por botão no celular)
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 6,
	RAIO_GOLPE    = 6.5,
	DANO_A        = 12,
	DANO_B        = 12,
	DANO_C        = 22,
	EMPURRAO      = 26,
	RECARGA       = 0.4,
	JANELA_COMBO  = 1.4,

	RECARGA_EXTRA = 9,
	JANELA_CONTRA = 1.0,
	FATOR_DEVOLVE = 1.6,
	TETO_DEVOLVE  = 55,
	RAIO_DEVOLVE  = 22,
	ATORDOAMENTO  = 1.6,
	EMPURRAO_CONTRA = 46,
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
local passoCombo = 0
local ultimoGolpe = 0
local vigiaContra = nil
local contraAberto = false
--- `function x()` sem esta linha atribui a uma GLOBAL
local fecharContra

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


--══════════════════════════════════════════════════════════════
-- M1 — combo de três
--
-- O passo avança só se o golpe anterior caiu dentro da janela. Passou do
-- prazo, volta ao primeiro: é o que faz combo ser combo e não uma fila de
-- socos avulsos. INTACTO do refazimento anterior.
--══════════════════════════════════════════════════════════════

local ORDEM = { "SOCO_A", "SOCO_B", "SOCO_C" }
local DANOS = { "DANO_A", "DANO_B", "DANO_C" }

function primaria(_mira)
	local agora = os.clock()
	if agora - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo + 1
	if passoCombo > 3 then passoCombo = 1 end
	ultimoGolpe = agora

	local passo = passoCombo
	ocupado = true
	rig:PlaySequence(ORDEM[passo], despachar({
		-- o TERCEIRO tem timbre próprio. É o gancho, o que fecha o combo e o
		-- que dá quase o dobro do dano dos dois primeiros — som igual aos
		-- outros dois desperdiçaria a única pista sonora de que ele é
		-- diferente. E é o que tira o `CARGA` da lista de som depositado e
		-- mudo: asset viajando dentro da Tool sem ninguém tocá-lo.
		CARGA = { sfx = { passo == 3 and "CARGA" or "PREPARA",
			passo == 3 and 0.9 or 1.15 } },
		BATE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local pegou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
				aplicarDano(alvo, CFG[DANOS[passo]])
				empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.2, 0),
					CFG.EMPURRAO, 0.18)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("SOCO", { posicao = alvoRaiz.Position, escala = 1 })
				end
				pegou = true
			end
			if pegou then
				tocarEm("IMPACTO", ponto, 1 + jitter(0.3) * 0.1)
			else
				tocar("GOLPE", 1.2)
			end
		end },
		FIM = { faz = function() passoCombo = 0 end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Counter
--
-- Abre uma janela de `JANELA_CONTRA` segundos. Se alguém acertar o portador
-- dentro dela, o dano é DEVOLVIDO multiplicado, e quem bateu fica atordoado.
--
-- COMO ELE SABE QUE LEVOU
--
--   `humanoide.HealthChanged`, que é a única coisa do Roblox que avisa perda
--   de vida sem importar de onde ela veio. A subtração filtra cura. E quem
--   bateu vem da etiqueta `creator` que o próprio repositório grava na vítima
--   — nada de gancho global do Núcleo, que é declarado lá como sendo para
--   sistemas e não para Tools.
--
-- O QUE ELE NÃO FAZ
--
--   Não anula o dano. Contra que zera o golpe é invencibilidade com outro
--   nome, e o `Desviar` já é a Tool que dá i-frames. Aqui você LEVA e devolve
--   mais — a troca é boa, e continua sendo uma troca.
--
--   E ele devolve UMA vez. A janela fecha no primeiro acerto: contra que
--   devolve tudo o que vier durante um segundo apaga qualquer time.
--══════════════════════════════════════════════════════════════

function fecharContra()
	contraAberto = false
	if vigiaContra then
		vigiaContra:Disconnect()
		vigiaContra = nil
	end
end

local function devolver(quanto, agressor)
	if not contraAberto then return end
	fecharContra()

	local devolvido = math.min(quanto * CFG.FATOR_DEVOLVE, CFG.TETO_DEVOLVE)
	if not agressor then
		-- pegou o golpe mas não achou quem deu: o gesto sai, o dano não.
		vfx("CONTRA_VAZIO", { posicao = raiz.Position, escala = 1 })
		tocar("PREPARA", 0.8)
		return
	end

	local alvoRaiz = raizDe(agressor)
	aplicarDano(agressor, devolvido)
	atordoar(agressor, CFG.ATORDOAMENTO)
	if alvoRaiz then
		empurrar(agressor, alvoRaiz.Position - raiz.Position
			+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_CONTRA, 0.24)
		vfx("CONTRA_DEVOLVE", { posicao = alvoRaiz.Position,
			de = raiz.Position, escala = 1 })
		tocarEm("IMPACTO", alvoRaiz.Position, 0.85)
	end

	-- a resposta interrompe a guarda no quadro em que o golpe chega, que é
	-- exatamente como counter deve ler. `PlaySequence` cancela a anterior.
	rig:PlaySequence("DEVOLVER", despachar({
		DEVOLVE = { sfx = { "GOLPE", 0.9 } },
	}), function() ocupado = false end)
end

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CONTRA", despachar({
		ABRE = { sfx = { "PREPARA", 1.3 }, faz = function()
			fecharContra()
			contraAberto = true
			vfx("CONTRA_ABRE", { posicao = raiz.Position, escala = 1,
				vida = CFG.JANELA_CONTRA })
			vigiaContra = guardar(vigiarVida(devolver))
			task.delay(CFG.JANELA_CONTRA, fecharContra)
		end },
		ESPERA = { faz = function()
			vfx("CONTRA_ABRE", { posicao = raiz.Position, escala = 0.6,
				vida = 0.4 })
		end },
		FECHA = { faz = fecharContra },
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

	rig = Animator.new(personagem, "DramaCombate", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	passoCombo = 0
	fecharContra()
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
