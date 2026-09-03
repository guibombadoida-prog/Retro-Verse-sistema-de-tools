-- Astral_Constelacao_Server_V1.lua
-- Script de servidor — Astral Constelação
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  Traço Sideral — marca quem for atingido
--   X   Sentença da Constelação — liga as marcas e detona
--
-- Gerado por FERRAMENTAS/gerar_servers_astral.py — o esqueleto (ciclo de vida,
-- dano pelo Núcleo, detecção que enxerga NPC, beat para o cliente) mora lá.
-- Editar aqui à mão faz as quatro derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

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

local ARQUETIPO = "ASTRAL"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	DANO_TRACO      = 24,
	ALCANCE_TRACO   = 10,
	DEBOUNCE_TRACO  = 0.4,
	VIDA_MARCA      = 8,
	MAX_MARCAS      = 6,

	DANO_SENTENCA   = 26,
	BONUS_TRES      = 40,     -- a partir de 3 marcas a sentença pesa mais
	CD_SENTENCA     = 30,

	SFX_GOLPE       = "SlashSound",
	SFX_EXTRA       = "Antificated",
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA, e o repositório inteiro dependia
--    dele: eram 217 pontos que conferiam só o TIPO.
--
--    `Vector3.new(0/0, 0/0, 0/0)` é um `Vector3` legítimo para o `typeof`.
--    Um cliente modificado manda isso, `.Unit` devolve NaN, e força NaN
--    aplicada a uma peça envenena a assembly dela — o alvo trava, voa para
--    coordenada absurda, ou o solver do motor engasga. Nenhum `pcall` pega,
--    porque não há erro: a conta simplesmente não tem resultado.
--
--    `n ~= n` é o único teste de NaN que funciona em Lua: NaN é o único valor
--    que não é igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda
--    na mesma linha.
--
-- E RATE LIMIT É DO SERVIDOR, não do cliente.
--
--    O `Client` já limita a 20 Hz, e isso não vale nada: quem manda o pacote
--    é o cliente, e cliente modificado manda a 2 000 Hz. O limite que conta
--    é o daqui.
--═══════════════════════════════════════════════════════════════

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
---
--- O corte por alcance não é só anticheat: mira a 5 000 studs faria o
--- `noChao()` varrer 400 studs de raycast a partir de um ponto onde não há
--- mapa, e a habilidade nasceria no vazio.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > CFG.MIRA_MAX then
		return raiz.Position + delta.Unit * CFG.MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem está abusando é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= CFG.PEDIDOS_POR_SEG
end
local podeExtra = true
local ativos = {}
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
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

local function tocar(nome, pitch)
	local base = somDe(nome)
	if not base then return end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, (som.TimeLength > 0 and som.TimeLength or 4) + 1)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

local function soltarTudo()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
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

--- NPC é Model com Humanoid, NÃO é Player: varrer `Players:GetPlayers()` não
--- enxerga NPC nenhum, e foi assim que uma leva inteira saiu sem acertar
--- inimigo de mapa.
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

--- Empurrão sem mexer em Health nem em estado: BodyVelocity com prazo.
local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADES
--═══════════════════════════════════════════════════════════════

local marcas = {}   -- [Humanoid] = { id = string, ate = number }

local function marcar(alvo)
	local atual = marcas[alvo]
	if atual then
		atual.ate = os.clock() + CFG.VIDA_MARCA
		return
	end

	local quantas = 0
	for _ in pairs(marcas) do quantas = quantas + 1 end
	if quantas >= CFG.MAX_MARCAS then return end

	local id = "marca_" .. tostring(proximo())
	marcas[alvo] = { id = id, ate = os.clock() + CFG.VIDA_MARCA }

	local corpo = alvo.Parent
	vfx("TRACO", {
		alvoNome = corpo and corpo.Name,
		deslocamento = Vector3.new(0, 3, 0),
		id = id, duracao = CFG.VIDA_MARCA,
	})

	task.delay(CFG.VIDA_MARCA, function()
		local reg = marcas[alvo]
		if reg and os.clock() >= reg.ate then
			marcas[alvo] = nil
			vfx("PARAR", { id = reg.id })
		end
	end)
end

function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_TRACO, function() Tool.Enabled = true end)

	local frente = raiz.CFrame.LookVector
	local ponto = raiz.Position + frente * 3

	tocar(CFG.SFX_GOLPE, 1)
	if rig then rig:PlaySequence("TRACO") end
	vfx("GOLPE", { posicao = ponto, direcao = frente, escala = 1 })

	for _, alvo in ipairs(alvosEm(ponto, CFG.ALCANCE_TRACO, 6)) do
		aplicarDano(alvo, CFG.DANO_TRACO)
		marcar(alvo)
		vfx("IMPACTO", { posicao = ponto, escala = 0.9 })
	end
end

--- Sentença: liga as marcas vivas e detona todas de uma vez. Sem marca não
--- acontece — e sem acontecer, NÃO gasta recarga.
function extra(mira)
	if not podeExtra or not raiz then return end

	local vivos, pontos = {}, {}
	local agora = os.clock()
	for alvo, reg in pairs(marcas) do
		if alvo and alvo.Health > 0 and agora < reg.ate then
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				table.insert(vivos, alvo)
				table.insert(pontos, alvoRaiz.Position + Vector3.new(0, 3, 0))
			end
		end
	end
	if #vivos == 0 then return end

	podeExtra = false
	task.delay(CFG.CD_SENTENCA, function() podeExtra = true end)

	tocar(CFG.SFX_EXTRA, 0.9)
	if rig then rig:PlaySequence("SENTENCA") end
	vfx("SENTENCA", { pontos = pontos })

	local dano = CFG.DANO_SENTENCA
	if #vivos >= 3 then dano = dano + CFG.BONUS_TRES end

	for _, alvo in ipairs(vivos) do
		local reg = marcas[alvo]
		if reg then vfx("PARAR", { id = reg.id }) end
		marcas[alvo] = nil
		aplicarDano(alvo, dano)
	end
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

Tool.Activated:Connect(primaria)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	if not taxaOk() then return end
	-- a whitelist de ação: qualquer tecla fora desta é descartada
	if tecla ~= "X" then return end
	mira = sanearMira(mira) or (raiz and raiz.Position) or Vector3.new()
	extra(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "AstralConstelacao", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	soltarTudo()
	for _, reg in pairs(marcas) do
		vfx("PARAR", { id = reg.id })
	end
	marcas = {}
	if rig then
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
