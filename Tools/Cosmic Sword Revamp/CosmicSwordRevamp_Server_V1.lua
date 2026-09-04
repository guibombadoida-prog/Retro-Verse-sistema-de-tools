-- CosmicSwordRevamp_Server_V1.lua
-- Script de servidor — Cosmic Sword Revamp
--
--   M1   Corte Cósmico     combo de 3, a mesma entrada
--   E    Supernova
--   Q    Shuriken do Espaço
--   X    Dobra              (o teleporte)
--   H    Hawking Cosmic Shuriken Radiation
--
--═══════════════════════════════════════════════════════════════
-- O QUE ESTE ARQUIVO SUBSTITUI, E POR QUÊ
--═══════════════════════════════════════════════════════════════
--
--   A Tool vinha com DOIS servidores: o `Server` de 1362 linhas do modelo de
--   origem `Sword of Cosmic Entity (Revamped)`, e o
--   `HawkingCosmicShurikenRadiation_Server_V1` enxertado por cima. Dois
--   `Tool.Equipped`, duas máquinas de estado, um rig cada.
--
--   ⛔ O `Server` da origem abria assim, na linha 10:
--
--          local SlashTrailModule = require(125275839196878)
--
--      Um asset remoto, buscado por id e EXECUTADO NO SERVIDOR. Quem
--      controlasse aquele asset controlava o servidor de quem equipasse a
--      Tool. Servia para TRÊS chamadas de `Slash_Trail` no M1 — o rastro do
--      corte, que agora é `Efeitos.CORTE` no `VFXModule`, dentro da Tool.
--
--   ✗ Ele lia `ServerStorage.CosmicVFX2` em quatro lugares, e um script
--      irmão chamado `remove` era quem punha a pasta lá. `ServerStorage` não
--      replica: o cliente NUNCA via molde nenhum, e era por isso que a Tool
--      não desenhava. O `DepositoVFX` faz o mesmo para `ReplicatedStorage`,
--      cria ou reutiliza, e mantém as duas portas (Regra nº 2).
--
--   ✗ Ele clonava a peça de VFX e pendurava nela um `Script` de tween que
--      rodava NO SERVIDOR. Geometria movida pelo servidor replica a ~20 Hz
--      sem interpolação. Os mesmos tweens, com os mesmos números, estão no
--      `VFXModule`, a 60 Hz.
--
--   ✗ Ele usava `LoadAnimation` sobre seis `Animation` de id. As seis viraram
--      sequências de pose R6 no `Poses.lua`.
--
--   ✗ E chamava `:Emit(` cinco vezes NO SERVIDOR, o que não replica.
--
--   O que veio da origem é a MECÂNICA: quantas fases cada habilidade tem, o
--   que cada uma acerta, e em que ordem. Os assets são todos dela.
--
--═══════════════════════════════════════════════════════════════
-- ONDE O EFEITO APARECE: EM TODO MUNDO
--═══════════════════════════════════════════════════════════════
--
--   `VFXRemote:FireAllClients` e o `Client` é `Script` com
--   `RunContext = Client`. O Client antigo do Hawking era `LocalScript`, que
--   dentro de Tool só roda para quem segura.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

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

local ARQUETIPO = "COSMICO"

