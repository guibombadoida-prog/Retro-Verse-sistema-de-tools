-- AsasTelecineticas_Server_V1.lua
-- Script de servidor — Asas Telecineticas  (conjunto GRAVIDADE)
--
-- Sai das 5 Tools do `calebe_tools.rbxmx`: o **Handle é da origem**, a
-- habilidade é escrita aqui. Duas do conjunto clonam o Handle de uma irmã —
-- ver `FERRAMENTAS/preparar_gravidade.py`.
--
--   M1   bate as asas: sobe e empurra quem estiver perto
--   R    Mergulho   (Extra, por `AcaoRemote` — e por botão no celular)
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

local ARQUETIPO = "TELECINESE"

local CFG = {
	ALCANCE       = 8,
	IMPULSO_CIMA  = 78,
	IMPULSO_FRENTE = 46,
	RAIO_SOPRO    = 14,
	DANO_SOPRO    = 12,
	EMPURRAO      = 62,
	RECARGA       = 5,

	RECARGA_EXTRA = 12,
	ALTURA_SUBIDA = 34,
	FORCA_MERGULHO = 190,
	RAIO_MERGULHO = 17,
	DANO_MERGULHO = 42,
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
local impulsoAtivo = nil

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
-- PRIMÁRIA — a batida de asa
--
-- Sobe o portador e empurra quem está perto. O impulso do PRÓPRIO portador é
-- guardado: se a Tool sumir no meio, `desmontar()` o tira — corpo de força
-- pendurado num personagem é estado que vaza.
--═══════════════════════════════════════════════════════════════

local function impulsionar(direcao, forca, tempo)
	if impulsoAtivo then impulsoAtivo.Parent = nil end
	impulsoAtivo = Instance.new("BodyVelocity")
	impulsoAtivo.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulsoAtivo.Velocity = direcao.Unit * forca
	impulsoAtivo.Parent = raiz
	Debris:AddItem(impulsoAtivo, tempo)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BATIDA", function(marca)
		if marca == "ABRE" then
			tocar("ScifiLiftSound", 1.2)
		elseif marca == "BATE" then
			tocar("ScifiBlastSound", 1.05)
			impulsionar(Vector3.new(0, CFG.IMPULSO_CIMA, 0)
				+ raiz.CFrame.LookVector * CFG.IMPULSO_FRENTE, 1, 0.3)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1.2 })

			for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SOPRO, 10)) do
				aplicarDano(alvo, CFG.DANO_SOPRO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.22)
				end
			end
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o mergulho
--
-- Sobe, segura, e desce com peso. É a sequência com mais quadro segurado do
-- conjunto depois do ultimate — a regra 7 vale para o alto também: o instante
-- parado no ar é o que vende a queda.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("MERGULHO", function(marca)
		if marca == "ERGUE" then
			tocar("ScifiLiftSound", 0.85)
			impulsionar(Vector3.new(0, CFG.ALTURA_SUBIDA, 0), 1, 0.45)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1 })

		elseif marca == "DESCE" then
			tocar("ScifiBlastSound", 0.75)
			impulsionar(Vector3.new(0, -1, 0), CFG.FORCA_MERGULHO, 0.35)

		elseif marca == "IMPACTO" then
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("MERGULHO", { posicao = chao, escala = 1.4 })
			tocarEm("Bam", chao, 0.8)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_MERGULHO, 12)) do
				aplicarDano(alvo, CFG.DANO_MERGULHO)
				tombar(alvo, 1.6)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - chao)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO * 1.4, 0.28)
				end
			end
		end
	end, function()
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

	rig = Animator.new(personagem, "GravAsas", Poses, Poses.SEQUENCIAS)
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
	if impulsoAtivo then
		impulsoAtivo.Parent = nil
		impulsoAtivo = nil
	end
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
