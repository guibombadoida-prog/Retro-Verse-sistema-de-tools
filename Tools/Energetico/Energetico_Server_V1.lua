-- Energetico_Server_V1.lua
-- Script de servidor — Energetico  (conjunto GUEST)
--
-- REMASTER. `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem
-- que mandaram converter, então a ESTRUTURA É LEI — Handle, mesh, Sound, Weld
-- e hierarquia saem da origem intactos. O que muda é a habilidade.
--
--   M1   bebe: cura e acelera por um tempo
--   R    Lata   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- Gerado por FERRAMENTAS/gerar_servers_guest.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "SUPORTE"

local CFG = {
	ALCANCE       = 6,
	CURA          = 10,
	VELOCIDADE    = 26,
	TEMPO_VELOZ   = 6,
	RECARGA       = 8,

	RECARGA_EXTRA = 6,
	DANO_EXTRA    = 15,
	RAIO_EXTRA    = 7,
	ALCANCE_MAX   = 90,
	FORCA_MIN     = 60,
	ARCO_TIRO     = 12,
	VIDA_LATA     = 5,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoExtra = 0, 0
local ocupado = false
local ativos = {}
local semente = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extra
local velocidadeBase = nil

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 41 `math.random` que os
--- originais usavam para variar pitch e ângulo: mesma variedade, e os dois
--- clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Toca um som numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça
--- que some no quadro seguinte mata o som no quadro em que ele nasce — foi o
--- que emudeceu a explosão das seis bombas.
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

--- Versão presa ao Handle — só para som que acompanha a mão e não a peça.
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
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro — é o
-- teste que decide a Regra nº 1.
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

--- Cura. Passa pelo Núcleo como qualquer efeito de vida.
---
--- ATENÇÃO: `_G.Combate.curar` **não existe** no `NucleoCombate.lua` de hoje.
--- Quem roda é o fallback. A guarda está aqui porque a regra manda toda
--- chamada ao Núcleo ser opcional, e para que o dia em que o Núcleo ganhar uma
--- `curar` as sete passem a usá-la sem tocar em nada.
local function curar(alvoHum, quanto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	if _G.Combate and _G.Combate.curar then
		return _G.Combate.curar(jogador, alvoHum, quanto) or 0
	end
	local antes = alvoHum.Health
	alvoHum.Health = math.min(alvoHum.Health + quanto, alvoHum.MaxHealth)
	return alvoHum.Health - antes
end

--- Alvos num raio. O `Taco` original varria `workspace:GetDescendants()` a
--- cada golpe; aqui é consulta espacial, e o filtro de time é do Núcleo.
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

--- O ponto à frente do portador. É onde o golpe corpo a corpo procura alvo.
local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE)
end

local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Tombo com prazo. Substitui o `require(ReplicatedFirst.Ragdoll)` do Diamond,
--- que era dependência de fora e não existe em place vazio.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com prazo, e com volta garantida mesmo se a Tool sumir no meio.
local velocidadeGuardada = {}

local function afrouxar(alvoHum, fator, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if velocidadeGuardada[alvoHum] == nil then
		velocidadeGuardada[alvoHum] = alvoHum.WalkSpeed
	end
	alvoHum.WalkSpeed = velocidadeGuardada[alvoHum] * fator
	task.delay(tempo, function()
		local antes = velocidadeGuardada[alvoHum]
		if antes and alvoHum and alvoHum.Parent then
			alvoHum.WalkSpeed = antes
		end
		velocidadeGuardada[alvoHum] = nil
	end)
end

local function devolverVelocidades()
	for alvoHum, antes in pairs(velocidadeGuardada) do
		if alvoHum and alvoHum.Parent then alvoHum.WalkSpeed = antes end
	end
	table.clear(velocidadeGuardada)
end


--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — beber
--
-- O original acelerava com `delay(5, ...)` e não devolvia nada se o jogador
-- desequipasse antes. Aqui o valor de origem é guardado, e `desmontar()`
-- devolve — nas duas portas.
--═══════════════════════════════════════════════════════════════

local GRIP_NORMAL = Tool.Grip
local GRIP_BOCA = CFrame.new(1.5, -0.5, 0.3)
	* CFrame.Angles(math.rad(-52), 0, math.rad(-14))

local function acelerar()
	if velocidadeBase == nil then velocidadeBase = humanoide.WalkSpeed end
	humanoide.WalkSpeed = CFG.VELOCIDADE
	task.delay(CFG.TEMPO_VELOZ, function()
		if humanoide and humanoide.Parent and velocidadeBase then
			humanoide.WalkSpeed = velocidadeBase
			velocidadeBase = nil
		end
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BEBER", function(passo)
		local marca = marcaDe(passo)
		if marca == "ERGUE" then
			Tool.Grip = GRIP_BOCA
			tocar("DrinkSound", 1)
		elseif marca == "ULTIMO_GOLE" then
			vfx("RESPINGO", { posicao = Handle.Position, escala = 0.6 })
		elseif marca == "CURA" then
			Tool.Grip = GRIP_NORMAL
			local ganho = curar(humanoide, CFG.CURA)
			if ganho > 0 then
				vfx("CURA", { posicao = raiz.Position, escala = 1.1 })
			end
			acelerar()
		end
	end, function()
		Tool.Grip = GRIP_NORMAL
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — amassa a lata e joga
--═══════════════════════════════════════════════════════════════

local function novaLata(posicao)
	local lata = Handle:Clone()
	lata.Name = "Lata"
	lata.Anchored = false
	lata.CanCollide = true
	lata.Massless = false
	lata.Size = Handle.Size * 0.8
	lata.CFrame = CFrame.new(posicao)
	for _, filho in ipairs(lata:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	lata.Parent = workspace
	pcall(function() lata:SetNetworkOwner(nil) end)
	Debris:AddItem(lata, CFG.VIDA_LATA)
	return lata
end

function extra(mira)
	ocupado = true
	rig:PlaySequence("LATA", function(passo)
		local marca = marcaDe(passo)
		if marca == "AMASSA" then
			tocar("OpenSound", 0.7)
		elseif marca == "JOGA" then
			local origem = Handle.Position + raiz.CFrame.LookVector * 1.5
			local lata = novaLata(origem)
			local dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
			local impulso = Instance.new("BodyVelocity")
			impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			impulso.Velocity = CFrame.new(origem, mira).LookVector
				* math.max(dist, CFG.FORCA_MIN) + Vector3.new(0, CFG.ARCO_TIRO, 0)
			impulso.Parent = lata
			Debris:AddItem(impulso, 0.1)

			local bateu = false
			guardar(lata.Touched:Connect(function(atingido)
				if bateu then return end
				local corpo = atingido and atingido.Parent
				if not corpo or corpo == personagem then return end
				local hum = corpo:FindFirstChildOfClass("Humanoid")
				if not (hum and hum.Health > 0) then return end
				bateu = true
				local onde = lata.Position
				vfx("RESPINGO", { posicao = onde, escala = 1.3,
					cor = Color3.fromRGB(255, 208, 96) })
				tocarEm("OpenSound", onde, 1.4)
				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_EXTRA, 4)) do
					aplicarDano(alvo, CFG.DANO_EXTRA)
				end
				lata.Transparency = 1
				lata.CanCollide = false
				lata.CanTouch = false
				Debris:AddItem(lata, 0.15)
			end))
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

	rig = Animator.new(personagem, "GuestEnergetico", Poses, Poses.SEQUENCIAS)
	tocar("OpenSound", 1)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência, e foi assim que o `Taco` original deixava perna soldada.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	devolverVelocidades()
	Tool.Grip = GRIP_NORMAL
	if humanoide and humanoide.Parent and velocidadeBase then
		humanoide.WalkSpeed = velocidadeBase
		velocidadeBase = nil
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
