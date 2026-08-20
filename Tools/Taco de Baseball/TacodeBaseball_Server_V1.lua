-- TacodeBaseball_Server_V1.lua
-- Script de servidor — Taco de Baseball  (conjunto GUEST)
--
-- REMASTER. `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem
-- que mandaram converter, então a ESTRUTURA É LEI — Handle, mesh, Sound, Weld
-- e hierarquia saem da origem intactos. O que muda é a habilidade.
--
--   M1   dois golpes de taco que revezam
--   R    Rebater   (Extra, por `AcaoRemote` — e por botão no celular)
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

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 6.5,
	RAIO_GOLPE    = 7,
	DANO_A        = 16,
	DANO_B        = 22,
	EMPURRAO      = 34,
	RECARGA       = 0.55,

	RECARGA_EXTRA = 10,
	JANELA_REBATE = 0.9,
	RAIO_REBATE   = 12,
	FORCA_REBATE  = 2.4,
	TETO_REBATE   = 220,
	MINIMO_REBATE = 8,
	DANO_REBATE   = 26,
	DANO_EXTRA    = 55,
	RAIO_EXTRA    = 11,
	EMPURRAO_EXTRA = 95,
	TOMBO         = 2.2,
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
local golpeB = false

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


--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — combo de dois golpes
--
-- Os dois revezam por um booleano, não por sorteio: `Hit`/`Hit2` e
-- `Ouch`/`Ouch2` vêm em par no modelo, e alternar por índice é o que a regra
-- manda usar no lugar de `math.random`.
--═══════════════════════════════════════════════════════════════

local function bater(dano, metal)
	local ponto = frente(CFG.ALCANCE)
	vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 0.4, -CFG.ALCANCE * 0.6),
		escala = 1, cor = Color3.fromRGB(255, 228, 176) })

	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.35, 0), CFG.EMPURRAO, 0.18)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end

	if achou then
		tocarEm(metal and "Hit2" or "Hit", ponto, 1 + jitter(0.3) * 0.08)
		tocarEm(metal and "Ouch2" or "Ouch", ponto, 1 + jitter(1.4) * 0.08)
	end
end

function primaria(_mira)
	ocupado = true
	local segundo = golpeB
	golpeB = not golpeB
	tocar("Swoosh", 1 + jitter(0.7) * 0.1)
	-- O beat é `GOLPE`, não `BATE`. As duas sequências do `Poses.lua` marcam o
	-- quadro de impacto como `GOLPE`; despachar `BATE` casava com nada e o
	-- `bater()` NUNCA rodava — M1 sem dano nenhum nas duas Tools, em silêncio.
	-- Só apareceu quando o `verificar_beats.py` foi consertado: o regex dele
	-- casava 1 bloco de 170 e imprimia OK sem ter olhado.
	rig:PlaySequence(segundo and "GOLPE_B" or "GOLPE_A", despachar({
		GOLPE = { faz = function()
			bater(segundo and CFG.DANO_B or CFG.DANO_A, segundo)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — Rebater
--
-- O taco ergue e FICA DE PRONTIDÃO. Durante a janela, tudo que estiver voando
-- perto volta na direção em que o portador olha — projétil de outra Tool, caco
-- de escudo, bomba, o que for.
--
-- A janela é o quadro SEGURADO da sequência, não o instante do golpe: rebater
-- é reação, e reação precisa de tempo em que a guarda está de pé. São 0.9 s.
--
-- O QUE CONTA COMO OBJETO REBATÍVEL
--
--   `BasePart` solta (não ancorada) com velocidade acima de 8 studs/s. Peça
--   parada não é ameaça, e peça ancorada é cenário — devolver o mapa na cara
--   de alguém não é rebater, é quebrar o jogo.
--
--   O personagem do portador fica de fora do teste, senão o taco rebateria as
--   próprias pernas a cada passo.
--
-- A velocidade volta MULTIPLICADA por 2.4, e quem for atingido pelo objeto
-- rebatido leva dano creditado a quem rebateu — não a quem atirou.
--═══════════════════════════════════════════════════════════════

--- O QUE CONTA COMO OBJETO REBATÍVEL.
---
--- ⚠️ ESTE É O CONSERTO DO EMPURRÃO INFINITO.
---
--- A versão anterior tirava do teste só o personagem do PORTADOR. Corpo de
--- jogador é feito de `BasePart` SOLTA, e quem anda já vai a 16 studs/s — bem
--- acima do mínimo de 8. Então cada golpe pegava quem estivesse perto e
--- multiplicava a velocidade dele por 2.4.
---
--- E compunha três vezes: o `SEGURA` e o `GOLPE` da MESMA sequência chamam
--- `rebaterPerto` (2.4 × 2.4 = 5.76 num aperto só), e o golpe seguinte pegava
--- a velocidade já inflada e multiplicava de novo. Dois ou três swings e a
--- pessoa saía do mapa.
---
--- Rebater é para OBJETO. Gente leva o taco, que é o outro caminho logo abaixo
--- — com dano creditado e `BodyVelocity` de prazo curto, que acaba sozinho.
local function rebativel(peca)
	if not peca:IsA("BasePart") then return false end
	if peca.Anchored then return false end

	-- qualquer peça de personagem sai: rebater gente ERA o bug
	local modelo = peca:FindFirstAncestorOfClass("Model")
	if modelo and modelo:FindFirstChildOfClass("Humanoid") then return false end
	if peca:FindFirstAncestorOfClass("Accessory") then return false end
	if peca:FindFirstAncestorOfClass("Tool") then return false end
	return true
end

local function rebaterPerto(direcao, jaBatidos)
	local centro = raiz.Position
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }

	local rebatidos = 0
	for _, peca in ipairs(workspace:GetPartBoundsInRadius(centro,
			CFG.RAIO_REBATE, filtro)) do
		if rebativel(peca) and not (jaBatidos and jaBatidos[peca]) then
			local v = peca.AssemblyLinearVelocity
			if v.Magnitude >= CFG.MINIMO_REBATE then
				if jaBatidos then jaBatidos[peca] = true end

				-- devolve com juros, mas COM TETO. Sem o teto, dois tacos
				-- trocando a mesma peça multiplicavam sem fim.
				local nova = math.min(v.Magnitude * CFG.FORCA_REBATE,
					CFG.TETO_REBATE)
				peca.AssemblyLinearVelocity = direcao.Unit * nova

				vfx("REBOTE", { posicao = peca.Position,
					direcao = direcao.Unit, forca = nova / CFG.TETO_REBATE,
					escala = 1 })
				vfx("IMPACTO_METAL", { posicao = peca.Position, escala = 1 })
				tocarEm("Hit2", peca.Position, 1 + jitter(0.5) * 0.1)

				-- o crédito passa a ser de quem rebateu
				local dono = peca:FindFirstChild("creator")
				if dono then dono.Parent = nil end
				local marca = Instance.new("ObjectValue")
				marca.Name = "creator"
				marca.Value = jogador
				marca.Parent = peca
				Debris:AddItem(marca, 4)

				rebatidos = rebatidos + 1
			end
		end
	end
	return rebatidos
end

function extra(_mira)
	ocupado = true
	-- uma lista POR USO: a mesma peça não é rebatida no SEGURA e de novo no
	-- GOLPE. Era 2.4 x 2.4 = 5.76 num aperto só.
	local jaBatidos = {}
	rig:PlaySequence("REBATER", despachar({
		CARGA = { faz = function()
			tocar("Equip", 1.1)
			vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 1, -2),
				escala = 1.1 })
		end },
		SEGURA = { faz = function()
			-- a janela: varre uma vez por quadro segurado, não por frame
			local direcao = raiz.CFrame.LookVector
			if rebaterPerto(direcao, jaBatidos) > 0 then
				tocar("Swoosh", 0.9)
			end
		end },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			tocarEm("Hit", ponto, 0.9)
			vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 1, -2.4),
				escala = 1.3 })
			vfx("FAISCA_TACO", { posicao = ponto, escala = 1.1 })
			vfx("ONDA", { posicao = raiz.Position, raio = CFG.RAIO_EXTRA,
				escala = 1 })
			rebaterPerto(raiz.CFrame.LookVector, jaBatidos)
			-- e quem estiver ao alcance leva o taco, rebatendo ou não
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_EXTRA, 6)) do
				aplicarDano(alvo, CFG.DANO_REBATE)
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_EXTRA, 0.26)
					vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.2 })
				end
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

	rig = Animator.new(personagem, "GuestTaco", Poses, Poses.SEQUENCIAS)
	tocar("Equip", 1)
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
