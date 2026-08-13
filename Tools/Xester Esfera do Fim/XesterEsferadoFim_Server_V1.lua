-- XesterEsferadoFim_Server_V1.lua
-- Script de servidor — Xester Esfera do Fim
--
--   M1   Carrega, suga durante a carga, e detona.
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
--   300 passos de succao em raio 40 (xesterv2.lua:1348-1349)
--   puxao com velocidade * -50 (xesterv2.lua:1356)
--   estouro: raio 40, empurrao 350 (xesterv2.lua:1392, 1399)
--   `death(...)` (xesterv2.lua:1403) VIROU dano pesado pelo Nucleo
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
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))

--══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--══════════════════════════════════════════════════════════════

local ARQUETIPO = "CEIFA"

local CFG = {
	RECARGA = 44,
	ALCANCE = 60,
	CARGA_MAX = 2.4,
	INTERVALO = 0.1,
	RAIO_SUGA = 40,
	RASPAO_MIN = 1.5,
	RASPAO_MAX = 3.5,
	SUCCAO = 50,
	AVANCO = 8,
	RAIO = 40,
	DANO_MIN = 70,
	DANO_MAX = 95,
	EMPURRAO = 350,
}

--══════════════════════════════════════════════════════════════
-- ESTADO
--══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
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
-- PRIMÁRIA — Esfera do Fim
--
-- Carrega enquanto segura, suga durante a carga, e detona ao soltar. O
-- original prendia a carga num `repeat ... until charging == false` amarrado
-- ao Button1Up do cliente; aqui a carga é um prazo com teto, para uma Tool
-- largada no chão não deixar sucção rodando para sempre.
--══════════════════════════════════════════════════════════════

local carregando = false

local function detonar(centro, forca)
	vfx("ESFERA_DETONA", { posicao = centro, escala = forca })
	golpearArea(centro, CFG.RAIO * forca, CFG.DANO_MIN * forca,
		CFG.DANO_MAX * forca, CFG.EMPURRAO, 16)
end

local function primaria()
	if carregando then return end
	carregando = true

	vfx("ESFERA_CARREGA", { duracao = CFG.CARGA_MAX })

	local pulsos = math.floor(CFG.CARGA_MAX / CFG.INTERVALO)
	local i = 1
	while i <= pulsos do
		local indice = i
		task.delay(indice * CFG.INTERVALO, function()
			if not (carregando and personagem and raiz) then return end
			-- sucção: puxa para o portador, com dano de raspão
			for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SUGA, 12)) do
				aplicarDano(alvo, naFaixa(CFG.RASPAO_MIN, CFG.RASPAO_MAX))
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					empurrar(alvo, raiz.Position - alvoRaiz.Position, CFG.SUCCAO, 0.2)
				end
			end
		end)
		i = i + 1
	end

	task.delay(CFG.CARGA_MAX, function()
		if not carregando then return end
		carregando = false
		if personagem and raiz then
			detonar(raiz.Position + raiz.CFrame.LookVector * CFG.AVANCO, 1)
		end
	end)
end


--══════════════════════════════════════════════════════════════
-- ANIMAÇÃO — o rig é DO SERVIDOR
--
-- `Instance.new("Weld")` criado num LocalScript é instância LOCAL: não replica.
-- Enquanto o rig morou no cliente, os outros jogadores viam o portador
-- executando a habilidade PARADO. Weld do servidor replica, e o C0 junto.
--══════════════════════════════════════════════════════════════

local function montarRig()
	if rig then return rig end
	if not personagem then return nil end
	rig = Animator.new(personagem, "XesterEsferadoFim", Poses, Poses.SEQUENCIAS)
	return rig
end

local function animar(sequencia)
	local atual = montarRig()
	if not atual then return end
	atual:PlaySequence(sequencia, function(passo)
		if passo.marca then vfx("BEAT", { marca = passo.marca }) end
	end)
end

local function desmontarRig()
	if not rig then return end
	rig:CancelSequence()
	rig:ReleaseLegs()
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
	carregando = false
end)

Tool.Activated:Connect(function()
	if not podeUsar(ultimoUso, CFG.RECARGA) then return end
	ultimoUso = os.clock()
	primaria()
end)

--- `Destroying`, não `AncestryChanged`: a Tool pode trocar de pai a cada
--- equipar sem estar sendo destruída.
Tool.Destroying:Connect(function()
	soltarTudo()
	carregando = false
end)
