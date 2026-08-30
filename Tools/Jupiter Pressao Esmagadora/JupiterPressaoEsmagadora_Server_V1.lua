-- JupiterPressaoEsmagadora_Server_V1.lua
-- Script de servidor — Jupiter Pressao Esmagadora  (conjunto JUPITER)
--
-- Os ASSETS saem do `Jupiter_Great_Pressure_Sword` do Acervo — som, malha do
-- planeta e textura de emissor, todos pela ficha. A HABILIDADE é escrita aqui:
-- o inventário do `LOGICA/HABILIDADES.md` registra `Health = 0`, raio de 1500
-- studs, 69 `:Destroy()` e 11 `require` de id numérico na origem, e nada disso
-- entra em Tool.
--
--   M1   Coluna
--   R    Prensa   (Extra 1)
--   T    Vacuo   (Extra 2)
--
--   Handle: eixo de ferro com dois blocos pesados nas pontas
--   PRENSA 9125403260 (Impact_Sound) · ESMAGA 260281717 (MeteorSmash)
--   VACUO 763717897 (VJ_Explosion) — os tres da ficha
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
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "GRAVIDADE"

local CFG = {
	ALCANCE       = 24,
	RECARGA       = 1.1,
	RAIO_COLUNA   = 7,
	DANO_COLUNA   = 16,
	PRESSAO       = 58,
	LENTIDAO      = 0.55,
	TEMPO_LENTO   = 2.4,

	RECARGA_R     = 13,
	RAIO_PRENSA   = 9,
	DANO_PRENSA   = 38,
	BORDA_PRENSA  = 19,
	TOMBO_PRENSA  = 1.8,

	RECARGA_T     = 24,
	RAIO_VACUO    = 22,
	DANO_VACUO    = 11,
	VIDA_VACUO    = 2.4,
	INTERVALO     = 0.4,
	RIGIDEZ_VACUO = 7000,
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
local vacuoId = nil

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
--- Sorteia DENTRO de um grupo de variação, com peso.
---
--- Um `Sound` com um `NumberValue` chamado `Weight` sai mais (ou menos) que os
--- irmãos. Serve para o take bom sair 3× mais que o esquisito sem ter de
--- apagar o esquisito.
---
--- ⚠️ A última linha NÃO é paranoia. `math.random() * total` pode, por
---    arredondamento de ponto flutuante, sobrar depois de subtrair todos os
---    pesos e cair fora do laço. A implementação de onde a ideia veio devolve
---    `nil` nesse caso — que é um som MUDO, em silêncio, uma vez a cada muitas.
local function sortearNoGrupo(pasta)
	local candidatos, total = {}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, { som = filho, peso = peso })
			total = total + peso
		end
	end
	if #candidatos == 0 then return nil end
	if #candidatos == 1 then return candidatos[1].som end

	local sorteio = math.random() * total
	for _, c in ipairs(candidatos) do
		if sorteio < c.peso then return c.som end
		sorteio = sorteio - c.peso
	end
	return candidatos[#candidatos].som
end

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	-- `Folder` com o nome do papel É o grupo de variação
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso. Tool antiga não muda de
--- comportamento: `Sound` avulso cai no primeiro `return`.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o `Sound` que
--- `tocar()` clona é parenteado no `Handle` pelo servidor, então a INSTÂNCIA
--- replica e todo mundo ouve a mesma. Se cada cliente sorteasse, duas pessoas
--- ouviriam sons diferentes para o mesmo golpe.
---
--- Achado ao ler o `ROBLOX-Audio-Manager` — ver
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1. Os modelos de
--- entrada já trazem 76 variantes que ninguém usava (`block1`..`block22` só no
--- Danilo, `Swing1`..`Swing5` no Reality).
local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
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
-- M1 — a coluna de pressão
--
-- Ela vem de CIMA. O alvo não é jogado para longe: é prensado contra o chão e
-- afrouxado — é o que separa esta Tool de uma explosão comum.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COLUNA", despachar({
		CARGA  = { sfx = { "PRENSA", 0.9 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_COLUNA * 0.3,
				escala = 0.5 })
		end },
		GOLPE = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_COLUNA,
				escala = 1 })
			tocarEm("PRENSA", destino, 1)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_COLUNA, 10)) do
				aplicarDano(alvo, CFG.DANO_COLUNA)
				empurrar(alvo, Vector3.new(0, -1, 0), CFG.PRESSAO, 0.3)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
			end
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — Prensa
--
-- Duas placas fecham no ponto. O dano é de núcleo e borda, e não de raio só:
-- é o que impede a prensa de matar quem estava só passando perto.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PRENSAR", despachar({
		CARGA  = { sfx = { "ESMAGA", 0.8 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_PRENSA * 0.4,
				escala = 0.6 })
		end },
		GOLPE = { faz = function()
			vfx("PRENSA", { posicao = destino, raio = CFG.RAIO_PRENSA,
				escala = 1 })
			tocarEm("ESMAGA", destino, 0.9)
			golpearArea(destino, CFG.RAIO_PRENSA, CFG.RAIO_PRENSA * 0.45,
				CFG.DANO_PRENSA, CFG.BORDA_PRENSA, nil, CFG.TOMBO_PRENSA)
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- T — Vácuo
--
-- Puxa para o ponto por `VIDA_VACUO` segundos. `atrair` é `BodyPosition` com
-- prazo: quem está preso continua podendo girar a câmera e atacar, e sai
-- sozinho quando o prazo vence — mesmo se a Tool sumir no meio.
--══════════════════════════════════════════════════════════════

local function pararVacuo()
	if vacuoId then
		vfx("APAGAR", { id = vacuoId })
		vacuoId = nil
	end
end

local function sugar(centro, restantes)
	if not vacuoId then return end
	if restantes <= 0 then
		pararVacuo()
		return
	end
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_VACUO, 12)) do
		aplicarDano(alvo, CFG.DANO_VACUO)
		atrair(alvo, centro, CFG.INTERVALO, CFG.RIGIDEZ_VACUO)
	end
	task.delay(CFG.INTERVALO, function()
		sugar(centro, restantes - 1)
	end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("VACUO", despachar({
		CARGA  = { sfx = { "VACUO", 1.1 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = 3, escala = 0.4 })
		end },
		GOLPE = { faz = function()
			pararVacuo()
			vacuoId = novoId("VACUO")
			vfx("VACUO", { id = vacuoId, posicao = destino,
				raio = CFG.RAIO_VACUO, escala = 1, vida = CFG.VIDA_VACUO })
			tocarEm("VACUO", destino, 0.95)
			sugar(destino, math.floor(CFG.VIDA_VACUO / CFG.INTERVALO))
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

	rig = Animator.new(personagem, "JupiterPressao", Poses,
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
	pararVacuo()
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

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- ⚠️ ISTO VIVIA FORA DO GERADOR, e o defeito estava em NOVE conjuntos.
--
--    A ligação tinha sido enxertada nos arquivos PRONTOS por
--    `FERRAMENTAS/ligar_deposito.py`, uma vez. Enquanto ninguém regerasse,
--    tudo passava. A primeira regeneração de cada conjunto a perdia — em
--    silêncio, porque o Server continua funcionando sem ela; o que para é o
--    VFX sair da Tool.
--
--    Enxerto que não volta para o gerador é conserto que dura até a próxima
--    geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
