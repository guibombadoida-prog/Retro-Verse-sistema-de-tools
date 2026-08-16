-- ArvoreMaligna_Server_V1.lua
-- Script de servidor — Arvore Maligna  (conjunto REALITY GUI)
--
-- Sai do `reality_tools.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_reality.py` para o mapa.
--
--   M1   planta a arvore, e ela caca
--   R    Derrubar   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   `tre`: Handle 4 x 1 x 2 e o Model `tree` com 5 UnionOperation
--   som Kill 4817657002
--   LOGICA: a arvore CACA. Ela procura o Humanoid mais perto num raio de
--      200, e **so anda enquanto ninguem esta olhando para ela** — o
--      `canSee` da origem testa FOV mais raycast. A menos de 10 studs,
--      mata. E anjo chorao, nao aura parada.
--   o BodyGyro e a ScreenGui da origem NAO atravessaram
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_reality.py. Editar aqui à mão faz as sete
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

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	ALCANCE        = 12,
	RECARGA        = 30,
	DURACAO        = 16,
	ALCANCE_CACA   = 90,
	PASSO          = 0.35,
	PASSO_STUDS    = 4.5,
	RAIO_MORTE     = 7,
	DANO_MORTE     = 85,
	TOMBO          = 2.5,
	INTERVALO_ALVO = 1.6,
	ARRASTO_A_CADA = 4,

	RECARGA_EXTRA  = 2,
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
local arvoreId = nil
local arvoreOnde = nil
local geracao = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 21 `math.random` da origem —
--- e com todos os clientes desenhando, um sorteio faria cada um ver uma cena
--- diferente, o que lê como lag.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Faixa determinística no lugar de `math.random(minimo, maximo)`.
local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
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
-- A ORIGEM NÃO TINHA UM `TakeDamage`. Ela escrevia em `Health` cinco vezes,
-- chamava `BreakJoints` seis, e o `Banish` fazia `Foe:Destroy()` — matar por
-- deleção tira o abate do Núcleo e apaga o personagem do jogador.
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

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
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

--- O alvo mais perto de um ponto.
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

local function puxar(alvoHum, centro, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end
	local delta = centro - alvoRaiz.Position
	if delta.Magnitude < 0.5 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.3)
end

--- Prender no lugar com prazo. `BodyPosition` no ponto onde o alvo já está —
--- não é teleporte, é âncora. Nunca `Anchored`, que travaria o personagem
--- inteiro e deixaria o jogador preso se a Tool sumisse no meio.
local function prender(alvoHum, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local ancora = Instance.new("BodyPosition")
	ancora.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	ancora.P = 12000
	ancora.D = 900
	ancora.Position = alvoRaiz.Position
	ancora.Parent = alvoRaiz
	Debris:AddItem(ancora, tempo or 3)
	return ancora
end

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta —
--- a origem chamava seis.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta garantida. Guarda a velocidade ANTES de mexer, e devolve
--- essa — nunca um número fixo, porque o alvo pode ter velocidade própria.
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

--- Dano em área com NÚCLEO e BORDA.
---
--- A origem fazia `ApplyAoE(pos, RAIO, MIN, MAX, FLING, INSTAKILL)` com um raio
--- só e dano chapado — e quatro das nove marcavam INSTAKILL. Dois raios é o que
--- impede uma explosão grande de matar meio servidor por estar por perto.
local function golpearArea(centro, raio, raioNucleo, danoNucleo, danoBorda,
		forca, tombo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 16)) do
		local alvoRaiz = raizDe(alvo)
		local d = alvoRaiz and (alvoRaiz.Position - centro).Magnitude or raio
		if d <= raioNucleo then
			aplicarDano(alvo, danoNucleo)
			if tombo then tombar(alvo, tombo) end
		else
			aplicarDano(alvo, danoBorda)
			if tombo then tombar(alvo, tombo * 0.5) end
		end
		if alvoRaiz and forca then
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.6, 0),
				forca, 0.32)
		end
		pegos = pegos + 1
	end
	return pegos
end


--══════════════════════════════════════════════════════════════
-- O ANJO CHORÃO — a mecânica que a versão anterior tinha perdido
--
-- O `tre` não é uma aura. Ele é uma peça que persegue: acha o `Humanoid` mais
-- perto num raio de 200 studs, aponta para ele, e **avança 15 studs por volta
-- do laço — mas só enquanto aquele alvo NÃO está olhando para ela**. O teste
-- da origem (`canSee`) é o produto escalar do vetor até a árvore com o
-- `lookVector` da cabeça: positivo = está no campo de visão = ela congela.
--
-- A menos de 10 studs, mata.
--
-- O que mudou para caber nas regras: o passo é de 0.35 s (a origem roda com
-- `wait(.000001)`, o que é por quadro e replica picotado), o avanço é de 4.5
-- studs por passo em vez de 15, o alcance é 90 em vez de 200, e o abate é
-- `TakeDamage` pelo Núcleo em vez de `Health = 0` mais `BreakJoints`.
--
-- O raycast de linha de visão da origem ficou de fora: o teste de FOV é o que
-- dá a leitura de "ela parou porque eu olhei", e um raycast por alvo por tique
-- pagaria caro por pouco. Quem se esconder atrás de uma parede e olhar na
-- direção dela ainda a congela.
--══════════════════════════════════════════════════════════════

