-- XesterBuracoNegro_Server_V1.lua
-- Script de servidor — Xester Buraco Negro
--
--   M1   Portal de carta que suga e colapsa.
--   Y    Raio (habilidade Extra)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   carta-portal 10 x 15 x 0.3 no ponto do mouse (un.lua:1252, 1261)
--   100 orbes de 2 studs sugados (un.lua:1336-1341)
--   raspao em raio 45 (un.lua:1359, 1364)
--   colapso: raio 60, dano 36..55, empurrao 200 (un.lua:1408-1414)
--   Extra: feixe cilindrico ate o mouse (un.lua:3138-3168)
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
local MiraRemote = Tool:WaitForChild("MiraRemote")

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "ARCANO"

local CFG = {
	RECARGA = 50,
	RECARGA_EXTRA = 14,
	ALCANCE = 90,
	CARTA = Vector3.new(10, 15, 0.3),
	ABERTURA = 0.7,
	PULSOS_SUGA = 20,
	INTERVALO = 0.08,
	RAIO_SUGA = 45,
	RASPAO_MIN = 0.4,
	RASPAO_MAX = 1.2,
	SUCCAO = 34,
	ANEIS = 2,
	ESTOUROS = 4,
	RAIO = 60,
	DANO_MIN = 36,
	DANO_MAX = 55,
	EMPURRAO = 200,
	ALCANCE_RAIO = 180,
	DURACAO_RAIO = 2.2,
	INTERVALO_RAIO = 0.1,
	FATIAS_RAIO = 8,
	RAIO_RAIO = 7,
	CALIBRE_RAIO = 3,
	DANO_RAIO_MIN = 5,
	DANO_RAIO_MAX = 11,
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
-- PRIMÁRIA — Buraco Negro
--
-- Três tempos, como no original: a carta-portal abre, 100 orbes são sugados
-- com dano de raspão, e o colapso dá o golpe cheio com empurrão de 200.
--══════════════════════════════════════════════════════════════

local function primaria(destino)
	local centro = mirar(destino)

	vfx("PORTAL_ABRE", { posicao = centro, tamanho = CFG.CARTA })

	-- sucção: dano de raspão a cada pulso, e o alvo é PUXADO (força negativa)
	local i = 1
	while i <= CFG.PULSOS_SUGA do
		local indice = i
		task.delay(CFG.ABERTURA + indice * CFG.INTERVALO, function()
			if not personagem then return end
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_SUGA, 12)) do
				aplicarDano(alvo, naFaixa(CFG.RASPAO_MIN, CFG.RASPAO_MAX))
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					empurrar(alvo, centro - alvoRaiz.Position, CFG.SUCCAO, 0.2)
				end
			end
		end)
		i = i + 1
	end

	-- colapso
	task.delay(CFG.ABERTURA + CFG.PULSOS_SUGA * CFG.INTERVALO, function()
		if not personagem then return end
		vfx("PORTAL_COLAPSA", { posicao = centro, aneis = CFG.ANEIS,
			estouros = CFG.ESTOUROS })
		golpearArea(centro, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
			CFG.EMPURRAO, 16)
	end)
end

--══════════════════════════════════════════════════════════════
-- EXTRA — Raio
--
-- Feixe contínuo do original ("the longer you hold down the key, the stronger
-- it gets"). O feixe em si é CILINDRO DO CLIENTE — geometria esticada por
-- quadro no servidor é exatamente o caso que replica picotado. O servidor
-- pulsa o dano ao longo da linha.
--══════════════════════════════════════════════════════════════

local function extra(mira)
	local origem = raiz.Position + Vector3.new(0, 1.5, 0)
	local delta = mira - origem
	if delta.Magnitude < 1 then return end
	local direcao = delta.Unit
	local alcance = math.min(delta.Magnitude, CFG.ALCANCE_RAIO)

	vfx("RAIO", { origem = origem, direcao = direcao, alcance = alcance,
		duracao = CFG.DURACAO_RAIO, calibre = CFG.CALIBRE_RAIO })

	local pulsos = math.floor(CFG.DURACAO_RAIO / CFG.INTERVALO_RAIO)
	local i = 1
	while i <= pulsos do
		local indice = i
		task.delay(indice * CFG.INTERVALO_RAIO, function()
			if not (personagem and raiz) then return end
			-- amostra a linha em fatias: uma consulta por fatia, não uma por
			-- stud, para não varrer o mundo inteiro a cada pulso
			local fatia = 1
			while fatia <= CFG.FATIAS_RAIO do
				local onde = origem + direcao
					* (alcance * (fatia / CFG.FATIAS_RAIO))
				golpearArea(onde, CFG.RAIO_RAIO, CFG.DANO_RAIO_MIN,
					CFG.DANO_RAIO_MAX, 0, 6)
				fatia = fatia + 1
			end
		end)
		i = i + 1
	end
end


--══════════════════════════════════════════════════════════════
-- MIRA — o mouse é do cliente, a conferência é do servidor
--
-- A primária continua em `Tool.Activated` (§9); o que chega pelo Remote é
-- só PARA ONDE, e a cada 0.1 s. O servidor guarda o último ponto e o
-- `mirar()` corta pelo alcance antes de usar — payload de cliente é entrada,
-- nunca verdade.
--══════════════════════════════════════════════════════════════

MiraRemote.OnServerEvent:Connect(function(quem, ponto)
	if quem ~= jogador then return end
	if typeof(ponto) ~= "Vector3" then return end
	ultimaMira = ponto
end)

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
