-- XesterAtodeDesaparecer_Server_V1.lua
-- Script de servidor — Xester Ato de Desaparecer
--
--   M1   Some o alvo dentro de uma carta no chao.
--   Y    Gargalhada (habilidade Extra)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   carta-plataforma 8 x 0.3 x 12 (un.lua:1654)
--   afundamento 0.25/quadro por 35 quadros (un.lua:1719)
--   duas ondas 20329976 crescendo (un.lua:1697, 1708)
--   `enemyhum.Parent:Remove()` (un.lua:1737) VIROU dano pesado
--
-- O QUE NÃO ATRAVESSOU A CONVERSÃO
--   `death()` / `:Remove()` no alvo  — matar por deleção tira o abate do
--                                      Núcleo e apaga o personagem do jogador
--   `damagealll` próprio             — regra de combate tem uma porta só
--   `math.random` no dano            — faixa determinística por contador
--   `swait()` / `wait()`             — task.wait e beat do animator
--   geometria movida por quadro NO SERVIDOR — replica a ~20 Hz picotado
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ARCANO"

local CFG = {
	RECARGA = 24,
	RECARGA_EXTRA = 6,
	ALCANCE = 60,
	ALCANCE_ALVO = 12,
	RAIO_BUSCA = 9,
	CARTA = Vector3.new(8, 0.3, 12),
	GIRO = 10,
	FUNDO = 3,
	MERGULHO = 1.2,
	ESCALA_ONDA = 2.5,
	DANO_MIN = 72,
	DANO_MAX = 96,
	PUXAO = 38,
	CARTAS_RISO = 8,
	RAIO_RISO = 14,
	SUSTO = 24,
}

--══════════════════════════════════════════════════════════════
-- ESTADO
--══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz
local ultimoUso, ultimoExtra = 0, 0
local ultimaMira = nil
local ativos = {}
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 1000000 then semente = 1 end
	return semente
end

--- Faixa determinística no lugar de `math.random(a, b)`.
--- O original sorteava o dano a cada golpe; aqui a variedade vem de uma
--- senoide sobre o contador — mesma dispersão, e reproduzível.
local function naFaixa(minimo, maximo)
	local onda = (math.sin(proximo() * 2.399963) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

--- Ângulo áureo: espalha N pontos sem repetir e sem sortear.
local function anguloDe(indice)
	return math.rad(137.507764 * indice)
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

local function soltarTudo()
	for _, conexao in ipairs(ativos) do
		if conexao.Connected then conexao:Disconnect() end
	end
	ativos = {}
end

--══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo decide (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro.
--══════════════════════════════════════════════════════════════

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

local function alvosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(
			posicao, raio, personagem, jogador, humanoide, limite or 14) or {}
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

--- Golpe em área: dano + empurrão + o beat para o cliente desenhar.
local function golpearArea(posicao, raio, minimo, maximo, forca, limite)
	local atingidos = 0
	for _, alvo in ipairs(alvosEm(posicao, raio, limite or 14)) do
		aplicarDano(alvo, naFaixa(minimo, maximo))
		atingidos = atingidos + 1
		if forca and forca > 0 then
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - posicao)
					+ Vector3.new(0, 0.3, 0), forca, 0.25)
			end
		end
	end
	return atingidos
end

--══════════════════════════════════════════════════════════════
-- MOLDES — o asset vem de DENTRO da Tool (Regra nº 1)
--══════════════════════════════════════════════════════════════

--- Acha um molde por nome, em qualquer profundidade de `Moldes/`.
local function molde(nome)
	return Moldes:FindFirstChild(nome, true)
end

--- Clona um molde para o mundo. O molde mora apagado (Transparency = 1);
--- quem acende é o cliente, ao desenhar. O que o servidor põe no mundo é
--- SÓ o que precisa de física ou de colisão.
local function porNoMundo(nome, cframe, vida)
	local base = molde(nome)
	if not base then return nil end
	local copia = base:Clone()
	copia.Parent = workspace
	if copia:IsA("BasePart") then
		copia.CFrame = cframe
	elseif copia:IsA("Model") and copia.PrimaryPart then
		copia:PivotTo(cframe)
	end
	Debris:AddItem(copia, vida or 8)
	return copia
