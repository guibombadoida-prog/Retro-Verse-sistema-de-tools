-- CanoDeRua_Server_V1.lua
-- Script de servidor — Cano De Rua  (conjunto GUEST)
--
-- REMASTER. `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem
-- que mandaram converter, então a ESTRUTURA É LEI — Handle, mesh, Sound, Weld
-- e hierarquia saem da origem intactos. O que muda é a habilidade.
--
--   M1   golpe de cano; o segundo vem mais forte
--   R    Cegar   (Extra, por `AcaoRemote` — e por botão no celular)
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
	ALCANCE       = 6,
	RAIO_GOLPE    = 6.5,
	DANO_A        = 13,
	DANO_B        = 19,
	EMPURRAO      = 28,
	RECARGA       = 0.5,

	RECARGA_EXTRA = 13,
	DURACAO_CEGO  = 4,
	DANO_EXTRA    = 34,
	RAIO_EXTRA    = 13,
	EMPURRAO_EXTRA = 55,
	LENTIDAO      = 0.45,
	TEMPO_LENTO   = 3.5,
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
local cegos = 0
local cegueiras = {}

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
-- PRIMÁRIA — dois golpes, e o segundo cobra mais caro
--
-- O original media 0.317 s por golpe, com proporção 42 : 58 — o que CONFIRMA a
-- regra 3 da gramática (combo bate cedo) e CONTRARIA a regra 1 (0.8–1.2 s).
-- Ver `ACERVO_RETROVERSE/Guest_Tools/R6_CFRAME/NOTAS.md`. A pose deste
-- conjunto fica em 0.50 s: mais lenta que o original porque ele não tinha um
-- único quadro segurado, e mais rápida que a tabela porque a 0.8 s uma briga
-- de rua vira coreografia.
--═══════════════════════════════════════════════════════════════

local function bater(dano, segundo)
	local ponto = frente(CFG.ALCANCE)
	vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 0.3, -CFG.ALCANCE * 0.6),
		escala = 0.9, cor = Color3.fromRGB(214, 226, 240) })

	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO, 0.16)
			vfx("IMPACTO_METAL", { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end

	if achou then
		tocarEm(segundo and "MetalHit2" or "MetalHit", ponto, 1 + jitter(0.5) * 0.09)
		tocarEm("Hit", ponto, 1 + jitter(1.9) * 0.07)
	end
end

function primaria(_mira)
	ocupado = true
	local segundo = golpeB
	golpeB = not golpeB
	tocar(segundo and "Swoosh2" or "Swoosh", 1 + jitter(0.9) * 0.1)
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
-- EXTRA — Cegar
--
-- É a habilidade do ORIGINAL levada até o fim. O `LeadpipeServer` já virava a
-- cabeça de quem apanhava para encarar o agressor
--
--     headdd.CFrame = CFrame.new(headdd.Position, owner.Head.Position)
--
-- e pendurava um `BoolValue` chamado `owieConcussed` — mas a "concussão" dele
-- não fazia nada além de desenhar uma `ScreenGui` na cara da vítima. GUI dentro
-- de Tool é proibida, e além de proibida é ruim: só quem levou via.
--
-- Aqui cegar é GEOMETRIA NO MUNDO 3D. Uma nuvem escura fica soldada à frente
-- da cabeça: tapa a vista de quem levou porque está fisicamente no caminho, e
-- a sala inteira vê quem está cego. Mais o que a origem já fazia — a cabeça
-- virada — e o que ela não tinha coragem de fazer: `AutoRotate = false`, que é
-- o que realmente atrapalha mirar.
--
-- Tudo com prazo, e tudo devolvido em `desmontar()`.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CEGAR", despachar({
		CARGA = { faz = function()
			tocar("Swoosh2", 0.72)
		end },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			tocarEm("MetalHit", ponto, 0.8)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_EXTRA, 6)) do
				aplicarDano(alvo, CFG.DANO_EXTRA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_CEGO)
				local corpo = alvo.Parent
				local cabeca = corpo and corpo:FindFirstChild("Head")
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if cabeca then
					local id = "CEGO_" .. tostring(cegos + 1)
					cegos = cegos + 1
					vfx("CEGUEIRA", { alvo = corpo, id = id, escala = 1,
						duracao = CFG.DURACAO_CEGO })
					table.insert(cegueiras, id)
					task.delay(CFG.DURACAO_CEGO, function()
						vfx("PARAR", { id = id })
					end)
				end
				-- a cabeça virada: é o gesto do original, e ele fica
				if cabeca and personagem and personagem:FindFirstChild("Head") then
					cabeca.CFrame = CFrame.new(cabeca.Position,
						personagem.Head.Position)
				end
				-- e o que a origem não fazia: tirar a mira
				alvo.AutoRotate = false
				task.delay(CFG.DURACAO_CEGO, function()
					if alvo and alvo.Parent and alvo.Health > 0 then
						alvo.AutoRotate = true
					end
				end)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO_EXTRA, 0.22)
					vfx("IMPACTO_METAL", { posicao = alvoRaiz.Position, escala = 1.2 })
				end
			end
		end },
		SEGURA = { faz = function()
			tocar("Swoosh", 0.66)
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

	rig = Animator.new(personagem, "GuestCano", Poses, Poses.SEQUENCIAS)
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
	tocar("unequip", 1)
	for _, id in ipairs(cegueiras) do vfx("PARAR", { id = id }) end
	table.clear(cegueiras)
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
