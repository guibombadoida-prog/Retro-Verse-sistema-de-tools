-- Astral_Nova_Server_V1.lua
-- Script de servidor — Astral Nova
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  Nova Estelar — onda estelar em cone, empurra quem pega
--   X   Colapso Anão — puxa tudo para o centro e detona
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
	DANO_NOVA       = 31,
	ALCANCE_NOVA    = 15,
	ANGULO_NOVA     = 70,      -- graus, meia-abertura do cone
	EMPURRAO_NOVA   = 55,
	DEBOUNCE_NOVA   = 0.5,

	RAIO_COLAPSO    = 26,
	DANO_COLAPSO    = 44,
	PUXAO_COLAPSO   = 70,
	TEMPO_COLAPSO   = 0.55,
	CD_COLAPSO      = 18,

	SFX_GOLPE       = "SlashSound",
	SFX_EXTRA       = "TeleSpike",
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

--- Nova Estelar: cone à frente. O cone é conferido por ÂNGULO, não por
--- caixa: quem está atrás do portador não leva.
function primaria()
	if not Tool.Enabled or not raiz then return end
	Tool.Enabled = false
	task.delay(CFG.DEBOUNCE_NOVA, function() Tool.Enabled = true end)

	local frente = raiz.CFrame.LookVector
	local centro = raiz.Position + frente * 4

	tocar(CFG.SFX_GOLPE, 1.05)
	if rig then rig:PlaySequence("NOVA") end
	vfx("NOVA", { posicao = centro, escala = 1.2, direcao = frente })

	local limite = math.cos(math.rad(CFG.ANGULO_NOVA))
	local acertou = false
	for _, alvo in ipairs(alvosEm(centro, CFG.ALCANCE_NOVA, 12)) do
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			local para = (alvoRaiz.Position - raiz.Position)
			if para.Magnitude > 0.1 and para.Unit:Dot(frente) >= limite then
				aplicarDano(alvo, CFG.DANO_NOVA)
				empurrar(alvo, para + Vector3.new(0, 0.4, 0), CFG.EMPURRAO_NOVA, 0.22)
				acertou = true
			end
		end
	end
	if acertou then
		vfx("IMPACTO", { posicao = centro, escala = 1.2 })
	end
end

--- Colapso Anão: puxa por PULSOS, não continuamente. Puxão contínuo briga
--- com o Humanoid do alvo — dois donos do mesmo corpo, e o alvo trava.
function extra(mira)
	if not podeExtra or not raiz then return end
	podeExtra = false
	task.delay(CFG.CD_COLAPSO, function() podeExtra = true end)

	local centro = raiz.Position + raiz.CFrame.LookVector * 8
	tocar(CFG.SFX_EXTRA, 0.9)
	if rig then rig:PlaySequence("COLAPSO") end
	vfx("COLAPSO", { posicao = centro, escala = 1.3 })

	local fim = os.clock() + CFG.TEMPO_COLAPSO
	local proximoPulso = 0
	local laco
	laco = guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		if agora >= fim then
			if laco then laco:Disconnect() end
			vfx("IMPACTO_NOVA", { posicao = centro, escala = 1.4 })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
				aplicarDano(alvo, CFG.DANO_COLAPSO)
			end
			return
		end
		if agora < proximoPulso then return end
		proximoPulso = agora + 0.2

		for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				local para = centro - alvoRaiz.Position
				if para.Magnitude > 2 then
					empurrar(alvo, para, CFG.PUXAO_COLAPSO, 0.18)
				end
			end
		end
	end))
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

	rig = Animator.new(personagem, "AstralNova", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	soltarTudo()
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