local CFG = {
	--─ M1: o combo de três ─
	RECARGA_M1       = 0.42,
	COMBO_JANELA     = 1.6,    -- passado isso, o combo volta ao golpe 1
	ALCANCE_CORTE    = 11,
	RAIO_CORTE       = 7,
	DANO_CORTE       = 21,     -- golpes 1 e 2
	DANO_ESTOCADA    = 34,     -- o terceiro fecha mais alto
	EMPURRAO_CORTE   = 46,

	--─ E: Supernova ─
	RECARGA_E        = 14,
	RAIO_NOVA        = 42,
	RAIO_NUCLEO_NOVA = 16,
	DANO_NOVA        = 62,
	DANO_NOVA_BORDA  = 24,
	EMPURRAO_NOVA    = 95,
	TOMBO_NOVA       = 1.1,

	--─ Q: Shuriken do Espaço ─
	RECARGA_Q        = 9,
	ALCANCE_SHURIKEN = 120,
	VELOCIDADE_SHURI = 130,
	ESCALA_SHURI     = 3,
	RAIO_SHURI       = 24,
	DANO_SHURI       = 55,
	EMPURRAO_SHURI   = 70,
	PASSO_VOO        = 1 / 30, -- só para saber ONDE bate; quem desenha é o cliente

	--─ X: Dobra ─
	RECARGA_X        = 11,
	ALCANCE_DOBRA    = 90,
	RAIO_DOBRA       = 18,
	DANO_DOBRA       = 30,
	EMPURRAO_DOBRA   = 55,
	ALTURA_DOBRA     = 3.5,    -- a chegada sobe isto, para não nascer no chão

	--─ H: Hawking, fase 1 (a shuriken viva) ─
	RECARGA_H        = 22,
	ESCALA_SHURIKEN  = 14,
	ALTURA           = 9,
	DISTANCIA        = 22,
	SUCCAO_DURACAO   = 3.5,
	SUCCAO_RAIO      = 70,
	SUCCAO_PULSO     = 0.15,
	PUXAO_MAX        = 95,
	PUXAO_MIN        = 18,
	ZONA_MORTA       = 6,
	DANO_SUCCAO      = 4,
	GIRO             = 26,

	--─ H, fase 2 (a explosão colossal) ─
	DANO_CENTRO      = 190,
	DANO_BORDA       = 60,
	RAIO_EXPLOSAO    = 62,
	EMPURRAO         = 130,
	ESCALA_EXPLOSAO  = 4,

	--─ H, fase 2b (as 5 mini shurikens) ─
	MINIS            = 5,
	ESCALA_MINI      = 3.5,
	DANO_MINI        = 45,
	RAIO_MINI        = 22,
	VELOCIDADE_MINI  = 92,
	PRAZO_MINI       = 4,
	ESCALA_EXP_MINI  = 1.4,
	VIDA_MINI        = 8,

	--─ som: os nomes REAIS do modelo. Ausente = segue sem quebrar ─
	SFX_EQUIPA       = "Equip1",
	SFX_GUARDA       = "Equip2",
	SFX_CARGA        = "Slash",
	SFX_CORTE        = "Cut",
	SFX_ESTOCADA     = "Scar",
	SFX_NOVA_FIRMA   = "Spike",
	SFX_NOVA         = "Supernova",
	SFX_SHURI_NASCE  = "anglusdie",
	SFX_SHURI_LANCA  = "ShuriHit",
	SFX_SHURI_ESTOURO = "ShurikenExplode",
	SFX_DOBRA_ABRE   = "TeleportActive",
	SFX_DOBRA_FECHA  = "Explode",
	SFX_INVOCA       = "Power Up",
	SFX_SUCCAO       = "Locked On",
	SFX_EXPLOSAO     = "ShurikenExplode",
	SFX_MINI         = "ShuriHit",
	SFX_COLOSSAL     = "Supernova",
}

