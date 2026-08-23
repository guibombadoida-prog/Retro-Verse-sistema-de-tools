-- JupiterLuasGalileanas_Server_V1.lua
-- Script de servidor — Jupiter Luas Galileanas  (conjunto JUPITER)
--
-- Os ASSETS saem do `Jupiter_Great_Pressure_Sword` do Acervo — som, malha do
-- planeta e textura de emissor, todos pela ficha. A HABILIDADE é escrita aqui:
-- o inventário do `LOGICA/HABILIDADES.md` registra `Health = 0`, raio de 1500
-- studs, 69 `:Destroy()` e 11 `require` de id numérico na origem, e nada disso
-- entra em Tool.
--
--   M1   Luas
--   R    Lanca Io   (Extra 1)
--   T    Eclipse   (Extra 2)
--
--   Handle: o planeta na mao com as quatro luas em volta
--   ORBITA 160773067 (SpawnJupiter) · IO 96478259 (Lightning2)
--   ECLIPSE 401056199 (VJ_Explosion2) — os tres da ficha
--   malha do planeta: 907848103 com textura 8077647902
--
-- TRÊS HABILIDADES, E UM `AcaoRemote` SÓ
--
--   Quem separa as duas Extras é o NOME DA TECLA no payload, conferido aqui
--   antes de qualquer coisa. Dois remotes seriam duas portas para o mesmo
--   cômodo, e duas superfícies para validar.
--
-- NINGUÉM TOCA EM `workspace.Gravity`
--
--   Este conjunto é sobre pressão, e a tentação óbvia seria a gravidade
--   global. Ela é estado do place inteiro: mexer nela por Tool quebra todo
--   mundo que estiver no servidor, e deixa o place torto se a Tool sumir no
--   meio. Quem cai, cai por `BodyPosition` com prazo, no alvo, um por um.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_jupiter.py. Editar aqui à mão faz as
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

local ARQUETIPO = "ASTRAL"