end

--══════════════════════════════════════════════════════════════
-- PORTA DE ENTRADA — recarga, energia, e o beat
--══════════════════════════════════════════════════════════════

local function podeUsar(quando, recarga)
	if not (personagem and humanoide and humanoide.Health > 0 and raiz) then
		return false
	end
	if os.clock() - quando < recarga then return false end
	return true
end

--- Mira: o cliente manda para onde aponta. O servidor CONFERE o alcance em
--- vez de confiar — payload de cliente é entrada, não verdade.
local function mirar(pedido)
	if typeof(pedido) ~= "Vector3" then
		return raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE
	end
	local delta = pedido - raiz.Position
	if delta.Magnitude > CFG.ALCANCE then
		return raiz.Position + delta.Unit * CFG.ALCANCE
	end
	return pedido
end

--══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o Ato de Desaparecer
--
-- O original ancorava o alvo, descia uma carta-plataforma sob ele e chamava
-- `enemyhum.Parent:Remove()`. Deletar o personagem tira o abate do Núcleo e
-- some com o corpo do jogador — aqui o alvo AFUNDA e leva dano pesado.
--══════════════════════════════════════════════════════════════

local function primaria()
	local frente = raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE_ALVO
	local perto = alvosEm(frente, CFG.RAIO_BUSCA, 1)
	local alvo = perto[1]
	if not alvo then
		-- sem alvo o truque não acontece: devolve a recarga
		ultimoUso = 0
		return
	end

	local corpo = alvo.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz then return end

	local chao = alvoRaiz.Position - Vector3.new(0, CFG.FUNDO, 0)
	vfx("CARTA_CHAO", { posicao = chao, tamanho = CFG.CARTA, giro = CFG.GIRO })

	-- o alvo perde o chão: PlatformStand em vez de Anchored, que travaria o
	-- personagem inteiro e deixaria o jogador preso se a Tool sumisse no meio
	alvo.PlatformStand = true
	task.delay(CFG.MERGULHO, function()
		if alvo and alvo.Parent then alvo.PlatformStand = false end
	end)

	vfx("ONDA_DUPLA", { posicao = chao, escala = CFG.ESCALA_ONDA })
	aplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
	empurrar(alvo, Vector3.new(0, -1, 0), CFG.PUXAO, CFG.MERGULHO)
end

--══════════════════════════════════════════════════════════════
-- EXTRA — Gargalhada
--
-- Provocação. O original desenhava "HaHaHaHaHa" num `BillboardGui`; GUI dentro
-- de Tool é proibido por diretriz, então a risada é som e cartas subindo em
-- volta da cabeça — efeito no mundo 3D, que é onde ele pode existir.
--══════════════════════════════════════════════════════════════

local function extra()
	vfx("GARGALHADA", { posicao = raiz.Position, cartas = CFG.CARTAS_RISO })
	-- provocação empurra sem ferir: quem está perto leva o susto, não o dano
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_RISO, 8)) do
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.SUSTO, 0.2)
		end
	end
end


--══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--══════════════════════════════════════════════════════════════

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	jogador = Players:GetPlayerFromCharacter(personagem)
	humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
end)

Tool.Unequipped:Connect(function()
	soltarTudo()
end)

Tool.Activated:Connect(function()
	if not podeUsar(ultimoUso, CFG.RECARGA) then return end
	ultimoUso = os.clock()
	primaria()
end)

AcaoRemote.OnServerEvent:Connect(function(quem, mira)
	-- O Remote é a porta de fora: confere QUEM chamou antes de qualquer coisa.
	if quem ~= jogador then return end
	if not podeUsar(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	extra(mirar(mira))
end)

--- `Destroying`, não `AncestryChanged`: a Tool pode trocar de pai a cada
--- equipar sem estar sendo destruída.
Tool.Destroying:Connect(function()
	soltarTudo()
end)