--- As 5 direções fixas do split. Tabela, nunca sorteio: com todos os clientes
--- desenhando, um sorteio faria cada um ver uma leva diferente.
local SPREADS_MINI = {
	Vector3.new( 0.00, 1.00,  0.00),
	Vector3.new( 0.85, 0.45,  0.00),
	Vector3.new(-0.85, 0.45,  0.00),
	Vector3.new( 0.00, 0.45,  0.85),
	Vector3.new( 0.00, 0.45, -0.85),
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA. `Vector3.new(0/0, 0/0, 0/0)` é um
--    `Vector3` legítimo para o `typeof`; um cliente modificado manda isso,
--    `.Unit` devolve NaN, e força NaN envenena a assembly do alvo. Nenhum
--    `pcall` pega, porque não há erro — a conta só não tem resultado.
--
--    `n ~= n` é o único teste de NaN em Lua: NaN é o único valor que não é
--    igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda junto.
--
-- E RATE LIMIT É DO SERVIDOR. O `Client` limita a taxa dele e isso não vale
-- nada: quem manda o pacote é o cliente, e cliente modificado manda o quanto
-- quiser. O limite que conta é o daqui.
--
-- Revisão do Codex no PR #1, item P1.6.
--═══════════════════════════════════════════════════════════════

local MIRA_MAX = 400
local PEDIDOS_POR_SEG = 30

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > MIRA_MAX then
		return raiz.Position + delta.Unit * MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem abusa é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= PEDIDOS_POR_SEG
end
local ultimoM1, ultimoE, ultimoQ, ultimoX, ultimoH = 0, 0, 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Onde o combo do M1 está, e quando foi o último golpe.
local passoCombo, ultimoGolpe = 0, 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as cinco virariam globais.
local corte, supernova, shuriken, dobra, hawking

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
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

--═══════════════════════════════════════════════════════════════
-- SOM — DUAS PORTAS, porque o modelo espalhou os Sound em dois lugares
--
-- Dez moravam dentro do `Server` que saiu e foram resgatados para `Tool/SFX/`;
-- quatro sempre estiveram pendurados no `Handle`. `somDe` procura nos dois, e
-- é o único ponto do Server que sabe disso.
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	achado = Handle:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	achado = Tool:FindFirstChild(nome, true)
	if achado and achado:IsA("Sound") then return achado end
	return nil
end

--- Toca no Handle. Serve para o que acontece na mão de quem usa.
local function tocar(nome, pitch, corte_)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte_ or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- Toca numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça
--- que some no quadro seguinte mata o som no quadro em que ele nasce.
local function tocarEm(nome, posicao, pitch, corte_)
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

	Debris:AddItem(ancora, corte_ or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--
-- `TESTES/verificar_beats.py` confere que todo beat despachado aqui existe na
-- sequência do `Poses.lua`.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- A ORIGEM NÃO TINHA `TakeDamage` em todo lugar: ela escrevia no `Health` e
-- reimplementava `IsTeamMate` por fora. `TakeDamage` respeita `ForceField`, e
-- a tag `creator` é o que credita o abate.
--
-- ORDEM DA TAG: `Name` ANTES de `Parent`. Ao contrário, o `Humanoid` recebe um
-- `ObjectValue` chamado "Value" e o abate não conta.
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
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

--- Alvos num raio, por consulta espacial sob demanda — nunca varredura do
--- mundo inteiro por assinatura.
local function alvosEm(posicao, raio, limite)
	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum ~= humanoide and not vistos[hum] then
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
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE_CORTE)
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

--- Dano em área com NÚCLEO e BORDA. Raio grande com dano chapado mata quem
--- está na borda sem nenhum aviso visual.
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
-- M1 — CORTE CÓSMICO
--
-- Combo de três na MESMA entrada. Pela REGRA_DISTRIBUICAO isso é UMA
-- habilidade, não três: "combo de três golpes na mesma entrada é uma".
-- O que muda é a pose e, no terceiro, o dano e o empurrão.
--═══════════════════════════════════════════════════════════════

function corte(mira)
	if not rig then return end

	-- fora da janela, o combo recomeça — senão o jogador guarda o terceiro
	-- golpe na mochila e volta sempre com o mais forte
	if os.clock() - ultimoGolpe > CFG.COMBO_JANELA then
		passoCombo = 0
	end
	ultimoGolpe = os.clock()
	passoCombo = passoCombo % 3 + 1

	local sequencia = ({ "CORTE_A", "CORTE_B", "CORTE_C" })[passoCombo]
	local ehEstocada = passoCombo == 3
	local dano = ehEstocada and CFG.DANO_ESTOCADA or CFG.DANO_CORTE

	local alvo = mira
	if typeof(alvo) ~= "Vector3" then alvo = frente() end

	ocupado = true
	rig:PlaySequence(sequencia, despachar({

		CARGA = { sfx = { CFG.SFX_CARGA, ehEstocada and 0.9 or 1.05 } },

		CORTA = {
			sfx = { ehEstocada and CFG.SFX_ESTOCADA or CFG.SFX_CORTE,
				0.95 + passoCombo * 0.05 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE_CORTE * 0.6)

				vfx("CORTE", {
					posicao = raiz.Position + Vector3.new(0, 1.2, 0),
					direcao = direcao,
					giro = passoCombo * 1.05,   -- cada golpe do combo inclina diferente
					raio = CFG.RAIO_CORTE,
				})

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_CORTE, 8)) do
					aplicarDano(quem, dano)
					local quemRaiz = raizDe(quem)
					if quemRaiz and ehEstocada then
						empurrar(quem, direcao + Vector3.new(0, 0.35, 0),
							CFG.EMPURRAO_CORTE, 0.24)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- E — SUPERNOVA
--
-- Da origem: `Ground` seguido de `Slam`, e a explosão desenhada com
-- `Nova_Circle` + `Nova_Wave`. O dano é em NÚCLEO e BORDA; a origem batia 30
-- chapados num raio só.
--═══════════════════════════════════════════════════════════════

function supernova()
	if not rig or not raiz then return end

	ocupado = true
	rig:PlaySequence("SUPERNOVA", despachar({

		FIRMA = { sfx = { CFG.SFX_NOVA_FIRMA, 0.9 } },

		ESTOURA = {
			sfx = { CFG.SFX_NOVA, 0.95 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("SUPERNOVA", { posicao = centro })
				tocarEm(CFG.SFX_NOVA, centro, 0.85)

				golpearArea(centro, CFG.RAIO_NOVA, CFG.RAIO_NUCLEO_NOVA,
					CFG.DANO_NOVA, CFG.DANO_NOVA_BORDA,
					CFG.EMPURRAO_NOVA, CFG.TOMBO_NOVA, 20)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- Q — SHURIKEN DO ESPAÇO
--
-- O voo é do CLIENTE, a 60 Hz. O servidor percorre a MESMA reta por
-- aritmética, a 1/30 s, só para saber onde ela bate — ele não move peça
-- nenhuma por quadro.
--═══════════════════════════════════════════════════════════════

function shuriken(mira)
	if not rig or not raiz then return end

	local alvo = mira
	if typeof(alvo) ~= "Vector3" then alvo = frente(CFG.ALCANCE_SHURIKEN) end

	ocupado = true
	rig:PlaySequence("INVOCAR", despachar({

		NASCE = { sfx = { CFG.SFX_SHURI_NASCE, 1.0 } },

		LANCA = {
			sfx = { CFG.SFX_SHURI_LANCA, 1.1 },
			faz = function()
				if not raiz then return end

				local origem = raiz.Position + raiz.CFrame.LookVector * 3
					+ Vector3.new(0, 2.4, 0)
				local delta = alvo - origem
				if delta.Magnitude < 1 then
					delta = raiz.CFrame.LookVector * CFG.ALCANCE_SHURIKEN
				end
				local direcao = delta.Unit
				local alcance = math.min(delta.Magnitude, CFG.ALCANCE_SHURIKEN)
				local duracao = alcance / CFG.VELOCIDADE_SHURI
				local destino = origem + direcao * alcance

				local id = novoId("cosmoshuri")
				vfx("SHURIKEN_VOO", {
					id = id, posicao = origem, destino = destino,
					escala = CFG.ESCALA_SHURI, duracao = duracao,
					giro = 26,
				})

				-- o mesmo trajeto, por aritmética, só para achar o impacto
				task.spawn(function()
					local percorrido = 0
					local onde = origem
					local bateu = false

					while percorrido < alcance do
						task.wait(CFG.PASSO_VOO)
						if not personagem or not personagem.Parent then return end
						percorrido = percorrido + CFG.VELOCIDADE_SHURI * CFG.PASSO_VOO
						onde = origem + direcao * math.min(percorrido, alcance)

						local achados = alvosEm(onde, CFG.RAIO_SHURI * 0.35, 1)
						if #achados > 0 then
							bateu = true
							break
						end
					end

					vfx("PARAR", { id = id })
					vfx("SHURIKEN_ESTOURO", { posicao = onde, escala = 1 })
					tocarEm(CFG.SFX_SHURI_ESTOURO, onde, bateu and 1.0 or 0.9)

					for _, quem in ipairs(alvosEm(onde, CFG.RAIO_SHURI, 12)) do
						aplicarDano(quem, CFG.DANO_SHURI)
						local quemRaiz = raizDe(quem)
						if quemRaiz then
							empurrar(quem, (quemRaiz.Position - onde)
								+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SHURI, 0.3)
						end
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- X — DOBRA
--
-- O teleporte da origem. Ela escrevia `hrp.CFrame` num laço e criava uma peça
-- de rastro por salto, no servidor. Aqui a chegada é UMA escrita de `CFrame`,
-- e o rastro inteiro é um beat só para o cliente.
--
-- A chegada é conferida por raycast: teleporte que atravessa parede é o que
-- transforma a habilidade em passe livre para dentro de base fechada.
--═══════════════════════════════════════════════════════════════

function dobra(mira)
	if not rig or not raiz then return end

	local alvo = mira
	if typeof(alvo) ~= "Vector3" then alvo = frente(CFG.ALCANCE_DOBRA) end

	ocupado = true
	rig:PlaySequence("DOBRAR", despachar({

		ABRE = { sfx = { CFG.SFX_DOBRA_ABRE, 1.0 } },

		ATRAVESSA = {
			sfx = { CFG.SFX_DOBRA_FECHA, 0.95 },
			faz = function()
				if not raiz or not personagem then return end

				local saida = raiz.Position
				local delta = alvo - saida
				if delta.Magnitude < 1 then
					delta = raiz.CFrame.LookVector * CFG.ALCANCE_DOBRA
				end
				local distancia = math.min(delta.Magnitude, CFG.ALCANCE_DOBRA)
				local direcao = delta.Unit

				-- para onde dá para ir sem atravessar parede
				local filtro = RaycastParams.new()
				filtro.FilterType = Enum.RaycastFilterType.Exclude
				filtro.FilterDescendantsInstances = { personagem }
				local batida = workspace:Raycast(saida, direcao * distancia, filtro)
				if batida then
					distancia = math.max((batida.Position - saida).Magnitude - 3, 0)
				end

				local chegada = saida + direcao * distancia
					+ Vector3.new(0, CFG.ALTURA_DOBRA, 0)

				vfx("DOBRA", { posicao = saida, destino = chegada })
				tocarEm(CFG.SFX_DOBRA_ABRE, saida, 1.05)
				tocarEm(CFG.SFX_DOBRA_FECHA, chegada, 0.9)

				raiz.CFrame = CFrame.new(chegada, chegada + direcao)

				-- quem estava nas DUAS pontas leva: sair é tão violento
				-- quanto chegar
				for _, ponta in ipairs({ saida, chegada }) do
					for _, quem in ipairs(alvosEm(ponta, CFG.RAIO_DOBRA, 8)) do
						aplicarDano(quem, CFG.DANO_DOBRA)
						local quemRaiz = raizDe(quem)
						if quemRaiz then
							empurrar(quem, (quemRaiz.Position - ponta)
								+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_DOBRA, 0.26)
						end
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- H — HAWKING COSMIC SHURIKEN RADIATION
--
-- Três fases: a shuriken viva que suga, a explosão colossal, e as cinco mini
-- shurikens com fusível de toque-ou-prazo. A mecânica é a que já estava
-- escrita no `HawkingCosmicShurikenRadiation_Server_V1`; o que mudou foi
-- passar a usar o `VFXRemote` da Tool, o `tocar` compartilhado, e ganhar a
-- animação, que ela não tinha.
--═══════════════════════════════════════════════════════════════

local pecasEmVoo = {}

local function guardarEmVoo(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Puxa um alvo para o centro da sucção. Renovado por pulso, nunca contínuo:
--- um `BodyVelocity` permanente tira o controle do alvo por inteiro.
local function puxarPara(centro, alvoHum)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end

	local delta = centro - alvoRaiz.Position
	local dist = delta.Magnitude
	if dist < CFG.ZONA_MORTA or dist < 0.01 then return end

	local fracao = math.clamp(dist / CFG.SUCCAO_RAIO, 0, 1)
	local forca = CFG.PUXAO_MIN + (CFG.PUXAO_MAX - CFG.PUXAO_MIN) * fracao

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, CFG.SUCCAO_PULSO * 0.9)
end

local function estourarMini(onde)
	vfx("HAWKING_MINI_EXPLODE", { posicao = onde, escala = CFG.ESCALA_EXP_MINI })
	for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_MINI, 12)) do
		aplicarDano(alvo, CFG.DANO_MINI)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - onde) + Vector3.new(0, 0.4, 0),
				CFG.EMPURRAO * 0.5, 0.2)
		end
	end
end

local function soltarMini(centro, direcao, indice)
	-- Corpo físico mínimo: uma Part invisível que carrega só a colisão. O
	-- visual é do CLIENTE, que clona o ShurikenModel e gira a 60 Hz.
	local corpo = Instance.new("Part")
	corpo.Name = "HawkingMiniShuriken"
	corpo.Shape = Enum.PartType.Ball
	corpo.Size = Vector3.new(3, 3, 3)
	corpo.Transparency = 1
	corpo.CanCollide = false
	corpo.CanQuery = false
	corpo.Anchored = false
	corpo.Massless = true
	corpo.CFrame = CFrame.new(centro)
	corpo.Parent = workspace
	table.insert(pecasEmVoo, corpo)
	Debris:AddItem(corpo, CFG.VIDA_MINI)
	pcall(function() corpo:SetNetworkOwner(nil) end)

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = direcao.Unit * CFG.VELOCIDADE_MINI
	impulso.Parent = corpo
	Debris:AddItem(impulso, 0.35)

	local id = novoId("hawkmini")
	vfx("HAWKING_MINI", {
		id = id, escala = CFG.ESCALA_MINI,
		alvoParte = corpo, duracao = CFG.VIDA_MINI,
	})

	local estourou = false
	local function detonar()
		if estourou or not corpo.Parent then return end
		estourou = true
		local onde = corpo.Position
		tocarEm(CFG.SFX_MINI, onde, 1.05 + indice * 0.03)
		vfx("PARAR", { id = id })
		corpo.CanTouch = false
		Debris:AddItem(corpo, 0.15)
		estourarMini(onde)
	end

	guardarEmVoo(corpo.Touched:Connect(function(atingido)
		if estourou then return end
		local outro = atingido and atingido.Parent
		if not outro or outro == personagem then return end
		local hum = outro:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or hum == humanoide then return end
		detonar()
	end))

	task.delay(CFG.PRAZO_MINI, detonar)
end

--- Fase 2: dano cai com a distância, e depois o split de cinco.
local function explodirColossal(centro)
	tocarEm(CFG.SFX_EXPLOSAO, centro, 0.85)
	tocarEm(CFG.SFX_COLOSSAL, centro, 0.9)

	vfx("HAWKING_COLOSSAL", { posicao = centro, escala = CFG.ESCALA_EXPLOSAO })

	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_EXPLOSAO, 24)) do
		local alvoRaiz = raizDe(alvo)
		local dano = CFG.DANO_CENTRO
		if alvoRaiz then
			local fracao = math.clamp(
				(alvoRaiz.Position - centro).Magnitude / CFG.RAIO_EXPLOSAO, 0, 1)
			dano = CFG.DANO_CENTRO + (CFG.DANO_BORDA - CFG.DANO_CENTRO) * fracao
		end
		aplicarDano(alvo, math.floor(dano + 0.5))
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.6, 0),
				CFG.EMPURRAO, 0.35)
		end
	end

	local i = 1
	while i <= CFG.MINIS do
		soltarMini(centro, SPREADS_MINI[i], i)
		i = i + 1
	end
end

function hawking()
	if not rig or not raiz then return end

	ocupado = true
	rig:PlaySequence("HAWKING", despachar({

		ERGUE = { sfx = { CFG.SFX_INVOCA, 0.9 } },

		SOLTA = {
			sfx = { CFG.SFX_SUCCAO, 0.8 },
			faz = function()
				if not raiz or not personagem then return end

				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * CFG.DISTANCIA
					+ Vector3.new(0, CFG.ALTURA, 0)
				local id = novoId("hawking")

				-- A shuriken viva é 100% VFX de CLIENTE: ela fica parada no ar
				-- e GIRA, e girar é mudar CFrame todo quadro. No servidor isso
				-- replicaria a ~20 Hz, e o giro viraria tranco.
				vfx("HAWKING_SHURIKEN", {
					id = id, posicao = centro,
					escala = CFG.ESCALA_SHURIKEN,
					giro = CFG.GIRO,
					duracao = CFG.SUCCAO_DURACAO,
					raio = CFG.SUCCAO_RAIO,
				})

				local fim = os.clock() + CFG.SUCCAO_DURACAO
				local proximoPulso = 0

				local laco
				laco = guardarEmVoo(RunService.Heartbeat:Connect(function()
					local agora = os.clock()

					if agora >= fim then
						if laco then laco:Disconnect() end
						vfx("PARAR", { id = id })
						explodirColossal(centro)
						return
					end

					if agora < proximoPulso then return end
					proximoPulso = agora + CFG.SUCCAO_PULSO

					for _, alvo in ipairs(alvosEm(centro, CFG.SUCCAO_RAIO, 20)) do
						puxarPara(centro, alvo)
						-- radiação Hawking: sangra devagar enquanto suga
						aplicarDano(alvo, CFG.DANO_SUCCAO)
					end
				end))
			end,
		},

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
	if quem ~= jogador then return end
	if not taxaOk() then return end
	-- ⚠️ AQUI NÃO HAVIA VALIDAÇÃO NENHUMA: `mira` ia direto para `corte()`.
	mira = sanearMira(mira) or (raiz and raiz.Position) or Vector3.new()
	if not podeAgir() then return end
	if not pronto(ultimoM1, CFG.RECARGA_M1) then return end
	ultimoM1 = os.clock()
	corte(mira)
end)

--- As QUATRO Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de E/Q/X/H é descartada sem resposta.
--- Confiar no cliente para dizer qual habilidade rodar seria dar a ele a
--- escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	if not taxaOk() then return end
	if type(tecla) ~= "string" then return end
	mira = sanearMira(mira) or (raiz and raiz.Position) or Vector3.new()
	if not podeAgir() then return end

	if tecla == "E" then
		if not pronto(ultimoE, CFG.RECARGA_E) then return end
		ultimoE = os.clock()
		supernova()
	elseif tecla == "Q" then
		if not pronto(ultimoQ, CFG.RECARGA_Q) then return end
		ultimoQ = os.clock()
		shuriken(mira)
	elseif tecla == "X" then
		if not pronto(ultimoX, CFG.RECARGA_X) then return end
		ultimoX = os.clock()
		dobra(mira)
	elseif tecla == "H" then
		if not pronto(ultimoH, CFG.RECARGA_H) then return end
		ultimoH = os.clock()
		hawking()
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	passoCombo = 0
	rig = Animator.new(personagem, "COSMIC", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	tocar(CFG.SFX_EQUIPA, 1.0)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(function()
	tocar(CFG.SFX_GUARDA, 1.0)
	desmontar()
end)
Tool.Destroying:Connect(desmontar)

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes de `CosmicVFX2` vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- fica lá até o servidor cair. É o que o script `remove` da origem tentava
-- fazer, só que para `ServerStorage`, que não replica.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
