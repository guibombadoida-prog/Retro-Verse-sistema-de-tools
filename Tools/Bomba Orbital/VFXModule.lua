-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto PODERES DE BOMBA
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: A EXPLOSÃO TEM TRÊS TEMPOS
--═══════════════════════════════════════════════════════════════
--
--   Explosão desenhada como um clarão só lê como flash de foto. O que faz ler
--   como explosão são três tempos que NÃO começam juntos:
--
--     1. o CLARÃO, em 0.06 s — o contato, e só ele é instantâneo
--     2. a ONDA, em 0.5 s — o anel que abre no chão, atrasado em 0.04 s
--     3. a POEIRA, em 1.4 s — o que sobe depois, atrasado em 0.12 s
--
--   Os atrasos são o efeito inteiro. Sem eles as três camadas nascem no mesmo
--   quadro e o olho lê uma coisa só, mais brilhante.
--
--   As camadas:
--
--     `camadaClarao`     a esfera branca de 0.06 s
--     `camadaOnda`       o anel chato que abre
--     `camadaCogumelo`   haste + capelo, a nuvem da nuclear
--     `camadaEstilhaco`  cacos arremessados, por ângulo áureo
--     `camadaPoeira`     as bolas escuras que sobem devagar
--     `camadaEspuma`     a espuma da Coca — bolhas claras, sem gravidade
--     `camadaPavio`      a luz que pisca na bomba plantada
--     `camadaArco`       o salto de um elo para o outro
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `Instance.new("Explosion")` — ela empurra e destrói junta por conta
--   própria, sem passar por `TakeDamage` nem respeitar `ForceField`, e o
--   servidor perde o controle do que ela fez.
--
--   Zero `math.random`: o ângulo áureo distribui estilhaço, bolha e poeira, e
--   é isso que faz todos os clientes desenharem a MESMA explosão. Sorteio por
--   cliente, com todo mundo desenhando, lê como lag.
--
--   Zero `:Destroy()` — `Parent = nil` e `Debris`. Zero `tick()` — acumulador
--   de `dt` a partir de zero.

local Debris       = game:GetService("Debris")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	LIMITE_VIVOS = 260,

	FOGO      = Color3.fromRGB(255, 148, 46),
	BRASA     = Color3.fromRGB(255, 92, 28),
	FUMACA    = Color3.fromRGB(64, 60, 58),
	RADIACAO  = Color3.fromRGB(150, 240, 150),
	COCA      = Color3.fromRGB(140, 30, 26),
	ESPUMA    = Color3.fromRGB(238, 226, 196),
	AZUL      = Color3.fromRGB(120, 200, 255),
	VAZIO     = Color3.fromRGB(18, 8, 32),
	ALERTA    = Color3.fromRGB(255, 72, 72),

	--- os três tempos, e os dois atrasos que fazem a explosão ler como uma
	ATRASO_ONDA   = 0.04,
	ATRASO_POEIRA = 0.12,

	TREMOR_FORCA = 0.5,
	TREMOR_TEMPO = 0.8,
}

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function angulo(i)
	return (i or proximo()) * CFG.ANGULO_AUREO
end

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id]
end

local function anotar(d, inst, conexao)
	local reg = registroDe(d)
	if not reg then return inst end
	if inst then table.insert(reg.partes, inst) end
	if conexao then table.insert(reg.conexoes, conexao) end
	return inst
end

local function registrar(inst, vida)
	table.insert(Vivos, inst)
	if #Vivos > CFG.LIMITE_VIVOS then
		local velho = table.remove(Vivos, 1)
		if velho and velho.Parent then velho.Parent = nil end
	end
	if vida then Debris:AddItem(inst, vida) end
	return inst
end

local function novaParte(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Massless, p.CastShadow = true, false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, estilo, direcao)
	local info = TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad,
		direcao or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, alvo)
	t:Play()
	return t
end

local function branco(cor, quanto)
	return cor:Lerp(Color3.new(1, 1, 1), quanto or 0.5)
end

local function acima(p, quanto)
	return (p or Vector3.new()) + Vector3.new(0, quanto or 1.6, 0)
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois. A segunda
-- não é redundância — num place vazio ninguém montou depósito nenhum.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function acharPack()
	if packProcurado then return raizPack end
	packProcurado = true
	raizPack = Deposito.achar(script, PACK.PASTA)
		or script:FindFirstChild(PACK.PASTA)
	return raizPack
end

