-- Desviar_Server_V1.lua
-- Script de servidor — Desviar  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   esquiva com invencibilidade
--   R    Empurrao   (Extra, por `AcaoRemote` — e por botão no celular)
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
local Deposito   = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 7,
	DISTANCIA_ESQ = 34,
	TEMPO_IMUNE   = 0.42,
	TEMPO_ESQ     = 0.28,
	RECARGA       = 3,

	RECARGA_EXTRA = 6,
	RAIO_CONE     = 11,
	DANO          = 9,
	EMPURRAO      = 92,
	SUBIDA        = 16,
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
local impulsoEsq = nil

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

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Handle/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight"). Tool
--- antiga não muda de comportamento.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o clone é
--- parenteado no `Handle` pelo servidor, então a INSTÂNCIA replica e todo
--- mundo ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons
--- diferentes para o mesmo golpe.
---
--- ⚠️ O último `return` do sorteio não é paranoia: `math.random() * total`
---    pode sobrar por arredondamento e cair fora do laço. A implementação de
---    onde a ideia veio devolve `nil` aí — um som mudo, calado, de vez em
---    quando.
---
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1.
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

local function somDe(nome)
	local achado = Handle:FindFirstChild(nome)
	if not achado then
		local pasta = Tool:FindFirstChild("SFX")
		achado = pasta and pasta:FindFirstChild(nome)
	end
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
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

--- Alvos num raio. O `Fists` varria `workspace:GetDescendants()` e o `dodge`
--- mantinha uma tabela viva de TODO Humanoid do jogo por
--- `workspace.DescendantAdded`. Aqui é consulta espacial sob demanda, e quem
--- filtra time é o Núcleo.
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

--- Lentidão com volta GARANTIDA.
---
--- ELE FALTAVA. O `Corte Frio` chamava `afrouxar` em DOIS lugares — no beat do
--- corte e no gelo do chão — e ele não existia em lugar nenhum do arquivo:
--- `attempt to call a nil value`, e as duas habilidades morriam caladas. Só
--- apareceu quando a lista `AJUDANTES` do `verificar_beats.py` cresceu.
---
--- Guarda a velocidade de ANTES e devolve ESSA, nunca 16 fixo: o alvo pode ter
--- velocidade própria, e devolver um número chapado quebra quem tinha.
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
-- ⚠️ Nada de gancho global de sistema nenhum: a Tool não conhece sistema.
--    Ler a etiqueta funciona num place vazio, que é o que a Regra nº 1 cobra.
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

