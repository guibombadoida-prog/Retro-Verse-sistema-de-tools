-- UltraCombo_Server_V1.lua
-- Script de servidor — Ultra Combo  (conjunto FAKER)
--
-- Sai da ÚNICA Tool do `faker_tools.rbxmx`, que é o His Cube original. Handle e
-- malhas vêm de lá; a habilidade é escrita aqui. Ver
-- `FERRAMENTAS/preparar_faker.py` para o mapa das sete malhas.
--
--   M1   combo de quatro que encadeiam, de palma
--   R    Selo   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
-- A origem punha tudo em LocalScript, e por isso a habilidade dela era
-- invisível para o resto do servidor.
--
-- Gerado por FERRAMENTAS/gerar_servers_faker.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

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

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE        = 6,
	RAIO_GOLPE     = 6.5,
	DANO_1         = 10,
	DANO_2         = 11,
	DANO_3         = 14,
	DANO_4         = 26,
	EMPURRAO       = 24,
	EMPURRAO_4     = 70,
	RECARGA        = 0.32,
	JANELA_COMBO   = 1.3,
	TOMBO          = 1.4,

	RECARGA_EXTRA  = 12,
	RAIO_SELO      = 14,
	DANO_SELO      = 34,
	EMPURRAO_SELO  = 46,
	LENTIDAO_SELO  = 0.55,
	TEMPO_SELO     = 2.5,
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
local passoCombo = 0
local ultimoGolpe = 0
local ORDEM_COMBO = { "COMBO_1", "COMBO_2", "COMBO_3", "COMBO_4" }

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 67 `math.random` da origem —
--- e neste conjunto isso pesa mais que nos outros, porque TODOS os clientes
--- desenham. Um sorteio faria cada um ver uma cena diferente, o que lê como
--- lag, não como efeito.
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
-- A ORIGEM NÃO TINHA DANO NENHUM. Zero `TakeDamage` e zero escrita em `Health`
-- nas 796 linhas dela: era casca de VFX privada. Este bloco é o que faz as sete
-- serem Tools de combate e não fogos de artifício.
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

--- Puxar é empurrar com o sinal trocado, e é o verbo deste conjunto: o poço, a
--- prisão e a implosão puxam. Sai por prazo no `Debris`, como tudo aqui.
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
--- não é teleporte, é âncora.
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

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta.
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
-- PRIMÁRIA — o combo de quatro
--
-- `Ultra Combo` é o nome que o PRÓPRIO modelo dá à habilidade Q dele:
-- `Services.Input:SetTitle("Primary", "Ultra Combo")`. Não foi inventado aqui.
--
-- O passo avança só se o golpe anterior caiu dentro da janela. Passou do prazo,
-- volta ao primeiro: é o que faz combo ser combo e não uma fila de golpes
-- independentes.
--
-- Bate de PALMA, não de punho. O punho é o vocabulário do conjunto DRAMA; aqui
-- quem bate de verdade é o disco.
--═══════════════════════════════════════════════════════════════

local function bater(dano, forca, escala)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
		aplicarDano(alvo, dano)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), forca, 0.18)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = escala or 1 })
		end
		achou = true
	end
	if achou then
		tocarEm("DISPARO", ponto, 1 + jitter(0.4) * 0.1)
	end
	return achou
end

function primaria(_mira)
	ocupado = true

	if os.clock() - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo % 4 + 1
	ultimoGolpe = os.clock()

	local dano = ({ CFG.DANO_1, CFG.DANO_2, CFG.DANO_3, CFG.DANO_4 })[passoCombo]

	rig:PlaySequence(ORDEM_COMBO[passoCombo], despachar({
		BATE = { faz = function()
			bater(dano, CFG.EMPURRAO, 0.9)
		end },
		BATE_FORTE = { faz = function()
			-- o quarto é o giro: pega em volta, não só à frente
			local ponto = raiz.Position
			tocarEm("AGUDO", ponto, 0.8)
			vfx("IMPACTO", { posicao = ponto, escala = 1.6 })
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE * 1.4, 8)) do
				aplicarDano(alvo, CFG.DANO_4)
				tombar(alvo, CFG.TOMBO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - ponto)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_4, 0.3)
				end
			end
		end },
		FIM = { faz = function()
			passoCombo = 0
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o selo
--
-- O disco `E` do próprio modelo, deitado no chão e aberto até 14 studs. É a
-- única das sete malhas que o `Ultra Combo` carrega, e ela é chata (9.9 × 1.0
-- × 9.9) — feita para ficar no piso.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	passoCombo = 0
	rig:PlaySequence("SELO", despachar({
		ERGUE = { sfx = { "AGUDO", 0.7 } },
		FECHA = { faz = function()
			local centro = raiz.Position - Vector3.new(0, 2.4, 0)
			vfx("IMPACTO", { posicao = centro, escala = 2.8 })
			tocarEm("DISPARO", centro, 0.55)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_SELO, 12)) do
				aplicarDano(alvo, CFG.DANO_SELO)
				afrouxar(alvo, CFG.LENTIDAO_SELO, CFG.TEMPO_SELO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_SELO, 0.28)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
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

	rig = Animator.new(personagem, "FakerUltraCombo", Poses, Poses.SEQUENCIAS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	passoCombo = 0
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