local function efeitoDoPack(nome)
	if not PACK.LIGADO then return nil end
	local guardado = moduloDoPack[nome]
	if guardado ~= nil then
		if guardado == false then return nil end
		return guardado
	end
	local raiz = acharPack()
	if not raiz then moduloDoPack[nome] = false return nil end
	local modulo = raiz:FindFirstChild(nome)
	if not modulo or not modulo:IsA("ModuleScript") then
		moduloDoPack[nome] = false
		return nil
	end
	local ok, fn = pcall(require, modulo)
	if not ok or type(fn) ~= "function" then
		moduloDoPack[nome] = false
		return nil
	end
	moduloDoPack[nome] = fn
	return fn
end

--- `pk` de nome que não existe no pack devolve false EM SILÊNCIO. Os dez nomes
--- reais são Floor_Crack, Laser_Shot, Shockwave, Shockwave_2,
--- Shockwave_Explosion, Small_Nova, Small_Slash, Smoky_Explosion, Sonar_Ring e
--- Spiral_Effect — `TESTES/verificar_pack_vfx.py` confere os TIPOS de cada
--- chamada, mas não inventa nome nenhum para quem errar.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Bomba] pack " .. tostring(nome) .. ": "
			.. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA
--
-- `workspace.CurrentCamera` é singleton por cliente, e este módulo roda em
-- cliente: é acesso de serviço, não depósito de asset. O tremor é aplicado por
-- MULTIPLICAÇÃO relativa e some sozinho — nada aqui escreve `CameraType`, e
-- por isso não há câmera a devolver. Quem escreve `CameraType` neste conjunto
-- é a `CutsceneCam`, e ela devolve por seis portas.
--═══════════════════════════════════════════════════════════════

local tremorAtivo = nil

local function tremor(forca, duracao)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
	if not workspace.CurrentCamera then return end

	local passado = 0
	tremorAtivo = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not workspace.CurrentCamera then
			if tremorAtivo then
				tremorAtivo:Disconnect()
				tremorAtivo = nil
			end
			return
		end
		local restante = 1 - (passado / duracao)
		local a = forca * restante
		-- ruído senoidal por acumulador de dt, nunca tick()
		local x = math.sin(passado * 61.3) * a
		local y = math.sin(passado * 47.7 + 1.3) * a
		local z = math.sin(passado * 53.1 + 2.6) * a * 0.4
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(
			math.rad(x), math.rad(y), math.rad(z))
	end)
end

--═══════════════════════════════════════════════════════════════
-- AS CAMADAS
--═══════════════════════════════════════════════════════════════