--- ⚠️ `beatCena` DECLARADO, mesmo nas Tools sem cutscene.
---
--- A guarda do despachante é `if kf.cam and beatCena then`, e sem esta linha
--- `beatCena` é uma GLOBAL IMPLÍCITA: em Lua ler global inexistente devolve
--- `nil`, então o curto-circuito segura e nada quebra — hoje.
---
--- O risco não é este arquivo: é qualquer script do place que um dia crie uma
--- global com esse nome. A partir daí `kf.cam` verdadeiro chamaria função de
--- estranho, com os argumentos desta Tool.
---
--- Nas Tools COM cutscene, o `local function beatCena` mais abaixo sombreia
--- este `nil` — que é o comportamento certo, e é por isso que a declaração
--- pode ser incondicional.
local beatCena = nil

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
-- M1 — a esquiva
--
-- Era a Extra e virou a PRIMÁRIA, a pedido. Faz sentido: é ela que dá nome à
-- Tool, e é o único pedaço de mecânica do `dodge` do Rufus14 que sobreviveu
-- inteiro ao passe de conformidade.
--
-- `TEMPO_ESQ = 0.28` e `TEMPO_IMUNE = 0.42`. A imunidade é MAIOR que o
-- deslocamento de propósito: esquivar e levar o golpe no quadro em que você
-- para é a coisa mais frustrante que um jogo de briga faz.
--
-- A INVENCIBILIDADE É `ForceField`, e ela tem prazo pelo `Debris`.
--
--   `ForceField` é o único jeito de recusar dano que respeita `TakeDamage` —
--   qualquer Tool do repositório que chame `TakeDamage` bate nele e não passa.
--   Um `atributo = imune` que só ESTA Tool consultasse não valeria nada contra
--   as outras 90 do repositório.
--
-- O que a origem tinha e não entrou: dois `workspace.DescendantAdded` globais
-- mantendo uma tabela viva de TODO Humanoid do jogo, ligados para sempre.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ESQUIVA", despachar({
		ENTRA = { sfx = { "PREPARA", 1.35 }, faz = function()
			local para = destino - raiz.Position
			para = Vector3.new(para.X, 0, para.Z)
			if para.Magnitude < 1 then
				para = -raiz.CFrame.LookVector
			else
				para = para.Unit
			end

			if impulsoEsq then impulsoEsq.Parent = nil end
			impulsoEsq = Instance.new("BodyVelocity")
			impulsoEsq.MaxForce = Vector3.new(1e5, 0, 1e5)
			impulsoEsq.Velocity = para * CFG.DISTANCIA_ESQ
			impulsoEsq.Parent = raiz
			Debris:AddItem(impulsoEsq, CFG.TEMPO_ESQ)

			vfx("ESQUIVA", { posicao = raiz.Position,
				para = raiz.Position + para * 8, escala = 1 })
		end },
		IMUNE = { faz = function()
			local campo = personagem:FindFirstChildOfClass("ForceField")
			if not campo then
				campo = Instance.new("ForceField")
				campo.Visible = false
				campo.Parent = personagem
			end
			Debris:AddItem(campo, CFG.TEMPO_IMUNE)
			vfx("IMUNE", { posicao = raiz.Position, escala = 1,
				vida = CFG.TEMPO_IMUNE })
		end },
		SAI = { sfx = { "GOLPE", 1.5 } },
	}), function()
		ocupado = false
		impulsoEsq = nil
	end)
end

--══════════════════════════════════════════════════════════════
-- R — Empurrão
--
-- Era a primária e desceu para Extra. Cone à frente: dano pequeno, empurrão
-- grande. Ele não mata — ele TIRA gente de cima, e é o par natural da esquiva.
--══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("EMPURRAO", despachar({
		CARGA = { sfx = { "CARGA", 1.1 } },
		EMPURRA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			vfx("EMPURRAO", { posicao = ponto, cframe = raiz.CFrame,
				raio = CFG.RAIO_CONE, escala = 1 })
			tocarEm("IMPACTO", ponto, 0.95)

			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CONE, 10)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					-- CONE, não esfera: só quem está à frente é empurrado.
					-- Empurrar quem está atrás de você é o defeito clássico
					-- de área de melee, e ele passa despercebido em teste
					-- contra um alvo parado na sua frente.
					local delta = alvoRaiz.Position - raiz.Position
					local plano = Vector3.new(delta.X, 0, delta.Z)
					if plano.Magnitude > 0.5
							and plano.Unit:Dot(raiz.CFrame.LookVector) > 0.25 then
						aplicarDano(alvo, CFG.DANO)
						empurrar(alvo, raiz.CFrame.LookVector
							+ Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),
							CFG.EMPURRAO, 0.28)
					end
				end
			end
		end },
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

	rig = Animator.new(personagem, "DramaDesviar", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	if impulsoEsq then
		impulsoEsq.Parent = nil
		impulsoEsq = nil
	end
	if humanoide and humanoide.Parent then
		humanoide.PlatformStand = false
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

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- fica lá até o servidor cair.
--
-- ISTO ESTAVA FORA DO GERADOR. A ligação tinha sido enxertada nos arquivos
-- prontos por `FERRAMENTAS/ligar_deposito.py`, e por isso a primeira
-- regeneração do DRAMA a perdeu — as sete Tools voltaram a não ter depósito, e
-- só o `verificar_deposito_vfx.py` percebeu. Enxerto que não volta para o
-- gerador é conserto que dura até a próxima geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