local function derrubar()
	geracao = geracao + 1
	if arvoreId then
		vfx("APAGAR", { id = arvoreId })
		arvoreId = nil
	end
	arvoreOnde = nil
end

--- O alvo está olhando para o ponto? `> 0` é o teste da origem: meio giro
--- inteiro conta como "de frente", e é isso que faz a árvore parecer travada
--- sempre que se vira para ela.
local function estaOlhando(alvo, ponto)
	local corpo = alvo and alvo.Parent
	local cabeca = corpo and (corpo:FindFirstChild("Head")
		or corpo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return false end
	local para = ponto - cabeca.Position
	if para.Magnitude < 0.5 then return true end
	return para.Unit:Dot(cabeca.CFrame.LookVector) > 0
end

local function cacar(id)
	geracao = geracao + 1
	local minha = geracao
	local ultimo = {}

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		local tique = 0
		while minha == geracao and os.clock() < ate and arvoreOnde do
			tique = tique + 1

			local presa, dist = nil, math.huge
			for _, alvo in ipairs(alvosEm(arvoreOnde, CFG.ALCANCE_CACA, 16)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local d = (alvoRaiz.Position - arvoreOnde).Magnitude
					if d < dist then presa, dist = alvo, d end
				end
			end

			local presaRaiz = presa and raizDe(presa)
			if presaRaiz then
				if estaOlhando(presa, arvoreOnde) then
					-- congelada. É a regra da origem, e é o jogo inteiro dela.
					if tique % CFG.ARRASTO_A_CADA == 0 then
						vfx("PARAR", { posicao = arvoreOnde, escala = 0.7,
							duracao = CFG.PASSO * CFG.ARRASTO_A_CADA })
					end
				else
					local delta = presaRaiz.Position - arvoreOnde
					local plano = Vector3.new(delta.X, 0, delta.Z)
					if plano.Magnitude > 0.5 then
						local anda = math.min(CFG.PASSO_STUDS, plano.Magnitude)
						arvoreOnde = arvoreOnde + plano.Unit * anda
						vfx("MOVER", { id = id, posicao = arvoreOnde,
							tempo = CFG.PASSO, olhar = presaRaiz.Position })
						if tique % CFG.ARRASTO_A_CADA == 0 then
							tocarEm("GALHO", arvoreOnde, 1.4,
								CFG.PASSO * CFG.ARRASTO_A_CADA + 0.3)
						end
					end
				end

				local agora = os.clock()
				if dist <= CFG.RAIO_MORTE
						and (not ultimo[presa]
							or agora - ultimo[presa] >= CFG.INTERVALO_ALVO) then
					ultimo[presa] = agora
					aplicarDano(presa, CFG.DANO_MORTE)
					tombar(presa, CFG.TOMBO)
					vfx("BURACO_FIM", { posicao = presaRaiz.Position, escala = 1.4 })
					tocarEm("GALHO", presaRaiz.Position, 0.55)
				end
			end

			task.wait(CFG.PASSO)
		end
		if minha == geracao then derrubar() end
	end)
end

--══════════════════════════════════════════════════════════════
-- PRIMÁRIA — plantar
--
-- O molde é o `Model` `tree` da origem, com as 5 `UnionOperation`. Entrou como
-- GEOMETRIA, ancorada e invisível; o clone é que aparece, e é ele que anda.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PLANTAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GALHO", 0.8)
		elseif marca == "GOLPE" then
			derrubar()
			local onde = (destino or frente(CFG.ALCANCE)) - Vector3.new(0, 1.5, 0)
			arvoreOnde = onde
			arvoreId = novoId("ARVORE")
			vfx("BURACO", { posicao = onde, escala = 1.6,
				duracao = CFG.DURACAO, id = arvoreId })
			tocarEm("GALHO", onde, 0.7)
			cacar(arvoreId)
		end
	end, function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- EXTRA — derrubar
--
-- A origem não tem segunda habilidade: a árvore fica de pé até o fim do round.
-- Esta Extra é o desligar dela, na tecla.
--══════════════════════════════════════════════════════════════

function extra(_mira)
	if not arvoreId then return end
	ocupado = true
	local onde = arvoreOnde
	rig:PlaySequence("GALHADA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GALHO", 1.15)
		elseif marca == "GOLPE" then
			local centro = onde or frente(CFG.ALCANCE)
			derrubar()
			vfx("BURACO_FIM", { posicao = centro, escala = 1.8 })
			tocarEm("GALHO", centro, 0.55)
		end
	end, function() ocupado = false end)
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

	rig = Animator.new(personagem, "RealityArvore", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	derrubar()
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