--- TEMPO 1: o contato. 0.06 s — mais que isso e vira a explosão inteira, que
--- não é o que ele é.
local function camadaClarao(p, c, raio)
	local flash = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 0.5, raio * 0.5, raio * 0.5),
		Color = branco(c, 0.85),
		Transparency = 0,
		CFrame = CFrame.new(p),
	})
	registrar(flash, 0.25)
	tween(flash, 0.06, {
		Transparency = 1,
		Size = Vector3.new(raio * 1.4, raio * 1.4, raio * 1.4),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = branco(c, 0.6), 8, raio * 2.5
	luz.Parent = flash
	return flash
end

--- TEMPO 2: o anel que abre no chão.
local function camadaOnda(p, c, raioFinal, vida)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 3, 3),
		Color = c,
		Transparency = 0.2,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(anel, (vida or 0.5) + 0.3)
	tween(anel, vida or 0.5, {
		Transparency = 1,
		Size = Vector3.new(0.08, raioFinal * 2, raioFinal * 2),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return anel
end

--- TEMPO 3: o que sobe depois. Escuro, lento, e por ângulo áureo.
local function camadaPoeira(p, c, raio, quantidade, vida)
	local n = quantidade or 14
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.2 + (i / n) * 0.8)
		local onde = p + Vector3.new(math.cos(a) * alcance, 0.4,
			math.sin(a) * alcance)
		local lado = raio * (0.12 + math.abs(jitter(a)) * 0.16)
		local bola = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(lado, lado, lado),
			Color = c,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.25,
			CFrame = CFrame.new(onde),
		})
		registrar(bola, (vida or 1.4) + 0.3)
		tween(bola, vida or 1.4, {
			Transparency = 1,
			Size = Vector3.new(lado * 2.2, lado * 2.2, lado * 2.2),
			CFrame = CFrame.new(onde + Vector3.new(
				math.cos(a) * raio * 0.3,
				raio * (0.4 + math.abs(jitter(a + 1)) * 0.5),
				math.sin(a) * raio * 0.3)),
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
end

--- Os cacos. Arremessados para fora, e para cima.
local function camadaEstilhaco(p, c, forca, quantidade, vida)
	local n = quantidade or 16
	for i = 1, n do
		local a = angulo(i)
		local direcao = Vector3.new(math.cos(a),
			0.35 + math.abs(jitter(a)) * 0.9, math.sin(a)).Unit
		local lado = 0.2 + math.abs(jitter(a + 0.7)) * 0.35
		local caco = novaParte({
			Size = Vector3.new(lado, lado, lado * 2.4),
			Color = branco(c, 0.4),
			Transparency = 0.05,
			CFrame = CFrame.lookAt(p, p + direcao),
		})
		registrar(caco, (vida or 0.6) + 0.2)
		tween(caco, vida or 0.6, {
			Transparency = 1,
			CFrame = CFrame.lookAt(p + direcao * forca,
				p + direcao * forca * 2),
			Size = Vector3.new(lado * 0.3, lado * 0.3, lado),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
end

--- A NUVEM DA NUCLEAR: haste + capelo.
---
--- É o que separa "explosão grande" de "nuclear". A haste sobe primeiro e o
--- capelo abre EM CIMA dela, atrasado — abrir os dois juntos dá uma bola, não
--- um cogumelo.
local function camadaCogumelo(p, altura, raioCapelo, c, cFumaca)
	local haste = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, raioCapelo * 0.5, raioCapelo * 0.5),
		Color = c,
		Transparency = 0.15,
		CFrame = CFrame.new(p + Vector3.new(0, 1, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(haste, 2.6)
	tween(haste, 0.9, {
		Size = Vector3.new(altura, raioCapelo * 0.7, raioCapelo * 0.7),
		CFrame = CFrame.new(p + Vector3.new(0, altura * 0.5, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tween(haste, 2.2, { Transparency = 1 }, Enum.EasingStyle.Sine,
		Enum.EasingDirection.In)

	-- o capelo abre 0.35 s DEPOIS da haste começar a subir
	task.delay(0.35, function()
		local topo = p + Vector3.new(0, altura, 0)
		local capelo = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 4, 4),
			Color = cFumaca or CFG.FUMACA,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.2,
			CFrame = CFrame.new(topo),
		})
		registrar(capelo, 2.4)
		tween(capelo, 1.1, {
			Size = Vector3.new(raioCapelo * 2, raioCapelo * 1.3,
				raioCapelo * 2),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(capelo, 2.0, { Transparency = 1 }, Enum.EasingStyle.Sine,
			Enum.EasingDirection.In)

		local coroa = novaParte({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 6, 6),
			Color = c,
			Transparency = 0.4,
			CFrame = CFrame.new(topo) * CFrame.Angles(0, 0, math.rad(90)),
		})
		registrar(coroa, 2.2)
		tween(coroa, 1.3, {
			Transparency = 1,
			Size = Vector3.new(0.3, raioCapelo * 3, raioCapelo * 3),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end)
end

--- A ESPUMA DA COCA. Bolhas claras que sobem devagar e NÃO caem: espuma de
--- refrigerante não tem peso — é o que a separa da poeira.
local function camadaEspuma(p, quantidade, forca, vida)
	local n = quantidade or 22
	for i = 1, n do
		local a = angulo(i)
		local sobe = 0.5 + math.abs(jitter(a)) * 1.0
		local direcao = Vector3.new(math.cos(a) * 0.7, sobe,
			math.sin(a) * 0.7).Unit
		local lado = 0.35 + math.abs(jitter(a + 1.3)) * 0.5
		local bolha = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(lado, lado, lado),
			Color = CFG.ESPUMA,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.1,
			CFrame = CFrame.new(p),
		})
		registrar(bolha, (vida or 1.0) + 0.3)
		tween(bolha, vida or 1.0, {
			Transparency = 1,
			CFrame = CFrame.new(p + direcao * forca),
			Size = Vector3.new(lado * 1.6, lado * 1.6, lado * 1.6),
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
end

--- O PAVIO: a luz que pisca numa bomba plantada.
---
--- Ela pisca cada vez MAIS RÁPIDO conforme o prazo se esgota, e é o único
--- aviso que o adversário tem. Piscar em ritmo constante não avisa nada.
local function camadaPavio(d, p, c, duracao)
	local corpo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Color = Color3.fromRGB(48, 48, 54),
		Material = Enum.Material.Metal,
		Transparency = 0,
		CFrame = CFrame.new(p),
	})
	anotar(d, corpo)
	registrar(corpo, duracao + 0.6)

	local luz = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.5, 0.5, 0.5),
		Color = c,
		Transparency = 0,
		CFrame = CFrame.new(p + Vector3.new(0, 0.9, 0)),
	})
	anotar(d, luz)
	registrar(luz, duracao + 0.6)

	local ponto = Instance.new("PointLight")
	ponto.Color, ponto.Brightness, ponto.Range = c, 3, 10
	ponto.Parent = luz

	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not luz.Parent then
			laco:Disconnect()
			return
		end
		-- a frequência cresce de 3 Hz até 14 Hz ao longo do prazo
		local fracao = passado / duracao
		local hz = 3 + fracao * 11
		local aceso = math.sin(passado * hz * math.pi * 2) > 0
		luz.Transparency = aceso and 0 or 0.75
		ponto.Brightness = aceso and 4 or 0.4
	end)
	anotar(d, nil, laco)
	return corpo
end

--- O ARCO: o salto de um elo da corrente para o outro.
local function camadaArco(a, b, c, vida)
	local delta = b - a
	local comprimento = delta.Magnitude
	if comprimento < 0.5 then return end

	-- cinco nós com desvio lateral, para o arco não ser uma reta
	local NOS = 5
	local anterior = a
	for i = 1, NOS do
		local fracao = i / NOS
		local reto = a + delta * fracao
		local desvio = Vector3.new(jitter(fracao * 3), jitter(fracao * 5),
			jitter(fracao * 7)) * (comprimento * 0.06)
		local ponto = (i == NOS) and b or (reto + desvio)

		local seg = ponto - anterior
		local pedaco = novaParte({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(seg.Magnitude, 0.5, 0.5),
			Color = branco(c, 0.5),
			Transparency = 0.05,
			CFrame = CFrame.lookAt(anterior + seg * 0.5, ponto)
				* CFrame.Angles(0, math.rad(90), 0),
		})
		registrar(pedaco, (vida or 0.3) + 0.2)
		tween(pedaco, vida or 0.3, {
			Transparency = 1,
			Size = Vector3.new(seg.Magnitude, 0.1, 0.1),
		})
		anterior = ponto
	end
end

--═══════════════════════════════════════════════════════════════
-- A EXPLOSÃO COMPLETA — os três tempos, com os dois atrasos
--
-- Esta é a função que quase todos os efeitos daqui chamam. Ela existe para que
-- os atrasos sejam escritos UMA vez: espalhados por catorze habilidades, mais
-- cedo ou mais tarde alguém escreveria as três camadas no mesmo quadro e a
-- explosão daquela Tool leria diferente de todas as outras.
--═══════════════════════════════════════════════════════════════

local function explosao(p, raio, c, cFumaca, forcaCaco)
	camadaClarao(p, c, raio * 0.55)

	task.delay(CFG.ATRASO_ONDA, function()
		camadaOnda(p, c, raio, 0.5)
		camadaEstilhaco(p, c, forcaCaco or raio * 0.8, 16, 0.6)
	end)

	task.delay(CFG.ATRASO_POEIRA, function()
		camadaPoeira(p, cFumaca or CFG.FUMACA, raio * 0.7, 14, 1.4)
	end)
end

--═══════════════════════════════════════════════════════════════
-- LEITURA DO PAYLOAD
--═══════════════════════════════════════════════════════════════

local function pos(d)
	return (d and typeof(d.posicao) == "Vector3") and d.posicao or Vector3.new()
end

local function dir(d)
	local v = d and d.direcao
	if typeof(v) ~= "Vector3" or v.Magnitude < 0.01 then
		return Vector3.new(0, 0, -1)
	end
	return v.Unit
end

local function raioDe(d, padrao)
	return (d and tonumber(d.raio)) or padrao
end

local function corDe(d, padrao)
	return (d and typeof(d.cor) == "Color3") and d.cor or padrao
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS
--
-- `TESTES/verificar_vfx_chamadas.py` confere que toda porta chamada pelos
-- Servers existe aqui. Efeito transmitido sem definição não desenha e nada
-- avisa.
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

-- ── 1. FILA DE BOMBAS ────────────────────────────────────────────────────

--- Uma bomba plantada, com o pavio piscando cada vez mais rápido.
function Efeitos.BOMBA_PLANTADA(d)
	camadaPavio(d, pos(d) + Vector3.new(0, 0.8, 0),
		corDe(d, CFG.FOGO), (d and tonumber(d.duracao)) or 4)
end

--- Um elo da fila indo. Menor que a explosão padrão: são vários.
function Efeitos.ESTOURO_FILA(d)
	local p = acima(pos(d), 1)
	local c = corDe(d, CFG.FOGO)
	explosao(p, raioDe(d, 14), c, CFG.FUMACA, 10)
	pk("Shockwave_Explosion", p, 0.5, 2, raioDe(d, 14), c, branco(c, 0.6))
end

--- E o R: a fila inteira de uma vez.
function Efeitos.DETONAR_TUDO(d)
	local p = acima(pos(d), 1)
	local c = corDe(d, CFG.BRASA)
	local raio = raioDe(d, 22)
	explosao(p, raio, c, CFG.FUMACA, raio * 0.9)
	camadaOnda(p, branco(c, 0.4), raio * 1.4, 0.75)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
	pk("Smoky_Explosion", p, 0.9, raio * 0.5, c, CFG.FUMACA)
end

-- ── 2. EXPLOSAO NUCLEAR ──────────────────────────────────────────────────

--- A ogiva voando. O voo é do CLIENTE, a 60 Hz.
function Efeitos.OGIVA(d)
	local origem = pos(d)
	local destino = (d and typeof(d.destino) == "Vector3") and d.destino
		or (origem + dir(d) * 60)
	local duracao = math.max((d and tonumber(d.duracao)) or 0.7, 0.05)

	local corpo = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 1.1, 1.1),
		Color = Color3.fromRGB(238, 240, 244),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
		CFrame = CFrame.lookAt(origem, destino) * CFrame.Angles(0, math.rad(90), 0),
	})
	anotar(d, corpo)
	registrar(corpo, duracao + 0.5)

	local delta = destino - origem
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		local fracao = math.min(passado / duracao, 1)
		if not corpo.Parent then laco:Disconnect() return end
		local onde = origem + delta * fracao
		corpo.CFrame = CFrame.lookAt(onde, onde + delta.Unit)
			* CFrame.Angles(0, math.rad(90), 0)
		-- rastro: uma brasa a cada quadro, apagando atrás
		if fracao < 1 then
			local brasa = novaParte({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.8, 0.8, 0.8),
				Color = CFG.BRASA,
				Transparency = 0.3,
				CFrame = CFrame.new(onde),
			})
			registrar(brasa, 0.5)
			tween(brasa, 0.3, { Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1) })
		end
		if fracao >= 1 then laco:Disconnect() end
	end)
	anotar(d, nil, laco)
