-- ControladordaGravidade_Server_V1.lua
-- Script de servidor — Controlador da Gravidade  (conjunto GRAVIDADE)
--
-- Sai das 5 Tools do `calebe_tools.rbxmx`: o **Handle é da origem**, a
-- habilidade é escrita aqui. Duas do conjunto clonam o Handle de uma irmã —
-- ver `FERRAMENTAS/preparar_gravidade.py`.
--
--   M1   campo de gravidade invertida no ponto mirado
--   R    Esmagar   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- ⚠️ ESTA TOOL NÃO ESCREVE `workspace.Gravity`, E NENHUMA DAS SETE ESCREVE.
--    Gravidade é propriedade global do servidor; o original a trocava e não
--    devolvia. Aqui o efeito é sempre por ALVO, com prazo no `Debris`.
--
-- Gerado por FERRAMENTAS/gerar_servers_gravidade.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

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

local ARQUETIPO = "GRAVIDADE"

local CFG = {
	ALCANCE       = 8,
	RAIO_CAMPO    = 16,
	ALTURA_CAMPO  = 22,
	DURACAO_CAMPO = 3.5,
	DANO_CAMPO    = 8,
	RECARGA       = 9,

	RECARGA_EXTRA = 13,
	RAIO_ESMAGA   = 18,
	DANO_ESMAGA   = 38,
	FORCA_ESMAGA  = 140,
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

--- Jitter determinístico em [-1,1]. No lugar dos 18 `math.random` da origem:
--- mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice — dispersão que não repete e não sorteia.
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

--- Versão presa ao Handle — só para som que acompanha a mão.
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
--- string nunca dá verdadeiro, e o efeito é silencioso: a animação roda inteira
--- e o dano, o VFX e o som do beat simplesmente não acontecem.
---
--- Foi o bug relatado como "o dano não está funcionando em npcs e jogadores".
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL. A Tool sozinha num place vazio funciona
-- por inteiro — é o teste que decide a Regra nº 1.
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

--- Alvos num raio. O filtro de time é do Núcleo — o `IsTeamMate` que o
--- `GravityHammer` original tinha dentro de si não veio junto.
local function alvosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(
			posicao, raio, personagem, jogador, humanoide, limite or 12) or {}
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

--═══════════════════════════════════════════════════════════════
-- GRAVIDADE POR ALVO
--
-- ISTO É O CORAÇÃO DO CONJUNTO, E O MOTIVO DE ELE EXISTIR ASSIM.
--
-- O modelo de origem trocava `workspace.Gravity`. Aqui cada alvo ganha o SEU
-- corpo de força, com prazo no `Debris` — e o `Debris` limpa mesmo se o script
-- morrer no meio. Não há estado global para vazar.
--═══════════════════════════════════════════════════════════════

--- Empurra um alvo numa direção, por um prazo.
local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Suspende um alvo no ar. É a "gravidade invertida" sem tocar em nada global:
--- um `BodyPosition` mira acima da posição atual e o `Debris` desfaz.
local function suspender(alvoHum, altura, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 12000
	prender.D = 900
	prender.Position = alvoRaiz.Position + Vector3.new(0, altura, 0)
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
end

--- Puxa um alvo PARA um ponto.
local function atrair(alvoHum, ponto, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 9000
	prender.D = 1100
	prender.Position = ponto
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
end

--- Tombo com prazo, sem ragdoll de fora.
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
-- PRIMÁRIA — gravidade invertida no ponto
--
-- ⚠️ O ORIGINAL FAZIA `game.Workspace.Gravity = 21.2` E NÃO DEVOLVIA.
--
-- Aqui ninguém toca em `workspace.Gravity`. Cada alvo dentro do campo ganha um
-- `BodyPosition` próprio mirando acima de si, com prazo no `Debris` — e o
-- `Debris` limpa mesmo se este script morrer no meio. Não existe estado global
-- para vazar.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("INVERTE", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "SOLTA" then return end
		local id = novoId("CAMPO")
		tocarEm("Shift", mira, 1.1)
		vfx("CAMPO_INVERSO", { posicao = mira, escala = 1.2,
			raio = CFG.RAIO_CAMPO, duracao = CFG.DURACAO_CAMPO, id = id })

		for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_CAMPO, 12)) do
			aplicarDano(alvo, CFG.DANO_CAMPO)
			suspender(alvo, CFG.ALTURA_CAMPO, CFG.DURACAO_CAMPO, 9000)
		end

		task.delay(CFG.DURACAO_CAMPO, function()
			vfx("PARAR", { id = id })
		end)
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — esmagar
--
-- O oposto visual e mecânico da primária: mesma bolha, força para baixo. É o
-- que faz as duas lerem como a mesma Tool.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	rig:PlaySequence("ESMAGAR", despachar({
		ERGUE = { faz = function()
			tocar("Shift", 0.7)
		end },
		ESMAGA = { faz = function()
			vfx("ESMAGA", { posicao = mira, escala = 1.3 })
			tocarEm("Beep", mira, 0.72)
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_ESMAGA, 12)) do
				aplicarDano(alvo, CFG.DANO_ESMAGA)
				empurrar(alvo, Vector3.new(0, -1, 0), CFG.FORCA_ESMAGA, 0.3)
				tombar(alvo, 1.6)
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--
-- Recarga por TIMESTAMP: sobrevive a desequipar/equipar, e por isso não dá
-- para zerar a recarga guardando e sacando a Tool.
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

	rig = Animator.new(personagem, "GravControlador", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência — e foi assim que o `Gravitron 1000` original deixava a
--- gravidade do servidor trocada para sempre.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
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