local CFG = {
	ALCANCE       = 22,
	RECARGA       = 1.0,
	RAIO_ORBITA   = 8,
	DANO_LUA      = 9,
	VIDA_ORBITA   = 6,
	INTERVALO     = 0.4,
	PASSO_FASE    = 0.55,

	RECARGA_R     = 11,
	VOO_MINIMO    = 0.28,
	VOO_MAXIMO    = 0.46,
	RAIO_IO       = 12,
	DANO_IO       = 25,
	QUEIMA        = 7,
	QUEIMADAS     = 3,

	RECARGA_T     = 25,
	RAIO_ECLIPSE  = 24,
	NUCLEO_ECLIPSE = 8,
	DANO_ECLIPSE  = 40,
	BORDA_ECLIPSE = 20,
	TOMBO_ECLIPSE = 2,
	LENTIDAO      = 0.45,
	TEMPO_SOMBRA  = 3,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT
local luasId, luasFase = nil, 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 16 `math.random` da origem —
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

--- Ângulo áureo por índice: é o que espalha as quatro luas, os raios da
--- tormenta e os pontos do cinturão sem sorteio nenhum.
local function anguloDe(i)
	return (i or proximo()) * 2.399963
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
--- Aqui o som mora em `Tool/SFX/`, não pendurado no Handle: são três por Tool
--- e a pasta deixa claro que são irmãos.
local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
end

local function tocarEm(nome, posicao, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end

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
	local base = somDe(nome)
	if not base then return nil end
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
--- dano não acontece. Custou 14 Tools de dois conjuntos.
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL. A Tool sozinha num place vazio funciona
-- por inteiro — é o teste que decide a Regra nº 1.
--
-- A ORIGEM NÃO TINHA UM `TakeDamage`. Ela escrevia `Health = 0` em dois
-- scripts (`Disintegration` e `Disintegrate`), o que fura `ForceField` e tira
-- o abate do Núcleo, e reimplementava `TagHumanoid` doze vezes por fora.
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

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
---
--- O RAIO É PEQUENO DE PROPÓSITO. A origem chamava com 1500 studs, que pega
--- meio mapa: quem estivesse do outro lado do place levava dano de uma espada
--- que nunca viu.
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

--═══════════════════════════════════════════════════════════════
-- PRESSÃO — os dois ajudantes que só este conjunto tem
--
-- `BodyPosition` com prazo, no alvo, um por um. Nunca `Anchored`, que travaria
-- o personagem inteiro e deixaria o jogador preso se a Tool sumisse no meio; e
-- nunca `workspace.Gravity`, que é estado do place e não da Tool.
--═══════════════════════════════════════════════════════════════

--- Sobe o alvo e o segura no ar.
local function suspender(alvoHum, altura, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local ancora = Instance.new("BodyPosition")
	ancora.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	ancora.P = rigidez or 12000
	ancora.D = 900
	ancora.Position = alvoRaiz.Position + Vector3.new(0, altura, 0)
	ancora.Parent = alvoRaiz
	Debris:AddItem(ancora, tempo)
	return ancora
end

--- Puxa o alvo PARA um ponto e o segura lá.
local function atrair(alvoHum, ponto, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local ancora = Instance.new("BodyPosition")
	ancora.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	ancora.P = rigidez or 9000
	ancora.D = 1100
	ancora.Position = ponto
	ancora.Parent = alvoRaiz
	Debris:AddItem(ancora, tempo)
	return ancora
end

--- Prende no lugar onde o alvo já está. Não é teleporte, é âncora.
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
--- a origem chamava um.
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
--- A origem tinha um raio só e dano chapado, com dois `Health = 0` no meio.
--- Dois raios é o que impede uma queda de planeta de matar meio servidor por
--- estar por perto.
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


--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- Antes cada sequência tinha uma escada de `elseif marca == "X" then`, com o
-- nome do beat escrito DUAS vezes: no `Poses.lua` e de novo no `if`. Errar a
-- segunda falha em silêncio — a animação roda inteira e o beat não acontece.
-- Foi assim que 14 Tools de dois conjuntos ficaram sem dano.
--
-- Agora cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { cam = true, sfx = { "IMPACTO", 0.9 }, faz = bater }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe
--   `sfx`  toca um som: `{ nome, pitch }`
--   `faz`  o trabalho que não cabe em dado
--
-- Câmera e som viraram DADO. Só o que é trabalho continua sendo código, e ele
-- vem com nome em vez de posição na escada.
--
-- `TESTES/verificar_beats.py` confere, Tool a Tool, que todo beat despachado
-- aqui existe na sequência do `Poses.lua`.
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
-- M1 — as quatro luas
--
-- Io, Europa, Ganimedes e Calisto giram em volta de quem conjurou e ferem quem
-- encostar. Quem as leva é o `MOVER`, por TIQUE — uma mensagem a cada 0.4 s, e
-- o cliente faz o meio do caminho com um tween linear. Mandar posição por
-- quadro seria 60 mensagens por segundo por lua.
--══════════════════════════════════════════════════════════════

local function pararLuas()
	if luasId then
		vfx("APAGAR", { id = luasId })
		luasId = nil
	end
end

local function orbitar(restantes)
	if not luasId then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		pararLuas()
		return
	end
	luasFase = luasFase + CFG.PASSO_FASE
	vfx("MOVER", { id = luasId, posicao = raiz.Position,
		raio = CFG.RAIO_ORBITA, fase = luasFase, tempo = CFG.INTERVALO })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_ORBITA + 2, 8)) do
		aplicarDano(alvo, CFG.DANO_LUA)
	end
	task.delay(CFG.INTERVALO, function()
		orbitar(restantes - 1)
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("LUAS", despachar({
		CARGA  = { sfx = { "ORBITA", 1 } },
		SEGURA = { faz = function()
			vfx("LUAS", { posicao = raiz.Position, raio = CFG.RAIO_ORBITA * 0.4,
				escala = 0.5, vida = 0.4 })
		end },
		GOLPE = { faz = function()
			pararLuas()
			luasId = novoId("LUAS")
			luasFase = 0
			vfx("LUAS", { id = luasId, posicao = raiz.Position,
				raio = CFG.RAIO_ORBITA, escala = 1, vida = CFG.VIDA_ORBITA })
			orbitar(math.floor(CFG.VIDA_ORBITA / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Lança Io
--
-- A lua vulcânica sai da mão e vai até o ponto. O impacto queima: três tiques
-- de dano pequeno depois do estouro, que é o que separa Io das outras três.
--══════════════════════════════════════════════════════════════

local function queimar(centro, restantes)
	if restantes <= 0 then return end
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_IO * 0.7, 6)) do
		aplicarDano(alvo, CFG.QUEIMA)
	end
	task.delay(0.5, function()
		queimar(centro, restantes - 1)
	end)
end

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LANCA_IO", despachar({
		CARGA = { sfx = { "IO", 1.3 } },
		GOLPE = { faz = function()
			local saida = raiz.Position + raiz.CFrame.LookVector * 2
				+ Vector3.new(0, 2, 0)
			local voo = naFaixa(CFG.VOO_MINIMO, CFG.VOO_MAXIMO)
			vfx("IO", { de = saida, para = destino, tempo = voo, escala = 1 })
			tocar("IO", 1.25)
			task.delay(voo, function()
				vfx("IO_IMPACTO", { posicao = destino, raio = CFG.RAIO_IO,
					escala = 1 })
				tocarEm("IO", destino, 0.95)
				for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_IO, 8)) do
					aplicarDano(alvo, CFG.DANO_IO)
				end
				queimar(destino, CFG.QUEIMADAS)
			end)
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- T — Eclipse
--
-- As quatro se alinham e a sombra cai. É a única habilidade do conjunto que
-- SUBTRAI luz em vez de somar, e o efeito é 3D — nada de `ColorCorrection`,
-- que a origem usava quatro vezes e é proibido dentro da Tool.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ECLIPSE", despachar({
		CARGA  = { sfx = { "ECLIPSE", 0.75 } },
		SEGURA = { faz = function()
			vfx("LUAS", { posicao = destino, raio = CFG.RAIO_ECLIPSE * 0.3,
				escala = 0.7, vida = 0.6 })
		end },
		GOLPE = { faz = function()
			vfx("ECLIPSE", { posicao = destino, raio = CFG.RAIO_ECLIPSE,
				escala = 1 })
			tocarEm("ECLIPSE", destino, 0.8)
			golpearArea(destino, CFG.RAIO_ECLIPSE, CFG.NUCLEO_ECLIPSE,
				CFG.DANO_ECLIPSE, CFG.BORDA_ECLIPSE, nil, CFG.TOMBO_ECLIPSE)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_ECLIPSE, 12)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_SOMBRA)
			end
			pararLuas()
		end },
	}), function() ocupado = false end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e DUAS Extras
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

--- As DUAS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R" e "T" é descartada sem resposta.
--- Confiar no cliente para dizer qual habilidade rodar seria dar a ele a
--- escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if tecla == "R" then
		if not pronto(ultimoR, CFG.RECARGA_R) then return end
		ultimoR = os.clock()
		extraR(mira)
	elseif tecla == "T" then
		if not pronto(ultimoT, CFG.RECARGA_T) then return end
		ultimoT = os.clock()
		extraT(mira)
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "JupiterLuas", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	pararLuas()
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