end

--- O cogumelo. A grande da Tool.
function Efeitos.NUCLEAR(d)
	local p = acima(pos(d), 1)
	local raio = raioDe(d, 46)
	local c = corDe(d, CFG.FOGO)

	explosao(p, raio, c, CFG.FUMACA, raio * 0.9)
	camadaCogumelo(p, raio * 1.1, raio * 0.45, c, CFG.FUMACA)
	camadaOnda(p, branco(c, 0.5), raio * 1.5, 0.9)
	tremor(CFG.TREMOR_FORCA * 1.5, CFG.TREMOR_TEMPO * 1.6)
	pk("Smoky_Explosion", p, 1.2, raio * 0.5, c, CFG.FUMACA)
end

--- A poeira que fica queimando depois. É o que dá o dano por tique.
function Efeitos.POEIRA(d)
	local p = pos(d)
	local raio = raioDe(d, 26)
	local duracao = (d and tonumber(d.duracao)) or 6

	local chao = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, raio * 2, raio * 2),
		Color = CFG.RADIACAO,
		Transparency = 0.72,
		CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	anotar(d, chao)
	registrar(chao, duracao + 0.6)

	local passado, proximaLufada = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not chao.Parent then
			laco:Disconnect()
			if chao.Parent then
				tween(chao, 0.5, { Transparency = 1 })
			end
			return
		end
		if passado < proximaLufada then return end
		proximaLufada = passado + 0.5
		camadaPoeira(p, CFG.RADIACAO, raio * 0.8, 6, 1.6)
	end)
	anotar(d, nil, laco)
