-- Humilhador_Server_V1.lua
-- Script de servidor — Humilhador  (conjunto GUEST)
--
-- REMASTER. `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem
-- que mandaram converter, então a ESTRUTURA É LEI — Handle, mesh, Sound, Weld
-- e hierarquia saem da origem intactos. O que muda é a habilidade.
--
--   M1   provoca — som e efeito, zero dano
--   R    Roda   (Extra, por `AcaoRemote` — e por botão no celular)
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
	RECARGA       = 4,

	RECARGA_EXTRA = 14,
	RAIO_EXTRA    = 22,
	LENTIDAO      = 0.6,
	TEMPO_LENTO   = 4,
	ALTURA_SPRITE = 3.2,
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
-- PRIMÁRIA — a provocação
--
-- Esta Tool NÃO causa dano, e é de propósito: é provocação. O que ela mexe é
-- na cabeça de quem está olhando.
--
-- O sprite do original vivia num `BillboardGui` com um `mainz` que rodava
-- `while true do wait(.05) ... end` sem saída, e se auto-destruía no fim.
-- `BillboardGui` NÃO é violação — a proibição é de `ScreenGui`, e a razão dela
-- é "efeito só no mundo 3D"; billboard vive no mundo 3D. O que era violação
-- era o laço sem fim e o `:Destroy()`. O beat agora vem do animator, e quem
-- desenha é o cliente.
--═══════════════════════════════════════════════════════════════

local function pontoDaCabeca()
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if cabeca then return cabeca.Position + Vector3.new(0, 1.4, 0) end
	return raiz.Position + Vector3.new(0, CFG.ALTURA_SPRITE, 0)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("PROVOCA", function(passo)
		local marca = marcaDe(passo)
		if marca == "SPRITE" then
			tocarEm("Provoca", pontoDaCabeca(), 1)
			vfx("ZOMBARIA", { posicao = pontoDaCabeca(), escala = 1 })
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a roda
--
-- Provocação em área. Continua sem dano: o que ela faz é AFROUXAR quem está
-- perto, e a lentidão é devolvida por prazo e por `desmontar()`.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("RODA", function(passo)
		local marca = marcaDe(passo)
		if marca == "GIRA" then
			tocarEm("Provoca", pontoDaCabeca(), 0.85)
		elseif marca == "PULSO" then
			local onde = raiz.Position
			vfx("ZOMBARIA_RODA", { posicao = onde, escala = 1.4 })
			tocarEm("Provoca", onde, 1.25)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_EXTRA, 12)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
				local corpo = alvo.Parent
				local cabeca = corpo and corpo:FindFirstChild("Head")
				if cabeca then
					vfx("ZOMBARIA", { posicao = cabeca.Position + Vector3.new(0, 1.4, 0),
						escala = 0.7 })
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

	rig = Animator.new(personagem, "GuestHumilhador", Poses, Poses.SEQUENCIAS)
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