end

-- ── 3. COCA EXPLOSIVA ────────────────────────────────────────────────────

--- A garrafa voando, empurrada pela própria espuma.
---
--- A trajetória NÃO é reta: ela guina. O servidor manda os pontos por onde ela
--- passa, e o cliente interpola entre eles — assim os dois concordam sobre
--- onde ela está sem o servidor mover peça por quadro.
function Efeitos.GARRAFA(d)
	local pontos = d and d.pontos
	if type(pontos) ~= "table" or #pontos < 2 then return end
	local duracao = math.max((d and tonumber(d.duracao)) or 1.1, 0.1)

	local garrafa = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.4, 1.1, 1.1),
		Color = CFG.COCA,
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		CFrame = CFrame.new(pontos[1]),
	})
	anotar(d, garrafa)
	registrar(garrafa, duracao + 0.5)

	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if not garrafa.Parent then laco:Disconnect() return end
		local fracao = math.min(passado / duracao, 1)

		-- em que trecho da guinada ela está
		local escala = fracao * (#pontos - 1)
		local i = math.clamp(math.floor(escala) + 1, 1, #pontos - 1)
		local dentro = escala - (i - 1)
		local onde = pontos[i]:Lerp(pontos[i + 1], dentro)

		garrafa.CFrame = CFrame.new(onde)
			* CFrame.Angles(passado * 14, passado * 9, 0)

		-- e vai deixando espuma pelo caminho
		camadaEspuma(onde, 2, 2.5, 0.5)

		if fracao >= 1 then laco:Disconnect() end
	end)
	anotar(d, nil, laco)
end

--- O estouro da garrafa: espuma, não fogo.
function Efeitos.ESPUMA(d)
	local p = acima(pos(d), 1)
	local raio = raioDe(d, 18)

	camadaClarao(p, CFG.ESPUMA, raio * 0.4)
	camadaEspuma(p, 40, raio * 0.7, 1.3)
	camadaOnda(p, CFG.ESPUMA, raio, 0.6)
	pk("Shockwave_Explosion", p, 0.6, 2, raio, CFG.ESPUMA, CFG.COCA)
end

--- O R: o jato de espuma em cone.
function Efeitos.JATO(d)
	local p = acima(pos(d), 2)
	local direcao = dir(d)
	local alcance = raioDe(d, 28)

	for i = 0, 6 do
		local fracao = i / 6
		local onde = p + direcao * (alcance * fracao)
		camadaEspuma(onde, 8, 3 + fracao * 5, 0.8 + fracao * 0.4)
	end
end

-- ── 4. BOMBA ORBITAL ─────────────────────────────────────────────────────

--- A zona marcada pelo farol.
function Efeitos.FAROL(d)
	local p = pos(d)
	local raio = raioDe(d, 24)
	local duracao = (d and tonumber(d.duracao)) or 10

	local marca = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio * 2, raio * 2),
		Color = CFG.AZUL,
		Transparency = 0.7,
		CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	anotar(d, marca)
	registrar(marca, duracao + 0.5)

	local coluna = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 2.4, 2.4),
		Color = CFG.AZUL,
		Transparency = 0.86,
		CFrame = CFrame.new(p + Vector3.new(0, 30, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	anotar(d, coluna)
	registrar(coluna, duracao + 0.5)

	local passado, proximoAnel = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not marca.Parent then
			laco:Disconnect()
			return
		end
		if passado < proximoAnel then return end
		proximoAnel = passado + 0.9
		camadaOnda(p + Vector3.new(0, 0.5, 0), CFG.AZUL, raio, 0.85)
	end)
	anotar(d, nil, laco)
end

--- A queda: o feixe descendo do céu.
function Efeitos.QUEDA(d)
	local p = pos(d)
	local duracao = math.max((d and tonumber(d.duracao)) or 0.8, 0.1)
	local alto = p + Vector3.new(0, 220, 0)

	local feixe = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(220, 6, 6),
		Color = branco(CFG.AZUL, 0.5),
		Transparency = 0.25,
		CFrame = CFrame.new(alto:Lerp(p, 0.5)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	anotar(d, feixe)
	registrar(feixe, duracao + 0.4)
	tween(feixe, duracao, { Size = Vector3.new(220, 22, 22), Transparency = 0.05 },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	-- a ogiva descendo dentro do feixe
	local casco = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		Color = CFG.BRASA,
		Transparency = 0,
		CFrame = CFrame.new(alto),
	})
	anotar(d, casco)
	registrar(casco, duracao + 0.4)
	tween(casco, duracao, { CFrame = CFrame.new(p) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
end

--- E o impacto orbital.
function Efeitos.IMPACTO_ORBITAL(d)
	local p = acima(pos(d), 1)
	local raio = raioDe(d, 40)
	local c = corDe(d, CFG.AZUL)

	explosao(p, raio, c, CFG.FUMACA, raio)
	camadaOnda(p, branco(c, 0.6), raio * 1.6, 0.95)
	camadaOnda(p, c, raio * 1.1, 0.7)
	tremor(CFG.TREMOR_FORCA * 1.3, CFG.TREMOR_TEMPO * 1.4)
	-- Floor_Crack(CF, Size, Lasting, Color)
	pk("Floor_Crack", CFrame.new(pos(d)), raio * 0.6, 3, c)
end

-- ── 5. BOMBA DE IMPLOSAO ─────────────────────────────────────────────────

--- O núcleo semeado, que puxa.
function Efeitos.NUCLEO(d)
	local p = acima(pos(d), 2)
	local raio = raioDe(d, 28)
	local duracao = (d and tonumber(d.duracao)) or 5

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 2.6, 2.6),
		Color = CFG.VAZIO,
		Material = Enum.Material.Glass,
		Reflectance = 0.2,
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	anotar(d, bola)
	registrar(bola, duracao + 0.6)

	local halo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 0.5, raio * 0.5, raio * 0.5),
		Color = CFG.AZUL,
		Transparency = 0.88,
		CFrame = CFrame.new(p),
	})
	anotar(d, halo)
	registrar(halo, duracao + 0.6)

	-- as lascas que caem PARA DENTRO. É o que faz ler como implosão em vez de
	-- aura: tudo se move na direção do centro, não para fora dele.
	local passado, proximaLasca = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not bola.Parent then
			laco:Disconnect()
			return
		end
		if passado < proximaLasca then return end
		proximaLasca = passado + 0.09

		local a = angulo()
		local alto = 0.3 + math.abs(jitter(a)) * 1.2
		local fora = p + Vector3.new(math.cos(a) * raio * 0.8,
			alto * raio * 0.3, math.sin(a) * raio * 0.8)
		local lasca = novaParte({
			Size = Vector3.new(0.3, 0.3, 1.4),
			Color = CFG.AZUL,
			Transparency = 0.15,
			CFrame = CFrame.lookAt(fora, p),
		})
		registrar(lasca, 0.7)
		tween(lasca, 0.5, {
			Transparency = 1,
			CFrame = CFrame.lookAt(p, p + (p - fora)),
			Size = Vector3.new(0.06, 0.06, 0.4),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	end)
	anotar(d, nil, laco)
end

--- O colapso: some para dentro, e SÓ ENTÃO estoura.
function Efeitos.COLAPSO(d)
	local p = acima(pos(d), 2)
	local raio = raioDe(d, 36)
	local c = corDe(d, CFG.AZUL)

	-- primeiro a sucção visual: uma casca que fecha
	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 1.6, raio * 1.6, raio * 1.6),
		Color = c,
		Transparency = 0.75,
		CFrame = CFrame.new(p),
	})
	registrar(casca, 1.2)
	tween(casca, 0.3, {
		Size = Vector3.new(1, 1, 1),
		Transparency = 0.1,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	-- e o estouro vem DEPOIS de ela fechar. Os 0.3 s são a habilidade
	-- inteira: implosão que estoura junto com a sucção é só uma explosão.
	task.delay(0.3, function()
		explosao(p, raio, branco(c, 0.4), CFG.VAZIO, raio)
		camadaOnda(p, c, raio * 1.5, 0.8)
		tremor(CFG.TREMOR_FORCA * 1.2, CFG.TREMOR_TEMPO * 1.3)
		pk("Small_Nova", p, 0.8, 4, raio, c, branco(c, 0.7))
	end)
end

-- ── 6. BOMBA EM CORRENTE ─────────────────────────────────────────────────

--- O estopim: a marca no primeiro alvo.
function Efeitos.ESTOPIM(d)
	local peca = d and d.peca
	local c = corDe(d, CFG.FOGO)
	local duracao = (d and tonumber(d.duracao)) or 6

	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)
	local marca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.1, 1.1, 1.1),
		Color = c,
		Transparency = 0.1,
		CFrame = CFrame.new(onde + Vector3.new(0, 3.6, 0)),
	})
	anotar(d, marca)
	registrar(marca, duracao + 0.5)

	if not (peca and peca:IsA("BasePart")) then return end
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not (marca.Parent and peca.Parent) then
			laco:Disconnect()
			if marca.Parent then marca.Parent = nil end
			return
		end
		marca.CFrame = peca.CFrame
			* CFrame.new(0, 3.6 + math.sin(passado * 5) * 0.3, 0)
	end)
	anotar(d, nil, laco)
end

--- O salto de um elo para o outro.
function Efeitos.SALTO(d)
	local a = pos(d)
	local b = (d and typeof(d.destino) == "Vector3") and d.destino or a
	camadaArco(acima(a, 2.4), acima(b, 2.4), corDe(d, CFG.FOGO), 0.3)
end

--- E o estouro de cada elo.
function Efeitos.ESTOURO_ELO(d)
	local p = acima(pos(d), 1.4)
	local c = corDe(d, CFG.FOGO)
	local raio = raioDe(d, 16)
	explosao(p, raio, c, CFG.FUMACA, raio * 0.8)
	pk("Shockwave_Explosion", p, 0.5, 2, raio, c, branco(c, 0.6))
end

-- ── 7. BOMBA DO JUIZO ────────────────────────────────────────────────────

--- A contagem: o mostrador aceso, no chão.
function Efeitos.CONTAGEM(d)
	camadaPavio(d, pos(d) + Vector3.new(0, 1.2, 0),
		CFG.ALERTA, (d and tonumber(d.duracao)) or 3)
	camadaOnda(acima(pos(d), 0.5), CFG.ALERTA, raioDe(d, 10), 0.6)
end

--- O Juízo Final. É a maior do conjunto, e ela é feita de CAMADAS EM TEMPOS
--- diferentes: clarão, cogumelo, três ondas e a poeira. Tudo junto no mesmo
--- quadro daria uma bola branca gigante e nada mais.
function Efeitos.JUIZO(d)
	local p = acima(pos(d), 1)
	local raio = raioDe(d, 60)
	local c = corDe(d, CFG.ALERTA)

	camadaClarao(p, Color3.new(1, 1, 1), raio * 0.7)
	explosao(p, raio, c, CFG.FUMACA, raio * 1.1)
	camadaCogumelo(p, raio * 1.3, raio * 0.5, c, CFG.FUMACA)

	local i = 0
	while i < 3 do
		local atraso = 0.14 * i
		local escala = 1 + i * 0.35
		task.delay(atraso, function()
			camadaOnda(p, branco(c, i * 0.25), raio * escala, 0.8 + i * 0.2)
		end)
		i = i + 1
	end

	tremor(CFG.TREMOR_FORCA * 1.8, CFG.TREMOR_TEMPO * 2)
	pk("Smoky_Explosion", p, 1.4, raio * 0.5, c, CFG.FUMACA)
	-- Sonar_Ring(CF, Lifetime, Size_Start, Size_End, Thickness_Start,
	--            Thickness_End, Color_A, Color_B)
	pk("Sonar_Ring", CFrame.new(p), 1.3, 6, raio * 2, 1.6, 0.1, c, branco(c, 0.7))
end

--- A onda que vem depois, e derruba de novo.
function Efeitos.ONDA_JUIZO(d)
	local p = acima(pos(d), 0.8)
	local raio = raioDe(d, 60)
	local c = corDe(d, CFG.BRASA)
	camadaOnda(p, c, raio, 0.9)
	camadaEstilhaco(p, c, raio * 0.5, 20, 0.8)
	camadaPoeira(pos(d), CFG.FUMACA, raio * 0.6, 18, 1.8)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Bomba] falha em " .. tostring(tipo)
			.. ": " .. tostring(err))
	end
	return ok
end

function VFX.Parar(id)
	local reg = PorId[id]
	if not reg then return end
	for _, conn in ipairs(reg.conexoes) do
		if conn then conn:Disconnect() end
	end
	for _, inst in ipairs(reg.partes) do
		if inst and inst.Parent then
			if inst:IsA("ParticleEmitter") or inst:IsA("Trail") then
				inst.Enabled = false
			end
			inst.Parent = nil
		end
	end
	PorId[id] = nil
end

function VFX.LimparTudo()
	for id in pairs(PorId) do VFX.Parar(id) end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then inst.Parent = nil end
	end
	table.clear(Vivos)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
end

return VFX
